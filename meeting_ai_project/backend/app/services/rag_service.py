import chromadb
from chromadb.config import Settings
from sentence_transformers import SentenceTransformer
import os

class RagService:
    def __init__(self):
        # 1. Vektör Veritabanını Başlat (Yerel Klasöre Kaydeder)
        self.chroma_client = chromadb.PersistentClient(path="chroma_db")
        
        # 2. Koleksiyonları (Tabloları) Oluştur
        # Toplantı transkriptleri için:
        self.transcript_collection = self.chroma_client.get_or_create_collection(
            name="meeting_transcripts",
            metadata={"hnsw:space": "cosine"} # Benzerlik hesabı için Cosine Similarity
        )
        
        # 3. Embedding Modelini Yükle (Metni Sayıya Çeviren Yapı)
        # 'all-MiniLM-L6-v2' hafif ve hızlıdır, CPU'da rahat çalışır.
        print("🧠 AI Hafıza Modeli Yükleniyor...")
        self.embedding_model = SentenceTransformer('all-MiniLM-L6-v2')
        print("✅ AI Hafıza Hazır!")

    def add_meeting_to_memory(self, meeting_id: int, segments: list, title: str):
        """
        Toplantı bittiğinde tüm konuşmaları vektör veritabanına ekler.
        """
        ids = []
        documents = []
        metadatas = []
        embeddings = []

        print(f"📥 Meeting #{meeting_id} hafızaya işleniyor...")

        # Her segmenti (cümle grubunu) tek tek işle
        for segment in segments:
            # Metin: "Ali: Bütçeyi onayladık."
            text_content = f"{segment['speaker_label']}: {segment['text']}"
            
            # Vektöre Çevir
            vector = self.embedding_model.encode(text_content).tolist()
            
            # Listelere Ekle
            # ID formatı: meet_1_seg_0, meet_1_seg_1...
            seg_id = f"meet_{meeting_id}_seg_{int(segment['start_time'])}"
            
            ids.append(seg_id)
            documents.append(text_content)
            embeddings.append(vector)
            metadatas.append({
                "meeting_id": meeting_id,
                "title": title,
                "timestamp": segment['start_time']
            })

        # Toplu halde ChromaDB'ye kaydet
        if ids:
            self.transcript_collection.add(
                ids=ids,
                documents=documents,
                embeddings=embeddings,
                metadatas=metadatas
            )
            print(f"✅ Meeting #{meeting_id} hafızaya kaydedildi ({len(ids)} parça).")

    def search_memory(self, query: str, limit: int = 5):
        """
        Kullanıcının sorusunu vektöre çevirip en alakalı geçmiş konuşmaları bulur.
        """
        # 1. Soruyu vektöre çevir
        query_vector = self.embedding_model.encode(query).tolist()
        
        # 2. Vektör veritabanında ara
        results = self.transcript_collection.query(
            query_embeddings=[query_vector],
            n_results=limit
        )
        
        # 3. Sonuçları temizle ve döndür
        found_docs = []
        if results['documents']:
            for i, doc in enumerate(results['documents'][0]):
                meta = results['metadatas'][0][i]
                found_docs.append(f"[Toplantı: {meta['title']}] {doc}")
                
        return found_docs

    def delete_meeting_memory(self, meeting_id: int):
        """Toplantı silinirse hafızadan da sil."""
        self.transcript_collection.delete(
            where={"meeting_id": meeting_id}
        )

# Servisi başlat
rag_service = RagService()
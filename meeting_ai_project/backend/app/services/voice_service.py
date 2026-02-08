import torch
import soundfile as sf # <-- Torchaudio yerine Soundfile
import os
import numpy as np

# SpeechBrain import kontrolü
try:
    from speechbrain.inference.speaker import EncoderClassifier
except ImportError:
    EncoderClassifier = None

class VoiceService:
    def __init__(self):
        print("🔄 Ses Tanıma Modeli Hazırlanıyor...")
        self.classifier = None
        save_path = "tmp_models/embedding_model"
        
        if EncoderClassifier:
            try:
                self.classifier = EncoderClassifier.from_hparams(
                    source="speechbrain/spkrec-ecapa-voxceleb", 
                    savedir=save_path,
                    run_opts={"device": "cpu"}
                )
                print("✅ Ses Tanıma Modeli Hazır!")
            except Exception as e:
                print(f"❌ Model Yükleme Hatası: {e}")
                self.classifier = None
        else:
            print("⚠️ SpeechBrain kütüphanesi eksik.")

    def extract_embedding(self, file_path: str):
        """
        Ses dosyasından 192 boyutlu vektör çıkarır.
        Soundfile kullanarak okur (Hatasız).
        """
        if self.classifier is None:
            return [0.0] * 192

        try:
            # 1. Sesi Soundfile ile Yükle (Torchaudio yerine)
            signal_np, fs = sf.read(file_path)
            
            # 2. Tensor'a çevir
            signal = torch.from_numpy(signal_np).float()
            
            # 3. Eğer Stereo ise Mono yap, boyut ekle
            if len(signal.shape) > 1:
                signal = signal.mean(dim=1) # Stereo -> Mono
            if signal.dim() == 1:
                signal = signal.unsqueeze(0) # [Batch, Time] formatı için

            # 4. Vektörü Çıkar
            embeddings = self.classifier.encode_batch(signal)
            
            # 5. Listeye Çevir
            vector = embeddings[0, 0, :].detach().cpu().numpy().tolist()
            return vector
        except Exception as e:
            print(f"❌ Vektör Çıkarma Hatası: {e}")
            return [0.0] * 192

    def identify_speaker(self, segment_embedding: list, known_profiles: list):
        if not known_profiles or segment_embedding == [0.0]*192:
            return "Misafir", 0.0

        best_match_name = "Misafir"
        best_score = 0.0
        threshold = 0.30 

        vec_a = np.array(segment_embedding)
        norm_a = np.linalg.norm(vec_a)
        
        if norm_a == 0: return "Misafir", 0.0

        for profile in known_profiles:
            vec_b = np.array(profile["embedding"])
            norm_b = np.linalg.norm(vec_b)
            
            if norm_b == 0: continue

            dot_product = np.dot(vec_a, vec_b)
            score = dot_product / (norm_a * norm_b)

            if score > best_score:
                best_score = score
                best_match_name = profile["name"]

        if best_score > threshold:
            return best_match_name, best_score
        else:
            return "Misafir", best_score

voice_service = VoiceService()
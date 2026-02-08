import whisper
import torch
import os

class AudioService:
    def __init__(self):        
        self.device = "cpu" 
        
        # DEĞİŞİKLİK BURADA: 'small' yerine 'medium' yapıyoruz.
        # Bu model Türkçeyi çok daha iyi anlar.
        self.model_size = "medium" 
        
        self.model = None

    def load_model(self):
        """Modeli hafızaya yükler (Lazy Loading)"""
        if self.model is None:
            print(f"🔄 Whisper '{self.model_size}' modeli yükleniyor... (Bu işlem ilk seferde vakit alır)")
            # GPU varsa kullan, yoksa CPU
            device = "cuda" if torch.cuda.is_available() else "cpu"
            self.model = whisper.load_model(self.model_size, device=device)
            print("✅ Model yüklendi!")

    def transcribe(self, file_path: str):
        """Sesi metne çevirir"""
        if not os.path.exists(file_path):
            raise FileNotFoundError(f"Dosya bulunamadı: {file_path}")

        # Modeli yükle
        self.load_model()

        # Çeviri işlemini başlat
        # fp16=False -> CPU hatalarını önlemek için (GPU yoksa)
        result = self.model.transcribe(file_path, fp16=False, language="tr")

        return result

# Singleton instance (Her seferinde yeni class yaratmayalım)
audio_service = AudioService()

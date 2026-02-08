import os
from groq import Groq
from dotenv import load_dotenv

load_dotenv()

class AudioService:
    def __init__(self):
        self.api_key = os.getenv("GROQ_API_KEY")
        if not self.api_key:
            print("⚠️ GROQ API KEY Eksik! .env dosyasını kontrol edin.")
        
        self.client = Groq(api_key=self.api_key)

    def transcribe(self, file_path: str):
        """
        Groq Whisper-Large-V3 kullanarak sesi metne çevirir.
        Akustik olarak en iyi sonucu almaya odaklanır.
        """
        print("🚀 Ses dosyası Groq Cloud'a gönderiliyor...")
        
        if not os.path.exists(file_path):
             return {"text": "", "segments": []}

        try:
            with open(file_path, "rb") as file:
                transcription = self.client.audio.transcriptions.create(
                    file=(file_path, file.read()),
                    model="whisper-large-v3",
                    # Genel Bağlam Prompt'u: Modele sadece düzgün yazmasını söylüyoruz.
                    prompt="Şimdi toplantı notlarını almaya başlıyorum. Lütfen cümleleri tam, akıcı ve noktalama işaretlerine dikkat ederek yaz.",
                    response_format="verbose_json",
                    language="tr"
                )
            
            segments = []
            if hasattr(transcription, 'segments'):
                for seg in transcription.segments:
                    segments.append({
                        "start": seg['start'],
                        "end": seg['end'],
                        "text": seg['text']
                    })
            else:
                segments.append({
                    "start": 0.0,
                    "end": transcription.duration,
                    "text": transcription.text
                })

            print("✅ Groq Whisper Analizi Tamamlandı!")
            return {"text": transcription.text, "segments": segments}

        except Exception as e:
            print(f"❌ Groq Transkripsiyon Hatası: {e}")
            return {"text": "", "segments": []}

audio_service = AudioService()
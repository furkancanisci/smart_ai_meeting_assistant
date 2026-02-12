import os
import json
from datetime import datetime
import locale
from groq import Groq
from dotenv import load_dotenv

load_dotenv()

class LLMService:
    def __init__(self):
        self.api_key = os.getenv("GROQ_API_KEY")
        if not self.api_key:
            print("⚠️ GROQ API KEY Eksik! .env dosyasını kontrol edin.")
            
        self.client = Groq(api_key=self.api_key)
        # En güncel ve yetenekli model
        self.model_name = "llama-3.3-70b-versatile"

    def _extract_json(self, content: str):
        """
        Yapay zeka çıktısının içinden JSON kısmını çekip alır.
        """
        try:
            # 1. Temizle (Markdown ve boşluklar)
            content = content.replace("```json", "").replace("```", "").strip()
            
            # 2. Direkt parse etmeyi dene
            return json.loads(content)
        except json.JSONDecodeError:
            # 3. Eğer yapamazsa, { ... } arasını bulmaya çalış (Cımbızlama)
            start = content.find('{')
            end = content.rfind('}')
            if start != -1 and end != -1:
                json_str = content[start : end + 1]
                try:
                    return json.loads(json_str)
                except:
                    pass
            return {}

    async def correct_transcript(self, text: str):
        """
        Whisper hatalarını düzeltir.
        """
        try:
            chat_completion = self.client.chat.completions.create(
                messages=[
                    {"role": "system", "content": "Sen bir editörsün. Sadece metindeki bariz ses hatalarını düzelt. Yorum yapma."},
                    {"role": "user", "content": text}
                ],
                model=self.model_name, 
                temperature=0.1,
            )
            return chat_completion.choices[0].message.content.strip()
        except Exception:
            return text

    async def extract_action_items(self, transcript: str):
        """
        Toplantı dökümünden görevleri çıkarır (Tarih Algılama Dahil).
        """
        # Bugünün tarihini al
        try:
            locale.setlocale(locale.LC_TIME, "tr_TR.UTF-8")
        except:
            try:
                locale.setlocale(locale.LC_TIME, "Turkish_Turkey.1254")
            except:
                pass
            
        current_date = datetime.now().strftime("%Y-%m-%d (%A)")

        system_prompt = f"""
        You are an AI Task Manager. Extract action items from the transcript.
        
        CONTEXT:
        - Current Date: {current_date}
        - Calculate relative dates (e.g., "tomorrow", "next Friday") based on the Current Date.
        - If a specific time is mentioned (e.g. "akşama"), assume 17:00.
        
        RULES:
        1. "Ahmet yapsın", "Ben yaparım", "Lazım", "Gerekli" -> TASKS.
        2. Output MUST be a valid JSON object with a single key "tasks".
        3. Do NOT add any conversational text. Just JSON.
        
        JSON FORMAT:
        {{
          "tasks": [
            {{
              "description": "Task description in Turkish",
              "assignee": "Name (or 'Belirsiz')",
              "due_date": "YYYY-MM-DD HH:MM (ISO Format) or null",
              "confidence": 0.9
            }}
          ]
        }}
        """
        
        user_prompt = f"TRANSCRIPT:\n{transcript}"

        try:
            print(f"🤖 Groq Görev Analizi Başladı... (Ref: {current_date})")
            
            chat_completion = self.client.chat.completions.create(
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt}
                ],
                model=self.model_name, 
                temperature=0.1,
                response_format={"type": "json_object"} 
            )

            content = chat_completion.choices[0].message.content.strip()
            data = self._extract_json(content)
            
            tasks = []
            if "tasks" in data: tasks = data["tasks"]
            elif "action_items" in data: tasks = data["action_items"]
            elif isinstance(data, list): tasks = data
            
            print(f"✅ Bulunan Görev Sayısı: {len(tasks)}")
            return tasks

        except Exception as e:
            print(f"❌ Kritik Groq Hatası (Görev): {e}")
            return []

    async def analyze_sentiment(self, transcript: str):
        """
        Toplantının genel duygu durumunu analiz eder.
        """
        prompt = """
        Analyze the sentiment of this meeting transcript.
        Output ONLY a JSON object.
        
        FORMAT:
        {
            "mood": "One word Turkish label (e.g., Gergin, Neşeli, Resmi, Verimli, Nötr)", 
            "score": 8 
        }
        (Score 1-10: 1=Very Negative/Tension, 10=Very Positive/Productive)
        """
        try:
            chat_completion = self.client.chat.completions.create(
                messages=[
                    {"role": "system", "content": prompt},
                    {"role": "user", "content": transcript[:15000]} 
                ],
                model=self.model_name,
                temperature=0.1,
                response_format={"type": "json_object"}
            )
            return self._extract_json(chat_completion.choices[0].message.content)
        except Exception as e:
            print(f"❌ Duygu Analizi Hatası: {e}")
            return {"mood": "Nötr", "score": 5}

    async def generate_executive_summary(self, transcript: str):
        """
        4 Maddeli Yönetici Özeti Çıkarır.
        """
        prompt = """
        You are an Executive Assistant. Summarize the meeting in Turkish.
        Output ONLY a JSON object.
        
        JSON FORMAT:
        {
          "discussions": ["Konuşulan madde 1", "Konuşulan madde 2"],
          "decisions": ["Alınan karar 1", "Alınan karar 2"],
          "action_plan": ["Kim ne yapacak (Kısa özet)"],
          "deadlines": ["Varsa kritik tarihler"]
        }
        """
        try:
            chat_completion = self.client.chat.completions.create(
                messages=[
                    {"role": "system", "content": prompt},
                    {"role": "user", "content": transcript[:15000]}
                ],
                model=self.model_name,
                temperature=0.1,
                response_format={"type": "json_object"}
            )
            return self._extract_json(chat_completion.choices[0].message.content)
        except Exception as e:
            print(f"❌ Özet Hatası: {e}")
            return {}

    async def chat_with_context(self, context: str, user_query: str):
        """
        Global veya Yerel fark etmeksizin, verilen Context'e göre soruyu cevaplar.
        """
        system_prompt = """
        Sen 'Smart', tüm toplantıların verisine hakim akıllı bir asistansın.
        
        GÖREVİN:
        Sana verilen 'BULUNAN VERİLER' kısmını analiz ederek kullanıcının sorusunu cevapla.
        
        KURALLAR:
        1. Hangi toplantıda ne konuşulduğunu net belirt (Örn: "25 Ocak tarihli toplantıda Ahmet şundan bahsetti...").
        2. Eğer sorunun cevabı verilerde yoksa "Kayıtlarımda buna dair net bir bilgi bulamadım" de. Uydurma.
        3. Cevabın profesyonel, toparlayıcı ve Türkçe olsun.
        """
        
        user_input = f"""
        BULUNAN VERİLER (CONTEXT):
        {context}
        
        KULLANICI SORUSU:
        {user_query}
        """

        try:
            chat_completion = self.client.chat.completions.create(
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_input}
                ],
                model=self.model_name,
                temperature=0.3, 
            )
            return chat_completion.choices[0].message.content.strip()
        except Exception as e:
            print(f"❌ Chat Hatası: {e}")
            return "Üzgünüm, şu an bağlantı kuramıyorum."

llm_service = LLMService()
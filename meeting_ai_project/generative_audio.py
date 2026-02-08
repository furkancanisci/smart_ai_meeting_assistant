import asyncio
import edge_tts
from pydub import AudioSegment
import os

# Senaryo Metni
SCRIPT = [
    ("Ali", "Arkadaşlar hoş geldiniz. Vaktimiz dar, hemen konuya girelim. Mobil uygulamanın lansmanı için son durum nedir? Müşteri sıkıştırmaya başladı."),
    ("Ayşe", "Ali Bey, backend tarafında işler yolunda, API entegrasyonlarını bitirdik. Ancak iOS tarafında beklemediğimiz bir sorun çıktı. Bildirimler bazen geç düşüyor, bazen hiç düşmüyor."),
    ("Ali", "Bu kabul edilemez Ayşe. Bildirim bu uygulamanın kalbi. Ne kadar sürer çözmesi?"),
    ("Ayşe", "Ekip üzerinde çalışıyor ama en az 3 güne ihtiyacımız var. Firebase tarafında bir yapılandırma hatası var gibi görünüyor."),
    ("Mehmet", "Arkadaşlar teknik kısmı böleceğim ama daha büyük bir sıkıntımız var. Geçen ayki sunucu masrafları projeksiyonu patlatmış. AWS faturası beklediğimizin yüzde 40 üzerinde geldi. Özellikle görsel işleme servisleri dolar kurundaki artışla birlikte belimizi büküyor."),
    ("Ali", "Nasıl yani? Biz bu projeye sabit bütçe verdik Mehmet. Ekstra kaynak ayıramayız. Neden şişti bu fatura?"),
    ("Ayşe", "Kullanıcılar profil fotoğraflarını çok yüksek çözünürlükte yüklüyor. Her fotoğrafı işlemek işlemciyi yoruyor."),
    ("Mehmet", "O zaman acil bir önlem almamız lazım. Yoksa gelecek ay şirketin nakit akışında ciddi sıkıntı yaşarız. Bu giderle lansmana çıkamayız."),
    ("Ayşe", "Tamam, o zaman şöyle yapalım: Görsel işleme servisini kapatalım, resimleri istemci tarafında, yani telefonda küçültüp sunucuya öyle atalım. Bu sunucu yükünü yüzde 80 azaltır."),
    ("Ali", "Bu kullanıcı deneyimini bozar mı?"),
    ("Ayşe", "Hayır, hissetmezler bile. Ama bunu kodlamak için bana ek süre lazım."),
    ("Ali", "Tamam, kararı veriyorum. İstemci taraflı sıkıştırmaya geçiyoruz. Ama Ayşe, sana en fazla önümüzdeki hafta Salı gününe kadar süre veriyorum. Yani 14 Şubat günü bu iş bitmiş, testleri yapılmış olacak."),
    ("Mehmet", "Bu çözüm faturayı düşürecekse onaylıyorum."),
    ("Ali", "Anlaştık. 14 Şubat Salı günü, hem bildirim sorunu hem de bu resim optimizasyonu bitmiş şekilde tekrar toplanıyoruz. Dağılabiliriz.")
]

# Ses Atamaları
VOICES = {
    "Ali": "tr-TR-AhmetNeural",   
    "Ayşe": "tr-TR-EmelNeural",   
    "Mehmet": "tr-TR-AhmetNeural" 
}

async def generate_audio():
    combined_audio = AudioSegment.empty()
    print("🎧 Ses dosyası oluşturuluyor...")

    for i, (speaker, text) in enumerate(SCRIPT):
        print(f"🗣️ {speaker} konuşuyor: {text[:30]}...")
        voice = VOICES[speaker]
        filename = f"temp_{i}.mp3"
        
        # Mehmet'i Ali'den ayırmak için ses tonu ayarı
        rate = "+0%"
        pitch = "+0Hz"
        if speaker == "Mehmet":
            rate = "-10%" 
            pitch = "-5Hz"
        
        communicate = edge_tts.Communicate(text, voice, rate=rate, pitch=pitch)
        await communicate.save(filename)
        
        segment = AudioSegment.from_mp3(filename)
        combined_audio += segment + AudioSegment.silent(duration=500)
        os.remove(filename)

    output_file = "test_meeting.wav"
    combined_audio.export(output_file, format="wav")
    print(f"\n✅ Başarılı! Dosya oluşturuldu: {output_file}")

if __name__ == "__main__":
    asyncio.run(generate_audio())
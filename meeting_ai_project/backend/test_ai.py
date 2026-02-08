from speechbrain.inference.speaker import EncoderClassifier

print("⏳ Model indiriliyor/yükleniyor...")
try:
    classifier = EncoderClassifier.from_hparams(
        source="speechbrain/spkrec-ecapa-voxceleb", 
        savedir="tmp_models/embedding_model",
        run_opts={"device": "cpu"}
    )
    print("✅ BAŞARILI! Model yüklendi.")
except Exception as e:
    print(f"❌ HATA: {e}")
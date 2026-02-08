import os

class Settings:
    PROJECT_NAME: str = "Meeting AI"
    API_V1_STR: str = "/api/v1"
    
    # Yüklenen dosyaların saklanacağı klasör
    UPLOAD_DIR: str = os.path.join(os.getcwd(), "uploads")

settings = Settings()

# Klasör yoksa oluştur
if not os.path.exists(settings.UPLOAD_DIR):
    os.makedirs(settings.UPLOAD_DIR)

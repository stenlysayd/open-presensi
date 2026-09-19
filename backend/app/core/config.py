import os
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    APP_NAME: str = "Open Presensi"
    ENVIRONMENT: str = "development"
    DEBUG: bool = True
    SECRET_KEY: str = "dev_default_secret_key_change_in_production_123456789"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days

    # Database
    DATABASE_URL: str = "postgresql://postgres:postgres@localhost:5432/open_presensi"

    # Default Timezone
    DEFAULT_TIMEZONE: str = "Asia/Makassar"

    # WhatsApp Settings
    WA_ENABLED: bool = False
    WA_PROVIDER: str = "fonnte"
    WA_API_TOKEN: str = ""
    WA_DEVICE_NUMBER: str = ""

    # AI Summarizer Settings
    AI_SUMMARY_ENABLED: bool = False
    AI_PROVIDER: str = "openai"  # "openai" or "gemini"
    AI_API_KEY: str = ""
    AI_MODEL_NAME: str = "gpt-4o-mini"

    model_config = SettingsConfigDict(env_file=".env", extra="allow")


settings = Settings()

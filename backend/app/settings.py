from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    DATABASE_URL: str
    CORS_ORIGINS: str = "http://localhost:3000,http://localhost:5173,http://127.0.0.1:5500"


settings = Settings()
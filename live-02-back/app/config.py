import os
from dotenv import load_dotenv

load_dotenv()

class Settings:
    # Supabase
    SUPABASE_URL: str = os.getenv("SUPABASE_URL")
    SUPABASE_KEY: str = os.getenv("SUPABASE_KEY")   # publishable/anon key
    SUPABASE_SERVICE_ROLE_KEY: str = os.getenv("SUPABASE_SERVICE_ROLE_KEY")  # secret key (backend)

    # LiveKit - COLOQUE AS CHAVES CORRETAS DO LIVEKIT CLOUD
    LIVEKIT_URL: str = os.getenv("LIVEKIT_URL", "wss://livestreamapp-ghcjo92o.livekit.cloud")
    LIVEKIT_API_KEY: str = os.getenv("LIVEKIT_API_KEY")
    LIVEKIT_API_SECRET: str = os.getenv("LIVEKIT_API_SECRET")

    # Outras configurações
    SECRET_KEY: str = os.getenv("SECRET_KEY", "change-this-in-production")
    ALGORITHM = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES = 30

settings = Settings()

# Validação
if not settings.LIVEKIT_API_KEY or not settings.LIVEKIT_API_SECRET:
    print("❌ ERRO: LIVEKIT_API_KEY ou LIVEKIT_API_SECRET não configuradas no .env")
    raise ValueError("LiveKit keys missing")

print("[OK] LiveKit config loaded OK")
print(f"LIVEKIT_URL: {settings.LIVEKIT_URL}")
print(f"API Key length: {len(settings.LIVEKIT_API_KEY)}")
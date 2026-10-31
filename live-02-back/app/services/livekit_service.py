# app/services/livekit_service.py
from livekit.api import AccessToken, VideoGrants
from app.config import settings
from datetime import timedelta


def create_livekit_token(identity: str, room: str, ttl_minutes: int = 60) -> str:
    """
    Gera token LiveKit de forma correta e compatível
    """
    try:
        token = AccessToken(
            api_key=settings.LIVEKIT_API_KEY,
            api_secret=settings.LIVEKIT_API_SECRET
        )

        token.with_identity(identity)
        token.with_name(f"User_{identity[:8]}")

        grants = VideoGrants(
            room_join=True,
            room=room,
            can_publish=True,
            can_subscribe=True,
            can_publish_data=True,
        )

        token.with_grants(grants)
        token.with_ttl(timedelta(minutes=ttl_minutes))

        jwt_token = token.to_jwt()

        print(f"[OK] Token LiveKit gerado com sucesso | Identity: {identity} | Room: {room}")
        return jwt_token

    except Exception as e:
        print(f"[ERRO] Erro ao gerar token LiveKit: {e}")
        raise
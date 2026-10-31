from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import os

from app.config import settings
from app.routers import auth, users, streams, payments, comments, test_db

app = FastAPI(title="Live Backend", version="0.1.0")

# CORS (dev: permissivo; prod: restringir via env)
allowed_origins = os.getenv("ALLOWED_ORIGINS", "*").split(",")
app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Routers
app.include_router(auth.router, prefix="/auth", tags=["auth"])
app.include_router(users.router, prefix="/users", tags=["users"])
app.include_router(streams.router, tags=["streams"])  # paths already include /streams
app.include_router(payments.router, prefix="/payments", tags=["payments"])
app.include_router(comments.router, prefix="/comments", tags=["comments"])
app.include_router(test_db.router, prefix="/test", tags=["test"])


@app.get("/")
def root():
    return {"message": "Backend OK - pronto para Flutter", "livekit_url": settings.LIVEKIT_URL}


@app.get("/health")
def health():
    return {"status": "ok", "ready": True}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)

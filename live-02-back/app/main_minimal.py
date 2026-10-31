from fastapi import FastAPI

app = FastAPI(title="Live Backend Minimal")

@app.get("/")
async def root():
    return {"message": "ok"}


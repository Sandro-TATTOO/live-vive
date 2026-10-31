from fastapi import FastAPI

app = FastAPI(title="Live Backend Minimal Fixed")

@app.get("/")
async def root():
    return {"message": "ok"}
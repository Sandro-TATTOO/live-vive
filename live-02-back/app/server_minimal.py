from fastapi import FastAPI
from fastapi.responses import HTMLResponse

app = FastAPI(title="Live Backend")

from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def root():
    return {"message": "Backend OK - pronto para Flutter"}

@app.get("/health")
def health():
    return {"status": "ok", "ready": True}

from app.routers.streams import router as streams_router

app.include_router(streams_router)

@app.get("/streams/test")
def streams_test():
    return {"livekit": True, "endpoints": ["/streams/create", "/streams/token", "/streams/test/livekit-token"], "status": "LiveKit ready"}

@app.get("/live-test", response_class=HTMLResponse)
async def live_test():
    html_content = """
<!DOCTYPE html>
<html>
<head>
    <title>LiveKit Test</title>
    <script src="https://cdn.jsdelivr.net/npm/livekit-client/dist/livekit-client.umd.min.js"></script>
</head>
<body>
    <h1>LiveKit Test</h1>
    <button id="start-live">Start Live</button>
    <div id="video-container" style="width: 800px; height: 600px; border: 1px solid #ccc;"></div>
</body>
</html>
    """
    return HTMLResponse(content=html_content)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)

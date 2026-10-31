console.log("🚀 LiveKit FULL SYSTEM LOADED");

/* =========================
   CONFIG
========================= */

const API_URL =
  location.hostname === "localhost" || location.hostname === "127.0.0.1"
    ? "http://127.0.0.1:8000"
    : `http://${location.hostname}:8000`;

const LIVEKIT_URL = "wss://livestreamapp-ghcjo92o.livekit.cloud";

let room = null;

/* =========================
   LOG
========================= */

function log(msg) {
  console.log(msg);

  const el = document.getElementById("console");

  if (el) {
    el.textContent += `[${new Date().toLocaleTimeString()}] ${msg}\n`;
    el.scrollTop = el.scrollHeight;
  }
}

/* =========================
   INIT
========================= */

document.addEventListener("DOMContentLoaded", () => {

  log("✅ Página carregada");
  log("LiveKit SDK: OK");
  log("🎯 sistema pronto");

  const btnStreamer = document.getElementById("startCamera");
  const btnViewer = document.getElementById("watchLive");
  const videoLocal = document.getElementById("video");

  /* =========================
     STREAMER
  ========================= */

  btnStreamer?.addEventListener("click", async () => {

    try {

      log("🔴 STREAMER iniciando...");

      const stream = await navigator.mediaDevices.getUserMedia({
        video: true,
        audio: true
      });

      videoLocal.srcObject = stream;

      log("📹 câmera ativa");

      const tokenRes = await fetch(
        `${API_URL}/streams/test/livekit-token?room=test_room&role=streamer`
      );

      const data = await tokenRes.json();

      log("🔑 token recebido STREAMER");

      room = new LivekitClient.Room();

      await room.connect(LIVEKIT_URL, data.token);

      log("✅ STREAMER conectado");

      const tracks = await LivekitClient.createLocalTracks({
        audio: true,
        video: true
      });

      for (const track of tracks) {

        await room.localParticipant.publishTrack(track);

        log("📡 publicado: " + track.kind);

      }

    } catch (err) {

      log("❌ STREAMER ERROR: " + err.message);

    }

  });

  /* =========================
     VIEWER
  ========================= */

  btnViewer?.addEventListener("click", async () => {

    try {

      log("👀 VIEWER clicou em assistir");

      const tokenRes = await fetch(
        `${API_URL}/streams/test/livekit-token?room=test_room&role=viewer`
      );

      const data = await tokenRes.json();

      log("🔑 token recebido VIEWER");

      room = new LivekitClient.Room();

      /* =========================
         EVENTOS
      ========================= */

      room.on("trackSubscribed", (track, publication, participant) => {

        log("📺 track recebida de " + participant.identity);

        const element = track.attach();

        const container = document.getElementById("video-container");

        if (container) {
          container.appendChild(element);
        } else {
          document.body.appendChild(element);
        }

      });

      room.on("participantConnected", p => {

        log("👤 participante entrou: " + p.identity);

      });

      room.on("participantDisconnected", p => {

        log("👋 participante saiu: " + p.identity);

      });

      await room.connect(LIVEKIT_URL, data.token);

      log("✅ VIEWER conectado");

    } catch (err) {

      log("❌ VIEWER ERROR: " + err.message);

    }

  });

});
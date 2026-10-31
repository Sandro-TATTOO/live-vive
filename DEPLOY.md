# Deploy do Backend (FastAPI) + Frontend (Flutter Web)

## Backend (FastAPI) - Deploy no Railway ou Render

### Opcao 1: Railway (recomendado)
1. Acesse https://railway.app e faca login com GitHub.
2. New Project -> Deploy from GitHub repo -> selecione live-vive.
3. Configure o Root Directory: `live-02-back`.
4. Adicione as variaveis de ambiente (Settings > Variables):
   - SUPABASE_URL
   - SUPABASE_KEY (publishable)
   - SUPABASE_SERVICE_ROLE_KEY (secret)
   - LIVEKIT_URL
   - LIVEKIT_API_KEY
   - LIVEKIT_API_SECRET
   - SECRET_KEY
   - ALLOWED_ORIGINS = https://Sandro-TATTOO.github.io
5. Deploy. Copie a URL publica (ex: https://live-vive-backend.up.railway.app).

### Opcao 2: Render
1. Acesse https://render.com -> New Web Service.
2. Conecte o repo GitHub.
3. Root Directory: `live-02-back`.
4. Build Command: `pip install -r requirements.txt`
5. Start Command: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
6. Adicione as variaveis de ambiente (igual ao Railway).
7. Deploy. Copie a URL publica.

## Frontend (Flutter Web) - GitHub Pages (ja configurado)
O deploy automatico esta configurado via GitHub Actions (.github/workflows/deploy.yml).
Para usar o backend publicado:
1. Edite `live-02-front/lib/services/stream_service.dart`:
   - Altere `_baseUrl` para a URL publica do backend.
2. Commit + push. O GitHub Actions fara o rebuild e deploy.

## Testar localmente com backend publicado
- Altere `_baseUrl` para a URL publica.
- Rode `flutter run -d chrome`.
- O app conectara ao backend publicado.

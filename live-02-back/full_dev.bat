@echo off
echo Removendo venv antigo...
if exist venv rmdir /s /q venv
echo Criando novo venv...
python -m venv venv
echo Ativando venv...
call venv\Scripts\activate.bat || .\venv\Scripts\Activate.ps1
echo Instalando dependencias...
pip install --upgrade pip
pip install -r requirements.txt --no-cache-dir --force-reinstall
pip install livekit-api
echo === BACKEND PRONTO ===
echo Acesse: http://localhost:8000/docs
uvicorn app.server_minimal:app --reload --host 0.0.0.0 --port 8000
pause

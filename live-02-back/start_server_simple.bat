@echo off
title Live Backend Simple
call venv\Scripts\activate.bat
uvicorn app.server_minimal:app --reload --host 0.0.0

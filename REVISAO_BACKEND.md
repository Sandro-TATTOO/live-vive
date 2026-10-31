# REVISAO DO ESTADO DO BACKEND (live-02-back)
Data: 31/10/2026

## 1. Entrypoints (confusao)
- app/main.py: versao MINIMAL com chaves hardcoded (placeholders) e apenas endpoint /streams/test/livekit-token. Nao registra routers.
- app/server_minimal.py: inclui streams_router, CORS, health. Provavel entrypoint real de dev.
- app/main_minimal.py / main_minimal_fixed.py: arquivos quebrados/incompletos.
Recomendacao: definir UM entrypoint oficial (main.py) que importa routers e usa settings/.env; remover/minimalizar duplicatas.

## 2. Bugs criticos de compilacao
- app/services/viewer_service.py: falta definicao de join_stream; codigo solto (return fora de funcao). Quebra import em streams.py.
- app/schemas.py: usa datetime sem importar datetime.
- app/main_minimal_fixed.py: string nao fechada.

## 3. Inconsistencias de contrato
- streams.py importa ViewerJoin, ViewerStats, join_stream, leave_stream, get_viewer_count de viewer_service, e MessageCreate/Message de chat_service.
- viewer_service espera tabela stream_viewers e RPCs get_viewer_count/increment_viewers/decrement_viewers (SQL fornecido em supabase_viewer_mvp.sql).
- chat_service espera tabela stream_messages com coluna is_deleted e status 'live' (SQL em supabase_chat.sql).
- streams router usa supabase.table('streams') e status 'live'/'ended' (SQL viewer_mvp usa 'idle'/'live'/'ended') -> OK.

## 4. Seguranca
- .env contem SUPABASE_KEY com service_role e LIVEKIT_API_SECRET reais. .gitignore agora ignora .env (Fase 0). Recomenda-se rotacionar chaves se ja foram expostas.
- .env.example atualizado.

## 5. Dependencias
- requirements.txt sem versoes (pip freeze recomendado - dicas.txt).

## 6. Tabelas/RPCs pendentes no Supabase
- Executar supabase_viewer_mvp.sql e supabase_chat.sql no Supabase SQL Editor.
- Verificar RLS policies (chat sql cria; viewer sql basico).

## 7. Proxima acao recomendada
Corrigir entrypoint e viewer_service, importar datetime em schemas, validar rodando uvicorn e testando /streams/live.
Nao iniciar Fase 1 de features ate backend basico rodar.

# PLANO DE CONSTRUCAO E EVOLUCAO - APP DE LIVE STREAMING
## (Estilo SuperLive / BigoLive - com diferenciais proprios)

> **Status:** PLANO (pre-implementacao) - nenhuma mudanca de codigo ate aprovacao.
> **Workspace:** c:\Users\YYYY\Documents\live-01
> **Modulos:** live-01 (usuario comum / web), live-02-back (backend FastAPI), live-02-front (frontend Flutter)
> **Atualizado:** 31/10/2026

## 0. PRINCIPIO DIRETOR (NAO NEGOCIAVEL)

1. Nenhuma logica financeira/VIP no frontend. Toda operacao critica passa por RPC/backend seguro.
2. Fonte unica de verdade: resumo-01.txt (arquitetura/regras) + este plano (execucao). Mudancas futuras sao incrementais (RESUMO-01.1, 01.2...), nunca substituem.
3. Seguranca primeiro: RLS em todas as tabelas; tokens LiveKit gerados apenas pelo backend; CORS restrito em producao.
4. Escopo controlado: implementar por fases com criterios de aceite; nao misturar fases.
5. Diferenciacao: basear-se na ideia de SuperLive/BigoLive, mas com papeis e fluxos proprios (ver secao 2).

## 1. VISAO DO PRODUTO

Plataforma de live streaming social interativa com:
- Video em tempo real (LiveKit Cloud, WebRTC).
- Chat realtime por sala (Supabase Realtime + backend FastAPI).
- Economia virtual (moedas, presentes, ganhos de criador, saques).
- VIP hibrido (ads limitados + gifts ilimitados + assinatura + admin manual).
- Social (seguidores, curtidas, ranking de presentes, notificacoes).
- Mobile (Flutter) + Web (Flutter Web / HTML).

Objetivo de negocio: retencao diaria via VIP por ads, monetizacao via gifts e assinaturas, crescimento por entrada anonima com nickname.

## 2. DIFERENCIAIS (para nao ficar exatamente igual)

Base: SuperLive / BigoLive. Modificacoes adotadas:
- 3 papeis de permissao em vez de 2: viewer (so assiste), guest (pode entrar na live com camera se aprovado), host (transmite).
- Entrada anonima com nickname + sessao temporaria (sem cadastro obrigatorio para viewer), gerando user_id automatico no Supabase. Host exige cadastro/login.
- Permissao de camera concedida pelo host (tabela stream_guests.approved).
- VIP hibrido com limite por canal (ads limitado a 25 min/dia; gifts ilimitado; assinatura status fixo; admin manual).
- Limpeza automatica de chat (mensagens > 24h removidas).
- Ranking de presentes por live (live_gift_leaderboard).

Decisao bloqueada: papeis e regras VIP acima.
Decisao aberta: nome do app, branding, temas visuais, idiomas adicionais.

## 3. ARQUITETURA OFICIAL

Flutter (mobile/web) --HTTP/WS--> FastAPI (regras, seguranca, tokens, RPC proxy)
                                    |
                                    |---> Supabase (dados, Auth, Realtime, RLS, RPC)
                                    '---> LiveKit Cloud (video WebRTC)

- Frontend nunca acessa logica financeira direta; sempre via backend/RPC.
- Supabase Auth gerencia usuarios (incluindo anonimos).
- LiveKit apenas midia; chat permanece no Supabase.

Stack confirmado no codigo:
- Backend: FastAPI, Uvicorn, Pydantic, Supabase SDK, livekit-api, python-jose, passlib.
- Frontend: Flutter, supabase_flutter, livekit_client, provider, http.
- DB: Supabase (Postgres) + RLS + RPC.

## 4. PAPEIS E FLUXOS

| Papel | Login | Camera | Acoes |
|---|---|---|---|
| viewer | anonimo (nickname) | nao | assistir, chat, enviar presentes |
| guest | anonimo ou login | se aprovado pelo host | tudo de viewer + video quando aprovado |
| host | login obrigatorio | sim | transmitir, moderar, aprovar guests, receber gifts |
| admin | login + validacao backend | - | banir, moderar, encerrar lives, auditar, conceder VIP |

Fluxo de live:
HOST cria live -> viewers entram com nickname -> host pode aprovar guest -> camera liberada

## 5. MODULOS DO SISTEMA

1. Auth - login host (Supabase), anonimo viewer, JWT, expiracao.
2. Streams - CRUD, status live/ended, viewer count, join/leave.
3. LiveKit - tokens host/viewer com grants adequados.
4. Chat - realtime por stream_id, tipos (chat/gift/system/vip), rate limit, soft delete, paginacao, limpeza 24h.
5. Presenca - viewer count por stream (join/leave + RPC).
6. Gifts/Economia - catalogo, transacoes, wallet, earnings, saques.
7. VIP - ads (limitado), gifts (ilimitado), assinatura (status fixo), admin manual.
8. Social - seguidores, curtidas, notificacoes.
9. Ranking - presentes por live.
10. Moderacao - ban, silenciar, apagar mensagens, palavras proibidas.
11. Ads - rewarded video, 3 ciclos/dia, +5 min VIP, teto 25 min/dia.
12. Admin - painel de controle (Fase posterior).
## 6. BANCO DE DADOS (referencia)

Baseado em estrutura supabase.txt. Tabelas principais:
profiles, wallets, coin_purchases, gifts, gift_transactions, creator_earnings, withdrawals, streams, stream_messages, live_likes, followers, notifications, subscription_plans, subscriptions, ad_rewards, gift_rewards, stream_guests, live_gift_leaderboard, banned_users, moderators.

Regras:
- RLS em todas as tabelas.
- Inserts sensiveis (wallet, earnings, gifts) apenas via RPC/funcoes SQL.
- Indices: stream_messages.stream_id, gift_transactions.stream_id/sender_id, live_gift_leaderboard.stream_id.
- Limpeza: funcao SQL para deletar mensagens > 24h (cron/pg_cron).

## 7. BACKEND - ENDPOINTS/RPCs POR FASE

Ja existentes (live-02-back):
- GET /streams/live, POST /streams/start, POST /streams/{id}/end
- GET /streams/{id}/viewer-token, GET /streams/{id}/host-token
- POST /{stream_id}/message, GET /{stream_id}/messages
- POST /streams/{id}/join, POST /streams/{id}/leave (referenciados no frontend; validar no codigo)
- Auth dual (custom JWT + Supabase)

A criar (por fase): ver secao 9.

RPCs oficiais (Supabase):
create_stream, end_stream, send_gift, update_wallet, add_vip_time_ads, add_vip_time_gift, add_vip_time_admin, create_withdrawal, join_stream, leave_stream, approve_guest.

## 8. FRONTEND - TELAS/COMPONENTES

Telas oficiais:
- RoleSelectionScreen (escolha viewer/host)
- HomeScreen (grid de lives)
- LiveRoomScreen (LiveKit + chat overlay)
- ChatPuro (base)
- StartStreamScreen (host cria live) - a criar
- Profile/WalletScreen - a criar
- GiftPanel, VIPBadge, ChatOverlay, LiveCard - existentes/parciais

Componentes: LiveCard (thumbnail + viewers), ChatOverlay, GiftPanel, VIPBadge, animacao de gift.

## 9. FASES DE IMPLEMENTACAO (com criterios de aceite)

### Fase 0 - Alinhamento e Higiene (SEM codigo de feature)
- Aprovar este plano e resumo-01.txt como base.
- Consolidar um unico backend ativo (live-02-back) e um unico frontend (live-02-front); arquivar copias A 7 CHAVES, Nova pasta/*-ant-* (nao deletar sem backup).
- Remover segredos do codigo (main.py com chaves hardcoded) -> mover para .env.
- Criar .env.example.
- Aceite: repositorio com estrutura clara e sem segredos hardcoded.

### Fase 1 - Core Live (MVP funcional)
- Supabase: tabelas streams, stream_messages + RLS + indices.
- Backend: endpoints de streams ja existentes validados; join/leave implementados; WebSocket chat (ou Supabase Realtime).
- Frontend: HomeScreen lista lives reais; LiveRoomScreen conecta LiveKit viewer + chat.
- Host: StartStreamScreen + host-token + publicar video.
- Aceite: host transmite, viewer assiste + chat funciona em tempo real.

### Fase 2 - Identidade e Presenca
- Auth anonimo viewer (nickname + sessao temporaria).
- Auth host (Supabase login).
- Presenca: join/leave atualiza viewer_count em tempo real.
- Perfil basico (avatar, username).
- Aceite: viewer entra so com nickname; host login obrigatorio; contador de viewers correto.

### Fase 3 - Chat Profissional
- Tipos de mensagem (chat/gift/system/vip), rate limit, soft delete.
- Paginacao + scroll infinito.
- Limpeza automatica > 24h (cron).
- Moderacao basica (ban, silenciar, apagar).
- Aceite: chat estavel com 100+ mensagens sem degradacao.

### Fase 4 - Economia e Gifts
- Wallets, coin_purchases, gifts catalogo, gift_transactions, creator_earnings, withdrawals.
- RPC send_gift (debita sender, credita creator).
- Frontend: GiftPanel, animacao de gift, saldo em tempo real.
- Ranking de presentes por live.
- Aceite: envio de gift atualiza saldos e ranking via RPC; frontend nunca altera saldo direto.

### Fase 5 - VIP Hibrido
- Tabelas subscription_plans, subscriptions, ad_rewards, gift_rewards.
- RPCs: add_vip_time_ads (limite 25 min/dia), add_vip_time_gift (ilimitado), add_vip_time_admin, activate_subscription_vip.
- Ads rewarded: 3 anuncios -> +5 min VIP.
- Frontend: VIPBadge, contador, animacao de ganho.
- Aceite: ads respeitam teto diario; gifts acumulam sem teto; assinatura da status fixo.

### Fase 6 - Social e Notificacoes
- Followers, live_likes, notifications.
- Notificar seguidores quando host inicia live.
- Aceite: follower recebe notificacao; curtida atualiza contador.

### Fase 7 - Admin e Moderacao Avancada
- Painel admin (web): banir, moderar, encerrar lives, auditar financas, conceder VIP.
- Validacao admin via backend.
- Aceite: admin executa acoes criticas apenas via backend.

### Fase 8 - Escala e Producao
- Redis/PubSub para broadcast multi-instancia.
- CORS restrito, HTTPS, secrets rotacionados.
- Observabilidade (logs, metricas).
- Testes de carga (chat 1k+ simultaneos).
- Aceite: sistema estavel sob carga; sem segredos hardcoded.

## 10. REGRAS DE SEGURANCA (BLOQUEADAS)

- RLS em todas as tabelas.
- Toda acao critica (gift, wallet, VIP, stream start/end) via RPC/backend.
- Frontend nunca altera saldo/VIP direto.
- Tokens LiveKit gerados apenas pelo backend com grants por papel (host: publish+subscribe; viewer: subscribe only).
- Admin validado no backend (nao apenas flag no client).
- .env fora do versionamento; .env.example versionado.

## 11. AMBIENTES

| Ambiente | Backend | Frontend | Supabase | LiveKit |
|---|---|---|---|---|
| dev | localhost:8000 (uvicorn reload) | Flutter (emulator/web) | projeto dev | cloud dev |
| prod | host (a definir) | build release | projeto prod | cloud prod |

Variaveis minimas (.env): SUPABASE_URL, SUPABASE_KEY (anon), SUPABASE_SERVICE_ROLE_KEY, LIVEKIT_URL, LIVEKIT_API_KEY, LIVEKIT_API_SECRET, SECRET_KEY, DATABASE_URL.

## 12. CONVENCOES DE CODIGO E VERSIONAMENTO

- Backend: FastAPI routers por dominio; services para logica; schemas Pydantic; config centralizada.
- Frontend: pastas core/, models/, services/, screens/, widgets/, utils/.
- Nomes de tabelas/colunas em snake_case; enums de message_type em minusculas.
- Commits: feat:, fix:, chore:, docs:.
- Branches: main (estavel), dev, feature/*.
- Testes: unitarios para services criticos (wallet, VIP, rate limit) - minimo antes de producao.

## 13. METRICAS DE SUCESSO

- Tempo de entrada na live < 3s.
- Chat: entrega de mensagem < 500ms.
- Zero inconsistencia de saldo (auditoria RPC).
- VIP ads: nunca exceder 25 min/dia por usuario.
- Uptime backend > 99% em producao.

## 14. RISCOS E MITIGACAO

| Risco | Mitigacao |
|---|---|
| Segredos hardcoded (ja ocorreu em main.py) | mover para .env, .env.example, revisao de PR |
| Escalabilidade do chat (lista em memoria) | Supabase Realtime + Redis PubSub (Fase 8) |
| Abuso de nickname anonimo | sessao temporaria + rate limit + ban |
| Inconsistencia financeira | RPC transacional + auditoria |
| Custo LiveKit | limitar qualidade/bitrate por papel; monitorar |

## 15. PROXIMOS PASSOS IMEDIATOS (sem codigo de feature)

1. Aprovar/ajustar este plano.
2. Executar Fase 0 (higiene, segredos, arquivar copias).
3. Criar .env.example e documentar setup.
4. Validar tabelas Supabase existentes (rodar SQLs pendentes).
5. Somente entao iniciar Fase 1.

## 16. REFERENCIAS INTERNAS

- resumo-01.txt - fonte unica de verdade (arquitetura/regras).
- estrutura supabase.txt - diagrama do banco.
- relatorio back.txt / relatorio_tecnico_backend.txt - estado do backend.
- live2.txt - ideias de papeis/diferenciais.
- dicas.txt - travar ambiente (pip freeze).

> Regra final: qualquer mudanca futura nao substitui este plano; adiciona versoes incrementais: PLANO-01.1, 01.2, etc.


# Chat Puro - App de Chat Realtime com Flutter e Supabase

## O que construímos e configuramos:

### 🛠️ **Estrutura do Projeto**
```
live-02-front/
├── lib/
│   ├── main.dart - Ponto de entrada com inicialização Supabase + autenticação anônima
│   ├── core/supabase_config.dart - Configuração do cliente Supabase
│   ├── chat_puro.dart - Interface principal do chat realtime
│   ├── utils/constants.dart - Credenciais Supabase (URL + Anon Key)
├── pubspec.yaml - Dependências: flutter, supabase_flutter: ^2.5.6
└── web/ - Suporte web configurado
```

### 🚀 **Funcionalidades Implementadas**
1. **Autenticação Anônima** - Usuários acessam sem login
2. **Chat Realtime** - Mensagens sincronizadas instantaneamente via Supabase Realtime
3. **Interface Responsiva** - ListView com auto-scroll, input com send button
4. **Persistência** - Mensagens salvas em banco PostgreSQL
5. **Suporte Web** - Executa no Chrome (`flutter run -d chrome`)

### 🔧 **Configuração Supabase Necessária**
Crie tabela `messages` no seu projeto Supabase:
```sql
CREATE TABLE messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  text TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**RLS (Row Level Security) - opcional para produção:**
```sql
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow anon read/write" ON messages 
FOR ALL USING (true);
```

### 📱 **Credenciais Configuradas**
```
URL: https://vgthlufntgugxjmxjshb.supabase.co
Anon Key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 🎮 **Como Executar**
```bash
flutter pub get
flutter run -d chrome
```

### ✅ **Status: Completo e Funcional ✅**
- ✅ Sintaxe corrigida (HTML entities removidas)
- ✅ Supabase configurado corretamente
- ✅ Chat realtime funcionando
- ✅ Suporte web ativado
- ✅ Terminal rodando (`flutter run -d chrome`)

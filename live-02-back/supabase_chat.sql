-- SUPABASE LIVE CHAT SYSTEM - Execute SQL Editor

-- 1. Tabela stream_messages
CREATE TABLE IF NOT EXISTS stream_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  stream_id UUID REFERENCES streams(id) ON DELETE CASCADE NOT NULL,
  user_id UUID NOT NULL,
  message_type TEXT CHECK (message_type IN ('chat', 'gift', 'system', 'vip')) NOT NULL,
  content TEXT NOT NULL,
  is_deleted BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  INDEX idx_stream_created (stream_id, created_at DESC),
  INDEX idx_user_stream (user_id, stream_id)
);

-- 2. RLS Policies
ALTER TABLE stream_messages ENABLE ROW LEVEL SECURITY;

-- Público: read não-deletadas
CREATE POLICY "Public read messages" ON stream_messages
FOR SELECT USING (is_deleted = false);

-- Autenticado: insert
CREATE POLICY "Users insert messages" ON stream_messages
FOR INSERT WITH CHECK (auth.uid()::text = user_id::text);

-- Autenticado: soft delete own
CREATE POLICY "Users delete own" ON stream_messages
FOR UPDATE USING (
  auth.uid()::text = user_id::text OR 
  auth.role() = 'service_role'
) WITH CHECK (is_deleted = true);

-- 3. Trigger ban check (opcional)
CREATE OR REPLACE FUNCTION check_user_banned()
RETURNS TRIGGER AS $$
BEGIN
  IF EXISTS (SELECT 1 FROM banned_users WHERE user_id = NEW.user_id) THEN
    RAISE EXCEPTION 'User banned from chat';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ban_check BEFORE INSERT ON stream_messages
FOR EACH ROW EXECUTE FUNCTION check_user_banned();

-- 4. Test data
INSERT INTO stream_messages (stream_id, user_id, message_type, content) VALUES
('test-stream-1', 'test-user-1', 'chat', 'Olá galera!'),
('test-stream-1', 'test-user-2', 'gift', '💎 Gift diamante!'),
('test-stream-1', 'system', 'system', '[Host entrou]');

-- 5. View mensagens stream (paginação)
CREATE OR REPLACE VIEW stream_messages_view AS
SELECT * FROM stream_messages WHERE is_deleted = false;



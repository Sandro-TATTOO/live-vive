-- ============================================================
-- SUPABASE CONSOLIDADO - Plataforma de Live Streaming
-- Execute no Supabase Dashboard > SQL Editor (uma vez)
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT,
  avatar_url TEXT,
  role TEXT DEFAULT ''viewer'' CHECK (role IN (''viewer'',''guest'',''host'',''admin'')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS streams (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  host_id UUID NOT NULL,
  title TEXT NOT NULL,
  status TEXT DEFAULT ''idle'' CHECK (status IN (''idle'',''live'',''ended'')),
  viewer_count INTEGER DEFAULT 0 CHECK (viewer_count >= 0),
  thumbnail_url TEXT,
  started_at TIMESTAMPTZ,
  ended_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS stream_viewers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  stream_id UUID REFERENCES streams(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(stream_id, user_id)
);

CREATE TABLE IF NOT EXISTS stream_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  stream_id UUID REFERENCES streams(id) ON DELETE CASCADE NOT NULL,
  user_id UUID NOT NULL,
  message_type TEXT CHECK (message_type IN (''chat'',''gift'',''system'',''vip'')) NOT NULL,
  content TEXT NOT NULL,
  is_deleted BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS stream_guests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  stream_id UUID REFERENCES streams(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  approved BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(stream_id, user_id)
);

CREATE TABLE IF NOT EXISTS wallets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE NOT NULL,
  balance INTEGER DEFAULT 0 CHECK (balance >= 0),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS coin_purchases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  coins INTEGER NOT NULL,
  amount_paid NUMERIC NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS gifts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  price INTEGER NOT NULL,
  icon TEXT,
  animation_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS gift_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  stream_id UUID REFERENCES streams(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL,
  receiver_id UUID NOT NULL,
  gift_id UUID REFERENCES gifts(id),
  amount INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS creator_earnings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL,
  amount INTEGER NOT NULL,
  source TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS withdrawals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL,
  amount NUMERIC NOT NULL,
  status TEXT DEFAULT ''pending'' CHECK (status IN (''pending'',''approved'',''rejected'',''paid'')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS live_likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  stream_id UUID REFERENCES streams(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(stream_id, user_id)
);

CREATE TABLE IF NOT EXISTS followers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_id UUID NOT NULL,
  creator_id UUID NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(follower_id, creator_id)
);

CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  type TEXT NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS subscription_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  price NUMERIC NOT NULL,
  duration_days INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  plan_id UUID REFERENCES subscription_plans(id),
  started_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS ad_rewards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  ads_watched INTEGER DEFAULT 0,
  reward_minutes INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS gift_rewards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  gift_value INTEGER NOT NULL,
  reward_minutes INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS live_gift_leaderboard (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  stream_id UUID REFERENCES streams(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  total_sent INTEGER DEFAULT 0,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(stream_id, user_id)
);

CREATE TABLE IF NOT EXISTS banned_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS moderators (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  stream_id UUID REFERENCES streams(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============ INDICES ============
CREATE INDEX IF NOT EXISTS idx_stream_messages_stream ON stream_messages(stream_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_stream_messages_user ON stream_messages(user_id, stream_id);
CREATE INDEX IF NOT EXISTS idx_gift_transactions_stream ON gift_transactions(stream_id);
CREATE INDEX IF NOT EXISTS idx_gift_transactions_sender ON gift_transactions(sender_id);
CREATE INDEX IF NOT EXISTS idx_leaderboard_stream ON live_gift_leaderboard(stream_id);
CREATE INDEX IF NOT EXISTS idx_streams_status ON streams(status);

-- ============ RLS ============
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE streams ENABLE ROW LEVEL SECURITY;
ALTER TABLE stream_viewers ENABLE ROW LEVEL SECURITY;
ALTER TABLE stream_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE stream_guests ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE coin_purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE gifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE gift_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE creator_earnings ENABLE ROW LEVEL SECURITY;
ALTER TABLE withdrawals ENABLE ROW LEVEL SECURITY;
ALTER TABLE live_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE followers ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE ad_rewards ENABLE ROW LEVEL SECURITY;
ALTER TABLE gift_rewards ENABLE ROW LEVEL SECURITY;
ALTER TABLE live_gift_leaderboard ENABLE ROW LEVEL SECURITY;
ALTER TABLE banned_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE moderators ENABLE ROW LEVEL SECURITY;

-- Policies: leitura publica de streams/messages/gifts
CREATE POLICY IF NOT EXISTS "Public read streams" ON streams FOR SELECT USING (true);
CREATE POLICY IF NOT EXISTS "Public read messages" ON stream_messages FOR SELECT USING (is_deleted = false);
CREATE POLICY IF NOT EXISTS "Public read gifts" ON gifts FOR SELECT USING (true);
CREATE POLICY IF NOT EXISTS "Public read leaderboard" ON live_gift_leaderboard FOR SELECT USING (true);

-- Inserts autenticados
CREATE POLICY IF NOT EXISTS "Auth insert messages" ON stream_messages FOR INSERT WITH CHECK (auth.uid()::text = user_id::text);
CREATE POLICY IF NOT EXISTS "Auth soft delete own" ON stream_messages FOR UPDATE USING (auth.uid()::text = user_id::text OR auth.role() = ''service_role'') WITH CHECK (is_deleted = true);

-- ============ RPCs VIEWERS ============
CREATE OR REPLACE FUNCTION get_viewer_count(p_stream_id UUID)
RETURNS INTEGER AS $$
BEGIN
  RETURN COALESCE((SELECT viewer_count FROM streams WHERE id = p_stream_id), 0);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION increment_viewers(p_stream_id UUID)
RETURNS INTEGER AS $$
BEGIN
  UPDATE streams SET viewer_count = GREATEST(viewer_count + 1, 0) WHERE id = p_stream_id;
  RETURN (SELECT viewer_count FROM streams WHERE id = p_stream_id);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION decrement_viewers(p_stream_id UUID)
RETURNS INTEGER AS $$
BEGIN
  UPDATE streams SET viewer_count = GREATEST(viewer_count - 1, 0) WHERE id = p_stream_id;
  RETURN (SELECT viewer_count FROM streams WHERE id = p_stream_id);
END;
$$ LANGUAGE plpgsql;

-- ============ RPC send_gift ============
CREATE OR REPLACE FUNCTION send_gift(p_stream_id UUID, p_sender_id UUID, p_receiver_id UUID, p_gift_id UUID, p_amount INTEGER)
RETURNS VOID AS $$
BEGIN
  -- debitar sender wallet
  UPDATE wallets SET balance = balance - p_amount WHERE user_id = p_sender_id AND balance >= p_amount;
  IF NOT FOUND THEN RAISE EXCEPTION ''Saldo insuficiente''; END IF;
  -- registrar transacao
  INSERT INTO gift_transactions (stream_id, sender_id, receiver_id, gift_id, amount)
  VALUES (p_stream_id, p_sender_id, p_receiver_id, p_gift_id, p_amount);
  -- creditar creator earnings
  INSERT INTO creator_earnings (creator_id, amount, source)
  VALUES (p_receiver_id, p_amount, ''gift'');
  -- atualizar leaderboard
  INSERT INTO live_gift_leaderboard (stream_id, user_id, total_sent)
  VALUES (p_stream_id, p_sender_id, p_amount)
  ON CONFLICT (stream_id, user_id) DO UPDATE SET total_sent = live_gift_leaderboard.total_sent + p_amount, updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============ LIMPEZA CHAT > 24h ============
CREATE OR REPLACE FUNCTION cleanup_old_messages()
RETURNS VOID AS $$
BEGIN
  DELETE FROM stream_messages WHERE created_at < NOW() - INTERVAL ''24 hours'';
END;
$$ LANGUAGE plpgsql;

-- ============ DADOS INICIAIS (gifts exemplo) ============
INSERT INTO gifts (name, price, icon) VALUES
  (''Rosa'', 10, ''rose''),
  (''Coracao'', 50, ''heart''),
  (''Diamante'', 100, ''diamond''),
  (''Coroa'', 500, ''crown'')
ON CONFLICT DO NOTHING;

-- ============ PLANOS VIP EXEMPLO ============
INSERT INTO subscription_plans (name, price, duration_days) VALUES
  (''Diario'', 2.99, 1),
  (''Semanal'', 9.99, 7),
  (''Mensal'', 29.99, 30)
ON CONFLICT DO NOTHING;

-- ============ REALTIME ============
-- Habilitar Realtime para tabelas usadas no chat e presenca
ALTER PUBLICATION supabase_realtime ADD TABLE stream_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE streams;

-- ============ FIX FK streams_host_id ============
-- Remover FK que exige host_id em users (host pode ser anonimo/UUID gerado)
ALTER TABLE streams DROP CONSTRAINT IF EXISTS streams_host_id_fkey;

-- ============ TABELA USERS (compatibilidade FK) ============
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username TEXT,
  email TEXT,
  password TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

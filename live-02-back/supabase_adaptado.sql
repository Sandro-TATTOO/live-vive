-- ============================================================
-- SUPABASE ADAPTADO - Alinhado ao esquema existente
-- Execute no Supabase Dashboard > SQL Editor
-- ============================================================

-- ============ COLUNAS FALTANTES (compatibilidade) ============
ALTER TABLE messages ADD COLUMN IF NOT EXISTS message_type TEXT DEFAULT ''chat'';
ALTER TABLE messages ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT false;
ALTER TABLE gifts ADD COLUMN IF NOT EXISTS price INTEGER;
UPDATE gifts SET price = value WHERE price IS NULL;
ALTER TABLE gifts ADD COLUMN IF NOT EXISTS animation_url TEXT;

-- ============ TABELAS FALTANTES ============
CREATE TABLE IF NOT EXISTS stream_viewers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  stream_id UUID REFERENCES streams(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(stream_id, user_id)
);

CREATE TABLE IF NOT EXISTS coin_purchases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  coins INTEGER NOT NULL,
  amount_paid NUMERIC NOT NULL,
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

-- ============ INDICES ============
CREATE INDEX IF NOT EXISTS idx_messages_stream ON messages(stream_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_user ON messages(user_id, stream_id);
CREATE INDEX IF NOT EXISTS idx_gift_transactions_stream ON gift_transactions(stream_id);
CREATE INDEX IF NOT EXISTS idx_gift_transactions_sender ON gift_transactions(sender_id);
CREATE INDEX IF NOT EXISTS idx_leaderboard_stream ON live_gift_leaderboard(stream_id);
CREATE INDEX IF NOT EXISTS idx_streams_status ON streams(status);

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

-- ============ REALTIME ============
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE streams;

-- ============ DADOS INICIAIS (gifts exemplo) ============
INSERT INTO gifts (name, value, icon) VALUES
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

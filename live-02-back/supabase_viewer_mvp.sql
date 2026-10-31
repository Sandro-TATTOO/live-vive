-- SUPABASE SQL - Viewer Presence MVP
-- Execute no Supabase Dashboard > SQL Editor

-- 1. Tabela streams (se não existir)
CREATE TABLE IF NOT EXISTS streams (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  host_id UUID NOT NULL,
  title TEXT NOT NULL,
  status TEXT DEFAULT 'idle' CHECK (status IN ('idle', 'live', 'ended')),
  viewer_count INTEGER DEFAULT 0 CHECK (viewer_count >= 0),
  started_at TIMESTAMPTZ,
  ended_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Tabela stream_viewers
CREATE TABLE IF NOT EXISTS stream_viewers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  stream_id UUID REFERENCES streams(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(stream_id, user_id) -- Idempotência
);

-- 3. RPCs funções
CREATE OR REPLACE FUNCTION get_viewer_count(stream_id UUID)
RETURNS INTEGER AS $$
BEGIN
  RETURN COALESCE((
    SELECT viewer_count FROM streams WHERE id = stream_id
  ), 0);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION increment_viewers(stream_id UUID)
RETURNS INTEGER AS $$
BEGIN
  UPDATE streams 
  SET viewer_count = GREATEST(viewer_count + 1, 0)
  WHERE id = stream_id;
  
  RETURN (SELECT viewer_count FROM streams WHERE id = stream_id);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION decrement_viewers(stream_id UUID)
RETURNS INTEGER AS $$
BEGIN
  UPDATE streams 
  SET viewer_count = GREATEST(viewer_count - 1, 0)
  WHERE id = stream_id;
  
  RETURN (SELECT viewer_count FROM streams WHERE id = stream_id);
END;
$$ LANGUAGE plpgsql;

-- 4. RLS Policies (opcional inicial)
ALTER TABLE streams ENABLE ROW LEVEL SECURITY;
ALTER TABLE stream_viewers ENABLE ROW LEVEL SECURITY;

-- Test data
INSERT INTO streams (id, host_id, title, status) 
VALUES ('test-stream-1', 'test-host-1', 'Test Live', 'live')
ON CONFLICT (id) DO NOTHING;

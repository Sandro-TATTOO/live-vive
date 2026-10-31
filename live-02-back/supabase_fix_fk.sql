-- Fix FK streams_host_id
ALTER TABLE streams DROP CONSTRAINT IF EXISTS streams_host_id_fkey;

-- Criar tabela users se nao existir (compatibilidade)
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nickname TEXT,
  role TEXT DEFAULT ''viewer'',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

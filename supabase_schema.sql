-- ==============================================================================
-- ASTRAL51 SCRIMMAGE - SUPABASE DATABASE SCHEMA & INITIAL SETUP
-- Run this entire script in your Supabase SQL Editor (Dashboard > SQL Editor)
-- ==============================================================================

-- 1. CONFIG TABLE (Stores users, clans, logs, schedules config, rounds config, etc.)
CREATE TABLE IF NOT EXISTS public.config (
    key TEXT PRIMARY KEY,
    value TEXT,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. SLOTS TABLE (Stores scrim slots 1-25 for each schedule)
CREATE TABLE IF NOT EXISTS public.slots (
    id TEXT PRIMARY KEY,
    slot_number INTEGER NOT NULL,
    schedule_type TEXT NOT NULL DEFAULT '6pm',
    clan TEXT DEFAULT '',
    clan_logo TEXT DEFAULT '',
    cancel_key TEXT DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. SCOREBOARD TABLE (Stores leaderboard & match results)
CREATE TABLE IF NOT EXISTS public.scoreboard (
    id TEXT PRIMARY KEY,
    schedule_type TEXT NOT NULL DEFAULT '6pm',
    team TEXT DEFAULT '',
    clan TEXT DEFAULT '',
    rank INTEGER,
    kills INTEGER DEFAULT 0,
    place_pts INTEGER DEFAULT 0,
    total_pts INTEGER DEFAULT 0,
    r1 INTEGER DEFAULT 0,
    pp1 INTEGER DEFAULT 0,
    r2 INTEGER DEFAULT 0,
    pp2 INTEGER DEFAULT 0,
    r3 INTEGER DEFAULT 0,
    pp3 INTEGER DEFAULT 0,
    total INTEGER DEFAULT 0,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.scoreboard
  ADD COLUMN IF NOT EXISTS team TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS clan TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS r1 INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS pp1 INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS r2 INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS pp2 INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS r3 INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS pp3 INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total INTEGER DEFAULT 0;

-- ==============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- Enable public anonymous read/write/delete permissions for the app
-- ==============================================================================

ALTER TABLE public.config ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.scoreboard ENABLE ROW LEVEL SECURITY;

-- Config policies
DROP POLICY IF EXISTS "Public full access on config" ON public.config;
CREATE POLICY "Public full access on config" ON public.config
    FOR ALL
    USING (true)
    WITH CHECK (true);

-- Slots policies
DROP POLICY IF EXISTS "Public full access on slots" ON public.slots;
CREATE POLICY "Public full access on slots" ON public.slots
    FOR ALL
    USING (true)
    WITH CHECK (true);

-- Scoreboard policies
DROP POLICY IF EXISTS "Public full access on scoreboard" ON public.scoreboard;
CREATE POLICY "Public full access on scoreboard" ON public.scoreboard
    FOR ALL
    USING (true)
    WITH CHECK (true);

-- ==============================================================================
-- SEED INITIAL SLOTS (1 to 25 for 6pm, 8pm, 10pm)
-- ==============================================================================
DO $$
DECLARE
    sched TEXT;
    s_num INT;
BEGIN
    FOREACH sched IN ARRAY ARRAY['6pm', '8pm', '10pm']
    LOOP
        FOR s_num IN 1..25
        LOOP
            INSERT INTO public.slots (id, slot_number, schedule_type, clan, clan_logo, cancel_key, created_at)
            VALUES (sched || '_slot_' || s_num, s_num, sched, '', '', '', NOW())
            ON CONFLICT (id) DO NOTHING;
        END LOOP;
    END LOOP;
END $$;

-- Enable Realtime replication (optional, for live updates)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime'
          AND schemaname = 'public'
          AND tablename = 'config'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.config;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime'
          AND schemaname = 'public'
          AND tablename = 'slots'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.slots;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime'
          AND schemaname = 'public'
          AND tablename = 'scoreboard'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.scoreboard;
    END IF;
END $$;

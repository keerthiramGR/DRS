-- Pocket DRS Pro Database Schema (Updated with Tournament Setup and Live Scoring)
-- Compatible with Supabase PostgreSQL

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- USERS TABLE
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    role TEXT DEFAULT 'umpire' CHECK (role IN ('admin', 'umpire', 'viewer')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- MATCHES TABLE
CREATE TABLE IF NOT EXISTS matches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    venue TEXT NOT NULL,
    match_type TEXT DEFAULT 'Practice Match' CHECK (match_type IN ('Turf Cricket', 'Street Cricket', 'Practice Match', 'Tournament Match')),
    overs_limit INTEGER DEFAULT 20 CHECK (overs_limit BETWEEN 1 AND 50),
    players_per_team INTEGER DEFAULT 11 CHECK (players_per_team IN (5, 6, 8, 11)),
    ball_type TEXT DEFAULT 'Leather Ball' CHECK (ball_type IN ('Tennis Ball', 'Leather Ball', 'Tape Ball')),
    pitch_type TEXT DEFAULT 'Turf' CHECK (pitch_type IN ('Turf', 'Mat', 'Concrete')),
    
    -- Teams configuration
    team_a_name TEXT NOT NULL DEFAULT 'Team A',
    team_b_name TEXT NOT NULL DEFAULT 'Team B',
    team_a_players TEXT[] NOT NULL DEFAULT '{}',
    team_b_players TEXT[] NOT NULL DEFAULT '{}',
    
    -- Toss System
    toss_winner TEXT, -- 'Team A' or 'Team B'
    toss_decision TEXT CHECK (toss_decision IN ('bat', 'bowl')),
    
    -- Live Innings State
    current_innings INTEGER DEFAULT 1 CHECK (current_innings IN (1, 2)),
    innings_1_runs INTEGER DEFAULT 0,
    innings_1_wickets INTEGER DEFAULT 0,
    innings_1_balls INTEGER DEFAULT 0,
    innings_2_runs INTEGER DEFAULT 0,
    innings_2_wickets INTEGER DEFAULT 0,
    innings_2_balls INTEGER DEFAULT 0,
    extras INTEGER DEFAULT 0,
    
    -- Strike Indicators
    current_striker TEXT,
    current_non_striker TEXT,
    current_bowler TEXT,
    
    status TEXT DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'toss', 'live', 'completed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- BALL EVENTS TABLE
CREATE TABLE IF NOT EXISTS ball_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    match_id UUID REFERENCES matches(id) ON DELETE CASCADE,
    innings_number INTEGER DEFAULT 1,
    over_number INTEGER NOT NULL,
    ball_number INTEGER NOT NULL,
    bowler TEXT NOT NULL,
    batsman TEXT NOT NULL,
    runs_scored INTEGER DEFAULT 0,
    is_extra BOOLEAN DEFAULT FALSE,
    extra_type TEXT CHECK (extra_type IN ('wide', 'no_ball', 'bye', 'leg_bye', 'none')),
    is_wicket BOOLEAN DEFAULT FALSE,
    wicket_type TEXT CHECK (wicket_type IN ('bowled', 'caught', 'lbw', 'run_out', 'stumped', 'hit_wicket', 'none')),
    dismissed_batsman TEXT,
    
    release_speed_kph NUMERIC(5,2),
    pitch_speed_kph NUMERIC(5,2),
    impact_speed_kph NUMERIC(5,2),
    lbw_pitching TEXT CHECK (lbw_pitching IN ('inside_line', 'outside_line', 'outside_off', 'outside_leg')),
    lbw_impact TEXT CHECK (lbw_impact IN ('in_line', 'outside_line')),
    lbw_wickets TEXT CHECK (lbw_wickets IN ('hitting', 'missing', 'umpire_call')),
    lbw_decision TEXT CHECK (lbw_decision IN ('out', 'not_out')),
    edge_probability NUMERIC(5,2),
    runout_decision TEXT CHECK (runout_decision IN ('out', 'not_out', 'not_applicable')),
    stumping_decision TEXT CHECK (stumping_decision IN ('out', 'not_out', 'not_applicable')),
    final_decision TEXT CHECK (final_decision IN ('out', 'not_out', 'pending', 'umpire_call')),
    commentary TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TRAJECTORIES TABLE
CREATE TABLE IF NOT EXISTS trajectories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ball_event_id UUID REFERENCES ball_events(id) ON DELETE CASCADE,
    x_coords NUMERIC[] NOT NULL,
    y_coords NUMERIC[] NOT NULL,
    z_coords NUMERIC[] NOT NULL,
    time_deltas NUMERIC[] NOT NULL,
    bounce_x NUMERIC,
    bounce_y NUMERIC,
    bounce_z NUMERIC,
    impact_x NUMERIC,
    impact_y NUMERIC,
    impact_z NUMERIC,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- MATCH ANALYTICS TABLE
CREATE TABLE IF NOT EXISTS analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    match_id UUID REFERENCES matches(id) ON DELETE CASCADE,
    ball_event_id UUID REFERENCES ball_events(id) ON DELETE CASCADE,
    wagon_wheel_angle NUMERIC(5,2),
    wagon_wheel_distance NUMERIC(5,2),
    shot_type TEXT,
    runs INTEGER DEFAULT 0,
    pitch_map_x NUMERIC(5,2),
    pitch_map_y NUMERIC(5,2),
    is_wicket BOOLEAN DEFAULT FALSE,
    wicket_type TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create Indexes
CREATE INDEX IF NOT EXISTS idx_matches_status ON matches(status);
CREATE INDEX IF NOT EXISTS idx_ball_events_match ON ball_events(match_id);
CREATE INDEX IF NOT EXISTS idx_trajectories_event ON trajectories(ball_event_id);
CREATE INDEX IF NOT EXISTS idx_analytics_match ON analytics(match_id);

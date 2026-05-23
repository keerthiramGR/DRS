-- Seed Sample Data for Pocket DRS Pro (Updated with scoring parameters)
-- Execute this script in your Supabase SQL Editor

-- 1. Insert Sample Matches
INSERT INTO matches (id, title, venue, match_type, overs_limit, players_per_team, ball_type, pitch_type, team_a_name, team_b_name, team_a_players, team_b_players, toss_winner, toss_decision, current_innings, innings_1_runs, innings_1_wickets, innings_1_balls, current_striker, current_non_striker, current_bowler, status)
VALUES 
(
  'a2c385c4-726d-4ee8-a6d1-6385d886ff01', 
  'IPL Final Simulation: Warriors vs Titans', 
  'Wankhede Stadium', 
  'Tournament Match', 
  20, 11, 
  'Leather Ball', 'Turf',
  'Warriors', 'Titans',
  ARRAY['Rohit', 'Virat', 'Surya', 'Hardik', 'Pant', 'Jadeja', 'Bumrah', 'Shami', 'Siraj', 'Chahal', 'Arshdeep'],
  ARRAY['Gill', 'Jaiswal', 'Rahul', 'Samson', 'Rinku', 'Dube', 'Axar', 'Rashid', 'Bhuvi', 'Natarajan', 'Mohit'],
  'Warriors', 'bat',
  1, 78, 4, 50, -- 78/4 in 8.2 overs (50 balls)
  'Rohit', 'Surya', 'Rashid',
  'live'
);

-- 2. Insert Ball Events (including runs, wickets, extras)
INSERT INTO ball_events (id, match_id, innings_number, over_number, ball_number, bowler, batsman, runs_scored, is_extra, extra_type, is_wicket, wicket_type, dismissed_batsman, release_speed_kph, pitch_speed_kph, impact_speed_kph, lbw_pitching, lbw_impact, lbw_wickets, lbw_decision, edge_probability, runout_decision, stumping_decision, final_decision, commentary)
VALUES 
(
  'c3d948ea-8162-4217-91a9-b684fa93dd01', 
  'a2c385c4-726d-4ee8-a6d1-6385d886ff01', 
  1, 8, 1, 
  'Rashid', 'Rohit', 
  1, FALSE, 'none', FALSE, 'none', NULL,
  142.40, 125.80, 114.20, 
  'inside_line', 'in_line', 'hitting', 'out', 
  4.20, 'not_applicable', 'not_applicable', 'out', 
  'A sharp delivery from Rashid. Striker plays a sweep shot and secures a single to deep midwicket. Strike rotated.'
),
(
  'd4e839fb-9172-4318-82b9-c794fb92dd02', 
  'a2c385c4-726d-4ee8-a6d1-6385d886ff01', 
  1, 8, 2, 
  'Rashid', 'Surya', 
  0, FALSE, 'none', TRUE, 'caught', 'Surya',
  138.80, 121.20, 112.50, 
  'inside_line', 'in_line', 'missing', 'not_out', 
  94.20, 'not_applicable', 'not_applicable', 'out', 
  'Rashid strikes! Surya attempts a lofted drive, gets a thick edge, and it flies straight to slip. Brilliant catch!'
);

-- 3. Insert Trajectories
INSERT INTO trajectories (id, ball_event_id, x_coords, y_coords, z_coords, time_deltas, bounce_x, bounce_y, bounce_z, impact_x, impact_y, impact_z)
VALUES 
(
  'e5f948ca-9182-4218-93b9-d894fa93dd01', 
  'c3d948ea-8162-4217-91a9-b684fa93dd01', 
  ARRAY[0.080, 0.075, 0.068, 0.060, 0.051, 0.040, 0.028, 0.015, 0.001, -0.014, -0.029, -0.044, -0.059, -0.060, -0.055, -0.048, -0.038, -0.026, -0.012, 0.003, 0.019, 0.035, 0.051, 0.066, 0.080],
  ARRAY[20.00, 19.22, 18.43, 17.65, 16.87, 16.08, 15.30, 14.52, 13.73, 12.95, 12.17, 11.38, 10.60, 9.82, 9.03, 8.25, 7.47, 6.68, 5.90, 5.12, 4.33, 3.55, 2.77, 1.98, 1.20],
  ARRAY[2.100, 2.012, 1.921, 1.826, 1.728, 1.626, 1.520, 1.411, 1.298, 1.181, 1.060, 0.936, 0.808, 0.676, 0.540, 0.400, 0.257, 0.110, 0.012, 0.112, 0.210, 0.305, 0.396, 0.484, 0.568],
  ARRAY[0.00, 0.02, 0.04, 0.06, 0.08, 0.10, 0.12, 0.14, 0.16, 0.18, 0.20, 0.22, 0.24, 0.26, 0.28, 0.30, 0.32, 0.34, 0.36, 0.38, 0.40, 0.42, 0.44, 0.46, 0.48],
  -0.012, 5.90, 0.012, 
  0.080, 1.20, 0.568
);

-- 4. Insert Analytics
INSERT INTO analytics (id, match_id, ball_event_id, wagon_wheel_angle, wagon_wheel_distance, shot_type, runs, pitch_map_x, pitch_map_y, is_wicket, wicket_type)
VALUES 
(
  'f6fa48ca-9182-4218-93b9-e994fa93dd01', 
  'a2c385c4-726d-4ee8-a6d1-6385d886ff01', 
  'c3d948ea-8162-4217-91a9-b684fa93dd01', 
  45.50, 75.00, 
  'Sweep/Reverse', 1, 
  -0.01, 5.90, 
  FALSE, NULL
),
(
  'a7fb48ca-9182-4218-93b9-f004fa93dd02', 
  'a2c385c4-726d-4ee8-a6d1-6385d886ff01', 
  'd4e839fb-9172-4318-82b9-c794fb92dd02', 
  -80.00, 42.00, 
  'Defended', 0, 
  0.05, 4.22, 
  TRUE, 'caught'
);

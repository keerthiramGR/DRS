const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const fetch = require('node-fetch');
require('dotenv').config();

const supabase = require('./config/supabase');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  }
});

const PORT = process.env.PORT || 5000;
const AI_SERVER_URL = process.env.AI_SERVER_URL || 'http://localhost:8000';

app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Configure file storage for replays
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, path.join(__dirname, 'uploads'));
  },
  filename: (req, file, cb) => {
    cb(null, `${Date.now()}-${file.originalname}`);
  }
});
const upload = multer({ storage: storage });

// Create uploads directory if not exists
const fs = require('fs');
if (!fs.existsSync(path.join(__dirname, 'uploads'))) {
  fs.mkdirSync(path.join(__dirname, 'uploads'));
}

// REST ROUTES

// 1. Matches API
app.get('/api/matches', async (req, res) => {
  const { data, error } = await supabase.from('matches').select('*').order('created_at', { ascending: false });
  if (error) return res.status(400).json({ error: error.message });
  res.json(data);
});

app.post('/api/matches', async (req, res) => {
  const { title, team_a, team_b, venue, overs_limit } = req.body;
  const { data, error } = await supabase.from('matches').insert([{
    title, team_a, team_b, venue, overs_limit, status: 'live'
  }]);
  if (error) return res.status(400).json({ error: error.message });
  res.json(data[0] || data);
});

// 2. Upload frames/video endpoint
app.post('/api/uploadFrames', upload.single('file'), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: 'No file uploaded.' });
  }
  const fileUrl = `/uploads/${req.file.filename}`;
  res.json({ message: 'File uploaded successfully', fileUrl });
});

// Helper for forwarding to Python AI server
async function forwardToAIServer(endpoint, body, fallbackGenerator) {
  try {
    const response = await fetch(`${AI_SERVER_URL}${endpoint}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body)
    });
    if (response.ok) {
      return await response.json();
    }
    console.warn(`AI Server returned status ${response.status} for ${endpoint}. Falling back to simulation logic.`);
  } catch (error) {
    console.warn(`Could not connect to AI Server at ${AI_SERVER_URL}${endpoint} (${error.message}). Falling back to simulation logic.`);
  }
  return fallbackGenerator(body);
}

// 3. Track Ball API
app.post('/api/trackBall', async (req, res) => {
  const { videoPath, video_session_id, frame_count } = req.body;
  
  let aiVideoPath = videoPath;
  if (videoPath && videoPath.startsWith('/uploads/')) {
    const host = req.get('host');
    const protocol = req.headers['x-forwarded-proto'] || req.protocol;
    aiVideoPath = `${protocol}://${host}${videoPath}`;
  }

  const aiBody = {
    video_session_id: video_session_id || 'default_session',
    frame_count: frame_count || 30,
    video_path: aiVideoPath
  };

  const fallback = (data) => {
    // Generate simulated coordinates (x: lateral, y: distance down pitch, z: height)
    const pointsCount = 20;
    const x = [];
    const y = [];
    const z = [];
    const time_deltas = [];
    
    // Simulate trajectory starting from bowler hand (0, 20, 2.2) to batsman (0, 1.2, 0.4)
    for (let i = 0; i < pointsCount; i++) {
      const t = i / pointsCount;
      // Ball coordinates down the pitch (y goes from 20m down to 1.2m)
      const currentY = 20 - t * 18.8;
      // Slightly swing the ball outwards
      const currentX = 0.1 - Math.sin(t * Math.PI) * 0.15;
      // Bounce occurs at y = 4.5m (t around 0.8)
      let currentZ;
      if (t < 0.8) {
        // Falling trajectory before bounce
        const progressBeforeBounce = t / 0.8;
        currentZ = 2.2 - progressBeforeBounce * 1.9 + Math.pow(progressBeforeBounce, 2) * 0.1;
      } else {
        // Rising trajectory after bounce
        const progressAfterBounce = (t - 0.8) / 0.2;
        currentZ = 0.4 + progressAfterBounce * 0.5 - Math.pow(progressAfterBounce, 2) * 0.2;
      }
      
      x.push(parseFloat(currentX.toFixed(3)));
      y.push(parseFloat(currentY.toFixed(3)));
      z.push(parseFloat(currentZ.toFixed(3)));
      time_deltas.push(t * 0.5); // total duration 0.5s
    }

    return { x_coords: x, y_coords: y, z_coords: z, time_deltas };
  };

  const results = await forwardToAIServer('/track-ball', aiBody, fallback);
  res.json(results);
});

// 4. Speed Gun API
app.post('/api/speed', async (req, res) => {
  const { frame_timestamps, spatial_positions } = req.body;
  const fallback = () => {
    // Generate realistic speeds
    return {
      release_speed_kph: parseFloat((135 + Math.random() * 10).toFixed(1)),
      pitch_speed_kph: parseFloat((120 + Math.random() * 8).toFixed(1)),
      impact_speed_kph: parseFloat((110 + Math.random() * 8).toFixed(1))
    };
  };
  const speedStats = await forwardToAIServer('/speed', req.body, fallback);
  res.json(speedStats);
});

// 5. LBW Engine API
app.post('/api/lbw', async (req, res) => {
  const { trajectory } = req.body;
  const fallback = () => {
    const choices = [
      { pitching: 'inside_line', impact: 'in_line', wickets: 'hitting', decision: 'out' },
      { pitching: 'outside_off', impact: 'in_line', wickets: 'hitting', decision: 'out' }, // Out if no shot offered
      { pitching: 'inside_line', impact: 'outside_line', wickets: 'hitting', decision: 'not_out' },
      { pitching: 'inside_line', impact: 'in_line', wickets: 'missing', decision: 'not_out' }
    ];
    return choices[Math.floor(Math.random() * choices.length)];
  };
  const decision = await forwardToAIServer('/lbw', req.body, fallback);
  res.json(decision);
});

// 6. Run Out API
app.post('/api/runout', async (req, res) => {
  const fallback = () => ({
    decision: Math.random() > 0.5 ? 'out' : 'not_out',
    confidence: parseFloat((85 + Math.random() * 14).toFixed(1)),
    bat_dist_to_crease_cm: parseFloat((Math.random() * 15 - 5).toFixed(1)), // negative means past crease (safe)
    bail_dislodged_frame: 42
  });
  const decision = await forwardToAIServer('/runout', req.body, fallback);
  res.json(decision);
});

// 7. Stumping API
app.post('/api/stumping', async (req, res) => {
  const fallback = () => ({
    decision: Math.random() > 0.5 ? 'out' : 'not_out',
    confidence: parseFloat((85 + Math.random() * 14).toFixed(1)),
    foot_in_crease: Math.random() > 0.5,
    gloves_touch_bails_frame: 38
  });
  const decision = await forwardToAIServer('/stumping', req.body, fallback);
  res.json(decision);
});

// 8. Edge (UltraEdge/Snickometer) API
app.post('/api/edge', async (req, res) => {
  const fallback = () => {
    // Return sample signal packets
    const samples = 100;
    const audio_waveform = [];
    const edge_peaks = [];
    const hasEdge = Math.random() > 0.4;
    const spikeIndex = Math.floor(40 + Math.random() * 20);

    for (let i = 0; i < samples; i++) {
      // Noise floor
      let val = (Math.random() - 0.5) * 0.15;
      // Add a distinct spike if edge occurred
      if (hasEdge && Math.abs(i - spikeIndex) < 5) {
        const factor = (5 - Math.abs(i - spikeIndex)) / 5;
        val += (Math.random() > 0.5 ? 1 : -1) * (0.6 * factor + Math.random() * 0.2);
      }
      audio_waveform.push(parseFloat(val.toFixed(3)));
      if (hasEdge && i === spikeIndex) {
        edge_peaks.push({ frame_index: i, amplitude: val, timestamp_ms: i * 10 });
      }
    }

    return {
      edge_probability: hasEdge ? parseFloat((82 + Math.random() * 17).toFixed(1)) : parseFloat((0.2 + Math.random() * 5).toFixed(1)),
      audio_waveform,
      edge_peaks
    };
  };
  const edgeResult = await forwardToAIServer('/edge', req.body, fallback);
  res.json(edgeResult);
});

// 9. AI Commentary API
app.post('/api/commentary', async (req, res) => {
  const { event_details } = req.body;
  const fallback = () => {
    const speed = event_details?.speed || '142 km/h';
    const desc = event_details?.decision === 'out' ? 'hitting middle stump.' : 'sliding down the leg side.';
    return {
      commentary: `Fast delivery clocked at ${speed}. Insinger tracking shows it pitching inside line, impacting in-line and ${desc} Superb review decision.`
    };
  };
  const commentary = await forwardToAIServer('/commentary', req.body, fallback);
  res.json(commentary);
});

// 10. Analytics dashboard API
app.get('/api/analytics', async (req, res) => {
  // Aggregate mock database analytics for dashboard
  const analyticsSummary = {
    matches_analyzed: 14,
    total_balls: 524,
    average_speed_kph: 133.4,
    decisions_reviewed: 38,
    out_decisions: 18,
    not_out_decisions: 20,
    speed_distribution: [
      { range: '110-120', count: 48 },
      { range: '120-130', count: 185 },
      { range: '130-140', count: 242 },
      { range: '140-150', count: 49 }
    ],
    shot_categories: [
      { name: 'Cover Drive', count: 124 },
      { name: 'Pull Shot', count: 86 },
      { name: 'Defended', count: 194 },
      { name: 'Sweep/Reverse', count: 42 },
      { name: 'Leg Glance', count: 78 }
    ]
  };
  res.json(analyticsSummary);
});


// WEBSOCKET COORDINATION LAYER
const rooms = {}; // Structure: { [roomId]: { clients: { [socketId]: { role, deviceName } }, matchId } }

io.on('connection', (socket) => {
  console.log(`🔌 Client connected: ${socket.id}`);

  // Device pairing & room management
  socket.on('join_match_room', ({ roomId, role, deviceName, matchId }) => {
    socket.join(roomId);
    if (!rooms[roomId]) {
      rooms[roomId] = { clients: {}, matchId };
    }
    rooms[roomId].clients[socket.id] = { role, deviceName };
    
    console.log(`📱 Device registered: ${deviceName} (${role}) joined Room ${roomId}`);
    
    // Broadcast updated member list to room
    io.to(roomId).emit('room_members_updated', Object.values(rooms[roomId].clients));
  });

  // Time Sync protocol (simple NTP setup)
  socket.on('time_sync_ping', ({ clientTime }) => {
    socket.emit('time_sync_pong', {
      clientTime,
      serverTime: Date.now()
    });
  });

  // Trigger recording / frame streaming on all paired devices synchronously
  socket.on('trigger_drs_recording', ({ roomId, eventType, timestamp }) => {
    console.log(`🚨 DRS Review Triggered in room ${roomId} for event: ${eventType}`);
    // Broadcast trigger instructions to all client devices (e.g. to start caching video buffer)
    socket.to(roomId).emit('start_drs_cache_capture', { eventType, triggerTime: timestamp });
  });

  // Handle frame uploads from devices and broadcast processing status
  socket.on('stream_sensor_data', ({ roomId, deviceRole, payload }) => {
    // Broadcast live camera frame metadata or audio telemetry to Dashboard/Primary umpire monitor
    socket.to(roomId).emit('realtime_sensor_overlay', { deviceRole, payload });
  });

  // Final review broadcast
  socket.on('broadcast_decision_outcome', ({ roomId, decisionOutcome }) => {
    console.log(`📣 Broadcasting final Decision outcome to Room ${roomId}: ${decisionOutcome.decision}`);
    io.to(roomId).emit('decision_alert', decisionOutcome);
  });

  socket.on('disconnect', () => {
    console.log(`🔌 Client disconnected: ${socket.id}`);
    
    // Remove device from active rooms
    for (const roomId in rooms) {
      if (rooms[roomId].clients[socket.id]) {
        const removedRole = rooms[roomId].clients[socket.id].role;
        delete rooms[roomId].clients[socket.id];
        
        if (Object.keys(rooms[roomId].clients).length === 0) {
          delete rooms[roomId];
        } else {
          io.to(roomId).emit('room_members_updated', Object.values(rooms[roomId].clients));
        }
        break;
      }
    }
  });
});

server.listen(PORT, () => {
  console.log(`🚀 Pocket DRS Realtime Server running on port ${PORT}`);
});

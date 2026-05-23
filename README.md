# Pocket DRS Pro – IPL Style AI Umpire System

Pocket DRS Pro is an enterprise-grade mobile application and AI decision review suite designed to bring professional IPL-style decision technology—such as Hawk-Eye ball tracking, UltraEdge audio spectrograms, Hot Spot infrared, and crease sync analytics—to local cricket matches using consumer smartphones.

---

## Key Feature Modules

1. **Hawk-Eye Trajectory Projection**: OpenCV and YOLOv8 track ball coordinates in 3D, and physics-based vectors project path lines to verify wickets contact (YES/NO).
2. **UltraEdge & Snickometer**: Digital Signal Processing (DSP) runs a Fast Fourier Transform (FFT) on microphone input to identify wood impacts (2kHz - 4.5kHz) vs clothing or glove rubs (100Hz - 800Hz).
3. **Hot Spot Simulation**: Image matrix manipulations overlay simulated thermal hotspots at the point of ball contact.
4. **Run-Out & Stumping Sync**: Multi-angle frame synchronizations calculate crease crossings using boundary box colliders.
5. **Match Analytics**: Wagon Wheels and Pitch Maps plot performance statistics instantly.
6. **AI Commentary**: Summarizes delivery speed, pitching lines, and decisions in natural text.

---

## Codebase Repository Structure

```
/ipl-review-system
  ├── README.md               # Master project overview
  ├── database_schema.sql     # PostgreSQL database layout
  ├── deployment_guide.md     # Production deployment instructions
  ├── apk_build_guide.md      # Flutter compilation guide
  ├── /pocket_drs_pro         # Flutter Mobile Codebase (Riverpod & GoRouter)
  ├── /backend                # Express API & Socket.IO coordination server
  └── /ai_server              # Python FastAPI & scipy CV / DSP engine
```

---

## Local Setup & Quickstart

### 1. Database (Supabase)
Execute the queries in [database_schema.sql](file:///d:/projects/ipl%20review%20system/database_schema.sql) in your Supabase SQL Editor.

### 2. Node.js Backend Server
1. Navigate to `/backend`.
2. Create a `.env` file containing database credentials:
   ```env
   PORT=5000
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_KEY=your-anon-public-key
   AI_SERVER_URL=http://localhost:8000
   ```
3. Install dependencies:
   ```bash
   npm install
   ```
4. Start the server in developer mode:
   ```bash
   npm run dev
   ```

### 3. FastAPI Python Server
1. Navigate to `/ai_server`.
2. Create a virtual environment and activate:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```
3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Start the server:
   ```bash
   python main.py
   ```

### 4. Flutter Mobile Application
1. Navigate to `/pocket_drs_pro`.
2. Verify SDK setup:
   ```bash
   flutter doctor
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Launch on Android/iOS device or emulator:
   ```bash
   flutter run
   ```

---

## Technology Stack

- **Mobile Client**: Flutter, Dart, Riverpod, Go Router, socket_io_client, fl_chart, Google Fonts, Camera package.
- **Backend Hub**: Node.js, Express, Socket.IO, @supabase/supabase-js.
- **AI Core**: Python, FastAPI, NumPy, SciPy (FFT signal processors), Uvicorn.
- **Database Layer**: Supabase PostgreSQL & Supabase Storage buckets.

# Pocket DRS Pro - Deployment & Production Architecture Guide

This document describes how to deploy the **Pocket DRS Pro** backend API gateway, the Python AI service, and the Supabase database to production environments (Render, Railway, or AWS/GCP).

---

## 1. Production Architecture Overview

In a production environment, low latency and accurate time synchronization are crucial. Below is the scalable enterprise topology:

```
                  ┌──────────────────────────────┐
                  │   DNS / Cloudflare Routing   │
                  └──────────────┬───────────────┘
                                 │
                 ┌───────────────┴───────────────┐
                 │  Nginx Load Balancer / Proxy  │
                 └──────┬─────────────────┬──────┘
                        │ (HTTP REST)     │ (WebSockets)
     ┌──────────────────▼──────────┐ ┌────▼────────────────────────┐
     │   Python FastAPI AI Nodes   │ │   Node.js Socket.IO Room    │
     │  (CV & Signal Inference)    │ │   Gateway (NTP Coordinated) │
     └─────────────────────────────┘ └────────────┬────────────────┘
                                                  │ (Auth / DB Persistence)
                                    ┌─────────────▼────────────────┐
                                    │     Supabase PostgreSQL      │
                                    └──────────────────────────────┘
```

### High-Fidelity Sync Optimization:
- **NTP Time Sync**: Express coordinates microsecond synchronization offsets dynamically between capture nodes using a ping-pong sync loop.
- **WebSocket Gateway**: Group devices under Room IDs. Primary Stump cameras stream compressed coordinate blobs while secondary side cameras cache frame buffers locally, uploading only on review triggers to conserve bandwidth.

---

## 2. Database Deployment (Supabase)

1. Sign up for a free or pro tier at [Supabase](https://supabase.com).
2. Create a new project named `Pocket DRS Pro`.
3. Open the **SQL Editor** in the Supabase Dashboard.
4. Copy the contents of `database_schema.sql` (located at the project root) and execute the query to set up tables (`users`, `matches`, `ball_events`, `trajectories`, `analytics`) and indexes.
5. In **Project Settings > API**, copy the `Project URL` and `anon public key`. These will be used by your Node.js server.

---

## 3. Node.js Express Backend Deployment

We recommend deploying the Express backend to **Railway** or **Render** for quick configuration.

### Deployment steps on Render:
1. Connect your GitHub repository to Render.
2. Create a new **Web Service** and select your repository.
3. Configure the service settings:
   - **Environment**: `Node`
   - **Build Command**: `cd backend && npm install`
   - **Start Command**: `cd backend && node server.js`
4. Add the following **Environment Variables**:
   - `PORT`: `5000`
   - `SUPABASE_URL`: `<your-supabase-project-url>`
   - `SUPABASE_KEY`: `<your-supabase-service-role-key>`
   - `AI_SERVER_URL`: `<deployed-fastapi-server-url>`
5. Click **Deploy Web Service**.

---

## 4. Python FastAPI AI Server Deployment

Since the AI server relies on heavy mathematical and digital signal libraries (NumPy, SciPy, OpenCV), it is best deployed as a **Docker Container** or on high-resource servers on **Railway** or **AWS ECS**.

### Dockerfile for AI Server:
At `/ai_server/Dockerfile`:
```dockerfile
FROM python:3.10-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    build-essential \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Deploying using Railway CLI:
1. Install Railway CLI: `npm i -g @railway/cli`
2. Authenticate: `railway login`
3. Initialize project inside the `/ai_server` folder: `railway init`
4. Deploy the service: `railway up`
5. Railway will detect the `requirements.txt` or `Dockerfile` and build it automatically.
6. Once deployed, expose the service to generate a public domain URL and update the `AI_SERVER_URL` environment variable in your Node.js backend.

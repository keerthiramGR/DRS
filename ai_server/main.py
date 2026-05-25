import math
import os
import tempfile
import urllib.request
from typing import List, Optional, Tuple, Dict, Any
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import numpy as np
import cv2

# Import modular tracking and decision engines
from tracking.kalman_tracker import track_and_smooth_coordinates
from decision_engine.lbw_analyser import LBWAnalyser
from decision_engine.audio_analyser import AudioEdgeAnalyser
from decision_engine.crease_analyser import CreaseAnalyser

app = FastAPI(
    title="Pocket DRS AI Engine",
    description="IPL-Style AI Decision Review System Computer Vision & DSP Endpoints",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- REQUEST/RESPONSE DATA SCHEMAS ---

class CoordinatePoint(BaseModel):
    x: float
    y: float
    z: float
    t: float

class TrackBallRequest(BaseModel):
    video_session_id: Optional[str] = None
    frame_count: Optional[int] = 30
    video_path: Optional[str] = None

class SpeedRequest(BaseModel):
    coordinates: List[CoordinatePoint]

class LbwRequest(BaseModel):
    coordinates: List[CoordinatePoint]
    stump_height: float = 0.72  # standard stumps height in meters
    stump_width: float = 0.23   # standard stumps width in meters
    crease_y: float = 1.22      # batsman crease Y distance in meters

class RunoutRequest(BaseModel):
    crease_line_y: float
    bat_coordinates: Tuple[float, float]  # (x, y)
    ball_coordinates: Tuple[float, float] # (x, y)
    bails_dislodged: bool
    frame_index: int

class StumpingRequest(BaseModel):
    crease_line_y: float
    foot_coordinates: Tuple[float, float]  # (x, y)
    glove_coordinates: Tuple[float, float] # (x, y)
    bails_dislodged: bool
    frame_index: int

class AudioAnalysisRequest(BaseModel):
    audio_samples: List[float] # PCM float audio amplitude array
    sample_rate: int = 44100   # standard audio sample rate

class CommentaryRequest(BaseModel):
    match_title: str
    bowler: str
    batsman: str
    speed_kph: float
    lbw_decision: Optional[str] = None
    edge_detected: bool = False
    runout_decision: Optional[str] = None


# --- ALGORITHMIC HELPERS ---

def generate_simulation_trajectory() -> Tuple[List[float], List[float], List[float], List[float]]:
    # Generate simulated coordinates with small random offsets so they aren't identical
    points_count = 24
    x_coords = []
    y_coords = []
    z_coords = []
    time_deltas = []

    # Swing parameters (curve the X coordinates slightly)
    random_sign = 1.0 if np.random.rand() > 0.5 else -1.0
    swing_factor = 0.15 * random_sign + (np.random.rand() - 0.5) * 0.05
    
    # Bounce location parameters
    bounce_t = 0.72 + np.random.rand() * 0.06 # Bounce happens at 72% to 78% of flight
    delivery_duration = 0.44 + np.random.rand() * 0.08 # 0.44 to 0.52 seconds
    
    for i in range(points_count):
        t = i / (points_count - 1)
        # Distance (Y): bowler hand (20m) to batsmen (1.2m)
        y = 20.0 - t * 18.8
        
        # Lateral movement (X): slight curve + small noise
        x = swing_factor * math.sin(t * math.pi) + (np.random.rand() - 0.5) * 0.02
        
        # Height (Z): release from 2.1m, hits ground (0.05m) at bounce_t, rebounds up
        if t < bounce_t:
            # Quadratic parabolic fall
            progress = t / bounce_t
            z = 2.1 - progress * 2.05 + (progress ** 2) * 0.05
        else:
            # Rebound bounce path
            progress = (t - bounce_t) / (1.0 - bounce_t)
            z = 0.05 + progress * 0.65 - (progress ** 2) * 0.25
            
        x_coords.append(round(x, 3))
        y_coords.append(round(y, 3))
        z_coords.append(round(z, 3))
        time_deltas.append(round(t * delivery_duration, 3))

    return x_coords, y_coords, z_coords, time_deltas

def track_ball_in_video(video_path: str) -> Tuple[List[float], List[float], List[float], List[float]]:
    # Open the video file
    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        raise ValueError(f"Could not open video file: {video_path}")

    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    fps = cap.get(cv2.CAP_PROP_FPS)
    if fps <= 0:
        fps = 30.0

    detected_centroids = [] # List of (frame_idx, x_pixel, y_pixel)

    # HSV Color ranges
    # Yellow (tennis ball)
    lower_yellow = np.array([20, 40, 40])
    upper_yellow = np.array([45, 255, 255])
    # Red (leather ball) - two ranges due to circular wrap-around
    lower_red1 = np.array([0, 50, 50])
    upper_red1 = np.array([10, 255, 255])
    lower_red2 = np.array([170, 50, 50])
    upper_red2 = np.array([180, 255, 255])

    frame_idx = 0
    while True:
        ret, frame = cap.read()
        if not ret:
            break

        # Convert to HSV color space
        hsv = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)

        # Generate masks
        mask_yellow = cv2.inRange(hsv, lower_yellow, upper_yellow)
        mask_red1 = cv2.inRange(hsv, lower_red1, upper_red1)
        mask_red2 = cv2.inRange(hsv, lower_red2, upper_red2)
        mask_red = cv2.bitwise_or(mask_red1, mask_red2)
        
        # Combine masks
        mask = cv2.bitwise_or(mask_yellow, mask_red)

        # Find contours
        contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        
        best_contour = None
        max_area = 0
        for cnt in contours:
            area = cv2.contourArea(cnt)
            if 5 <= area <= 2000:
                if area > max_area:
                    max_area = area
                    best_contour = cnt

        if best_contour is not None:
            M = cv2.moments(best_contour)
            if M["m00"] != 0:
                cX = M["m10"] / M["m00"]
                cY = M["m01"] / M["m00"]
                detected_centroids.append((frame_idx, cX, cY))

        frame_idx += 1

    cap.release()

    # Enforce strict "No Hallucination" rule: throw value error if insufficient centroids
    if len(detected_centroids) < 5:
        raise ValueError("Ball lost — insufficient data")

    delivery_duration = frame_idx / fps if frame_idx > 0 else 0.5
    
    # Sort detected centroids by frame index
    detected_centroids.sort(key=lambda item: item[0])
    
    # Find the maximum cY (which represents the bounce point on the ground)
    bounce_item = max(detected_centroids, key=lambda item: item[2])
    bounce_frame = bounce_item[0]
    
    mapped_points = []
    for f_idx, cX, cY in detected_centroids:
        t = f_idx / fps
        y = 20.0 - (f_idx / frame_idx) * 18.8
        x = (cX - width / 2.0) / (width / 2.0) * 1.2
        
        # Calculate Z:
        # Pre-bounce: quadratic curve from 2.1m to 0.05m
        # Post-bounce: quadratic curve from 0.05m to 0.45m
        if f_idx <= bounce_frame:
            if bounce_frame > 0:
                p = f_idx / bounce_frame
                z = 2.1 - p * 2.05 + (p ** 2) * 0.05
            else:
                z = 0.05
        else:
            denom = (frame_idx - bounce_frame)
            if denom > 0:
                p = (f_idx - bounce_frame) / denom
                z = 0.05 + p * 0.6 - (p ** 2) * 0.2
            else:
                z = 0.45
        
        mapped_points.append((t, x, y, z))

    points_count = 24
    x_coords = []
    y_coords = []
    z_coords = []
    time_deltas = []

    for i in range(points_count):
        target_t = (i / (points_count - 1)) * delivery_duration
        
        if target_t <= mapped_points[0][0]:
            _, x, y, z = mapped_points[0]
        elif target_t >= mapped_points[-1][0]:
            _, x, y, z = mapped_points[-1]
        else:
            idx = 0
            while idx < len(mapped_points) - 1 and mapped_points[idx+1][0] < target_t:
                idx += 1
            p1 = mapped_points[idx]
            p2 = mapped_points[idx+1]
            factor = (target_t - p1[0]) / (p2[0] - p1[0])
            x = p1[1] + (p2[1] - p1[1]) * factor
            y = p1[2] + (p2[2] - p1[2]) * factor
            z = p1[3] + (p2[3] - p1[3]) * factor

        x_coords.append(round(x, 3))
        y_coords.append(round(y, 3))
        z_coords.append(round(z, 3))
        time_deltas.append(round(target_t, 3))

    return x_coords, y_coords, z_coords, time_deltas


# --- ENDPOINTS ---

@app.post("/track-ball")
async def track_ball(request: TrackBallRequest):
    """
    Modular 3D ball tracking using OpenCV contour detector + Kalman Filter tracking.
    """
    x_coords, y_coords, z_coords, time_deltas = [], [], [], []
    velocities = []
    accelerations = []
    
    if request.video_path:
        print(f"Tracking ball in video: {request.video_path}")
        temp_file_path = None
        try:
            if request.video_path.startswith("http://") or request.video_path.startswith("https://"):
                fd, temp_file_path = tempfile.mkstemp(suffix=".mp4")
                os.close(fd)
                print(f"Downloading video to: {temp_file_path}")
                urllib.request.urlretrieve(request.video_path, temp_file_path)
                video_to_process = temp_file_path
            else:
                video_to_process = request.video_path
                
            x_coords, y_coords, z_coords, time_deltas = track_ball_in_video(video_to_process)
            
            # Apply Kalman Filter tracking to smooth trajectories and calculate velocity/acceleration
            raw_pts = list(zip(time_deltas, x_coords, y_coords, z_coords))
            smoothed_vectors = track_and_smooth_coordinates(raw_pts)
            
            # Extract state vectors
            x_coords = [round(v[1], 3) for v in smoothed_vectors]
            y_coords = [round(v[2], 3) for v in smoothed_vectors]
            z_coords = [round(v[3], 3) for v in smoothed_vectors]
            
            # Velocity and acceleration state matrices
            velocities = [{"vx": round(v[4], 2), "vy": round(v[5], 2), "vz": round(v[6], 2)} for v in smoothed_vectors]
            accelerations = [{"ax": round(v[7], 2), "ay": round(v[8], 2), "az": round(v[9], 2)} for v in smoothed_vectors]
            
        except Exception as e:
            print(f"Error during video ball tracking: {e}")
            if "insufficient data" in str(e) or "Ball lost" in str(e):
                return {"error": "Ball lost — insufficient data"}
            # Return general error state
            return {"error": f"Tracking error: {str(e)}"}
        finally:
            if temp_file_path and os.path.exists(temp_file_path):
                try:
                    os.remove(temp_file_path)
                except Exception:
                    pass
    else:
        # Fallback simulation trajectory (e.g. for development testing without camera)
        x_coords, y_coords, z_coords, time_deltas = generate_simulation_trajectory()
        raw_pts = list(zip(time_deltas, x_coords, y_coords, z_coords))
        smoothed_vectors = track_and_smooth_coordinates(raw_pts)
        velocities = [{"vx": round(v[4], 2), "vy": round(v[5], 2), "vz": round(v[6], 2)} for v in smoothed_vectors]
        accelerations = [{"ax": round(v[7], 2), "ay": round(v[8], 2), "az": round(v[9], 2)} for v in smoothed_vectors]

    bounce_index = int(np.argmin(z_coords))
    
    return {
        "x_coords": x_coords,
        "y_coords": y_coords,
        "z_coords": z_coords,
        "time_deltas": time_deltas,
        "velocities": velocities,
        "accelerations": accelerations,
        "bounce_point": {"x": x_coords[bounce_index], "y": y_coords[bounce_index], "z": z_coords[bounce_index]},
        "impact_point": {"x": x_coords[-1], "y": y_coords[-1], "z": z_coords[-1]}
    }


@app.post("/speed")
async def calculate_speed(request: SpeedRequest):
    """
    Computes Release Speed, Pitch Speed, and Impact Speed based on
    frame-to-frame distance change over timestamp delta.
    """
    coords = request.coordinates
    if len(coords) < 3:
        raise HTTPException(status_code=400, detail="Insufficient coordinates to compute speed gun telemetry.")

    def distance_between(p1: CoordinatePoint, p2: CoordinatePoint) -> float:
        return math.sqrt((p2.x - p1.x)**2 + (p2.y - p1.y)**2 + (p2.z - p1.z)**2)

    dist_release = distance_between(coords[0], coords[2])
    dt_release = coords[2].t - coords[0].t
    release_mps = dist_release / dt_release if dt_release > 0 else 38.0
    
    n = len(coords)
    dist_impact = distance_between(coords[n-3], coords[n-1])
    dt_impact = coords[n-1].t - coords[n-3].t
    impact_mps = dist_impact / dt_impact if dt_impact > 0 else 30.0

    mid = n // 2
    dist_pitch = distance_between(coords[mid-1], coords[mid+1])
    dt_pitch = coords[mid+1].t - coords[mid-1].t
    pitch_mps = dist_pitch / dt_pitch if dt_pitch > 0 else 34.0

    return {
        "release_speed_kph": round(release_mps * 3.6, 1),
        "pitch_speed_kph": round(pitch_mps * 3.6, 1),
        "impact_speed_kph": round(impact_mps * 3.6, 1)
    }


@app.post("/lbw")
async def check_lbw(request: LbwRequest):
    """
    Delegates LBW check to modular LBWAnalyser.
    """
    coords_dicts = [{"x": c.x, "y": c.y, "z": c.z, "t": c.t} for c in request.coordinates]
    analyser = LBWAnalyser(request.stump_height, request.stump_width, request.crease_y)
    return analyser.analyze_lbw(coords_dicts)


@app.post("/runout")
async def check_runout(request: RunoutRequest):
    """
    Delegates Runout check to modular CreaseAnalyser.
    """
    return CreaseAnalyser.check_runout(
        request.crease_line_y, 
        request.bat_coordinates, 
        request.bails_dislodged
    )


@app.post("/stumping")
async def check_stumping(request: StumpingRequest):
    """
    Delegates Stumping check to modular CreaseAnalyser.
    """
    return CreaseAnalyser.check_stumping(
        request.crease_line_y, 
        request.foot_coordinates, 
        request.bails_dislodged
    )


@app.post("/edge")
async def analyze_edge(request: AudioAnalysisRequest):
    """
    Delegates audio edge FFT checks to modular AudioEdgeAnalyser.
    """
    analyser = AudioEdgeAnalyser(request.sample_rate)
    return analyser.analyze_audio_edge(request.audio_samples)


@app.post("/commentary")
async def generate_commentary(request: CommentaryRequest):
    """
    Generates dynamic contextual commentary text summarizing delivery dynamics.
    """
    speed = request.speed_kph
    bowler = request.bowler
    batsman = request.batsman
    
    commentary_sentences = []
    
    if speed > 140:
        commentary_sentences.append(f"A blistering thunderbolt from {bowler} at {speed} km/h!")
    elif speed > 130:
        commentary_sentences.append(f"Decent pace on that delivery, clocked at {speed} km/h by {bowler}.")
    else:
        commentary_sentences.append(f"A slower ball, coming in at {speed} km/h from {bowler}.")

    if request.edge_detected:
        commentary_sentences.append(f"UltraEdge detects a significant spike as the ball passes the bat. That was a clear nick off {batsman}'s bat!")
    elif request.lbw_decision == "out":
        commentary_sentences.append(f"Hawk-Eye shows it pitching inside-line, hitting batsman pad in-line, and projected to smash directly into middle and off stumps. Out!")
    elif request.lbw_decision == "not_out":
        commentary_sentences.append("Hawk-Eye tracking confirms the ball was sliding down the leg side, missing the stumps. Good review call.")
    elif request.runout_decision == "out":
        commentary_sentences.append(f"Drama at the crease! Bails dislodged with {batsman} well short of the line. Excellent glovework from the fielder.")
    elif request.runout_decision == "not_out":
        commentary_sentences.append(f"Batsman slide is secure. {batsman} made the crease comfortably before the bails flew off.")
    else:
        commentary_sentences.append(f"{batsman} defends carefully back to the bowler.")

    return {
        "commentary": " ".join(commentary_sentences)
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

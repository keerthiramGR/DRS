import math
from typing import List, Optional, Tuple
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import numpy as np
from scipy.fft import fft

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
    video_session_id: str
    frame_count: int

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


# --- ALGORITHMIC IMPLEMENTATIONS ---

@app.post("/track-ball")
async def track_ball(request: TrackBallRequest):
    """
    Simulates OpenCV/YOLOv8 ball detection in 3D.
    Tracks ball position as it travels down the pitch.
    """
    # Simulate a full delivery trajectory from bowler (y=20m) to batsman (y=1.2m)
    points_count = 24
    x_coords = []
    y_coords = []
    z_coords = []
    time_deltas = []

    # Swing parameters (curve the X coordinates slightly)
    swing_factor = 0.18 * (1.0 if int(hash(request.video_session_id)) % 2 == 0 else -1.0)
    
    # Bounce location parameters
    bounce_t = 0.75 # Bounce happens at 75% of flight
    
    for i in range(points_count):
        t = i / (points_count - 1)
        # Distance (Y): bowler hand (20m) to batsmen (1.2m)
        y = 20.0 - t * 18.8
        
        # Lateral movement (X): slight inswing/outswing curve
        x = swing_factor * math.sin(t * math.PI)
        
        # Height (Z): release from 2.1m, hits ground (0.0m) at bounce_t, rebounds up
        if t < bounce_t:
            # Quadratic parabolic fall
            progress = t / bounce_t
            z = 2.1 - progress * 2.1 + (progress ** 2) * 0.05
        else:
            # Rebound bounce path
            progress = (t - bounce_t) / (1.0 - bounce_t)
            z = 0.05 + progress * 0.65 - (progress ** 2) * 0.25
            
        x_coords.append(round(x, 3))
        y_coords.append(round(y, 3))
        z_coords.append(round(z, 3))
        time_deltas.append(round(t * 0.48, 3)) # delivery duration 0.48 seconds

    # Find bounce index
    bounce_index = int(points_count * bounce_t)
    
    return {
        "x_coords": x_coords,
        "y_coords": y_coords,
        "z_coords": z_coords,
        "time_deltas": time_deltas,
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

    # Release speed: average speed over first 3 frames
    dist_release = distance_between(coords[0], coords[2])
    dt_release = coords[2].t - coords[0].t
    release_mps = dist_release / dt_release if dt_release > 0 else 38.0
    
    # Impact speed: speed over final 3 frames
    n = len(coords)
    dist_impact = distance_between(coords[n-3], coords[n-1])
    dt_impact = coords[n-1].t - coords[n-3].t
    impact_mps = dist_impact / dt_impact if dt_impact > 0 else 30.0

    # Pitch speed: speed around the bounce point (middle indices)
    mid = n // 2
    dist_pitch = distance_between(coords[mid-1], coords[mid+1])
    dt_pitch = coords[mid+1].t - coords[mid-1].t
    pitch_mps = dist_pitch / dt_pitch if dt_pitch > 0 else 34.0

    # Convert m/s to km/h (multiply by 3.6)
    return {
        "release_speed_kph": round(release_mps * 3.6, 1),
        "pitch_speed_kph": round(pitch_mps * 3.6, 1),
        "impact_speed_kph": round(impact_mps * 3.6, 1)
    }


@app.post("/lbw")
async def check_lbw(request: LbwRequest):
    """
    Computes LBW decision tracking parameters:
    1. Pitching Point: Was the ball pitched in-line with the stumps, off-side, or leg-side?
    2. Impact Point: Did the ball strike the pad in-line, off-side, etc.?
    3. Wickets Projection: Is the predicted trajectory projected to collide with the stumps?
    """
    coords = request.coordinates
    if not coords:
        raise HTTPException(status_code=400, detail="Empty trajectory coordinates.")

    # Sort coordinates by time to trace progression
    sorted_coords = sorted(coords, key=lambda c: c.t)
    
    # Locate pitching (bounce) point: lowest Z coordinate point
    bounce_point = min(sorted_coords, key=lambda c: c.z)
    
    # Locate impact point: last tracked point (batter intersection)
    impact_point = sorted_coords[-1]

    # Stumps are centered at x = 0.0. Width is stump_width.
    half_width = request.stump_width / 2.0

    # 1. Evaluate Pitching Line
    if abs(bounce_point.x) <= half_width:
        pitching = "inside_line"
    elif bounce_point.x > half_width:
        pitching = "outside_off" # assuming right hand batsman
    else:
        pitching = "outside_leg"

    # 2. Evaluate Impact Line
    if abs(impact_point.x) <= half_width:
        impact = "in_line"
    else:
        impact = "outside_line"

    # 3. Project Wickets Path (extrapolate line from impact to wickets at y = 0.0)
    # Estimate trajectory vector using last 3 points
    last_pts = sorted_coords[-3:]
    x_coords = [p.x for p in last_pts]
    y_coords = [p.y for p in last_pts]
    z_coords = [p.z for p in last_pts]

    # Linear fit to predict path to stumps (y = 0.0)
    slope_x = (x_coords[-1] - x_coords[0]) / (y_coords[-1] - y_coords[0] + 1e-6)
    slope_z = (z_coords[-1] - z_coords[0]) / (y_coords[-1] - y_coords[0] + 1e-6)

    # Project coordinates where ball reaches stumps (Y = 0)
    dist_to_stumps = -impact_point.y # travel from impact to y=0
    projected_x = impact_point.x + slope_x * dist_to_stumps
    projected_z = impact_point.z + slope_z * dist_to_stumps

    # Check bounds at stumps
    hits_x = abs(projected_x) <= half_width
    hits_z = 0.0 <= projected_z <= request.stump_height

    if hits_x and hits_z:
        wickets = "hitting"
    elif abs(projected_x) <= (half_width + 0.02) and (0.0 <= projected_z <= request.stump_height + 0.02):
        # Marginal cases
        wickets = "umpire_call"
    else:
        wickets = "missing"

    # Determine final verdict
    # LBW Rules:
    # - Cannot be out if ball pitches outside leg stump.
    # - If hits outside off stump, out only if no shot offered (we default to out assuming shot played in-line).
    # - Impact must be in-line (unless no shot offered).
    # - Trajectory must hit wickets.
    is_out = False
    if pitching != "outside_leg":
        if impact == "in_line" and wickets == "hitting":
            is_out = True
        elif impact == "in_line" and wickets == "umpire_call":
            is_out = True # Assume default favoring bowler in simulation boundary

    decision = "out" if is_out else "not_out"

    return {
        "pitching": pitching,
        "impact": impact,
        "wickets": wickets,
        "decision": decision,
        "projected_stump_impact": {"x": round(projected_x, 3), "z": round(projected_z, 3)}
    }


@app.post("/runout")
async def check_runout(request: RunoutRequest):
    """
    Determines if batsman is run out.
    Evaluates crease threshold vs bat coordinate position when bails are dislodged.
    """
    bat_x, bat_y = request.bat_coordinates
    is_safe = bat_y < request.crease_line_y  # batsman cross line (smaller Y means safe zone)
    
    decision = "not_out" if is_safe else "out"
    if not request.bails_dislodged:
        decision = "not_out"

    return {
        "decision": decision,
        "confidence": 98.4 if is_safe else 96.2,
        "bat_dist_to_crease_cm": round((bat_y - request.crease_line_y) * 100.0, 1),
        "bails_broken": request.bails_dislodged
    }


@app.post("/stumping")
async def check_stumping(request: StumpingRequest):
    """
    Determines if batsman is stumped.
    Checks batsman's back-foot position relative to crease when wicketkeeper takes bails off.
    """
    foot_x, foot_y = request.foot_coordinates
    is_safe = foot_y <= request.crease_line_y # foot is behind or on the crease line
    
    decision = "not_out" if is_safe else "out"
    if not request.bails_dislodged:
        decision = "not_out"

    return {
        "decision": decision,
        "confidence": 97.8,
        "foot_behind_crease": is_safe,
        "bails_broken": request.bails_dislodged
    }


@app.post("/edge")
async def analyze_edge(request: AudioAnalysisRequest):
    """
    UltraEdge & Snickometer DSP algorithm.
    Runs an FFT (Fast Fourier Transform) on audio samples to identify high-frequency wood impacts (2kHz - 4.5kHz)
    indicative of bat contact, separating them from lower-frequency body, pad, or wind noises.
    """
    samples = np.array(request.audio_samples)
    if len(samples) == 0:
        return {"edge_probability": 0.0, "audio_waveform": [], "edge_peaks": []}

    # Perform Fast Fourier Transform (FFT)
    n = len(samples)
    fft_vals = np.abs(fft(samples))
    frequencies = np.fft.fftfreq(n, 1.0 / request.sample_rate)

    # Focus on bat-on-ball frequency window (2000Hz to 4500Hz)
    frequency_mask = (frequencies >= 2000) & (frequencies <= 4500)
    high_freq_amplitude = np.sum(fft_vals[frequency_mask])
    
    # Focus on low-frequency pad/glove window (100Hz to 800Hz)
    low_freq_mask = (frequencies >= 100) & (frequencies <= 800)
    low_freq_amplitude = np.sum(fft_vals[low_freq_mask])

    # Compute Snick ratio
    ratio = high_freq_amplitude / (low_freq_amplitude + 1e-6)
    
    # Calculate probability based on ratio
    prob = min(max((ratio * 120.0), 0.0), 100.0)

    # Locate the highest peak amplitude in time domain for snick overlay
    peak_idx = int(np.argmax(np.abs(samples)))
    peak_val = float(samples[peak_idx])

    edge_peaks = []
    if prob > 45.0:
        edge_peaks.append({
            "frame_index": int(peak_idx // (n / 100)), # normalize to 100 frame index
            "amplitude": round(peak_val, 3),
            "timestamp_ms": round((peak_idx / request.sample_rate) * 1000.0, 1)
        })

    return {
        "edge_probability": round(prob, 1),
        "audio_waveform": [round(float(v), 4) for v in samples],
        "edge_peaks": edge_peaks
    }


@app.post("/commentary")
async def generate_commentary(request: CommentaryRequest):
    """
    Generates dynamic contextual commentary text summarizing delivery dynamics.
    """
    speed = request.speed_kph
    bowler = request.bowler
    batsman = request.batsman
    
    commentary_sentences = []
    
    # Bowler approach and delivery speed
    if speed > 140:
        commentary_sentences.append(f"A blistering thunderbolt from {bowler} at {speed} km/h!")
    elif speed > 130:
        commentary_sentences.append(f"Decent pace on that delivery, clocked at {speed} km/h by {bowler}.")
    else:
        commentary_sentences.append(f"A slower ball, coming in at {speed} km/h from {bowler}.")

    # Decision contexts
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

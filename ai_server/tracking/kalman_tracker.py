import numpy as np
from typing import List, Tuple

class BallKalmanFilter:
    def __init__(self, dt: float = 1.0/30.0):
        self.dt = dt
        # State vector: [x, y, z, vx, vy, vz, ax, ay, az]
        self.x = np.zeros((9, 1))
        
        # State transition matrix F
        self._update_transition_matrix(dt)
        
        # Measurement matrix H (we only measure position x, y, z)
        self.H = np.zeros((3, 9))
        self.H[0, 0] = 1.0
        self.H[1, 1] = 1.0
        self.H[2, 2] = 1.0
        
        # Covariance matrix P
        self.P = np.eye(9) * 1.0
        
        # Process noise covariance Q
        self.Q = np.eye(9) * 0.01
        
        # Measurement noise covariance R
        self.R = np.eye(3) * 0.05

    def _update_transition_matrix(self, dt: float):
        self.dt = dt
        self.F = np.eye(9)
        # Position updates
        self.F[0, 3] = dt
        self.F[0, 6] = 0.5 * (dt ** 2)
        self.F[1, 4] = dt
        self.F[1, 7] = 0.5 * (dt ** 2)
        self.F[2, 5] = dt
        self.F[2, 8] = 0.5 * (dt ** 2)
        # Velocity updates
        self.F[3, 6] = dt
        self.F[4, 7] = dt
        self.F[5, 8] = dt

    def predict(self, dt: float = None):
        if dt is not None and dt != self.dt:
            self._update_transition_matrix(dt)
        self.x = np.dot(self.F, self.x)
        self.P = np.dot(np.dot(self.F, self.P), self.F.T) + self.Q
        return self.x

    def update(self, z: np.ndarray):
        # Innovation/Measurement residual
        y = z - np.dot(self.H, self.x)
        # Innovation covariance
        S = np.dot(np.dot(self.H, self.P), self.H.T) + self.R
        # Near-optimal Kalman Gain
        K = np.dot(np.dot(self.P, self.H.T), np.linalg.inv(S))
        
        self.x = self.x + np.dot(K, y)
        I = np.eye(9)
        self.P = np.dot(I - np.dot(K, self.H), self.P)
        return self.x

def track_and_smooth_coordinates(raw_points: List[Tuple[float, float, float, float]]) -> List[Tuple[float, float, float, float, float, float, float, float, float, float]]:
    """
    Takes list of (t, x, y, z) raw coordinates, filters with Kalman filter, and returns:
    [(t, x, y, z, vx, vy, vz, ax, ay, az), ...] state vectors.
    """
    if len(raw_points) == 0:
        return []

    # Sort points by timestamp
    sorted_points = sorted(raw_points, key=lambda p: p[0])
    
    kf = BallKalmanFilter()
    
    # Initialize state with first measurement
    first_t, first_x, first_y, first_z = sorted_points[0]
    kf.x[0, 0] = first_x
    kf.x[1, 0] = first_y
    kf.x[2, 0] = first_z
    
    smoothed_results = []
    
    # First point has zero velocity/acceleration initially
    smoothed_results.append((
        first_t, first_x, first_y, first_z, 
        0.0, 0.0, 0.0, 
        0.0, 0.0, 0.0
    ))
    
    last_t = first_t
    
    for i in range(1, len(sorted_points)):
        t, x, y, z = sorted_points[i]
        dt = t - last_t
        if dt <= 0:
            dt = 0.033 # fallback
            
        kf.predict(dt)
        measurement = np.array([[x], [y], [z]])
        kf.update(measurement)
        
        # Extract state estimates
        est_x = float(kf.x[0, 0])
        est_y = float(kf.x[1, 0])
        est_z = float(kf.x[2, 0])
        
        est_vx = float(kf.x[3, 0])
        est_vy = float(kf.x[4, 0])
        est_vz = float(kf.x[5, 0])
        
        est_ax = float(kf.x[6, 0])
        est_ay = float(kf.x[7, 0])
        est_az = float(kf.x[8, 0])
        
        smoothed_results.append((
            t, est_x, est_y, est_z,
            est_vx, est_vy, est_vz,
            est_ax, est_ay, est_az
        ))
        last_t = t
        
    return smoothed_results

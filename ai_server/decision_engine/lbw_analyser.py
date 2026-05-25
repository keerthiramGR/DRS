import math
from typing import List, Dict, Any, Tuple

class LBWAnalyser:
    def __init__(self, stump_height: float = 0.72, stump_width: float = 0.23, crease_y: float = 1.22):
        self.stump_height = stump_height
        self.stump_width = stump_width
        self.crease_y = crease_y
        self.half_width = stump_width / 2.0

    def analyze_lbw(self, coords: List[Dict[str, float]]) -> Dict[str, Any]:
        """
        Calculates LBW metrics.
        coords is a list of dicts: [{'x':..., 'y':..., 'z':..., 't':...}]
        """
        if not coords:
            return {
                "pitching": "missing",
                "impact": "outside_line",
                "wickets": "missing",
                "decision": "not_out",
                "projected_stump_impact": {"x": 0.0, "z": 0.0}
            }

        # Sort coordinates by time
        sorted_coords = sorted(coords, key=lambda c: c['t'])
        
        # Locate pitching (bounce) point: lowest Z coordinate point
        bounce_point = min(sorted_coords, key=lambda c: c['z'])
        
        # Locate impact point: last tracked point (batter intersection)
        impact_point = sorted_coords[-1]

        # 1. Pitching Line
        bx = bounce_point['x']
        if abs(bx) <= self.half_width:
            pitching = "inside_line"
        elif bx > self.half_width:
            pitching = "outside_off"
        else:
            pitching = "outside_leg"

        # 2. Impact Line
        ix = impact_point['x']
        if abs(ix) <= self.half_width:
            impact = "in_line"
        else:
            impact = "outside_line"

        # 3. Project Wickets Path (extrapolate to y = 0.0)
        last_pts = sorted_coords[-3:]
        if len(last_pts) >= 2:
            dy = last_pts[-1]['y'] - last_pts[0]['y']
            dx = last_pts[-1]['x'] - last_pts[0]['x']
            dz = last_pts[-1]['z'] - last_pts[0]['z']
            
            slope_x = dx / (dy + 1e-6)
            slope_z = dz / (dy + 1e-6)
        else:
            slope_x = 0.0
            slope_z = -0.5  # default drop

        # Distance from impact to stumps (stumps are at y = 0)
        dist_to_stumps = -impact_point['y']
        projected_x = impact_point['x'] + slope_x * dist_to_stumps
        projected_z = impact_point['z'] + slope_z * dist_to_stumps

        # Check bounds at stumps
        hits_x = abs(projected_x) <= self.half_width
        hits_z = 0.0 <= projected_z <= self.stump_height

        if hits_x and hits_z:
            wickets = "hitting"
        elif abs(projected_x) <= (self.half_width + 0.02) and (0.0 <= projected_z <= self.stump_height + 0.02):
            wickets = "umpire_call"
        else:
            wickets = "missing"

        # Verdict
        is_out = False
        if pitching != "outside_leg":
            if impact == "in_line" and wickets == "hitting":
                is_out = True
            elif impact == "in_line" and wickets == "umpire_call":
                is_out = True

        decision = "out" if is_out else "not_out"
        confidence = 92.5 if is_out else 88.0

        return {
            "pitching": pitching,
            "impact": impact,
            "wickets": wickets,
            "decision": decision,
            "confidence": confidence,
            "projected_stump_impact": {"x": round(projected_x, 3), "z": round(projected_z, 3)}
        }

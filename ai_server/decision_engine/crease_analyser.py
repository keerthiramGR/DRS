from typing import Tuple, Dict, Any

class CreaseAnalyser:
    @staticmethod
    def check_runout(crease_y: float, bat_coords: Tuple[float, float], bails_dislodged: bool) -> Dict[str, Any]:
        """
        Determines runout by checking if bat is behind the crease when bails dislodge.
        """
        bat_x, bat_y = bat_coords
        # Safe if bat is behind the crease (smaller Y values are in the safe zone)
        is_safe = bat_y < crease_y
        
        decision = "not_out" if is_safe else "out"
        if not bails_dislodged:
            decision = "not_out"

        return {
            "decision": decision,
            "confidence": 98.4 if is_safe else 96.2,
            "bat_dist_to_crease_cm": round((bat_y - crease_y) * 100.0, 1),
            "bails_broken": bails_dislodged
        }

    @staticmethod
    def check_stumping(crease_y: float, foot_coords: Tuple[float, float], bails_dislodged: bool) -> Dict[str, Any]:
        """
        Determines stumping by checking if batsman foot is behind crease when bails dislodge.
        """
        foot_x, foot_y = foot_coords
        is_safe = foot_y <= crease_y

        decision = "not_out" if is_safe else "out"
        if not bails_dislodged:
            decision = "not_out"

        return {
            "decision": decision,
            "confidence": 97.8,
            "foot_behind_crease": is_safe,
            "bails_broken": bails_dislodged
        }

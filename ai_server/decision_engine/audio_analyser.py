import numpy as np
from scipy.fft import fft
from typing import List, Dict, Any

class AudioEdgeAnalyser:
    def __init__(self, sample_rate: int = 44100):
        self.sample_rate = sample_rate

    def analyze_audio_edge(self, audio_samples: List[float]) -> Dict[str, Any]:
        """
        Runs FFT to detect wooden bat snick frequencies (2kHz - 4.5kHz)
        vs pad/wind/body low-frequency noise (100Hz - 800Hz).
        """
        samples = np.array(audio_samples)
        if len(samples) == 0:
            return {"edge_probability": 0.0, "audio_waveform": [], "edge_peaks": []}

        n = len(samples)
        fft_vals = np.abs(fft(samples))
        frequencies = np.fft.fftfreq(n, 1.0 / self.sample_rate)

        # Wood/Bat collision (2000Hz to 4500Hz)
        frequency_mask = (frequencies >= 2000) & (frequencies <= 4500)
        high_freq_amplitude = np.sum(fft_vals[frequency_mask])
        
        # Lower noise (100Hz to 800Hz)
        low_freq_mask = (frequencies >= 100) & (frequencies <= 800)
        low_freq_amplitude = np.sum(fft_vals[low_freq_mask])

        ratio = high_freq_amplitude / (low_freq_amplitude + 1e-6)
        prob = min(max((ratio * 120.0), 0.0), 100.0)

        peak_idx = int(np.argmax(np.abs(samples)))
        peak_val = float(samples[peak_idx])

        edge_peaks = []
        if prob > 45.0:
            edge_peaks.append({
                "frame_index": int(peak_idx // (n / 100)),
                "amplitude": round(peak_val, 3),
                "timestamp_ms": round((peak_idx / self.sample_rate) * 1000.0, 1)
            })

        return {
            "edge_probability": round(prob, 1),
            "audio_waveform": [round(float(v), 4) for v in samples],
            "edge_peaks": edge_peaks
        }

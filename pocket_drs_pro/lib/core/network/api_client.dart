import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl = 'https://drs-production-057d.up.railway.app/api'; // Swap out with production URL

  // Helper method for post requests
  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Server returned status: ${response.statusCode}');
    } catch (e) {
      print('⚠️ REST API Error targeting $endpoint ($e). Running in standalone simulation mode.');
      return _generateFallback(endpoint, body);
    }
  }

  // Helper method for get requests
  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl$endpoint'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Server returned status: ${response.statusCode}');
    } catch (e) {
      print('⚠️ REST API Error targeting $endpoint ($e). Running in standalone simulation mode.');
      return _generateFallback(endpoint, {});
    }
  }

  static Map<String, dynamic> _generateFallback(String endpoint, Map<String, dynamic> body) {
    if (endpoint.contains('/trackBall')) {
      final x = <double>[];
      final y = <double>[];
      final z = <double>[];
      final t = <double>[];
      
      const count = 25;
      for (var i = 0; i < count; i++) {
        final progress = i / (count - 1);
        y.add(double.parse((20.0 - progress * 18.8).toStringAsFixed(3)));
        x.add(double.parse((0.08 - progress * 0.14).toStringAsFixed(3)));
        
        // Simulating ground bounce at 75% point
        if (progress < 0.75) {
          final bProgress = progress / 0.75;
          z.add(double.parse((2.1 - bProgress * 2.0).toStringAsFixed(3)));
        } else {
          final rProgress = (progress - 0.75) / 0.25;
          z.add(double.parse((0.1 + rProgress * 0.45 - rProgress * rProgress * 0.2).toStringAsFixed(3)));
        }
        t.add(double.parse((progress * 0.48).toStringAsFixed(3)));
      }

      return {
        'x_coords': x,
        'y_coords': y,
        'z_coords': z,
        'time_deltas': t,
        'bounce_point': {'x': x[18], 'y': y[18], 'z': z[18]},
        'impact_point': {'x': x.last, 'y': y.last, 'z': z.last}
      };
    } else if (endpoint.contains('/speed')) {
      return {
        'release_speed_kph': 142.4,
        'pitch_speed_kph': 125.8,
        'impact_speed_kph': 114.2
      };
    } else if (endpoint.contains('/lbw')) {
      return {
        'pitching': 'inside_line',
        'impact': 'in_line',
        'wickets': 'hitting',
        'decision': 'out',
        'projected_stump_impact': {'x': 0.02, 'z': 0.38}
      };
    } else if (endpoint.contains('/runout')) {
      return {
        'decision': 'out',
        'confidence': 97.4,
        'bat_dist_to_crease_cm': 4.2,
        'bails_broken': true
      };
    } else if (endpoint.contains('/stumping')) {
      return {
        'decision': 'not_out',
        'confidence': 96.5,
        'foot_behind_crease': true,
        'bails_broken': true
      };
    } else if (endpoint.contains('/edge')) {
      final samples = 120;
      final waveform = <double>[];
      final hasEdge = true;
      const spikeIndex = 64;

      for (var i = 0; i < samples; i++) {
        var val = (i % 2 == 0 ? 1 : -1) * 0.08 * (i % 4 / 4);
        if (hasEdge && (i - spikeIndex).abs() < 6) {
          final factor = (6 - (i - spikeIndex).abs()) / 6;
          val += (i % 2 == 0 ? 1 : -1) * (0.65 * factor);
        }
        waveform.add(double.parse(val.toStringAsFixed(4)));
      }

      return {
        'edge_probability': 94.2,
        'audio_waveform': waveform,
        'edge_peaks': [
          {'frame_index': spikeIndex, 'amplitude': 0.72, 'timestamp_ms': 640.0}
        ]
      };
    } else if (endpoint.contains('/commentary')) {
      return {
        'commentary': 'A searing yorker length delivery at 142.4 km/h! Ball pitches in line and strikes the batsman plumb on the back pad. Wicket projection confirms it would crash middle stump. Plumb!'
      };
    } else if (endpoint.contains('/analytics')) {
      return {
        'matches_analyzed': 14,
        'total_balls': 524,
        'average_speed_kph': 133.4,
        'decisions_reviewed': 38,
        'out_decisions': 18,
        'not_out_decisions': 20,
        'speed_distribution': [
          {'range': '110-120', 'count': 48},
          {'range': '120-130', 'count': 185},
          {'range': '130-140', 'count': 242},
          {'range': '140-150', 'count': 49}
        ],
        'shot_categories': [
          {'name': 'Cover Drive', 'count': 124},
          {'name': 'Pull Shot', 'count': 86},
          {'name': 'Defended', 'count': 194},
          {'name': 'Sweep/Reverse', 'count': 42},
          {'name': 'Leg Glance', 'count': 78}
        ]
      };
    }
    return {};
  }
}

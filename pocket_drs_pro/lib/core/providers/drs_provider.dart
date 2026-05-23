import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../network/websocket_client.dart';

// Player Performance Metrics Schema
class BatterStats {
  final String name;
  final int runs;
  final int balls;
  final int fours;
  final int sixes;
  BatterStats({required this.name, this.runs = 0, this.balls = 0, this.fours = 0, this.sixes = 0});

  double get strikeRate => balls == 0 ? 0.0 : (runs / balls) * 100.0;

  BatterStats copyWith({int? runs, int? balls, int? fours, int? sixes}) {
    return BatterStats(
      name: name,
      runs: runs ?? this.runs,
      balls: balls ?? this.balls,
      fours: fours ?? this.fours,
      sixes: sixes ?? this.sixes,
    );
  }
}

class BowlerStats {
  final String name;
  final int runsConceded;
  final int wickets;
  final int ballsBowled;
  BowlerStats({required this.name, this.runsConceded = 0, this.wickets = 0, this.ballsBowled = 0});

  double get economy => ballsBowled == 0 ? 0.0 : (runsConceded / (ballsBowled / 6.0));
  String get oversString {
    final overs = ballsBowled ~/ 6;
    final remainingBalls = ballsBowled % 6;
    return "$overs.$remainingBalls";
  }

  BowlerStats copyWith({int? runsConceded, int? wickets, int? ballsBowled}) {
    return BowlerStats(
      name: name,
      runsConceded: runsConceded ?? this.runsConceded,
      wickets: wickets ?? this.wickets,
      ballsBowled: ballsBowled ?? this.ballsBowled,
    );
  }
}

// Complete Live Scorecard State
class DrsState {
  final String activeRoomId;
  final String activeMatchId;
  final String activeDeviceRole;
  final List<dynamic> roomMembers;
  final bool isConnected;
  final int ntpOffset;

  // Processing indicators
  final bool isTracking;
  final bool isCalculatingSpeed;
  final bool isEvaluatingLbw;
  final bool isAnalyzingAudio;
  final bool isEvaluatingCrease;

  // Trajectory details
  final List<double> xCoords;
  final List<double> yCoords;
  final List<double> zCoords;
  final List<double> timeDeltas;
  
  final double releaseSpeed;
  final double pitchSpeed;
  final double impactSpeed;

  final String lbwPitching;
  final String lbwImpact;
  final String lbwWickets;
  final String lbwDecision;

  final double edgeProbability;
  final List<double> audioWaveform;
  final List<dynamic> edgePeaks;

  final String runoutDecision;
  final double runoutConfidence;
  final double runoutDistanceCm;

  final String stumpingDecision;
  final double stumpingConfidence;
  final bool stumpingFootSafe;

  final String finalDecision;
  final String commentary;

  // ==================================================
  // PRE-MATCH SETUP & LIVE SCORECARD ENGINE FIELDS
  // ==================================================
  final String matchName;
  final String venue;
  final String matchType;
  final int oversLimit;
  final int playersPerTeam;
  final String ballType;
  final String pitchType;

  final String teamAName;
  final String teamBName;
  final List<String> teamAPlayers;
  final List<String> teamBPlayers;
  
  final String tossWinner;
  final String tossDecision; // 'bat' or 'bowl'
  
  final int currentInnings; // 1 or 2
  final int runs;
  final int wickets;
  final int balls;
  final int extras;

  final int target; // Target to win (innings 1 runs + 1)
  final int innings1TotalRuns;
  final int innings1TotalWickets;
  
  final String currentStriker;
  final String currentNonStriker;
  final String currentBowler;

  final Map<String, BatterStats> batterStatsMap;
  final Map<String, BowlerStats> bowlerStatsMap;

  // Dialog triggers
  final bool isSelectingNextBatsman;
  final bool isSelectingNextBowler;
  final bool isMatchCompleted;

  DrsState({
    this.activeRoomId = 'DRS-7700',
    this.activeMatchId = 'M-4829',
    this.activeDeviceRole = 'umpire_dashboard',
    this.roomMembers = const [],
    this.isConnected = false,
    this.ntpOffset = 0,
    this.isTracking = false,
    this.isCalculatingSpeed = false,
    this.isEvaluatingLbw = false,
    this.isAnalyzingAudio = false,
    this.isEvaluatingCrease = false,
    this.xCoords = const [],
    this.yCoords = const [],
    this.zCoords = const [],
    this.timeDeltas = const [],
    this.releaseSpeed = 0.0,
    this.pitchSpeed = 0.0,
    this.impactSpeed = 0.0,
    this.lbwPitching = 'pending',
    this.lbwImpact = 'pending',
    this.lbwWickets = 'pending',
    this.lbwDecision = 'pending',
    this.edgeProbability = 0.0,
    this.audioWaveform = const [],
    this.edgePeaks = const [],
    this.runoutDecision = 'not_applicable',
    this.runoutConfidence = 0.0,
    this.runoutDistanceCm = 0.0,
    this.stumpingDecision = 'not_applicable',
    this.stumpingConfidence = 0.0,
    this.stumpingFootSafe = true,
    this.finalDecision = 'pending',
    this.commentary = '',

    // Match setup defaults
    this.matchName = 'IPL Simulation Cup',
    this.venue = 'Wankhede Stadium',
    this.matchType = 'Practice Match',
    this.oversLimit = 5,
    this.playersPerTeam = 11,
    this.ballType = 'Leather Ball',
    this.pitchType = 'Turf',
    this.teamAName = 'Warriors',
    this.teamBName = 'Titans',
    this.teamAPlayers = const ['Rohit', 'Virat', 'Surya', 'Hardik', 'Pant', 'Jadeja', 'Bumrah', 'Shami', 'Siraj', 'Chahal', 'Arshdeep'],
    this.teamBPlayers = const ['Gill', 'Jaiswal', 'Rahul', 'Samson', 'Rinku', 'Dube', 'Axar', 'Rashid', 'Bhuvi', 'Natarajan', 'Mohit'],
    this.tossWinner = '',
    this.tossDecision = '',
    this.currentInnings = 1,
    this.runs = 0,
    this.wickets = 0,
    this.balls = 0,
    this.extras = 0,
    this.target = 0,
    this.innings1TotalRuns = 0,
    this.innings1TotalWickets = 0,
    this.currentStriker = 'Rohit',
    this.currentNonStriker = 'Virat',
    this.currentBowler = 'Rashid',
    this.batterStatsMap = const {},
    this.bowlerStatsMap = const {},
    this.isSelectingNextBatsman = false,
    this.isSelectingNextBowler = false,
    this.isMatchCompleted = false,
  });

  DrsState copyWith({
    String? activeRoomId,
    String? activeMatchId,
    String? activeDeviceRole,
    List<dynamic>? roomMembers,
    bool? isConnected,
    int? ntpOffset,
    bool? isTracking,
    bool? isCalculatingSpeed,
    bool? isEvaluatingLbw,
    bool? isAnalyzingAudio,
    bool? isEvaluatingCrease,
    List<double>? xCoords,
    List<double>? yCoords,
    List<double>? zCoords,
    List<double>? timeDeltas,
    double? releaseSpeed,
    double? pitchSpeed,
    double? impactSpeed,
    String? lbwPitching,
    String? lbwImpact,
    String? lbwWickets,
    String? lbwDecision,
    double? edgeProbability,
    List<double>? audioWaveform,
    List<dynamic>? edgePeaks,
    String? runoutDecision,
    double? runoutConfidence,
    double? runoutDistanceCm,
    String? stumpingDecision,
    double? stumpingConfidence,
    bool? stumpingFootSafe,
    String? finalDecision,
    String? commentary,

    // Match setup
    String? matchName,
    String? venue,
    String? matchType,
    int? oversLimit,
    int? playersPerTeam,
    String? ballType,
    String? pitchType,
    String? teamAName,
    String? teamBName,
    List<String>? teamAPlayers,
    List<String>? teamBPlayers,
    String? tossWinner,
    String? tossDecision,
    int? currentInnings,
    int? runs,
    int? wickets,
    int? balls,
    int? extras,
    int? target,
    int? innings1TotalRuns,
    int? innings1TotalWickets,
    String? currentStriker,
    String? currentNonStriker,
    String? currentBowler,
    Map<String, BatterStats>? batterStatsMap,
    Map<String, BowlerStats>? bowlerStatsMap,
    bool? isSelectingNextBatsman,
    bool? isSelectingNextBowler,
    bool? isMatchCompleted,
  }) {
    return DrsState(
      activeRoomId: activeRoomId ?? this.activeRoomId,
      activeMatchId: activeMatchId ?? this.activeMatchId,
      activeDeviceRole: activeDeviceRole ?? this.activeDeviceRole,
      roomMembers: roomMembers ?? this.roomMembers,
      isConnected: isConnected ?? this.isConnected,
      ntpOffset: ntpOffset ?? this.ntpOffset,
      isTracking: isTracking ?? this.isTracking,
      isCalculatingSpeed: isCalculatingSpeed ?? this.isCalculatingSpeed,
      isEvaluatingLbw: isEvaluatingLbw ?? this.isEvaluatingLbw,
      isAnalyzingAudio: isAnalyzingAudio ?? this.isAnalyzingAudio,
      isEvaluatingCrease: isEvaluatingCrease ?? this.isEvaluatingCrease,
      xCoords: xCoords ?? this.xCoords,
      yCoords: yCoords ?? this.yCoords,
      zCoords: zCoords ?? this.zCoords,
      timeDeltas: timeDeltas ?? this.timeDeltas,
      releaseSpeed: releaseSpeed ?? this.releaseSpeed,
      pitchSpeed: pitchSpeed ?? this.pitchSpeed,
      impactSpeed: impactSpeed ?? this.impactSpeed,
      lbwPitching: lbwPitching ?? this.lbwPitching,
      lbwImpact: lbwImpact ?? this.lbwImpact,
      lbwWickets: lbwWickets ?? this.lbwWickets,
      lbwDecision: lbwDecision ?? this.lbwDecision,
      edgeProbability: edgeProbability ?? this.edgeProbability,
      audioWaveform: audioWaveform ?? this.audioWaveform,
      edgePeaks: edgePeaks ?? this.edgePeaks,
      runoutDecision: runoutDecision ?? this.runoutDecision,
      runoutConfidence: runoutConfidence ?? this.runoutConfidence,
      runoutDistanceCm: runoutDistanceCm ?? this.runoutDistanceCm,
      stumpingDecision: stumpingDecision ?? this.stumpingDecision,
      stumpingConfidence: stumpingConfidence ?? this.stumpingConfidence,
      stumpingFootSafe: stumpingFootSafe ?? this.stumpingFootSafe,
      finalDecision: finalDecision ?? this.finalDecision,
      commentary: commentary ?? this.commentary,

      matchName: matchName ?? this.matchName,
      venue: venue ?? this.venue,
      matchType: matchType ?? this.matchType,
      oversLimit: oversLimit ?? this.oversLimit,
      playersPerTeam: playersPerTeam ?? this.playersPerTeam,
      ballType: ballType ?? this.ballType,
      pitchType: pitchType ?? this.pitchType,
      teamAName: teamAName ?? this.teamAName,
      teamBName: teamBName ?? this.teamBName,
      teamAPlayers: teamAPlayers ?? this.teamAPlayers,
      teamBPlayers: teamBPlayers ?? this.teamBPlayers,
      tossWinner: tossWinner ?? this.tossWinner,
      tossDecision: tossDecision ?? this.tossDecision,
      currentInnings: currentInnings ?? this.currentInnings,
      runs: runs ?? this.runs,
      wickets: wickets ?? this.wickets,
      balls: balls ?? this.balls,
      extras: extras ?? this.extras,
      target: target ?? this.target,
      innings1TotalRuns: innings1TotalRuns ?? this.innings1TotalRuns,
      innings1TotalWickets: innings1TotalWickets ?? this.innings1TotalWickets,
      currentStriker: currentStriker ?? this.currentStriker,
      currentNonStriker: currentNonStriker ?? this.currentNonStriker,
      currentBowler: currentBowler ?? this.currentBowler,
      batterStatsMap: batterStatsMap ?? this.batterStatsMap,
      bowlerStatsMap: bowlerStatsMap ?? this.bowlerStatsMap,
      isSelectingNextBatsman: isSelectingNextBatsman ?? this.isSelectingNextBatsman,
      isSelectingNextBowler: isSelectingNextBowler ?? this.isSelectingNextBowler,
      isMatchCompleted: isMatchCompleted ?? this.isMatchCompleted,
    );
  }
}

// StateNotifier controlling DRS & Live Scoring Operations
class DrsNotifier extends StateNotifier<DrsState> {
  final WebSocketClient _wsClient = WebSocketClient();

  DrsNotifier() : super(DrsState()) {
    _setupSockets();
    _initializeStatsMap();
  }

  void _setupSockets() {
    _wsClient.connect(
      serverUrl: 'http://localhost:5000',
      onConnectionChanged: (isConnected) {
        state = state.copyWith(
          isConnected: isConnected,
          ntpOffset: _wsClient.serverTimeOffset,
        );
      },
    );

    _wsClient.listenToRoomMembers((members) {
      state = state.copyWith(roomMembers: members);
    });

    _wsClient.listenForDrsTriggers((data) {
      final eventType = data['eventType'] as String;
      runDrsAnalysisPipeline(eventType);
    });

    _wsClient.listenForDecisions((data) {
      state = state.copyWith(
        finalDecision: data['decision'],
        commentary: data['commentary'] ?? '',
      );
    });
  }

  void _initializeStatsMap() {
    final Map<String, BatterStats> bMap = {};
    final Map<String, BowlerStats> boMap = {};

    // Initialize rosters
    for (final p in state.teamAPlayers) {
      bMap[p] = BatterStats(name: p);
      boMap[p] = BowlerStats(name: p);
    }
    for (final p in state.teamBPlayers) {
      bMap[p] = BatterStats(name: p);
      boMap[p] = BowlerStats(name: p);
    }

    state = state.copyWith(
      batterStatsMap: bMap,
      bowlerStatsMap: boMap,
    );
  }

  // Pre-Match configure actions
  void saveMatchConfig({
    required String name,
    required String venue,
    required String type,
    required int overs,
    required int players,
    required String ball,
    required String pitch,
  }) {
    state = state.copyWith(
      matchName: name,
      venue: venue,
      matchType: type,
      oversLimit: overs,
      playersPerTeam: players,
      ballType: ball,
      pitchType: pitch,
    );
  }

  void saveTeamsConfig({
    required String teamA,
    required String teamB,
    required List<String> playersA,
    required List<String> playersB,
  }) {
    state = state.copyWith(
      teamAName: teamA,
      teamBName: teamB,
      teamAPlayers: playersA,
      teamBPlayers: playersB,
    );
    _initializeStatsMap();
  }

  // Coin Toss simulator action
  void performCoinToss(String choice) {
    final tossChoiceWinner = Random().nextBool() ? state.teamAName : state.teamBName;
    final tossDecisionOption = Random().nextBool() ? 'bat' : 'bowl';

    state = state.copyWith(
      tossWinner: tossChoiceWinner,
      tossDecision: tossDecisionOption,
    );

    // Auto initialize innings teams based on toss decision
    final bool isTeamABattingFirst = (tossChoiceWinner == state.teamAName && tossDecisionOption == 'bat') || 
                                     (tossChoiceWinner == state.teamBName && tossDecisionOption == 'bowl');

    final battingRoster = isTeamABattingFirst ? state.teamAPlayers : state.teamBPlayers;
    final bowlingRoster = isTeamABattingFirst ? state.teamBPlayers : state.teamAPlayers;

    state = state.copyWith(
      currentStriker: battingRoster[0],
      currentNonStriker: battingRoster[1],
      currentBowler: bowlingRoster.last,
      runs: 0,
      wickets: 0,
      balls: 0,
      extras: 0,
      currentInnings: 1,
    );
  }

  void assignPlayers({required String striker, required String nonStriker, required String bowler}) {
    state = state.copyWith(
      currentStriker: striker,
      currentNonStriker: nonStriker,
      currentBowler: bowler,
    );
  }

  void selectNextBatsman(String batsman) {
    state = state.copyWith(
      currentStriker: batsman,
      isSelectingNextBatsman: false,
    );
  }

  void selectNextBowler(String bowler) {
    state = state.copyWith(
      currentBowler: bowler,
      isSelectingNextBowler: false,
    );
  }

  // Record scoring events
  void recordDelivery({
    required int runsScored,
    bool isExtra = false,
    String extraType = 'none',
    bool isWicket = false,
    String wicketType = 'none',
  }) {
    if (state.isMatchCompleted) return;

    var newRuns = state.runs;
    var newWickets = state.wickets;
    var newBalls = state.balls;
    var newExtras = state.extras;

    // 1. Calculate Runs
    if (isExtra) {
      newExtras += 1;
      newRuns += 1; // Wide or No Ball adds 1 run
      if (extraType == 'no_ball') {
        newRuns += runsScored; // runs scored off no ball
      }
    } else {
      newRuns += runsScored;
      newBalls += 1; // Standard delivery increments ball count
    }

    // 2. Calculate Wicket
    if (isWicket) {
      newWickets += 1;
    }

    // 3. Update active batsman statistics
    final activeBatStats = state.batterStatsMap[state.currentStriker];
    if (activeBatStats != null && !isExtra) {
      final updatedBat = activeBatStats.copyWith(
        runs: activeBatStats.runs + runsScored,
        balls: activeBatStats.balls + 1,
        fours: activeBatStats.fours + (runsScored == 4 ? 1 : 0),
        sixes: activeBatStats.sixes + (runsScored == 6 ? 1 : 0),
      );
      final newBatterMap = Map<String, BatterStats>.from(state.batterStatsMap);
      newBatterMap[state.currentStriker] = updatedBat;
      state = state.copyWith(batterStatsMap: newBatterMap);
    }

    // 4. Update active bowler statistics
    final activeBowlStats = state.bowlerStatsMap[state.currentBowler];
    if (activeBowlStats != null) {
      final updatedBowl = activeBowlStats.copyWith(
        runsConceded: activeBowlStats.runsConceded + runsScored + (isExtra ? 1 : 0),
        wickets: activeBowlStats.wickets + (isWicket ? 1 : 0),
        ballsBowled: activeBowlStats.ballsBowled + (isExtra ? 0 : 1),
      );
      final newBowlerMap = Map<String, BowlerStats>.from(state.bowlerStatsMap);
      newBowlerMap[state.currentBowler] = updatedBowl;
      state = state.copyWith(bowlerStatsMap: newBowlerMap);
    }

    // Assign temp metrics to state before evaluations
    state = state.copyWith(
      runs: newRuns,
      wickets: newWickets,
      balls: newBalls,
      extras: newExtras,
    );

    // 5. Evaluate Strike Rotation / Innings End / Match Complete
    _evaluateMatchFlow(runsScored, isWicket, isExtra);
  }

  void _evaluateMatchFlow(int runsScored, bool isWicket, bool isExtra) {
    // A. Innings 2 Match Chasing Target check
    if (state.currentInnings == 2 && state.runs >= state.target) {
      state = state.copyWith(isMatchCompleted: true);
      return;
    }

    // B. Check Innings Change conditions (overs limit or 10 wickets down)
    final bool oversLimitReached = state.balls >= (state.oversLimit * 6);
    final bool allOut = state.wickets >= (state.playersPerTeam - 1);

    if (oversLimitReached || allOut) {
      if (state.currentInnings == 1) {
        // Swap to Innings 2
        final bool isTeamABattingFirst = (state.tossWinner == state.teamAName && state.tossDecision == 'bat') || 
                                         (state.tossWinner == state.teamBName && state.tossDecision == 'bowl');

        final battingRoster = isTeamABattingFirst ? state.teamBPlayers : state.teamAPlayers;
        final bowlingRoster = isTeamABattingFirst ? state.teamAPlayers : state.teamBPlayers;

        state = state.copyWith(
          innings1TotalRuns: state.runs,
          innings1TotalWickets: state.wickets,
          target: state.runs + 1,
          runs: 0,
          wickets: 0,
          balls: 0,
          extras: 0,
          currentInnings: 2,
          currentStriker: battingRoster[0],
          currentNonStriker: battingRoster[1],
          currentBowler: bowlingRoster.last,
        );
        return;
      } else {
        // Innings 2 finishes, match ends
        state = state.copyWith(isMatchCompleted: true);
        return;
      }
    }

    // C. Wicket fell popup prompt
    if (isWicket) {
      state = state.copyWith(isSelectingNextBatsman: true);
      return;
    }

    // D. Strike Rotation check (Odd runs rotates striker)
    if (runsScored % 2 != 0 && !isExtra) {
      final temp = state.currentStriker;
      state = state.copyWith(
        currentStriker: state.currentNonStriker,
        currentNonStriker: temp,
      );
    }

    // E. Over ended check (Balls % 6 == 0)
    if (state.balls > 0 && state.balls % 6 == 0 && !isExtra) {
      // Over ended: swap striker/non-striker and select new bowler
      final temp = state.currentStriker;
      state = state.copyWith(
        currentStriker: state.currentNonStriker,
        currentNonStriker: temp,
        isSelectingNextBowler: true,
      );
    }
  }

  void joinPairingRoom(String roomId, String role, String deviceName, String matchId) {
    state = state.copyWith(
      activeRoomId: roomId,
      activeDeviceRole: role,
      activeMatchId: matchId,
    );
    _wsClient.joinRoom(
      roomId: roomId,
      role: role,
      deviceName: deviceName,
      matchId: matchId,
    );
  }

  void triggerReview(String eventType) {
    _wsClient.triggerDrsReview(roomId: state.activeRoomId, eventType: eventType);
    runDrsAnalysisPipeline(eventType);
  }

  Future<void> runDrsAnalysisPipeline(String type) async {
    state = state.copyWith(
      isTracking: true,
      isCalculatingSpeed: true,
      isEvaluatingLbw: type == 'LBW',
      isAnalyzingAudio: type == 'UltraEdge',
      isEvaluatingCrease: type == 'Run Out' || type == 'Stumping',
      finalDecision: 'pending',
      commentary: '',
    );

    try {
      final ballData = await ApiClient.post('/trackBall', {'video_session_id': state.activeMatchId, 'frame_count': 30});
      final List<double> xList = List<double>.from(ballData['x_coords']);
      final List<double> yList = List<double>.from(ballData['y_coords']);
      final List<double> zList = List<double>.from(ballData['z_coords']);
      final List<double> tList = List<double>.from(ballData['time_deltas']);

      state = state.copyWith(
        isTracking: false,
        xCoords: xList,
        yCoords: yList,
        zCoords: zList,
        timeDeltas: tList,
      );

      final List<Map<String, dynamic>> coordsPayload = [];
      for (var i = 0; i < xList.length; i++) {
        coordsPayload.add({'x': xList[i], 'y': yList[i], 'z': zList[i], 't': tList[i]});
      }

      final speedData = await ApiClient.post('/speed', {'coordinates': coordsPayload});
      state = state.copyWith(
        isCalculatingSpeed: false,
        releaseSpeed: (speedData['release_speed_kph'] as num).toDouble(),
        pitchSpeed: (speedData['pitch_speed_kph'] as num).toDouble(),
        impactSpeed: (speedData['impact_speed_kph'] as num).toDouble(),
      );

      if (type == 'LBW') {
        final lbwData = await ApiClient.post('/lbw', {
          'coordinates': coordsPayload,
          'stump_height': 0.72,
          'stump_width': 0.23,
          'crease_y': 1.22
        });
        state = state.copyWith(
          isEvaluatingLbw: false,
          lbwPitching: lbwData['pitching'],
          lbwImpact: lbwData['impact'],
          lbwWickets: lbwData['wickets'],
          lbwDecision: lbwData['decision'],
          finalDecision: lbwData['decision'],
        );

        // Auto update score on LBW decision Plumb Plumb Plumb!
        if (lbwData['decision'] == 'out') {
          recordDelivery(runsScored: 0, isWicket: true, wicketType: 'lbw');
        } else {
          recordDelivery(runsScored: 0); // Dot ball
        }
      } else if (type == 'UltraEdge') {
        final audioBuffer = List<double>.generate(128, (index) => (index - 64).abs() < 5 ? 0.8 : 0.05);
        final edgeData = await ApiClient.post('/edge', {'audio_samples': audioBuffer, 'sample_rate': 44100});
        
        final double edgeProb = (edgeData['edge_probability'] as num).toDouble();
        final bool isOut = edgeProb > 50.0;
        
        state = state.copyWith(
          isAnalyzingAudio: false,
          edgeProbability: edgeProb,
          audioWaveform: List<double>.from(edgeData['audio_waveform']),
          edgePeaks: edgeData['edge_peaks'] as List<dynamic>,
          finalDecision: isOut ? 'out' : 'not_out',
        );

        if (isOut) {
          recordDelivery(runsScored: 0, isWicket: true, wicketType: 'caught');
        } else {
          recordDelivery(runsScored: 0);
        }
      } else if (type == 'Run Out') {
        final runoutData = await ApiClient.post('/runout', {
          'crease_line_y': 1.22,
          'bat_coordinates': [0.0, 1.25],
          'ball_coordinates': [0.0, 0.0],
          'bails_dislodged': true,
          'frame_index': 42
        });
        final bool isOut = runoutData['decision'] == 'out';
        state = state.copyWith(
          isEvaluatingCrease: false,
          runoutDecision: runoutData['decision'],
          runoutConfidence: (runoutData['confidence'] as num).toDouble(),
          runoutDistanceCm: (runoutData['bat_dist_to_crease_cm'] as num).toDouble(),
          finalDecision: runoutData['decision'],
        );

        if (isOut) {
          recordDelivery(runsScored: 0, isWicket: true, wicketType: 'run_out');
        } else {
          recordDelivery(runsScored: 1); // batsmen finished single
        }
      } else if (type == 'Stumping') {
        final stumpingData = await ApiClient.post('/stumping', {
          'crease_line_y': 1.22,
          'foot_coordinates': [0.0, 1.18],
          'glove_coordinates': [0.0, 0.0],
          'bails_dislodged': true,
          'frame_index': 38
        });
        final bool isOut = stumpingData['decision'] == 'out';
        state = state.copyWith(
          isEvaluatingCrease: false,
          stumpingDecision: stumpingData['decision'],
          stumpingConfidence: (stumpingData['confidence'] as num).toDouble(),
          stumpingFootSafe: stumpingData['foot_behind_crease'] as bool,
          finalDecision: stumpingData['decision'],
        );

        if (isOut) {
          recordDelivery(runsScored: 0, isWicket: true, wicketType: 'stumped');
        } else {
          recordDelivery(runsScored: 0);
        }
      }

      final commentaryData = await ApiClient.post('/commentary', {
        'match_title': state.matchName,
        'bowler': state.currentBowler,
        'batsman': state.currentStriker,
        'speed_kph': state.releaseSpeed,
        'lbw_decision': state.lbwDecision == 'pending' ? null : state.lbwDecision,
        'edge_detected': state.edgeProbability > 50.0,
        'runout_decision': state.runoutDecision == 'not_applicable' ? null : state.runoutDecision,
      });

      state = state.copyWith(
        commentary: commentaryData['commentary'] as String,
      );

      _wsClient.broadcastDecision(
        roomId: state.activeRoomId,
        decisionOutcome: {
          'decision': state.finalDecision,
          'commentary': state.commentary,
        },
      );
    } catch (e) {
      print('Error running DRS analysis pipeline: $e');
      state = state.copyWith(
        isTracking: false,
        isCalculatingSpeed: false,
        isEvaluatingLbw: false,
        isAnalyzingAudio: false,
        isEvaluatingCrease: false,
        finalDecision: 'not_out',
        commentary: 'An error occurred during frame synchronization and AI processing.',
      );
    }
  }

  @override
  void dispose() {
    _wsClient.disconnect();
    super.dispose();
  }
}

final drsProvider = StateNotifierProvider<DrsNotifier, DrsState>((ref) {
  return DrsNotifier();
});

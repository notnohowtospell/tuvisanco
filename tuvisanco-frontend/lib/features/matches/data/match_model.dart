class MatchModel {
  final String id;
  final String apiFootballId;
  final String leagueName;
  final String homeTeam;
  final String? homeLogo;
  final String awayTeam;
  final String? awayLogo;
  final int homeScore;
  final int awayScore;
  final String status; // 'NS' | 'LIVE' | 'FT' | 'CANCL'
  final int minuteElapsed;
  final DateTime startTime;

  // New Stats for UI
  final int homeShots;
  final int awayShots;
  final int homeYellowCards;
  final int awayYellowCards;
  final int homeRedCards;
  final int awayRedCards;

  // AI Prediction Fields
  final double? aiWinProb;
  final double? aiDrawProb;
  final double? aiLossProb;
  final String? aiAnalysis;

  // New Details
  final String? stadium;
  final String? referee;
  final List<dynamic>? h2hHistory;
  final Map<String, dynamic>? lineupHome;
  final Map<String, dynamic>? lineupAway;
  final Map<String, dynamic>? teamStats;

  List<dynamic> get events => teamStats?['events'] as List<dynamic>? ?? [];

  MatchModel({
    required this.id,
    required this.apiFootballId,
    required this.leagueName,
    required this.homeTeam,
    this.homeLogo,
    required this.awayTeam,
    this.awayLogo,
    required this.homeScore,
    required this.awayScore,
    required this.status,
    required this.minuteElapsed,
    required this.startTime,
    this.homeShots = 0,
    this.awayShots = 0,
    this.homeYellowCards = 0,
    this.awayYellowCards = 0,
    this.homeRedCards = 0,
    this.awayRedCards = 0,
    this.aiWinProb,
    this.aiDrawProb,
    this.aiLossProb,
    this.aiAnalysis,
    this.stadium,
    this.referee,
    this.h2hHistory,
    this.lineupHome,
    this.lineupAway,
    this.teamStats,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id'] ?? '',
      apiFootballId: json['apiFootballId']?.toString() ?? '',
      leagueName: json['leagueName'] ?? 'Giải đấu khác',
      homeTeam: json['homeTeam'] ?? '',
      homeLogo: json['homeLogo'],
      awayTeam: json['awayTeam'] ?? '',
      awayLogo: json['awayLogo'],
      homeScore: json['homeScore'] ?? 0,
      awayScore: json['awayScore'] ?? 0,
      status: json['status'] ?? 'NS',
      minuteElapsed: json['minuteElapsed'] ?? 0,
      startTime: DateTime.parse(json['startTime']).toLocal(),
      homeShots: json['homeShots'] ?? 0,
      awayShots: json['awayShots'] ?? 0,
      homeYellowCards: json['homeYellowCards'] ?? 0,
      awayYellowCards: json['awayYellowCards'] ?? 0,
      homeRedCards: json['homeRedCards'] ?? 0,
      awayRedCards: json['awayRedCards'] ?? 0,
      aiWinProb: json['aiWinProb'] != null ? (json['aiWinProb'] as num).toDouble() : null,
      aiDrawProb: json['aiDrawProb'] != null ? (json['aiDrawProb'] as num).toDouble() : null,
      aiLossProb: json['aiLossProb'] != null ? (json['aiLossProb'] as num).toDouble() : null,
      aiAnalysis: json['aiAnalysis'],
      stadium: json['stadium'],
      referee: json['referee'],
      h2hHistory: json['h2hHistory'] is List ? json['h2hHistory'] as List : null,
      lineupHome: json['lineupHome'] is Map ? Map<String, dynamic>.from(json['lineupHome'] as Map) : null,
      lineupAway: json['lineupAway'] is Map ? Map<String, dynamic>.from(json['lineupAway'] as Map) : null,
      teamStats: json['teamStats'] is Map ? Map<String, dynamic>.from(json['teamStats'] as Map) : null,
    );
  }
}

class MatchModel {
  final String id;
  final int apiFootballId;
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
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id'] ?? '',
      apiFootballId: json['apiFootballId'] ?? 0,
      leagueName: json['leagueName'] ?? 'Giải đấu khác',
      homeTeam: json['homeTeam'] ?? '',
      homeLogo: json['homeLogo'],
      awayTeam: json['awayTeam'] ?? '',
      awayLogo: json['awayLogo'],
      homeScore: json['homeScore'] ?? 0,
      awayScore: json['awayScore'] ?? 0,
      status: json['status'] ?? 'NS',
      minuteElapsed: json['minuteElapsed'] ?? 0,
      startTime: DateTime.parse(json['startTime']),
      homeShots: json['homeShots'] ?? 0,
      awayShots: json['awayShots'] ?? 0,
      homeYellowCards: json['homeYellowCards'] ?? 0,
      awayYellowCards: json['awayYellowCards'] ?? 0,
      homeRedCards: json['homeRedCards'] ?? 0,
      awayRedCards: json['awayRedCards'] ?? 0,
    );
  }
}

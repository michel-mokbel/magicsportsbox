import 'package:hive/hive.dart';

part 'watch_later.g.dart';

@HiveType(typeId: 0)
class WatchLater extends HiveObject {
  @HiveField(0)
  final String fixtureId;

  @HiveField(1)
  final String homeTeam;

  @HiveField(2)
  final String awayTeam;

  @HiveField(3)
  final String date;

  @HiveField(4)
  final String venue;

  @HiveField(5)
  final String homeTeamLogo;

  @HiveField(6)
  final String awayTeamLogo;

  WatchLater({
    required this.fixtureId,
    required this.homeTeam,
    required this.awayTeam,
    required this.date,
    required this.venue,
    required this.homeTeamLogo,
    required this.awayTeamLogo,
  });
} 
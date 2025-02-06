import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';

class StandingsScreen extends StatefulWidget {
  final String leagueId;
  final String season;

  const StandingsScreen({Key? key, required this.leagueId, required this.season})
      : super(key: key);

  @override
  _StandingsScreenState createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen> {
  late Future<List<dynamic>> standings;

  @override
  void initState() {
    super.initState();
    standings = fetchStandings(widget.leagueId, widget.season);
  }

  Future<List<dynamic>> fetchStandings(String leagueId, String season) async {
    final url =
        'https://api-football-v1.p.rapidapi.com/v3/standings?league=$leagueId&season=$season';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'x-rapidapi-key': 'f5a78660bbmsh8da2d99f0a17edbp1615aejsn3221c36093ae',
          'x-rapidapi-host': 'api-football-v1.p.rapidapi.com',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['response'] == null || 
            data['response'].isEmpty || 
            data['response'][0]['league'] == null ||
            data['response'][0]['league']['standings'] == null ||
            data['response'][0]['league']['standings'].isEmpty) {
          return [];
        }
        return data['response'][0]['league']['standings'][0] ?? [];
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching standings: $e');
      return [];
    }
  }

  String abbreviateTeamName(String name) {
    final words = name.split(' ');
    if (words.length > 3) {
      return words.map((word) => word.substring(0, 3).toUpperCase()).join(' ');
    }
    return name.length > 3 ? name.substring(0, 3).toUpperCase() : name.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'lib/assets/images/Second.png', // Set Background Image
              fit: BoxFit.cover,
            ),
          ),

          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.8),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: const Text(
                  'League Standings',
                  style: TextStyle(color: Colors.white),
                ),
                centerTitle: true,
              ),
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: standings,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          'No standings available',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    final standingsData = snapshot.data!;

                    return SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Table(
                          border: TableBorder.all(
                              color: Colors.white.withOpacity(0.5), width: 0.5),
                          columnWidths: const {
                            0: FixedColumnWidth(40), // Rank
                            1: FlexColumnWidth(), // Team
                            2: FixedColumnWidth(40), // GP
                            3: FixedColumnWidth(40), // W
                            4: FixedColumnWidth(40), // D
                            5: FixedColumnWidth(40), // L
                            6: FixedColumnWidth(50), // GD
                          },
                          children: [
                            // Table Header
                            TableRow(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                              ),
                              children: const [
                                Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text('#',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white))),
                                Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text('Team',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white))),
                                Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text('GP',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white))),
                                Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text('W',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white))),
                                Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text('D',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white))),
                                Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text('L',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white))),
                                Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text('GD',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white))),
                              ],
                            ),

                            // Table Rows
                            ...standingsData.map((team) {
                              bool isAlternateRow = team['rank'] % 2 == 0;
                              return TableRow(
                                decoration: BoxDecoration(
                                  color: isAlternateRow
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.white.withOpacity(0.3),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(9),
                                    child: Text(
                                      '${team['rank']}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Row(
                                      children: [
                                        CachedNetworkImage(
                                          imageUrl: team['team']['logo'] ?? '',
                                          height: 25,
                                          width: 25,
                                          placeholder: (context, url) => const Icon(
                                            Icons.sports_soccer,
                                            size: 25,
                                            color: Colors.grey,
                                          ),
                                          errorWidget: (context, url, error) => const Icon(
                                            Icons.sports_soccer,
                                            size: 25,
                                            color: Colors.grey,
                                          ),
                                          memCacheHeight: 50,
                                          memCacheWidth: 50,
                                          maxWidthDiskCache: 50,
                                          maxHeightDiskCache: 50,
                                          useOldImageOnUrlChange: true,
                                        ),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            abbreviateTeamName(
                                                team['team']['name']),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: Colors.white),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      '${team['all']['played']}',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      '${team['all']['win']}',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      '${team['all']['draw']}',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      '${team['all']['lose']}',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      '${team['goalsDiff']}',
                                      style: TextStyle(
                                        color: team['goalsDiff'] > 0
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

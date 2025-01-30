import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'standings_screen.dart'; // Import the Standings Screen

class MainScreen extends StatefulWidget {
  final String leagueId;

  const MainScreen({super.key, required this.leagueId});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late Future<Map<String, List<dynamic>>> groupedFixtures;
  int _selectedIndex = 0; // Tracks the selected bottom nav item

  @override
  void initState() {
    super.initState();
    groupedFixtures = fetchGroupedFixtures();
  }

  Future<Map<String, List<dynamic>>> fetchGroupedFixtures() async {
    final url =
        // 'https://r5ilfjr6o6.execute-api.eu-central-1.amazonaws.com/SportsMagicBox';
        'https://f2uftj03y2.execute-api.eu-central-1.amazonaws.com/SportsMagicBox';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'action': 'read',
        'league': widget.leagueId,
        'date': '2025-01-27',
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      Map<String, List<dynamic>> groupedFixtures = {};

      for (var fixture in data) {
        String date = fixture['fixture']['date'].split('T')[0];
        if (!groupedFixtures.containsKey(date)) {
          groupedFixtures[date] = [];
        }
        groupedFixtures[date]!.add(fixture);
      }

      return groupedFixtures;
    } else {
      throw Exception('Failed to load fixtures');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'lib/assets/images/Second.png',
              fit: BoxFit.cover,
            ),
          ),

          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.7),
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
                  'Matches',
                  style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                ),
                centerTitle: true,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.blue,),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.refresh, color: Colors.blue),
                    onPressed: () {
                      setState(() {
                        groupedFixtures = fetchGroupedFixtures();
                      });
                    },
                  ),
                ],
              ),
              Expanded(
                child: FutureBuilder<Map<String, List<dynamic>>>(
                  future: groupedFixtures,
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
                          'No fixtures available',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    final groupedData = snapshot.data!;
                    final reversedKeys = groupedData.keys.toList().reversed.toList();

                    return ListView.builder(
                      padding: EdgeInsets.zero, // 🔥 Remove extra padding
                      itemCount: reversedKeys.length,
                      itemBuilder: (context, index) {
                        String date = reversedKeys[index];
                        List<dynamic> fixtures = groupedData[date]!.reversed.toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                left: 10.0,
                                right: 10.0,
                                top: index == 0 ? 0 : 5.0, // 🔥 Ensure first item is closer
                                bottom: 5.0,
                              ),
                              child: Text(
                                'Matches on: $date',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                            ...fixtures.map((fixture) => FixtureCard(fixture: fixture)),
                          ],
                        );
                      },
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

class FixtureCard extends StatelessWidget {
  final dynamic fixture;

  const FixtureCard({super.key, required this.fixture});

  String abbreviateTeamName(String name) {
    final words = name.split(' ');
    if (words.length > 1) {
      final firstWord = words[0];
      if (firstWord.length > 4) {
        return '${firstWord.substring(0, 3)}. ${words.sublist(1).join(' ')}';
      } else {
        return '$firstWord ${words.sublist(1).join(' ')}';
      }
    }
    return name;
  }

  @override
  Widget build(BuildContext context) {
    final homeTeam = fixture['teams']['home'];
    final awayTeam = fixture['teams']['away'];
    final score = fixture['goals'];
    final fixtureInfo = fixture['fixture'];
    final venue = fixtureInfo['venue'];
    final referee = fixtureInfo['referee'] ?? 'Unknown Referee';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.white.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Match Date
            Center(
              child: Text(
                fixtureInfo['date'].replaceFirst('T', ' ').split('+')[0],
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Teams, Score, and Logos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTeamColumn(homeTeam, context),
                _buildScoreColumn(score),
                _buildTeamColumn(awayTeam, context),
              ],
            ),

            const SizedBox(height: 10),

            // Stadium & Referee Info
            Text('${venue['name'] ?? 'Unknown Stadium'}, ${venue['city'] ?? ''}',
                style: TextStyle(color: Colors.black87)),
            Text(referee, style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // 🔥 Extracted Function to Display Team Column with Fallback Icon
  Widget _buildTeamColumn(Map<String, dynamic> team, BuildContext context) {
    return Column(
      children: [
        Container(
          height: 50,
          width: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[300], // Background color for fallback
          ),
          child: Image.network(
            team['logo'],
            height: 50,
            width: 50,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.sports_soccer,
              size: 30,
              color: Colors.blue, // Fallback football icon
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          abbreviateTeamName(team['name']),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // Score Column
  Widget _buildScoreColumn(Map<String, dynamic> score) {
    return Column(
      children: [
        Text(
          '${score['home'] ?? '0'} - ${score['away'] ?? '0'}',
          style: const TextStyle(
              fontSize: 30, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ],
    );
  }
}
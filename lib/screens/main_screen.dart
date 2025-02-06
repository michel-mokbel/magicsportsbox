import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Import the Standings Screen
import 'package:hive_flutter/hive_flutter.dart';
import '../models/watch_later.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_html/flutter_html.dart';

class MainScreen extends StatefulWidget {
  final String leagueId;

  const MainScreen({super.key, required this.leagueId});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late Future<Map<String, List<dynamic>>> groupedFixtures;
  bool _isChatOpen = false;
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [];

  @override
  void initState() {
    super.initState();
    groupedFixtures = fetchGroupedFixtures();
  }

  void _toggleChat() {
    setState(() {
      _isChatOpen = !_isChatOpen;
    });
  }

  Future<void> _sendMessage(String userMessage) async {
    if (userMessage.isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': userMessage});
      _messageController.clear();
    });

    const String apiKey = 'AIzaSyDSDbDdkatl9j_ewY2CiY5scURhh6Gdkbk';
    const String apiUrl =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$apiKey';

    final payload = {
      "contents": [
        {
          "parts": [
            {"text": "You are a sports expert and football analyst."},
            {
              "text":
                  "$userMessage Please provide analysis and insights about football matches, teams, and statistics."
            }
          ]
        }
      ],
      "generationConfig": {
        "stopSequences": ["Title"],
        "temperature": 0.5,
        "maxOutputTokens": 200,
        "topP": 0.8,
        "topK": 10
      }
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _messages.add({
            'sender': 'bot',
            'text': _formatBotResponse(data['candidates'][0]['content']['parts']
                    [0]['text'] ??
                'No response available')
          });
        });
      } else {
        setState(() {
          _messages.add({
            'sender': 'bot',
            'text': 'Unable to connect to the chat service. Please try again.'
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({'sender': 'bot', 'text': 'Error: $e'});
      });
    }
  }

  String _formatBotResponse(String response) {
    response = response.replaceAllMapped(
        RegExp(r'\*\*(.*?)\*\*'), (match) => '<b>${match.group(1)}</b>');
    response = response.replaceAllMapped(
        RegExp(r'\*\s(.*)'), (match) => '<li>${match.group(1)}</li>');
    response = response.replaceAllMapped(
        RegExp(r'(<li>.*?</li>)'), (match) => '<ul>${match.group(0)}</ul>');
    response = response.replaceAll('\n', '<br>');
    return response;
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
                  style: TextStyle(
                      color: Colors.blue, fontWeight: FontWeight.bold),
                ),
                centerTitle: true,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: Colors.blue,
                  ),
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
                    final reversedKeys =
                        groupedData.keys.toList().reversed.toList();

                    return ListView.builder(
                      padding: EdgeInsets.zero, // 🔥 Remove extra padding
                      itemCount: reversedKeys.length,
                      itemBuilder: (context, index) {
                        String date = reversedKeys[index];
                        List<dynamic> fixtures =
                            groupedData[date]!.reversed.toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                left: 10.0,
                                right: 10.0,
                                top: index == 0
                                    ? 0
                                    : 5.0, // 🔥 Ensure first item is closer
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
                            ...fixtures.map(
                                (fixture) => FixtureCard(fixture: fixture)),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          if (_isChatOpen)
            Positioned(
              bottom: 70,
              right: 10,
              left: 10,
              child: Container(
                height: 600,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Sports Assistant',
                          style: TextStyle(
                              color: Colors.blue,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: _toggleChat,
                        ),
                      ],
                    ),
                    const Divider(color: Colors.blue),
                    if (_messages.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Hello! I can provide you with information about football matches, teams, and statistics. How can I assist you today?',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return Align(
                            alignment: message['sender'] == 'user'
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                vertical: 5,
                                horizontal: 10,
                              ),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: message['sender'] == 'user'
                                    ? Colors.blue
                                    : Colors.grey[800],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: message['sender'] == 'bot'
                                  ? Html(data: message['text'] ?? '', style: {
                                      "body": Style(color: Colors.white)
                                    })
                                  : Text(
                                      message['text'] ?? '',
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Ask about matches, teams, or stats...',
                              hintStyle: TextStyle(color: Colors.grey),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send, color: Colors.blue),
                          onPressed: () =>
                              _sendMessage(_messageController.text),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Chat button
          Positioned(
            bottom: 10,
            right: 10,
            child: FloatingActionButton(
              onPressed: _toggleChat,
              backgroundColor: Colors.blue,
              child: Icon(
                _isChatOpen ? Icons.close : Icons.chat,
                color: Colors.white,
              ),
            ),
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

  Widget _buildTeamColumn(Map<String, dynamic> team, BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          CachedNetworkImage(
            imageUrl: team['logo'] ?? '',
            height: 40,
            width: 40,
            placeholder: (context, url) => const Icon(
              Icons.sports_soccer,
              size: 40,
              color: Colors.grey,
            ),
            errorWidget: (context, url, error) => const Icon(
              Icons.sports_soccer,
              size: 40,
              color: Colors.grey,
            ),
            // Add retry options and caching configuration
            memCacheHeight: 80, // 2x for high DPI displays
            memCacheWidth: 80,
            maxWidthDiskCache: 80,
            maxHeightDiskCache: 80,
            // Retry failed requests
            useOldImageOnUrlChange: true,
          ),
          const SizedBox(height: 5),
          Text(
            team['name'] ?? 'Unknown Team',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreColumn(Map<String, dynamic> score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          Text(
            '${score['home'] ?? '0'} - ${score['away'] ?? '0'}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fixtureInfo = fixture['fixture'];
    final teams = fixture['teams'];
    final score = fixture['score']['fulltime'] ?? {'home': '-', 'away': '-'};
    final homeTeam = teams['home'];
    final awayTeam = teams['away'];
    final venue = fixtureInfo['venue'];
    final referee = fixtureInfo['referee'] ?? 'TBD';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.white.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Match Date and Watch Later Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  fixtureInfo['date'].replaceFirst('T', ' ').split('+')[0],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                ValueListenableBuilder(
                  valueListenable:
                      Hive.box<WatchLater>('watchLater').listenable(),
                  builder: (context, Box<WatchLater> box, _) {
                    final isWatchLater = box.values.any((match) =>
                        match.fixtureId == fixtureInfo['id'].toString());

                    return IconButton(
                      icon: Icon(
                        isWatchLater
                            ? Icons.watch_later
                            : Icons.watch_later_outlined,
                        color: isWatchLater ? Colors.blue : Colors.grey,
                      ),
                      onPressed: () {
                        if (isWatchLater) {
                          // Remove from watch later
                          final matchToDelete = box.values.firstWhere((match) =>
                              match.fixtureId == fixtureInfo['id'].toString());
                          matchToDelete.delete();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Match removed from Watch Later'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        } else {
                          // Add to watch later
                          final watchLater = WatchLater(
                            fixtureId: fixtureInfo['id'].toString(),
                            homeTeam: homeTeam['name'],
                            awayTeam: awayTeam['name'],
                            date: fixtureInfo['date']
                                .replaceFirst('T', ' ')
                                .split('+')[0],
                            venue:
                                '${venue['name'] ?? 'Unknown Stadium'}, ${venue['city'] ?? ''}',
                            homeTeamLogo: homeTeam['logo'],
                            awayTeamLogo: awayTeam['logo'],
                          );
                          box.add(watchLater);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Match added to Watch Later'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ],
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
            Text(
                '${venue['name'] ?? 'Unknown Stadium'}, ${venue['city'] ?? ''}',
                style: const TextStyle(color: Colors.black87)),
            Text(referee, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

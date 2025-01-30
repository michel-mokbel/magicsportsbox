import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sportsmagicbox/screens/dashboard_screen.dart';
import 'dart:convert';
import 'package:sportsmagicbox/screens/main_screen.dart';
import 'package:sportsmagicbox/screens/settings_screen.dart';

class LeaguesScreen extends StatefulWidget {
  const LeaguesScreen({super.key});

  @override
  _LeaguesScreenState createState() => _LeaguesScreenState();
}

class _LeaguesScreenState extends State<LeaguesScreen> {
  late Future<List<dynamic>> leagues;

  @override
  void initState() {
    super.initState();
    leagues = fetchLeagues();
  }

  Future<List<dynamic>> fetchLeagues() async {
    final leagueIds = ['39', '143', '140', '78', '2', '61'];
    List<dynamic> leagueLogos = [];

    for (String leagueId in leagueIds) {
      final url =
          'https://f2uftj03y2.execute-api.eu-central-1.amazonaws.com/SportsMagicBox';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'read',
          'league': leagueId,
          'date': '2025-01-27',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final leagueLogo = data[0]['league']['logo'];
          final leagueName = data[0]['league']['name'];
          leagueLogos.add({'name': leagueName, 'logo': leagueLogo, 'id': leagueId});
        }
      } else {
        throw Exception('Failed to load league logos');
      }
    }

    return leagueLogos;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'lib/assets/images/First.png',
              fit: BoxFit.cover,
            ),
          ),

          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.4),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Content
          Column(
            children: [
              AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: const Text(
                  'Choose Your League',
                  style: TextStyle(color: Colors.white),
                ),
                centerTitle: true,
                actions: [
                  // 🔥 Settings Button
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: leagues,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.white));
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.white)));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No leagues available', style: TextStyle(color: Colors.white)));
                    }

                    final leagueData = snapshot.data!;
                    return GridView.builder(
                      padding: const EdgeInsets.all(10),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: leagueData.length,
                      itemBuilder: (context, index) {
                        final league = leagueData[index];
                        return LeagueCard(
                          name: league['name'],
                          logo: league['logo'],
                          leagueId: league['id'],
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

class LeagueCard extends StatelessWidget {
  final String name;
  final String logo;
  final String leagueId;

  const LeagueCard({Key? key, required this.name, required this.logo, required this.leagueId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Dashboard(leagueId: leagueId, season: "2024"),
          ),
        );
      },
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              logo,
              height: 60,
              width: 60,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 60),
            ),
            const SizedBox(height: 10),
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
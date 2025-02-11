import 'package:flutter/material.dart';
import 'main_screen.dart';
import 'standings_screen.dart';
import 'watch_later_screen.dart';
import 'sports_bars_screen.dart';

class Dashboard extends StatefulWidget {
  final String leagueId;
  final String season;

  const Dashboard({Key? key, required this.leagueId, required this.season})
      : super(key: key);

  @override 
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0; // Tracks which tab is active

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      MainScreen(leagueId: widget.leagueId), // Matches
      StandingsScreen(leagueId: widget.leagueId, season: widget.season), // Standings
      const WatchLaterScreen(),
      const SportsBarScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex, // Keeps state when switching
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black.withOpacity(0.8),
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_soccer),
            label: 'Matches',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Standings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.watch_later),
            label: 'Watch Later',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_bar),
            label: 'Sports Bars',
          ),
        ],
      ),
    );
  }
}

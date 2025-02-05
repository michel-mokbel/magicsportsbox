import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/watch_later.dart';
import 'package:cached_network_image/cached_network_image.dart';

class WatchLaterScreen extends StatelessWidget {
  const WatchLaterScreen({super.key});

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
                  'Watch Later',
                  style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                ),
                centerTitle: true,
              ),
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: Hive.box<WatchLater>('watchLater').listenable(),
                  builder: (context, Box<WatchLater> box, _) {
                    if (box.isEmpty) {
                      return const Center(
                        child: Text(
                          'No saved matches',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: box.length,
                      itemBuilder: (context, index) {
                        final match = box.getAt(index);
                        if (match == null) return const SizedBox.shrink();

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          color: Colors.white.withOpacity(0.9),
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              children: [
                                Text(
                                  match.date,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        children: [
                                          CachedNetworkImage(
                                            imageUrl: match.homeTeamLogo,
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
                                            memCacheHeight: 80,
                                            memCacheWidth: 80,
                                            maxWidthDiskCache: 80,
                                            maxHeightDiskCache: 80,
                                            useOldImageOnUrlChange: true,
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            match.homeTeam,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Text(
                                      'VS',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          CachedNetworkImage(
                                            imageUrl: match.awayTeamLogo,
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
                                            memCacheHeight: 80,
                                            memCacheWidth: 80,
                                            maxWidthDiskCache: 80,
                                            maxHeightDiskCache: 80,
                                            useOldImageOnUrlChange: true,
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            match.awayTeam,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  match.venue,
                                  style: const TextStyle(color: Colors.black87),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    box.deleteAt(index);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Match removed from Watch Later'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
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
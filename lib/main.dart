import 'package:flutter/material.dart';
import 'package:sportsmagicbox/screens/welcome_screen.dart';


// Future<void> preloadCache() async {
//   final prefs = await SharedPreferences.getInstance();

//   if (!prefs.containsKey("preloaded")) {
//     await MovieService.fetchAllByType("movie");
//     await MovieService.fetchAllByType("tv_show");

//     prefs.setBool("preloaded", true);
//   }
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // RequestConfiguration configuration = RequestConfiguration(
  //   testDeviceIds: ['00008030-0004481C1185402E'],
  // );
  // MobileAds.instance.updateRequestConfiguration(configuration);

  // await preloadCache();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();

}

class _MyAppState extends State<MyApp> {


  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const WelcomeScreen(),
    );
  }
}

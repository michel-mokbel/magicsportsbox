import 'package:flutter/material.dart';
import 'package:sportsmagicbox/screens/leagues_screen.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportsmagicbox/services/ads_service.dart';

class WelcomeScreen extends StatefulWidget {
  final bool showAtt;
  
  const WelcomeScreen({super.key, this.showAtt = false});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final String title = 'Sports Magic Box';
  final String backgroundImage = 'lib/assets/images/Third.png';
  final AdsService _adsService = AdsService();
  bool _isNavigating = false; // Prevent multiple navigation attempts

  @override
  void initState() {
    super.initState();
    
    // Request ATT if showAtt is true
    if (widget.showAtt) {
      _requestTrackingAuthorization();
    }
  }
  
  Future<void> _requestTrackingAuthorization() async {
    try {
      // Wait a moment to ensure app is visible
      await Future.delayed(const Duration(milliseconds: 500));
      
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        await Future.delayed(const Duration(milliseconds: 200));
        final newStatus = await AppTrackingTransparency.requestTrackingAuthorization();
        print('ATT permission request in welcome screen. Result: $newStatus');
        
        final isTrackingAllowed = newStatus == TrackingStatus.authorized;
        if (isTrackingAllowed) {
          // Get AppsFlyer instance using functions from main.dart
          final devKey = await _fetchDevKeyFromRemoteConfig();
          final appsflyerSdk = _initAppsFlyerInstance(devKey);
          _startAppsFlyerTracking(appsflyerSdk, true);
        } else {
          // Start with limited tracking
          final devKey = await _fetchDevKeyFromRemoteConfig();
          final appsflyerSdk = _initAppsFlyerInstance(devKey);
          _startAppsFlyerTracking(appsflyerSdk, false);
        }
      } else {
        final isTrackingAllowed = status == TrackingStatus.authorized;
        final devKey = await _fetchDevKeyFromRemoteConfig();
        final appsflyerSdk = _initAppsFlyerInstance(devKey);
        _startAppsFlyerTracking(appsflyerSdk, isTrackingAllowed);
      }
    } catch (e) {
      print('Failed to request tracking authorization in welcome screen: $e');
      
      // Start with limited tracking on error
      try {
        final devKey = await _fetchDevKeyFromRemoteConfig();
        final appsflyerSdk = _initAppsFlyerInstance(devKey);
        _startAppsFlyerTracking(appsflyerSdk, false);
      } catch (e) {
        print('Error initializing AppsFlyer: $e');
      }
    }
  }
  
  // Handle navigation to leagues screen with potential ad
  Future<void> _navigateToLeaguesScreen() async {
    // Prevent multiple navigation attempts
    if (_isNavigating) return;
    
    setState(() {
      _isNavigating = true;
    });
    
    try {
      // Only show interstitial ad if it's ready, otherwise skip it
      if (_adsService.isInterstitialAdReady()) {
        print('Interstitial ad ready, showing before navigation');
        await _adsService.showInterstitialAd();
      } else {
        print('Interstitial ad not ready, skipping and requesting load for next time');
        // Request load for next time, no waiting
        _adsService.showInterstitialAd(); // This will return false but trigger loading
      }
      
      // Navigate to leagues screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LeaguesScreen()),
        );
      }
    } catch (e) {
      print('Error handling interstitial ad: $e');
      // Navigate anyway if there was an error with the ad
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LeaguesScreen()),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
      }
    }
  }
  
  Future<String> _fetchDevKeyFromRemoteConfig() async {
    final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
    try {
      await remoteConfig.setDefaults(<String, dynamic>{
        'dev_key': 'TVuiYiPd4Bu5wzUuZwTymX', // Default value if Remote Config fails
      });
      await remoteConfig.fetchAndActivate();
      String devKey = remoteConfig.getString('dev_key');
      print('Fetched dev_key: $devKey');
      return devKey;
    } catch (e) {
      print('Error fetching dev_key from Remote Config: $e');
      return 'TVuiYiPd4Bu5wzUuZwTymX'; // Fallback dev key
    }
  }
  
  AppsflyerSdk _initAppsFlyerInstance(String devKey) {
    // Ensure dev key is not empty
    if (devKey.isEmpty) {
      print("WARNING: Empty dev key detected, using default key");
      devKey = 'TVuiYiPd4Bu5wzUuZwTymX';
    }
    
    print("Initializing AppsFlyer in welcome screen with dev key: $devKey");
    
    final AppsFlyerOptions options = AppsFlyerOptions(
        afDevKey: devKey,
        appId: "6741192283",
        showDebug: true,
        timeToWaitForATTUserAuthorization: 1, // Give time for ATT dialog
        manualStart: true); // Important: We'll manually start it later
        
    return AppsflyerSdk(options);
  }
  
  void _startAppsFlyerTracking(AppsflyerSdk appsflyerSdk, bool isTrackingAllowed) {
    // Setup install attribution callbacks
    appsflyerSdk.onInstallConversionData((res) {
      print("AppsFlyer Install Conversion Data: $res");
      final data = res["data"];
      if (data != null) {
        // Check if it's a new install
        final isFirstLaunch = data["is_first_launch"];
        if (isFirstLaunch != null && isFirstLaunch.toString() == "true") {
          print("This is a new AppsFlyer install!");
          // Handle new install here (e.g., show special first-time user screens, etc.)
        }
  
        // Check attribution source
        final mediaSource = data["media_source"];
        if (mediaSource != null) {
          print("Install attributed to: $mediaSource");
        }
  
        // Store attribution data if needed
        final campaign = data["campaign"];
        if (campaign != null) {
          // You might want to save this to shared preferences or pass to analytics
          print("Campaign: $campaign");
        }
      }
    });
  
    // Helper function to determine user type based on shared preferences
    Future<String> getUserTypeAsync() async {
      try {
        final prefInstance = await SharedPreferences.getInstance();
        final firstOpen = prefInstance.getBool('first_open') ?? true;
        if (firstOpen) {
          await prefInstance.setBool('first_open', false);
          return "new_user";
        } else {
          return "returning_user";
        }
      } catch (e) {
        print("Error determining user type: $e");
        return "unknown";
      }
    }
  
    appsflyerSdk.onAppOpenAttribution((res) {
      print("AppsFlyer App Open Attribution: $res");
      // Handle deep link data here
    });
  
    // Always initialize SDK with appropriate callbacks
    appsflyerSdk.initSdk(
        registerConversionDataCallback: true,
        registerOnAppOpenAttributionCallback: true,
        registerOnDeepLinkingCallback: true);
  
    // Start SDK
    appsflyerSdk.startSDK(
      onSuccess: () async {
        print("AppsFlyer SDK initialized successfully in welcome screen.");
  
        // Log app open event if tracking is allowed
        if (isTrackingAllowed) {
          // Get user type asynchronously
          final userType = await getUserTypeAsync();
          
          appsflyerSdk.logEvent("user_session_started", {
            "session_start_time": DateTime.now().toIso8601String(),
            "tracking_permission_granted": true,
            "user_type": userType,
          });
        }
      },
      onError: (int errorCode, String errorMessage) => print(
          "Error initializing AppsFlyer SDK in welcome screen: Code $errorCode - $errorMessage"),
    );
  
    // Log limited events even if tracking isn't fully allowed
    appsflyerSdk.logEvent("app_installation_completed", {
      "installation_time": DateTime.now().toIso8601String(),
      "tracking_enabled": isTrackingAllowed,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Static Background Image
          Positioned.fill(
            child: Image.asset(
              backgroundImage,
              fit: BoxFit.cover,
            ),
          ),

          // Gradient Overlay
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(0, 0, 0, 0),
                  Color.fromARGB(194, 0, 0, 0), 
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Text and Button Overlay
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Title and Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const Text(
                      'Your Sports Hub',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Your ultimate guide to sports leagues and matches.",
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Get Started Button
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _isNavigating ? null : _navigateToLeaguesScreen,
                  child: _isNavigating 
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        "Get Started",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ],
      ),
    );
  }
}

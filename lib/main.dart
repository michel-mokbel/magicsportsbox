import 'package:flutter/material.dart';
import 'package:sportsmagicbox/screens/welcome_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/watch_later.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:app_set_id/app_set_id.dart';
import 'dart:async';
import 'package:sportsmagicbox/services/ads_service.dart';

// A simple splash screen widget to show while initializing
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AdsService _adsService = AdsService();
  
  @override
  void initState() {
    super.initState();
    // Reset ad counters at app launch
    _adsService.resetAdCounters();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      print('DEBUG: SplashScreen initialization started');
      
      // Initialize remote config
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(seconds: 10), // Shorter interval for development
      ));
      await remoteConfig.fetchAndActivate();
      print('DEBUG: Remote Config initialized and fetched');

      // Get URL and show_att from remote config
      final url = remoteConfig.getString('url');
      final showAtt = remoteConfig.getBool('show_att');
      
      print('Remote config URL: $url');
      print('Remote config show_att: $showAtt');
      print('Remote config last fetch status: ${remoteConfig.lastFetchStatus}');
      print('Remote config last fetch time: ${remoteConfig.lastFetchTime}');
      
      // Create AppsFlyer instance early - will be started after ATT check
      final devKey = await fetchDevKeyFromRemoteConfig();
      final appsflyerSdk = initAppsFlyerInstance(devKey);
      
      if (url.isNotEmpty) {
        // If URL is present and show_att is true, request ATT in splash screen
        if (showAtt) {
          try {
            await Future.delayed(const Duration(seconds: 1));
            final status = await AppTrackingTransparency.requestTrackingAuthorization();
            print('ATT permission request in splash screen. Result: $status');
            
            final isTrackingAllowed = status == TrackingStatus.authorized;
            if (isTrackingAllowed) {
              // Start AppsFlyer SDK with full tracking
              startAppsFlyerTracking(appsflyerSdk, true);
            } else {
              // Start without full tracking if permission not granted
              startAppsFlyerTracking(appsflyerSdk, false);
            }
          } catch (e) {
            print('Failed to request tracking authorization: $e');
            // Start AppsFlyer even on error, but without full tracking
            startAppsFlyerTracking(appsflyerSdk, false);
          }
        } else {
          // If show_att is false, start AppsFlyer without requesting permission
          startAppsFlyerTracking(appsflyerSdk, false);
        }
        
        // Get device information
        final deviceInfo = await getDeviceInfo();
        
        // Replace placeholders in URL
        var finalUrl = url
          .replaceAll('{bundle_id}', deviceInfo['bundle_id']!)
          .replaceAll('{uuid}', deviceInfo['uuid']!)
          .replaceAll('{idfa}', deviceInfo['idfa']!)
          .replaceAll('{idfv}', deviceInfo['idfv']!)
          .replaceAll('{appsflyer_id}', deviceInfo['appsflyer_id']!);
          
        print('Final URL with parameters: $finalUrl');
        
        // Launch WebView with the URL
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => WebViewScreen(url: finalUrl),
            ),
          );
        }
      } else {
        // No URL, show rewarded ad directly before navigating to welcome screen
        print('No URL from remote config, showing rewarded ad before going to welcome screen');
        
        // Check if ads are initialized - don't block if not
        if (!_adsService.isInitialized) {
          print('Unity Ads not initialized yet, attempting to initialize');
          // Don't wait, just trigger initialization and continue
          _adsService.initialize().then((success) {
            if (success) {
              print('Unity Ads initialized successfully in SplashScreen');
            } else {
              print('Unity Ads failed to initialize in SplashScreen');
            }
          });
        }
        
        // Show rewarded ad if available - if not, just continue
        try {
          // Only wait if ad is already loaded, otherwise continue immediately
          if (_adsService.isRewardedAdReady()) {
            await _adsService.showRewardedAd();
          } else {
            print('Rewarded ad not ready, continuing without showing ad');
            // Request load for next time
            _adsService.showRewardedAd(); // This will return false but trigger loading
          }
        } catch (e) {
          print('Error showing rewarded ad: $e');
        }
        
        // Navigate to welcome screen with showAtt flag
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => WelcomeScreen(showAtt: showAtt),
            ),
          );
        }
      }
    } catch (e) {
      print('Error in splash screen initialization: $e');
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const WelcomeScreen(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset('lib/assets/images/logo.png', width: 150),
      ),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  final String url;

  const WebViewScreen({super.key, required this.url});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  final adsService = AdsService();
  late WebViewController controller;
  int _pageLoadCount = 0; // Track page loads for interstitial frequency
  static const int _showAdAfterNPages = 3; // Show an interstitial after every N page loads
  
  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _ensureAdsInitialized();
  }
  
  // Make sure ads are initialized when the WebView is shown
  Future<void> _ensureAdsInitialized() async {
    if (!adsService.isInitialized) {
      print('Unity Ads not initialized in WebViewScreen, attempting to initialize');
      // Don't wait - just trigger initialization and continue
      adsService.initialize().then((success) {
        if (success) {
          print('Unity Ads initialized successfully in WebViewScreen');
        } else {
          print('Unity Ads failed to initialize in WebViewScreen');
        }
      });
    }
  }
  
  void _initializeWebView() {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('Page started loading: $url');
          },
          onPageFinished: (String url) {
            print('Page finished loading: $url');
            _onPageFinishedLoading();
          },
          onWebResourceError: (WebResourceError error) async {
            print('WebView error: ${error.description}');
            
            // Show rewarded ad on WebView error only if ready
            print('Checking if rewarded ad is ready after WebView error');
            try {
              if (adsService.isRewardedAdReady()) {
                await adsService.showRewardedAd();
              } else {
                print('Rewarded ad not ready after WebView error, continuing without showing ad');
                // Request load for next time, no waiting
                adsService.showRewardedAd(); // This will return false but trigger loading
              }
            } catch (e) {
              print('Error showing rewarded ad after WebView error: $e');
            }
            
            // Navigate to welcome screen
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const WelcomeScreen()),
              );
            }
          },
          onNavigationRequest: (NavigationRequest request) async {
            print('Navigation request to: ${request.url}');
            
            if (request.url.startsWith('error://')) {
              print('Error scheme detected, checking if rewarded ad is ready');
              
              // Show rewarded ad only if ready
              try {
                if (adsService.isRewardedAdReady()) {
                  await adsService.showRewardedAd();
                } else {
                  print('Rewarded ad not ready on error schema, continuing without showing ad');
                  // Request load for next time, no waiting
                  adsService.showRewardedAd(); // This will return false but trigger loading
                }
              } catch (e) {
                print('Error showing rewarded ad on error schema: $e');
              }
              
              // Navigate to welcome screen
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                );
              }
              return NavigationDecision.prevent;
            }
            
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }
  
  // Handle page load completion and potentially show interstitial
  Future<void> _onPageFinishedLoading() async {
    _pageLoadCount++;
    
    // After every N page loads, show an interstitial
    if (_pageLoadCount >= _showAdAfterNPages) {
      _pageLoadCount = 0; // Reset counter
      
      // Only try to show interstitial if we're still in the app (mounted) and ad is ready
      if (mounted) {
        // Small delay to ensure page is fully rendered
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Show interstitial only if ready
        try {
          if (adsService.isInterstitialAdReady()) {
            await adsService.showInterstitialAd();
          } else {
            print('Interstitial ad not ready after page load, continuing without showing ad');
            // Request load for next time, no waiting
            adsService.showInterstitialAd(); // This will return false but trigger loading
          }
        } catch (e) {
          print('Error showing interstitial ad after page load: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(child: WebViewWidget(controller: controller)),
        ],
      ),
    );
  }
}

Future<String> getOrCreateUUID() async {
  final prefs = await SharedPreferences.getInstance();
  String? uuid = prefs.getString('device_uuid');
  
  if (uuid == null) {
    uuid = const Uuid().v4();
    await prefs.setString('device_uuid', uuid);
  }
  
  return uuid;
}

Future<Map<String, String>> getDeviceInfo() async {
  final deviceInfo = <String, String>{};
  
  // Get or create persistent UUID
  final uuid = await getOrCreateUUID();
  deviceInfo['uuid'] = uuid;
  
  // Get IDFA (Advertising Identifier)
  try {
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.authorized) {
      final idfa = await AppTrackingTransparency.getAdvertisingIdentifier();
      deviceInfo['idfa'] = idfa;
    } else {
      print('Tracking not authorized, status: $status');
      deviceInfo['idfa'] = '';
    }
  } catch (e) {
    print('Error getting IDFA: $e');
    deviceInfo['idfa'] = '';
  }

  // Get IDFV (Vendor Identifier)
  try {
    final appSetId = AppSetId();
    final idfv = await appSetId.getIdentifier();
    deviceInfo['idfv'] = idfv ?? '';
  } catch (e) {
    print('Error getting IDFV: $e');
    deviceInfo['idfv'] = '';
  }

  deviceInfo['bundle_id'] = 'com.appadsrocket.sportsmagicbox';

  // Get AppsFlyer ID
  try {
    final devKey = await fetchDevKeyFromRemoteConfig();
    final appsflyerSdk = initAppsFlyerInstance(devKey);
    final appsFlyerId = await appsflyerSdk.getAppsFlyerUID();
    deviceInfo['appsflyer_id'] = appsFlyerId ?? '';
  } catch (e) {
    print('Error getting AppsFlyer ID: $e');
    deviceInfo['appsflyer_id'] = '';
  }

  print('Device info collected: $deviceInfo');
  return deviceInfo;
}

Future<void> main() async {
  try {
    print('DEBUG: main() function started');
    WidgetsFlutterBinding.ensureInitialized();
    print('DEBUG: Flutter binding initialized');

    // Initialize Firebase
    try {
      await Firebase.initializeApp();
      print('DEBUG: Firebase initialized successfully');
    } catch (e) {
      print('DEBUG: Failed to initialize Firebase: $e');
    }
    
    // Fire-and-forget Unity Ads initialization early but don't wait for it
    print('DEBUG: Starting Unity Ads initialization in background');
    final adsService = AdsService();
    
    // Don't use await - fire and forget
    // This is "launch and abandon" pattern - start initialization and don't wait for it
    adsService.initialize().then((success) {
      if (success) {
        print('DEBUG: Unity Ads initialized successfully in background');
      } else {
        print('DEBUG: Unity Ads failed to initialize in background');
      }
    }).catchError((error) {
      print('DEBUG: Error during Unity Ads initialization: $error');
    });
    print('DEBUG: Continuing app startup without waiting for ads initialization');

    // Initialize Hive
    try {
      await Hive.initFlutter();
      Hive.registerAdapter(WatchLaterAdapter());
      await Hive.openBox<WatchLater>('watchLater');
      print('DEBUG: Hive initialized successfully');
    } catch (e) {
      print('DEBUG: Failed to initialize Hive: $e');
    }

    // Start the app with SplashScreen regardless of ads or Hive status
    print('DEBUG: Starting app with SplashScreen');
    runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    ));
  } catch (e) {
    print('Fatal error during initialization: $e');
    runApp(const MyApp());
  }
}

Future<String> fetchDevKeyFromRemoteConfig() async {
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

void initAppsFlyer(String devKey, bool isTrackingAllowed) {
  final double timeToWait = isTrackingAllowed ? 10 : 0;

  final AppsFlyerOptions options = AppsFlyerOptions(
      afDevKey: devKey,
      appId: "6741192283",
      showDebug: true,
      timeToWaitForATTUserAuthorization: timeToWait,
      manualStart: false);

  final appsflyerSdk = AppsflyerSdk(options);

  if (isTrackingAllowed) {
    appsflyerSdk.initSdk(
        registerConversionDataCallback: true,
        registerOnAppOpenAttributionCallback: true,
        registerOnDeepLinkingCallback: true);
    appsflyerSdk.startSDK(
      onSuccess: () => print("AppsFlyer SDK initialized successfully."),
      onError: (int errorCode, String errorMessage) =>
          print("Error initializing AppsFlyer SDK: Code $errorCode - $errorMessage"),
    );
  } else {
    print("Tracking denied, skipping AppsFlyer initialization.");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const WelcomeScreen(),
    );
  }
}

// Modified to create instance but not start tracking
AppsflyerSdk initAppsFlyerInstance(String devKey) {
  // Ensure dev key is not empty
  if (devKey.isEmpty) {
    print("WARNING: Empty dev key detected, using default key");
    devKey = 'TVuiYiPd4Bu5wzUuZwTymX';
  }
  
  print("Initializing AppsFlyer with dev key: $devKey");
  
  final AppsFlyerOptions options = AppsFlyerOptions(
      afDevKey: devKey,
      appId: "6741192283",
      showDebug: true,
      timeToWaitForATTUserAuthorization: 1, // Give time for ATT dialog
      manualStart: true); // Important: We'll manually start it later
      
  return AppsflyerSdk(options);
}

// New function to start tracking with appropriate settings
void startAppsFlyerTracking(AppsflyerSdk appsflyerSdk, bool isTrackingAllowed) {
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
      print("AppsFlyer SDK initialized successfully.");

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
        "Error initializing AppsFlyer SDK: Code $errorCode - $errorMessage"),
  );

  // Log limited events even if tracking isn't fully allowed
  appsflyerSdk.logEvent("app_installation_completed", {
    "installation_time": DateTime.now().toIso8601String(),
    "tracking_enabled": isTrackingAllowed,
  });
}

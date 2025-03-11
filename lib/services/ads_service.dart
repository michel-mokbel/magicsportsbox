import 'package:flutter/material.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:shared_preferences/shared_preferences.dart';

class AdsService {
  // Singleton pattern
  static final AdsService _instance = AdsService._internal();
  factory AdsService() => _instance;
  AdsService._internal();

  // Unity Ads game IDs - platform specific
  static final String _unityGameId = Platform.isIOS 
      ? '5811994'  // iOS Game ID
      : '5811995'; // Android Game ID 
  
  // Ad placement IDs - platform specific
  static final String _rewardedAdPlacementId = Platform.isIOS
      ? 'Rewarded_iOS'
      : 'Rewarded_Android';
  static final String _interstitialAdPlacementId = Platform.isIOS
      ? 'Interstitial_iOS'
      : 'Interstitial_Android';
  
  // Unity Ads configuration
  // Set to false for production release
  static const bool _testMode = true;
  
  // Track initialization status and attempts
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  int _initAttempts = 0;
  static const int _maxInitAttempts = 5;
  
  // Track ad ready status
  bool _isRewardedAdReady = false;
  bool _isInterstitialAdReady = false;
  
  // Ad frequency control
  static const int _minTimeBetweenAds = 60; // Minimum seconds between interstitial ads
  DateTime? _lastAdShownTime;
  
  // Session ad counter to limit frequency
  int _interstitialAdCount = 0;
  static const int _maxInterstitialsPerSession = 6;
  
  // Completer to track initialization completion
  Completer<bool>? _initCompleter;

  // Initialize Unity Ads
  Future<bool> initialize() async {
    // If already initializing, return the existing completer
    if (_initCompleter != null && !_initCompleter!.isCompleted) {
      print('Unity Ads initialization already in progress');
      return _initCompleter!.future;
    }
    
    // If already initialized, return immediately
    if (_isInitialized) {
      print('Unity Ads already initialized');
      return true;
    }
    
    // Increment attempt counter
    _initAttempts++;
    print('Unity Ads initialization attempt $_initAttempts of $_maxInitAttempts');
    print('Unity Ads configuration: GameID: $_unityGameId, TestMode: $_testMode');
    
    // Create a new completer
    _initCompleter = Completer<bool>();
    
    try {
      print('Initializing Unity Ads with gameId: $_unityGameId (${Platform.isIOS ? "iOS" : "Android"})');
      
      UnityAds.init(
        gameId: _unityGameId,
        testMode: _testMode,
        onComplete: () {
          print('Unity Ads initialization complete');
          _isInitialized = true;
          _initAttempts = 0; // Reset attempts counter on success
          
          // Load ads after successful initialization
          _loadRewardedAd(); 
          _loadInterstitialAd();
          
          if (!_initCompleter!.isCompleted) _initCompleter!.complete(true);
        },
        onFailed: (error, message) {
          print('Unity Ads initialization failed: $error - $message');
          _isInitialized = false;
          
          if (!_initCompleter!.isCompleted) _initCompleter!.complete(false);
          
          // Retry initialization if we haven't reached max attempts
          if (_initAttempts < _maxInitAttempts) {
            print('Retrying Unity Ads initialization in 3 seconds...');
            Future.delayed(const Duration(seconds: 3), () {
              initialize();
            });
          } else {
            print('Reached maximum initialization attempts. Unity Ads will not be available.');
          }
        },
      );
      
      // Return the future with a timeout
      return _initCompleter!.future.timeout(
        const Duration(seconds: 60), // Extended timeout to ensure completion
        onTimeout: () {
          print('Unity Ads initialization timed out after 60 seconds');
          
          if (!_initCompleter!.isCompleted) _initCompleter!.complete(false);
          
          // Retry initialization if timeout and we haven't reached max attempts
          if (_initAttempts < _maxInitAttempts) {
            print('Retrying Unity Ads initialization after timeout...');
            Future.delayed(const Duration(seconds: 3), () {
              initialize();
            });
          } else {
            print('Reached maximum initialization attempts after timeout. Unity Ads will not be available.');
          }
          
          return false;
        },
      );
    } catch (e) {
      print('Error initializing Unity Ads: $e');
      _isInitialized = false;
      
      if (!_initCompleter!.isCompleted) _initCompleter!.complete(false);
      
      // Retry initialization if exception and we haven't reached max attempts
      if (_initAttempts < _maxInitAttempts) {
        print('Retrying Unity Ads initialization after error...');
        Future.delayed(const Duration(seconds: 3), () {
          initialize();
        });
      } else {
        print('Reached maximum initialization attempts after error. Unity Ads will not be available.');
      }
      
      return false;
    }
  }

  // Load rewarded ad with improved error handling
  void _loadRewardedAd() {
    if (!_isInitialized) {
      print('Cannot load rewarded ad - Unity Ads not initialized');
      return;
    }
    
    print('Loading Unity Ads rewarded ad: $_rewardedAdPlacementId');
    _isRewardedAdReady = false;
    
    try {
      UnityAds.load(
        placementId: _rewardedAdPlacementId,
        onComplete: (placementId) {
          print('Unity Ads rewarded ad loaded successfully: $placementId');
          _isRewardedAdReady = true;
        },
        onFailed: (placementId, error, message) {
          print('Unity Ads rewarded ad load failed: $placementId - $error - $message');
          _isRewardedAdReady = false;
          
          // Retry loading after a delay
          Future.delayed(const Duration(seconds: 5), () {
            if (_isInitialized) _loadRewardedAd();
          });
        },
      );
    } catch (e) {
      print('Unexpected error loading rewarded ad: $e');
      _isRewardedAdReady = false;
      
      // Retry loading after exception
      Future.delayed(const Duration(seconds: 5), () {
        if (_isInitialized) _loadRewardedAd();
      });
    }
  }
  
  // Load interstitial ad with improved error handling
  void _loadInterstitialAd() {
    if (!_isInitialized) {
      print('Cannot load interstitial ad - Unity Ads not initialized');
      return;
    }
    
    print('Loading Unity Ads interstitial ad: $_interstitialAdPlacementId');
    _isInterstitialAdReady = false;
    
    try {
      UnityAds.load(
        placementId: _interstitialAdPlacementId,
        onComplete: (placementId) {
          print('Unity Ads interstitial ad loaded successfully: $placementId');
          _isInterstitialAdReady = true;
        },
        onFailed: (placementId, error, message) {
          print('Unity Ads interstitial ad load failed: $placementId - $error - $message');
          _isInterstitialAdReady = false;
          
          // Retry loading after a delay
          Future.delayed(const Duration(seconds: 5), () {
            if (_isInitialized) _loadInterstitialAd();
          });
        },
      );
    } catch (e) {
      print('Unexpected error loading interstitial ad: $e');
      _isInterstitialAdReady = false;
      
      // Retry loading after exception
      Future.delayed(const Duration(seconds: 5), () {
        if (_isInitialized) _loadInterstitialAd();
      });
    }
  }

  // Check if rewarded ad is ready
  bool isRewardedAdReady() {
    if (!_isInitialized) {
      print('Unity Ads not initialized when checking if rewarded ad is ready');
      return false;
    }
    
    print('Unity Ads rewarded ad ready status: $_isRewardedAdReady');
    return _isRewardedAdReady;
  }
  
  // Check if interstitial ad is ready
  bool isInterstitialAdReady() {
    if (!_isInitialized) {
      print('Unity Ads not initialized when checking if interstitial ad is ready');
      return false;
    }
    
    print('Unity Ads interstitial ad ready status: $_isInterstitialAdReady');
    return _isInterstitialAdReady;
  }
  
  // Check if we should show an interstitial ad based on frequency rules
  Future<bool> shouldShowInterstitial() async {
    // Don't show if we've reached the limit for this session
    if (_interstitialAdCount >= _maxInterstitialsPerSession) {
      print('Reached maximum number of interstitial ads for this session');
      return false;
    }
    
    // Check time since last ad
    if (_lastAdShownTime != null) {
      final secondsSinceLastAd = DateTime.now().difference(_lastAdShownTime!).inSeconds;
      if (secondsSinceLastAd < _minTimeBetweenAds) {
        print('Not enough time has passed since last ad: $secondsSinceLastAd seconds');
        return false;
      }
    }
    
    // Check if this is first app open of the day
    final prefs = await SharedPreferences.getInstance();
    final String? lastOpenDate = prefs.getString('last_app_open_date');
    final today = DateTime.now().toIso8601String().split('T')[0]; // Just get YYYY-MM-DD part
    
    if (lastOpenDate != today) {
      // First open of the day, update the date
      await prefs.setString('last_app_open_date', today);
      // Don't show ad on first open to avoid overwhelming new users
      return false;
    }
    
    return true;
  }

  // Show rewarded ad
  Future<bool> showRewardedAd() async {
    if (!_isInitialized) {
      print('Unity Ads not initialized, cannot show rewarded ad');
      // Try to initialize if not already initialized
      if (_initAttempts < _maxInitAttempts) {
        print('Attempting to initialize Unity Ads before showing rewarded ad');
        final initialized = await initialize();
        if (!initialized) {
          print('Failed to initialize Unity Ads for rewarded ad');
          return false;
        }
      } else {
        print('Exceeded maximum initialization attempts for rewarded ad');
        return false;
      }
    }
    
    // Check if ad is ready - show immediately if ready, skip otherwise
    if (!isRewardedAdReady()) {
      print('Unity Ads rewarded ad not ready, skipping and requesting load for next time');
      _loadRewardedAd(); // Request load for next time
      return false;
    }
    
    Completer<bool> rewardCompleter = Completer<bool>();
    bool hasUserEarnedReward = false;
    
    print('Showing Unity Ads rewarded ad: $_rewardedAdPlacementId');
    
    try {
      // Set up ad listeners
      UnityAds.showVideoAd(
        placementId: _rewardedAdPlacementId,
        onStart: (placementId) {
          print('Unity Ads rewarded ad started: $placementId');
        },
        onClick: (placementId) {
          print('Unity Ads rewarded ad clicked: $placementId');
        },
        onSkipped: (placementId) {
          print('Unity Ads rewarded ad skipped: $placementId');
          hasUserEarnedReward = false;
          _isRewardedAdReady = false;
          if (!rewardCompleter.isCompleted) rewardCompleter.complete(false);
        },
        onComplete: (placementId) {
          print('Unity Ads rewarded ad completed: $placementId');
          hasUserEarnedReward = true;
          _isRewardedAdReady = false;
          if (!rewardCompleter.isCompleted) rewardCompleter.complete(true);
        },
        onFailed: (placementId, error, message) {
          print('Unity Ads rewarded ad failed to show: $placementId - $error - $message');
          _isRewardedAdReady = false;
          if (!rewardCompleter.isCompleted) rewardCompleter.complete(false);
        },
      );
    } catch (e) {
      print('Exception while showing rewarded ad: $e');
      if (!rewardCompleter.isCompleted) rewardCompleter.complete(false);
      return false;
    }
    
    // Wait for ad completion
    try {
      return await rewardCompleter.future.timeout(
        const Duration(minutes: 2),
        onTimeout: () {
          print('Rewarded ad timeout after 2 minutes');
          return hasUserEarnedReward;
        },
      );
    } catch (e) {
      print('Error showing rewarded ad: $e');
      return false;
    } finally {
      // Preload next ad
      _loadRewardedAd();
    }
  }
  
  // Show interstitial ad
  Future<bool> showInterstitialAd() async {
    // First check if we should show an ad based on frequency rules
    final shouldShow = await shouldShowInterstitial();
    if (!shouldShow) {
      print('Skipping interstitial ad based on frequency rules');
      return false;
    }
    
    if (!_isInitialized) {
      print('Unity Ads not initialized, cannot show interstitial ad');
      // Try to initialize if not already initialized
      if (_initAttempts < _maxInitAttempts) {
        print('Attempting to initialize Unity Ads before showing interstitial ad');
        final initialized = await initialize();
        if (!initialized) {
          print('Failed to initialize Unity Ads for interstitial ad');
          return false;
        }
      } else {
        print('Exceeded maximum initialization attempts for interstitial ad');
        return false;
      }
    }
    
    // Check if ad is ready - show immediately if ready, skip otherwise
    if (!isInterstitialAdReady()) {
      print('Unity Ads interstitial ad not ready, skipping and requesting load for next time');
      _loadInterstitialAd(); // Request load for next time
      return false;
    }
    
    Completer<bool> adCompleter = Completer<bool>();
    
    print('Showing Unity Ads interstitial ad: $_interstitialAdPlacementId');
    
    // Update tracking variables
    _lastAdShownTime = DateTime.now();
    _interstitialAdCount++;
    
    try {
      // Set up ad listeners
      UnityAds.showVideoAd(
        placementId: _interstitialAdPlacementId,
        onStart: (placementId) {
          print('Unity Ads interstitial ad started: $placementId');
        },
        onClick: (placementId) {
          print('Unity Ads interstitial ad clicked: $placementId');
        },
        onSkipped: (placementId) {
          print('Unity Ads interstitial ad skipped: $placementId');
          _isInterstitialAdReady = false;
          if (!adCompleter.isCompleted) adCompleter.complete(true);
        },
        onComplete: (placementId) {
          print('Unity Ads interstitial ad completed: $placementId');
          _isInterstitialAdReady = false;
          if (!adCompleter.isCompleted) adCompleter.complete(true);
        },
        onFailed: (placementId, error, message) {
          print('Unity Ads interstitial ad failed to show: $placementId - $error - $message');
          _isInterstitialAdReady = false;
          if (!adCompleter.isCompleted) adCompleter.complete(false);
        },
      );
    } catch (e) {
      print('Exception while showing interstitial ad: $e');
      if (!adCompleter.isCompleted) adCompleter.complete(false);
      return false;
    }
    
    // Wait for ad completion
    try {
      return await adCompleter.future.timeout(
        const Duration(minutes: 1),
        onTimeout: () {
          print('Interstitial ad timeout after 1 minute');
          return false;
        },
      );
    } catch (e) {
      print('Error showing interstitial ad: $e');
      return false;
    } finally {
      // Preload next ad
      _loadInterstitialAd();
    }
  }
  
  // Reset the session ad counter
  void resetAdCounters() {
    _interstitialAdCount = 0;
    _lastAdShownTime = null;
    print('Ad counters reset');
  }
} 
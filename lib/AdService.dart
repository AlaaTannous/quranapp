import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdHelper {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-7669325052980442/5242004923';
    }
    // else if (Platform.isIOS) {
    //   return 'ca-app-pub-3940256099942544/6300978111';
    // }
    else {
      throw new UnsupportedError('Unsupported platform');
    }
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-7669325052980442/4475718164";
    }
    //  else if (Platform.isIOS) {
    //   return "ca-app-pub-3940256099942544/1033173712";
    // }
    else {
      throw new UnsupportedError("Unsupported platform");
    }
  }
}

class AdService {
  static AdService? _dataService;
  var _interstitialDate = DateTime.now();
  bool _isInterstitialAdReady = false;
  InterstitialAd? _interstitialAd;
  bool adsDisabled = false;
  AdService.createInstance();

  factory AdService() {
    if (_dataService == null) {
      _dataService = AdService.createInstance();
    }
    return _dataService!;
  }

  showInterstitialAd() {
    if (!adsDisabled) {
      debugPrint(
          "_interstitialDate.millisecondsSinceEpoch < DateTime.now().millisecondsSinceEpoch - ${_interstitialDate.millisecondsSinceEpoch < DateTime.now().millisecondsSinceEpoch}");

      debugPrint("_isInterstitialAdReady - $_isInterstitialAdReady");

      if (_interstitialDate.millisecondsSinceEpoch <
              DateTime.now().millisecondsSinceEpoch &&
          _isInterstitialAdReady) {
        _interstitialDate = DateTime.now();
        _interstitialAd?.show();
      } else if (!_isInterstitialAdReady) {
        loadInterstitialAd();
      }
    } else {
      debugPrint("Ads disabled");
    }
  }

  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          this._interstitialAd = ad;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              loadInterstitialAd();
            },
          );

          _isInterstitialAdReady = true;
        },
        onAdFailedToLoad: (err) {
          
          _isInterstitialAdReady = false;
        },
      ),
    );
  }
}

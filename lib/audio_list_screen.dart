import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'AdService.dart';
import 'clsAudio.dart';
import 'common.dart';

class AudioListScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return AudioListScreenState();
  }
}

class AudioListScreenState extends State<AudioListScreen>
    with WidgetsBindingObserver {
  List<clsAudio> niyams = [];
  AudioPlayer audioPlayer = AudioPlayer();
  bool playerStarted = false;
  int selectedIndex = 0;
  int bannerHeight = 0;
  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;

  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
          audioPlayer.positionStream,
          audioPlayer.bufferedPositionStream,
          audioPlayer.durationStream,
          (position, bufferedPosition, duration) => PositionData(
              position, bufferedPosition, duration ?? Duration.zero));

  @override
  void initState() {
    super.initState();
    AdService().showInterstitialAd();

    debugPrint("initState");
    WidgetsBinding.instance.addObserver(this);
    if (niyams.isEmpty) {
      getNiyams();
      _init();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadBanner();
    });
  }

  @override
  void dispose() {
    super.dispose();
    debugPrint("disposes");
    WidgetsBinding.instance.removeObserver(this);
    audioPlayer.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:const Text("سور مختارة من القرآن الكريم  "),
        centerTitle: true,
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        return Column(
          children: [
            Expanded(child: getPlayerView()),
            SizedBox(
                height: constraints.maxHeight - 130 - bannerHeight,
                child: getNiyamListView()),
            if (_isBannerAdReady)
              Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: _bannerAd.size.width.toDouble(),
                  height: _bannerAd.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd),
                ),
              ),
          ],
        );
      }),
    );
  }

  Future<void> _init() async {
    // Inform the operating system of our app's audio attributes etc.
    // We pick a reasonable default for an app that plays speech.
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    // Listen to errors during playback.
    audioPlayer.playbackEventStream.listen((event) {},
        onError: (Object e, StackTrace stackTrace) {
      
    });
    // Try to load audio from a source and catch any errors.
    try {
      await audioPlayer.setAudioSource(
        ConcatenatingAudioSource(
          // Start loading next item just before reaching it.
          useLazyPreparation: true, // default
          // Customise the shuffle algorithm.
          shuffleOrder: DefaultShuffleOrder(), // default
          // Specify the items in the playlist.
          children: getAllPlayItemsUrl(),
        ),
        // Playback will be prepared to start from track1.mp3
        initialIndex: 0, // default
        // Playback will be prepared to start from position zero.
        initialPosition: Duration.zero, // default
      );
    } catch (e) {
      print("Error loading audio source: $e");
    }
  }

  void loadBanner() {
    AdSize.getAnchoredAdaptiveBannerAdSize(
            Orientation.portrait, MediaQuery.of(context).size.width.round())
        .then((value) {
      _bannerAd = BannerAd(
        adUnitId: AdHelper.bannerAdUnitId,
        request: const AdRequest(),
        size: AdSize(width: value?.width ?? 0, height: value?.height ?? 0),
        listener: BannerAdListener(
          onAdLoaded: (_) {
            setState(() {
              _isBannerAdReady = true;
            });
          },
          onAdFailedToLoad: (ad, err) {
            
            _isBannerAdReady = false;
            ad.dispose();
          },
        ),
      );
      bannerHeight = _bannerAd.size.height;

      _bannerAd.load();
    });
  }

  List<AudioSource> getAllPlayItemsUrl() {
    List<AudioSource> items = [];
    niyams.forEach((element) {
      var url = Uri.parse(element.content);
      items.add(AudioSource.uri(url));
    });
    return items;
  }

  Widget getNiyamListView() {
    return ListView.builder(
      itemCount: niyams.length,
      itemBuilder: (context, index) {
        return Card(
          elevation: 2.0,
          child: ListTile(
              onTap: () {
                playAudio(index);
                AdService().showInterstitialAd();
              },
              leading: const Icon(Icons.audiotrack),
              title: Text(niyams[index].subTitle),
              subtitle: Text(niyams[index].title),
              selected: index == selectedIndex),
        );
      },
    );
  }

  getPlayerView() {
    return SizedBox(
      width: (MediaQuery.of(context).size.width),
      height: (MediaQuery.of(context).size.height),
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display play/pause button and volume/speed sliders.
            // Display seek bar. Using StreamBuilder, this widget rebuilds
            // each time the position, buffered position or duration changes.
            StreamBuilder<PositionData>(
              stream: _positionDataStream,
              builder: (context, snapshot) {
                final positionData = snapshot.data;
                return SeekBar(
                  duration: positionData?.duration ?? Duration.zero,
                  position: positionData?.position ?? Duration.zero,
                  bufferedPosition:
                      positionData?.bufferedPosition ?? Duration.zero,
                  onChangeEnd: audioPlayer.seek,
                );
              },
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Opens volume slider dialog
                IconButton(
                  icon: const Icon(Icons.volume_up),
                  onPressed: () {
                    showSliderDialog(
                      context: context,
                      title: "Adjust volume",
                      divisions: 10,
                      min: 0.0,
                      max: 1.0,
                      value: audioPlayer.volume,
                      stream: audioPlayer.volumeStream,
                      onChanged: audioPlayer.setVolume,
                    );
                  },
                ),
                StreamBuilder<SequenceState?>(
                  stream: audioPlayer.sequenceStateStream,
                  builder: (context, snapshot) => IconButton(
                    icon: const Icon(Icons.skip_previous),
                    onPressed: () {
                      if (audioPlayer.hasPrevious) {
                        audioPlayer.seekToPrevious();
                        setState(() {
                          selectedIndex -= 1;
                        });
                      }
                    },
                  ),
                ),
        
                /// This StreamBuilder rebuilds whenever the player state changes, which
                /// includes the playing/paused state and also the
                /// loading/buffering/ready state. Depending on the state we show the
                /// appropriate button or loading indicator.
                StreamBuilder<PlayerState>(
                  stream: audioPlayer.playerStateStream,
                  builder: (context, snapshot) {
                    final playerState = snapshot.data;
                    final processingState = playerState?.processingState;
                    final playing = playerState?.playing;
                    if (processingState == ProcessingState.loading ||
                        processingState == ProcessingState.buffering) {
                      return Container(
                        margin: const EdgeInsets.all(8.0),
                        width: 50.0,
                        height: 50.0,
                        child: const CircularProgressIndicator(),
                      );
                    } else if (playing != true) {
                      return IconButton(
                        icon: const Icon(Icons.play_arrow),
                        iconSize: 50.0,
                        onPressed: () {
                          AdService().showInterstitialAd();
        
                          audioPlayer.play();
                        },
                      );
                    } else if (processingState != ProcessingState.completed) {
                      return IconButton(
                        icon: const Icon(Icons.pause),
                        iconSize: 50.0,
                        onPressed: audioPlayer.pause,
                      );
                    } else {
                      return IconButton(
                        icon: const Icon(Icons.replay),
                        iconSize: 50.0,
                        onPressed: () => audioPlayer.seek(Duration.zero),
                      );
                    }
                  },
                ),
                StreamBuilder<SequenceState?>(
                  stream: audioPlayer.sequenceStateStream,
                  builder: (context, snapshot) => IconButton(
                    icon: const Icon(Icons.skip_next),
                    onPressed: () {
                      if (audioPlayer.hasNext) {
                        setState(() {
                          selectedIndex += 1;
                        });
                        audioPlayer.seekToNext();
                      }
                    },
                  ),
                ),
                // Opens speed slider dialog
                StreamBuilder<double>(
                  stream: audioPlayer.speedStream,
                  builder: (context, snapshot) => IconButton(
                    icon: Text("${snapshot.data?.toStringAsFixed(1)}x",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      showSliderDialog(
                        context: context,
                        title: "Adjust speed",
                        divisions: 10,
                        min: 0.5,
                        max: 1.5,
                        value: audioPlayer.speed,
                        stream: audioPlayer.speedStream,
                        onChanged: audioPlayer.setSpeed,
                      );
                    },
                  ),
                ),
              ],
            ),
            
            // ElevatedButton(child: Text('الرجاء تقييم التطبيق 5 نجوم بارك الله فيك اضغط هنا',style: TextStyle(color: Colors.black),) ,onPressed: (){},),
        
          ],
        
        
        ),
      ),
    );
  }

  playAudio(index) async {
    setState(() {
      selectedIndex = index;
    });
    audioPlayer.seek(Duration.zero, index: index);
    audioPlayer.play();
  }

  void getNiyams() {
    var header0 = clsAudio();
    header0.title = "تخرج الشياطين من البيت";
    header0.subTitle = "سورة البقرة";
    header0.content = "asset:///assets/1.mp3";

    niyams.add(header0);

    var header1 = clsAudio();
    header1.title = "اقراها قبل النوم لتحصنك من الشيطان";
    header1.subTitle = "اية الكرسي";
    header1.content = "asset:///assets/2.mp3";

    niyams.add(header1);

    var header2 = clsAudio();
    header2.title = "تجلب الرزق وتمنع الفقر باذن الله";
    header2.subTitle = "سورة الواقعة";
    header2.content = "asset:///assets/3.mp3";

    niyams.add(header2);
    var header3 = clsAudio();
    header3.title = "حصن نفسك واطفالك";
    header3.subTitle = "المعوذات";
    header3.content = "asset:///assets/4.mp3";

    

    niyams.add(header3);
    var header4 = clsAudio();
    header4.title = "تكفيك من كل مكروه وتبعد عنك الشيطان";
    header4.subTitle = "اخر ايتين من سورة البقرة";
    header4.content = "asset:///assets/5.mp3";

    niyams.add(header4);

    var header5 = clsAudio();
    header5.title = "تمنع عنك عذاب القبر";
    header5.subTitle = "سورة الملك";
    header5.content = "asset:///assets/6.mp3";

    niyams.add(header5);

    var header6 = clsAudio();
    header6.title = "مغفرة الذنوب وتكفير السيئات";
    header6.subTitle = "ياسين";
    header6.content = "asset:///assets/7.mp3";

    niyams.add(header6);
    
    // var header2 = clsAudio();
    // header2.title = "Tonight (Best You Ever Had)";
    // header2.subTitle = "John Legend";
    // header2.content = "asset:///assets/audio/3.mp3";

    // niyams.add(header2);

    return;
    // var header3 = clsAudio();
    // header3.title = "Cheap Thrills";
    // header3.subTitle = "Sia";
    // header3.content =
    //     "https://themamaship.com/music/Catalog/Cheap%20Thrills%20-%20Sia%20ft.%20Sean%20Paul.mp3";

    // niyams.add(header3);

    // var header4 = clsAudio();
    // header4.title = "Counting Stars";
    // header4.subTitle = "One Republic";
    // header4.content =
    //     "https://themamaship.com/music/Catalog/Counting%20Stars%20-OneRepublic.mp3";

    // var header5 = clsAudio();
    // header5.title = "Hey Brother";
    // header5.subTitle = "Avicii";
    // header5.content =
    //     "https://themamaship.com/music/Catalog/Hey%20Brother%20-%20Avicii.mp3";

    // niyams.add(header5);

    // var header6 = clsAudio();
    // header6.title = "I'm Yours";
    // header6.subTitle = "Jason Marzે";
    // header6.content =
    //     "https://themamaship.com/music/Catalog/Jason%20Mraz%20-%20I'm%20Yours%20(radio%20edit).mp3";

    // niyams.add(header6);

    // var header7 = clsAudio();
    // header7.title = "Marry You";
    // header7.subTitle = "Bruno Mars";
    // header7.content =
    //     "https://themamaship.com/music/Catalog/Marry%20You%20-%20Bruno%20Mars.mp3";

    // niyams.add(header7);

    // var header8 = clsAudio();
    // header8.title = "Shape of Your";
    // header8.subTitle = "Ed Sheeran";
    // header8.content =
    //     "https://themamaship.com/music/Catalog/Shape%20Of%20You%20-%20Ed%20Sheeran.mp3";

    // niyams.add(header8);
  }
}

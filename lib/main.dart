import 'dart:async';
import 'dart:math';

import 'package:audio_streamer/audio_streamer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  MediaStream? _audioStream;

  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<List<double>>? audioSubscription;
  Timer? _speakerOverrideTimer;

  // Method channel for interacting with native iOS code
  static const platform = MethodChannel('com.example.myapp/audio');

  Future<void> setAudioSession() async {
    try {
      await platform.invokeMethod('setAudioSession');
      print("Audio session set for playback and recording.");
    } catch (e) {
      print("Error setting audio session: $e");
    }
  }

  Future<void> startAudioStreaming() async {
    // Ensure microphone permission is granted
    if (!(await Permission.microphone.isGranted)) {
      await Permission.microphone.request();
    }

    final constraints = <String, dynamic>{
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': false,
    };

    try {
      // Get user media (audio only) with echo cancellation
      MediaStream stream = await navigator.mediaDevices.getUserMedia(constraints);

      // Save the audio stream for later use
      setState(() {
        _audioStream = stream;
      });

      // Log each track for debugging
      stream.getAudioTracks().forEach((track) {
        print("Audio track added: ${track.kind}");
      });

      print("Audio streaming started with echo cancellation enabled.");
    } catch (e) {
      print("Error starting audio streaming: $e");
    }
  }

  bool isRecording() {
    // If the audio stream is not null and contains active audio tracks, it's recording
    return _audioStream != null &&
        _audioStream!.getAudioTracks().any(((track) {
          print("this data is from webRTC : ${track.kind}");
          print("this data is from webRTC : ${track.enabled}");
          if (track.kind == 'audio' && track.enabled) {
            return true;
          } else {
            return false;
          }
        }));
  }

  void _incrementCounter() {
    print("is webRTC recording : ${isRecording()}");
    isRecording();
  }

  Future<void> _loadAudio() async {
    // Load the audio file from assets
    await _audioPlayer.setAsset('assets/audio/audio.mp3');
    _audioPlayer.play();
  }

  @override
  void initState() {
    super.initState();

    // Ensure the audio session is set up for playback and recording
    setAudioSession();

    // Start the audio streaming setup after permissions are handled
    Future.delayed(Duration(seconds: 1), () async {
      await _loadAudio();

      // Add a delay to ensure audio setup completes before streaming starts
      Future.delayed(Duration(seconds: 2), () async {
        // setAudioSession();
        await startAudioStreaming();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

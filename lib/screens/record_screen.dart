import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class RecordScreen extends StatefulWidget {
  final String app;
  final String token;

  RecordScreen({required this.app, required this.token});

  @override
  _RecordScreenState createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  CameraController? _controller;
  List<CameraDescription>? cameras;
  late CameraDescription camera;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
    camera = cameras!.first;

    _controller = CameraController(
      camera,
      ResolutionPreset.high,
    );

    await _controller!.initialize();
    setState(() {});
  }

  void _startRecording() async {
    if (_controller != null && _controller!.value.isInitialized) {
      await _controller!.startVideoRecording();
      setState(() {
        _isRecording = true;
      });
    }
  }

  void _stopRecording() async {
    if (_controller != null && _controller!.value.isRecordingVideo) {
      final file = await _controller!.stopVideoRecording();
      _uploadFile(file.path);
      setState(() {
        _isRecording = false;
      });
    }
  }

  Future<void> _uploadFile(String filePath) async {
    var request = http.MultipartRequest('POST', Uri.parse('https://yourbackend.com/upload'));
    request.headers['Authorization'] = 'Bearer ${widget.token}';
    request.files.add(await http.MultipartFile.fromPath('video', filePath));
    var res = await request.send();

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload successful')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed')),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recording - ${widget.app}'),
      ),
      body: _controller == null || !_controller!.value.isInitialized
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                CameraPreview(_controller!),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: FloatingActionButton(
                      onPressed: _isRecording ? _stopRecording : _startRecording,
                      child: Icon(_isRecording ? Icons.stop : Icons.videocam),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

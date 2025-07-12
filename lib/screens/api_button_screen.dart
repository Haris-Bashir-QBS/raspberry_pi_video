import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:open_file/open_file.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'live_stream_screen.dart';

class ApiButtonScreen extends StatefulWidget {
  const ApiButtonScreen({super.key});

  @override
  State<ApiButtonScreen> createState() => _ApiButtonScreenState();
}

class _ApiButtonScreenState extends State<ApiButtonScreen> {
  final ApiService _apiService = ApiService();
  bool _loading = false;
  String _status = '';
  List<String> _videoList = [];
  int _videoCount = 0;
  final Map<String, String> _downloadedFiles = {};
  bool _connectionStatus = false; // true: connected, false: not connected
  final List<String> _log = [];
  Timer? _statusTimer;
  bool _statusCheckEnabled = true;
  // bool _showLiveStream = false;

  @override
  void initState() {
    super.initState();
    _fetchVideoList();
    _fetchConnectionStatus();
    _startStatusTimer();
  }

  void _startStatusTimer() {
    _statusTimer?.cancel();
    if (_statusCheckEnabled) {
      _statusTimer = Timer.periodic(const Duration(milliseconds: 1500), (
        timer,
      ) {
        _fetchConnectionStatus();
      });
    }
  }

  void _stopStatusTimer() {
    _statusTimer?.cancel();
    _statusTimer = null;
  }

  @override
  void dispose() {
    _stopStatusTimer();
    super.dispose();
  }

  Future<void> _fetchConnectionStatus() async {
    try {
      final response = await _apiService.getStatus();
      setState(() {
        _connectionStatus = response.statusCode == 200;
        _log.insert(0, 'Status: \\${response.statusCode} \\${response.data}');
      });
    } catch (e) {
      setState(() {
        _connectionStatus = false;
        _log.insert(0, 'Status error: $e');
      });
    }
  }

  Future<void> _fetchVideoList() async {
    setState(() {
      _loading = true;
      _status = 'Fetching video list...';
    });
    try {
      final result = await _apiService.fetchVideoList();
      setState(() {
        _videoList = List<String>.from(result['videos'] ?? []);
        _videoCount = result['count'] ?? 0;
        // Remove setting 'Video list loaded' to _status
        _log.insert(0, 'Fetched video list: count=\$_videoCount');
        _status = '';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _log.insert(0, 'Fetch video list error: $e');
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _downloadVideo(String fileName) async {
    setState(() {
      _loading = true;
      _status = 'Downloading $fileName...';
    });
    try {
      final filePath = await _apiService.downloadVideo(fileName);
      setState(() {
        _downloadedFiles[fileName] = filePath;
        _status = 'Downloaded $fileName to $filePath';
        _log.insert(0, 'Downloaded $fileName to $filePath');
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _log.insert(0, 'Download error: $e');
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _openDownloadedFile(String fileName) {
    final filePath = _downloadedFiles[fileName];
    if (filePath != null) {
      OpenFile.open(filePath);
    }
  }

  Future<void> _callApi(Future Function() apiMethod, String label) async {
    setState(() {
      _loading = true;
      _status = 'Calling $label...';
    });
    try {
      final result = await apiMethod();
      if (label == 'download') {
        setState(() {
          _status = 'File downloaded to: $result';
          _log.insert(0, '$label: File downloaded to: $result');
        });
      } else {
        setState(() {
          _status = 'Response: \\${result.statusCode}';
          _log.insert(
            0,
            '$label: Response: \\${result.statusCode} \\${result.data}',
          );
        });
        if (label == 'stop') {
          // Refresh the video list after stopping
          await _fetchVideoList();
        }
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _log.insert(0, '$label error: $e');
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _openLiveStream() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const LiveStreamScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        actions: [
          Row(
            children: [
              const Text(
                'Status Check',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Switch(
                value: _statusCheckEnabled,
                activeColor: Colors.green,
                inactiveThumbColor: Colors.grey,
                onChanged: (val) {
                  setState(() {
                    _statusCheckEnabled = val;
                    if (val) {
                      _startStatusTimer();
                      _fetchConnectionStatus();
                    } else {
                      _stopStatusTimer();
                    }
                  });
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Chip(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 0,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  avatar: Icon(
                    _statusCheckEnabled
                        ? (_connectionStatus
                            ? Icons.check_circle
                            : Icons.cancel)
                        : Icons.radio_button_unchecked,
                    color:
                        _statusCheckEnabled
                            ? (_connectionStatus ? Colors.green : Colors.red)
                            : Colors.grey,
                    size: 14,
                  ),
                  label: Text(
                    _statusCheckEnabled
                        ? (_connectionStatus ? 'Connected' : 'Disconnected')
                        : 'Status Off',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  backgroundColor:
                      _statusCheckEnabled
                          ? (_connectionStatus ? Colors.green : Colors.red)
                          : Colors.grey,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[100],
        child: Column(
          children: [
            // Padding(
            //   padding: const EdgeInsets.only(
            //     top: 12.0,
            //     left: 16,
            //     right: 16,
            //     bottom: 4,
            //   ),
            //   child: Row(
            //     children: [
            //       Icon(Icons.live_tv, color: Colors.deepPurple),
            //       const SizedBox(width: 8),
            //       Text(
            //         'Live Stream',
            //         style: TextStyle(
            //           fontWeight: FontWeight.bold,
            //           color: Colors.deepPurple[700],
            //           fontSize: 16,
            //         ),
            //       ),
            //       const Spacer(),
            //       Switch(
            //         value: _showLiveStream,
            //         activeColor: Colors.deepPurple,
            //         onChanged: (val) {
            //           setState(() {
            //             _showLiveStream = val;
            //           });
            //         },
            //       ),
            //     ],
            //   ),
            // ),
            // if (_showLiveStream)
            //   const Padding(
            //     padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
            //     child: AspectRatio(
            //       aspectRatio: 4 / 3,
            //       child: LiveStreamWidget(),
            //     ),
            //   ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        foregroundColor: Colors.white,
                      ),
                      onPressed:
                          _loading
                              ? null
                              : () => _callApi(_apiService.start, 'start'),
                      icon: const Icon(Icons.play_arrow, color: Colors.white),
                      label: const Text(
                        'Start',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        foregroundColor: Colors.white,
                      ),
                      onPressed:
                          _loading
                              ? null
                              : () => _callApi(_apiService.stop, 'stop'),
                      icon: const Icon(Icons.stop, color: Colors.white),
                      label: const Text(
                        'Stop',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: CircularProgressIndicator(),
              ),
            if (_status.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _status,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            if (_status.startsWith('Error:'))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _loading ? null : _fetchVideoList,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text('Retry'),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Icon(Icons.video_library, color: Colors.indigo[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Video List',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo[700],
                    ),
                  ),
                  const Spacer(),
                  if (_videoCount > 0)
                    Text(
                      'Total: $_videoCount',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
            const Divider(thickness: 2),
            Expanded(
              flex: 5,
              child: RefreshIndicator(
                onRefresh: _fetchVideoList,
                child: ListView.builder(
                  itemCount: _videoList.length,
                  itemBuilder: (context, index) {
                    final fileName = _videoList[index];
                    final isDownloaded = _downloadedFiles.containsKey(fileName);
                    final cardColor =
                        index % 2 == 0 ? Colors.white : Colors.indigo[50];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 6.0,
                      ),
                      child: Card(
                        color: cardColor,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.indigo[100],
                            child: Icon(
                              Icons.videocam,
                              color: Colors.indigo[700],
                            ),
                          ),
                          title: Text(
                            fileName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          trailing: SizedBox(
                            width: 90,
                            child:
                                isDownloaded
                                    ? ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 4,
                                        ),
                                        minimumSize: const Size(0, 28),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed:
                                          () => _openDownloadedFile(fileName),
                                      icon: const Icon(
                                        Icons.play_circle_fill,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      label: const Text(
                                        'View',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                        ),
                                      ),
                                    )
                                    : ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 4,
                                        ),
                                        minimumSize: const Size(0, 28),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed:
                                          _loading
                                              ? null
                                              : () => _downloadVideo(fileName),
                                      icon: const Icon(
                                        Icons.download,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      label: const Text(
                                        'Download',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const Divider(thickness: 2),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Icon(Icons.list_alt, color: Colors.indigo[700]),
                  const SizedBox(width: 8),
                  Text(
                    'API Log',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.indigo,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                color: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.builder(
                  reverse: true,
                  itemCount: _log.length,
                  itemBuilder:
                      (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 2.0,
                        ),
                        child: Text(
                          _log[index],
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.greenAccent,
                            fontFamily: 'RobotoMono',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LiveStreamWidget extends StatefulWidget {
  const LiveStreamWidget({super.key});

  @override
  State<LiveStreamWidget> createState() => _LiveStreamWidgetState();
}

class _LiveStreamWidgetState extends State<LiveStreamWidget> {
  Uint8List? _currentFrame;
  bool _running = true;
  late final ApiService _apiService;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _startPolling();
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) async {
      if (!_running) return;
      final base64Image = await _apiService.fetchStreamFrame();
      if (base64Image != null && mounted) {
        try {
          final bytes = base64Decode(base64Image);
          setState(() {
            _currentFrame = bytes;
          });
        } catch (_) {}
      }
    });
  }

  @override
  void dispose() {
    _running = false;
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child:
            _currentFrame != null
                ? Image.memory(_currentFrame!, gaplessPlayback: true)
                : const CircularProgressIndicator(),
      ),
    );
  }
}

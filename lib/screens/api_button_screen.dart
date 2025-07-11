import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:open_file/open_file.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchVideoList();
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
        _status = 'Video list loaded';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
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
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
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
        });
      } else {
        setState(() {
          _status = 'Response: \\${result.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API Button Demo')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _loading
                            ? null
                            : () => _callApi(_apiService.start, 'start'),
                    child: const Text('Start'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _loading
                            ? null
                            : () => _callApi(_apiService.stop, 'stop'),
                    child: const Text('Stop'),
                  ),
                ),
              ],
            ),
          ),
          if (_loading) const CircularProgressIndicator(),
          if (_status.isNotEmpty)
            Padding(padding: const EdgeInsets.all(8.0), child: Text(_status)),
          if (_status.startsWith('Error:'))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: ElevatedButton(
                onPressed: _loading ? null : _fetchVideoList,
                child: const Text('Retry'),
              ),
            ),
          if (_videoCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text('Total videos: $_videoCount'),
            ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: _videoList.length,
              itemBuilder: (context, index) {
                final fileName = _videoList[index];
                final isDownloaded = _downloadedFiles.containsKey(fileName);
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  child: Card(
                    child: ListTile(
                      title: Text(fileName),
                      trailing: SizedBox(
                        width: 120,
                        child:
                            isDownloaded
                                ? ElevatedButton(
                                  onPressed:
                                      () => _openDownloadedFile(fileName),
                                  child: const Text('View'),
                                )
                                : ElevatedButton(
                                  onPressed:
                                      _loading
                                          ? null
                                          : () => _downloadVideo(fileName),
                                  child: const Text('Download'),
                                ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

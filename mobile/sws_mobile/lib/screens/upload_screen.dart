import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../api/api_service.dart';
import '../theme.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});
  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final ApiService _api = ApiService();
  List<PlatformFile> _selectedFiles = [];
  Map<String, double> _progress = {};
  Map<String, String> _statuses = {};
  bool _isBulkUploading = false;
  bool _isUploading = false;

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      setState(() {
        _selectedFiles = result.files;
        _progress = {for (var f in result.files) f.name: 0.0};
        _statuses = {for (var f in result.files) f.name: 'queued'};
      });
    }
  }

  Future<void> _uploadFiles() async {
    if (_selectedFiles.isEmpty) return;
    setState(() => _isUploading = true);

    final files = _selectedFiles.map((f) => File(f.path!)).toList();

    if (_selectedFiles.length > 3) {
      setState(() => _isBulkUploading = true);
    } else {
      // Simulate per-file progress
      for (var f in _selectedFiles) {
        setState(() => _statuses[f.name] = 'uploading');
        for (int i = 1; i <= 10; i++) {
          await Future.delayed(const Duration(milliseconds: 100));
          setState(() => _progress[f.name] = i / 10);
        }
        setState(() => _statuses[f.name] = 'complete');
      }
    }

    await _api.uploadFiles(files);
    setState(() {
      _isUploading = false;
      if (!_isBulkUploading) _selectedFiles = [];
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upload complete!'),
          backgroundColor: AppTheme.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Documents')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Drop zone
            GestureDetector(
              onTap: _pickFiles,
              child: Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.primary,
                    style: BorderStyle.solid,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  color: AppTheme.primary.withOpacity(0.05),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 48,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to select PDF files',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Supports multiple files',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bulk banner
            if (_isBulkUploading) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_sync, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      'Uploading ${_selectedFiles.length} files in background…',
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // File list with progress
            Expanded(
              child: ListView.builder(
                itemCount: _selectedFiles.length,
                itemBuilder: (context, index) {
                  final file = _selectedFiles[index];
                  final prog = _progress[file.name] ?? 0.0;
                  final status = _statuses[file.name] ?? 'queued';
                  final sizeKb = ((file.size ?? 0) / 1024).toStringAsFixed(1);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.picture_as_pdf,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  file.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              _statusChip(status),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$sizeKb KB',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          if (status == 'uploading') ...[
                            const SizedBox(height: 8),
                            LinearPercentIndicator(
                              percent: prog,
                              lineHeight: 6,
                              progressColor: AppTheme.primary,
                              backgroundColor: AppTheme.primary.withOpacity(
                                0.15,
                              ),
                              barRadius: const Radius.circular(4),
                              trailing: Text(
                                '${(prog * 100).toInt()}%',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Upload button
            if (_selectedFiles.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isUploading ? null : _uploadFiles,
                  icon: const Icon(Icons.upload),
                  label: Text(
                    _isUploading
                        ? 'Uploading…'
                        : 'Upload ${_selectedFiles.length} File(s)',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final colors = {
      'queued': Colors.grey,
      'uploading': Colors.blue,
      'complete': Colors.green,
      'failed': Colors.red,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (colors[status] ?? Colors.grey).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: colors[status] ?? Colors.grey,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

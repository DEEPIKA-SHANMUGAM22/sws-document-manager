import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../models/document.dart';
import '../theme.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});
  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final ApiService _api = ApiService();
  List<Document> _docs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDocs();
  }

  Future<void> _loadDocs() async {
    setState(() => _loading = true);
    final docs = await _api.getDocuments();
    setState(() {
      _docs = docs;
      _loading = false;
    });
  }

  Future<void> _delete(int id) async {
    await _api.deleteDocument(id);
    _loadDocs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Library'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadDocs),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _docs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 64,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No documents yet',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadDocs,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _docs.length,
                itemBuilder: (context, index) {
                  final doc = _docs[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.picture_as_pdf,
                          color: Colors.red,
                        ),
                      ),
                      title: Text(
                        doc.originalName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        '${doc.formattedSize} • ${doc.uploadDate.substring(0, 10)}',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () => _delete(doc.id),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

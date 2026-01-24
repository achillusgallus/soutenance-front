import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerPage extends StatefulWidget {
  final String pdfUrl;
  final String title;

  const PdfViewerPage({super.key, required this.pdfUrl, required this.title});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  late final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    // 1. Force HTTPS logic
    final secureUrl = widget.pdfUrl.replaceFirst('http://', 'https://');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.black87, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _pdfViewerKey.currentState
                  ?.clearSelection(); // Reset visual state if needed
              // Simply rebuilding usually triggers reload for SfPdfViewer if key changes,
              // but here we just rely on internal refresh or user could re-open.
              // A better refresh is to setState to trigger key change?
              setState(() {});
            },
          ),
        ],
      ),
      body: SfPdfViewer.network(
        secureUrl,
        key: _pdfViewerKey,
        onDocumentLoaded: (PdfDocumentLoadedDetails details) {
          setState(() => _isLoading = false);
        },
        onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
          setState(() {
            _isLoading = false;
            _errorMessage =
                "Erreur de chargement: ${details.error}\n${details.description}";
          });
        },
        canShowScrollHead: true,
        canShowScrollStatus: true,
      ),
    );
  }
}

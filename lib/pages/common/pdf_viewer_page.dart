import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:togoschool/service/token_storage.dart';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditionnels pour Web
import 'dart:ui_web' as ui_web;
import 'dart:html' as html;

class PdfViewerPage extends StatefulWidget {
  final String pdfUrl;
  final String title;

  const PdfViewerPage({super.key, required this.pdfUrl, required this.title});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  late final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  final PdfViewerController _pdfViewerController = PdfViewerController();

  Uint8List? _pdfBytes;
  String? _blobUrl;
  String? _currentViewId;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  @override
  void dispose() {
    _cleanupBlob();
    super.dispose();
  }

  void _cleanupBlob() {
    if (_blobUrl != null) {
      html.Url.revokeObjectUrl(_blobUrl!);
      _blobUrl = null;
    }
  }

  Future<void> _loadPdf() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentViewId = null;
    });

    try {
      final token = await TokenStorage.getToken();
      final options = Options(
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
        responseType: ResponseType.bytes,
      );

      final dio = Dio();
      final response = await dio.get(widget.pdfUrl, options: options);

      if (response.statusCode == 200) {
        if (mounted) {
          final bytes = Uint8List.fromList(response.data);
          _cleanupBlob();

          if (kIsWeb) {
            final blob = html.Blob([bytes], 'application/pdf');
            final url = html.Url.createObjectUrlFromBlob(blob);
            // On utilise un ID unique temporel pour forcer le rafraîchissement
            final viewId = 'pdf-view-${DateTime.now().millisecondsSinceEpoch}';

            ui_web.platformViewRegistry.registerViewFactory(
              viewId,
              (int viewId) => html.IFrameElement()
                ..src = url
                ..style.border = 'none'
                ..width = '100%'
                ..height = '100%',
            );

            setState(() {
              _blobUrl = url;
              _currentViewId = viewId;
              _pdfBytes = bytes;
              _isLoading = false;
            });
          } else {
            setState(() {
              _pdfBytes = bytes;
              _isLoading = false;
            });
          }
        }
      } else {
        throw Exception("Erreur serveur: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              "Impossible de charger le document sécurisé. \nErreur: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.black87, fontSize: 14),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          if (_blobUrl != null && kIsWeb)
            IconButton(
              icon: const Icon(Icons.open_in_new),
              tooltip: "Ouvrir dans le navigateur",
              onPressed: () => html.window.open(_blobUrl!, "_blank"),
            ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadPdf),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Préparation du document sécurisé..."),
                ],
              ),
            )
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(_errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadPdf,
                      child: const Text("Réessayer"),
                    ),
                  ],
                ),
              ),
            )
          : kIsWeb && _currentViewId != null
          ? HtmlElementView(viewType: _currentViewId!)
          : SfPdfViewer.memory(
              _pdfBytes!,
              key: _pdfViewerKey,
              controller: _pdfViewerController,
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:togoschool/services/stockage_jeton.dart';
import 'package:togoschool/services/service_progres.dart';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

// Conditionnels pour Web
import 'dart:ui_web' as ui_web;
import 'dart:html' as html;

class PdfViewerPage extends StatefulWidget {
  final String pdfUrl;
  final String title;
  final int? courseId;

  const PdfViewerPage({
    super.key,
    required this.pdfUrl,
    required this.title,
    this.courseId,
  });

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  late final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  final PdfViewerController _pdfViewerController = PdfViewerController();
  final ProgressService _progressService = ProgressService();

  Uint8List? _pdfBytes;
  String? _blobUrl;
  String? _currentViewId;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isOffline = false;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _loadPdf();
  }

  @override
  void dispose() {
    _saveProgress();
    _cleanupBlob();
    super.dispose();
  }

  Future<void> _saveProgress() async {
    if (_startTime != null && widget.courseId != null) {
      final timeSpent = DateTime.now().difference(_startTime!).inSeconds;
      try {
        await _progressService.saveProgressLocally(
          widget.courseId!,
          100, // Considérer comme complété quand le PDF est ouvert
          timeSpent,
        );
      } catch (e) {
        print('Erreur sauvegarde progression: $e');
      }
    }
  }

  void _cleanupBlob() {
    if (_blobUrl != null) {
      html.Url.revokeObjectUrl(_blobUrl!);
      _blobUrl = null;
    }
  }

  // Créer une clé de cache unique basée sur l'URL
  String _getCacheKey() {
    return md5.convert(utf8.encode(widget.pdfUrl)).toString();
  }

  Future<void> _loadPdf() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentViewId = null;
    });

    final cacheKey = _getCacheKey();
    final box = Hive.box('pdf_cache');

    // 1. Vérifier le cache local pour l'accès hors-ligne
    if (box.containsKey(cacheKey)) {
      final cachedData = box.get(cacheKey);
      if (cachedData is Uint8List) {
        setState(() {
          _pdfBytes = cachedData;
          _isOffline = true;
        });
        _prepareView(cachedData);
        return;
      }
    }

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

          // Sauvegarder en cache
          await box.put(cacheKey, bytes);

          setState(() => _isOffline = false);
          _prepareView(bytes);
        }
      } else {
        throw Exception("Erreur serveur: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              "Impossible de charger le document sécurisé (vérifiez votre connexion). \nErreur: $e";
        });
      }
    }
  }

  void _prepareView(Uint8List bytes) {
    if (!mounted) return;
    _cleanupBlob();

    if (kIsWeb) {
      final blob = html.Blob([bytes], 'application/pdf');
      // On ajoute des paramètres pour cacher la barre d'outils du navigateur
      final url =
          html.Url.createObjectUrlFromBlob(blob) +
          "#toolbar=0&navpanes=0&scrollbar=0";
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title + (_isOffline ? " (Hors-ligne)" : ""),
          style: const TextStyle(color: Colors.black87, fontSize: 13),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
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

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:togoschool/services/student_feature_service.dart';
import 'package:togoschool/services/service_api.dart';

class ManageStudentFeatures extends StatefulWidget {
  const ManageStudentFeatures({super.key});

  @override
  State<ManageStudentFeatures> createState() => _ManageStudentFeaturesState();
}

class _ManageStudentFeaturesState extends State<ManageStudentFeatures>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final StudentFeatureService _featureService = StudentFeatureService();
  final ApiService _api = ApiService();

  List<dynamic> _discoveryResources = [];
  List<dynamic> _educationalNews = [];
  List<dynamic> _matieres = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _featureService.getAllDiscoveryAdmin(),
        _featureService.getAllNewsAdmin(),
        _api.read('/admin/matieres'),
      ]);
      setState(() {
        _discoveryResources = results[0] as List<dynamic>;
        _educationalNews = results[1] as List<dynamic>;
        _matieres = (results[2] as dynamic)?.data ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erreur de chargement: $e")));
      }
    }
  }

  void _showDiscoveryForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DiscoveryFormSheet(onSaved: _loadAll),
    );
  }

  void _showNewsForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          NewsFormSheet(matieres: _matieres, onSaved: _loadAll),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestion des contenus"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              text: "Découvertes (Jour)",
              icon: Icon(Icons.lightbulb_outline),
            ),
            Tab(text: "Actualités Éducatives", icon: Icon(Icons.newspaper)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildDiscoveryList(), _buildNewsList()],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            _tabController.index == 0 ? _showDiscoveryForm() : _showNewsForm(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDiscoveryList() {
    if (_discoveryResources.isEmpty) {
      return const Center(child: Text("Aucune ressource"));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _discoveryResources.length,
      itemBuilder: (context, index) {
        final item = _discoveryResources[index];
        return Card(
          child: ListTile(
            leading: Icon(_getDiscoveryIcon(item['type'])),
            title: Text(item['title']),
            subtitle: Text("Date d'affichage : ${item['display_date']}"),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteDiscovery(item['id']),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNewsList() {
    if (_educationalNews.isEmpty) {
      return const Center(child: Text("Aucune actualité"));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _educationalNews.length,
      itemBuilder: (context, index) {
        final item = _educationalNews[index];
        return Card(
          child: ListTile(
            leading: item['image_url'] != null
                ? CircleAvatar(backgroundImage: NetworkImage(item['image_url']))
                : const Icon(Icons.article),
            title: Text(item['title']),
            subtitle: Text(item['matiere_nom'] ?? "Général"),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteNews(item['id']),
            ),
          ),
        );
      },
    );
  }

  IconData _getDiscoveryIcon(String type) {
    switch (type) {
      case 'video':
        return Icons.play_circle_outline;
      case 'tip':
        return Icons.tips_and_updates;
      case 'anecdote':
        return Icons.history_edu;
      default:
        return Icons.help_outline;
    }
  }

  Future<void> _deleteDiscovery(int id) async {
    try {
      if (await _featureService.deleteDiscovery(id)) _loadAll();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erreur de suppression: $e")));
      }
    }
  }

  Future<void> _deleteNews(int id) async {
    try {
      if (await _featureService.deleteNews(id)) _loadAll();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erreur de suppression: $e")));
      }
    }
  }
}

class DiscoveryFormSheet extends StatefulWidget {
  final VoidCallback onSaved;
  const DiscoveryFormSheet({super.key, required this.onSaved});

  @override
  State<DiscoveryFormSheet> createState() => _DiscoveryFormSheetState();
}

class _DiscoveryFormSheetState extends State<DiscoveryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _type = 'tip';
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(
        20,
      ).copyWith(bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Nouvelle Découverte",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Titre",
                border: OutlineInputBorder(),
              ),
              validator: (v) => v?.isEmpty ?? true ? "Champ requis" : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _type,
              items: [
                'video',
                'tip',
                'anecdote',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _type = v!),
              decoration: const InputDecoration(
                labelText: "Type",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: "Contenu (Texte ou URL Vidéo)",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (v) => v?.isEmpty ?? true ? "Champ requis" : null,
            ),
            const SizedBox(height: 12),
            ListTile(
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey[400]!),
                borderRadius: BorderRadius.circular(5),
              ),
              title: Text(
                "Date d'affichage : ${_selectedDate.toLocal().toString().split(' ')[0]}",
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) setState(() => _selectedDate = date);
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("ENREGISTRER"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      try {
        final service = StudentFeatureService();
        final success = await service.createDiscovery(
          title: _titleController.text,
          type: _type,
          content: _contentController.text,
          displayDate: _selectedDate.toLocal().toString().split(' ')[0],
        );
        setState(() => _isSaving = false);
        if (success) {
          widget.onSaved();
          if (mounted) Navigator.pop(context);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Échec de l'enregistrement")),
            );
          }
        }
      } catch (e) {
        setState(() => _isSaving = false);
        if (mounted) {
          String errorMsg = e.toString().replaceFirst('Exception: ', '');
          if (errorMsg.contains('already been taken')) {
            errorMsg =
                "Une découverte existe déjà pour cette date. Choisissez une autre date.";
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Erreur : $errorMsg"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class NewsFormSheet extends StatefulWidget {
  final List<dynamic> matieres;
  final VoidCallback onSaved;
  const NewsFormSheet({
    super.key,
    required this.matieres,
    required this.onSaved,
  });

  @override
  State<NewsFormSheet> createState() => _NewsFormSheetState();
}

class _NewsFormSheetState extends State<NewsFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  int? _selectedMatiereId;
  File? _imageFile;
  Uint8List? _webImage;
  String? _selectedFileName;
  bool _isSaving = false;

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _webImage = result.files.single.bytes;
        _selectedFileName = result.files.single.name;
        if (!kIsWeb && result.files.single.path != null) {
          _imageFile = File(result.files.single.path!);
        } else {
          _imageFile = null;
        }
      });
    } else if (result != null && result.files.single.path != null) {
      setState(() {
        _imageFile = File(result.files.single.path!);
        _selectedFileName = result.files.single.name;
        _webImage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(
        20,
      ).copyWith(bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Nouvelle Actualité",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "Titre",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty ?? true ? "Champ requis" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: "Contenu",
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (v) => v?.isEmpty ?? true ? "Champ requis" : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _selectedMatiereId,
                items: widget.matieres
                    .map(
                      (e) => DropdownMenuItem<int>(
                        value: e['id'],
                        child: Text(e['nom']),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedMatiereId = v),
                decoration: const InputDecoration(
                  labelText: "Matière (Optionnel)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: _webImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: Image.memory(_webImage!, fit: BoxFit.cover),
                        )
                      : _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: Image.file(_imageFile!, fit: BoxFit.cover),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, color: Colors.grey),
                            Text(
                              "Ajouter une image (Optionnel)",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("ENREGISTRER"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      try {
        final service = StudentFeatureService();
        final success = await service.createNews(
          title: _titleController.text,
          content: _contentController.text,
          matiereId: _selectedMatiereId,
          image: _imageFile,
          imageBytes: _webImage,
          fileName: _selectedFileName,
        );
        setState(() => _isSaving = false);
        if (success) {
          widget.onSaved();
          if (mounted) Navigator.pop(context);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Échec de l'enregistrement")),
            );
          }
        }
      } catch (e) {
        setState(() => _isSaving = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Erreur : ${e.toString().replaceFirst('Exception: ', '')}",
              ),
            ),
          );
        }
      }
    }
  }
}

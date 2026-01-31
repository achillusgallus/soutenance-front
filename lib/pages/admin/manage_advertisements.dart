import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:togoschool/models/advertisement.dart';
import 'package:togoschool/services/advertisement_service.dart';

class ManageAdvertisements extends StatefulWidget {
  const ManageAdvertisements({super.key});

  @override
  State<ManageAdvertisements> createState() => _ManageAdvertisementsState();
}

class _ManageAdvertisementsState extends State<ManageAdvertisements> {
  final AdvertisementService _adService = AdvertisementService();
  List<Advertisement> _ads = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAds();
  }

  Future<void> _loadAds() async {
    setState(() => _isLoading = true);
    final ads = await _adService.getAllAdvertisementsAdmin();
    setState(() {
      _ads = ads;
      _isLoading = false;
    });
  }

  void _showAdForm({Advertisement? ad}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdFormSheet(ad: ad, onSaved: _loadAds),
    );
  }

  Future<void> _deleteAd(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: const Text("Voulez-vous vraiment supprimer cette publicité ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _adService.deleteAdvertisement(id);
        if (success) {
          _loadAds();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Publicité supprimée")),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Erreur : ${e.toString()}")));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gérer les publicités"),
        actions: [
          IconButton(onPressed: _loadAds, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _ads.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.ads_click, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text("Aucune publicité configurée"),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showAdForm(),
                    child: const Text("Ajouter ma première publicité"),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _ads.length,
              itemBuilder: (context, index) {
                final ad = _ads[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      if (ad.imageUrl.isNotEmpty)
                        Image.network(
                          ad.imageUrl,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                height: 150,
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image, size: 50),
                              ),
                        ),
                      ListTile(
                        title: Text(
                          ad.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(ad.description ?? "Pas de description"),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              ad.isActive ? Icons.check_circle : Icons.cancel,
                              color: ad.isActive ? Colors.green : Colors.red,
                            ),
                            Text(
                              ad.isActive ? "Active" : "Inactif",
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () => _showAdForm(ad: ad),
                              icon: const Icon(Icons.edit),
                              label: const Text("Modifier"),
                            ),
                            TextButton.icon(
                              onPressed: () => _deleteAd(ad.id),
                              icon: const Icon(Icons.delete, color: Colors.red),
                              label: const Text(
                                "Supprimer",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAdForm(),
        label: const Text("Nouvelle Pub"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class AdFormSheet extends StatefulWidget {
  final Advertisement? ad;
  final VoidCallback onSaved;

  const AdFormSheet({super.key, this.ad, required this.onSaved});

  @override
  State<AdFormSheet> createState() => _AdFormSheetState();
}

class _AdFormSheetState extends State<AdFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _linkController;
  late TextEditingController _orderController;
  late TextEditingController
  _startDateController; // Contrôleur pour l'affichage de la date
  late bool _isActive;
  File? _selectedImage;
  Uint8List? _webImage;
  String? _selectedFileName;
  bool _isSaving = false;
  String _selectedType = 'general';
  DateTime? _selectedDate;

  final List<Map<String, String>> _types = [
    {'value': 'general', 'label': 'Général'},
    {'value': 'event', 'label': 'Événement'},
    {'value': 'promo', 'label': 'Promotion'},
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.ad?.title);
    _descController = TextEditingController(text: widget.ad?.description);
    _linkController = TextEditingController(text: widget.ad?.linkUrl);
    _orderController = TextEditingController(
      text: widget.ad?.order.toString() ?? "0",
    );
    _isActive = widget.ad?.isActive ?? true;
    _selectedType = widget.ad?.type ?? 'general';
    _selectedDate = widget.ad?.startDate;
    _startDateController = TextEditingController(
      text: _selectedDate != null ? _formatDate(_selectedDate!) : '',
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _linkController.dispose();
    _orderController.dispose();
    _startDateController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _webImage = result.files.single.bytes;
        _selectedFileName = result.files.single.name;
        // On n'utilise File que si on n'est pas sur le Web
        if (!kIsWeb && result.files.single.path != null) {
          _selectedImage = File(result.files.single.path!);
        } else {
          _selectedImage = null;
        }
      });
    } else if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedImage = File(result.files.single.path!);
        _selectedFileName = result.files.single.name;
        _webImage = null;
      });
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _startDateController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.ad == null && _selectedImage == null && _webImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez sélectionner une image")),
      );
      return;
    }

    try {
      setState(() => _isSaving = true);
      final service = AdvertisementService();
      bool success;

      if (widget.ad == null) {
        success = await service.createAdvertisement(
          title: _titleController.text,
          description: _descController.text,
          imageFile: _selectedImage,
          imageBytes: _webImage,
          fileName: _selectedFileName,
          linkUrl: _linkController.text,
          order: int.tryParse(_orderController.text) ?? 0,
          isActive: _isActive,
          type: _selectedType,
          startDate: _selectedDate,
        );
      } else {
        success = await service.updateAdvertisement(
          widget.ad!.id,
          title: _titleController.text,
          description: _descController.text,
          imageFile: _selectedImage,
          imageBytes: _webImage,
          fileName: _selectedFileName,
          linkUrl: _linkController.text,
          isActive: _isActive,
          order: int.tryParse(_orderController.text) ?? 0,
          type: _selectedType,
          startDate: _selectedDate,
        );
      }

      setState(() => _isSaving = false);
      if (success) {
        widget.onSaved();
        if (mounted) Navigator.pop(context);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Échec de l'enregistrement sur le serveur"),
            ),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.ad == null ? "Nouvelle Publicité" : "Modifier Publicité",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Type Dropdown
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: "Type de publicité",
                  border: OutlineInputBorder(),
                ),
                items: _types.map((type) {
                  return DropdownMenuItem(
                    value: type['value'],
                    child: Text(type['label']!),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedType = val);
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "Titre",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? "Champ requis" : null,
              ),
              const SizedBox(height: 16),

              if (_selectedType == 'event') ...[
                TextFormField(
                  controller: _startDateController,
                  readOnly: true,
                  onTap: _pickDate,
                  decoration: const InputDecoration(
                    labelText: "Date de l'événement",
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  validator: (v) =>
                      _selectedType == 'event' && (v == null || v.isEmpty)
                      ? "Date requise pour un événement"
                      : null,
                ),
                const SizedBox(height: 16),
              ],

              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _linkController,
                decoration: const InputDecoration(
                  labelText: "Lien de redirection (ex: /cours)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _orderController,
                      decoration: const InputDecoration(
                        labelText: "Ordre d'affichage",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Switch(
                    value: _isActive,
                    onChanged: (val) => setState(() => _isActive = val),
                  ),
                  const Text("Active"),
                ],
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: _webImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(_webImage!, fit: BoxFit.cover),
                        )
                      : _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(_selectedImage!, fit: BoxFit.cover),
                        )
                      : widget.ad != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            widget.ad!.imageUrl,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              size: 40,
                              color: Colors.grey,
                            ),
                            Text("Sélectionner une image"),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(widget.ad == null ? "PUBLIER" : "METTRE À JOUR"),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

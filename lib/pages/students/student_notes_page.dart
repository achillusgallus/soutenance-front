import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:togoschool/service/progress_service.dart';

class StudentNotesPage extends StatefulWidget {
  final int? courseId;
  final String? courseName;

  const StudentNotesPage({super.key, this.courseId, this.courseName});

  @override
  State<StudentNotesPage> createState() => _StudentNotesPageState();
}

class _StudentNotesPageState extends State<StudentNotesPage> {
  final ProgressService _progressService = ProgressService();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<dynamic> _notes = [];
  List<dynamic> _filteredNotes = [];
  int? _editingNoteId;

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _searchController.addListener(_filterNotes);
  }

  @override
  void dispose() {
    _noteController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    try {
      final courseId = widget.courseId;
      if (courseId != null) {
        final notes = await _progressService.getNotes(courseId);
        if (mounted) {
          setState(() {
            _notes = notes;
            _filteredNotes = notes;
            _isLoading = false;
          });
        }
      } else {
        // Charger toutes les notes si aucun cours spécifique
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterNotes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredNotes = _notes.where((note) {
        final content = note['content']?.toString().toLowerCase() ?? '';
        final courseName = note['course_name']?.toString().toLowerCase() ?? '';
        return content.contains(query) || courseName.contains(query);
      }).toList();
    });
  }

  Future<void> _saveNote() async {
    if (_noteController.text.trim().isEmpty) return;

    try {
      final courseId = widget.courseId ?? 1; // ID par défaut si aucun cours
      final success = await _progressService.saveNote(courseId, _noteController.text);

      if (success) {
        if (_editingNoteId != null) {
          // Mode édition
          setState(() {
            final index = _notes.indexWhere((note) => note['id'] == _editingNoteId);
            if (index != -1) {
              _notes[index]['content'] = _noteController.text;
              _notes[index]['updated_at'] = DateTime.now().toIso8601String();
            }
            _editingNoteId = null;
          });
        } else {
          // Mode ajout
          setState(() {
            _notes.insert(0, {
              'id': DateTime.now().millisecondsSinceEpoch,
              'content': _noteController.text,
              'course_id': courseId,
              'course_name': widget.courseName ?? 'Note',
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
          });
        }

        _noteController.clear();
        _filterNotes();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_editingNoteId != null ? 'Note mise à jour' : 'Note enregistrée'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de l\'enregistrement de la note'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editNote(Map<String, dynamic> note) {
    setState(() {
      _editingNoteId = note['id'];
      _noteController.text = note['content'] ?? '';
    });
  }

  void _deleteNote(int noteId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la note'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette note ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _notes.removeWhere((note) => note['id'] == noteId);
                _filterNotes();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Note supprimée'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.courseName != null ? 'Notes - ${widget.courseName}' : 'Mes Notes',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF8B5CF6),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildNoteEditor(),
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredNotes.isEmpty
                    ? _buildEmptyState()
                    : _buildNotesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteEditor() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: _editingNoteId != null 
                        ? 'Modifiez votre note...' 
                        : 'Prenez une note...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  IconButton(
                    onPressed: _saveNote,
                    icon: Icon(
                      _editingNoteId != null ? FontAwesomeIcons.edit : FontAwesomeIcons.save,
                      color: const Color(0xFF8B5CF6),
                    ),
                  ),
                  if (_editingNoteId != null)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _editingNoteId = null;
                          _noteController.clear();
                        });
                      },
                      icon: const Icon(
                        FontAwesomeIcons.times,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[50],
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher dans vos notes...',
          prefixIcon: const Icon(FontAwesomeIcons.search, color: Color(0xFF8B5CF6)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FontAwesomeIcons.stickyNote,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty 
                ? 'Aucune note trouvée'
                : 'Aucune note',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty
                ? 'Essayez une autre recherche'
                : 'Commencez à prendre des notes pour les voir ici',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredNotes.length,
      itemBuilder: (context, index) {
        final note = _filteredNotes[index];
        return _buildNoteCard(note);
      },
    );
  }

  Widget _buildNoteCard(Map<String, dynamic> note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    note['course_name'] ?? 'Note',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8B5CF6),
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _editNote(note),
                      icon: const Icon(
                        FontAwesomeIcons.edit,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _deleteNote(note['id']),
                      icon: const Icon(
                        FontAwesomeIcons.trash,
                        size: 16,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              note['content'] ?? '',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatDate(note['updated_at'] ?? note['created_at']),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Aujourd\'hui à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        return 'Hier à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays < 7) {
        return 'Il y a ${difference.inDays} jours';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }
}

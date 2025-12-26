class Forum {
  final int id;
  final String titre;
  final String matiereNom;

  Forum({required this.id, required this.titre, required this.matiereNom});

  factory Forum.fromJson(Map<String, dynamic> json) {
    return Forum(
      id: json['id'] ?? 0,
      titre: json['titre'] ?? '',
      matiereNom: json['matiere_nom'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'titre': titre, 'matiere_nom': matiereNom};
  }
}

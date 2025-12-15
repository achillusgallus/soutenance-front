
class User {
  final String nom;
  final String prenom;
  final String classe;
  final String email;
  final String password;

  User({required this.nom, required this.prenom, required this.classe, required this.email, required this.password,});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      nom: json['nom'],
      prenom: json['prenom'],
      classe: json['classe'],
      email: json['email'],
      password: json['password'],
    );
  }
}
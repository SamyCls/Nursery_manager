enum UserRole { admin, standard }

class AppUser {
  final String id;
  final String username;
  final String password;
  final UserRole role;

  AppUser({
    required this.id,
    required this.username,
    required this.password,
    required this.role,
  });

  // 🔹 Getters pratiques
  bool get isAdmin => role == UserRole.admin;
  bool get isStandard => role == UserRole.standard;

  // 🔹 Conversion vers Map pour la base de données
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'role': role.name, // Convertir l'enum en String
    };
  }

  // 🔹 Création depuis Map (depuis la base de données)
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.standard,
      ),
    );
  }

  // 🔹 Méthode pour créer un utilisateur admin par défaut
  static AppUser createDefaultAdmin() {
    return AppUser(
      id: 'admin-001',
      username: 'admin',
      password: 'admin123', // À changer après la première connexion
      role: UserRole.admin,
    );
  }
}
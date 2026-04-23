import 'package:flutter/material.dart';
import '/models/utilisateurs.dart';
import '/db/usersdao.dart';

class ParametersScreen extends StatefulWidget {
  const ParametersScreen({super.key});

  @override
  State<ParametersScreen> createState() => _ParametersScreenState();
}

class _ParametersScreenState extends State<ParametersScreen> {
  final UserDao _userDao = UserDao();
  List<AppUser> _adminUsers = [];
  List<AppUser> _standardUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final allUsers = await _userDao.getAllUsers();
      setState(() {
        _adminUsers = allUsers.where((user) => user.isAdmin).toList();
        _standardUsers = allUsers.where((user) => user.isStandard).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des utilisateurs: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAddUserDialog({UserRole role = UserRole.standard, AppUser? existingUser}) {
    final usernameController = TextEditingController(text: existingUser?.username ?? '');
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final roleController = TextEditingController(text: existingUser?.role.name ?? role.name);
    
    // Variables pour gérer la visibilité des mots de passe
    bool showPassword = false;
    bool showConfirmPassword = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(existingUser == null ? 'Ajouter un utilisateur' : 'Modifier l\'utilisateur'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom d\'utilisateur',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: !showPassword, // Masquer ou afficher le mot de passe
                      decoration: InputDecoration(
                        labelText: existingUser == null ? 'Mot de passe' : 'Nouveau mot de passe (laisser vide pour ne pas changer)',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            showPassword ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              showPassword = !showPassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: !showConfirmPassword, // Masquer ou afficher la confirmation
                      decoration: InputDecoration(
                        labelText: 'Confirmer le mot de passe',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            showConfirmPassword ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              showConfirmPassword = !showConfirmPassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<UserRole>(
                      value: existingUser?.role ?? role,
                      decoration: const InputDecoration(
                        labelText: 'Rôle',
                        border: OutlineInputBorder(),
                      ),
                      items: UserRole.values.map((userRole) {
                        return DropdownMenuItem<UserRole>(
                          value: userRole,
                          child: Text(userRole == UserRole.admin ? 'Administrateur' : 'Standard'),
                        );
                      }).toList(),
                      onChanged: (UserRole? newRole) {
                        roleController.text = newRole?.name ?? role.name;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (usernameController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Le nom d\'utilisateur est requis')),
                      );
                      return;
                    }

                    if (existingUser == null && passwordController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Le mot de passe est requis')),
                      );
                      return;
                    }

                    if (passwordController.text != confirmPasswordController.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Les mots de passe ne correspondent pas')),
                      );
                      return;
                    }

                    try {
                      final newUser = AppUser(
                        id: existingUser?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                        username: usernameController.text,
                        password: passwordController.text.isNotEmpty 
                            ? passwordController.text 
                            : existingUser?.password ?? '',
                        role: UserRole.values.firstWhere(
                          (e) => e.name == roleController.text,
                          orElse: () => UserRole.standard,
                        ),
                      );

                      if (existingUser == null) {
                        await _userDao.insertUser(newUser);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Utilisateur ajouté avec succès')),
                        );
                      } else {
                        await _userDao.updateUser(newUser);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Utilisateur modifié avec succès')),
                        );
                      }

                      Navigator.pop(context);
                      _loadUsers();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur: ${e.toString()}')),
                      );
                    }
                  },
                  child: Text(existingUser == null ? 'Ajouter' : 'Modifier'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(AppUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer l\'utilisateur "${user.username}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _userDao.deleteUser(user.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Utilisateur supprimé avec succès')),
                );
                Navigator.pop(context);
                _loadUsers();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur: ${e.toString()}')),
                );
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(AppUser user) {
    return GestureDetector(
      onTap: () => _showAddUserDialog(existingUser: user),
      child: Container(
        width: 50,
        height: 50,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: user.isAdmin ? Colors.red.shade50 : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: user.isAdmin ? Colors.red.shade200 : Colors.blue.shade200,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Emoji et informations
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '👤', // Emoji personne
                    style: TextStyle(fontSize: 32),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.username,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    user.isAdmin ? 'Admin' : 'Standard',
                    style: TextStyle(
                      fontSize: 10,
                      color: user.isAdmin ? Colors.red : Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            // Boutons d'action en haut à droite
            Positioned(
              top: 4,
              right: 4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
                    onPressed: () => _showAddUserDialog(existingUser: user),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                    onPressed: () => _showDeleteConfirmation(user),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSection(String title, List<AppUser> users, UserRole role) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Bouton +
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.red, size: 28),
              onPressed: () => _showAddUserDialog(role: role),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (users.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Aucun utilisateur',
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6, // 3 cartes par ligne
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1, // Carrés parfaits
            ),
            itemCount: users.length,
            itemBuilder: (context, index) {
              return _buildUserCard(users[index]);
            },
          ),
        
        const SizedBox(height: 24),
        const Divider(thickness: 1),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestion des Utilisateurs", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserSection("👑 Administrateurs", _adminUsers, UserRole.admin),
              const SizedBox(height: 16),
              _buildUserSection("👥 Utilisateurs Standard", _standardUsers, UserRole.standard),
              
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _loadUsers,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text("Actualiser", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
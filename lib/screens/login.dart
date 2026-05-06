import 'package:flutter/material.dart';
import '/dummydata/dummy_data.dart';
import '/screens/dashboard.dart';
import '/models/utilisateurs.dart';
import '/app_state.dart';
import '/db/usersdao.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final UserDao _userDao = UserDao();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _login() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    final String username = _usernameController.text.trim();
    final String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Veuillez remplir tous les champs")),
        );
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      // 1. D'abord essayer avec la base de données
      final AppUser? dbUser = await _userDao.authenticate(username, password);
      
      if (dbUser != null) {
        _handleSuccessfulLogin(dbUser);
        return;
      }

      // 2. Si pas trouvé en base, essayer avec les données dummy (pour la démo)
      final dummyUser = dummyUsers.firstWhere(
        (u) => u.username == username && u.password == password,
        orElse: () => AppUser(id: '', username: '', password: '', role: UserRole.standard),
      );

      if (dummyUser.id.isNotEmpty) {
        _handleSuccessfulLogin(dummyUser);
        
        // Optionnel: Ajouter l'utilisateur dummy à la base de données
        await _userDao.insertUser(dummyUser);
        return;
      }

      // 3. Si aucun des deux ne fonctionne
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Identifiant ou mot de passe incorrect")),
        );
      }

    } catch (e) {
      debugPrint('Erreur de connexion: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur de connexion, veuillez réessayer")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

   void _handleSuccessfulLogin(AppUser user) {
    // Stocker l'utilisateur dans la variable globale
    currentUser = user;
    
    debugPrint('Utilisateur connecté: ${user.username}, Role: ${user.role}');
    
    // Rediriger vers Dashboard
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => DashboardPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const beginOffset = Offset(0.0, 1.0);
          const endOffset = Offset.zero;
          const curve = Curves.easeInOut;

          final tween = Tween(begin: beginOffset, end: endOffset)
              .chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Adapter la disposition en fonction de la largeur de l'écran
          if (constraints.maxWidth < 800) {
            // Disposition verticale pour les petits écrans
            return SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                child: Column(
                  children: [
                    // Partie formulaire
                    _buildLoginForm(),
                    const SizedBox(height: 40),
                    
                    // Partie image (plus petite sur mobile)
                    SizedBox(
                      height: 250,
                      child: Image.asset(
                        "assets/images/login.png",
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else {
            // Disposition horizontale pour les grands écrans
            return Row(
              children: [
                // Partie gauche (formulaire)
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLoginForm(),
                      ],
                    ),
                  ),
                ),

                // Partie droite (image) - avec conteneur pour limiter l'expansion
                Expanded(
                  flex: 1,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 500), // Limite la largeur max
                    child: Image.asset(
                      "assets/images/login.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "CONTENT DE\nVOUS REVOIR !",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "Veuillez entrer vos informations",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 30),

        // Champ Identifiant - TAILLE RÉDUITE
        SizedBox(
          height: 50,
          child: TextField(
            controller: _usernameController,
            decoration: InputDecoration(
              hintText: "Identifiant",
              prefixIcon: const Icon(Icons.person_outline, size: 20),
              filled: true,
              fillColor: const Color(0xfff3f3f3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 15),

        // Champ Mot de passe - TAILLE RÉDUITE
        SizedBox(
          height: 50,
          child: TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: "Mot de passe",
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: Container(
                width: 40,
                alignment: Alignment.center,
                child: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.black,
                    size: 22,
                  ),
                  onPressed: _togglePasswordVisibility,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              filled: true,
              fillColor: const Color(0xfff3f3f3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 25),

        // Bouton Se connecter
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              disabledBackgroundColor: Colors.grey,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    "Se connecter",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
          ),
        ),
      ],
    );
  }
}
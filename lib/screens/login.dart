import 'package:flutter/material.dart';
import '/dummydata/dummy_data.dart';
import '/screens/dashboard.dart';
import '/models/utilisateurs.dart';
import '/app_state.dart';
import '/db/usersdao.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/trial.service.dart'; // Import the trial service

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
  int _remainingDays = 3;
  bool _trialExpired = false;

  @override
  void initState() {
    super.initState();
    _checkTrialStatus();
  }

  Future<void> _checkTrialStatus() async {
    // Use the enhanced trial verification
    final bool expired = await isTrialExpired();
    
    if (expired) {
      if (mounted) {
        setState(() {
          _trialExpired = true;
          _remainingDays = 0;
        });
        
        // Rediriger vers la page d'expiration
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.pushReplacementNamed(context, "/trial_expired");
          }
        });
      }
      return;
    }
    
    // Calculate remaining days if trial is still active
    final prefs = await SharedPreferences.getInstance();
    final installationDate = prefs.getString('installation_date');
    
    if (installationDate == null) {
      if (mounted) {
        setState(() {
          _remainingDays = 30;
          _trialExpired = false;
        });
      }
      return;
    }
    
    final installDate = DateTime.parse(installationDate);
    final currentDate = DateTime.now();
    final difference = currentDate.difference(installDate).inDays;
    final remaining = 30 - difference;
    
    if (mounted) {
      setState(() {
        _remainingDays = remaining > 0 ? remaining : 0;
        _trialExpired = false;
      });
    }
    
    // CRITICAL FIX: Immediately redirect if remaining days calculation is negative
    // This happens when user sets time back to get more days
    if (difference > 30) {
      if (mounted) {
        setState(() {
          _trialExpired = true;
          _remainingDays = 0;
        });
      }
      
      // Mark as expired in preferences
      await prefs.setBool('trial_expired', true);
      
      // Rediriger vers la page d'expiration
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, "/trial_expired");
        }
      });
    }
  }

  Future<void> _login() async {
    // Vérifier d'abord si l'essai est expiré
    if (_trialExpired || await isTrialExpired()) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, "/trial_expired");
      }
      return;
    }
    
    // Additional check: if remaining days calculation shows negative value
    final prefs = await SharedPreferences.getInstance();
    final installationDate = prefs.getString('installation_date');
    if (installationDate != null) {
      final installDate = DateTime.parse(installationDate);
      final currentDate = DateTime.now();
      final difference = currentDate.difference(installDate).inDays;
      
      if (difference > 30) {
        await prefs.setBool('trial_expired', true);
        if (mounted) {
          Navigator.pushReplacementNamed(context, "/trial_expired");
        }
        return;
      }
    }
    
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
    // CRITICAL FIX: Check if remaining days calculation shows negative value
    // and immediately redirect to trial expired screen
    if (_remainingDays < 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, "/trial_expired");
        }
      });
      return Container(); // Return empty container while redirecting
    }
    
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
                    
                    // Affichage des jours d'essai restants - placé en bas
                    const SizedBox(height: 20),
                    _buildTrialInfo(),
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
                        const SizedBox(height: 20),
                        _buildTrialInfo(),
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

  Widget _buildTrialInfo() {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      child: Text(
        _trialExpired 
          ? "Période d'essai expirée" 
          : "Période d'essai: $_remainingDays jour${_remainingDays > 1 ? 's' : ''} restant${_remainingDays > 1 ? 's' : ''}",
        style: TextStyle(
          color: _trialExpired ? Colors.red : Colors.grey,
          fontSize: 14,
          fontWeight: _trialExpired ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '/screens/dashboard.dart';
import '/screens/enfant_screen.dart';
import '/screens/présence.dart';
import '/screens/employe_page.dart';
import '/screens/planing_act.dart';
import '/screens/depenses.dart';
import '/screens/stats.dart';
import '/screens/suivipaie.dart';
import '/screens/settings.dart';
import '/app_state.dart'; // Importez le fichier app_state

/// 🔹 Fonction utilitaire : retourne le bon widget en fonction de la route
Widget _getPageFromRoute(String route) {
  switch (route) {
    case '/':
      return DashboardPage();
    case '/enfants':
      return ListeEnfantsPage();
    case '/presence':
      return PresenceScreen();
    case '/employes':
      return ListeEmployesPage();
    case '/activites':
      return WeeklyPlannerPage();
    case '/depenses':
      return DepensesScreen();
    case '/paiements-enfant':
      return SuiviPaiementsScreen();
    case '/statistiques':
      return StatisticsScreen();
    case '/parametres':
      return ParametersScreen();
    default:
      return DashboardPage();
  }
}

/// 🔹 Composant Sidebar (menu latéral)
class Sidebar extends StatefulWidget {
  const Sidebar({super.key});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> with TickerProviderStateMixin {
  bool _showPaiementSubmenu = false;

  @override
  void initState() {
    super.initState();
    print('Sidebar initialisé avec utilisateur: ${currentUser?.username}, Role: ${currentUser?.role}'); // Debug
  }

  // Définissez les menus pour chaque type d'utilisateur
  List<Map<String, dynamic>> get menuItems {
    if (currentUser == null) {
      print('Aucun utilisateur connecté'); // Debug
      return [];
    }
    
    print('Chargement du menu pour: ${currentUser!.username}, Admin: ${currentUser!.isAdmin}'); // Debug
    
    if (currentUser!.isAdmin) {
      // Menu complet pour les administrateurs
      return [
        {'label': 'Dashboard', 'icon': CupertinoIcons.home, 'route': '/'},
        {'label': 'Enfants', 'icon': CupertinoIcons.person_2, 'route': '/enfants'},
        {'label': 'Présence', 'icon': CupertinoIcons.checkmark_seal, 'route': '/presence'},
        {'label': 'Employés', 'icon': CupertinoIcons.person_crop_rectangle, 'route': '/employes'},
        {'label': 'Activités', 'icon': CupertinoIcons.calendar_today, 'route': '/activites'},
        {'label': 'Paiements', 'icon': CupertinoIcons.money_dollar, 'route': '/paiements', 'isPaiement': true},
        {'label': 'Statistiques', 'icon': CupertinoIcons.chart_bar, 'route': '/statistiques'},
        {'label': 'Paramètres', 'icon': CupertinoIcons.settings, 'route': '/parametres'},
      ];
    } else {
      // Menu restreint pour les utilisateurs standard
      return [
        {'label': 'Dashboard', 'icon': CupertinoIcons.home, 'route': '/'},
        {'label': 'Enfants', 'icon': CupertinoIcons.person_2, 'route': '/enfants'},
        {'label': 'Présence', 'icon': CupertinoIcons.checkmark_seal, 'route': '/presence'},
        {'label': 'Activités', 'icon': CupertinoIcons.calendar_today, 'route': '/activites'},
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: const Color(0xFFEAF6FF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),

         

          const Divider(
            color: Colors.black26,
            thickness: 1,
            indent: 24,
            endIndent: 24,
          ),

          // Affichez le type de compte selon le rôle
         // Affichez le nom d'utilisateur
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
  child: Text(
    "Utilisateur: ${currentUser != null ? currentUser!.username : 'Non connecté'}",
    style: const TextStyle(color: Colors.black87, fontSize: 14),
  ),
),
          /// 🔹 Menu principal
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: menuItems.map((item) {
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                        child: _SidebarItem(
                          icon: item['icon'],
                          label: item['label'],
                          onTap: () {
                            if (item['isPaiement'] == true && currentUser!.isAdmin) {
                              setState(() {
                                _showPaiementSubmenu = !_showPaiementSubmenu;
                              });
                            } else {
                              Navigator.of(context).push(
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) =>
                                      _getPageFromRoute(item['route']),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    final curvedAnimation = CurvedAnimation(
                                        parent: animation, curve: Curves.easeInOut);
                                    return FadeTransition(
                                      opacity: curvedAnimation,
                                      child: ScaleTransition(
                                        scale: Tween<double>(begin: 0.95, end: 1.0)
                                            .animate(curvedAnimation),
                                        child: child,
                                      ),
                                    );
                                  },
                                  transitionDuration: const Duration(milliseconds: 500),
                                ),
                              );
                            }
                          },
                        ),
                      ),

                      // 🔹 Sous-menu Paiements (uniquement pour les admins)
                      if (item['isPaiement'] == true && currentUser!.isAdmin)
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: _showPaiementSubmenu
                              ? Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 32.0, right: 8, top: 2, bottom: 2),
                                      child: _SidebarItem(
                                        icon: CupertinoIcons.arrow_right,
                                        label: "Dépenses",
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => _getPageFromRoute('/depenses'),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 32.0, right: 8, top: 2, bottom: 2),
                                      child: _SidebarItem(
                                        icon: CupertinoIcons.arrow_right,
                                        label: "Paiements Enfant",
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => _getPageFromRoute('/paiements-enfant'),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                )
                              : const SizedBox.shrink(),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),

          const Divider(color: Colors.black26, thickness: 1, indent: 16, endIndent: 16),

          // 🔹 Bouton Se déconnecter en bas
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                // Réinitialiser l'utilisateur courant
                currentUser = null;
                Navigator.of(context).pushReplacementNamed('/login');
              },
              icon: const Icon(CupertinoIcons.power),
              label: const Text("Se déconnecter",style: TextStyle(color: Colors.black),),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 255, 232, 232),
                foregroundColor: const Color.fromARGB(255, 231, 7, 7),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 🔹 Composant individuel pour chaque élément du menu
class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SidebarItem({required this.icon, required this.label, required this.onTap, });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _isHovering ? Colors.blue[100] : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(widget.icon, color: Colors.black54),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: const TextStyle(color: Colors.black87, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
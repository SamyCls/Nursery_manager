import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../layout/main_layout.dart';
import 'package:intl/intl.dart';
import '/models/activity.dart';
import '/db/activitydao.dart';
import '/db/enfant_dao.dart';
import '/db/presencedao.dart';
import '/models/enfant.dart';
import '/models/Presence.dart';

// ----------------------------
// Écran principal : Dashboard
// ----------------------------
class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Classe sélectionnée pour le filtrage
  String? selectedClass;

  // Liste des classes disponibles (sera chargée depuis la BD)
  List<String> classes = [];

  // DAO
  final ActivityDao activityDao = ActivityDao();
  final EnfantDao enfantDao = EnfantDao();
  final PresenceDao presenceDao = PresenceDao();
  List<Activity> allActivities = [];

  // Données statistiques
  int totalEnfants = 0;
  int inscriptionsCeMois = 0;
  int presentsAujourdhui = 0;
  int absentsAujourdhui = 0;

  @override
  void initState() {
    super.initState();
    _loadClassesAndActivities();
    _loadStats();
  }

  Future<void> _loadClassesAndActivities() async {
    // Charger les classes depuis la base de données
    final enfants = await enfantDao.getAllEnfants();
    final distinctClasses = enfants.map((e) => e.classe).toSet().toList();

    // Charger les activités
    final activities = await activityDao.getAllActivities();

    setState(() {
      classes = distinctClasses;
      allActivities = activities;

      // Sélectionner la première classe par défaut si disponible
      if (classes.isNotEmpty && selectedClass == null) {
        selectedClass = classes[0];
      }
    });
  }

  Future<void> _loadStats() async {
    try {
      // Charger tous les enfants
      final List<Enfant> enfants = await enfantDao.getAllEnfants();

      // Calculer le nombre total d'enfants
      final int total = enfants.length;

      // Calculer les inscriptions ce mois-ci
      final now = DateTime.now();
      final int inscriptionsMois = enfants.where((enfant) {
        if (enfant.dateInscription != null) {
          return enfant.dateInscription!.year == now.year &&
              enfant.dateInscription!.month == now.month;
        }
        return false;
      }).length;

      // Calculer les présences d'aujourd'hui - VERSION CORRIGÉE
      final aujourdhui = DateTime.now();
      final List<Presence> presencesAujourdhui = await presenceDao
          .getPresencesByDate(aujourdhui);

      // Debug: afficher les informations
      print('Total enfants: $total');
      print('Inscriptions ce mois: $inscriptionsMois');
      print(
        'Nombre de présences trouvées aujourd\'hui: ${presencesAujourdhui.length}',
      );

      // Vérification plus robuste des statuts
      int presents = 0;
      int absents = 0;

      for (var presence in presencesAujourdhui) {
        print(' - ${presence.enfantId}: ${presence.statut}');

        final statut = presence.statut.toLowerCase();
        if (statut.contains('présent') || statut.contains('present')) {
          presents++;
        } else if (statut.contains('absent') || statut.contains('abscent')) {
          absents++;
        }
      }

      setState(() {
        totalEnfants = total;
        inscriptionsCeMois = inscriptionsMois;
        presentsAujourdhui = presents;
        absentsAujourdhui = absents;
      });
    } catch (e) {
      print('Erreur lors du chargement des statistiques: $e');
      // En cas d'erreur, mettre des valeurs par défaut
      setState(() {
        totalEnfants = 0;
        inscriptionsCeMois = 0;
        presentsAujourdhui = 0;
        absentsAujourdhui = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre Dashboard en haut à gauche
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),

            StatusCards(
              totalEnfants: totalEnfants,
              inscriptionsCeMois: inscriptionsCeMois,
              presentsAujourdhui: presentsAujourdhui,
              absentsAujourdhui: absentsAujourdhui,
            ), // Affiche les cartes de statistiques
            SizedBox(height: 24),

            // Ligne avec le titre et le sélecteur de classe
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Activité / Planning',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                // Sélecteur de classe en haut à droite
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(15, 155, 171, 230),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: selectedClass,
                    underline: const SizedBox(),
                    onChanged: (v) {
                      setState(() {
                        selectedClass = v;
                      });
                    },
                    items: classes
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                  ),
                ),
              ],
            ),

            Divider(thickness: 1), // Ligne de séparation
            SizedBox(height: 16),

            Expanded(
              child: WeeklyPlannerMini(
                selectedClass: selectedClass,
                classes: classes,
                allActivities: allActivities,
                onClassChanged: (newClass) {
                  setState(() {
                    selectedClass = newClass;
                  });
                },
              ),
            ), // Planning hebdomadaire miniaturisé
            SizedBox(height: 16),
            ImportantReminder(), // Affiche les rappels importants
          ],
        ),
      ),
    );
  }
}

// Composant de planning hebdomadaire miniaturisé pour le dashboard
// Composant de planning hebdomadaire miniaturisé pour le dashboard
// Composant de planning hebdomadaire miniaturisé pour le dashboard
class WeeklyPlannerMini extends StatefulWidget {
  final String? selectedClass;
  final List<String> classes;
  final List<Activity> allActivities;
  final Function(String?) onClassChanged;

  const WeeklyPlannerMini({
    required this.selectedClass,
    required this.classes,
    required this.allActivities,
    required this.onClassChanged,
    Key? key,
  }) : super(key: key);

  @override
  _WeeklyPlannerMiniState createState() => _WeeklyPlannerMiniState();
}

class _WeeklyPlannerMiniState extends State<WeeklyPlannerMini> {
  // Date de début de la semaine affichée
  DateTime weekStart = _startOfWeek(DateTime.now());

  // Types d'activités disponibles
  final List<String> activityTypes = [
    'Jeux',
    'Lecture',
    'Sport',
    'Art',
    'Musique',
  ];

  // Couleurs associées à chaque type d'activité
  final Map<String, Color> activityColors = {
    'Jeux': Colors.blueAccent,
    'Lecture': Colors.greenAccent,
    'Sport': Colors.redAccent,
    'Art': Colors.purpleAccent,
    'Musique': Colors.orangeAccent,
  };

  // Paramètres de la grille horaire
  final TimeOfDay startHour = const TimeOfDay(hour: 8, minute: 0);
  final TimeOfDay endHour = const TimeOfDay(hour: 17, minute: 0);
  final int numberOfRows = 9;
  double cellWidth = 160;

  // Retourne le premier jour (dimanche) de la semaine pour une date donnée
  static DateTime _startOfWeek(DateTime dt) {
    final diff = dt.weekday % 7;
    final s = DateTime(
      dt.year,
      dt.month,
      dt.day,
    ).subtract(Duration(days: diff));
    return DateTime(s.year, s.month, s.day);
  }

  List<DateTime> getWeekDays(DateTime start) =>
      List.generate(7, (i) => start.add(Duration(days: i)));

  // Charger les activités du jour depuis la liste en mémoire
  List<Activity> _getActivitiesForDayAndClass(DateTime day) {
    return widget.allActivities.where((activity) {
      return activity.className == widget.selectedClass &&
          activity.date.year == day.year &&
          activity.date.month == day.month &&
          activity.date.day == day.day;
    }).toList()..sort(
      (a, b) =>
          (a.start.hour * 60 + a.start.minute) -
          (b.start.hour * 60 + b.start.minute),
    );
  }

  double _calculateTopOffsetForHeight(TimeOfDay time, double containerHeight) {
    final totalMinutes =
        (time.hour * 60 + time.minute) -
        (startHour.hour * 60 + startHour.minute);
    final totalAvailableMinutes =
        (endHour.hour * 60 + endHour.minute) -
        (startHour.hour * 60 + startHour.minute);
    return (totalMinutes / totalAvailableMinutes) * containerHeight;
  }

  double _calculateHeightForHeight(
    TimeOfDay start,
    TimeOfDay end,
    double containerHeight,
  ) {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    final durationMinutes = endMinutes - startMinutes;
    final totalAvailableMinutes =
        (endHour.hour * 60 + endHour.minute) -
        (startHour.hour * 60 + startHour.minute);
    return (durationMinutes / totalAvailableMinutes) * containerHeight;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculer la largeur disponible pour chaque cellule
        final availableWidth = constraints.maxWidth - 1;
        cellWidth = availableWidth / 7; // Diviser par 7 jours

        // Calculer la hauteur disponible pour le tableau
        final availableHeight = constraints.maxHeight;
        final calculatedCellHeight =
            availableHeight - 40; // Soustrayez la hauteur de l'en-tête

        return Column(
          children: [
            // En-tête des jours de la semaine
            Row(
              children: getWeekDays(weekStart).map((d) {
                return Container(
                  width: cellWidth,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xff1e73be),
                    border: Border.all(color: Colors.white, width: 0.5),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat.EEEE('fr_FR').format(d),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM', 'fr_FR').format(d),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            // Corps du tableau avec les activités
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xffe9f2fb),
                  border: Border.all(color: Colors.grey.shade300, width: 0.5),
                ),
                child: SingleChildScrollView(
                  child: SizedBox(
                    height: calculatedCellHeight,
                    child: Row(
                      children: getWeekDays(weekStart).map((day) {
                        final dayActivities = _getActivitiesForDayAndClass(day);
                        return Container(
                          width: cellWidth,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 0.5,
                            ),
                          ),
                          child: Stack(
                            children: [
                              // Lignes horaires
                              ...List.generate(numberOfRows, (index) {
                                final hour = startHour.hour + index;
                                return Positioned(
                                  top:
                                      (index / numberOfRows) *
                                      calculatedCellHeight,
                                  left: 0,
                                  right: 0,
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 30,
                                        child: Text(
                                          '$hour:00',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          height: 1,
                                          color: Colors.grey.withOpacity(0.3),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),

                              // Activités
...dayActivities.map((activity) {
  // Calculate proportional top & height
  double top = _calculateTopOffsetForHeight(
    activity.start,
    calculatedCellHeight,
  );
  double height = _calculateHeightForHeight(
    activity.start,
    activity.end,
    calculatedCellHeight,
  );

  // ✅ Clamp so it always fits
  top = top.clamp(0, calculatedCellHeight);
  if (top + height > calculatedCellHeight) {
    height = calculatedCellHeight - top;
  }
  if (height < 20) height = 20; // minimum visible height

  final color = activityColors[activity.title] ?? Colors.grey;

  return Positioned(
    top: top,
    left: 2,
    right: 2,
    height: height,
    child: Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.all(4),
      child: FittedBox( // ✅ scales text automatically to fit
        alignment: Alignment.topLeft,
        fit: BoxFit.scaleDown,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              activity.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${activity.start.format(context)} - ${activity.end.format(context)}',
              style: const TextStyle(
                fontSize: 10,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (activity.notes.isNotEmpty)
              Text(
                activity.notes,
                style: const TextStyle(fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    ),
  );
}).toList(),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ----------------------------------------
// Composant qui affiche les 3 cartes stats
// ----------------------------------------
class StatusCards extends StatelessWidget {
  final int totalEnfants;
  final int inscriptionsCeMois;
  final int presentsAujourdhui;
  final int absentsAujourdhui;

  const StatusCards({
    required this.totalEnfants,
    required this.inscriptionsCeMois,
    required this.presentsAujourdhui,
    required this.absentsAujourdhui,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: StatusCard(
            title: 'Inscription',
            value: 'Ce mois : $inscriptionsCeMois / Total : $totalEnfants',
            color: Colors.blue,
            icon: Icons.person_add_alt_1,
          ),
        ),
        Expanded(
          child: StatusCard(
            title: 'Présence du jour',
            value: 'Présent: $presentsAujourdhui / Absent: $absentsAujourdhui',
            color: Colors.green,
            icon: Icons.event_available,
          ),
        ),
        Expanded(
          child: StatusCard(
            title: 'Notifications',
            value: '02',
            color: Colors.redAccent,
            icon: Icons.notifications_active,
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------
// Composant réutilisable pour chaque carte de statistique
// ----------------------------------------------------------
class StatusCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const StatusCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8.0),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28), // Icône principale
          SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------
// Widget qui affiche des rappels importants dans une zone colorée
// ------------------------------------------------------------------
class ImportantReminder extends StatelessWidget {
  final List<String> alerts = ['Notif 1', 'Notif 2'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: AnimatedAlert(alerts: alerts), // Animation de rappel
    );
  }
}

// -------------------------------------------------------------------------
// Composant animé qui fait défiler les messages d'alerte un par un
// -------------------------------------------------------------------------
class AnimatedAlert extends StatefulWidget {
  final List<String> alerts;

  const AnimatedAlert({required this.alerts});

  @override
  State<AnimatedAlert> createState() => _AnimatedAlertState();
}

class _AnimatedAlertState extends State<AnimatedAlert>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;
  int _currentIndex = 0;
  bool _isDisposed = false; // <-- Flag pour arrêter la boucle

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _startLoop(); // Lance l'animation en boucle
  }

  void _setupAnimation() {
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 700),
    );

    _animation = Tween<Offset>(
      begin: Offset(1.0, 0.0),
      end: Offset(0.0, 0.0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  void _startLoop() {
    Future.delayed(Duration(seconds: 1), () async {
      while (mounted && !_isDisposed) {
        await _controller.forward();
        await Future.delayed(Duration(seconds: 3));
        if (_isDisposed) break; // sécurité
        await _controller.reverse();
        await Future.delayed(Duration(milliseconds: 400));
        if (_isDisposed) break; // sécurité

        setState(() {
          _currentIndex = (_currentIndex + 1) % widget.alerts.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true; // <-- stop la boucle
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _animation,
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.alerts[_currentIndex],
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

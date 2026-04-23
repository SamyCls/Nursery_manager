// ======================================================================
// IMPORT STATEMENTS
// ======================================================================
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/enfant.dart';
import '../db/presencedao.dart';

// ======================================================================
// PRESENCE CALENDAR WIDGET
// ======================================================================
class PresenceCalendar extends StatefulWidget {
  final Enfant enfant;

  const PresenceCalendar({required this.enfant, super.key});

  @override
  State<PresenceCalendar> createState() => _PresenceCalendarState();
}

// ======================================================================
// STATE
// ======================================================================
class _PresenceCalendarState extends State<PresenceCalendar> {
  DateTime _currentMonth = DateTime.now();
  final PresenceDao _presenceDao = PresenceDao();

  /// Historique chargé depuis la DB
  Map<DateTime, String> _presenceData = {};

  @override
  void initState() {
    super.initState();
    _loadPresences();
  }

  /// Charge les présences depuis la DB pour l’enfant
  Future<void> _loadPresences() async {
    final presences =
        await _presenceDao.getPresencesByEnfant(widget.enfant.id);
    setState(() {
      _presenceData = {
        for (var p in presences) DateUtils.dateOnly(p.date): p.statut,
      };
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final header = DateFormat.yMMMM('fr_FR').format(_currentMonth);

    // ===== Calcul des jours à afficher =====
    final firstDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0);

    final startWeekday = firstDayOfMonth.weekday % 7; // 0 = Dimanche
    final totalDays = lastDayOfMonth.day;

    // Nombre de cases à afficher (jours du mois + offset au début + padding fin)
    final totalCells = ((startWeekday + totalDays + 6) ~/ 7) * 7;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Historique de présence : ${widget.enfant.nomComplet}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: Column(
        children: [
          // ===== Header mois + navigation =====
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                    icon: const Icon(Icons.chevron_left), onPressed: _prevMonth),
                Text(header,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                    icon: const Icon(Icons.chevron_right), onPressed: _nextMonth),
              ],
            ),
          ),

          // ===== Ligne des jours de semaine =====
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam']
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(day,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                )
                .toList(),
          ),

          // ===== Grille =====
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 4,
                    mainAxisExtent: 70,
                  ),
                  itemCount: totalCells,
                  itemBuilder: (context, index) {
                    final day = index - startWeekday + 1;

                    if (day < 1 || day > totalDays) {
                      // Cellule vide (avant/après le mois)
                      return Container();
                    }

                    final currentDay =
                        DateTime(_currentMonth.year, _currentMonth.month, day);

                    final status = _presenceData[DateUtils.dateOnly(currentDay)] ?? "";

                    return Container(
                      decoration: BoxDecoration(
                        color: status == "Présent"
                            ? Colors.green[100]
                            : status == "Absent"
                                ? Colors.red[100]
                                : Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "$day",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          if (status.isNotEmpty)
                            Text(
                              status,
                              style: TextStyle(
                                fontSize: 14,
                                color: status == "Présent"
                                    ? Colors.green[800]
                                    : Colors.red[800],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

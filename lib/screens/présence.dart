import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/layout/main_layout.dart';

// 🔹 imports DB
import '../db/enfant_dao.dart';
import '../db/presencedao.dart';
import '../models/enfant.dart';
import '../models/Presence.dart';

class PresenceScreen extends StatefulWidget {
  @override
  _PresenceScreenState createState() => _PresenceScreenState();
}

class _PresenceScreenState extends State<PresenceScreen> {
  DateTime selectedDate = DateTime.now();
  Map<String, String> presenceStatus = {}; // enfantId -> "Présent"/"Absent"
  String? selectedClassFilter;
  List<Enfant> students = [];
  List<String> classes = []; // Modifié: liste vide initialement
  final enfantDao = EnfantDao();
  final presenceDao = PresenceDao();

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final data = await enfantDao.getAllEnfants();
    
    // Filter to show only active enfants
    final activeStudents = data.where((enfant) => enfant.estActif).toList();
    
    // Récupérer les classes distinctes depuis les données des élèves actifs
    final distinctClasses = activeStudents.map((e) => e.classe).toSet().toList();
    
    setState(() {
      students = activeStudents; // Only active students
      classes = distinctClasses; // Mettre à jour avec les classes de la BD
    });
    
    // 🔹 After loading students, also load presence data
    await _loadPresenceForDate(selectedDate);
  }

  /// 🔹 Load saved presences from DB for the selected date
  Future<void> _loadPresenceForDate(DateTime date) async {
    Map<String, String> loadedStatus = {};

    for (var student in students) {
      final presence =
          await presenceDao.getPresenceForDate(student.id, date);
      if (presence != null) {
        loadedStatus[student.id] = presence.statut;
      }
    }

    setState(() {
      presenceStatus = loadedStatus;
    });
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      locale: const Locale('fr', 'FR'),
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      // 🔹 Reload presence data for new date
      await _loadPresenceForDate(picked);
    }
  }

  Future<void> _savePresence() async {
    for (var entry in presenceStatus.entries) {
      final enfantId = entry.key;
      final statut = entry.value;

      final presence = Presence(
        enfantId: enfantId,
        date: DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
        ),
        statut: statut,
      );

      await presenceDao.insertPresence(presence);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Présences enregistrées ✅")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        DateFormat('EEEE d MMMM y', 'fr_FR').format(selectedDate);
    final filteredStudents = selectedClassFilter == null
        ? students
        : students.where((s) => s.classe == selectedClassFilter).toList();

    return MainLayout(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 🔹 HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      "Présence",
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _selectDate(context),
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(formattedDate,
                          style: const TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    setState(() {
                      selectedClassFilter = value == "Tous" ? null : value;
                    });
                  },
                  icon: const Icon(Icons.filter_list, color: Colors.black),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: "Tous",
                      child: Text("📂 Toutes les classes"),
                    ),
                    ...classes.map((classe) =>
                        PopupMenuItem(value: classe, child: Text("🏫 $classe"))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 🔹 TABLEAU
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      offset: const Offset(0, 4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F1F1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: const [
                          Expanded(child: Text("👦 Élève",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 20))),
                          Expanded(child: Text("🏫 Classe",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 20))),
                          Expanded(child: Text("📋 Statut",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 20))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: filteredStudents.isEmpty
                          ? Center(
                              child: Text(
                                "Aucun élève actif trouvé",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: filteredStudents.length,
                              separatorBuilder: (_, __) => const Divider(),
                              itemBuilder: (context, index) {
                                final student = filteredStudents[index];
                                final currentStatus =
                                    presenceStatus[student.id] ?? "Sélectionner";

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    children: [
                                      Expanded(
                                          child: Text(
                                              "${student.prenom} ${student.nom}")),
                                      Expanded(child: Text(student.classe)),
                                      Expanded(
                                        child: DropdownButton<String>(
                                          value: currentStatus == "Sélectionner"
                                              ? null
                                              : currentStatus,
                                          hint: const Text("Sélectionner"),
                                          isExpanded: true,
                                          items: [
                                            DropdownMenuItem(
                                              value: "Présent",
                                              child: Row(
                                                children: const [
                                                  Icon(Icons.check_circle,
                                                      color: Color(0xFF1c8b48)),
                                                  SizedBox(width: 8),
                                                  Text("✅ Présent",
                                                      style: TextStyle(
                                                          color: Color(0xFF1c8b48),
                                                          fontSize: 20)),
                                                ],
                                              ),
                                            ),
                                            DropdownMenuItem(
                                              value: "Absent",
                                              child: Row(
                                                children: const [
                                                  Icon(Icons.cancel,
                                                      color: Color(0xFFF24848)),
                                                  SizedBox(width: 8),
                                                  Text("❌ Absent",
                                                      style: TextStyle(
                                                          color: Color(0xFFF24848),
                                                          fontSize: 20)),
                                                ],
                                              ),
                                            ),
                                          ],
                                          onChanged: (newValue) {
                                            setState(() {
                                              presenceStatus[student.id] = newValue!;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),

            // 🔹 BOUTONS
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // TODO: Impression
                  },
                  child: const Text("Imprimer"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _savePresence,
                  child: const Text("Enregistrer"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
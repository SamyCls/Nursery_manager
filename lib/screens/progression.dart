import 'package:flutter/material.dart';
import 'package:creche_manager/db/evaluationdao.dart';
import 'package:creche_manager/models/enfant.dart';
 
class EvaluationPage extends StatefulWidget {
  final Enfant enfant; // Objet enfant au lieu de juste l'ID

  const EvaluationPage({super.key, required this.enfant});

  @override
  State<EvaluationPage> createState() => _EvaluationPageState();
}

class _EvaluationPageState extends State<EvaluationPage> {
  final EvaluationDao evaluationDao = EvaluationDao();

  final Map<String, bool> checkTrue = {};
  final Map<String, bool> checkFalse = {};
  final Map<String, TextEditingController> textControllers = {};

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  final Map<String, List<String>> sections = {
    "1) Autonomie – développement": [
      "S'adapte et participe à la vie du groupe",
      "Respecte les règles de vie, de la classe et de l'école",
      "S'organise et travaille seul(e)",
      "Désire apprendre et manifeste de la curiosité",
      "Comprend et respecte les consignes",
      "Mène un travail à son terme",
      "Retient des comptines, des poèmes",
      "Écoute la maîtresse",
    ],
    "2) Compétence langue française": [
      "Prend la parole et argumente (dans le sujet)",
      "Utilise des phrases assez élaborées",
      "Utilise un vocabulaire précis",
      "Reconnaît les lettres",
      "Reconnaît certains mots dans une phrase",
      "Repère des correspondances lettres/sons",
      "Utilise correctement crayon, stylo, craie",
      "Écrit seul(e) des lettres",
      "Écrit correctement entre deux lignes",
    ],
    "3) Mathématiques": [
      "Connaît la suite des nombres jusqu'à",
      "Classe les nombres",
      "Écrit correctement les chiffres ",
      "Sait compter un certain nombre d'objets",
      "Reproduit et nomme des formes simples",
      "Compare des grandeurs",
    ],
  };

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadEvaluations();
  }

  void _initializeControllers() {
    for (var items in sections.values) {
      for (var item in items) {
        checkTrue[item] = false;
        checkFalse[item] = false;
        textControllers[item] = TextEditingController();
      }
    }
  }

  Future<void> _loadEvaluations() async {
    setState(() => _isLoading = true);
    
    try {
      // Clear previous values
      _initializeControllers();
      
      // Load evaluations for the selected month
      final evals = await evaluationDao.getEvaluationsByMonth(
        widget.enfant.id, 
        _selectedDate.year, 
        _selectedDate.month
      );

      for (var e in evals) {
        setState(() {
          if (e.valeur) {
            checkTrue[e.competence] = true;
            checkFalse[e.competence] = false;
          } else {
            checkTrue[e.competence] = false;
            checkFalse[e.competence] = true;
          }
          if (e.texte != null) {
            textControllers[e.competence]?.text = e.texte!;
          }
        });
      }
    } catch (e) {
      print("Error loading evaluations: $e");
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _saveEvaluations() async {
    try {
      // Clear existing evaluations for this month and child
      await evaluationDao.clearEvaluationsForMonth(
        widget.enfant.id, 
        _selectedDate.year,
        _selectedDate.month
      );

      for (var section in sections.values) {
        for (var item in section) {
          bool valeur = checkTrue[item] ?? false;
          String? texte = textControllers[item]?.text.isNotEmpty == true
              ? textControllers[item]!.text
              : null;

          final eval = Evaluation(
            enfantId: widget.enfant.id,
            date: _selectedDate,
            competence: item,
            valeur: valeur,
            texte: texte,
          );
          await evaluationDao.insertEvaluation(eval);
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Évaluations enregistrées ✅")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de l'enregistrement: $e")),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year,
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadEvaluations();
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + delta);
      _loadEvaluations();
    });
  }

  @override
  void dispose() {
    for (var controller in textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool needsTextField(String item) {
    return item.contains("jusqu'à");
  }

  String _getMonthName(int month) {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return months[month - 1];
  }

  

  // Widget personnalisé pour la case "Vrai" avec ✅
  Widget _buildTrueCheckbox(String item) {
    return GestureDetector(
      onTap: () {
        setState(() {
          checkTrue[item] = !(checkTrue[item] ?? false);
          if (checkTrue[item] == true) {
            checkFalse[item] = false;
          }
        });
      },
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
          color: checkTrue[item] == true ? Colors.green : Colors.transparent,
        ),
        child: checkTrue[item] == true
            ? const Icon(Icons.check, size: 18, color: Colors.white)
            : null,
      ),
    );
  }

  // Widget personnalisé pour la case "Faux" avec X
  Widget _buildFalseCheckbox(String item) {
    return GestureDetector(
      onTap: () {
        setState(() {
          checkFalse[item] = !(checkFalse[item] ?? false);
          if (checkFalse[item] == true) {
            checkTrue[item] = false;
          }
        });
      },
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
          color: checkFalse[item] == true ? Colors.red : Colors.transparent,
        ),
        child: checkFalse[item] == true
            ? const Text("X",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center)
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Text(
                "Evaluation de ${widget.enfant.prenom} ${widget.enfant.nom}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        centerTitle: false, // Désactiver le centrage pour aligner à gauche
        actions: [
          // Month picker in top right corner
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 20),
                  onPressed: () => _changeMonth(-1),
                ),
                TextButton(
                  onPressed: () => _selectDate(context),
                  child: Text(
                    "${_getMonthName(_selectedDate.month)} ${_selectedDate.year}",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward, size: 20),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveEvaluations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: sections.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        color: Colors.grey[300],
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(top: 16),
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Table(
                        border: TableBorder.all(color: Colors.grey),
                        columnWidths: const {
                          0: FlexColumnWidth(4), // Compétence
                          1: FlexColumnWidth(1), // Vrai (gauche)
                          2: FlexColumnWidth(1), // X (droite)
                        },
                        children: entry.value.map((item) {
                          return TableRow(
                            children: [
                              // Compétence column
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: needsTextField(item)
                                    ? Row(
                                        children: [
                                          Expanded(child: Text(item)),
                                          const SizedBox(width: 8),
                                          SizedBox(
                                            width: 70,
                                            child: TextField(
                                              controller: textControllers[item],
                                              decoration: const InputDecoration(
                                                border: OutlineInputBorder(),
                                                isDense: true,
                                                contentPadding: EdgeInsets.symmetric(
                                                    horizontal: 6, vertical: 4),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(item),
                              ),
                              // Vrai checkbox (gauche) avec ✅
                              Center(
                                child: _buildTrueCheckbox(item),
                              ),
                              // X checkbox (droite) avec X
                              Center(
                                child: _buildFalseCheckbox(item),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
    );
  }
}
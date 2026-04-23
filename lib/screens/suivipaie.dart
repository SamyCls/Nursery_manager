import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/models/enfant.dart';
import '/db/enfant_dao.dart';
import 'dart:ui';
import '/layout/main_layout.dart';
import 'package:flutter/services.dart'; // Add this import

class SuiviPaiementsScreen extends StatefulWidget {
  const SuiviPaiementsScreen({super.key});

  @override
  State<SuiviPaiementsScreen> createState() => _SuiviPaiementsScreenState();
}

class _SuiviPaiementsScreenState extends State<SuiviPaiementsScreen> {
  String searchText = "";
  String? selectedClasse;
  String? selectedMois;
  String? selectedStatut;
  List<Enfant> _enfants = [];
  bool _isLoading = true;
  final EnfantDao _enfantDao = EnfantDao();

  @override
  void initState() {
    super.initState();
    _loadEnfants();
  }

  Future<void> _loadEnfants() async {
    try {
      final enfants = await _enfantDao.getAllEnfants();
      // Load payments for each child
      final enfantsWithPayments = await Future.wait(
        enfants.map((enfant) async {
          final paiements = await _enfantDao.getPaiementsByEnfantId(enfant.id);
          return Enfant(
            id: enfant.id,
            nom: enfant.nom,
            prenom: enfant.prenom,
            classe: enfant.classe,
            telephone: enfant.telephone,
            estActif: enfant.estActif,
            dateNaissance: enfant.dateNaissance,
            sexe: enfant.sexe,
            adresse: enfant.adresse,
            photoPath: enfant.photoPath,
            nomPrenomPere: enfant.nomPrenomPere,
            telPere: enfant.telPere,
            professionPere: enfant.professionPere,
            adressePere: enfant.adressePere,
            nomPrenomMere: enfant.nomPrenomMere,
            telMere: enfant.telMere,
            professionMere: enfant.professionMere,
            statutFamilial: enfant.statutFamilial,
            allergies: enfant.allergies,
            commentairesMedicaux: enfant.commentairesMedicaux,
            dossierMedicalPath: enfant.dossierMedicalPath,
            paiements: paiements,
            historiquePresence: enfant.historiquePresence,
          );
        }),
      );

      setState(() {
        _enfants = enfantsWithPayments;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading enfants: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Formate une date au format dd/MM/yy
  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yy').format(date);
  }

  // Récupère tous les mois disponibles dans les paiements des enfants
  List<String> getMoisDisponibles() {
    final Set<String> moisSet = {};
    for (var enfant in _enfants) {
      for (var paiement in enfant.paiements ?? []) {
        moisSet.add(paiement.mois);
      }
    }
    return moisSet.toList()..sort();
  }

  // Récupère toutes les classes disponibles
  List<String> getClassesDisponibles() {
    final Set<String> classesSet = {};
    for (var enfant in _enfants) {
      classesSet.add(enfant.classe);
    }
    return classesSet.toList()..sort();
  }

  // Crée un widget Chip pour afficher le statut du paiement avec la couleur appropriée
  Widget _buildStatutChip(StatutPaiements statut) {
    switch (statut) {
      case StatutPaiements.paye:
        return Chip(
          label: const Text("Payé"),
          backgroundColor: Colors.green.shade100,
          labelStyle: TextStyle(color: Colors.green.shade800),
          avatar: const Icon(Icons.check_circle, color: Colors.green),
        );
      case StatutPaiements.impaye:
        return Chip(
          label: const Text("Non payé"),
          backgroundColor: Colors.red.shade100,
          labelStyle: TextStyle(color: Colors.red.shade800),
          avatar: const Icon(Icons.cancel, color: Colors.red),
        );
      case StatutPaiements.partiel:
        return Chip(
          label: const Text("Partiel"),
          backgroundColor: Colors.orange.shade100,
          labelStyle: TextStyle(color: Colors.orange.shade800),
          avatar: const Icon(Icons.warning, color: Colors.orange),
        );
    }
  }

  Future<void> _addPaiement(Enfant enfant, Paiement paiement) async {
    try {
      await _enfantDao.insertPaiement(enfant.id, paiement);
      await _loadEnfants(); // Reload data
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Paiement ajouté pour ${enfant.nomComplet}')),
      );
    } catch (e) {
      print('Error adding payment: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur lors de l\'ajout: $e')));
    }
  }

  Future<void> _updatePaiement(String enfantId, Paiement paiement) async {
    try {
      await _enfantDao.updatePaiement(enfantId, paiement);
      await _loadEnfants(); // Reload data
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Paiement mis à jour')));
    } catch (e) {
      print('Error updating payment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la mise à jour: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MainLayout(child: Center(child: CircularProgressIndicator()));
    }

    // Construire une liste plate (enfant, paiement) et appliquer TOUS les filtres
    final List<Map<String, dynamic>> filteredPaiements = [];

    for (var enfant in _enfants) {
      for (var paiement in enfant.paiements ?? []) {
        final bool matchName = enfant.nomComplet.toLowerCase().contains(
          searchText.toLowerCase(),
        );

        final bool matchClasse =
            selectedClasse == null || enfant.classe == selectedClasse;

        final bool matchMois =
            selectedMois == null ||
            paiement.mois.toLowerCase().trim() ==
                selectedMois!.toLowerCase().trim();

        bool matchStatut = true;
        if (selectedStatut != null) {
          switch (selectedStatut) {
            case "Payé":
              matchStatut = paiement.statut == StatutPaiements.paye;
              break;
            case "Non payé":
              matchStatut = paiement.statut == StatutPaiements.impaye;
              break;
            case "Partiel":
              matchStatut = paiement.statut == StatutPaiements.partiel;
              break;
          }
        }

        if (matchName && matchClasse && matchMois && matchStatut) {
          filteredPaiements.add({"enfant": enfant, "paiement": paiement});
        }
      }
    }

    // Encapsuler le contenu dans MainLayout
    return MainLayout(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Titre de la page en haut à gauche
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Suivi des paiements",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Barre supérieure avec recherche + filtres + bouton
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Recherche (width réduit via flex:1)
                SizedBox(
                  width: 220,
                  height: 40,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Rechercher...",
                      prefixIcon: const Icon(Icons.search, size: 18),
                      filled: true,
                      fillColor: const Color(0xFFE2ECF9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 12,
                      ),
                    ),
                    style: const TextStyle(fontSize: 14),
                    onChanged: (val) {
                      setState(() => searchText = val);
                    },
                  ),
                ),

                const SizedBox(width: 8),

                // Filtre Classe
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2ECF9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    hint: const Text("Classe"),
                    value: selectedClasse,
                    underline: const SizedBox(),
                    items: getClassesDisponibles()
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) {
                      setState(() => selectedClasse = val);
                    },
                  ),
                ),

                const SizedBox(width: 8),

                // Filtre Mois
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2ECF9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    hint: const Text("Mois"),
                    value: selectedMois,
                    underline: const SizedBox(),
                    items: getMoisDisponibles()
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) {
                      setState(() => selectedMois = val);
                    },
                  ),
                ),

                const SizedBox(width: 8),

                // Filtre Statut
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2ECF9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    hint: const Text("Statut"),
                    value: selectedStatut,
                    underline: const SizedBox(),
                    items: ["Payé", "Non payé", "Partiel"]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) {
                      setState(() => selectedStatut = val);
                    },
                  ),
                ),

                const SizedBox(width: 12),

                // Bouton Ajouter Paiement
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 40, 165, 40),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () {
                    _showAddPaiementDialog();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("Ajouter Paiement"),
                ),
              ],
            ),

            // Affichage des filtres actifs
            if (selectedClasse != null ||
                selectedMois != null ||
                selectedStatut != null ||
                searchText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Filtres actifs : "
                        "${searchText.isNotEmpty ? "Recherche='$searchText' " : ""}"
                        "${selectedClasse != null ? "Classe=$selectedClasse " : ""}"
                        "${selectedMois != null ? "Mois=$selectedMois " : ""}"
                        "${selectedStatut != null ? "Statut=$selectedStatut " : ""}",
                        style: const TextStyle(
                          color: Colors.teal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFE2ECF9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          searchText = "";
                          selectedClasse = null;
                          selectedMois = null;
                          selectedStatut = null;
                        });
                      },
                      icon: const Icon(Icons.clear, color: Colors.red),
                      label: const Text(
                        "Réinitialiser",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // Compteur de paiements trouvés
            if (selectedClasse != null ||
                selectedMois != null ||
                selectedStatut != null ||
                searchText.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "${filteredPaiements.length} paiements trouvés",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: filteredPaiements.isEmpty ? Colors.red : Colors.teal,
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // Tableau PaginatedDataTable
            Expanded(
              child: Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.95,
                  child: SingleChildScrollView(
                    child: DataTableTheme(
                      data: DataTableThemeData(
                        headingRowColor: WidgetStateProperty.all(
                          const Color.fromARGB(255, 255, 255, 255),
                        ),
                        dataRowColor: WidgetStateProperty.all(Colors.white),
                      ),
                      child: PaginatedDataTable(
                        headingRowHeight: 56,
                        dataRowMinHeight: 52,
                        dataRowMaxHeight: 56,
                        columnSpacing: 32,
                        rowsPerPage: 10,
                        showCheckboxColumn: false,
                        columns: const [
                          DataColumn(label: Text("Enfant")),
                          DataColumn(label: Text("Mois concerné")),
                          DataColumn(label: Text("Montant dû")),
                          DataColumn(label: Text("Montant payé")),
                          DataColumn(label: Text("Solde restant")),
                          DataColumn(label: Text("Date paiement")),
                          DataColumn(label: Text("Statut")),
                        ],
                        source: _PaiementDataSource(
                          filteredPaiements,
                          _formatDate,
                          _buildStatutChip,
                          onDoubleTap: (enfant, paiement) {
                            _showEditPaiementDialog(enfant, paiement);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

 void _showAddPaiementDialog() {
  final _formKey = GlobalKey<FormState>();
  Enfant? selectedEnfant;
  String? selectedMonth;
  String? selectedYear;
  final montantDuController = TextEditingController();
  final montantPayeController = TextEditingController();
  DateTime selectedDate = DateTime.now();


  // Liste des mois
  final List<String> months = [
    "Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
    "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre",
  ];

  // Liste des années
  final List<String> years = [];
  final currentYear = DateTime.now().year;
  for (int y = currentYear - 1; y <= currentYear + 1; y++) {
    years.add(y.toString());
  }

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Ajouter un paiement"),
            content: SizedBox(
              width: 500,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Sélection de l'enfant avec Autocomplete - CORRIGÉ
                      Autocomplete<Enfant>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<Enfant>.empty();
                          }
                          return _enfants.where((Enfant enfant) {
                            return enfant.nomComplet.toLowerCase().contains(
                              textEditingValue.text.toLowerCase(),
                            );
                          });
                        },
                        displayStringForOption: (Enfant enfant) => enfant.nomComplet,
                        fieldViewBuilder: (
                          BuildContext context,
                          TextEditingController textEditingController,
                          FocusNode focusNode,
                          VoidCallback onFieldSubmitted,
                        ) {
                          // Utiliser le contrôleur fourni par Autocomplete
                          return TextFormField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              labelText: "Enfant *",
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              // Réinitialiser la sélection si l'utilisateur modifie le texte
                              setDialogState(() {
                                selectedEnfant = null;
                              });
                            },
                          );
                        },
                        onSelected: (Enfant selection) {
                          setDialogState(() {
                            selectedEnfant = selection;
                          });
                        },
                        optionsViewBuilder: (
                          BuildContext context,
                          AutocompleteOnSelected<Enfant> onSelected,
                          Iterable<Enfant> options,
                        ) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4.0,
                              child: SizedBox(
                                height: 200,
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  itemCount: options.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    final Enfant option = options.elementAt(index);
                                    return InkWell(
                                      onTap: () => onSelected(option),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Text(option.nomComplet),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),

                      // Mois et Année séparés
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: "Mois *",
                                border: OutlineInputBorder(),
                              ),
                              value: selectedMonth,
                              items: months
                                  .map((m) => DropdownMenuItem(
                                        value: m,
                                        child: Text(m),
                                      ))
                                  .toList(),
                              onChanged: (val) => setDialogState(() => selectedMonth = val),
                              validator: (val) => val == null ? "Choisissez un mois" : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: "Année *",
                                border: OutlineInputBorder(),
                              ),
                              value: selectedYear,
                              items: years
                                  .map((y) => DropdownMenuItem(
                                        value: y,
                                        child: Text(y),
                                      ))
                                  .toList(),
                              onChanged: (val) => setDialogState(() => selectedYear = val),
                              validator: (val) => val == null ? "Choisissez une année" : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Montant dû
                      TextFormField(
                        controller: montantDuController,
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: "Montant dû *",
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return "Entrez le montant dû";
                          }
                          final amount = int.tryParse(val);
                          if (amount == null || amount <= 0) {
                            return "Montant invalide";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Montant payé
                      TextFormField(
                        controller: montantPayeController,
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: "Montant payé *",
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return "Entrez le montant payé";
                          }
                          final amount = int.tryParse(val);
                          if (amount == null || amount < 0) {
                            return "Montant invalide";
                          }
                          
                          // Validation supplémentaire : montant payé ne peut pas dépasser montant dû
                          final montantDu = int.tryParse(montantDuController.text) ?? 0;
                          if (amount > montantDu) {
                            return "Le montant payé ne peut pas dépasser le montant dû";
                          }
                          
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Date de paiement
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: "Date de paiement *",
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            DateFormat("dd/MM/yyyy").format(selectedDate),
                          ),
                        ),
                      ),
                      
                      // Message d'information
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "* Champs obligatoires\nDouble-cliquez sur un paiement existant pour le modifier",
                          style: TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Annuler"),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Valider le formulaire
                  if (!_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Veuillez corriger les erreurs'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Validation manuelle supplémentaire
                  if (selectedEnfant == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Veuillez sélectionner un enfant valide'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (selectedMonth == null || selectedYear == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Veuillez sélectionner un mois et une année'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  try {
                    // Combine month and year
                    final selectedMois = "$selectedMonth $selectedYear";

                    final montantDu = int.tryParse(montantDuController.text) ?? 0;
                    final montantPaye = int.tryParse(montantPayeController.text) ?? 0;
                    final reste = montantDu - montantPaye;

                    // Determine status
                    StatutPaiements statut;
                    if (montantPaye == 0) {
                      statut = StatutPaiements.impaye;
                    } else if (montantPaye >= montantDu) {
                      statut = StatutPaiements.paye;
                    } else {
                      statut = StatutPaiements.partiel;
                    }

                    final newPaiement = Paiement(
                      date: selectedDate,
                      mois: selectedMois,
                      montantdu: montantDu,
                      montantPaye: montantPaye,
                      reste: reste,
                      statut: statut,
                    );

                    await _addPaiement(selectedEnfant!, newPaiement);
                    Navigator.of(context).pop();
                    
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text("Enregistrer"),
              ),
            ],
          );
        },
      );
    },
  );
}

  void _showEditPaiementDialog(Enfant enfant, Paiement paiement) {
    final _formKey = GlobalKey<FormState>();
    final montantDuController = TextEditingController(
      text: paiement.montantdu.toString(),
    );
    final montantPayeController = TextEditingController(
      text: paiement.montantPaye.toString(),
    );
    DateTime selectedDate = paiement.date;

    // Extraire le mois et l'année du paiement
    final parts = paiement.mois.split(' ');
    String? selectedMonth = parts.isNotEmpty ? parts[0] : null;
    String? selectedYear = parts.length > 1 ? parts[1] : null;

    // Liste des mois
    final List<String> months = [
      "Janvier",
      "Février",
      "Mars",
      "Avril",
      "Mai",
      "Juin",
      "Juillet",
      "Août",
      "Septembre",
      "Octobre",
      "Novembre",
      "Décembre",
    ];

    // Liste des années
    final List<String> years = [];
    final currentYear = DateTime.now().year;
    for (int y = currentYear - 1; y <= currentYear + 1; y++) {
      years.add(y.toString());
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Modifier le paiement"),
              content: SizedBox(
                width: 500,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Afficher le nom de l'enfant (non modifiable)
                        TextFormField(
                          readOnly: true,
                          initialValue: enfant.nomComplet,
                          decoration: const InputDecoration(
                            labelText: "Enfant",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Mois et Année séparés
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: "Mois",
                                  border: OutlineInputBorder(),
                                ),
                                value: selectedMonth,
                                items: months
                                    .map(
                                      (m) => DropdownMenuItem(
                                        value: m,
                                        child: Text(m),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) =>
                                    setDialogState(() => selectedMonth = val),
                                validator: (val) =>
                                    val == null ? "Choisissez un mois" : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: "Année",
                                  border: OutlineInputBorder(),
                                ),
                                value: selectedYear,
                                items: years
                                    .map(
                                      (y) => DropdownMenuItem(
                                        value: y,
                                        child: Text(y),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) =>
                                    setDialogState(() => selectedYear = val),
                                validator: (val) =>
                                    val == null ? "Choisissez une année" : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Montant dû
                        TextFormField(
                          controller: montantDuController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                          ],
                          decoration: const InputDecoration(
                            labelText: "Montant dû",
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) => val == null || val.isEmpty
                              ? "Entrez le montant dû"
                              : (int.tryParse(val) == null
                                    ? "Veuillez entrer un nombre valide"
                                    : null),
                        ),
                        const SizedBox(height: 12),

                        // Montant payé
                        TextFormField(
                          controller: montantPayeController,
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter
                                .digitsOnly, // Only numbers can be entered
                          ],
                          decoration: const InputDecoration(
                            labelText: "Montant payé",
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) => val == null || val.isEmpty
                              ? "Entrez le montant payé"
                              : (int.tryParse(val) == null
                                    ? "Veuillez entrer un nombre valide"
                                    : null),
                        ),
                        const SizedBox(height: 12),

                        // Date de paiement
                        InkWell(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setDialogState(() {
                                selectedDate = picked;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: "Date de paiement",
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              DateFormat("dd/MM/yyyy").format(selectedDate),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Annuler"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate() &&
                        selectedMonth != null &&
                        selectedYear != null) {
                      // Combine month and year
                      final selectedMois = "$selectedMonth $selectedYear";

                      final montantDu =
                          int.tryParse(montantDuController.text) ?? 0;
                      final montantPaye =
                          int.tryParse(montantPayeController.text) ?? 0;
                      final reste = montantDu - montantPaye;

                      // Determine status
                      StatutPaiements statut;
                      if (montantPaye == 0) {
                        statut = StatutPaiements.impaye;
                      } else if (montantPaye >= montantDu) {
                        statut = StatutPaiements.paye;
                      } else {
                        statut = StatutPaiements.partiel;
                      }

                      final updatedPaiement = Paiement(
                        date: selectedDate,
                        mois: selectedMois,
                        montantdu: montantDu,
                        montantPaye: montantPaye,
                        reste: reste,
                        statut: statut,
                      );

                      await _updatePaiement(enfant.id, updatedPaiement);
                      Navigator.of(context).pop();
                    } else {
                      // Afficher un message d'erreur si la validation échoue
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Veuillez remplir tous les champs correctement',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text("Enregistrer"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// Source de données pour le tableau des paiements
class _PaiementDataSource extends DataTableSource {
  final List<Map<String, dynamic>> paiements;
  final String Function(DateTime) formatDate;
  final Widget Function(StatutPaiements) buildStatutChip;
  final Function(Enfant, Paiement) onDoubleTap;

  _PaiementDataSource(
    this.paiements,
    this.formatDate,
    this.buildStatutChip, {
    required this.onDoubleTap,
  });

  @override
  DataRow getRow(int index) {
    if (index >= paiements.length) return DataRow(cells: []);

    final enfant = paiements[index]["enfant"] as Enfant;
    final paiement = paiements[index]["paiement"] as Paiement;

    return DataRow(
      cells: [
        DataCell(
          GestureDetector(
            onDoubleTap: () => onDoubleTap(enfant, paiement),
            child: Text(enfant.nomComplet),
          ),
        ),
        DataCell(
          GestureDetector(
            onDoubleTap: () => onDoubleTap(enfant, paiement),
            child: Text(paiement.mois),
          ),
        ),
        DataCell(
          GestureDetector(
            onDoubleTap: () => onDoubleTap(enfant, paiement),
            child: Text("${paiement.montantdu} DA"),
          ),
        ),
        DataCell(
          GestureDetector(
            onDoubleTap: () => onDoubleTap(enfant, paiement),
            child: Text("${paiement.montantPaye} DA"),
          ),
        ),
        DataCell(
          GestureDetector(
            onDoubleTap: () => onDoubleTap(enfant, paiement),
            child: Text("${paiement.reste} DA"),
          ),
        ),
        DataCell(
          GestureDetector(
            onDoubleTap: () => onDoubleTap(enfant, paiement),
            child: Text(formatDate(paiement.date)),
          ),
        ),
        DataCell(
          GestureDetector(
            onDoubleTap: () => onDoubleTap(enfant, paiement),
            child: buildStatutChip(paiement.statut),
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => paiements.length;

  @override
  int get selectedRowCount => 0;
}

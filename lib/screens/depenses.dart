import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/db/depensesdao.dart';
import '/db/employedao.dart';
import '/models/depenses.dart';
import '/models/employe.dart';
import '/layout/main_layout.dart';

class DepensesScreen extends StatefulWidget {
  const DepensesScreen({super.key});

  @override
  State<DepensesScreen> createState() => _DepensesScreenState();
}

class _DepensesScreenState extends State<DepensesScreen> {
  final TextEditingController searchController = TextEditingController();
  final DepenseDao _depenseDao = DepenseDao();
  final EmployeDao _employeDao = EmployeDao();

  DateTime? filtreJour;
  DateTime? filtreMois;
  String? filtreCategorie;
  String searchQuery = '';

  List<Depense> depensesAffichees = [];
  List<Depense> allDepenses = [];
  List<Depense> salaryExpenses = [];
  int? depenseEnEdition; // index dépense qu'on édite

  // Predefined categories
  final List<String> predefinedCategories = [
    'Fournitures',
    'Transport',
    'Divers',
    'Maintenance',
    'Cuisine',
    'Électricité',
    'Eau',
    'Nettoyage',
    'Jardinage',
    'Salaires',
    'Loyer',
    'Assurance',
    'Équipement'
  ];
  
  // Custom categories that can be added by the user
  List<String> customCategories = [];
  List<String> get allCategories => [...predefinedCategories, ...customCategories];

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _loadCustomCategories();
  }

  Future<void> _loadCustomCategories() async {
    // Load custom categories from database or shared preferences
    final depenses = await _depenseDao.getAllDepenses();
    final categoriesFromDb = depenses.map((d) => d.categorie).toSet();
    
    setState(() {
      customCategories = categoriesFromDb
          .where((cat) => !predefinedCategories.contains(cat))
          .toList();
    });
  }

  Future<void> _loadAllData() async {
    await _loadDepenses();
    await _loadSalaryExpenses();
    _combineExpenses();
  }

  Future<void> _loadDepenses() async {
    final depenses = await _depenseDao.getAllDepenses();
    setState(() {
      allDepenses = depenses;
    });
  }

  Future<void> _loadSalaryExpenses() async {
    final employees = await _employeDao.getAllEmployes();
    final List<Depense> salaryDepenses = [];

    for (var employee in employees) {
      for (var payment in employee.paiements) {
        // Only include paid salaries
        if (payment.statut == StatutPaiement.paye) {
          salaryDepenses.add(Depense(
            id: 'salary_${employee.id}_${payment.mois}',
            categorie: 'Salaires',
            description: 'Salaire de ${employee.prenom} ${employee.nom} - ${payment.mois}',
            montant: payment.montantPaye,
            date: payment.datePaiement,
            attestation: 'Paiement employé',
          ));
        }
      }
    }

    setState(() {
      salaryExpenses = salaryDepenses;
    });
  }

  void _combineExpenses() {
    setState(() {
      // Combine regular expenses with salary expenses
      depensesAffichees = [...allDepenses, ...salaryExpenses];
      // Sort by date descending
      depensesAffichees.sort((a, b) => b.date.compareTo(a.date));
    });
  }

  void applyFilters() {
    setState(() {
      final combinedExpenses = [...allDepenses, ...salaryExpenses];
      depensesAffichees = combinedExpenses.where((d) {
        if (filtreJour != null) {
          if (!(d.date.year == filtreJour!.year &&
              d.date.month == filtreJour!.month &&
              d.date.day == filtreJour!.day)) {
            return false;
          }
        }

        if (filtreMois != null) {
          if (!(d.date.year == filtreMois!.year &&
              d.date.month == filtreMois!.month)) {
            return false;
          }
        }

        if (filtreCategorie != null && filtreCategorie!.isNotEmpty) {
          if (d.categorie != filtreCategorie) return false;
        }

        if (searchQuery.isNotEmpty) {
          final q = searchQuery.toLowerCase();
          final inDesc = d.description.toLowerCase().contains(q);
          final inCat = d.categorie.toLowerCase().contains(q);
          if (!(inDesc || inCat)) return false;
        }

        return true;
      }).toList();
      
      // Sort by date descending
      depensesAffichees.sort((a, b) => b.date.compareTo(a.date));
    });
  }

  Future<void> choisirJour() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: filtreJour ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      filtreJour = DateTime(picked.year, picked.month, picked.day);
      filtreMois = null;
      applyFilters();
    }
  }

  Future<void> choisirMois() async {
    final now = DateTime.now();
    final initial = filtreMois ?? DateTime(now.year, now.month, 1);

    const monthLabels = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc',
    ];

    DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (ctx) {
        int tempYear = initial.year;
        final selectedMonth = initial.month;

        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              title: const Text('Choisir un mois'),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => setStateDialog(() => tempYear--),
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Text(
                          '$tempYear',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          onPressed: () => setStateDialog(() => tempYear++),
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 12,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 3,
                      ),
                      itemBuilder: (context, i) {
                        final month = i + 1;
                        final isSelected = (tempYear == initial.year && month == selectedMonth);

                        return OutlinedButton(
                          onPressed: () {
                            Navigator.of(ctx).pop(DateTime(tempYear, month, 1));
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            backgroundColor: isSelected
                                ? Theme.of(context).colorScheme.primary.withOpacity(0.08)
                                : null,
                          ),
                          child: Text(monthLabels[i]),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (picked != null) {
      filtreMois = picked;
      filtreJour = null;
      applyFilters();
    }
  }

  void choisirCategorie() {
    final categories = [...allDepenses.map((d) => d.categorie).toSet(), 'Salaires']..sort();
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.clear),
                title: const Text('Aucune catégorie (retirer)'),
                onTap: () {
                  Navigator.pop(context);
                  filtreCategorie = null;
                  applyFilters();
                },
              ),
              const Divider(height: 0),
              ...categories.map(
                (cat) => ListTile(
                  leading: const Icon(Icons.category),
                  title: Text(cat),
                  onTap: () {
                    Navigator.pop(context);
                    filtreCategorie = cat;
                    applyFilters();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void afficherMenuFiltre() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.list),
                title: const Text("Voir tout"),
                onTap: () {
                  Navigator.pop(context);
                  searchController.clear();
                  searchQuery = '';
                  filtreJour = null;
                  filtreMois = null;
                  filtreCategorie = null;
                  applyFilters();
                },
              ),
              const Divider(height: 0),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text("Filtrer par Date (jour)"),
                onTap: () {
                  Navigator.pop(context);
                  choisirJour();
                },
              ),
              ListTile(
                leading: const Icon(Icons.date_range),
                title: const Text("Filtrer par Mois"),
                onTap: () {
                  Navigator.pop(context);
                  choisirMois();
                },
              ),
              ListTile(
                leading: const Icon(Icons.category),
                title: const Text("Filtrer par Catégorie"),
                onTap: () {
                  Navigator.pop(context);
                  choisirCategorie();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String get libelleFiltreActif {
    final parts = <String>[];
    if (filtreJour != null) {
      parts.add('Date: ${DateFormat('dd/MM/yyyy').format(filtreJour!)}');
    }
    if (filtreMois != null) {
      parts.add('Mois: ${DateFormat('MMMM yyyy').format(filtreMois!)}');
    }
    if (filtreCategorie != null) {
      parts.add('Catégorie: $filtreCategorie');
    }
    if (searchQuery.isNotEmpty) {
      parts.add('Recherche: "$searchQuery"');
    }
    return parts.isEmpty ? 'Aucun' : parts.join('  •  ');
  }

  void supprimerDepense(int index) {
    final depenseToDelete = depensesAffichees[index];
    
    // Don't allow deletion of salary expenses
    if (depenseToDelete.categorie == 'Salaires') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les salaires ne peuvent pas être supprimés ici. Utilisez l\'écran de gestion des employés.'))
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cette dépense ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              await _depenseDao.deleteDepense(depenseToDelete.id);
              if (mounted) {
                await _loadAllData();
              }
              Navigator.pop(ctx);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void ajouterDepense() {
    final descController = TextEditingController();
    final montantController = TextEditingController();
    final attestationController = TextEditingController();
    String? selectedCategory;
    DateTime selectedDate = DateTime.now();
    final newCategoryController = TextEditingController();

    // Function to show dialog for adding a new category
    void showAddCategoryDialog() {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Nouvelle catégorie'),
            content: TextField(
              controller: newCategoryController,
              decoration: const InputDecoration(
                hintText: 'Nom de la nouvelle catégorie',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (newCategoryController.text.isNotEmpty) {
                    setState(() {
                      customCategories.add(newCategoryController.text);
                      selectedCategory = newCategoryController.text;
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text('Ajouter'),
              ),
            ],
          );
        },
      );
    }

    Future<void> selectDate(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (picked != null) {
        setState(() {
          selectedDate = picked;
        });
      }
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Ajouter",
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim, _, child) {
        final curvedValue = Curves.easeOutBack.transform(anim.value);
        return Transform.scale(
          scale: curvedValue,
          child: Opacity(
            opacity: anim.value,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Nouvelle dépense",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Catégorie Dropdown with Add option
                        InputDecorator(
                          decoration: const InputDecoration(
                            labelText: "Catégorie",
                            border: OutlineInputBorder(),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedCategory,
                              isExpanded: true,
                              hint: const Text('Sélectionnez une catégorie'),
                              items: [
                                ...allCategories.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }),
                                const DropdownMenuItem<String>(
                                  value: 'add_new',
                                  child: Row(
                                    children: [
                                      Icon(Icons.add, size: 18),
                                      SizedBox(width: 8),
                                      Text('Ajouter une nouvelle catégorie'),
                                    ],
                                  ),
                                ),
                              ],
                              onChanged: (String? newValue) {
                                if (newValue == 'add_new') {
                                  showAddCategoryDialog();
                                } else {
                                  setState(() {
                                    selectedCategory = newValue;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Description
                        TextField(
                          controller: descController,
                          decoration: const InputDecoration(
                            labelText: "Description",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Montant
                        TextField(
                          controller: montantController,
                          decoration: const InputDecoration(
                            labelText: "Montant",
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),

                        // Date
                        InkWell(
                          onTap: () => selectDate(context),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: "Date",
                              border: OutlineInputBorder(),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                                const Icon(Icons.calendar_today),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Attestation
                        TextField(
                          controller: attestationController,
                          decoration: const InputDecoration(
                            labelText: "Attestation",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Annuler"),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              onPressed: () async {
                                if (selectedCategory == null || selectedCategory!.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Veuillez sélectionner une catégorie'))
                                  );
                                  return;
                                }
                                
                                final newDepense = Depense(
                                  categorie: selectedCategory!,
                                  description: descController.text,
                                  montant: double.tryParse(montantController.text) ?? 0,
                                  date: selectedDate,
                                  attestation: attestationController.text,
                                );
                                
                                await _depenseDao.insertDepense(newDepense);
                                if (mounted) {
                                  await _loadAllData();
                                  await _loadCustomCategories();
                                }
                                
                                Navigator.pop(context);
                              },
                              child: const Text("Ajouter"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void modifierDepense(int index) {
    final d = depensesAffichees[index];
    
    // Don't allow editing of salary expenses (they come from employee payments)
    if (d.categorie == 'Salaires') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les salaires ne peuvent pas être modifiés ici. Utilisez l\'écran de gestion des employés.'))
      );
      return;
    }

    final descController = TextEditingController(text: d.description);
    final montantController = TextEditingController(text: d.montant.toString());
    final attestationController = TextEditingController(text: d.attestation);
    String? selectedCategory = d.categorie;
    DateTime selectedDate = d.date;
    final newCategoryController = TextEditingController();

    setState(() {
      depenseEnEdition = index;
    });

    // Function to show dialog for adding a new category
    void showAddCategoryDialog() {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Nouvelle catégorie'),
            content: TextField(
              controller: newCategoryController,
              decoration: const InputDecoration(
                hintText: 'Nom de la nouvelle catégorie',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (newCategoryController.text.isNotEmpty) {
                    setState(() {
                      customCategories.add(newCategoryController.text);
                      selectedCategory = newCategoryController.text;
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text('Ajouter'),
              ),
            ],
          );
        },
      );
    }

    Future<void> selectDate(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (picked != null && picked != selectedDate) {
        setState(() {
          selectedDate = picked;
        });
      }
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Modifier",
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, anim, _, child) {
        final curvedValue = Curves.easeOutBack.transform(anim.value);
        return Transform.scale(
          scale: curvedValue,
          child: Opacity(
            opacity: anim.value,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Modifier la dépense",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Catégorie Dropdown with Add option
                      InputDecorator(
                        decoration: const InputDecoration(
                          labelText: "Catégorie",
                          border: OutlineInputBorder(),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedCategory,
                            isExpanded: true,
                            hint: const Text('Sélectionnez une catégorie'),
                            items: [
                              ...allCategories.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }),
                              const DropdownMenuItem<String>(
                                value: 'add_new',
                                child: Row(
                                  children: [
                                    Icon(Icons.add, size: 18),
                                    SizedBox(width: 8),
                                    Text('Ajouter une nouvelle catégorie'),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (String? newValue) {
                              if (newValue == 'add_new') {
                                showAddCategoryDialog();
                              } else {
                                setState(() {
                                  selectedCategory = newValue;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Description
                      TextField(
                        controller: descController,
                        decoration: const InputDecoration(
                          labelText: "Description",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Montant
                      TextField(
                        controller: montantController,
                        decoration: const InputDecoration(
                          labelText: "Montant",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),

                      // Date
                      InkWell(
                        onTap: () => selectDate(context),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: "Date",
                            border: OutlineInputBorder(),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                              const Icon(Icons.calendar_today),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Attestation
                      TextField(
                        controller: attestationController,
                        decoration: const InputDecoration(
                          labelText: "Attestation",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Annuler"),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              if (selectedCategory == null || selectedCategory!.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Veuillez sélectionner une catégorie'))
                                );
                                return;
                              }
                              
                              final updatedDepense = Depense(
                                id: d.id,
                                categorie: selectedCategory!,
                                description: descController.text,
                                montant: double.tryParse(montantController.text) ?? d.montant,
                                date: selectedDate,
                                attestation: attestationController.text,
                              );
                              
                              await _depenseDao.updateDepense(updatedDepense);
                              if (mounted) {
                                await _loadAllData();
                                await _loadCustomCategories();
                              }
                              
                              Navigator.pop(context);
                            },
                            child: const Text("Enregistrer"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ).then((_) {
      setState(() {
        depenseEnEdition = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(
                  child: Text(
                    "Dépenses",
                    style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  width: 200,
                  height: 36,
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, size: 16),
                      hintText: "Search",
                      hintStyle: const TextStyle(fontSize: 14),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: const Color.fromARGB(255, 238, 242, 255),
                    ),
                    onChanged: (value) {
                      searchQuery = value;
                      applyFilters();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: afficherMenuFiltre,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade400,
                    minimumSize: const Size(80, 36),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Filtrer", style: TextStyle(fontSize: 14)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: ajouterDepense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow.shade400,
                    minimumSize: const Size(120, 36),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text("Ajouter Dépense", style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Filtre actif : $libelleFiltreActif",
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (filtreJour != null || filtreMois != null || filtreCategorie != null || searchQuery.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Confirmer'),
                          content: const Text('Voulez-vous vraiment effacer tous les filtres ?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Non'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                searchController.clear();
                                searchQuery = '';
                                filtreJour = null;
                                filtreMois = null;
                                filtreCategorie = null;
                                applyFilters();
                              },
                              child: const Text('Oui'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text("Effacer"),
                  ),
              ],
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                      ),
                      child: const Row(
                        children: [
                          Expanded(flex: 2, child: Text("Categorie", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20), textAlign: TextAlign.center)),
                          Expanded(flex: 3, child: Text("Description", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20), textAlign: TextAlign.center)),
                          Expanded(flex: 2, child: Text("Montant", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20), textAlign: TextAlign.center)),
                          Expanded(flex: 2, child: Text("Date", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20), textAlign: TextAlign.center)),
                          Expanded(flex: 2, child: Text("Attestation", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20), textAlign: TextAlign.center)),
                          Expanded(flex: 1, child: SizedBox()),
                        ],
                      ),
                    ),
                    Expanded(
                      child: depensesAffichees.isEmpty
                          ? const Center(child: Text("Aucun résultat. Modifiez ou effacez vos filtres.", style: TextStyle(color: Colors.grey)))
                          : ListView.builder(
                              itemCount: depensesAffichees.length,
                              itemBuilder: (context, index) {
                                final d = depensesAffichees[index];
                                final isEditing = depenseEnEdition == index;
                                final isSalary = d.categorie == 'Salaires';
                                
                                return Container(
                                  margin: isEditing ? const EdgeInsets.all(4) : EdgeInsets.zero,
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                  decoration: BoxDecoration(
                                    border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                                    color: isEditing ? Colors.blue.withOpacity(0.1) : (isSalary ? Colors.grey.shade50 : Colors.transparent),
                                    borderRadius: isEditing ? BorderRadius.circular(8) : BorderRadius.zero,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          d.categorie,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: isSalary ? FontWeight.bold : FontWeight.normal,
                                            color: isSalary ? Colors.blue : Colors.black,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          d.description,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontStyle: isSalary ? FontStyle.italic : FontStyle.normal,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          '${d.montant.toStringAsFixed(2)} DA',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: isSalary ? Colors.blue : Colors.black,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          DateFormat('dd/MM/yyyy').format(d.date),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          d.attestation,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontStyle: isSalary ? FontStyle.italic : FontStyle.normal,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            if (!isSalary) IconButton(
                                              onPressed: () => supprimerDepense(index),
                                              icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade400),
                                            ),
                                            if (!isSalary) const SizedBox(width: 4),
                                            if (!isSalary) IconButton(
                                              onPressed: () => modifierDepense(index),
                                              icon: const Icon(Icons.edit, size: 20),
                                            ),
                                          ],
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
          ],
        ),
      ),
    );
  }
}
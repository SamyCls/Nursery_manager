import 'package:flutter/material.dart';
import '/db/employedao.dart';
import '/models/employe.dart';
import '/layout/main_layout.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '/screens/employe_profile.dart';

class ListeEmployesPage extends StatefulWidget {
  @override
  _ListeEmployesPageState createState() => _ListeEmployesPageState();
}

class _ListeEmployesPageState extends State<ListeEmployesPage> with WidgetsBindingObserver {
  final EmployeDao _employeDao = EmployeDao();
  List<Employe> _allEmployes = [];
  bool _isLoading = true;

  // Variables d'état pour la gestion de la pagination et des filtres
  int currentPage = 0;
  int itemsPerPage = 5;
  String searchQuery = '';
  String? selectedFilter;
  String? selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadEmployes();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Cette méthode est appelée quand l'état de l'application change
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // L'application est revenue au premier plan, on rafraîchit
      _loadEmployes();
    }
  }

  // Cette méthode est appelée à chaque frame
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Vérifier si cette route est actuellement visible
    if (ModalRoute.of(context)?.isCurrent ?? false) {
      _loadEmployes();
    }
  }

  Future<void> _loadEmployes() async {
    try {
      final employes = await _employeDao.getAllEmployes();
      if (mounted) {
        setState(() {
          _allEmployes = employes;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des employés: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des employés')),
        );
      }
    }
  }

  List<Employe> get filteredEmployes {
    List<Employe> list = _allEmployes.where((e) {
      final matchSearch = selectedFilter == 'Poste'
          ? e.poste.toLowerCase().contains(searchQuery.toLowerCase())
          : e.nom.toLowerCase().contains(searchQuery.toLowerCase()) ||
              e.prenom.toLowerCase().contains(searchQuery.toLowerCase());

      final matchStatus =
          selectedStatus == null ||
          (selectedStatus == 'Actif' && e.estActif) ||
          (selectedStatus == 'Inactif' && !e.estActif);

      return matchSearch && matchStatus;
    }).toList();

    if (selectedFilter == 'Nom') {
      list.sort((a, b) => a.nom.toLowerCase().compareTo(b.nom.toLowerCase()));
    } else if (selectedFilter == 'Poste') {
      list.sort((a, b) => a.poste.toLowerCase().compareTo(b.poste.toLowerCase()));
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MainLayout(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final startIndex = currentPage * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(0, filteredEmployes.length);
    final paginatedEmployes = filteredEmployes.sublist(startIndex, endIndex);

    return MainLayout(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Employés',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            
            Wrap(
              spacing: 8,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 300,
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Rechercher',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                        currentPage = 0;
                      });
                    },
                  ),
                ),

                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField2<String>(
                    value: selectedFilter,
                    decoration: const InputDecoration(
                      labelText: 'Filtrer par',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    dropdownStyleData: DropdownStyleData(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    items: ['Nom', 'Poste']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedFilter = val;
                        currentPage = 0;
                      });
                    },
                  ),
                ),

                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField2<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Statut',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    dropdownStyleData: DropdownStyleData(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        selectedStatus = val;
                        currentPage = 0;
                      });
                    },
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Tout')),
                      DropdownMenuItem(value: 'Actif', child: Text('Actif')),
                      DropdownMenuItem(
                        value: 'Inactif',
                        child: Text('Inactif'),
                      ),
                    ],
                  ),
                ),

                SizedBox(
                  width: 140,
                  child: DropdownButtonFormField2<int>(
                    value: itemsPerPage,
                    decoration: const InputDecoration(
                      labelText: 'Employés par page',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    dropdownStyleData: DropdownStyleData(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    items: [5, 10, 15]
                        .map(
                          (e) => DropdownMenuItem(value: e, child: Text('$e')),
                        )
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        itemsPerPage = val!;
                        currentPage = 0;
                      });
                    },
                  ),
                ),

                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EmployeeProfilePage(employeeId: null),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 30),
                  label: const Text(
                    'Ajouter un employé',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Row(
                children: const [
                  Expanded(child: Text('🆔 ID', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(child: Text('👤 Employé', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(child: Text('💼 Poste', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(child: Text('📞 Téléphone', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(child: Text('📌 Statut', style: TextStyle(fontWeight: FontWeight.bold))),
                  SizedBox(width: 80, child: Center(child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold)))),
                ],
              ),
            ),

            Expanded(
              child: ListView.builder(
                itemCount: paginatedEmployes.length,
                itemBuilder: (context, index) {
                  final employe = paginatedEmployes[index];
                  final isEven = index % 2 == 0;

                  return Container(
                    color: isEven ? const Color(0xFFE2E7F3) : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    child: Row(
                      children: [
                        Expanded(child: Text(employe.id)),
                        Expanded(child: Text("${employe.prenom} ${employe.nom}")),
                        Expanded(child: Text(employe.poste)),
                        Expanded(child: Text(employe.telephone)),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                              decoration: BoxDecoration(
                                color: employe.estActif ? Colors.green[100] : Colors.red[100],
                                border: Border.all(
                                  color: employe.estActif ? Colors.green : Colors.red,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                employe.estActif ? 'Actif' : 'Inactif',
                                style: TextStyle(
                                  color: employe.estActif ? Colors.green[800] : Colors.red[800],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 90,
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility, color: Color(0xFF0082EC)),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EmployeeProfilePage(employeeId: employe.id),
                                    ),
                                  );
                                },
                              ),

                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('Confirmation'),
                                        content: const Text('Voulez-vous vraiment supprimer cet employé ?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(),
                                            child: const Text('Annuler'),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              Navigator.of(context).pop();
                                              try {
                                                await _employeDao.deleteEmploye(employe.id);
                                                await _loadEmployes();
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Employé supprimé avec succès')),
                                                );
                                              } catch (e) {
                                                print('Erreur lors de la suppression: $e');
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Erreur lors de la suppression')),
                                                );
                                              }
                                            },
                                            child: const Text('Confirmer', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
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

            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: currentPage > 0 ? () => setState(() => currentPage--) : null,
                  ),
                  Text('${currentPage + 1} / ${((filteredEmployes.length - 1) / itemsPerPage).floor() + 1}'),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: (currentPage + 1) * itemsPerPage < filteredEmployes.length
                        ? () => setState(() => currentPage++)
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
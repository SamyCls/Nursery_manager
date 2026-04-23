import 'package:flutter/material.dart';
import '/models/enfant.dart';
import '/layout/main_layout.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '/screens/enfant_profil_screen.dart';
import '/db/enfant_dao.dart'; 

class ListeEnfantsPage extends StatefulWidget {
  @override
  _ListeEnfantsPageState createState() => _ListeEnfantsPageState();
}

class _ListeEnfantsPageState extends State<ListeEnfantsPage> {
  final EnfantDao enfantDao = EnfantDao();

  // Données chargées depuis la BD
  List<Enfant> allEnfants = [];
  bool isLoading = true;

  // Variables d'état pour la pagination, la recherche et les filtres
  int currentPage = 0;
  int itemsPerPage = 5;
  String searchQuery = '';
  String? selectedFilter;
  String? selectedStatus;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _loadEnfants();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadEnfants() async {
    final enfants = await enfantDao.getAllEnfants();
    setState(() {
      allEnfants = enfants;
      isLoading = false;
    });
  }

  // Méthode pour obtenir la liste filtrée et triée des enfants
  List<Enfant> get filteredEnfants {
    List<Enfant> list = allEnfants.where((e) {
      // Filtrage par recherche (nom, prénom ou classe selon le filtre sélectionné)
      final matchSearch = selectedFilter == 'Classe'
          ? e.classe.toLowerCase().contains(searchQuery.toLowerCase())
          : e.nom.toLowerCase().contains(searchQuery.toLowerCase()) ||
              e.prenom.toLowerCase().contains(searchQuery.toLowerCase());

      // Filtrage par statut (Actif/Inactif/Tout)
      final matchStatus =
          selectedStatus == null ||
          (selectedStatus == 'Actif' && e.estActif) ||
          (selectedStatus == 'Inactif' && !e.estActif);

      return matchSearch && matchStatus;
    }).toList();

    // Tri de la liste selon le filtre sélectionné
    if (selectedFilter == 'Nom') {
      list.sort((a, b) => a.nom.toLowerCase().compareTo(b.nom.toLowerCase()));
    } else if (selectedFilter == 'Classe') {
      list.sort(
        (a, b) => a.classe.toLowerCase().compareTo(b.classe.toLowerCase()),
      );
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return MainLayout(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Calcul des enfants à afficher sur la page courante
    final startIndex = currentPage * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(
      0,
      filteredEnfants.length,
    );
    final paginatedEnfants =
        filteredEnfants.isNotEmpty ? filteredEnfants.sublist(startIndex, endIndex) : [];
    
    return MainLayout(
      child: Focus(
        focusNode: _focusNode,
        onFocusChange: (hasFocus) {
          if (hasFocus) {
            _loadEnfants(); // Reload when this page gets focus
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Titre de la page
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Tous les enfants',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              
              // Barre d'outils avec filtres et boutons
              Wrap(
                spacing: 8,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Champ de recherche
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
                          currentPage = 0; // Réinitialiser à la première page
                        });
                      },
                    ),
                  ),

                  // Dropdown pour filtrer par nom ou classe
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
                      items: ['Nom', 'Classe']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedFilter = val;
                          currentPage = 0; // Réinitialiser à la première page
                        });
                      },
                    ),
                  ),

                  // Dropdown pour filtrer par statut
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
                          currentPage = 0; // Réinitialiser à la première page
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

                  // Dropdown pour choisir le nombre d'enfants par page
                  SizedBox(
                    width: 140,
                    child: DropdownButtonFormField2<int>(
                      value: itemsPerPage,
                      decoration: const InputDecoration(
                        labelText: 'Enfant par page',
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
                          currentPage = 0; // Réinitialiser à la première page
                        });
                      },
                    ),
                  ),

                  // Bouton pour ajouter un nouvel enfant
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => EnfantProfilScreen(enfant: emptyEnfant),
                        ),
                      ).then((value) {
                        // This callback runs when you return from the EnfantProfilScreen
                        if (value == true) {
                          _loadEnfants(); // Reload the list to show the new child immediately
                        }
                      });
                    },
                    icon: const Icon(Icons.add, size: 30),
                    label: const Text(
                      'Ajouter un enfant',
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

              // EN-TÊTE du tableau
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Row(
                  children: const [
                    Expanded(
                      child: Text(
                        '🆔 ID',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '👤 Enfant',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '🏫 Classe',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '📞 Téléphone',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '📌 Statut',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Center(
                        child: Text(
                          'Actions',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Liste des enfants (corps du tableau)
              Expanded(
                child: paginatedEnfants.isEmpty
                    ? Center(
                        child: Text(
                          "Aucun enfant trouvé",
                          style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                        ),
                      )
                    : ListView.builder(
                        itemCount: paginatedEnfants.length,
                        itemBuilder: (context, index) {
                          final enfant = paginatedEnfants[index];
                          final isEven = index % 2 == 0;

                          return Container(
                            color: isEven ? const Color(0xFFE2E7F3) : Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                            child: Row(
                              children: [
                                Expanded(child: Text(enfant.id)),
                                Expanded(child: Text(enfant.nomComplet)),
                                Expanded(child: Text(enfant.classe)),
                                Expanded(child: Text(enfant.telPere)),
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: enfant.estActif
                                            ? Colors.green[100]
                                            : Colors.red[100],
                                        border: Border.all(
                                          color: enfant.estActif
                                              ? Colors.green
                                              : Colors.red,
                                          width: 1.5,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        enfant.estActif ? 'Actif' : 'Inactif',
                                        style: TextStyle(
                                          color: enfant.estActif
                                              ? Colors.green[800]
                                              : Colors.red[800],
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
                                        icon: const Icon(
                                          Icons.visibility,
                                          color: Color(0xFF0082EC),
                                        ),
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  EnfantProfilScreen(enfant: enfant),
                                            ),
                                          ).then((value) {
                                            // This callback runs when you return from the EnfantProfilScreen
                                            if (value == true) {
                                              _loadEnfants(); // Reload the list to show updated data
                                            }
                                          });
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: const Text('Confirmation'),
                                                content: const Text(
                                                    'Voulez-vous vraiment supprimer cet enfant ?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(context).pop(false),
                                                    child: const Text('Annuler'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(context).pop(true),
                                                    child: const Text(
                                                      'Confirmer',
                                                      style: TextStyle(color: Colors.red),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          );

                                          if (confirm == true) {
                                            await enfantDao.deleteEnfant(enfant.id);
                                            _loadEnfants(); // recharge la liste
                                          }
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

              // Pagination (inchangée)
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: currentPage > 0
                          ? () => setState(() => currentPage--)
                          : null,
                    ),
                    Text(
                      '${currentPage + 1} / ${((filteredEnfants.length - 1) / itemsPerPage).floor() + 1}',
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: (currentPage + 1) * itemsPerPage <
                              filteredEnfants.length
                          ? () => setState(() => currentPage++)
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
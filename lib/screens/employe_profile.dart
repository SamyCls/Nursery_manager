import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for FilteringTextInputFormatter
import 'package:intl/intl.dart';
import '/db/employedao.dart';
import '/layout/main_layout.dart';
import '/models/employe.dart';
import '/screens/employe_histpaye.dart';

class EmployeeProfilePage extends StatefulWidget {
  final String? employeeId; // Null pour la création

  const EmployeeProfilePage({super.key, required this.employeeId});

  @override
  State<EmployeeProfilePage> createState() => _EmployeeProfilePageState();
}

class _EmployeeProfilePageState extends State<EmployeeProfilePage> {
  final EmployeDao _employeDao = EmployeDao();
  Employe? employee;
  late bool estActif;
  late DateFormat _dateFormat;
  bool _isLoading = true;
  bool _isNewEmployee = true;
  bool _hasUnsavedChanges = false;

  // Controllers
  late TextEditingController _nomController;
  late TextEditingController _prenomController;
  late TextEditingController _dateNaissanceController;
  late TextEditingController _dateEmbaucheController;
  late TextEditingController _posteController;
  late TextEditingController _salaireController;
  late TextEditingController _telephoneController;
  late TextEditingController _adresseController;

  // For image handling
  File? _selectedImage;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _dateFormat = DateFormat('dd/MM/yyyy');
    _isNewEmployee = widget.employeeId == null;
    
    // Initialiser les contrôleurs avec des valeurs vides
    _nomController = TextEditingController();
    _prenomController = TextEditingController();
    _dateNaissanceController = TextEditingController(text: _dateFormat.format(DateTime.now()));
    _dateEmbaucheController = TextEditingController(text: _dateFormat.format(DateTime.now()));
    _posteController = TextEditingController();
    _salaireController = TextEditingController(text: "0.0");
    _telephoneController = TextEditingController();
    _adresseController = TextEditingController();
    estActif = true;

    // Add listeners to track changes
    _nomController.addListener(_markAsChanged);
    _prenomController.addListener(_markAsChanged);
    _dateNaissanceController.addListener(_markAsChanged);
    _dateEmbaucheController.addListener(_markAsChanged);
    _posteController.addListener(_markAsChanged);
    _salaireController.addListener(_markAsChanged);
    _telephoneController.addListener(_markAsChanged);
    _adresseController.addListener(_markAsChanged);

    if (!_isNewEmployee) {
      _loadEmployeeData();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _markAsChanged() {
    if (!_isNewEmployee && !_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _loadEmployeeData() async {
    try {
      final employe = await _employeDao.getEmployeById(widget.employeeId!);
      
      if (employe != null) {
        setState(() {
          employee = employe;
          estActif = employee!.estActif;
          
          _nomController.text = employee!.nom;
          _prenomController.text = employee!.prenom;
          _dateNaissanceController.text = _dateFormat.format(employee!.dateNaissance);
          _dateEmbaucheController.text = _dateFormat.format(employee!.dateEmbauche);
          _posteController.text = employee!.poste;
          _salaireController.text = employee!.salaire.toStringAsFixed(2);
          _telephoneController.text = employee!.telephone;
          _adresseController.text = employee!.adresse;
          _imagePath = employee!.photoUrl;
          
          _isLoading = false;
          _hasUnsavedChanges = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Employé non trouvé')),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement de l\'employé: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors du chargement des données')),
        );
      }
    }
  }

  @override
  void dispose() {
    // Remove listeners
    _nomController.removeListener(_markAsChanged);
    _prenomController.removeListener(_markAsChanged);
    _dateNaissanceController.removeListener(_markAsChanged);
    _dateEmbaucheController.removeListener(_markAsChanged);
    _posteController.removeListener(_markAsChanged);
    _salaireController.removeListener(_markAsChanged);
    _telephoneController.removeListener(_markAsChanged);
    _adresseController.removeListener(_markAsChanged);
    
    // Dispose controllers
    _nomController.dispose();
    _prenomController.dispose();
    _dateNaissanceController.dispose();
    _dateEmbaucheController.dispose();
    _posteController.dispose();
    _salaireController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  Future<String> _generateNewEmployeeId() async {
    final allEmployes = await _employeDao.getAllEmployes();
    final existingIds = allEmployes.map((e) => e.id).toList();
    
    int counter = 1;
    String newId;
    do {
      newId = 'EMP-${counter.toString().padLeft(3, '0')}';
      counter++;
    } while (existingIds.contains(newId));
    
    return newId;
  }

  Future<void> _saveEmployee() async {
    try {
      final newId = await _generateNewEmployeeId();
      
      final newEmploye = Employe(
        id: newId,
        nom: _capitalizeFirstLetter(_nomController.text),
        prenom: _capitalizeFirstLetter(_prenomController.text),
        dateNaissance: _parseDate(_dateNaissanceController.text),
        dateEmbauche: _parseDate(_dateEmbaucheController.text),
        poste: _posteController.text,
        salaire: double.parse(_salaireController.text),
        telephone: _telephoneController.text,
        adresse: _adresseController.text,
        estActif: estActif,
        photoUrl: _imagePath ?? '', // Use selected image path
        paiements: [],
      );

      await _employeDao.insertEmploye(newEmploye);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Employé créé avec succès')),
        );
        
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Erreur lors de la création: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la création')),
        );
      }
    }
  }

  Future<void> _updateEmployee() async {
    try {
      final updatedEmploye = Employe(
        id: employee!.id,
        nom: _capitalizeFirstLetter(_nomController.text),
        prenom: _capitalizeFirstLetter(_prenomController.text),
        dateNaissance: _parseDate(_dateNaissanceController.text),
        dateEmbauche: _parseDate(_dateEmbaucheController.text),
        poste: _posteController.text,
        salaire: double.parse(_salaireController.text),
        telephone: _telephoneController.text,
        adresse: _adresseController.text,
        estActif: estActif,
        photoUrl: _imagePath ?? employee!.photoUrl, // Use new image path if available
        paiements: employee!.paiements,
      );

      await _employeDao.updateEmploye(updatedEmploye);
      
      if (mounted) {
        setState(() {
          _hasUnsavedChanges = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Employé mis à jour avec succès')),
        );
      }
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la mise à jour')),
        );
      }
    }
  }

  // Helper function to capitalize first letter
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  DateTime _parseDate(String dateString) {
    try {
      final parts = dateString.split('/');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

  ImageProvider _imageProvider() {
    if (_selectedImage != null) {
      return FileImage(_selectedImage!);
    } else if (_imagePath != null && _imagePath!.isNotEmpty) {
      if (_imagePath!.startsWith('http')) {
        return NetworkImage(_imagePath!);
      } else {
        return FileImage(File(_imagePath!));
      }
    }
    return const AssetImage('assets/default_avatar.png');
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
    DateTime initialDate,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      locale: const Locale("fr", "FR"),
    );
    if (picked != null && picked != initialDate) {
      setState(() {
        controller.text = _dateFormat.format(picked);
        _hasUnsavedChanges = true;
      });
    }
  }

  // Function to pick image from file system
  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedImage = File(result.files.single.path!);
          _imagePath = result.files.single.path;
          _hasUnsavedChanges = true;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors de la sélection de l\'image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la sélection de l\'image')),
        );
      }
    }
  }

  // Function to print payslip
  void _printPayslip() {
    // Implement your payslip printing logic here
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impression de la fiche de paie')),
      );
    }
  }

  // Function to print contract
  void _printContract() {
    // Implement your contract printing logic here
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impression du contrat')),
      );
    }
  }

  void _showAddPaymentDialog() {
    if (_isNewEmployee) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez d\'abord enregistrer l\'employé')),
        );
      }
      return;
    }

    TextEditingController moisController = TextEditingController();
    TextEditingController salaireController = TextEditingController(text: employee!.salaire.toStringAsFixed(2));
    TextEditingController montantController = TextEditingController();
    TextEditingController primeController = TextEditingController(text: "0.0");
    TextEditingController datePaiementController = TextEditingController(text: _dateFormat.format(DateTime.now()));

    // Initialize with current month and year
    DateTime selectedMonth = DateTime.now();
    moisController.text = "${_getMonthName(selectedMonth.month)} ${selectedMonth.year}";
    
    // Calculate initial amount (salaire + prime)
    double primeValue = double.tryParse(primeController.text) ?? 0.0;
    double salaireValue = double.tryParse(salaireController.text) ?? 0.0;
    montantController.text = (salaireValue + primeValue).toStringAsFixed(2);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "AJOUTER PAIEMENT",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Month picker field
                _buildMonthPickerField(
                  Icons.calendar_month,
                  "MOIS CONCERNÉ",
                  moisController,
                  selectedMonth,
                  (DateTime newMonth) {
                    setState(() {
                      selectedMonth = newMonth;
                      moisController.text = "${_getMonthName(newMonth.month)} ${newMonth.year}";
                    });
                  },
                ),
                
                _buildPaymentField(
                  Icons.attach_money,
                  "SALAIRE",
                  salaireController,
                  onChanged: (value) {
                    // Recalculate amount when salary changes
                    double primeValue = double.tryParse(primeController.text) ?? 0.0;
                    double salaireValue = double.tryParse(value) ?? 0.0;
                    montantController.text = (salaireValue + primeValue).toStringAsFixed(2);
                  },
                ),
                
                _buildPaymentField(
                  Icons.payment, 
                  "PRIMES", 
                  primeController,
                  onChanged: (value) {
                    // Recalculate amount when prime changes
                    double primeValue = double.tryParse(value) ?? 0.0;
                    double salaireValue = double.tryParse(salaireController.text) ?? 0.0;
                    montantController.text = (salaireValue + primeValue).toStringAsFixed(2);
                  },
                ),
                
                // Read-only amount field
                _buildReadOnlyPaymentField(
                  Icons.money_off,
                  "MONTANT PAYÉ",
                  montantController,
                ),
                
                _buildDatePickerFieldDialog(
                  Icons.date_range,
                  "DATE PAIEMENT",
                  datePaiementController,
                  DateTime.now(),
                ),

                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.cancel, color: Colors.white),
                      label: const Text(
                        "ANNULER",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        "AJOUTER",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () async {
                        try {
                          final nouveauPaiement = PaiementEmploye(
                            datePaiement: _parseDate(datePaiementController.text),
                            mois: moisController.text,
                            salaireBase: double.parse(salaireController.text),
                            prime: double.tryParse(primeController.text) ?? 0.0,
                            montantPaye: double.parse(montantController.text),
                            statut: StatutPaiement.paye,
                          );

                          employee!.paiements.add(nouveauPaiement);
                          await _employeDao.updateEmploye(employee!);
                          
                          Navigator.pop(context);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Paiement ajouté avec succès')),
                            );
                          }
                          
                          await _loadEmployeeData();
                        } catch (e) {
                          debugPrint('Erreur lors de l\'ajout du paiement: $e');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Erreur lors de l\'ajout du paiement')),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper method to get month name in French
  String _getMonthName(int month) {
    final months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return months[month - 1];
  }

  // Month picker field widget
  Widget _buildMonthPickerField(
    IconData icon,
    String label,
    TextEditingController controller,
    DateTime initialDate,
    Function(DateTime) onMonthSelected,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: () async {
          // Show year picker first
          final DateTime? pickedYear = await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Sélectionner une année'),
                content: SizedBox(
                  width: 300,
                  height: 300,
                  child: YearPicker(
                    firstDate: DateTime(DateTime.now().year - 10),
                    lastDate: DateTime(DateTime.now().year + 10),
                    selectedDate: initialDate,
                    onChanged: (DateTime date) {
                      Navigator.pop(context, date);
                    },
                  ),
                ),
              );
            },
          );

          if (pickedYear != null) {
            // Then show month picker
            final DateTime? pickedMonth = await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Sélectionner un mois pour ${pickedYear.year}'),
                  content: SizedBox(
                    width: 300,
                    height: 400,
                    child: GridView.count(
                      crossAxisCount: 3,
                      children: List.generate(12, (index) {
                        final month = index + 1;
                        return InkWell(
                          onTap: () {
                            Navigator.pop(context, DateTime(pickedYear.year, month));
                          },
                          child: Card(
                            child: Center(
                              child: Text(
                                _getMonthName(month),
                                style: TextStyle(
                                  fontWeight: month == initialDate.month ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                );
              },
            );

            if (pickedMonth != null) {
              onMonthSelected(pickedMonth);
            }
          }
        },
        child: IgnorePointer(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              prefixIcon: Icon(icon),
              labelText: label,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              suffixIcon: const Icon(Icons.arrow_drop_down),
            ),
          ),
        ),
      ),
    );
  }

  // Read-only payment field widget
  Widget _buildReadOnlyPaymentField(
    IconData icon,
    String label,
    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  // Updated payment field with onChanged callback
  Widget _buildPaymentField(
    IconData icon,
    String label,
    TextEditingController controller, {
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onChanged: onChanged,
      ),
    );
  }

  // Date picker field for the dialog
  Widget _buildDatePickerFieldDialog(
    IconData icon,
    String label,
    TextEditingController controller,
    DateTime initialDate,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: initialDate,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            locale: const Locale("fr", "FR"),
          );
          if (picked != null && picked != initialDate) {
            controller.text = _dateFormat.format(picked);
          }
        },
        child: IgnorePointer(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              prefixIcon: Icon(icon),
              labelText: label,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              suffixIcon: const Icon(Icons.calendar_today),
            ),
          ),
        ),
      ),
    );
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

    return MainLayout(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      if (_hasUnsavedChanges && !_isNewEmployee) {
                        _showUnsavedChangesDialog();
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isNewEmployee 
                        ? "Créer un nouvel employé"
                        : "Profil de : ${_nomController.text} ${_prenomController.text}",
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_isNewEmployee)
                    ElevatedButton.icon(
                      onPressed: _saveEmployee,
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text(
                        'Créer',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  if (!_isNewEmployee && _hasUnsavedChanges)
                    ElevatedButton.icon(
                      onPressed: _updateEmployee,
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text(
                        'Enregistrer',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTextField("Nom", _nomController, capitalize: true),
                          _buildTextField("Prénom", _prenomController, capitalize: true),
                          _buildDatePickerField(
                            "Date de naissance",
                            _dateNaissanceController,
                            _parseDate(_dateNaissanceController.text),
                          ),
                          _buildDatePickerField(
                            "Date d'embauche",
                            _dateEmbaucheController,
                            _parseDate(_dateEmbaucheController.text),
                          ),

                          const SizedBox(height: 20),
                          if (!_isNewEmployee) ...[
                            // New print buttons
                            _buildBlueButton("IMPRIMER FICHE DE PAIE", _printPayslip),
                            const SizedBox(height: 10),
                            _buildBlueButton("IMPRIMER CONTRAT", _printContract),
                            const SizedBox(height: 10),
                            _buildBlueButton(
                              "AJOUTER PAIEMENT",
                              _showAddPaymentDialog,
                            ),
                            const SizedBox(height: 10),
                            _buildBlueButton("HISTORIQUE PAIEMENTS", () {
                              if (_hasUnsavedChanges) {
                                _showUnsavedChangesDialog();
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        PaiementEmployeScreen(employe: employee!),
                                  ),
                                );
                              }
                            }),
                          ],
                        ],
                      ),
                    ),

                    Container(
                      width: 1,
                      color: Colors.grey[300],
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 50,
                                    backgroundImage: _imageProvider(),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: CircleAvatar(
                                      radius: 15,
                                      backgroundColor: Colors.white,
                                      child: const Icon(Icons.edit, size: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildTextField("Poste", _posteController),
                          _buildNumericTextField("Salaire", _salaireController),
                          _buildNumericTextField("Téléphone", _telephoneController),
                          _buildTextField("Adresse", _adresseController),

                          const SizedBox(height: 10),
                          const Text(
                            "Statut",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),

                          SizedBox(
                            width: 160,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  estActif = !estActif;
                                  _hasUnsavedChanges = true;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: estActif
                                    ? Colors.green[700]
                                    : Colors.red[700],
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: estActif ? Colors.green : Colors.red,
                                    width: 2,
                                  ),
                                ),
                                elevation: 2,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    estActif
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    estActif ? "Actif" : "Inactif",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
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

  void _showUnsavedChangesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Modifications non enregistrées'),
          content: const Text(
              'Vous avez des modifications non enregistrées. Voulez-vous les enregistrer avant de continuer ?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Ignorer'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Enregistrer'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _updateEmployee();
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool capitalize = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
            ),
            onChanged: (value) {
              if (capitalize && value.isNotEmpty) {
                // Capitalize first letter
                final selection = controller.selection;
                controller.text = _capitalizeFirstLetter(value);
                controller.selection = selection;
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNumericTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            keyboardType: label == "Salaire" 
                ? TextInputType.numberWithOptions(decimal: true)
                : TextInputType.phone,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
            ),
            inputFormatters: [
              if (label == "Salaire")
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))
              else
                FilteringTextInputFormatter.digitsOnly,
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerField(
    String label,
    TextEditingController controller,
    DateTime initialDate,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            readOnly: true,
            onTap: () => _selectDate(context, controller, initialDate),
            decoration: InputDecoration(
              suffixIcon: const Icon(Icons.calendar_today),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlueButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
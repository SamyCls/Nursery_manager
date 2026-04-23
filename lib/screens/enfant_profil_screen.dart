import 'dart:io';
import 'dart:typed_data';
import 'package:creche_manager/screens/progression.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for input formatters
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '/models/enfant.dart';
import '/layout/main_layout.dart';
import '/screens/presence_hist.dart';
import '/screens/paiements_hist.dart';
import '/db/enfant_dao.dart';
import '/models/accompagnateur.dart';
import '/db/accompagnateur_dao.dart';
import '/services/ficheenfant.dart';

class EnfantProfilScreen extends StatefulWidget {
  final Enfant enfant;

  const EnfantProfilScreen({super.key, required this.enfant});

  @override
  State<EnfantProfilScreen> createState() => _EnfantProfilScreenState();
}

class _EnfantProfilScreenState extends State<EnfantProfilScreen> {
  Uint8List? _selectedImage;
  late List<Accompagnateur> accompagnateurs = [];
  final AccompagnateurDao _accDao = AccompagnateurDao();
  final EnfantDao _enfantDao = EnfantDao();
  File? _imageFile;

  // Track unsaved changes
  bool _hasUnsavedChanges = false;

  // Controllers
  late TextEditingController nomController;
  late TextEditingController prenomController;
  late TextEditingController dateNaissanceController;
  late TextEditingController sexeController;
  late TextEditingController classeController;
  late TextEditingController adresseController;
  late TextEditingController nomPrenomPereController;
  late TextEditingController telPereController;
  late TextEditingController professionPereController;
  late TextEditingController nomPrenomMereController;
  late TextEditingController telMereController;
  late TextEditingController professionMereController;
  late TextEditingController statutFamilialController;
  late TextEditingController allergiesController;
  late TextEditingController commentairesMedicauxController;

  // For class autocomplete
  List<String> classSuggestions = [];
  final FocusNode _classeFocusNode = FocusNode();
  
  // Options for statut familial dropdown
  final List<String> statutFamilialOptions = ['Mariée', 'Divorcé', 'Autre'];

  // For date inscription editing
  bool _isEditingDateInscription = false;
  late TextEditingController _dateInscriptionController;
  DateTime? _originalDateInscription;

  @override
  void initState() {
    super.initState();
    final e = widget.enfant;

    _loadAccompagnateurs();
    _loadClassSuggestions();
    _loadImageFromPath();

    // Initialize controllers
    nomController = TextEditingController(text: e.nom);
    prenomController = TextEditingController(text: e.prenom);
    dateNaissanceController = TextEditingController(
      text: e.dateNaissance ?? '',
    );
    adresseController = TextEditingController(text: e.adresse);
    sexeController = TextEditingController(text: e.sexe ?? '');
    classeController = TextEditingController(text: e.classe);
    nomPrenomPereController = TextEditingController(
      text: e.nomPrenomPere ?? '',
    );
    telPereController = TextEditingController(text: e.telPere ?? '');
    professionPereController = TextEditingController(
      text: e.professionPere ?? '',
    );
    nomPrenomMereController = TextEditingController(
      text: e.nomPrenomMere ?? '',
    );
    telMereController = TextEditingController(text: e.telMere ?? '');
    professionMereController = TextEditingController(
      text: e.professionMere ?? '',
    );
    statutFamilialController = TextEditingController(
      text: e.statutFamilial ?? '',
    );
    allergiesController = TextEditingController(text: e.allergies ?? '');
    commentairesMedicauxController = TextEditingController(
      text: e.commentairesMedicaux ?? '',
    );

    // Initialize date inscription controller
    _dateInscriptionController = TextEditingController(
      text: e.dateInscription != null
          ? "${e.dateInscription!.day.toString().padLeft(2, '0')}/${e.dateInscription!.month.toString().padLeft(2, '0')}/${e.dateInscription!.year}"
          : "",
    );
    _originalDateInscription = e.dateInscription;

    // Add listeners to track changes
    nomController.addListener(_markAsChanged);
    prenomController.addListener(_markAsChanged);
    dateNaissanceController.addListener(_markAsChanged);
    sexeController.addListener(_markAsChanged);
    classeController.addListener(_markAsChanged);
    nomPrenomPereController.addListener(_markAsChanged);
    telPereController.addListener(_markAsChanged);
    professionPereController.addListener(_markAsChanged);
    nomPrenomMereController.addListener(_markAsChanged);
    telMereController.addListener(_markAsChanged);
    professionMereController.addListener(_markAsChanged);
    statutFamilialController.addListener(_markAsChanged);
    allergiesController.addListener(_markAsChanged);
    commentairesMedicauxController.addListener(_markAsChanged);
    adresseController.addListener(_markAsChanged);
    // Add capitalization on change
    nomController.addListener(() => _capitalizeName(nomController));
    prenomController.addListener(() => _capitalizeName(prenomController));
    nomPrenomPereController.addListener(
      () => _capitalizeName(nomPrenomPereController),
    );
    nomPrenomMereController.addListener(
      () => _capitalizeName(nomPrenomMereController),
    );
    professionPereController.addListener(
      () => _capitalizeName(professionPereController),
    );
    professionMereController.addListener(
      () => _capitalizeName(professionMereController),
    );

    // Add class capitalization when focus is lost
    _classeFocusNode.addListener(() {
      if (!_classeFocusNode.hasFocus) {
        _capitalizeClass();
      }
    });
  }

  // Function to capitalize names (first letter of each word)
  void _capitalizeName(TextEditingController controller) {
    final text = controller.text;
    if (text.isNotEmpty) {
      final newText = text
          .toLowerCase()
          .split(' ')
          .map(
            (word) => word.isNotEmpty
                ? word[0].toUpperCase() + word.substring(1)
                : '',
          )
          .join(' ');

      if (newText != text) {
        controller.value = controller.value.copyWith(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        );
      }
    }
  }

  // Function to capitalize class (first letter only)
  void _capitalizeClass() {
    final text = classeController.text;
    if (text.isNotEmpty) {
      final newText = text[0].toUpperCase() + text.substring(1).toLowerCase();
      if (newText != text) {
        classeController.value = classeController.value.copyWith(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        );
      }
    }
  }

  void _markAsChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  // Load class suggestions from database
  Future<void> _loadClassSuggestions() async {
    final enfants = await _enfantDao.getAllEnfants();
    final classes = enfants.map((e) => e.classe).toSet().toList();
    setState(() {
      classSuggestions = classes;
    });
  }

  // Load image from file path
  Future<void> _loadImageFromPath() async {
    if (widget.enfant.photoPath != null && widget.enfant.photoPath!.isNotEmpty) {
      final file = File(widget.enfant.photoPath!);
      if (await file.exists()) {
        setState(() {
          _imageFile = file;
        });
      }
    }
  }

  // Get the profiles directory
  Future<Directory> _getProfilesDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final profilesDir = Directory(path.join(appDocDir.path, 'profiles'));
    if (!await profilesDir.exists()) {
      await profilesDir.create(recursive: true);
    }
    return profilesDir;
  }

  // ✅ Generate next ID like ENF-001, ENF-002
Future<String> _generateNextId() async {
  final enfants = await _enfantDao.getAllEnfants();
  
  if (enfants.isEmpty) return "ENF-001";
  
  // Find all existing ENF numbers
  final existingNumbers = <int>{};
  final regExp = RegExp(r'^ENF-(\d+)$');
  
  for (final enfant in enfants) {
    final match = regExp.firstMatch(enfant.id);
    if (match != null) {
      final number = int.tryParse(match.group(1)!);
      if (number != null) {
        existingNumbers.add(number);
      }
    }
  }
  
  // If no valid ENF IDs found, start from 1
  if (existingNumbers.isEmpty) return "ENF-001";
  
  // Find the next available number
  int nextNumber = 1;
  while (existingNumbers.contains(nextNumber)) {
    nextNumber++;
  }
  
  return "ENF-${nextNumber.toString().padLeft(3, '0')}";
}

  // ✅ Build Enfant object from form
  Future<Enfant> _buildEnfant() async {
    String id = widget.enfant.id;
    if (id.isEmpty) {
      id = await _generateNextId();
    }

    return Enfant(
      id: id,
      nom: nomController.text,
      prenom: prenomController.text,
      classe: classeController.text,
      telephone: widget.enfant.telephone,
      estActif: widget.enfant.estActif,
      dateNaissance: dateNaissanceController.text,
      sexe: sexeController.text,
      adresse: adresseController.text,
      photoPath: widget.enfant.photoPath,
      nomPrenomPere: nomPrenomPereController.text,
      telPere: telPereController.text,
      professionPere: professionPereController.text,
      adressePere: widget.enfant.adressePere,
      nomPrenomMere: nomPrenomMereController.text,
      telMere: telMereController.text,
      professionMere: professionMereController.text,
      statutFamilial: statutFamilialController.text,
      allergies: allergiesController.text,
      commentairesMedicaux: commentairesMedicauxController.text,
      dossierMedicalPath: widget.enfant.dossierMedicalPath,
      dateInscription: widget.enfant.dateInscription ?? DateTime.now(),
    );
  }

  ImageProvider? _getProfileImage() {
    if (_imageFile != null && _imageFile!.existsSync()) {
      return FileImage(_imageFile!);
    } else if (_selectedImage != null) {
      return MemoryImage(_selectedImage!);
    } else if (widget.enfant.photoPath != null && 
               widget.enfant.photoPath!.isNotEmpty) {
      final file = File(widget.enfant.photoPath!);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }
    return null; // Return null when no image is selected
  }

  Future<void> _loadAccompagnateurs() async {
    final list = await _accDao.getAccompagnateursByEnfant(widget.enfant.id);
    setState(() {
      accompagnateurs = list;
    });
  }

  // ✅ Save enfant (insert or update)
  Future<bool> _saveEnfant() async {
    try {
      // Save the image first if a new one was selected
      if (_selectedImage != null) {
        await _saveImageToFile();
      }

      final enfant = await _buildEnfant();
      final existing = await _enfantDao.getEnfantById(enfant.id);

      if (existing == null) {
        await _enfantDao.insertEnfant(enfant);
      } else {
        await _enfantDao.updateEnfant(enfant);
      }

      setState(() {
        _hasUnsavedChanges = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Enfant ${existing == null ? 'ajouté' : 'modifié'} avec succès ✅",
            ),
          ),
        );
      }

      // Return true to indicate successful save
      return true;
    } catch (e) {
      print('Erreur lors de la sauvegarde: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la sauvegarde')),
      );

      // Return false to indicate failure
      return false;
    }
  }

  // Save the selected image to file
  Future<void> _saveImageToFile() async {
    if (_selectedImage == null) return;

    try {
      final profilesDir = await _getProfilesDirectory();
      final imageFile = File(path.join(profilesDir.path, 'enfant_${widget.enfant.id}.jpg'));
      
      await imageFile.writeAsBytes(_selectedImage!);
      
      // Update the enfant's photoPath
      widget.enfant.photoPath = imageFile.path;
      
      setState(() {
        _imageFile = imageFile;
        _selectedImage = null; // Clear the temporary selection
      });
      
      print('Image sauvegardée: ${imageFile.path}');
    } catch (e) {
      print('Erreur lors de la sauvegarde de l\'image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sauvegarde de l\'image: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ✅ Delete enfant
  Future<void> _deleteEnfant() async {
    if (widget.enfant.id.isEmpty) return;

    // Show confirmation dialog
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: const Text(
            'Êtes-vous sûr de vouloir supprimer cet enfant ?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text(
                'Supprimer',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      // Delete the profile image if it exists
      if (widget.enfant.photoPath != null && widget.enfant.photoPath!.isNotEmpty) {
        final imageFile = File(widget.enfant.photoPath!);
        if (await imageFile.exists()) {
          await imageFile.delete();
        }
      }
      
      await _enfantDao.deleteEnfant(widget.enfant.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Enfant supprimé ❌")));
        Navigator.pop(context);
      }
    }
  }

  // Toggle activation status
  Future<void> _toggleActivationStatus() async {
    final newStatus = !widget.enfant.estActif;
    
    // Show confirmation dialog
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(newStatus ? 'Activer l\'enfant' : 'Désactiver l\'enfant'),
          content: Text(
            newStatus 
              ? 'Êtes-vous sûr de vouloir activer cet enfant ?'
              : 'Êtes-vous sûr de vouloir désactiver cet enfant ?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text(newStatus ? 'Activer' : 'Désactiver'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        // Update the enfant status
        final updatedEnfant = Enfant(
          id: widget.enfant.id,
          nom: widget.enfant.nom,
          prenom: widget.enfant.prenom,
          classe: widget.enfant.classe,
          telephone: widget.enfant.telephone,
          estActif: newStatus,
          dateNaissance: widget.enfant.dateNaissance,
          sexe: widget.enfant.sexe,
          adresse: widget.enfant.adresse,
          photoPath: widget.enfant.photoPath,
          dateInscription: widget.enfant.dateInscription,
          nomPrenomPere: widget.enfant.nomPrenomPere,
          telPere: widget.enfant.telPere,
          professionPere: widget.enfant.professionPere,
          adressePere: widget.enfant.adressePere,
          nomPrenomMere: widget.enfant.nomPrenomMere,
          telMere: widget.enfant.telMere,
          professionMere: widget.enfant.professionMere,
          statutFamilial: widget.enfant.statutFamilial,
          allergies: widget.enfant.allergies,
          commentairesMedicaux: widget.enfant.commentairesMedicaux,
          dossierMedicalPath: widget.enfant.dossierMedicalPath,
        );

        await _enfantDao.updateEnfant(updatedEnfant);
        
        // Update the local widget state
        widget.enfant.estActif = newStatus;
        
        setState(() {
          _hasUnsavedChanges = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                newStatus 
                  ? 'Enfant activé avec succès ✅'
                  : 'Enfant désactivé avec succès ⚠️',
              ),
            ),
          );
        }
      } catch (e) {
        print('Erreur lors de la modification du statut: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la modification du statut')),
        );
      }
    }
  }

  void _showUnsavedChangesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Modifications non enregistrées'),
          content: const Text(
            'Vous avez des modifications non enregistrées. Voulez-vous les enregistrer avant de continuer ?',
          ),
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
                await _saveEnfant();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Show date picker for birth date
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedDate =
          "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      setState(() {
        dateNaissanceController.text = formattedDate;
        _hasUnsavedChanges = true;
      });
    }
  }

  // Show date picker for inscription date
  Future<void> _selectInscriptionDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.enfant.dateInscription ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedDate =
          "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      setState(() {
        _dateInscriptionController.text = formattedDate;
        widget.enfant.dateInscription = picked;
        _hasUnsavedChanges = true;
      });
    }
  }

  // Toggle date inscription editing mode
  void _toggleDateInscriptionEditing() {
    setState(() {
      _isEditingDateInscription = !_isEditingDateInscription;
      if (!_isEditingDateInscription) {
        // If canceling edit, restore original date
        if (_originalDateInscription != null) {
          widget.enfant.dateInscription = _originalDateInscription;
          _dateInscriptionController.text = 
              "${_originalDateInscription!.day.toString().padLeft(2, '0')}/"
              "${_originalDateInscription!.month.toString().padLeft(2, '0')}/"
              "${_originalDateInscription!.year}";
        }
      } else {
        // When starting to edit, save the original date
        _originalDateInscription = widget.enfant.dateInscription;
      }
    });
  }

  void _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'bmp', 'gif'],
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        if (file.bytes != null) {
          setState(() {
            _selectedImage = file.bytes;
            _hasUnsavedChanges = true;
          });
          
          // Preview the selected image
          final tempDir = await getTemporaryDirectory();
          final tempFile = File(path.join(tempDir.path, 'temp_image.jpg'));
          await tempFile.writeAsBytes(_selectedImage!);
          
          setState(() {
            _imageFile = tempFile;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image sélectionnée: ${file.name}')),
          );
        } else if (file.path != null) {
          // If we have a file path instead of bytes (some desktop platforms)
          final fileBytes = await File(file.path!).readAsBytes();
          setState(() {
            _selectedImage = fileBytes;
            _hasUnsavedChanges = true;
          });
          
          setState(() {
            _imageFile = File(file.path!);
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image sélectionnée: ${file.name}')),
          );
        }
      }
    } catch (e) {
      print('Erreur lors de la sélection de l\'image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection de l\'image: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showEditAccompagnateurDialog({Accompagnateur? acc}) {
    final nomCtrl = TextEditingController(text: acc?.nomPrenom ?? "");
    final telCtrl = TextEditingController(text: acc?.telephone ?? "");
    final cinCtrl = TextEditingController(text: acc?.cin ?? "");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          acc == null ? "Ajouter Accompagnateur" : "Modifier Accompagnateur",
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomCtrl,
              decoration: const InputDecoration(labelText: "Nom & Prénom"),
              onChanged: (value) {
                // Capitalize name in real-time
                if (value.isNotEmpty) {
                  final newValue = value
                      .toLowerCase()
                      .split(' ')
                      .map(
                        (word) => word.isNotEmpty
                            ? word[0].toUpperCase() + word.substring(1)
                            : '',
                      )
                      .join(' ');

                  if (newValue != value) {
                    nomCtrl.value = nomCtrl.value.copyWith(
                      text: newValue,
                      selection: TextSelection.collapsed(
                        offset: newValue.length,
                      ),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: telCtrl,
              decoration: const InputDecoration(labelText: "Téléphone"),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly, // Only allow digits
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: cinCtrl,
              decoration: const InputDecoration(labelText: "CIN"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (acc == null) {
                final newAcc = Accompagnateur(
                  enfantId: widget.enfant.id,
                  nomPrenom: nomCtrl.text,
                  telephone: telCtrl.text,
                  cin: cinCtrl.text,
                );
                await _accDao.insertAccompagnateur(newAcc);
              } else {
                final updated = Accompagnateur(
                  id: acc.id,
                  enfantId: acc.enfantId,
                  nomPrenom: nomCtrl.text,
                  telephone: telCtrl.text,
                  cin: cinCtrl.text,
                );
                await _accDao.updateAccompagnateur(updated);
              }

              await _loadAccompagnateurs();
              setState(() {
                _hasUnsavedChanges = true;
              });
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isDateField = false,
    bool isSexeField = false,
    bool isClassField = false,
    bool isPhoneField = false,
    bool isStatutFamilialField = false,
  }) {
    if (isDateField) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: _selectDate,
            ),
          ),
          readOnly: true,
          onTap: _selectDate,
        ),
      );
    } else if (isSexeField) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DropdownButtonFormField<String>(
          value: controller.text.isNotEmpty ? controller.text : null,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'Masculin', child: Text('Masculin')),
            DropdownMenuItem(value: 'Féminin', child: Text('Féminin')),
          ],
          onChanged: (value) {
            setState(() {
              controller.text = value ?? '';
              _hasUnsavedChanges = true;
            });
          },
        ),
      );
    } else if (isClassField) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<String>.empty();
            }
            return classSuggestions.where((String option) {
              return option.toLowerCase().contains(
                textEditingValue.text.toLowerCase(),
              );
            });
          },
          fieldViewBuilder:
              (
                BuildContext context,
                TextEditingController textEditingController,
                FocusNode focusNode,
                VoidCallback onFieldSubmitted,
              ) {
                textEditingController.text = controller.text;
                textEditingController.addListener(() {
                  controller.text = textEditingController.text;
                });
                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: label,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    _hasUnsavedChanges = true;
                  },
                );
              },
          onSelected: (String selection) {
            setState(() {
              controller.text = selection;
              _hasUnsavedChanges = true;
            });
          },
        ),
      );
    } else if (isPhoneField) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly, // Only allow digits
          ],
        ),
      );
    } else if (isStatutFamilialField) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DropdownButtonFormField<String>(
          value: controller.text.isNotEmpty ? controller.text : null,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          items: statutFamilialOptions.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              controller.text = value ?? '';
              _hasUnsavedChanges = true;
            });
          },
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
        ),
      );
    }
  }

  Widget _buildBlueButton(String label, {VoidCallback? onPressed}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  // Build activation/deactivation button
  Widget _buildActivationButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ElevatedButton(
        onPressed: _toggleActivationStatus,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.enfant.estActif ? Colors.orange : Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          widget.enfant.estActif ? 'DÉSACTIVER ENFANT' : 'ACTIVER ENFANT',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildAccompagnateurCard(Accompagnateur acc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Nom : ${acc.nomPrenom}"),
                Text("Téléphone : ${acc.telephone}"),
                Text("CIN : ${acc.cin}"),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () => _showEditAccompagnateurDialog(acc: acc),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              if (acc.id != null) {
                await _accDao.deleteAccompagnateur(acc.id!);
                await _loadAccompagnateurs();
                setState(() {
                  _hasUnsavedChanges = true;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  // Widget for date inscription with double-tap to edit feature
  Widget _buildDateInscriptionWidget() {
    if (_isEditingDateInscription) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _dateInscriptionController,
            decoration: InputDecoration(
              labelText: "Date d'inscription",
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: _selectInscriptionDate,
              ),
            ),
            readOnly: true,
            onTap: _selectInscriptionDate,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(
                onPressed: _toggleDateInscriptionEditing,
                child: const Text('Annuler'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isEditingDateInscription = false;
                    _hasUnsavedChanges = true;
                  });
                },
                child: const Text('Valider'),
              ),
            ],
          ),
        ],
      );
    } else {
      return GestureDetector(
        onDoubleTap: _toggleDateInscriptionEditing,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            "Date d'inscription : ${_dateInscriptionController.text}",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    // Remove listeners
    nomController.removeListener(_markAsChanged);
    prenomController.removeListener(_markAsChanged);
    dateNaissanceController.removeListener(_markAsChanged);
    sexeController.removeListener(_markAsChanged);
    classeController.removeListener(_markAsChanged);
    nomPrenomPereController.removeListener(_markAsChanged);
    telPereController.removeListener(_markAsChanged);
    professionPereController.removeListener(_markAsChanged);
    nomPrenomMereController.removeListener(_markAsChanged);
    telMereController.removeListener(_markAsChanged);
    professionMereController.removeListener(_markAsChanged);
    statutFamilialController.removeListener(_markAsChanged);
    allergiesController.removeListener(_markAsChanged);
    commentairesMedicauxController.removeListener(_markAsChanged);

    // Remove capitalization listeners
    nomController.removeListener(() => _capitalizeName(nomController));
    prenomController.removeListener(() => _capitalizeName(prenomController));
    nomPrenomPereController.removeListener(
      () => _capitalizeName(nomPrenomPereController),
    );
    nomPrenomMereController.removeListener(
      () => _capitalizeName(nomPrenomMereController),
    );
    professionPereController.removeListener(
      () => _capitalizeName(professionPereController),
    );
    professionMereController.removeListener(
      () => _capitalizeName(professionMereController),
    );

    // Dispose focus node
    _classeFocusNode.dispose();

    // Dispose controllers
    nomController.dispose();
    prenomController.dispose();
    dateNaissanceController.dispose();
    sexeController.dispose();
    classeController.dispose();
    nomPrenomPereController.dispose();
    telPereController.dispose();
    professionPereController.dispose();
    nomPrenomMereController.dispose();
    telMereController.dispose();
    professionMereController.dispose();
    statutFamilialController.dispose();
    allergiesController.dispose();
    commentairesMedicauxController.dispose();
    _dateInscriptionController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: Column(
        children: [
          AppBar(
            backgroundColor: const Color(0xfff6f7fb),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (_hasUnsavedChanges) {
                  _showUnsavedChangesDialog();
                } else {
                  Navigator.pop(context);
                }
              },
            ),
            title: Text(
              'Profil de ${widget.enfant.nom} ${widget.enfant.prenom}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
            ),
            actions: [
              if (_hasUnsavedChanges)
                ElevatedButton.icon(
                  onPressed: () async {
                    final success = await _saveEnfant();
                    if (success && mounted) {
                      Navigator.of(
                        context,
                      ).pop(true); // Return true to parent screen
                    }
                  },
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text(
                    "Enregistrer",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: _deleteEnfant,
              ),
            ],
            elevation: 2,
          ),

          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Colonne gauche : photo et infos de base de l'enfant
                Container(
                  width: 300,
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundImage: _getProfileImage(),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: _pickImage,
                            ),
                          ],
                        ),
                        const SizedBox(height: 13),
                        _buildTextField("Nom", nomController),
                        _buildTextField("Prénom", prenomController),
                        _buildTextField(
                          "Date de naissance",
                          dateNaissanceController,
                          isDateField: true,
                        ),
                        _buildTextField(
                          "Sexe",
                          sexeController,
                          isSexeField: true,
                        ),
                        _buildTextField(
                          "Classe / groupe",
                          classeController,
                          isClassField: true,
                        ),
                        _buildTextField("Adresse", adresseController),
                        const SizedBox(height: 20),
                        _buildActivationButton(), // Added activation button
                        _buildBlueButton(
                          "IMPRIMER FICHE ENFANT",
                          onPressed: () async {
                            // First save any unsaved changes
                            if (_hasUnsavedChanges) {
                              final success = await _saveEnfant();
                              if (!success) return;
                            }

                            // Generate and save the PDF
                            try {
                              await PDFFillService.fillAndSaveChildForm(
                                widget.enfant,
                                accompagnateurs,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Fiche enfant générée et sauvegardée ✅",
                                  ),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Erreur lors de la génération du PDF: $e",
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                        _buildBlueButton("IMPRIMER CARTE ENFANT"),
                        _buildBlueButton(
                          "HISTORIQUE DE PRÉSENCE",
                          onPressed: () {
                            if (_hasUnsavedChanges) {
                              _showUnsavedChangesDialog();
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PresenceCalendar(enfant: widget.enfant),
                                ),
                              );
                            }
                          },
                        ),
                        _buildBlueButton(
                          "HISTORIQUE DES PAIEMENTS",
                          onPressed: () {
                            if (_hasUnsavedChanges) {
                              _showUnsavedChangesDialog();
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      PaiementScreen(enfant: widget.enfant),
                                ),
                              );
                            }
                          },
                        ),
                         _buildBlueButton(
                          "EVALUATION",
                          onPressed: () {
                            if (_hasUnsavedChanges) {
                              _showUnsavedChangesDialog();
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      EvaluationPage(enfant: widget.enfant),
                                ),
                              );
                            }
                          },
                        ),
                        
                        // DATE D'INSCRIPTION EN BAS DES BOUTONS BLEUS
                        const SizedBox(height: 20),
                        _buildDateInscriptionWidget(),
                      ],
                    ),
                  ),
                ),

                // Vertical divider
                Container(
                  width: 1,
                  height: double.infinity,
                  color: Colors.grey[300],
                ),

                // Colonne droite : Infos parentales, accompagnateurs, santé
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            "Infos Parentales",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            // Infos du père
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Père",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    "Nom & Prénom",
                                    nomPrenomPereController,
                                  ),
                                  _buildTextField(
                                    "Téléphone",
                                    telPereController,
                                    isPhoneField: true, // Added this parameter
                                  ),
                                  _buildTextField(
                                    "Profession",
                                    professionPereController,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Infos de la mère
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Mère",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    "Nom & Prénom",
                                    nomPrenomMereController,
                                  ),
                                  _buildTextField(
                                    "Téléphone",
                                    telMereController,
                                    isPhoneField: true, // Added this parameter
                                  ),
                                  _buildTextField(
                                    "Profession",
                                    professionMereController,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        _buildTextField(
                          "Statut familial",
                          statutFamilialController,
                          isStatutFamilialField: true,
                        ),
                        const SizedBox(height: 24),
                        const Divider(thickness: 1),
                        const Text(
                          "Accompagnateurs autorisés",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => _showEditAccompagnateurDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text("Ajouter un accompagnateur"),
                        ),
                        const SizedBox(height: 16),
                        ...accompagnateurs
                            .map((acc) => _buildAccompagnateurCard(acc))
                            .toList(),
                        const SizedBox(height: 32),
                        const Divider(thickness: 1),
                        const Text(
                          "Infos Santé",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                "Allergies",
                                allergiesController,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                "Commentaires médicaux",
                                commentairesMedicauxController,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../models/employe.dart';
import '../layout/main_layout.dart';
import '../db/employedao.dart'; // Import your DAO

class PaiementEmployeScreen extends StatefulWidget {
  final Employe employe;

  const PaiementEmployeScreen({super.key, required this.employe});

  @override
  State<PaiementEmployeScreen> createState() => _PaiementEmployeScreenState();
}

class _PaiementEmployeScreenState extends State<PaiementEmployeScreen> {
  late List<PaiementEmploye> paiements;
  final EmployeDao _employeDao = EmployeDao(); // DAO instance
  int? _editingIndex; // Track which payment is being edited

  @override
  void initState() {
    super.initState();
    paiements = List.from(widget.employe.paiements);
    _editingIndex = null;
  }

  String _statutToString(StatutPaiement statut) {
    return statut == StatutPaiement.paye ? 'Payé' : 'Impayé';
  }

  Color getColor(StatutPaiement statut) {
    return statut == StatutPaiement.paye ? Colors.green : Colors.red;
  }

  void _updateStatut(PaiementEmploye p) {
    if (p.montantPaye >= p.salaireTotal) {
      p.statut = StatutPaiement.paye;
    } else {
      p.statut = StatutPaiement.impaye;
    }
  }

  // Save payment changes to database
  Future<void> _savePaymentChanges(PaiementEmploye payment) async {
    try {
      // Update the employee with the modified payment
      widget.employe.paiements = paiements;
      await _employeDao.updateEmploye(widget.employe);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paiement mis à jour avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  // Toggle edit mode for a payment
  void _toggleEditMode(int index) {
    setState(() {
      if (_editingIndex == index) {
        // Save changes and exit edit mode
        _savePaymentChanges(paiements[index]);
        _editingIndex = null;
      } else {
        // Enter edit mode for this payment
        _editingIndex = index;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Paiements : ${widget.employe.nom} ${widget.employe.prenom}',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildTableHeader(),
                      const Divider(thickness: 1.2),
                      Expanded(
                        child: ListView.builder(
                          itemCount: paiements.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onDoubleTap: () => _toggleEditMode(index),
                              child: Column(
                                children: [
                                  _buildRow(paiements[index], index),
                                  Divider(
                                    color: Colors.grey.shade300,
                                    thickness: 1,
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
      ),
    );
  }

  Widget _buildTableHeader() {
    return Row(
      children: const [
        _HeaderCell("📅 Date"),
        _HeaderCell("📆 Mois"),
        _HeaderCell("💰 Salaire total"),
        _HeaderCell("✅ Payé"),
        _HeaderCell("💸 Reste"),
        _HeaderCell("📊 Statut"),
      ],
    );
  }

  Widget _buildRow(PaiementEmploye paiement, int index) {
    final dateStr =
        '${paiement.datePaiement.day.toString().padLeft(2, '0')}/${paiement.datePaiement.month.toString().padLeft(2, '0')}/${paiement.datePaiement.year}';

    final isEditing = _editingIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _Cell(dateStr),
          _Cell(paiement.mois),
          Expanded(
            child: Center(
              child: Text(
                '${paiement.salaireTotal} DA',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Center(
              child: SizedBox(
                width: 100,
                height: 50,
                child: TextFormField(
                  enabled: isEditing, // Only enabled when editing
                  initialValue: paiement.montantPaye.toString(),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isEditing 
                        ? Colors.blue.shade50 
                        : Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(vertical: 6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: isEditing 
                            ? Colors.blue 
                            : Colors.grey.shade400
                      ),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      paiement.montantPaye =
                          double.tryParse(val) ?? paiement.montantPaye;
                      _updateStatut(paiement);
                    });
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Center(
              child: Text(
                '${paiement.salaireTotal - paiement.montantPaye} DA',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: getColor(paiement.statut).withOpacity(0.1),
                  border: Border.all(
                    color: isEditing 
                        ? Colors.blue 
                        : getColor(paiement.statut)
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<StatutPaiement>(
                    isExpanded: true,
                    value: paiement.statut,
                    items: StatutPaiement.values.map((statut) {
                      return DropdownMenuItem(
                        value: statut,
                        child: Center(
                          child: Text(
                            _statutToString(statut),
                            style: TextStyle(
                              color: getColor(statut),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: isEditing // Only enabled when editing
                        ? (val) {
                            if (val != null) {
                              setState(() {
                                paiement.statut = val;
                              });
                            }
                          }
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String title;
  const _HeaderCell(this.title);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String value;
  const _Cell(this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          value,
          style: const TextStyle(color: Colors.black87, fontSize: 16),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '/models/enfant.dart';
import '/layout/main_layout.dart';
import '/db/enfant_dao.dart'; // Import the DAO

class PaiementScreen extends StatefulWidget {
  final Enfant enfant;

  const PaiementScreen({super.key, required this.enfant});

  @override
  State<PaiementScreen> createState() => _PaiementScreenState();
}

class _PaiementScreenState extends State<PaiementScreen> {
  late List<Paiement> paiements;
  final EnfantDao _enfantDao = EnfantDao();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    paiements = List.from(widget.enfant.paiements ?? []);
    _loadPaiements();
  }

  Future<void> _loadPaiements() async {
    try {
      final loadedPaiements = await _enfantDao.getPaiementsByEnfantId(widget.enfant.id);
      setState(() {
        paiements = loadedPaiements;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading payments: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _savePaiement(Paiement paiement) async {
    try {
      await _enfantDao.insertPaiement(widget.enfant.id, paiement);
      await _loadPaiements(); // Reload the payments
    } catch (e) {
      print('Error saving payment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sauvegarde: $e')),
      );
    }
  }

  Future<void> _updatePaiement(Paiement paiement) async {
    try {
      await _enfantDao.updatePaiement(widget.enfant.id, paiement);
      await _loadPaiements(); // Reload the payments
    } catch (e) {
      print('Error updating payment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la mise à jour: $e')),
      );
    }
  }

  Future<void> _deletePaiement(String paiementId) async {
    try {
      await _enfantDao.deletePaiement(paiementId, widget.enfant.id);
      await _loadPaiements(); // Reload the payments
    } catch (e) {
      print('Error deleting payment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression: $e')),
      );
    }
  }

  void _showAddPaiementDialog() {
    final now = DateTime.now();
    final newPaiement = Paiement(
      date: now,
      mois: _getMonthName(now.month),
      montantdu: 0,
      montantPaye: 0,
      reste: 0,
      statut: StatutPaiements.impaye,
    );

    showDialog(
      context: context,
      builder: (context) => PaiementDialog(
        paiement: newPaiement,
        onSave: (paiement) {
          _savePaiement(paiement);
          Navigator.pop(context);
        },
        isNew: true,
      ),
    );
  }

  void _showEditPaiementDialog(Paiement paiement) {
    showDialog(
      context: context,
      builder: (context) => PaiementDialog(
        paiement: paiement,
        onSave: (updatedPaiement) {
          _updatePaiement(updatedPaiement);
          Navigator.pop(context);
        },
        onDelete: () {
          _deletePaiement('${widget.enfant.id}_${paiement.mois}_${paiement.date.millisecondsSinceEpoch}');
          Navigator.pop(context);
        },
        isNew: false,
      ),
    );
  }

  String _getMonthName(int month) {
    final months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return months[month - 1];
  }

  String _statutToString(StatutPaiements statut) {
    switch (statut) {
      case StatutPaiements.paye:
        return 'payé';
      case StatutPaiements.impaye:
        return 'impayé';
      case StatutPaiements.partiel:
        return 'partiel';
    }
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
                      'Paiements de : ${widget.enfant.nom} ${widget.enfant.prenom}',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 30),
                    onPressed: _showAddPaiementDialog,
                    tooltip: 'Ajouter un paiement',
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
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : paiements.isEmpty
                                ? const Center(
                                    child: Text(
                                      'Aucun paiement enregistré',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: paiements.length,
                                    itemBuilder: (context, index) {
                                      return GestureDetector(
                                        onTap: () => _showEditPaiementDialog(paiements[index]),
                                        child: Column(
                                          children: [
                                            _buildRow(paiements[index]),
                                            Divider(
                                              color: Colors.grey.shade300,
                                              thickness: 1,
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                      )
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
    return const Row(
      children: [
        _HeaderCell("📅 Date"),
        _HeaderCell("📆 Mois"),
        _HeaderCell("💰 Dû"),
        _HeaderCell("✅ Payé"),
        _HeaderCell("💸 Reste"),
        _HeaderCell("📊 Statut"),
      ],
    );
  }

  Widget _buildRow(Paiement paiement) {
    final dateStr =
        '${paiement.date.day.toString().padLeft(2, '0')}/${paiement.date.month.toString().padLeft(2, '0')}/${paiement.date.year}';

    Color getColor(StatutPaiements statut) {
      switch (statut) {
        case StatutPaiements.paye:
          return Colors.green;
        case StatutPaiements.impaye:
          return Colors.red;
        case StatutPaiements.partiel:
          return Colors.amber;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _Cell(dateStr),
          _Cell(paiement.mois),
          _Cell('${paiement.montantdu} DA'),
          _Cell('${paiement.montantPaye} DA'),
          _Cell('${paiement.montantdu - paiement.montantPaye} DA'),
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: getColor(paiement.statut).withOpacity(0.1),
                  border: Border.all(color: getColor(paiement.statut)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _statutToString(paiement.statut),
                  style: TextStyle(
                    color: getColor(paiement.statut),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
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

class PaiementDialog extends StatefulWidget {
  final Paiement paiement;
  final Function(Paiement) onSave;
  final Function()? onDelete;
  final bool isNew;

  const PaiementDialog({
    super.key,
    required this.paiement,
    required this.onSave,
    this.onDelete,
    required this.isNew,
  });

  @override
  State<PaiementDialog> createState() => _PaiementDialogState();
}

class _PaiementDialogState extends State<PaiementDialog> {
  late DateTime _selectedDate;
  late String _selectedMonth;
  late int _montantdu;
  late int _montantPaye;
  late StatutPaiements _statut;

  final List<String> _months = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.paiement.date;
    _selectedMonth = widget.paiement.mois;
    _montantdu = widget.paiement.montantdu;
    _montantPaye = widget.paiement.montantPaye;
    _statut = widget.paiement.statut;
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedMonth = _months[picked.month - 1];
      });
    }
  }

  void _updateStatut() {
    if (_montantPaye == 0) {
      _statut = StatutPaiements.impaye;
    } else if (_montantPaye >= _montantdu) {
      _statut = StatutPaiements.paye;
    } else {
      _statut = StatutPaiements.partiel;
    }
  }

  // Function for the print button (does nothing as requested)
  void _onPrintPressed() {
    // This function does nothing as requested
    print("Imprimer button pressed");
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isNew ? 'Nouveau Paiement' : 'Modifier Paiement'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date'),
              subtitle: Text(
                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              ),
              onTap: _selectDate,
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Mois'),
              subtitle: Text(_selectedMonth),
            ),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Montant Dû',
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              initialValue: _montantdu.toString(),
              onChanged: (value) {
                setState(() {
                  _montantdu = int.tryParse(value) ?? _montantdu;
                  _updateStatut();
                });
              },
            ),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Montant Payé',
                prefixIcon: Icon(Icons.payment),
              ),
              keyboardType: TextInputType.number,
              initialValue: _montantPaye.toString(),
              onChanged: (value) {
                setState(() {
                  _montantPaye = int.tryParse(value) ?? _montantPaye;
                  _updateStatut();
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('Reste à payer'),
              subtitle: Text('${_montantdu - _montantPaye} DA'),
            ),
            ListTile(
              leading: const Icon(Icons.stacked_bar_chart),
              title: const Text('Statut'),
              subtitle: Text(_statutToString(_statut)),
            ),
          ],
        ),
      ),
      actions: [
        // Add the Imprimer button
        if (!widget.isNew)
          ElevatedButton.icon(
            onPressed: _onPrintPressed,
            icon: const Icon(Icons.print),
            label: const Text('Imprimer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        
        if (!widget.isNew && widget.onDelete != null)
          TextButton(
            onPressed: () {
              widget.onDelete!();
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            final updatedPaiement = Paiement(
              date: _selectedDate,
              mois: _selectedMonth,
              montantdu: _montantdu,
              montantPaye: _montantPaye,
              reste: _montantdu - _montantPaye,
              statut: _statut,
            );
            widget.onSave(updatedPaiement);
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }

  String _statutToString(StatutPaiements statut) {
    switch (statut) {
      case StatutPaiements.paye:
        return 'Payé';
      case StatutPaiements.impaye:
        return 'Impayé';
      case StatutPaiements.partiel:
        return 'Partiel';
    }
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
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
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
          style: const TextStyle(color: Colors.black87, fontSize: 19),
        ),
      ),
    );
  }
}
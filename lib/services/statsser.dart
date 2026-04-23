// services/stats_repository.dart
import 'package:fl_chart/fl_chart.dart';
import '../db/database_helper.dart';

class StatsRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Get total revenue from payments - INCLUDE partial payments
  Future<double> getTotalRevenue() async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.rawQuery('''
        SELECT SUM(montantPaye) as total 
        FROM paiements 
        WHERE statut IN (0, 2)  -- 0: payé, 2: partiel
      ''');
      
      final total = (result.first['total'] as num?)?.toDouble() ?? 0.0;
      print('Total revenue: $total');
      return total;
    } catch (e) {
      print('Error in getTotalRevenue: $e');
      return 0.0;
    }
  }

  // Get current month revenue - INCLUDE partial payments
  Future<double> getCurrentMonthRevenue() async {
    try {
      final db = await _databaseHelper.database;
      final now = DateTime.now();
      final currentMonthYear = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      
      final result = await db.rawQuery('''
        SELECT SUM(montantPaye) as total 
        FROM paiements 
        WHERE substr(date, 1, 7) = ? 
        AND statut IN (0, 2)  -- 0: payé, 2: partiel
      ''', [currentMonthYear]);
      
      final total = (result.first['total'] as num?)?.toDouble() ?? 0.0;
      print('Current month revenue ($currentMonthYear): $total');
      return total;
    } catch (e) {
      print('Error in getCurrentMonthRevenue: $e');
      return 0.0;
    }
  }

  // Get total expenses
  Future<double> getTotalExpenses() async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.rawQuery('''
        SELECT SUM(montant) as total FROM depenses
      ''');
      return (result.first['total'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      print('Error in getTotalExpenses: $e');
      return 0.0;
    }
  }

  // Get current month expenses
  Future<double> getCurrentMonthExpenses() async {
    try {
      final db = await _databaseHelper.database;
      final now = DateTime.now();
      final currentMonthYear = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      
      final result = await db.rawQuery('''
        SELECT SUM(montant) as total 
        FROM depenses 
        WHERE substr(date, 1, 7) = ?
      ''', [currentMonthYear]);
      
      final total = (result.first['total'] as num?)?.toDouble() ?? 0.0;
      print('Current month expenses ($currentMonthYear): $total');
      return total;
    } catch (e) {
      print('Error in getCurrentMonthExpenses: $e');
      return 0.0;
    }
  }

  // Get expenses by category
  Future<Map<String, double>> getExpensesByCategory() async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.rawQuery('''
        SELECT categorie, SUM(montant) as total 
        FROM depenses 
        GROUP BY categorie
      ''');
      
      final Map<String, double> expensesByCategory = {};
      for (var row in result) {
        expensesByCategory[row['categorie'] as String] = (row['total'] as num).toDouble();
      }
      return expensesByCategory;
    } catch (e) {
      print('Error in getExpensesByCategory: $e');
      return {};
    }
  }

  // Get payment status distribution - CORRECTED for your DB values
  Future<Map<String, double>> getPaymentStatusDistribution() async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.rawQuery('''
        SELECT 
          COUNT(*) as total,
          SUM(CASE WHEN statut = 0 THEN 1 ELSE 0 END) as paye,      -- 0: payé
          SUM(CASE WHEN statut = 2 THEN 1 ELSE 0 END) as partiel,   -- 2: partiel
          SUM(CASE WHEN statut = 1 THEN 1 ELSE 0 END) as impaye     -- 1: impayé
        FROM paiements
      ''');
      
      final row = result.first;
      final int total = (row['total'] as num?)?.toInt() ?? 0;
      final int paye = (row['paye'] as num?)?.toInt() ?? 0;
      final int partiel = (row['partiel'] as num?)?.toInt() ?? 0;
      final int impaye = (row['impaye'] as num?)?.toInt() ?? 0;

      print('Payment distribution - Total: $total, Payé: $paye, Partiel: $partiel, Impayé: $impaye');

      if (total == 0) return {"Payés": 0, "Partiels": 0, "Impayés": 0};

      return {
        "Payés": (paye / total * 100),
        "Partiels": (partiel / total * 100),
        "Impayés": (impaye / total * 100),
      };
    } catch (e) {
      print('Error in getPaymentStatusDistribution: $e');
      return {"Payés": 0, "Partiels": 0, "Impayés": 0};
    }
  }

  // Debug method to check all payments
  Future<void> debugPayments() async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.rawQuery('''
        SELECT id, montantPaye, statut, date 
        FROM paiements 
        ORDER BY date DESC
        LIMIT 20
      ''');
      
      print('=== DEBUG: Last 20 payments ===');
      for (var row in result) {
        final statut = row['statut'];
        String statutText;
        switch (statut) {
          case 0: statutText = 'payé'; break;
          case 1: statutText = 'impayé'; break;
          case 2: statutText = 'partiel'; break;
          default: statutText = 'inconnu ($statut)';
        }
        print('ID: ${row['id']}, MontantPaye: ${row['montantPaye']}, Statut: $statutText, Date: ${row['date']}');
      }
      print('=== END DEBUG ===');
      
      // Additional debug: check payment counts by status
      final statusResult = await db.rawQuery('''
        SELECT 
          statut,
          COUNT(*) as count, 
          SUM(montantPaye) as total 
        FROM paiements 
        GROUP BY statut
      ''');
      
      print('=== Payment counts by status ===');
      for (var row in statusResult) {
        final statut = row['statut'];
        String statutText;
        switch (statut) {
          case 0: statutText = 'payé'; break;
          case 1: statutText = 'impayé'; break;
          case 2: statutText = 'partiel'; break;
          default: statutText = 'inconnu ($statut)';
        }
        print('Statut: $statutText, Count: ${row['count']}, Total: ${row['total']}');
      }
      
    } catch (e) {
      print('Error in debugPayments: $e');
    }
  }

  // Get revenue by month for a specific year - INCLUDE partial payments
  Future<List<FlSpot>> getRevenueByMonth(int year) async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.rawQuery('''
        SELECT 
          substr(date, 6, 2) as month,
          SUM(montantPaye) as total
        FROM paiements 
        WHERE substr(date, 1, 4) = ?
        AND statut IN (0, 2)  -- 0: payé, 2: partiel
        GROUP BY substr(date, 6, 2)
        ORDER BY month
      ''', [year.toString()]);

      print('Revenue by month for $year:');
      for (var row in result) {
        print('Month: ${row['month']}, Total: ${row['total']}');
      }

      final List<FlSpot> spots = List.generate(12, (index) => FlSpot(index.toDouble(), 0));
      
      for (var row in result) {
        final monthStr = row['month'] as String?;
        final month = int.tryParse(monthStr ?? '') ?? 1;
        final total = (row['total'] as num?)?.toDouble() ?? 0;
        if (month >= 1 && month <= 12) {
          spots[month - 1] = FlSpot((month - 1).toDouble(), total);
        }
      }
      
      return spots;
    } catch (e) {
      print('Error in getRevenueByMonth: $e');
      return List.generate(12, (index) => FlSpot(index.toDouble(), 0));
    }
  }

  Future<double> getMonthRevenue(int year, int month) async {
  try {
    final db = await _databaseHelper.database;
    final monthYear = '$year-${month.toString().padLeft(2, '0')}';
    
    final result = await db.rawQuery('''
      SELECT SUM(montantPaye) as total 
      FROM paiements 
      WHERE substr(date, 1, 7) = ? 
      AND statut IN (0, 2)  -- 0: payé, 2: partiel
    ''', [monthYear]);
    
    final total = (result.first['total'] as num?)?.toDouble() ?? 0.0;
    print('Revenue for $monthYear: $total');
    return total;
  } catch (e) {
    print('Error in getMonthRevenue: $e');
    return 0.0;
  }
}

// Get expenses for a specific month and year
Future<double> getMonthExpenses(int year, int month) async {
  try {
    final db = await _databaseHelper.database;
    final monthYear = '$year-${month.toString().padLeft(2, '0')}';
    
    final result = await db.rawQuery('''
      SELECT SUM(montant) as total 
      FROM depenses 
      WHERE substr(date, 1, 7) = ?
    ''', [monthYear]);
    
    final total = (result.first['total'] as num?)?.toDouble() ?? 0.0;
    print('Expenses for $monthYear: $total');
    return total;
  } catch (e) {
    print('Error in getMonthExpenses: $e');
    return 0.0;
  }
}

// Get expenses by category for a specific month and year
Future<Map<String, double>> getExpensesByCategoryForMonth(int year, int month) async {
  try {
    final db = await _databaseHelper.database;
    final monthYear = '$year-${month.toString().padLeft(2, '0')}';
    
    final result = await db.rawQuery('''
      SELECT categorie, SUM(montant) as total 
      FROM depenses 
      WHERE substr(date, 1, 7) = ?
      GROUP BY categorie
    ''', [monthYear]);
    
    final Map<String, double> expensesByCategory = {};
    for (var row in result) {
      expensesByCategory[row['categorie'] as String] = (row['total'] as num).toDouble();
    }
    return expensesByCategory;
  } catch (e) {
    print('Error in getExpensesByCategoryForMonth: $e');
    return {};
  }
}

  // Get available years from payments
  Future<List<int>> getAvailableYears() async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.rawQuery('''
        SELECT DISTINCT substr(date, 1, 4) as year 
        FROM paiements 
        ORDER by year DESC
      ''');
      
      return result.map((row) {
        final yearStr = row['year'] as String?;
        return int.tryParse(yearStr ?? '') ?? DateTime.now().year;
      }).toList();
    } catch (e) {
      print('Error in getAvailableYears: $e');
      return [DateTime.now().year];
    }
  }
}
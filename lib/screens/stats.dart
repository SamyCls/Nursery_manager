import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/statsser.dart';
import '/layout/main_layout.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late int selectedYear;
  int selectedMonth = DateTime.now().month;
  final StatsRepository _statsRepository = StatsRepository();

  // State variables
  double totalRevenue = 0;
  double revenueCeMois = 0;
  double totalDepenses = 0;
  double depensesCeMois = 0;
  Map<String, double> depensesParCategorie = {};
  Map<String, double> repartitionPaiements = {};
  List<FlSpot> revenueSpots = [];
  List<FlSpot> expenseSpots = [];
  List<int> availableYears = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    selectedYear = DateTime.now().year;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    try {
      final results = await Future.wait([
        _statsRepository.getTotalRevenue(),
        _statsRepository.getCurrentMonthRevenue(),
        _statsRepository.getTotalExpenses(),
        _statsRepository.getCurrentMonthExpenses(),
        _statsRepository.getExpensesByCategory(),
        _statsRepository.getPaymentStatusDistribution(),
        _statsRepository.getRevenueByMonth(selectedYear),
        _statsRepository.getAvailableYears(),
        _statsRepository.getExpensesByMonth(selectedYear),
      ]);

      setState(() {
        totalRevenue = results[0] as double;
        revenueCeMois = results[1] as double;
        totalDepenses = results[2] as double;
        depensesCeMois = results[3] as double;
        depensesParCategorie = results[4] as Map<String, double>;
        repartitionPaiements = results[5] as Map<String, double>;
        revenueSpots = results[6] as List<FlSpot>;
        availableYears = results[7] as List<int>;
        expenseSpots = results[8] as List<FlSpot>;
        // Guard: ensure selectedYear is always present in the list
        if (!availableYears.contains(selectedYear)) {
          availableYears.insert(0, selectedYear);
        }
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading statistics: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  Future<void> _onYearChanged(int? newYear) async {
    if (newYear != null) {
      setState(() {
        selectedYear = newYear;
        isLoading = true;
      });

      try {
        final results = await Future.wait([
          _statsRepository.getRevenueByMonth(newYear),
          _statsRepository.getExpensesByMonth(newYear),
        ]);
        setState(() {
          revenueSpots = results[0] as List<FlSpot>;
          expenseSpots = results[1] as List<FlSpot>;
          isLoading = false;
        });
      } catch (e) {
        debugPrint('Error loading year data: $e');
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _onMonthChanged(int? newMonth) async {
    if (newMonth != null) {
      setState(() {
        selectedMonth = newMonth;
        isLoading = true;
      });

      try {
        // Charger les données spécifiques au mois sélectionné
        final results = await Future.wait([
          _statsRepository.getMonthRevenue(selectedYear, selectedMonth),
          _statsRepository.getMonthExpenses(selectedYear, selectedMonth),
          _statsRepository.getExpensesByCategoryForMonth(selectedYear, selectedMonth),
        ]);

        setState(() {
          revenueCeMois = results[0] as double;
          depensesCeMois = results[1] as double;
          depensesParCategorie = results[2] as Map<String, double>;
          isLoading = false;
        });
      } catch (e) {
        debugPrint('Error loading month data: $e');
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final netProfitTotal = totalRevenue - totalDepenses;
    final netProfitCeMois = revenueCeMois - depensesCeMois;

    if (isLoading) {
      return MainLayout(
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return MainLayout(
      child: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Statistiques",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // Month + Year pickers
                  Row(
                    children: [
                      // Month
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButton<int>(
                          value: selectedMonth,
                          underline: const SizedBox(),
                          items: List.generate(12, (index) {
                            const monthNames = [
                       'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'September', 'Octobre', 'Novembre', 'Décembre'
                            ];
                            return DropdownMenuItem(
                              value: index + 1,
                              child: Text(monthNames[index]),
                            );
                          }),
                          onChanged: _onMonthChanged,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Year
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButton<int>(
                          value: selectedYear,
                          underline: const SizedBox(),
                          items: availableYears
                              .map((y) => DropdownMenuItem(
                                    value: y,
                                    child: Text(y.toString()),
                                  ))
                              .toList(),
                          onChanged: _onYearChanged,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Info Cards
              Row(
                children: [
                  Expanded(
                    child: _buildCombinedInfoCard(
                      title: 'Revenue',
                      totalValue: _formatCurrency(totalRevenue),
                      currentMonthValue: _formatCurrency(revenueCeMois),
                      color: const Color(0xFFD0E8FF),
                      icon: Icons.attach_money,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCombinedInfoCard(
                      title: 'Dépenses',
                      totalValue: _formatCurrency(totalDepenses),
                      currentMonthValue: _formatCurrency(depensesCeMois),
                      color: const Color(0xFFFFD9D9),
                      icon: Icons.money_off,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCombinedInfoCard(
                      title: 'Profit Net',
                      totalValue: _formatCurrency(netProfitTotal),
                      currentMonthValue: _formatCurrency(netProfitCeMois),
                      color: netProfitCeMois >= 0
                          ? const Color(0xFFE6F4D9)
                          : const Color(0xFFFFE6E6),
                      icon: netProfitCeMois >= 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Two main charts side-by-side, horizontally scrollable
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(width: 520, child: _buildRevenueChart()),
                      const SizedBox(width: 16),
                      SizedBox(width: 520, child: _buildRevenueVsExpensesChart()),
                    ],
                  ),
                ),
              ),

              // Pie + Bar charts
              const SizedBox(height: 24),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(width: 520, child: _buildPieChartSection()),
                      const SizedBox(width: 16),
                      SizedBox(width: 520, child: _buildBarChartSection()),
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

  Widget _buildRevenueChart() {
    const moisLabels = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc',
    ];

    final maxY = _calculateMaxY(revenueSpots);
    final interval = _calculateYInterval(revenueSpots.map((e) => e.y).toList());

    // KPI summary
    final double peak = revenueSpots.isEmpty ? 0 : revenueSpots.map((e) => e.y).reduce(max);
    final double total = revenueSpots.fold(0, (s, e) => s + e.y);
    final double avg = revenueSpots.isEmpty ? 0 : total / revenueSpots.length;
    final int peakMonthIdx = revenueSpots.isEmpty
        ? 0
        : revenueSpots.indexWhere((e) => e.y == peak);
    final String peakMonthName =
        (peakMonthIdx >= 0 && peakMonthIdx < 12) ? moisLabels[peakMonthIdx] : '--';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header gradient ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Évolution du revenue',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Recettes mensuelles — $selectedYear',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.70),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                // Year picker chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withOpacity(0.30)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: selectedYear,
                      isDense: true,
                      dropdownColor: const Color(0xFF1E40AF),
                      icon: const Icon(Icons.expand_more, color: Colors.white, size: 18),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                      items: availableYears
                          .map((y) => DropdownMenuItem(
                                value: y,
                                child: Text(y.toString()),
                              ))
                          .toList(),
                      onChanged: _onYearChanged,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── KPI chips row ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFF0F6FF),
            ),
            child: Row(
              children: [
                _revenueKpi(Icons.trending_up_rounded, 'Total', _formatCurrency(total), const Color(0xFF3B82F6)),
                _revenueKpiDivider(),
                _revenueKpi(Icons.star_rounded, 'Meilleur mois', '$peakMonthName · ${_formatCurrency(peak)}', const Color(0xFF10B981)),
                _revenueKpiDivider(),
                _revenueKpi(Icons.calculate_rounded, 'Moyenne', _formatCurrency(avg), const Color(0xFF8B5CF6)),
              ],
            ),
          ),

          // ── Chart ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 24, 12),
            child: SizedBox(
              height: 170,
              child: revenueSpots.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucune donnée pour cette année',
                        style: TextStyle(color: Colors.black38, fontSize: 14),
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: interval,
                          getDrawingHorizontalLine: (_) => FlLine(
                            color: const Color(0xFFE5E7EB),
                            strokeWidth: 1,
                            dashArray: [5, 4],
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        minX: 0,
                        maxX: 11,
                        minY: 0,
                        maxY: maxY,
                        titlesData: FlTitlesData(
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                if (idx < 0 || idx >= 12 || idx != value) return const SizedBox();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    moisLabels[idx],
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 80,
                              interval: interval,
                              getTitlesWidget: (value, meta) {
                                if (value == 0) return const SizedBox();
                                return Text(
                                  _formatCurrency(value),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF9CA3AF),
                                    fontWeight: FontWeight.w500,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: revenueSpots,
                            isCurved: true,
                            curveSmoothness: 0.4,
                            isStrokeCapRound: true,
                            barWidth: 3,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF3B82F6)],
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF3B82F6).withOpacity(0.25),
                                  const Color(0xFF6366F1).withOpacity(0.00),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, bar, index) =>
                                  FlDotCirclePainter(
                                radius: 4,
                                color: Colors.white,
                                strokeWidth: 2.5,
                                strokeColor: const Color(0xFF3B82F6),
                              ),
                            ),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          handleBuiltInTouches: true,
                          touchTooltipData: LineTouchTooltipData(
                            tooltipRoundedRadius: 12,
                            tooltipPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            tooltipBorder: BorderSide.none,
                            getTooltipColor: (_) => const Color(0xFF1E293B),
                            getTooltipItems: (spots) => spots.map((s) {
                              final idx = s.x.toInt();
                              final monthName = (idx >= 0 && idx < 12) ? moisLabels[idx] : '';
                              return LineTooltipItem(
                                '$monthName\n',
                                const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                                children: [
                                  TextSpan(
                                    text: _formatCurrency(s.y),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _revenueKpi(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w500)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B)),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _revenueKpiDivider() => Container(
        width: 1,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        color: const Color(0xFFD1D5DB),
      );

  Widget _buildRevenueVsExpensesChart() {
    const moisLabels = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc',
    ];

    // Show all 12 months
    final allRevenue = List.generate(12, (i) =>
        revenueSpots.firstWhere((s) => s.x == i.toDouble(), orElse: () => FlSpot(i.toDouble(), 0)).y);
    final allExpenses = List.generate(12, (i) =>
        expenseSpots.firstWhere((s) => s.x == i.toDouble(), orElse: () => FlSpot(i.toDouble(), 0)).y);

    final allVals = [...allRevenue, ...allExpenses];
    final maxVal = allVals.isEmpty ? 1000.0 : allVals.reduce(max);
    final maxY = (maxVal * 1.25).ceilToDouble();
    final interval = _calculateYInterval(allVals.where((v) => v > 0).toList());

    final totalRev = allRevenue.fold(0.0, (s, v) => s + v);
    final totalExp = allExpenses.fold(0.0, (s, v) => s + v);
    final netProfit = totalRev - totalExp;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF064E3B), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Revenue vs Dépenses',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.3)),
                      const SizedBox(height: 4),
                      Text('Comparaison mensuelle — $selectedYear',
                          style: TextStyle(color: Colors.white.withOpacity(0.70), fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // KPI strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: const BoxDecoration(color: Color(0xFFF0FDF9)),
            child: Row(
              children: [
                _revenueKpi(Icons.arrow_upward_rounded, 'Revenue total', _formatCurrency(totalRev), const Color(0xFF10B981)),
                _revenueKpiDivider(),
                _revenueKpi(Icons.arrow_downward_rounded, 'Dépenses total', _formatCurrency(totalExp), const Color(0xFFEF4444)),
                _revenueKpiDivider(),
                _revenueKpi(
                  netProfit >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  'Profit net',
                  _formatCurrency(netProfit),
                  netProfit >= 0 ? const Color(0xFF3B82F6) : const Color(0xFFEF4444),
                ),
              ],
            ),
          ),

          // Chart
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 24, 12),
            child: SizedBox(
              height: 170,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barGroups: List.generate(12, (i) => BarChartGroupData(
                    x: i,
                    groupVertically: false,
                    barsSpace: 4,
                    barRods: [
                      BarChartRodData(
                        toY: allRevenue[i],
                        gradient: const LinearGradient(
                          colors: [Color(0xFF34D399), Color(0xFF10B981)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 14,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                      ),
                      BarChartRodData(
                        toY: allExpenses[i],
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFCA5A5), Color(0xFFEF4444)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 14,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                      ),
                    ],
                  )),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: interval > 0 ? interval : 1000,
                    getDrawingHorizontalLine: (_) => const FlLine(
                      color: Color(0xFFE5E7EB),
                      strokeWidth: 1,
                      dashArray: [5, 4],
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 80,
                        interval: interval > 0 ? interval : 1000,
                        getTitlesWidget: (v, _) => v == 0
                            ? const SizedBox()
                            : Text(_formatCurrency(v),
                                style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500)),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= 12) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(moisLabels[i],
                                style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600)),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      tooltipRoundedRadius: 12,
                      getTooltipColor: (_) => const Color(0xFF1E293B),
                      getTooltipItem: (group, gi, rod, ri) {
                        final label = ri == 0 ? 'Revenue' : 'Dépenses';
                        return BarTooltipItem(
                          '${moisLabels[gi]} · $label\n',
                          const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w500),
                          children: [
                            TextSpan(
                              text: _formatCurrency(rod.toY),
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Legend
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _rveLegendChip(const Color(0xFF10B981), 'Revenue'),
                const SizedBox(width: 16),
                _rveLegendChip(const Color(0xFFEF4444), 'Dépenses'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rveLegendChip(Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12, height: 12,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ],
      );

  Widget _buildPieChartSection() {
    const payColors = [Color(0xFF10B981), Color(0xFFF59E0B), Color(0xFFEF4444)];
    const payLabels = ['Payés', 'Partiels', 'Impayés'];
    final payKeys = ['Payés', 'Partiels', 'Impayés'];
    final payValues = payKeys.map((k) => repartitionPaiements[k] ?? 0).toList();
    final total = payValues.fold(0.0, (s, v) => s + v);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF065F46), Color(0xFF10B981)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Statut des paiements',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.3)),
                const SizedBox(height: 4),
                Text('Répartition pour $selectedYear',
                    style: TextStyle(color: Colors.white.withOpacity(0.70), fontSize: 13)),
              ],
            ),
          ),
          // Chart + legend
          Padding(
            padding: const EdgeInsets.all(16),
            child: total == 0
                ? const SizedBox(
                    height: 220,
                    child: Center(
                      child: Text('Aucune donnée', style: TextStyle(color: Colors.black38, fontSize: 14)),
                    ),
                  )
                : Column(
                    children: [
                      SizedBox(
                        height: 170,
                        child: PieChart(
                          PieChartData(
                            centerSpaceRadius: 38,
                            sectionsSpace: 3,
                            sections: List.generate(3, (i) {
                              final val = payValues[i];
                              final pct = total > 0 ? (val / total * 100) : 0.0;
                              return PieChartSectionData(
                                value: val,
                                color: payColors[i],
                                radius: 42,
                                title: pct < 5 ? '' : '${pct.toStringAsFixed(0)}%',
                                titleStyle: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              );
                            }),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Legend chips
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: List.generate(3, (i) {
                          final val = payValues[i];
                          final pct = total > 0 ? (val / total * 100) : 0.0;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: payColors[i].withOpacity(0.10),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: payColors[i].withOpacity(0.30)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(width: 8, height: 8,
                                    decoration: BoxDecoration(color: payColors[i], shape: BoxShape.circle)),
                                const SizedBox(width: 6),
                                Text('${payLabels[i]}  ${pct.toStringAsFixed(0)}%',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: payColors[i])),
                              ],
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChartSection() {
    final cats = depensesParCategorie.keys.toList();
    final vals = depensesParCategorie.values.toList();
    final barColors = [
      const Color(0xFF6366F1), const Color(0xFF3B82F6), const Color(0xFF10B981),
      const Color(0xFFF59E0B), const Color(0xFFEF4444), const Color(0xFF8B5CF6),
      const Color(0xFF14B8A6), const Color(0xFFF97316),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF92400E), Color(0xFFF59E0B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Dépenses par catégorie',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.3)),
                const SizedBox(height: 4),
                Text('Ce mois — ${_getMonthName(selectedMonth)} $selectedYear',
                    style: TextStyle(color: Colors.white.withOpacity(0.70), fontSize: 13)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 24, 16),
            child: cats.isEmpty
                ? const SizedBox(
                    height: 220,
                    child: Center(
                      child: Text('Aucune dépense ce mois', style: TextStyle(color: Colors.black38, fontSize: 14)),
                    ),
                  )
                : SizedBox(
                    height: 190,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        barGroups: List.generate(cats.length, (i) {
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: vals[i],
                                gradient: LinearGradient(
                                  colors: [
                                    barColors[i % barColors.length].withOpacity(0.70),
                                    barColors[i % barColors.length],
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                width: 32,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                              ),
                            ],
                          );
                        }),
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (_) => const FlLine(
                            color: Color(0xFFE5E7EB),
                            strokeWidth: 1,
                            dashArray: [5, 4],
                          ),
                        ),
                        titlesData: FlTitlesData(
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 80,
                              interval: _calculateYInterval(vals),
                              getTitlesWidget: (v, _) => v == 0
                                  ? const SizedBox()
                                  : Text(_formatCurrency(v),
                                      style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500)),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 36,
                              getTitlesWidget: (v, _) {
                                final i = v.toInt();
                                if (i < 0 || i >= cats.length) return const SizedBox();
                                String label = cats[i];
                                if (label.length > 8) label = '${label.substring(0, 7)}…';
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(label,
                                      style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280), fontWeight: FontWeight.w500)),
                                );
                              },
                            ),
                          ),
                        ),
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            tooltipRoundedRadius: 12,
                            getTooltipColor: (_) => const Color(0xFF1E293B),
                            getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                              '${cats[gi]}\n',
                              const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w500),
                              children: [
                                TextSpan(
                                  text: _formatCurrency(rod.toY),
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedInfoCard({
    required String title,
    required String totalValue,
    required String currentMonthValue,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey[800]),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Total: $totalValue',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_getMonthName(selectedMonth)}: $currentMonthValue',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    return NumberFormat.decimalPattern().format(value);
  }

  double _calculateMaxY(List<FlSpot> spots) {
    if (spots.isEmpty) return 1000;
    final maxY = spots.map((e) => e.y).reduce(max);
    return (maxY * 1.2).ceilToDouble();
  }

  double _calculateYInterval(List<double> values) {
    if (values.isEmpty) return 1000;

    final maxVal = values.reduce(max);
    if (maxVal == 0) return 100;

    final rawInterval = maxVal / 5;
    final magnitude = pow(10, (log(rawInterval) / ln10).floor()).toDouble();
    final niceInterval = (rawInterval / magnitude).ceil() * magnitude;

    return niceInterval;
  }

  String _getMonthName(int month) {
    const monthNames = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'September', 'Octobre', 'Novembre', 'Décembre'
    ];
    return monthNames[month - 1];
  }
}
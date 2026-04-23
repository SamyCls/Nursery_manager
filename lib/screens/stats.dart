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
        final newSpots = await _statsRepository.getRevenueByMonth(newYear);
        setState(() {
          revenueSpots = newSpots;
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
              const SizedBox(height: 32),

              // Line Chart
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Évolution du revenue',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<int>(
                    value: selectedYear,
                    items: availableYears
                        .map((y) => DropdownMenuItem(
                              value: y,
                              child: Text(y.toString()),
                            ))
                        .toList(),
                    onChanged: _onYearChanged,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 400,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: LineChart(
                    LineChartData(
                      gridData:
                          FlGridData(show: true, drawVerticalLine: false),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              const mois = [
                                'Jan', 'Fev', 'Mar', 'Avr', 'Mai', 'Juin',
                                'Juil', 'Aou', 'Sep', 'Oct', 'Nov', 'Dec',
                              ];
                              int index = value.toInt();
                              if (index < 0 ||
                                  index >= mois.length ||
                                  index != value) return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  mois[index],
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 100,
                            interval: _calculateYInterval(
                                revenueSpots.map((e) => e.y).toList()),
                            getTitlesWidget: (value, meta) {
                              return Text(
                                _formatCurrency(value),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles:
                            AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles:
                            AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: const Border(
                          left: BorderSide(color: Colors.black12),
                          bottom: BorderSide(color: Colors.black12),
                        ),
                      ),
                      minX: 0,
                      maxX: 11,
                      minY: 0,
                      maxY: _calculateMaxY(revenueSpots),
                      lineBarsData: [
                        LineChartBarData(
                          spots: revenueSpots,
                          isCurved: true,
                          color: Colors.blueAccent,
                          barWidth: 3,
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.blueAccent.withOpacity(0.1),
                          ),
                          dotData: FlDotData(show: revenueSpots.length <= 24),
                          isStrokeCapRound: true,
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((e) {
                              return LineTooltipItem(
                                _formatCurrency(e.y),
                                const TextStyle(color: Colors.white),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Pie + Bar charts
              const SizedBox(height: 32),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 800) {
                    return Column(
                      children: [
                        _buildPieChartSection(),
                        const SizedBox(height: 24),
                        _buildBarChartSection(),
                      ],
                    );
                  } else {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildPieChartSection()),
                        const SizedBox(width: 24),
                        Expanded(child: _buildBarChartSection()),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPieChartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statut des paiements',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          height: 400,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 50,
              sections: [
                PieChartSectionData(
                  value: repartitionPaiements["Payés"] ?? 0,
                  color: Colors.green,
                  title:
                      '${(repartitionPaiements["Payés"] ?? 0).toStringAsFixed(0)}%',
                  radius: 65,
                  titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                PieChartSectionData(
                  value: repartitionPaiements["Partiels"] ?? 0,
                  color: Colors.orange,
                  title:
                      '${(repartitionPaiements["Partiels"] ?? 0).toStringAsFixed(0)}%',
                  radius: 65,
                  titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                PieChartSectionData(
                  value: repartitionPaiements["Impayés"] ?? 0,
                  color: Colors.redAccent,
                  title:
                      '${(repartitionPaiements["Impayés"] ?? 0).toStringAsFixed(0)}%',
                  radius: 65,
                  titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildLegend(),
      ],
    );
  }

  Widget _buildBarChartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dépenses par catégorie',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          height: 400,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              barGroups: depensesParCategorie.entries.map((e) {
                return BarChartGroupData(
                  x: depensesParCategorie.keys.toList().indexOf(e.key),
                  barRods: [
                    BarChartRodData(
                      toY: e.value,
                      color: Colors.blueAccent,
                      width: 28,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final cats = depensesParCategorie.keys.toList();
                      if (value.toInt() >= cats.length) return const SizedBox();

                      String category = cats[value.toInt()];
                      if (category.length > 10) {
                        category = '${category.substring(0, 8)}...';
                      }

                      return Transform.rotate(
                        angle: -0.5, // ~ -30°
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            category,
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 100,
                    interval:
                        _calculateYInterval(depensesParCategorie.values.toList()),
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: Text(
                          _formatCurrency(value),
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${depensesParCategorie.keys.elementAt(groupIndex)}\n${_formatCurrency(rod.toY)}',
                      const TextStyle(color: Colors.white),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
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

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(Colors.green, 'Payés'),
        const SizedBox(width: 16),
        _buildLegendItem(Colors.orange, 'Partiels'),
        const SizedBox(width: 16),
        _buildLegendItem(Colors.redAccent, 'Impayés'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(width: 16, height: 16, color: color),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  String _getMonthName(int month) {
    const monthNames = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'September', 'Octobre', 'Novembre', 'Décembre'
    ];
    return monthNames[month - 1];
  }
}
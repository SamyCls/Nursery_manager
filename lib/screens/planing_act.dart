import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/layout/main_layout.dart';
import '/models/activity.dart';
import '/db/activitydao.dart';
import '/db/enfant_dao.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class WeeklyPlannerPage extends StatefulWidget {
  const WeeklyPlannerPage({super.key});

  @override
  State<WeeklyPlannerPage> createState() => _WeeklyPlannerPageState();
}

class _WeeklyPlannerPageState extends State<WeeklyPlannerPage> {
  List<String> classes = [];
  final List<String> activityTypes = [
    'Jeux',
    'Lecture',
    'Sport',
    'Art',
    'Musique',
  ];

  final Map<String, Color> activityColors = {
    'Jeux':    const Color(0xFF3B82F6), // blue
    'Lecture': const Color(0xFF10B981), // emerald
    'Sport':   const Color(0xFFEF4444), // red
    'Art':     const Color(0xFF8B5CF6), // violet
    'Musique': const Color(0xFFF59E0B), // amber
  };

  String? selectedClass;
  String? selectedActivityType;
  TimeOfDay? selectedStartTime;
  TimeOfDay? selectedEndTime;
  final TextEditingController notesController = TextEditingController();
  Activity? selectedActivity;
  DateTime selectedDate = DateTime.now();

  final ActivityDao activityDao = ActivityDao();
  final EnfantDao enfantDao = EnfantDao();
  List<Activity> allActivities = [];

  final TimeOfDay startHour = const TimeOfDay(hour: 8, minute: 0);
  final TimeOfDay endHour = const TimeOfDay(hour: 17, minute: 0);
  final int numberOfRows = 9;
  double cellWidth = 160;

  @override
  void initState() {
    super.initState();
    _loadClassesAndActivities();
  }

  Future<void> _loadClassesAndActivities() async {
    final enfants = await enfantDao.getAllEnfants();
    final distinctClasses = enfants.map((e) => e.classe).toSet().toList();
    
    final activities = await activityDao.getAllActivities();
    
    if (mounted) {
      setState(() {
        classes = distinctClasses;
        allActivities = activities;
        
        if (classes.isNotEmpty && selectedClass == null) {
          selectedClass = classes[0];
        }
      });
    }
  }

  // Custom time picker with restrictions
  Future<TimeOfDay?> _showRestrictedTimePicker(
    BuildContext context, {
    required TimeOfDay initialTime,
    required TimeOfDay firstAllowedTime,
    required TimeOfDay lastAllowedTime,
  }) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: true,
          ),
          child: child!,
        );
      },
    );

    // Validate the selected time
    if (picked != null) {
      final totalMinutes = picked.hour * 60 + picked.minute;
      final firstMinutes = firstAllowedTime.hour * 60 + firstAllowedTime.minute;
      final lastMinutes = lastAllowedTime.hour * 60 + lastAllowedTime.minute;

      if (totalMinutes < firstMinutes || totalMinutes > lastMinutes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Veuillez choisir une heure entre ${firstAllowedTime.format(context)} et ${lastAllowedTime.format(context)}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }
    }

    return picked;
  }

  pw.Widget _buildPDFTable() {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 1),
      children: [
        pw.TableRow(
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Heure', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(selectedDate),
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
          ],
        ),
        ...List.generate(numberOfRows, (index) {
          final hour = startHour.hour + index;
          final timeText = '$hour:00';
          final dayActivities = _getActivitiesForDayAndClass(selectedDate);
          final activitiesForThisHour = dayActivities.where((a) => a.start.hour == hour).toList();

          return pw.TableRow(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(timeText, style: const pw.TextStyle(fontSize: 10)),
              ),
              activitiesForThisHour.isEmpty
                  ? pw.Container(height: 30, child: pw.Text(''))
                  : pw.Container(
                      height: 30,
                      child: pw.Center(
                        child: pw.Text(
                          activitiesForThisHour.first.title,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
            ],
          );
        }),
      ],
    );
  }

  static DateTime _startOfWeek(DateTime dt) {
    final diff = dt.weekday % 7;
    final s = DateTime(dt.year, dt.month, dt.day).subtract(Duration(days: diff));
    return DateTime(s.year, s.month, s.day);
  }

  List<DateTime> getWeekDays(DateTime start) =>
      List.generate(7, (i) => start.add(Duration(days: i)));

  String _formatDay(DateTime date) =>
      DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(date);

  void _changeDate(DateTime newDate) {
    setState(() {
      selectedDate = DateTime(newDate.year, newDate.month, newDate.day);
      selectedActivity = null;
    });
  }

void _addOrEditActivity({Activity? activityToEdit}) {
  DateTime? selectedDate;
  String? tempSelectedActivityType;
  TimeOfDay? tempSelectedStartTime;
  TimeOfDay? tempSelectedEndTime;
  String? tempSelectedClass;
  final TextEditingController tempNotesController = TextEditingController();

  if (activityToEdit != null) {
    tempSelectedActivityType = activityToEdit.title;
    tempSelectedStartTime = activityToEdit.start;
    tempSelectedEndTime = activityToEdit.end;
    tempNotesController.text = activityToEdit.notes;
    selectedDate = activityToEdit.date;
    tempSelectedClass = activityToEdit.className;
  } else {
    selectedDate = DateTime.now();
    tempSelectedClass = selectedClass;
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Type d\'activité',
                    ),
                    value: tempSelectedActivityType,
                    items: activityTypes
                        .map((type) =>
                            DropdownMenuItem(value: type, child: Text(type)))
                        .toList(),
                    onChanged: (value) {
                      setModalState(() {
                        tempSelectedActivityType = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Classe',
                    ),
                    value: tempSelectedClass,
                    items: classes
                        .map((classe) =>
                            DropdownMenuItem(value: classe, child: Text(classe)))
                        .toList(),
                    onChanged: (value) {
                      setModalState(() {
                        tempSelectedClass = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        setModalState(() => selectedDate = date);
                      }
                    },
                    child: Text(
                      selectedDate == null
                          ? 'Choisir la date'
                          : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            final time = await _showRestrictedTimePicker(
                              context,
                              initialTime: tempSelectedStartTime ?? const TimeOfDay(hour: 8, minute: 0),
                              firstAllowedTime: const TimeOfDay(hour: 8, minute: 0),
                              lastAllowedTime: const TimeOfDay(hour: 17, minute: 0),
                            );
                            if (time != null) {
                              setModalState(() => tempSelectedStartTime = time);
                            }
                          },
                          child: Text(
                            tempSelectedStartTime == null
                                ? 'Début'
                                : tempSelectedStartTime!.format(context),
                            style: TextStyle(
                              color: tempSelectedStartTime == null ? Colors.grey : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            // Set initial time to start time + 1 hour if start time is selected
                            TimeOfDay initialEndTime;
                            if (tempSelectedStartTime != null) {
                              initialEndTime = TimeOfDay(
                                hour: (tempSelectedStartTime!.hour + 1).clamp(8, 17),
                                minute: tempSelectedStartTime!.minute,
                              );
                            } else {
                              initialEndTime = const TimeOfDay(hour: 9, minute: 0);
                            }

                            final time = await _showRestrictedTimePicker(
                              context,
                              initialTime: tempSelectedEndTime ?? initialEndTime,
                              firstAllowedTime: const TimeOfDay(hour: 8, minute: 0),
                              lastAllowedTime: const TimeOfDay(hour: 17, minute: 0),
                            );
                            if (time != null) {
                              setModalState(() => tempSelectedEndTime = time);
                            }
                          },
                          child: Text(
                            tempSelectedEndTime == null
                                ? 'Fin'
                                : tempSelectedEndTime!.format(context),
                            style: TextStyle(
                              color: tempSelectedEndTime == null ? Colors.grey : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: tempNotesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optionnel)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () async {
                      if (tempSelectedActivityType != null &&
                          tempSelectedStartTime != null &&
                          tempSelectedEndTime != null &&
                          selectedDate != null &&
                          tempSelectedClass != null) {
                        
                        // Validate that end time is after start time
                        final startMinutes = tempSelectedStartTime!.hour * 60 + tempSelectedStartTime!.minute;
                        final endMinutes = tempSelectedEndTime!.hour * 60 + tempSelectedEndTime!.minute;

                        if (endMinutes <= startMinutes) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('L\'heure de fin doit être après l\'heure de début'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        
                        if (activityToEdit != null) {
                          activityToEdit.title = tempSelectedActivityType!;
                          activityToEdit.start = tempSelectedStartTime!;
                          activityToEdit.end = tempSelectedEndTime!;
                          activityToEdit.notes = tempNotesController.text;
                          activityToEdit.date = selectedDate!;
                          activityToEdit.className = tempSelectedClass!;
                          await activityDao.updateActivity(activityToEdit);
                        } else {
                          final newActivity = Activity(
                            id: DateTime.now()
                                .millisecondsSinceEpoch
                                .toString(),
                            className: tempSelectedClass!,
                            date: selectedDate!,
                            title: tempSelectedActivityType!,
                            start: tempSelectedStartTime!,
                            end: tempSelectedEndTime!,
                            notes: tempNotesController.text,
                          );
                          await activityDao.insertActivity(newActivity);
                        }

                        if (mounted) {
                          Navigator.pop(context);
                          setState(() {
                            selectedActivityType = null;
                            selectedStartTime = null;
                            selectedEndTime = null;
                            notesController.clear();
                            selectedActivity = null;
                          });
                          _loadClassesAndActivities();
                        }
                      }
                    },
                    child: Text(activityToEdit != null ? 'Modifier' : 'Ajouter'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
  

  List<Activity> _getActivitiesForDayAndClass(DateTime day) {
    return allActivities.where((activity) {
      return activity.className == selectedClass &&
          activity.date.year == day.year &&
          activity.date.month == day.month &&
          activity.date.day == day.day;
    }).toList()
      ..sort(
        (a, b) =>
            (a.start.hour * 60 + a.start.minute) -
            (b.start.hour * 60 + b.start.minute),
      );
  }

  List<Activity> _getActivitiesForDateAndClass(
      DateTime date, String className) {
    return allActivities.where((activity) {
      return activity.className == className &&
          activity.date.year == date.year &&
          activity.date.month == date.month &&
          activity.date.day == date.day;
    }).toList()
      ..sort(
        (a, b) =>
            (a.start.hour * 60 + a.start.minute) -
            (b.start.hour * 60 + b.start.minute),
      );
  }

  Future<void> _generateAndViewPDF() async {
  try {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Planning du ${DateFormat("EEEE d MMMM yyyy", "fr_FR").format(selectedDate)} - ${selectedClass ?? ""}',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            _buildPDFTable(),
          ];
        },
      ),
    );

    // Get the application documents directory
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    final file = File('$path/planning_${selectedClass}_${DateFormat('yyyy-MM-dd').format(selectedDate)}.pdf');
    
    // Save the PDF to file
    await file.writeAsBytes(await pdf.save());
    
    // Open the PDF file with proper error handling
    final result = await OpenFile.open(file.path);
    
    if (result.type != ResultType.done && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'ouverture du fichier: ${result.message}')),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la génération du PDF: $e')),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    // Show empty state if there are no classes
    if (classes.isEmpty) {
      return MainLayout(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Aucune classe disponible',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Veuillez d\'abord ajouter des enfants avec leurs classes',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return MainLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Activité / Planning',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _addOrEditActivity(),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Ajouter Activité',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27ae60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                
                ElevatedButton.icon(
                  onPressed: _generateAndViewPDF,
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                  label: const Text('Imprimer', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                ElevatedButton.icon(
                  onPressed: selectedActivity != null
                      ? () => _addOrEditActivity(
                            activityToEdit: selectedActivity,
                          )
                      : null,
                  icon: const Icon(Icons.edit, color: Colors.white),
                  label: const Text('Modifier',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedActivity != null
                        ? Colors.orange
                        : Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                ElevatedButton.icon(
                  onPressed: selectedActivity != null
                      ? () async {
                          await activityDao.deleteActivity(
                              selectedActivity!.id);
                          if (mounted) {
                            setState(() {
                              selectedActivity = null;
                            });
                            _loadClassesAndActivities();
                          }
                        }
                      : null,
                  icon: const Icon(Icons.delete, color: Colors.white),
                  label: const Text('Supprimer',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedActivity != null
                        ? Colors.red
                        : Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Day navigation
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Jour précédent',
                  onPressed: () => _changeDate(
                      selectedDate.subtract(const Duration(days: 1))),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null && mounted) _changeDate(picked);
                    },
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: Color(0xFF3B82F6)),
                          const SizedBox(width: 6),
                          Text(
                            _formatDay(selectedDate),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Jour suivant',
                  onPressed: () =>
                      _changeDate(selectedDate.add(const Duration(days: 1))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _buildGrid(),
                      ),
                    ),
                  ),
                ),
                _buildActivityTypesLegend(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Grid constants & helpers ────────────────────────────────────────────

  static const double _hourHeight = 72.0;
  static const double _timeColWidth = 72.0;
  static const double _classColWidth = 180.0;

  double _topForTime(TimeOfDay time) {
    final minutes = (time.hour - startHour.hour) * 60 + time.minute;
    return (minutes / 60.0) * _hourHeight;
  }

  double _heightForDuration(TimeOfDay start, TimeOfDay end) {
    final minutes = (end.hour - start.hour) * 60 + (end.minute - start.minute);
    return (minutes / 60.0) * _hourHeight;
  }

  Widget _buildActivityCard(Activity activity) {
    final color = activityColors[activity.title] ?? const Color(0xFF6366F1);
    final isSelected = selectedActivity?.id == activity.id;
    return GestureDetector(
      onTap: () => setState(() => selectedActivity = activity),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.75) : color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(color: color, width: 4),
            top: isSelected ? BorderSide(color: color, width: 1.5) : BorderSide.none,
            right: isSelected ? BorderSide(color: color, width: 1.5) : BorderSide.none,
            bottom: isSelected ? BorderSide(color: color, width: 1.5) : BorderSide.none,
          ),
        ),
        padding: const EdgeInsets.only(left: 6, right: 6, top: 4, bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              activity.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isSelected ? Colors.white : color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (activity.notes.isNotEmpty)
              Text(
                activity.notes,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected
                      ? Colors.white70
                      : color.withOpacity(0.75),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final int numClasses = classes.length;
        final double colWidth = numClasses > 0
            ? ((constraints.maxWidth - _timeColWidth) / numClasses)
                .clamp(_classColWidth, double.infinity)
            : _classColWidth;

        return Column(
          children: [
            // ── Header row ──────────────────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Container(
                    width: _timeColWidth,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF0F4FF),
                      border: Border(
                        right: BorderSide(color: Color(0xFFD1D5DB), width: 1),
                        bottom: BorderSide(color: Color(0xFFD1D5DB), width: 1),
                      ),
                    ),
                    child: const Text(
                      'Time',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  ...classes.map((cls) => Container(
                        width: colWidth,
                        height: 50,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF0F4FF),
                          border: Border(
                            right: BorderSide(
                                color: Color(0xFFD1D5DB), width: 1),
                            bottom: BorderSide(
                                color: Color(0xFFD1D5DB), width: 1),
                          ),
                        ),
                        child: Text(
                          cls,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF374151),
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                ],
              ),
            ),
            // ── Body ────────────────────────────────────────────────────
            Expanded(
              child: LayoutBuilder(
                builder: (context, bodyConstraints) {
                  final double availableHeight = bodyConstraints.maxHeight;
                  final double dynamicHourHeight = availableHeight > _hourHeight * numberOfRows
                      ? availableHeight / numberOfRows
                      : _hourHeight;
                  final double dynamicTotalHeight = dynamicHourHeight * numberOfRows;

                  return SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Time column
                          Column(
                            children: List.generate(numberOfRows, (i) {
                              final hour = startHour.hour + i;
                              final label = hour < 12
                                  ? '$hour:00 AM'
                                  : hour == 12
                                      ? '12:00 PM'
                                      : '${hour - 12}:00 PM';
                              return Container(
                                width: _timeColWidth,
                                height: dynamicHourHeight,
                                alignment: Alignment.topCenter,
                                padding: const EdgeInsets.only(top: 6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF9FAFB),
                                  border: Border(
                                    right: BorderSide(
                                        color: Color(0xFFE5E7EB), width: 1),
                                    bottom: BorderSide(
                                        color: Color(0xFFE5E7EB), width: 1),
                                  ),
                                ),
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF6B7280),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }),
                          ),
                          // Class columns
                          ...List.generate(classes.length, (idx) {
                            final cls = classes[idx];
                            final activities =
                                _getActivitiesForDateAndClass(selectedDate, cls);
                            final colBg = idx.isEven
                                ? Colors.white
                                : const Color(0xFFF9FAFB);
                        return Container(
                          width: colWidth,
                          height: dynamicTotalHeight,
                          decoration: BoxDecoration(
                            color: colBg,
                            border: const Border(
                              right: BorderSide(
                                  color: Color(0xFFE5E7EB), width: 1),
                            ),
                          ),
                          child: Stack(
                            children: [
                              ...List.generate(
                                  numberOfRows,
                                  (i) => Positioned(
                                        top: i * dynamicHourHeight,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          height: 1,
                                          color: const Color(0xFFE5E7EB),
                                        ),
                                      )),
                              ...activities.map((activity) {
                                final totalMinutes = (activity.start.hour - startHour.hour) * 60 + activity.start.minute;
                                final durationMinutes = (activity.end.hour - activity.start.hour) * 60 + (activity.end.minute - activity.start.minute);
                                double top = (totalMinutes / 60.0) * dynamicHourHeight;
                                double height = (durationMinutes / 60.0) * dynamicHourHeight;
                                top = top.clamp(0.0, dynamicTotalHeight - 24);
                                if (top + height > dynamicTotalHeight)
                                  height = dynamicTotalHeight - top;
                                if (height < 24) height = 24;
                                return Positioned(
                                  top: top,
                                  left: 4,
                                  right: 4,
                                  height: height,
                                  child: _buildActivityCard(activity),
                                );
                              }),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActivityTypesLegend() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text(
            'Activity Types:  ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
              fontSize: 12,
            ),
          ),
          ...activityTypes.map((type) {
            final color = activityColors[type] ?? const Color(0xFF6366F1);
            return Container(
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.35)),
              ),
              child: Text(
                type,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
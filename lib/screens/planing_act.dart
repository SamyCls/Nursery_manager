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
    'Jeux': Colors.blueAccent,
    'Lecture': Colors.greenAccent,
    'Sport': Colors.redAccent,
    'Art': Colors.purpleAccent,
    'Musique': Colors.orangeAccent,
  };

  String? selectedClass;
  DateTime weekStart = _startOfWeek(DateTime.now());
  String? selectedActivityType;
  TimeOfDay? selectedStartTime;
  TimeOfDay? selectedEndTime;
  final TextEditingController notesController = TextEditingController();
  Activity? selectedActivity;

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
    final weekDays = getWeekDays(weekStart);
    
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 1),
      children: [
        // Header row with days
        pw.TableRow(
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Heure', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            ...weekDays.map((day) {
              return pw.Container(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Column(
                  children: [
                    pw.Text(
                      DateFormat.EEEE('fr_FR').format(day),
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      DateFormat('dd/MM', 'fr_FR').format(day),
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
        
        // Time slots rows
        ...List.generate(numberOfRows, (index) {
          final hour = startHour.hour + index;
          final timeText = '$hour:00';
          
          return pw.TableRow(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(timeText, style: const pw.TextStyle(fontSize: 10)),
              ),
              ...weekDays.map((day) {
                final dayActivities = _getActivitiesForDayAndClass(day);
                final activitiesForThisHour = dayActivities.where((activity) {
                  return activity.start.hour == hour;
                }).toList();
                
                if (activitiesForThisHour.isEmpty) {
                  return pw.Container(
                    padding: const pw.EdgeInsets.all(4),
                    height: 30,
                    child: pw.Text(''),
                  );
                }
                
                // Get the activity color
                final activity = activitiesForThisHour.first;
                final color = activityColors[activity.title] ?? Colors.grey;
                final pdfColor = PdfColor.fromInt(color.value);
                
                return pw.Container(
                  height: 30,
                  decoration: pw.BoxDecoration(
                    color: pdfColor,
                    border: pw.TableBorder(
                      left: const pw.BorderSide(width: 1, color: PdfColors.black),
                      right: const pw.BorderSide(width: 1, color: PdfColors.black),
                      top: index == 0 
                          ? const pw.BorderSide(width: 1, color: PdfColors.black)
                          :  const pw.BorderSide(width: 0, color: PdfColors.white),
                      bottom: const pw.BorderSide(width: 1, color: PdfColors.black),
                    ),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      activity.title,
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.white),
                    ),
                  ),
                );
              }),
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

  String _formatWeekRange(DateTime start) {
    final end = start.add(const Duration(days: 6));
    final df = DateFormat('dd MMM yyyy', 'fr_FR');
    return '${df.format(start)} - ${df.format(end)}';
  }

  void _changeWeek(DateTime newDate) {
    setState(() {
      weekStart = _startOfWeek(newDate);
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
                'Planning Hebdomadaire - ${selectedClass ?? ''}',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            
            pw.Text(
              _formatWeekRange(weekStart),
              style: const pw.TextStyle(fontSize: 14),
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
    final file = File('$path/weekly_planner_${selectedClass}_${weekStart.millisecondsSinceEpoch}.pdf');
    
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

                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: weekStart,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null && mounted) _changeWeek(picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1e73be),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month,
                              color: Colors.black54),
                          const SizedBox(width: 8),
                          Text(
                            _formatWeekRange(weekStart),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.arrow_drop_down,
                              color: Colors.black54),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3E8FB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: selectedClass,
                    underline: const SizedBox(),
                    onChanged: (v) {
                      setState(() {
                        selectedClass = v!;
                        selectedActivity = null;
                      });
                    },
                    items: classes
                        .map(
                          (c) => DropdownMenuItem(value: c, child: Text(c)),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth;
                  cellWidth = availableWidth / 7;
                  
                  final availableHeight = constraints.maxHeight;
                  final calculatedCellHeight = availableHeight - 40;
                  
                  return Column(
                    children: [
                      Row(
                        children: getWeekDays(weekStart).map((d) {
                          return Container(
                            width: cellWidth,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1e73be),
                              border: Border.all(
                                color: Colors.white,
                                width: 0.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  DateFormat.EEEE('fr_FR').format(d),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  DateFormat('dd MMM', 'fr_FR').format(d),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                      Expanded(
                        child: SingleChildScrollView(
                          child: SizedBox(
                            height: calculatedCellHeight,
                            child: Row(
                              children: getWeekDays(weekStart).map((day) {
                                final dayActivities =
                                    _getActivitiesForDayAndClass(day);
                                return Container(
                                  width: cellWidth,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFe9f2fb),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      ...List.generate(numberOfRows, (index) {
                                        final hour = startHour.hour + index;
                                        return Positioned(
                                          top: (index / numberOfRows) * calculatedCellHeight,
                                          left: 0,
                                          right: 0,
                                          child: Row(
                                            children: [
                                              SizedBox(
                                                width: 30,
                                                child: Text(
                                                  '$hour:00',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Container(
                                                  height: 1,
                                                  color: Colors.grey.withOpacity(0.3),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),

                                      ...dayActivities.map((activity) {
                                        final top = _calculateTopOffsetForHeight(
                                            activity.start, calculatedCellHeight);
                                        final height = _calculateHeightForHeight(
                                          activity.start,
                                          activity.end,
                                          calculatedCellHeight,
                                        );
                                        final color =
                                            activityColors[activity.title] ??
                                                Colors.grey;

                                        return Positioned(
                                          top: top,
                                          left: 4,
                                          right: 4,
                                          height: height,
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                selectedActivity = activity;
                                              });
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: selectedActivity?.id ==
                                                        activity.id
                                                    ? Colors.black26
                                                    : color,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              padding: const EdgeInsets.all(4),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    activity.title,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${activity.start.format(context)} - ${activity.end.format(context)}',
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                  if (activity.notes.isNotEmpty)
                                                    Text(
                                                      activity.notes,
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTopOffsetForHeight(TimeOfDay time, double containerHeight) {
    final totalMinutes =
        (time.hour - startHour.hour) * 60 + (time.minute - startHour.minute);
    return (totalMinutes / 60) * (containerHeight / numberOfRows);
  }

  double _calculateHeightForHeight(TimeOfDay start, TimeOfDay end, double containerHeight) {
    final durationMinutes =
        (end.hour - start.hour) * 60 + (end.minute - start.minute);
    return (durationMinutes / 60) * (containerHeight / numberOfRows);
  }
}
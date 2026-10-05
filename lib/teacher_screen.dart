import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'api_service.dart';
import 'csv_helper.dart';

class TeacherScreen extends StatefulWidget {
  const TeacherScreen({super.key});

  @override
  State<TeacherScreen> createState() => _TeacherScreenState();
}

class _TeacherScreenState extends State<TeacherScreen> {
  List<dynamic> _courses = [];
  String? _selectedCourse;
  DateTime _selectedDate = DateTime.now();
  List<dynamic> _studentsData = [];
  bool _loading = true;

  final Map<String, String> _statusMap = {};
  final Map<String, TextEditingController> _marksMap = {};

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    try {
      final courses = await ApiService.fetchCourses();
      setState(() {
        _courses = courses;
        if (courses.isNotEmpty) _selectedCourse = courses[0]['code'];
      });
      if (_selectedCourse != null) await _loadAttendanceSheet();
    } catch (e) {
      _showSnackbar("Connection error. Ensure Node.js server is running.");
    }
  }

  Future<void> _loadAttendanceSheet() async {
    setState(() => _loading = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    try {
      final data = await ApiService.fetchAttendance(_selectedCourse!, dateStr);
      setState(() {
        _studentsData = data;
        for (var item in data) {
          final roll = item['roll'];
          _statusMap[roll] = item['status'] ?? 'Absent';
          _marksMap[roll] = TextEditingController(text: (item['marks'] ?? 0.0).toString());
        }
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showSnackbar("Failed to fetch attendance data.");
    }
  }

  Future<void> _saveData() async {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final records = _studentsData.map((s) {
      final roll = s['roll'];
      return {
        'roll': roll,
        'status': _statusMap[roll] ?? 'Absent',
        'marks': double.tryParse(_marksMap[roll]?.text ?? '0.0') ?? 0.0,
      };
    }).toList();

    final success = await ApiService.saveAttendance(_selectedCourse!, dateStr, records);
    _showSnackbar(success ? "Attendance saved to database!" : "Error saving attendance.");
  }

  Future<void> _exportCSV() async {
    try {
      final data = await ApiService.fetchCourseReport(_selectedCourse!);
      List<List<dynamic>> rows = [
        ["Roll", "Name", "Total Classes", "Present", "Absent", "Attendance %", "Exam Eligibility", "Avg Marks"]
      ];

      for (var r in data) {
        final total = r['total_classes'] ?? 0;
        final present = r['present_count'] ?? 0;
        final absent = r['absent_count'] ?? 0;
        final pct = total > 0 ? (present / total) * 100 : 0.0;
        rows.add([
          r['roll'],
          r['name'],
          total,
          present,
          absent,
          "${pct.toStringAsFixed(1)}%",
          pct >= 50.0 ? "Eligible" : "Barred (<50%)",
          (r['avg_marks'] ?? 0.0).toStringAsFixed(1)
        ]);
      }

      final csvStr = const ListToCsvConverter().convert(rows);
      final filename = "${_selectedCourse!.replaceAll(' ', '_')}_Report.csv";
      downloadCsvFile(csvStr, filename);
      _showSnackbar("CSV Export triggered: $filename");
    } catch (e) {
      _showSnackbar("Failed to generate CSV.");
    }
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Teacher Portal"),
        actions: [
          IconButton(icon: const Icon(Icons.file_download), tooltip: "Export CSV", onPressed: _exportCSV),
          IconButton(icon: const Icon(Icons.save), tooltip: "Save Records", onPressed: _saveData),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Material(
                  elevation: 2,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedCourse,
                              items: _courses.map((c) {
                                return DropdownMenuItem<String>(
                                  value: c['code'],
                                  child: Text("${c['code']} - ${c['title']}", overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedCourse = val);
                                  _loadAttendanceSheet();
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonalIcon(
                          icon: const Icon(Icons.calendar_month, size: 18),
                          label: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                          onPressed: () async {
                            final pick = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2025),
                              lastDate: DateTime(2030),
                            );
                            if (pick != null && pick != _selectedDate) {
                              setState(() => _selectedDate = pick);
                              _loadAttendanceSheet();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: _studentsData.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final s = _studentsData[i];
                      final roll = s['roll'];
                      final isPresent = _statusMap[roll] == 'Present';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isPresent ? Colors.green.shade100 : Colors.red.shade100,
                          child: Text(
                            roll.substring(roll.length - 2),
                            style: TextStyle(
                              color: isPresent ? Colors.green.shade900 : Colors.red.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text("${s['name']} ($roll)"),
                        subtitle: Row(
                          children: [
                            const Text("Daily Marks: "),
                            SizedBox(
                              width: 60,
                              height: 32,
                              child: TextField(
                                controller: _marksMap[roll],
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: FilterChip(
                          label: Text(isPresent ? "Present" : "Absent"),
                          selected: isPresent,
                          selectedColor: Colors.green.shade200,
                          onSelected: (selected) {
                            setState(() {
                              _statusMap[roll] = selected ? 'Present' : 'Absent';
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
import 'package:flutter/material.dart';
import 'api_service.dart';

class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  final TextEditingController _rollController = TextEditingController(text: "2103001");
  List<dynamic> _reports = [];
  bool _searched = false;
  bool _loading = false;

  Future<void> _search() async {
    final roll = _rollController.text.trim();
    if (roll.isEmpty) return;

    setState(() => _loading = true);
    try {
      final res = await ApiService.fetchStudentSummary(roll);
      setState(() {
        _reports = res;
        _searched = true;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error fetching records for roll.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student Examination Clearance")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _rollController,
                    decoration: const InputDecoration(
                      labelText: "Enter RUET Roll",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _search,
                  child: const Text("Check"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading) const CircularProgressIndicator(),
            if (!_loading && _searched && _reports.isEmpty)
              const Text("No records recorded yet."),
            if (!_loading && _reports.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _reports.length,
                  itemBuilder: (context, i) {
                    final item = _reports[i];
                    final double pct = (item['percentage'] as num?)?.toDouble() ?? 0.0;
                    final bool isEligible = item['is_eligible'] ?? false;

                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text("${item['code']} - ${item['title']}"),
                        subtitle: Text(
                          "Attended: ${item['attended_classes']}/${item['total_classes']} sessions | Marks Avg: ${(item['avg_marks'] ?? 0.0).toStringAsFixed(1)}",
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "${pct.toStringAsFixed(1)}%",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isEligible ? Colors.green : Colors.red,
                              ),
                            ),
                            Text(
                              isEligible ? "ELIGIBLE" : "BARRED (<50%)",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isEligible ? Colors.green.shade800 : Colors.red.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
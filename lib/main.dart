import 'package:flutter/material.dart';
import '../teacher_screen.dart';
import '../student_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RuetAttendanceApp());
}

class RuetAttendanceApp extends StatelessWidget {
  const RuetAttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RUET Attendance System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      home: const DashboardHome(),
    );
  }
}

class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("CSE 2100 - RUET"), centerTitle: true),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school, size: 72, color: Colors.indigo),
              const SizedBox(height: 12),
              const Text(
                "Course Attendance & Evaluation",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                icon: const Icon(Icons.assignment_ind),
                label: const Text("Teacher Portal (Roll Call & Marks)"),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TeacherScreen()),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                icon: const Icon(Icons.person_search),
                label: const Text("Student Portal (Check Eligibility)"),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StudentScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
# RUET Course Attendance & Continuous Evaluation System

A full-stack, cross-platform academic evaluation and attendance tracking system built for the CSE 2nd-year curriculum at Rajshahi University of Engineering & Technology (RUET) for CSE 2100.

## 📌 Features
- **Teacher Portal:** 
  - Date-specific digital roll call with instant visual feedback.
  - Continuous evaluation marks entry.
  - High-performance batch database persistence via SQLite transactions.
  - RFC-4180-compliant CSV course attendance report generator.
- **Student Portal:** 
  - Real-time roll lookup.
  - Automatic calculation for the institutional **50% Examination Eligibility** cutoff.
  - Clear visual status badges (`ELIGIBLE` vs `BARRED (< 50%)`).

## 🛠 Tech Stack
- **Frontend:** Flutter (Dart) — Material 3 UI (Web & Android)
- **Backend:** Node.js, Express.js (RESTful JSON APIs)
- **Database:** SQLite3 (`attendance.db`)

## 🚀 Getting Started

### 1. Run Backend Server
```bash
cd ruet_attendance_backend
npm install
node server.js
```
The server will start on http://localhost:5000.

2. Run Flutter Client
flutter pub get
flutter run -d chrome    # For Web

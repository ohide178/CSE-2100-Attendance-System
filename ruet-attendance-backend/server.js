const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const cors = require('cors');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());

// Initialize SQLite database
const dbPath = path.resolve(__dirname, 'attendance.db');
const db = new sqlite3.Database(dbPath, (err) => {
  if (err) console.error('Database connection error:', err.message);
  else console.log('Connected to SQLite database at:', dbPath);
});

// Database Initialization & Seeding
db.serialize(() => {
  db.run(`CREATE TABLE IF NOT EXISTS courses (
    code TEXT PRIMARY KEY,
    title TEXT NOT NULL
  )`);

  db.run(`CREATE TABLE IF NOT EXISTS students (
    roll TEXT PRIMARY KEY,
    name TEXT NOT NULL
  )`);

  db.run(`CREATE TABLE IF NOT EXISTS attendance (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    course_code TEXT NOT NULL,
    roll TEXT NOT NULL,
    date TEXT NOT NULL,
    status TEXT NOT NULL,
    marks REAL DEFAULT 0.0,
    FOREIGN KEY (course_code) REFERENCES courses(code),
    FOREIGN KEY (roll) REFERENCES students(roll),
    UNIQUE(course_code, roll, date)
  )`);

  const courses = [
    { code: 'HUM 2113', title: 'Economics, Government and Sociology' },
    { code: 'CSE 2101', title: 'Discreet Mathematics' },
    { code: 'CSE 2103', title: 'Digital Logic Design' },
    { code: 'EEE 2151', title: 'Electrical Machine Drives and Instrumentations' },
    { code: 'MATH 2113', title: 'Matrix & Linear Algebra' }
  ];

  const courseStmt = db.prepare(`INSERT OR IGNORE INTO courses (code, title) VALUES (?, ?)`);
  courses.forEach(c => courseStmt.run(c.code, c.title));
  courseStmt.finalize();

  const names = [
    "Tanvir Ahmed", "Sadia Islam", "Sabbir Hossain", "Nusrat Jahan", "Arifur Rahman",
    "Farhana Akter", "Rakibul Hasan", "Mahmudul Hasan", "Mehedi Hasan", "Anika Tabassum",
    "Tamim Iqbal", "Sumaiya Rahman", "Sajib Chandra", "Shakil Ahmed", "Tasnim Sultana",
    "Rayhan Kabir", "Fahmida Yeasmin", "Ashraful Alam", "Nahid Hasan", "Ishrat Jahan",
    "Aftab Uddin", "Sharmin Sultana", "Jubayer Hossain", "Ishtiak Ahmed", "Humaira Khan",
    "Shahriar Kabir", "Rifat Hossain", "Mst. Jannatul Ferdous", "Nazmul Huda", "Sabrina Akter",
    "Tariqul Islam", "Kazi Arafat", "Maliha Tasnim", "Sayed Al-Amin", "Fariha Hossain",
    "Muntasir Billah", "Towhidul Islam", "Pritom Das", "Subrata Paul", "Samia Rahman",
    "Zubair Ahmed", "Dipu Chandra", "Rumana Akter", "Imran Nazir", "Shanto Roy",
    "Shariful Islam", "Sanjida Akter", "Asif Mahmud", "Bishwajit Roy", "Munira Khatun",
    "Hasanul Banna", "Shahadat Hossain", "Rezaul Karim", "Mustafizur Rahman", "Farzana Yeasmin",
    "Zannatun Nayem", "Abir Hasan", "Afsana Mimi", "Sourav Kundu", "Tanushree Ghosh"
  ];

  const studentStmt = db.prepare(`INSERT OR IGNORE INTO students (roll, name) VALUES (?, ?)`);
  names.forEach((name, i) => {
    const roll = (2103001 + i).toString();
    studentStmt.run(roll, name);
  });
  studentStmt.finalize();
});

// --- RESTful API Routes ---

// 1. Get all courses
app.get('/api/courses', (req, res) => {
  db.all('SELECT * FROM courses', [], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(rows);
  });
});

// 2. Get all students
app.get('/api/students', (req, res) => {
  db.all('SELECT * FROM students ORDER BY roll ASC', [], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(rows);
  });
});

// 3. Get attendance sheet for specific course and date
app.get('/api/attendance', (req, res) => {
  const { course_code, date } = req.query;
  if (!course_code || !date) {
    return res.status(400).json({ error: 'course_code and date are required query parameters' });
  }

  const query = `
    SELECT s.roll, s.name, 
           COALESCE(a.status, 'Absent') AS status, 
           COALESCE(a.marks, 0.0) AS marks
    FROM students s
    LEFT JOIN attendance a 
      ON s.roll = a.roll AND a.course_code = ? AND a.date = ?
    ORDER BY s.roll ASC
  `;
  db.all(query, [course_code, date], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(rows);
  });
});

// 4. Batch save/update attendance & marks for a given date
app.post('/api/attendance', (req, res) => {
  const { course_code, date, records } = req.body;
  if (!course_code || !date || !Array.isArray(records)) {
    return res.status(400).json({ error: 'Invalid payload structure' });
  }

  const sql = `
    INSERT INTO attendance (course_code, roll, date, status, marks)
    VALUES (?, ?, ?, ?, ?)
    ON CONFLICT(course_code, roll, date) 
    DO UPDATE SET status = excluded.status, marks = excluded.marks
  `;

  db.serialize(() => {
    db.run('BEGIN TRANSACTION');
    const stmt = db.prepare(sql);
    for (const r of records) {
      stmt.run(course_code, r.roll, date, r.status, r.marks || 0.0);
    }
    stmt.finalize();
    db.run('COMMIT', (err) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ message: 'Attendance records saved successfully' });
    });
  });
});

// 5. Student summary (Check 50% Exam Eligibility)
app.get('/api/student/:roll/summary', (req, res) => {
  const { roll } = req.params;
  const sql = `
    SELECT 
      c.code, 
      c.title,
      COUNT(a.id) AS total_classes,
      SUM(CASE WHEN a.status = 'Present' THEN 1 ELSE 0 END) AS attended_classes,
      AVG(a.marks) AS avg_marks
    FROM courses c
    LEFT JOIN attendance a ON c.code = a.course_code AND a.roll = ?
    GROUP BY c.code, c.title
  `;

  db.all(sql, [roll], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    const formatted = rows.map(r => {
      const total = r.total_classes || 0;
      const attended = r.attended_classes || 0;
      const percentage = total > 0 ? (attended / total) * 100 : 0.0;
      return {
        ...r,
        percentage: Number(percentage.toFixed(2)),
        is_eligible: percentage >= 50.0
      };
    });
    res.json(formatted);
  });
});

// 6. Course-wide aggregated report for CSV export
app.get('/api/course/:course_code/report', (req, res) => {
  const { course_code } = req.params;
  const sql = `
    SELECT 
      s.roll,
      s.name,
      COUNT(a.id) AS total_classes,
      SUM(CASE WHEN a.status = 'Present' THEN 1 ELSE 0 END) AS present_count,
      SUM(CASE WHEN a.status = 'Absent' THEN 1 ELSE 0 END) AS absent_count,
      AVG(a.marks) AS avg_marks
    FROM students s
    LEFT JOIN attendance a ON s.roll = a.roll AND a.course_code = ?
    GROUP BY s.roll, s.name
    ORDER BY s.roll ASC
  `;

  db.all(sql, [course_code], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(rows);
  });
});

app.listen(PORT, () => {
  console.log(`RUET Attendance Backend running at http://localhost:${PORT}`);
});
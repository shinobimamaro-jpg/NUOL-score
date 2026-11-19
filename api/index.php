<?php
// NUOL Scores JSON API (PHP + MySQL via PDO). Same-origin only, session cookie auth.
$cfg = require __DIR__ . '/config.php';
header('Content-Type: application/json; charset=utf-8');
header('X-Content-Type-Options: nosniff');
header('Cache-Control: no-store');
session_set_cookie_params(['lifetime' => 0, 'path' => '/', 'httponly' => true, 'samesite' => 'Lax']);
session_start();

function out($d, $code = 200) { http_response_code($code); echo json_encode($d, JSON_UNESCAPED_UNICODE); exit; }
function mlen($s) { return function_exists('mb_strlen') ? mb_strlen($s) : (int)preg_match_all('/./us', $s); }
function msub($s, $n) { return function_exists('mb_substr') ? mb_substr($s, 0, $n) : implode('', array_slice(preg_split('//u', $s, -1, PREG_SPLIT_NO_EMPTY), 0, $n)); }
function fail($m, $code = 400) { out(['ok' => false, 'error' => $m], $code); }

try {
    $pdo = new PDO("mysql:host={$cfg['host']};port={$cfg['port']};dbname={$cfg['name']};charset=utf8mb4", $cfg['user'], $cfg['pass'], [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ]);
} catch (Throwable $e) {
    fail('Cannot connect to the database. Start MySQL in XAMPP and import database.sql.', 503);
}

$action = $_GET['action'] ?? '';
$in = [];
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (stripos($_SERVER['CONTENT_TYPE'] ?? '', 'application/json') !== 0) fail('Unsupported request.', 415);
    $in = json_decode(file_get_contents('php://input'), true);
    if (!is_array($in)) fail('Bad JSON.');
}

function current_user($pdo) {
    if (empty($_SESSION['uid'])) return null;
    $st = $pdo->prepare("SELECT u.user_id, u.username, u.role, u.student_id,
        COALESCE(NULLIF(p.display_name,''), NULLIF(TRIM(CONCAT(s.first_name,' ',s.last_name)),''), u.username) AS name
        FROM users u LEFT JOIN user_profiles p ON p.user_id=u.user_id LEFT JOIN students s ON s.student_id=u.student_id WHERE u.user_id=?");
    $st->execute([$_SESSION['uid']]);
    $r = $st->fetch();
    if (!$r) { unset($_SESSION['uid']); return null; }
    return ['user' => $r['username'], 'name' => $r['name'], 'role' => $r['role'], 'sid' => $r['student_id']];
}
function need_login($pdo) { $u = current_user($pdo); if (!$u) fail('Please sign in.', 401); return $u; }
function need_admin($pdo) { $u = need_login($pdo); if ($u['role'] !== 'admin') fail('Admin only.', 403); return $u; }

function students($pdo, $only = null) {
    $w = $only !== null ? ' WHERE s.student_id=?' : '';
    $st = $pdo->prepare("SELECT s.student_id, s.first_name, s.last_name, s.gender, s.phone, s.email, m.name_en AS major, COALESCE(t.study_type,'normal') AS type
        FROM students s LEFT JOIN majors m ON m.major_id=s.major_id LEFT JOIN student_study_type t ON t.student_id=s.student_id$w ORDER BY s.student_id");
    $st->execute($only !== null ? [$only] : []);
    $rows = $st->fetchAll();
    $c = $pdo->prepare('SELECT student_id, month_no, credits FROM monthly_credits' . ($only !== null ? ' WHERE student_id=?' : ''));
    $c->execute($only !== null ? [$only] : []);
    $cr = [];
    foreach ($c->fetchAll() as $r) { $cr[$r['student_id']][(int)$r['month_no']] = (int)$r['credits']; }
    $res = [];
    foreach ($rows as $r) {
        $id = $r['student_id'];
        $arr = [];
        for ($m = 1; $m <= 10; $m++) $arr[] = $cr[$id][$m] ?? null;
        $res[] = ['id' => $id, 'name' => trim($r['first_name'] . ' ' . $r['last_name']), 'g' => $r['gender'], 'major' => $r['major'] ?? '',
                  'phone' => $r['phone'], 'email' => $r['email'], 'type' => $r['type'], 'cr' => $arr];
    }
    return $res;
}
function list_for($pdo, $u) { return $u['role'] === 'admin' ? students($pdo) : ($u['sid'] ? students($pdo, $u['sid']) : []); }

try {
    switch ($action) {
    case 'ping':
        $u = current_user($pdo);
        out(['ok' => true, 'user' => $u, 'students' => $u ? list_for($pdo, $u) : []]);

    case 'login':
        $name = trim((string)($in['username'] ?? '')); $pw = (string)($in['password'] ?? '');
        $st = $pdo->prepare('SELECT user_id, password_hash FROM users WHERE username=?');
        $st->execute([$name]);
        $r = $st->fetch();
        if (!$r || !password_verify($pw, $r['password_hash'])) { usleep(400000); fail('Invalid name or password.', 401); }
        session_regenerate_id(true);
        $_SESSION['uid'] = (int)$r['user_id'];
        $u = current_user($pdo);
        out(['ok' => true, 'user' => $u, 'students' => list_for($pdo, $u)]);

    case 'logout':
        $_SESSION = [];
        session_destroy();
        out(['ok' => true]);

    case 'signup':
        $name = trim((string)($in['name'] ?? '')); $un = trim((string)($in['username'] ?? '')); $sid = trim((string)($in['student_id'] ?? ''));
        $pw = (string)($in['password'] ?? ''); $cf = (string)($in['confirm'] ?? '');
        if ($name === '' || mlen($name) > 100) fail('Enter your full name (up to 100 characters).');
        if (!preg_match('/^[A-Za-z0-9][A-Za-z0-9 _.-]{2,29}$/', $un)) fail('Username needs 3 to 30 letters, numbers, spaces, dots, dashes or underscores.');
        if (strlen($pw) < 8 || strlen($pw) > 72) fail('Password needs 8 to 72 characters.');
        if ($pw !== $cf) fail('The passwords don’t match.');
        $q = $pdo->prepare('SELECT 1 FROM students WHERE student_id=?'); $q->execute([$sid]);
        if (!$q->fetch()) fail('We couldn’t find that student ID.');
        $q = $pdo->prepare('SELECT 1 FROM users WHERE student_id=?'); $q->execute([$sid]);
        if ($q->fetch()) fail('That student ID already has an account.');
        $q = $pdo->prepare('SELECT 1 FROM users WHERE username=?'); $q->execute([$un]);
        if ($q->fetch()) fail('That username is already taken.');
        $pdo->beginTransaction();
        $pdo->prepare("INSERT INTO users(username,password_hash,role,student_id) VALUES(?,?,'student',?)")->execute([$un, password_hash($pw, PASSWORD_DEFAULT), $sid]);
        $pdo->prepare('INSERT INTO user_profiles(user_id,display_name) VALUES(?,?)')->execute([$pdo->lastInsertId(), $name]);
        $pdo->commit();
        out(['ok' => true]);

    case 'students':
        $u = need_login($pdo);
        out(['ok' => true, 'students' => list_for($pdo, $u)]);

    case 'student_save':
        need_admin($pdo);
        $s = $in['student'] ?? []; $new = !empty($in['is_new']);
        $id = trim((string)($s['id'] ?? '')); $nm = trim((string)($s['name'] ?? ''));
        if (!preg_match('/^[A-Za-z0-9_-]{3,20}$/', $id)) fail('Student ID needs 3 to 20 letters, numbers, - or _.');
        if ($nm === '' || mlen($nm) > 100) fail('Enter the student name.');
        $g = ($s['g'] ?? 'M') === 'F' ? 'F' : 'M';
        $type = in_array($s['type'] ?? '', ['good', 'normal', 'lazy', 'bad'], true) ? $s['type'] : 'normal';
        $major = trim((string)($s['major'] ?? '')); if ($major === '') $major = 'Computer Science'; $major = msub($major, 60);
        $phone = msub(trim((string)($s['phone'] ?? '')), 20);
        $email = trim((string)($s['email'] ?? '')); if ($email !== '' && (strlen($email) > 150 || !filter_var($email, FILTER_VALIDATE_EMAIL))) fail('Email is not valid.');
        $cr = is_array($s['cr'] ?? null) ? $s['cr'] : [];
        $parts = preg_split('/\s+/', $nm, 2); $first = $parts[0]; $last = $parts[1] ?? '';
        $pdo->beginTransaction();
        $q = $pdo->prepare('SELECT major_id FROM majors WHERE name_en=?'); $q->execute([$major]);
        $mid = $q->fetchColumn();
        if (!$mid) {
            $f = $pdo->query('SELECT MIN(faculty_id) FROM faculties')->fetchColumn();
            if (!$f) { $pdo->rollBack(); fail('Add a faculty first.'); }
            $pdo->prepare('INSERT INTO majors(faculty_id,name_lao,name_en) VALUES(?,?,?)')->execute([$f, $major, $major]);
            $mid = $pdo->lastInsertId();
        }
        $q = $pdo->prepare('SELECT 1 FROM students WHERE student_id=?'); $q->execute([$id]);
        $exists = (bool)$q->fetch();
        if ($new && $exists) { $pdo->rollBack(); fail('That student ID already exists.'); }
        if (!$new && !$exists) { $pdo->rollBack(); fail('Student not found.', 404); }
        if ($new) $pdo->prepare('INSERT INTO students(student_id,first_name,last_name,gender,major_id,phone,email) VALUES(?,?,?,?,?,?,?)')->execute([$id, $first, $last, $g, $mid, $phone, $email]);
        else $pdo->prepare('UPDATE students SET first_name=?,last_name=?,gender=?,major_id=?,phone=?,email=? WHERE student_id=?')->execute([$first, $last, $g, $mid, $phone, $email, $id]);
        $pdo->prepare('INSERT INTO student_study_type(student_id,study_type) VALUES(?,?) ON DUPLICATE KEY UPDATE study_type=VALUES(study_type)')->execute([$id, $type]);
        $pdo->prepare('DELETE FROM monthly_credits WHERE student_id=?')->execute([$id]);
        $ins = $pdo->prepare('INSERT INTO monthly_credits(student_id,month_no,credits) VALUES(?,?,?)');
        for ($m = 0; $m < 10; $m++) {
            if (isset($cr[$m]) && $cr[$m] !== null && $cr[$m] !== '') $ins->execute([$id, $m + 1, max(0, min(4, (int)$cr[$m]))]);
        }
        $pdo->commit();
        out(['ok' => true, 'students' => students($pdo)]);

    case 'student_delete':
        need_admin($pdo);
        $pdo->prepare('DELETE FROM students WHERE student_id=?')->execute([(string)($in['id'] ?? '')]);
        out(['ok' => true, 'students' => students($pdo)]);

    case 'change_password':
        $u = need_login($pdo);
        $cur = (string)($in['current'] ?? ''); $new = (string)($in['new'] ?? ''); $cf = (string)($in['confirm'] ?? '');
        $q = $pdo->prepare('SELECT password_hash FROM users WHERE user_id=?'); $q->execute([$_SESSION['uid']]);
        if (!password_verify($cur, (string)$q->fetchColumn())) fail('Your current password isn’t right.');
        if (strlen($new) < 8 || strlen($new) > 72) fail('New password needs 8 to 72 characters.');
        if ($new !== $cf) fail('The new passwords don’t match.');
        $pdo->prepare('UPDATE users SET password_hash=? WHERE user_id=?')->execute([password_hash($new, PASSWORD_DEFAULT), $_SESSION['uid']]);
        out(['ok' => true]);

    default:
        fail('Unknown action.', 404);
    }
} catch (Throwable $e) {
    if ($pdo->inTransaction()) $pdo->rollBack();
    error_log('NUOL API: ' . $e->getMessage());
    fail('Server error.', 500);
}

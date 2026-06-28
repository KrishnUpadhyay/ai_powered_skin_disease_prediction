import sqlite3
import os
import hashlib

DATABASE_PATH = os.path.join(os.path.dirname(__file__), 'diary.db')

def get_db_connection():
    conn = sqlite3.connect(DATABASE_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def hash_password(password):
    return hashlib.sha256(password.encode()).hexdigest()

def init_db():
    print(f"Initializing database at: {DATABASE_PATH}")
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # 1. Create users table with phone_number
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            password TEXT NOT NULL,
            phone_number TEXT UNIQUE
        )
    ''')
    
    # 2. Create diary table with treatment tracking
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS diary (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL DEFAULT 1,
            disease TEXT NOT NULL,
            confidence REAL NOT NULL,
            severity TEXT NOT NULL,
            date TEXT NOT NULL,
            image_base64 TEXT NOT NULL,
            treatment_notes TEXT,
            treatment_progress INTEGER DEFAULT 0,
            home_remedies TEXT,
            FOREIGN KEY(user_id) REFERENCES users(id)
        )
    ''')
    
    # 3. Dynamic migrations to add columns safely to existing databases
    try:
        cursor.execute("ALTER TABLE users ADD COLUMN phone_number TEXT")
        print("Migration: Added phone_number to users table.")
    except sqlite3.OperationalError:
        pass

    try:
        cursor.execute("CREATE UNIQUE INDEX IF NOT EXISTS idx_users_phone ON users(phone_number)")
        print("Migration: Created unique index on users phone_number.")
    except sqlite3.OperationalError:
        pass

    try:
        cursor.execute("ALTER TABLE diary ADD COLUMN user_id INTEGER NOT NULL DEFAULT 1")
    except sqlite3.OperationalError:
        pass

    try:
        cursor.execute("ALTER TABLE diary ADD COLUMN treatment_notes TEXT")
        print("Migration: Added treatment_notes to diary table.")
    except sqlite3.OperationalError:
        pass

    try:
        cursor.execute("ALTER TABLE diary ADD COLUMN treatment_progress INTEGER DEFAULT 0")
        print("Migration: Added treatment_progress to diary table.")
    except sqlite3.OperationalError:
        pass

    try:
        cursor.execute("ALTER TABLE diary ADD COLUMN home_remedies TEXT")
        print("Migration: Added home_remedies to diary table.")
    except sqlite3.OperationalError:
        pass

    # Create symptom_logs table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS symptom_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL DEFAULT 1,
            date TEXT NOT NULL,
            itchiness INTEGER NOT NULL,
            redness INTEGER NOT NULL,
            hydration INTEGER NOT NULL,
            FOREIGN KEY(user_id) REFERENCES users(id)
        )
    ''')

    conn.commit()
    conn.close()
    print("Database initializations and migrations completed successfully.")

def create_user(name, email, password, phone_number=None):
    conn = get_db_connection()
    cursor = conn.cursor()
    hashed = hash_password(password)
    phone = phone_number.strip() if phone_number else None
    try:
        cursor.execute('''
            INSERT INTO users (name, email, password, phone_number)
            VALUES (?, ?, ?, ?)
        ''', (name, email.lower().strip(), hashed, phone))
        conn.commit()
        new_id = cursor.lastrowid
        conn.close()
        return {'id': new_id, 'name': name, 'email': email, 'phone_number': phone}
    except sqlite3.IntegrityError:
        conn.close()
        return None # Email or Phone already exists

def verify_credentials(email, password):
    conn = get_db_connection()
    cursor = conn.cursor()
    hashed = hash_password(password)
    cursor.execute('''
        SELECT id, name, email, phone_number FROM users
        WHERE email = ? AND password = ?
    ''', (email.lower().strip(), hashed))
    row = cursor.fetchone()
    conn.close()
    if row:
        return {'id': row['id'], 'name': row['name'], 'email': row['email'], 'phone_number': row['phone_number']}
    return None

def verify_phone_user(phone_number):
    """
    Finds a user by phone number. If they do not exist, they are registered
    automatically under OTP-verification flow (common industry pattern).
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    phone = phone_number.strip()
    cursor.execute('''
        SELECT id, name, email, phone_number FROM users
        WHERE phone_number = ?
    ''', (phone,))
    row = cursor.fetchone()
    
    if row:
        conn.close()
        return {'id': row['id'], 'name': row['name'], 'email': row['email'], 'phone_number': row['phone_number']}
    else:
        # Create a new user automatically
        import random
        rand_id = random.randint(1000, 9999)
        name = f"User {phone[-4:] if len(phone) >= 4 else phone}"
        email = f"phone_{phone}_{rand_id}@dermascan.ai"
        password_hash = "OTP_AUTHENTICATED_USER_SESSION"
        try:
            cursor.execute('''
                INSERT INTO users (name, email, password, phone_number)
                VALUES (?, ?, ?, ?)
            ''', (name, email, password_hash, phone))
            conn.commit()
            new_id = cursor.lastrowid
            conn.close()
            return {'id': new_id, 'name': name, 'email': email, 'phone_number': phone}
        except Exception as e:
            conn.close()
            print(f"Error auto-creating user for phone OTP: {e}")
            return None

def save_diary_entry(user_id, disease, confidence, severity, date, image_base64, treatment_notes="", treatment_progress=0, home_remedies=""):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute('''
        INSERT INTO diary (user_id, disease, confidence, severity, date, image_base64, treatment_notes, treatment_progress, home_remedies)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', (user_id, disease, confidence, severity, date, image_base64, treatment_notes, int(treatment_progress), home_remedies))
    conn.commit()
    new_id = cursor.lastrowid
    conn.close()
    return new_id

def get_all_diary_entries(user_id):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute('''
        SELECT * FROM diary 
        WHERE user_id = ? 
        ORDER BY datetime(date) DESC
    ''', (user_id,))
    rows = cursor.fetchall()
    conn.close()
    
    entries = []
    for row in rows:
        keys = row.keys()
        entries.append({
            'id': row['id'],
            'disease': row['disease'],
            'confidence': row['confidence'],
            'severity': row['severity'],
            'date': row['date'],
            'image_base64': row['image_base64'],
            'treatment_notes': row['treatment_notes'] if 'treatment_notes' in keys else "",
            'treatment_progress': row['treatment_progress'] if 'treatment_progress' in keys else 0,
            'home_remedies': row['home_remedies'] if 'home_remedies' in keys else ""
        })
    return entries

def save_symptom_log(user_id, date, itchiness, redness, hydration):
    conn = get_db_connection()
    cursor = conn.cursor()
    # Check if a log already exists for this date. If so, update it, otherwise insert it.
    cursor.execute('''
        SELECT id FROM symptom_logs
        WHERE user_id = ? AND date = ?
    ''', (user_id, date))
    row = cursor.fetchone()
    if row:
        cursor.execute('''
            UPDATE symptom_logs
            SET itchiness = ?, redness = ?, hydration = ?
            WHERE id = ?
        ''', (itchiness, redness, hydration, row['id']))
        log_id = row['id']
    else:
        cursor.execute('''
            INSERT INTO symptom_logs (user_id, date, itchiness, redness, hydration)
            VALUES (?, ?, ?, ?, ?)
        ''', (user_id, date, itchiness, redness, hydration))
        log_id = cursor.lastrowid
    conn.commit()
    conn.close()
    return log_id

def get_symptom_logs(user_id):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute('''
        SELECT * FROM symptom_logs
        WHERE user_id = ?
        ORDER BY date ASC
    ''', (user_id,))
    rows = cursor.fetchall()
    conn.close()
    
    logs = []
    for row in rows:
        logs.append({
            'id': row['id'],
            'user_id': row['user_id'],
            'date': row['date'],
            'itchiness': row['itchiness'],
            'redness': row['redness'],
            'hydration': row['hydration']
        })
    return logs


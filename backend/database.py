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
    
    # 1. Create users table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            password TEXT NOT NULL
        )
    ''')
    
    # 2. Create diary table if not exists (with user_id)
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS diary (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL DEFAULT 1,
            disease TEXT NOT NULL,
            confidence REAL NOT NULL,
            severity TEXT NOT NULL,
            date TEXT NOT NULL,
            image_base64 TEXT NOT NULL,
            FOREIGN KEY(user_id) REFERENCES users(id)
        )
    ''')
    
    # 3. Migration: Auto-migrate existing diary table to add user_id column if it doesn't exist
    try:
        cursor.execute("ALTER TABLE diary ADD COLUMN user_id INTEGER NOT NULL DEFAULT 1")
    except sqlite3.OperationalError:
        # Column already exists, swallow the exception safely
        pass

    conn.commit()
    conn.close()
    print("Database initializations and migrations completed successfully.")

def create_user(name, email, password):
    conn = get_db_connection()
    cursor = conn.cursor()
    hashed = hash_password(password)
    try:
        cursor.execute('''
            INSERT INTO users (name, email, password)
            VALUES (?, ?, ?)
        ''', (name, email.lower().strip(), hashed))
        conn.commit()
        new_id = cursor.lastrowid
        conn.close()
        return {'id': new_id, 'name': name, 'email': email}
    except sqlite3.IntegrityError:
        conn.close()
        return None # Email already exists

def verify_credentials(email, password):
    conn = get_db_connection()
    cursor = conn.cursor()
    hashed = hash_password(password)
    cursor.execute('''
        SELECT id, name, email FROM users
        WHERE email = ? AND password = ?
    ''', (email.lower().strip(), hashed))
    row = cursor.fetchone()
    conn.close()
    if row:
        return {'id': row['id'], 'name': row['name'], 'email': row['email']}
    return None

def save_diary_entry(user_id, disease, confidence, severity, date, image_base64):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute('''
        INSERT INTO diary (user_id, disease, confidence, severity, date, image_base64)
        VALUES (?, ?, ?, ?, ?, ?)
    ''', (user_id, disease, confidence, severity, date, image_base64))
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
        entries.append({
            'id': row['id'],
            'disease': row['disease'],
            'confidence': row['confidence'],
            'severity': row['severity'],
            'date': row['date'],
            'image_base64': row['image_base64']
        })
    return entries

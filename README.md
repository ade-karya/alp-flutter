# ALP (Adaptive Learning Platform)

ALP adalah aplikasi edukasi berbasis Flutter yang dirancang untuk mendukung pembelajaran adaptif. Aplikasi ini mendukung **Windows** dan **Android**, serta dilengkapi dengan berbagai fitur canggih seperti asisten AI dan sinkronisasi data peer-to-peer.

## 🚀 Fitur Utama

* **Asisten AI Cerdas**: Terintegrasi dengan Google Gemini untuk membantu proses belajar mengajar.
* **Manajemen Multi-Peran**: Mendukung peran **Siswa** dan **Guru** dengan fitur yang disesuaikan.
* **Sinkronisasi Offline (P2P)**: Memungkinkan pertukaran data antar perangkat menggunakan koneksi lokal dan QR Code (tanpa internet).
* **Penyimpanan Lokal**: Menggunakan SQLite untuk penyimpanan data yang efisien dan aman.
* **Multi-Platform**: Dapat berjalan dengan mulus di perangkat Android dan Desktop Windows.
* **Keamanan**: Autentikasi pengguna yang aman.

## 🛠️ Prasyarat

Sebelum memulai, pastikan Anda telah menginstal:

1. **Flutter SDK** (Versi terbaru disarankan, minimal 3.10.x).
2. **Editor Kode**: VS Code atau Android Studio.
3. **Untuk Android**:
    * Android SDK & Tools.
    * Emulator Android atau Perangkat Fisik (dengan USB Debugging aktif).
4. **Untuk Windows**:
    * Visual Studio 2022 (Community Edition cukup).
    * Workload **"Desktop development with C++"** harus diinstal.

## 📦 Instalasi

1. **Clone Repositori** (jika menggunakan git):

    ```bash
    git clone <repository_url>
    cd alp
    ```

2. **Instal Dependensi**:
    Jalankan perintah berikut di terminal proyek Anda untuk mengunduh semua paket yang diperlukan:

    ```bash
    flutter pub get
    ```

## ▶️ Cara Menjalankan Aplikasi

### 📱 Android

1. Pastikan emulator berjalan atau perangkat fisik Anda terhubung.
2. Cek perangkat yang terhubung:

    ```bash
    flutter devices
    ```

3. Jalankan aplikasi:

    ```bash
    flutter run
    ```

    Jika ada lebih dari satu perangkat, gunakan flag `-d`:

    ```bash
    flutter run -d <device_id>
    ```

### 💻 Windows

1. Pastikan Anda telah menginstal Visual Studio dengan komponen C++ yang tepat.
2. Aktifkan **Developer Mode** di pengaturan Windows Anda (Settings > Update & Security > For developers).
3. Jalankan aplikasi dengan target Windows:

    ```bash
    flutter run -d windows
    ```

## 🏗️ Struktur Proyek

Proyek ini dibuat menggunakan **Clean Architecture** dan pola **BLoC** untuk manajemen state.

* `lib/core`: Komponen inti, utilitas, dan konfigurasi dasar.
* `lib/features`: Modul fitur utama (Auth, Student, Teacher, Network, AI Assistant, dll).
* `lib/main.dart`: Titik masuk aplikasi.

## 🔧 Pemecahan Masalah (Troubleshooting)

* **Masalah Database di Windows**: Jika Anda menemui masalah terkait `sqlite3.dll` di Windows, pastikan build tool C++ terinstal dengan benar melalui Visual Studio.
* **Koneksi P2P**: Untuk fitur sinkronisasi, pastikan kedua perangkat terhubung ke jaringan Wi-Fi yang sama atau salah satu perangkat mengaktifkan Hotspot.

---
Dikembangkan dengan ❤️ menggunakan Flutter.

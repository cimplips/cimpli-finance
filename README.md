# Cimpli Finance

Cimpli Finance adalah aplikasi manajemen keuangan pribadi berbasis Flutter yang membantu pengguna mencatat transaksi, memantau saldo, mengatur anggaran, melihat laporan keuangan, dan mengelola beberapa akun keuangan dalam satu aplikasi.

Aplikasi dirancang dengan pendekatan **local-first**, sehingga fungsi utama pengelolaan keuangan dapat digunakan tanpa bergantung pada koneksi internet.

---

## ✨ Fitur

### 📊 Dashboard

Dashboard menjadi pusat informasi keuangan pengguna.

Fitur yang tersedia:

- Saldo keuangan
- Total pemasukan
- Total pengeluaran
- Ringkasan kondisi keuangan
- Transaksi terbaru
- Informasi anggaran
- Peringatan anggaran
- Ringkasan transaksi berulang
- Pemilihan akun aktif

---

### 💰 Pencatatan Transaksi

Pengguna dapat mencatat aktivitas keuangan seperti:

- Pemasukan
- Pengeluaran
- Jumlah transaksi
- Catatan transaksi
- Tanggal transaksi
- Akun keuangan yang digunakan

---

### 🧾 Riwayat Transaksi

Riwayat digunakan untuk melihat aktivitas keuangan yang telah dicatat.

Pengguna dapat meninjau transaksi berdasarkan data yang tersimpan pada aplikasi.

---

### 📈 Laporan Keuangan

Aplikasi menyediakan halaman laporan untuk membantu pengguna memahami kondisi keuangan berdasarkan transaksi yang telah dicatat.

Laporan membantu melihat:

- Pemasukan
- Pengeluaran
- Perkembangan kondisi keuangan
- Ringkasan berdasarkan periode transaksi

---

### 🏦 Multi Akun Keuangan

Cimpli Finance mendukung beberapa akun keuangan.

Contohnya:

- Pribadi
- Rumah Tangga
- Usaha
- Kantor
- Bisnis
- Akun keuangan lainnya

Pengguna dapat menambahkan akun baru dan memilih akun aktif yang ingin digunakan.

---

### 🎯 Anggaran

Fitur anggaran membantu pengguna mengontrol pengeluaran.

Fitur meliputi:

- Membuat anggaran
- Menentukan batas anggaran
- Memantau penggunaan anggaran
- Menampilkan status anggaran
- Memberikan peringatan ketika anggaran mendekati atau melewati batas

---

### 🔄 Transaksi Berulang

Transaksi berulang digunakan untuk mengelola transaksi yang terjadi secara berkala.

Contohnya:

- Gaji
- Tagihan rutin
- Cicilan
- Sewa
- Langganan
- Pengeluaran rutin lainnya

---

### 🔐 Kunci Aplikasi

Cimpli Finance memiliki fitur keamanan untuk membantu melindungi data keuangan pengguna.

Kunci aplikasi menggunakan sistem autentikasi perangkat.

Jika perangkat mendukungnya, pengguna dapat menggunakan:

- PIN
- Pola
- Password perangkat
- Sidik jari
- Metode biometrik lain yang tersedia

---

### 🌙 Mode Gelap & Terang

Aplikasi mendukung dua mode tampilan:

- Dark Mode
- Light Mode

Pilihan tampilan dapat diubah melalui halaman **Pengaturan**.

Pilihan mode tampilan disimpan sehingga preferensi pengguna tetap digunakan ketika aplikasi dibuka kembali.

---

## 🛠️ Teknologi

Project ini dibangun menggunakan:

- **Flutter**
- **Dart**
- **SQLite**
- **sqflite**
- **Shared Preferences**
- **local_auth**

### Flutter

Framework utama yang digunakan untuk membangun antarmuka dan aplikasi mobile.

### SQLite / sqflite

Digunakan sebagai penyimpanan data keuangan secara lokal pada perangkat.

### Shared Preferences

Digunakan untuk menyimpan pengaturan aplikasi seperti:

- Mode tampilan
- Status kunci aplikasi
- Preferensi sederhana lainnya

### local_auth

Digunakan untuk autentikasi menggunakan keamanan perangkat.

---

## 📁 Struktur Project

```text
lib/
├── main.dart
├── app.dart
│
├── core/
│   └── finance_scope.dart
│
├── models/
│   ├── transaction.dart
│   └── recurring_transaction.dart
│
├── services/
│   ├── finance_store.dart
│   ├── budget_store.dart
│   ├── recurring_transaction.dart
│   └── app_lock_service.dart
│
├── screens/
│   ├── home_page.dart
│   ├── dashboard_page.dart
│   ├── add_transaction_page.dart
│   ├── history_page.dart
│   ├── report_page.dart
│   ├── settings_page.dart
│   ├── budget_page.dart
│   ├── recurring_transactions_page.dart
│   └── app_lock_page.dart
│
└── widgets/
    └── transaction_tile.dart

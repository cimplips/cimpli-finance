# Refactor tahap 1

`lib/main.dart` sekarang hanya menjadi entry point. Kode aplikasi dipisahkan berdasarkan tanggung jawab:

- `models/transaction.dart` — model transaksi dan enum.
- `services/finance_store.dart` — SQLite, akun, transaksi, dan kalkulasi.
- `core/finance_scope.dart` — akses store melalui InheritedNotifier.
- `screens/` — halaman utama aplikasi.
- `widgets/transaction_tile.dart` — widget transaksi yang dipakai ulang.
- `app.dart` — konfigurasi MaterialApp dan tema.

Refactor ini bertujuan mengubah struktur tanpa mengubah alur fitur utama. Jalankan `flutter pub get`, `dart format lib`, lalu `flutter analyze` pada mesin dengan Flutter SDK.

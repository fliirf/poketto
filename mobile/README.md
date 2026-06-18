# Poketto Mobile

Poketto Mobile adalah aplikasi Flutter untuk mencatat pemasukan/pengeluaran dan memantau kondisi keuangan pribadi. App berjalan sebagai client REST API Laravel dengan Neon PostgreSQL sebagai source of truth bersama web.

## Fitur

- Login, register, session restore, dan logout.
- Dashboard ringkasan: total pemasukan, total pengeluaran, saldo, transaksi terbaru, warning finansial, dan kurs jika endpoint tersedia.
- CRUD transaksi: tambah, edit, hapus, dan refresh list.
- Budget harian dapat diatur dari profile menu melalui `Budget Settings`.
- Kategori dan budget bulanan tersinkron dengan web melalui API.
- Geolocation opsional saat menambah transaksi pengeluaran. App mencoba lokasi terakhir lalu current location dengan timeout pendek; jika gagal, transaksi tetap tersimpan tanpa lokasi dan list/edit transaksi menampilkan status lokasi.
- In-app budget/financial warning dari backend.
- Local notification HP untuk budget/financial warning melalui channel `Budget Alerts`.
- Export laporan PDF dari fitur existing project.

## Tech Stack

- Flutter 3.x / Dart 3.x
- Provider untuk state sederhana
- `http` untuk REST API
- `flutter_secure_storage` untuk token
- `geolocator` dan `geocoding` untuk lokasi
- `flutter_local_notifications` untuk notifikasi lokal HP
- `intl` untuk format tanggal dan mata uang

## Konfigurasi

Jalankan dependency:

```bash
flutter pub get
```

Backend API diatur melalui dart-define:

```bash
--dart-define=API_BASE_URL=http://10.0.2.2:8002/api
```

Budget dan settings selalu berasal dari backend Laravel/Neon.

## Cara Run

Android emulator:

```bash
flutter devices
flutter emulators
flutter emulators --launch <emulator_id>
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8002/api
```

Android device fisik:

```bash
flutter devices
flutter run --dart-define=API_BASE_URL=http://<ip-komputer-atau-server>:8002/api
```

Chrome/web untuk cek UI cepat:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8002/api
```

Catatan: target utama app ini mobile. Geolocation dan permission di web bisa berbeda dari Android/iOS.

APK debug:

```bash
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8002/api
```

Output APK:

```txt
build/app/outputs/flutter-apk/app-debug.apk
```

## API Base URL

Default:

```txt
http://10.0.2.2:8002/api
```

Untuk Android emulator, `10.0.2.2` mengarah ke localhost komputer. Jika backend sudah online atau berjalan di IP LAN, ganti `API_BASE_URL`.

## Endpoint yang Digunakan

- `POST /login`
- `POST /register`
- `POST /logout`
- `GET /me`
- `GET /dashboard/summary`
- `GET /transactions`
- `POST /transactions`
- `GET /transactions/{id}`
- `PUT /transactions/{id}`
- `DELETE /transactions/{id}`
- `GET /categories`
- `POST /categories` jika backend mendukung tambah kategori
- `PUT/PATCH /categories/{id}` jika backend mendukung edit kategori/budget
- `DELETE /categories/{id}` jika backend mendukung hapus kategori
- `GET /budget-alerts`
- `GET /exchange-rates`

Endpoint protected dikirim dengan:

```txt
Authorization: Bearer <token>
Accept: application/json
Content-Type: application/json
```

Response auth yang didukung termasuk:

```json
{ "token": "...", "user": {} }
```

```json
{ "data": { "token": "...", "user": {} } }
```

```json
{ "access_token": "...", "token_type": "Bearer", "user": {} }
```

List API dapat berupa array langsung, `{ "data": [] }`, `{ "transactions": [] }`, atau wrapper serupa.

## Penyimpanan Data

Autentikasi, kategori, transaksi, dashboard, settings, budget alert, dan kurs selalu menggunakan REST API Laravel dan Neon PostgreSQL. Mobile tidak memiliki database SQLite.

Budget harian, budget bulanan, threshold, currency, dan notification settings disimpan melalui endpoint backend.

Lokasi transaksi yang diparsing dari API: `location_lat/location_lng`, `latitude/longitude`, `lat/lng`, nested `location`, dan `location_name/address`.

## Permission

Android:

- `INTERNET`
- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`
- `POST_NOTIFICATIONS` untuk Android 13+

iOS:

- `NSLocationWhenInUseUsageDescription`

Notification budget sekarang muncul sebagai in-app warning card dan local notification HP. Saat pertama kali app meminta izin notifikasi di Android 13+, pilih Allow agar warning bisa muncul di notification tray.

## Testing/Validation

Perintah yang sudah dipakai:

```bash
dart pub get
flutter test --no-pub
flutter build apk --debug --no-pub
```

Untuk analisis statis:

```bash
flutter analyze --no-pub
```

Known analyzer issue di environment ini: analysis server crash dengan `Bad state: No definition of type Map`. Debug APK tetap berhasil dibuild.

## Known Issues

- `flutter analyze` dapat crash karena internal Dart/Flutter analyzer di environment ini. Gunakan hasil `flutter build apk --debug` sebagai validasi compile.
- Setelah `flutter clean`, `flutter pub get` di Windows dapat meminta Developer Mode karena plugin desktop butuh symlink. Untuk target Android, `dart pub get` lalu `flutter build apk --debug --no-pub` tetap berhasil di environment ini.
- `flutter run` membutuhkan Android emulator/device. Jika belum muncul di `flutter devices`, launch emulator dari Android Studio atau `flutter emulators --launch <emulator_id>`.
- Local notification sudah aktif melalui `flutter_local_notifications`. Jika notifikasi tidak muncul, cek permission notifikasi Poketto di device/emulator dan pastikan dashboard memiliki budget alert yang aktif.
- Exchange rate hanya tampil jika backend menyediakan `/exchange-rates`.

## Demo Flow

1. Jalankan backend dan pastikan `API_BASE_URL` benar.
2. Buka app, register user baru atau login user existing.
3. Buka profile menu lalu `Budget Settings`, set daily budget misalnya Rp50.000.
4. Buka halaman `Kategori`, lalu atur budget kategori Makanan misalnya Rp100.000.
5. Lihat dashboard: saldo, pemasukan, pengeluaran, budget harian, transaksi terbaru, dan warning jika ada.
6. Tambah transaksi income.
7. Tambah transaksi expense Makanan Rp80.000. Biarkan switch `Tambahkan lokasi` aktif untuk demo geolocation dan lihat status lokasi di form.
8. Dashboard menampilkan warning kategori 80%. Jika expense hari ini melewati daily budget, warning budget harian juga muncul.
9. Izinkan permission notifikasi saat diminta. Warning budget yang aktif akan dikirim ke notification tray HP melalui channel `Budget Alerts`.
10. Ubah daily budget menjadi Rp100.000 untuk memperlihatkan warning harian berubah/hilang sesuai kondisi.
11. Long press transaksi untuk edit atau hapus dengan confirmation dialog.
12. Matikan permission lokasi lalu tambah expense lagi. Transaksi tetap tersimpan dan app menampilkan pesan lokasi dilewati/gagal.
13. Long press transaksi expense lalu pilih edit untuk melihat detail lokasi: nama lokasi, latitude, dan longitude jika tersedia.
14. Pull to refresh dashboard/list jika perlu.
15. Logout dari profile menu.

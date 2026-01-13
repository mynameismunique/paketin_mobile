# Paketin Mobile

Aplikasi Manajemen Gudang & Logistik berbasis Android/iOS.
Project ini dibuat untuk menangani alur keluar-masuk barang (Inventory) sekaligus tracking pengiriman paket oleh kurir (Logistics).

## Tentang Aplikasi
Paketin Mobile memisahkan peran antara **Admin Gudang** dan **Kurir Logistik**.
* **Admin:** Fokus jaga stok, restock barang dari supplier, mutasi antar gudang, dan memantau status kiriman.
* **Kurir:** Fokus ambil tugas pengiriman dan update status paket sampai ke penerima (wajib pakai bukti foto).

Database menggunakan **Firebase (Firestore)** biar datanya *real-time* tanpa perlu refresh manual terus-terusan.

## Fitur Unggulan

### Buat Admin Gudang:
* **Dashboard Monitoring:** Cek ringkasan stok dan orderan baru secara live.
* **Manajemen Stok (Inventory):** Cek barang, hapus, dan edit data. Sudah support fitur **Multi-Gudang** (lihat sebaran stok di tiap cabang).
* **Restock Barang:** Input barang masuk lengkap dengan data Supplier, Batch Number, dan Expired Date.
* **Mutasi Stok:** Pindahin stok dari Gudang A ke Gudang B.
* **Kirim Paket:** Buat order pengiriman baru (pilih metode: Regular, Express, dll).
* **Manajemen Supplier:** Simpan database kontak supplier biar gak ngetik ulang.
* **Laporan & PDF:** Export laporan stok dan riwayat pengiriman ke file PDF siap cetak.
* **Audit Log:** Pantau siapa yang ngubah data (Admin/Kurir) dan kapan kejadiannya.
* **Notifikasi:** Alert otomatis kalau ada stok yang menipis (Low Stock).

### Buat Kurir:
* **Job List:** Lihat daftar paket yang statusnya "Dikemas" dan siap diambil.
* **Update Status:** Ubah status dari "Dikemas" -> "Dikirim" -> "Sampai".
* **Bukti Pengantaran:** Wajib upload foto bukti penerima sebelum menyelesaikan order.
* **Riwayat:** Lihat history paket yang sudah sukses diantar.

## Tech Stack
* **Framework:** Flutter (Dart)
* **Backend:** Firebase Authentication & Cloud Firestore
* **State Management:** `setState` (Native) & StreamBuilder
* **PDF Generation:** `pdf` & `printing` packages
* **Camera:** `image_picker` (dengan kompresi otomatis)

## Cara Jalanin Project (Installation)

1. **Siapkan folder terlebih dahulu, untuk kalian simpan file project nya**
2. **Clone Repository ini dengan cara mengetikan:**
   ```bash
   git clone https://github.com/mynameismunique/paketin_mobile.git
3. **Project berhasil di clone, selanjutnya kalian bisa langsung buka IDE yang kalian mau untuk buka file project nya**
4. **Jangan lupa untuk mengetik kembali**
   ```bash
   flutter clean

5. **Jangan lupa untuk mengetik kembali:**
   ```bash
   flutter run

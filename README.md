# Aplikasi Web "Kavita"

> Status laporan: draf awal (10 Oktober 2026). Bagian yang belum dikerjakan
> diberi tanda **[BELUM]** dan akan diisi setelah praktik selesai.

## Sekilas Tentang

Kavita adalah aplikasi web self-hosted untuk membaca dan mengelola koleksi
manga, komik, dan buku digital. File bacaan (misalnya `.cbz`, `.epub`, `.pdf`)
ditaruh di sebuah folder, lalu Kavita memindainya menjadi library yang bisa
dibuka lewat browser dari berbagai perangkat.

- Situs dan dokumentasi: https://wiki.kavitareader.com
- Kode sumber: https://github.com/Kareadita/Kavita
- Versi yang terpasang: v0.9.1.4 (terlihat di log container)

Lingkungan praktik:

| Item | Keterangan |
|---|---|
| Host | Windows 11 Home, RAM 7,9 GB |
| Virtualisasi | VirtualBox 7.2.16 |
| VM | Ubuntu 26.04.1 LTS Desktop, 8 core, RAM 4,3 GB, disk 25 GB |
| Jaringan VM | NAT, IP `10.0.2.15` |
| Docker | Engine 29.9.0, Compose v5.6.0 |
| Image | `jvmilazz0/kavita:latest` |

## Instalasi

### Prasyarat

- Ubuntu dengan akses `sudo`
- Docker Engine dan Docker Compose plugin
- CPU yang mendukung SSE4.2 (syarat dari dokumentasi Kavita)
- Port 5000 belum dipakai program lain

Cek port 5000:

```bash
ss -tln | grep ':5000' || echo "Port 5000 kosong"
```

Hasil di VM saya: `Port 5000 kosong`.

### Langkah instalasi (CLI)

**1. Buat folder proyek dan folder bacaan**

```bash
mkdir -p ~/kavita/manga && cd ~/kavita
```

**2. Buat `compose.yaml`**

```bash
cat > compose.yaml <<'EOF'
services:
  kavita:
    image: jvmilazz0/kavita:latest
    container_name: kavita
    volumes:
      - ./manga:/manga
      - kavita-config:/kavita/config
    environment:
      - TZ=Asia/Jakarta
    ports:
      - "5000:5000"
    restart: unless-stopped

volumes:
  kavita-config:
EOF
```

Penjelasan singkat:

- `./manga:/manga` : folder bacaan di Ubuntu dipasang ke `/manga` di dalam container.
- `kavita-config:/kavita/config` : Docker volume untuk akun, pengaturan, dan database. Path ini tidak boleh diubah.
- `restart: unless-stopped` : Kavita menyala otomatis setelah Ubuntu restart.

**3. Validasi file**

```bash
sudo docker compose config -q && echo "compose.yaml VALID"
```

Hasil: `compose.yaml VALID`.

**4. Unduh image dan jalankan**

```bash
sudo docker compose pull
sudo docker compose up -d
```

**5. Cek status**

```bash
sudo docker compose ps
curl -sI http://localhost:5000 | head -n 1
```

Hasil di VM saya: container `Up`, port 5000 `LISTEN`, dan `curl` mengembalikan
`HTTP/1.1 200 OK`. Status kesehatan sempat `health: starting` lebih dari satu
menit pada start pertama karena Kavita menyiapkan database dulu.

**6. Port Forwarding VirtualBox (di Windows)** **[BELUM]**

Settings VM, Network, Adapter 1 (NAT), Advanced, Port Forwarding. Tambah aturan:

| Kolom | Isi |
|---|---|
| Name | `kavita` |
| Protocol | `TCP` |
| Host IP | `127.0.0.1` |
| Host Port | `5000` |
| Guest IP | `10.0.2.15` |
| Guest Port | `5000` |

Setelah itu Kavita dibuka dari Windows lewat `http://localhost:5000`.

### Catatan soal log

Log start pertama memuat banyak baris berlevel `Fatal` dan `Error`, padahal
aplikasi berjalan normal. Penyebabnya:

- Baris `[Fatal] ... migration ... This is not an error` adalah pesan migrasi
  database. Kavita memang menulisnya dengan level `Fatal`, dan teksnya sendiri
  menyebut bahwa itu bukan error.
- Baris `Unable to copy ... github_*.json` dan `DirectoryNotFoundException ... pr_cache`
  muncul karena file cache versi lama belum ada pada instalasi baru. Kavita
  menandainya sebagai `Warning` lalu melanjutkan start.

Tanda Kavita siap ada di log: `Now listening on: http://[::]:5000` dan
`Application started`.

## Konfigurasi (opsional)

Yang bisa diatur lewat `compose.yaml`:

| Pengaturan | Cara |
|---|---|
| Ganti port di Ubuntu | Ubah `"5000:5000"` menjadi misalnya `"5001:5000"` |
| Zona waktu | Ubah nilai `TZ` |
| Tambah folder bacaan | Tambah baris `volumes`, misalnya `- /data/komik:/komik` |

Setelah mengubah `compose.yaml`, terapkan dengan:

```bash
sudo docker compose up -d
```

Batas upload file dan batas memori **[BELUM]** diperiksa. Pemakaian sumber daya
sebenarnya bisa dilihat dengan `sudo docker stats --no-stream`.

## Plugin untuk fungsi tambahan **[BELUM]**

Belum dicek di dokumentasi mana saja fitur tambahan Kavita (misalnya login
pihak ketiga atau akses lewat aplikasi pembaca eksternal). Bagian ini akan
diisi setelah dibaca langsung dari wiki resmi.

## Maintenance (opsional)

Data penting Kavita ada di volume `kavita-config` dan folder `~/kavita/manga`.
Rencana backup (belum diuji):

```bash
mkdir -p ~/backup
sudo docker run --rm \
  -v kavita_kavita-config:/data \
  -v ~/backup:/backup \
  alpine tar czf /backup/kavita-config-$(date +%F).tar.gz -C /data .
```

Nama volume `kavita_kavita-config` mengikuti nama folder proyek (`kavita`) ditambah
nama volume di `compose.yaml`. Namanya bisa dipastikan dengan `sudo docker volume ls`.

Perintah rutin:

```bash
sudo docker compose ps              # cek status
sudo docker compose logs --tail 30  # lihat log
sudo docker compose restart         # restart aplikasi
sudo docker compose stop            # hentikan sementara, data aman
sudo docker compose start           # nyalakan lagi
```

**Peringatan:** jangan jalankan `docker compose down -v`. Opsi `-v` menghapus
volume sehingga semua akun dan library hilang. `docker compose down` tanpa `-v`
hanya menghapus container.

Backup terjadwal lewat cron dan pembaruan versi **[BELUM]** dikerjakan.

## Otomatisasi (opsional)

Skrip `setup-kavita.sh` mengerjakan instalasi dari awal: memasang Docker,
membuat folder dan `compose.yaml`, menjalankan Kavita, lalu menunggu sampai
merespons. Skrip belum diuji di VM baru.

```bash
bash setup-kavita.sh
```

Isi lengkap skrip ada di berkas `setup-kavita.sh`. Port Forwarding VirtualBox
dan pembuatan akun admin tetap dilakukan manual.

## Cara Pemakaian **[BELUM]**

Bagian ini diisi setelah Port Forwarding selesai dan Kavita bisa dibuka dari
browser Windows.

### Tampilan aplikasi

![Halaman pembuatan akun admin](screenshots/01-akun-admin.png)

### Fungsi-fungsi utama

Rencana yang akan dicoba:

1. Membuat akun admin pertama dan login.
2. Menaruh beberapa file uji (`.epub`, `.cbz`, `.pdf`) di `~/kavita/manga`.
3. Membuat library yang mengarah ke `/manga`, lalu menjalankan scan.
4. Membuka salah satu file di pembaca bawaan.
5. Menguji restart aplikasi dan restart Ubuntu, lalu memastikan akun dan
   library tidak hilang.

![Library berisi file uji](screenshots/02-library.png)

![Tampilan pembaca](screenshots/03-pembaca.png)

## Pembahasan

### Pengalaman sejauh ini

Kelebihan yang sudah terlihat:

- Instalasi lewat Docker Compose singkat: satu file konfigurasi dan dua perintah.
- Tidak butuh database terpisah, jadi tidak ada langkah tambahan seperti
  memasang MySQL.
- Data dipisahkan dengan jelas: file bacaan di folder biasa, akun dan
  pengaturan di Docker volume.
- Bisa menyala otomatis setelah restart lewat `restart: unless-stopped`.

Kekurangan yang saya temui:

- Start pertama cukup lama (status `health: starting` lebih dari satu menit di
  VM dengan RAM 4,3 GB).
- Log memuat banyak baris `Fatal` dan `Error` yang sebenarnya bukan masalah,
  sehingga membingungkan bagi pemula.
- Pemakaian sumber daya lebih besar daripada aplikasi ringan seperti
  ezBookkeeping. Angka sebenarnya **[BELUM]** diukur.

Kelebihan dan kekurangan lain akan ditambah setelah bagian Cara Pemakaian selesai.

### Perbandingan

Perbandingan dengan ezBookkeeping (aplikasi lain yang saya pasang di VM yang sama).
Keduanya beda fungsi, jadi ini lebih ke perbandingan pemasangan dan sumber daya:

| Aspek | ezBookkeeping | Kavita |
|---|---|---|
| Fungsi | Pencatatan keuangan pribadi | Perpustakaan dan pembaca digital |
| Teknologi | Go | .NET |
| Port di VM | 8080 | 5000 |
| Sumber daya | Lebih ringan | Lebih berat, terutama saat scan library |
| Data | Docker volume | Folder file bacaan + Docker volume |

Perbandingan dengan aplikasi sejenis (pembaca manga/komik self-hosted lain,
misalnya Komga) **[BELUM]** dikerjakan karena saya belum mencoba atau membaca
dokumentasinya.

## Referensi

- Kavita, Wiki dan dokumentasi resmi: https://wiki.kavitareader.com
- Kavita, Getting Started dan Docker Install (di wiki yang sama)
- Kavita, Repositori GitHub: https://github.com/Kareadita/Kavita
- Image Docker `jvmilazz0/kavita` di Docker Hub (dirujuk dari wiki Kavita)
- Docker, Install Docker Engine on Ubuntu: https://docs.docker.com/engine/install/ubuntu/
- Log dan keluaran terminal dari praktik sendiri di VM Ubuntu (9 sampai 10 Oktober 2026)

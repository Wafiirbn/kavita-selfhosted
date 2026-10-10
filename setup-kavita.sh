#!/bin/bash
# Setup Kavita pakai Docker di Ubuntu
# Jalankan: bash setup-kavita.sh  (jangan pakai sudo di depannya)

set -e

PORT=5000
FOLDER=~/kavita

sudo apt-get update

# Install Docker dari repository resmi
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo ${UBUNTU_CODENAME:-$VERSION_CODENAME}) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker

# Siapkan folder Kavita
mkdir -p $FOLDER/manga
cd $FOLDER

# Cek port
if ss -tln | grep -q ":$PORT " && ! sudo docker ps | grep -q kavita; then
  echo "Port $PORT sudah dipakai program lain. Ganti PORT di atas lalu jalankan ulang."
  exit 1
fi

# Buat compose.yaml (kalau belum ada)
if [ ! -f compose.yaml ]; then
cat > compose.yaml <<COMPOSE
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
      - "$PORT:5000"
    restart: unless-stopped

volumes:
  kavita-config:
COMPOSE
fi

sudo docker compose config -q && echo "compose.yaml valid"

# Unduh dan jalankan
sudo docker compose pull
sudo docker compose up -d

# Tunggu Kavita siap (maksimal 3 menit)
echo "Menunggu Kavita siap..."
for i in $(seq 1 36); do
  curl -fs -o /dev/null http://localhost:$PORT && break
  sleep 5
done

sudo docker compose ps

echo ""
echo "Kavita sudah jalan di http://localhost:$PORT (dari dalam Ubuntu)"
echo "Folder bacaan : $FOLDER/manga  (di Kavita pilih folder /manga)"
echo ""
echo "Sisa langkah manual:"
echo "1. Di VirtualBox: Settings > Network > Port Forwarding"
echo "   TCP, Host IP 127.0.0.1, Host Port $PORT, Guest IP $(hostname -I | awk '{print $1}'), Guest Port $PORT"
echo "2. Buka http://localhost:$PORT di browser Windows, buat akun admin"
echo ""
echo "Jangan jalankan 'docker compose down -v', datanya hilang semua."

#!/bin/bash

# Cập nhật hệ thống & cài đặt WireGuard
echo "🔄 Đang cập nhật hệ thống..."
sudo apt update -y && sudo apt upgrade -y
echo "✅ Hệ thống đã cập nhật!"

echo "🔄 Đang cài đặt WireGuard..."
sudo apt install wireguard -y
echo "✅ WireGuard đã được cài đặt!"

# Tạo thư mục và key
WG_DIR="/etc/wireguard"
PRIVATE_KEY="$WG_DIR/privatekey"
PUBLIC_KEY="$WG_DIR/publickey"

if [ ! -f "$PRIVATE_KEY" ]; then
    sudo mkdir -p $WG_DIR
    sudo chmod 700 $WG_DIR
    wg genkey | sudo tee $PRIVATE_KEY | wg pubkey | sudo tee $PUBLIC_KEY
fi

# Lấy IP máy chủ
SERVER_IP=$(curl -s ifconfig.me)

# WireGuard Interface Config
WG_CONF="$WG_DIR/wg0.conf"
cat <<EOF | sudo tee $WG_CONF
[Interface]
PrivateKey = $(sudo cat $PRIVATE_KEY)
Address = 10.0.0.1/24
ListenPort = 51820
SaveConfig = true
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
PublicKey = CHUA_CO_PUBLIC_KEY_CLIENT
AllowedIPs = 10.0.0.2/32
EOF

# Mở cổng VPN trên firewall
echo "🔄 Đang mở cổng firewall..."
sudo ufw allow 51820/udp
sudo sysctl -w net.ipv4.ip_forward=1
echo "✅ Firewall đã cấu hình!"

# Bật WireGuard
echo "🔄 Đang khởi động WireGuard..."
sudo systemctl enable wg-quick@wg0
sudo systemctl start wg-quick@wg0
echo "✅ WireGuard đã khởi động!"

# Xuất thông tin VPN
echo "🎉 VPN WireGuard đã sẵn sàng!"
echo "------------------------------------"
echo "🌍 Server IP: $SERVER_IP"
echo "🔑 Private Key Server: $(sudo cat $PRIVATE_KEY)"
echo "📌 Port: 51820"
echo "------------------------------------"
echo "📌 Để thêm Client, cần tạo Key & cập nhật file wg0.conf!"
echo "------------------------------------"

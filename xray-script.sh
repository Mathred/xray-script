#!/bin/bash

# Обновление системы и установка необходимых пакетов
sudo apt update && sudo apt install -y curl bash openssl

# Скачивание и установка Xray через официальный скрипт
curl -o install-release.sh -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh
bash install-release.sh
rm install-release.sh

# Создание папки для конфигурации
mkdir -p /usr/local/etc/xray

# Генерация UUID
UUID=$(/usr/local/bin/xray uuid)
echo "$UUID" > /usr/local/etc/xray/uuid

# Генерация публичного и приватного ключей
KEYPAIR=$(/usr/local/bin/xray x25519)
PRIVATE_KEY=$(echo "$KEYPAIR" | head -n 1 | awk '{print $NF}')
PUBLIC_KEY=$(echo "$KEYPAIR" | tail -n 1 | awk '{print $NF}')
echo "$PRIVATE_KEY" > /usr/local/etc/xray/private.key
echo "$PUBLIC_KEY" > /usr/local/etc/xray/public.key

# Генерация short ID с использованием openssl
SHORT_ID=$(openssl rand -hex 8)
echo "$SHORT_ID" > /usr/local/etc/xray/shortid

# Получение IP сервера
SERVER_IP=$(hostname -i)

# Создание конфигурационного файла Xray
cat <<EOF > /usr/local/etc/xray/config.json
{
    "inbounds": [
        {
            "port": 443,
            "protocol": "vless",
            "tag": "vless_tls",
            "settings": {
                "clients": [
                    {
                        "id": "$UUID",
                        "email": "user1@myserver",
                        "flow": "xtls-rprx-vision"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "tcp",
                "security": "reality",
                "realitySettings": {
                    "show": false,
                    "dest": "www.microsoft.com:443",
                    "xver": 0,
                    "serverNames": [
                        "www.microsoft.com"
                    ],
                    "privateKey": "$PRIVATE_KEY",
                    "shortIds": [
                        "$SHORT_ID"
                    ]
                }
            },
            "sniffing": {
                "enabled": true,
                "destOverride": [
                    "http",
                    "tls",
                    "quic"
                ]
            }
        },
        {
            "port": 443,
            "protocol": "vless",
            "tag": "vless_ws",
            "settings": {
                "clients": [
                    {
                        "id": "$UUID",
                        "email": "user1@myserver",
                        "flow": "xtls-rprx-vision"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "security": "reality",
                "realitySettings": {
                    "show": false,
                    "dest": "www.microsoft.com:443",
                    "xver": 0,
                    "serverNames": [
                        "www.microsoft.com"
                    ],
                    "privateKey": "$PRIVATE_KEY",
                    "shortIds": [
                        "$SHORT_ID"
                    ]
                },
                "wsSettings": {
                  "path": "/ws-path"
                }
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom",
            "tag": "direct"
        }
    ]
}
EOF

# Вывод информации для клиента
echo "==== Client Configuration ===="
echo "Server IP: $SERVER_IP"
echo "Port: 443"
echo "UUID: $UUID"
echo "SNI: www.microsoft.com"
echo "Fingerprint: chrome"
echo "Public Key: $PUBLIC_KEY"
echo "Short ID: $SHORT_ID"
echo "WebSocket Path: /ws-path"
echo "============================="

# Создание конфигурационного файла клиента
cat <<EOF > /usr/local/etc/xray/client-config.json
{
    "log": {
        "access": "",
        "error": "",
        "loglevel": "warning"
    },
    "inbounds": [
        {
            "port": 10801,
            "listen": "127.0.0.1",
            "protocol": "http",
            "settings": {
                "udp": true
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "vless",
            "settings": {
                "vnext": [
                    {
                        "address": "$SERVER_IP",
                        "port": 443,
                        "users": [
                            {
                                "id": "$UUID",
                                "flow": "xtls-rprx-vision",
                                "encryption": "none"
                            }
                        ]
                    }
                ]
            },
            "streamSettings": {
                "network": "tcp",
                "security": "reality",
                "realitySettings": {
                    "serverName": "www.microsoft.com",
                    "publicKey": "$PUBLIC_KEY",
                    "shortId": "$SHORT_ID",
                    "fingerprint": "chrome"
                }
            }
        }
    ]
}
EOF

# Запуск Xray
systemctl restart xray
journalctl -u xray
echo "Xray установлен и запущен!"
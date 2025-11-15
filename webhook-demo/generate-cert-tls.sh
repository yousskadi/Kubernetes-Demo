#!/bin/bash
set -e

# Dossier où seront stockés le certificat et la clé
TLS_DIR="./tls"

# Nom des fichiers
CERT_FILE="$TLS_DIR/tls.crt"
KEY_FILE="$TLS_DIR/tls.key"
CSR_CONF="$TLS_DIR/csr.conf"

# Crée le dossier tls s'il n'existe pas
mkdir -p "$TLS_DIR"

# Création du fichier de configuration pour SAN
cat > "$CSR_CONF" <<EOF
[req]
default_bits = 4096
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[dn]
CN = webhook-server

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
IP.1 = 127.0.0.1
EOF

# Génération de la clé et du certificat autosigné
openssl req -x509 -nodes -days 365 \
  -newkey rsa:4096 \
  -keyout "$KEY_FILE" \
  -out "$CERT_FILE" \
  -config "$CSR_CONF" \
  -extensions req_ext

# Vérifie le SAN
echo "Vérification du Subject Alternative Name :"
openssl x509 -in "$CERT_FILE" -noout -text | grep -A2 "Subject Alternative Name"

# Corrige les permissions pour que Docker puisse lire les fichiers
chmod 644 "$CERT_FILE" "$KEY_FILE"

echo "Certificat et clé générés dans $TLS_DIR"

#!/usr/bin/env bash
set -e

NAMESPACE="webhook-demo"
SERVICE_NAME="webhook-server"
CERT_DIR="./certs"
mkdir -p "$CERT_DIR"
cd "$CERT_DIR"

# 1) CA
openssl genrsa -out ca.key 2048
openssl req -x509 -new -nodes -key ca.key -subj "/CN=admission-webhook-ca" -days 3650 -out ca.crt

# 2) server key
openssl genrsa -out server.key 2048

# 3) CSR config with SAN
cat > server.cnf <<EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = ${SERVICE_NAME}
DNS.2 = ${SERVICE_NAME}.${NAMESPACE}
DNS.3 = ${SERVICE_NAME}.${NAMESPACE}.svc
EOF

openssl req -new -key server.key -subj "/CN=${SERVICE_NAME}.${NAMESPACE}.svc" -config server.cnf -out server.csr

# 4) Sign CSR with CA (create v3 ext file)
cat > extfile.cnf <<EOF
basicConstraints=CA:FALSE
keyUsage=digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth
subjectAltName = DNS:${SERVICE_NAME},DNS:${SERVICE_NAME}.${NAMESPACE},DNS:${SERVICE_NAME}.${NAMESPACE}.svc
EOF

openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days 365 -extfile extfile.cnf

echo "Generated certs in $(pwd): ca.crt, server.crt, server.key"
echo "To create the TLS secret in k8s: kubectl -n ${NAMESPACE} create secret tls webhook-server-tls --key=server.key --cert=server.crt"

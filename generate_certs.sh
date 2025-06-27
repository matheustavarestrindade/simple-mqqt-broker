#!/bin/sh
# generate_certs.sh — SH-compatible script for generating Mosquitto SSL/TLS certs

### --- CONFIGURATION SECTION --- ###
CERTS_DIR="certs"
KEY_SIZE=2048
VALIDITY_DAYS=3650

# Subjects
CA_SUBJ="/C=US/ST=State/L=City/O=MyOrg/CN=MyMosquittoCA"
SERVER_SUBJ="/C=US/ST=State/L=City/O=MyOrg/CN=localhost"
CLIENT_SUBJ_BASE="/C=US/ST=State/L=City/O=MyOrg/CN="

# Space-separated client names
CLIENTS="hydroponic-farm water-tank healthcheck"

# File names (generated automatically)
CA_KEY="$CERTS_DIR/ca.key"
CA_CRT="$CERTS_DIR/ca.crt"
SERVER_KEY="$CERTS_DIR/server.key"
SERVER_CSR="$CERTS_DIR/server.csr"
SERVER_CRT="$CERTS_DIR/server.crt"

### --- START SCRIPT --- ###
echo "🔧 Configuration:"
echo " - Output directory: $CERTS_DIR"
echo " - Key size: ${KEY_SIZE} bits"
echo " - Validity: ${VALIDITY_DAYS} days"
echo " - Clients: $CLIENTS"
echo ""

# Check if openssl is installed
if ! command -v openssl >/dev/null 2>&1; then
    echo "❌ openssl could not be found. Please install it to run this script."
    exit 1
fi

# Create output directory
mkdir -p "$CERTS_DIR" || { echo "❌ Failed to create $CERTS_DIR."; exit 1; }

### --- 1. CA KEY & CERT ---
echo "🔐 Generating CA Key and Certificate..."
openssl genrsa -out "$CA_KEY" $KEY_SIZE || { echo "❌ CA key generation failed."; exit 1; }

openssl req -x509 -new -nodes -key "$CA_KEY" -sha256 -days $VALIDITY_DAYS \
    -out "$CA_CRT" -subj "$CA_SUBJ" || { echo "❌ CA certificate generation failed."; exit 1; }

echo "✅ CA created: $CA_KEY, $CA_CRT"
echo ""

### --- 2. SERVER KEY & CERT ---
echo "🖥️  Generating Server Key and Certificate..."
openssl genrsa -out "$SERVER_KEY" $KEY_SIZE || { echo "❌ Server key generation failed."; exit 1; }

openssl req -new -key "$SERVER_KEY" -out "$SERVER_CSR" -subj "$SERVER_SUBJ" || { echo "❌ Server CSR generation failed."; exit 1; }

openssl x509 -req -in "$SERVER_CSR" -CA "$CA_CRT" -CAkey "$CA_KEY" -CAcreateserial \
    -out "$SERVER_CRT" -days $VALIDITY_DAYS -sha256 || { echo "❌ Server certificate signing failed."; exit 1; }

echo "✅ Server cert created: $SERVER_KEY, $SERVER_CRT"
echo ""

### --- 3. CLIENT CERTS ---
echo "👥 Generating client certificates..."
for client_name in $CLIENTS; do
    CLIENT_KEY="$CERTS_DIR/${client_name}.key"
    CLIENT_CSR="$CERTS_DIR/${client_name}.csr"
    CLIENT_CRT="$CERTS_DIR/${client_name}.crt"

    echo " - $client_name"
    openssl genrsa -out "$CLIENT_KEY" $KEY_SIZE || { echo "  ❌ Key gen failed for $client_name"; continue; }

    openssl req -new -key "$CLIENT_KEY" -out "$CLIENT_CSR" -subj "${CLIENT_SUBJ_BASE}${client_name}" || {
        echo "  ❌ CSR gen failed for $client_name"; continue; }

    openssl x509 -req -in "$CLIENT_CSR" -CA "$CA_CRT" -CAkey "$CA_KEY" -CAcreateserial \
        -out "$CLIENT_CRT" -days $VALIDITY_DAYS -sha256 || {
        echo "  ❌ Cert signing failed for $client_name"; continue; }

    echo "  ✅ Done: $CLIENT_KEY, $CLIENT_CRT"
done

echo ""
echo "🎉 All certificates and keys generated successfully in '$CERTS_DIR'."

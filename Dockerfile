FROM alpine:latest

# Instala os pacotes necessários
RUN apk add --no-cache bash openssl mosquitto mosquitto-clients

# Diretórios padrão
WORKDIR /app

# Copia os arquivos
COPY generate_certs.sh /app/generate_certs.sh
COPY mosquitto.conf /etc/mosquitto/mosquitto.conf

# Garante que o script seja executável
RUN chmod +x /app/generate_certs.sh

# Gera os certificados e inicia o Mosquitto
CMD ["/bin/sh", "-c", "/app/generate_certs.sh && mosquitto -c /etc/mosquitto/mosquitto.conf"]

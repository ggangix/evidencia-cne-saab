#!/usr/bin/env bash
# Captura la respuesta del API del CNE (consulta popular) para las cédulas dadas,
# con cabeceras, traza de curl, certificado TLS y hashes SHA-256 sellados con
# OpenTimestamps. Uso: ./capturar.sh [cedula ...]   (por defecto las dos del README)
set -euo pipefail
cd "$(dirname "$0")"

API=https://consultapopular.cne.gob.ve/circuits-re-api/api
ORIGIN=https://consultapopular.cne.gob.ve
HOST=consultapopular.cne.gob.ve
UA='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36'

if [ $# -gt 0 ]; then CEDULAS=("$@"); else CEDULAS=(21495350 36893134); fi

TS=$(date -u +%Y%m%dT%H%M%SZ)
OUT="capturas/$TS"
mkdir -p "$OUT"
cd "$OUT"

# Sin cookies a propósito: solo cabeceras genéricas de navegador, nada que identifique a quien consulta.
COMMON=(-sS --trace-time -H "User-Agent: $UA" -H "Origin: $ORIGIN" -H "Referer: $ORIGIN/")

echo "→ Pidiendo token"
curl "${COMMON[@]}" -D token.headers -o token.json "$API/token"
TK=$(python3 -I -c 'import json,sys; print(json.load(sys.stdin)["token"])' < token.json)

for C in "${CEDULAS[@]}"; do
  echo "→ Consultando V-$C"
  curl "${COMMON[@]}" -v \
    -H 'accept: application/json' -H 'content-type: application/json' -H "x-web-token: $TK" \
    -D "V$C.headers" -o "V$C.json" \
    --data-raw "{\"cedula\":\"$C\",\"nacionalidad\":\"V\",\"tk\":\"$TK\"}" \
    "$API/get-register" 2> "V$C.curl-trace.txt"
  head -1 "V$C.headers"
  sleep 2
done

echo "→ Guardando certificado TLS"
echo | openssl s_client -connect "$HOST:443" -servername "$HOST" -showcerts 2>/dev/null > tls-cadena.pem.txt || true
openssl x509 -noout -subject -issuer -dates -fingerprint -sha256 < tls-cadena.pem.txt > tls-resumen.txt || true

cat > metadata.txt <<EOF
capturado_utc: $(date -u +%FT%TZ)
endpoint: $API/get-register
cedulas: ${CEDULAS[*]}
curl: $(curl --version | head -1)
openssl: $(openssl version)
EOF

shasum -a 256 -- * > SHA256SUMS
if command -v ots >/dev/null; then
  ots stamp SHA256SUMS && echo "✓ Sellado OpenTimestamps (correr 'ots upgrade' en unas horas)"
else
  echo "⚠ 'ots' no está instalado: pipx install opentimestamps-client && ots stamp $OUT/SHA256SUMS"
fi

echo
echo "Listo: $OUT"
for C in "${CEDULAS[@]}"; do echo "--- V$C"; cat "V$C.json"; echo; done

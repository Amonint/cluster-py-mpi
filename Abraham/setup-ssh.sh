#!/usr/bin/env bash
set -euo pipefail

# --- EDITAR ANTES DE EJECUTAR ---
ANDRE_USER="${ANDRE_USER:-usuario}"
ANDRE_HOST="${ANDRE_HOST:-192.168.1.101}"
ALEX_USER="${ALEX_USER:-usuario}"
ALEX_HOST="${ALEX_HOST:-192.168.1.102}"
# --------------------------------

KEY="${HOME}/.ssh/id_ed25519"

echo "==> Generando clave SSH (si no existe)"
mkdir -p "${HOME}/.ssh"
chmod 700 "${HOME}/.ssh"

if [[ ! -f "${KEY}" ]]; then
  ssh-keygen -t ed25519 -N "" -f "${KEY}" -q
fi

echo "==> Copiando clave pública a André (${ANDRE_USER}@${ANDRE_HOST})"
ssh-copy-id -i "${KEY}.pub" "${ANDRE_USER}@${ANDRE_HOST}"

echo "==> Copiando clave pública a Alex (${ALEX_USER}@${ALEX_HOST})"
ssh-copy-id -i "${KEY}.pub" "${ALEX_USER}@${ALEX_HOST}"

echo "==> Probando conexión"
ssh -o BatchMode=yes "${ANDRE_USER}@${ANDRE_HOST}" hostname
ssh -o BatchMode=yes "${ALEX_USER}@${ALEX_HOST}" hostname

echo "==> SSH configurado correctamente"

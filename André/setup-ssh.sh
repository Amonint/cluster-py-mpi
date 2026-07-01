#!/usr/bin/env bash
set -euo pipefail

PEER_HOST="${PEER_HOST:-abraham.local}"

KEY="${HOME}/.ssh/id_ed25519"

echo "==> Activando Remote Login local (pide tu password de macOS, no la del otro equipo)"
sudo systemsetup -setremotelogin on

echo "==> Generando clave SSH local (si no existe)"
mkdir -p "${HOME}/.ssh"
chmod 700 "${HOME}/.ssh"

if [[ ! -f "${KEY}" ]]; then
  ssh-keygen -t ed25519 -N "" -f "${KEY}" -q
fi

echo ""
echo "==> Paso manual: comparte tu clave pública por AirDrop"
echo "    Archivo a enviar: ${KEY}.pub"
echo "    Abre Finder, ve a ~/.ssh, arrastra id_ed25519.pub al ícono de AirDrop"
echo "    del Mac de Abraham. NO se pide contraseña, solo aceptar la transferencia."
echo ""
echo "==> Cuando recibas la clave pública de Abraham por AirDrop, agrégala a tu propio authorized_keys:"
echo "    cat ~/Downloads/id_ed25519.pub >> ~/.ssh/authorized_keys"
echo "    chmod 600 ~/.ssh/authorized_keys"
echo ""
read -rp "Presiona Enter cuando ya intercambiaste las claves por AirDrop en ambos equipos... "

echo "==> Probando conexión sin contraseña hacia ${PEER_HOST}"
ssh -o BatchMode=yes -o ConnectTimeout=5 "${PEER_HOST}" hostname

echo "==> SSH configurado correctamente hacia ${PEER_HOST}"

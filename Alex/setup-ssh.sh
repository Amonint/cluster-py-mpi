#!/usr/bin/env bash
set -euo pipefail

echo "==> Alex (WSL2): configurando openssh-server"

sudo service ssh start

mkdir -p ~/.ssh
chmod 700 ~/.ssh

if [[ ! -f ~/.ssh/authorized_keys ]]; then
  touch ~/.ssh/authorized_keys
fi
chmod 600 ~/.ssh/authorized_keys

echo "IP de este nodo WSL2 (compartir con Abraham para hostfile/SSH):"
hostname -I

echo ""
echo "Siguiente paso: desde Abraham ejecutar ssh-copy-id hacia este nodo."
echo "Si usas puerto distinto a 22, edita /etc/ssh/sshd_config y reinicia: sudo service ssh restart"

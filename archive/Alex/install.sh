#!/usr/bin/env bash
set -euo pipefail

echo "==> Alex (WSL2 Ubuntu worker): instalando dependencias"

export DEBIAN_FRONTEND=noninteractive

sudo apt update
sudo apt install -y \
  openmpi-bin \
  libopenmpi-dev \
  python3 \
  python3-pip \
  python3-venv \
  openssh-server \
  rsync

python3 -m pip install --upgrade pip --break-system-packages 2>/dev/null \
  || python3 -m pip install --upgrade pip
python3 -m pip install mpi4py numpy --break-system-packages 2>/dev/null \
  || python3 -m pip install mpi4py numpy

echo "==> Instalación completada"

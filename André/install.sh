#!/usr/bin/env bash
set -euo pipefail

echo "==> André (macOS worker): instalando dependencias"

if ! command -v brew &>/dev/null; then
  echo "Homebrew no encontrado. Instálalo desde https://brew.sh y vuelve a ejecutar."
  exit 1
fi

brew update
brew install openmpi python

python3 -m pip install --upgrade pip
python3 -m pip install mpi4py numpy

echo "==> Instalación completada"

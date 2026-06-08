#!/usr/bin/env bash
set -euo pipefail

echo "==> Verificando Alex (WSL2 worker)"

command -v mpirun
mpirun --version | head -1

command -v python3
python3 --version

python3 -c "from mpi4py import MPI; print('mpi4py OK, MPI version:', MPI.Get_version())"

echo "IP WSL2:"
hostname -I

if sudo service ssh status >/dev/null 2>&1; then
  echo "openssh-server: activo"
else
  echo "AVISO: openssh-server no está activo. Ejecuta: sudo service ssh start"
fi

echo "==> Verificación local completada"

#!/usr/bin/env bash
set -euo pipefail

echo "==> Verificando Abraham (maestro)"

command -v mpirun
mpirun --version | head -1

command -v python3
python3 --version

python3 -c "from mpi4py import MPI; print('mpi4py OK, MPI version:', MPI.Get_version())"

if [[ -f hostfile ]]; then
  echo "hostfile presente:"
  cat hostfile
else
  echo "AVISO: hostfile no encontrado. Copia hostfile.example a hostfile y edita las IPs."
fi

echo "==> Verificación local completada"

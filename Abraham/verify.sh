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

echo "==> Resolución mDNS hacia André"
if ping -c 1 -t 2 andre.local >/dev/null 2>&1; then
  echo "andre.local responde"
else
  echo "AVISO: andre.local no responde. Verifica que ambos Macs estén en la misma red (hotspot/Ethernet+ICS)."
fi

echo "==> Syncthing"
if pgrep -x syncthing >/dev/null 2>&1; then
  echo "Syncthing corriendo"
else
  echo "AVISO: Syncthing no está corriendo. Ejecuta: brew services start syncthing"
fi

echo "==> Verificación local completada"

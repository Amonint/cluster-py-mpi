#!/usr/bin/env bash
set -euo pipefail

echo "==> Verificando André (worker macOS)"

command -v mpirun
mpirun --version | head -1

command -v python3
python3 --version

python3 -c "from mpi4py import MPI; print('mpi4py OK, MPI version:', MPI.Get_version())"

if systemsetup -getremotelogin 2>/dev/null | grep -q "On"; then
  echo "Remote Login (SSH): activo"
else
  echo "AVISO: Remote Login puede estar desactivado. Ejecuta: sudo systemsetup -setremotelogin on"
fi

echo "==> Resolución mDNS hacia Abraham"
if ping -c 1 -t 2 abraham.local >/dev/null 2>&1; then
  echo "abraham.local responde"
else
  echo "AVISO: abraham.local no responde. Verifica que ambos Macs estén en la misma red (hotspot/Ethernet+ICS)."
fi

echo "==> Syncthing"
if pgrep -x syncthing >/dev/null 2>&1; then
  echo "Syncthing corriendo"
else
  echo "AVISO: Syncthing no está corriendo. Ejecuta: brew services start syncthing"
fi

echo "==> Verificación local completada"

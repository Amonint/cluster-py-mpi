#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOSTFILE="${SCRIPT_DIR}/hostfile"
SHARED="${SCRIPT_DIR}/../shared"

if [[ ! -f "${HOSTFILE}" ]]; then
  echo "Error: ${HOSTFILE} no existe. Copia hostfile.example a hostfile y edita las IPs."
  exit 1
fi

cd "${SHARED}"
mpirun -np 6 --hostfile "${HOSTFILE}" python3 vector_sum.py

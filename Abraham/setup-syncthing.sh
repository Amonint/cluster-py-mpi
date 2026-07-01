#!/usr/bin/env bash
set -euo pipefail

echo "==> Instalando Syncthing"
brew install syncthing

echo "==> Arrancando Syncthing como servicio local"
brew services start syncthing

echo ""
echo "==> Abre http://localhost:8384 en tu navegador"
echo "    1. Copia tu Device ID (Acciones > Mostrar ID)"
echo "    2. Compártelo con André (por AirDrop, mensaje, o mostrando pantalla)"
echo "    3. Cuando André agregue tu Device ID, acepta el par en la UI"
echo "    4. Agrega la carpeta compartida:"
echo "       - Ruta: $(cd "$(dirname "${BASH_SOURCE[0]}")/../shared" && pwd)"
echo "       - Compartir con: dispositivo de André"
echo "       - Tipo: Send & Receive"
echo ""
echo "==> Cuando ambos lados muestren la carpeta 'shared' como Up to Date, la sync está lista."

#!/usr/bin/env bash
set -euo pipefail

echo "==> Instalando Syncthing"
brew install syncthing

echo "==> Arrancando Syncthing como servicio local"
brew services start syncthing

echo ""
echo "==> Abre http://localhost:8384 en tu navegador"
echo "    1. Copia tu Device ID (Acciones > Mostrar ID)"
echo "    2. Compártelo con Abraham (por AirDrop, mensaje, o mostrando pantalla)"
echo "    3. Cuando Abraham agregue tu Device ID, acepta el par en la UI"
echo "    4. Acepta la carpeta compartida 'shared' que Abraham te va a enviar"
echo "       - Ruta local sugerida: $(cd "$(dirname "${BASH_SOURCE[0]}")/../shared" && pwd)"
echo ""
echo "==> Cuando ambos lados muestren la carpeta 'shared' como Up to Date, la sync está lista."

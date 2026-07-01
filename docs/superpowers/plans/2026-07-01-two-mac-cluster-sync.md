# Two-Mac Cluster + Realtime Shared Sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reduce the cluster to 2 macOS nodes (Abraham=master, André=worker), connected via mobile hotspot (Ethernet+Internet Sharing as fallback), with passwordless SSH set up without ever entering one Mac's password from the other, and real-time bidirectional sync of `shared/` via Syncthing.

**Architecture:** Two independent communication meshes on the same LAN (hotspot or ICS subnet): (1) SSH mesh used only by `mpirun` to launch/manage MPI processes, trust established via local keygen + AirDrop pubkey exchange, addressed by mDNS `.local` hostnames instead of static IPs; (2) Syncthing mesh, paired by Device ID, keeping `shared/` identical on both nodes with no manual copy step.

**Tech Stack:** macOS (Homebrew, Open MPI, mpi4py, OpenSSH, Bonjour/mDNS, AirDrop, Syncthing).

## Global Constraints

- No node's password may be entered from the other node; no remote-login-style credential requests between machines (spec requirement).
- Use mDNS `.local` hostnames, not static IPs, in hostfile/SSH config (hotspot IP is dynamic).
- `Alex/` is archived, not deleted (`archive/Alex/`).
- `shared/` path must remain identical on both nodes: `~/cluster-py-mpi/shared/`.
- Existing MPI programs (`hello_mpi.py`, `vector_sum.py`) are unchanged.

---

### Task 1: Archive Alex, update README to 2-node cluster

**Files:**
- Move: `Alex/` → `archive/Alex/`
- Modify: `README.md`

**Steps:**

- [ ] **Step 1: Move Alex's folder into archive**

```bash
mkdir -p archive
git mv Alex archive/Alex
```

- [ ] **Step 2: Rewrite README.md**

Replace the full contents of `README.md` with:

```markdown
# cluster-py-mpi

Clúster universitario educativo con **Python + MPI + SSH**, 2 nodos macOS.

## Nodos

| Carpeta | Persona | Rol | Sistema |
|---|---|---|---|
| `Abraham/` | Abraham | **Maestro** | macOS |
| `André/` | André | Worker | macOS |

> El nodo de Alex (Windows/WSL2) salió del proyecto. Su configuración quedó en `archive/Alex/` como referencia, fuera del flujo activo.

## Estructura

\`\`\`
cluster-py-mpi/
├── README.md
├── Abraham/          # Nodo maestro: hostfile, SSH, Syncthing, lanzamiento MPI
├── André/             # Worker macOS
├── archive/Alex/       # Referencia archivada, no usar
└── shared/             # Programas Python + carpeta sincronizada en tiempo real
    ├── hello_mpi.py
    └── vector_sum.py
\`\`\`

## Red

Los 2 Macs se conectan a la **misma red local**. Método principal: **hotspot móvil** desde un celular (sin restricciones de red universitaria, portátil). Plan B: **Ethernet + Compartir Internet** desde Abraham si el hotspot no es viable. Ambos nodos se direccionan por hostname mDNS (`abraham.local`, `andre.local`), no por IP fija, porque el hotspot asigna IP dinámica.

## Sincronización en tiempo real de `shared/`

`shared/` se mantiene idéntica en ambos nodos con **Syncthing** (bidireccional, automático, sin servidor central). Un cambio en un nodo aparece en el otro en segundos mientras ambos estén en la misma red.

## Inicio rápido

1. Copia este repositorio a cada Mac en `~/cluster-py-mpi/`
2. Conecta ambos Macs a la misma red (hotspot móvil o Ethernet+ICS)
3. Sigue `INSTRUCCIONES.md` en `Abraham/` y `André/` — orden recomendado abajo

## Orden recomendado

1. **Ambos nodos**: `./install.sh` → `./verify.sh`
2. **Ambos nodos**: `./setup-ssh.sh` (genera clave local, intercambio por AirDrop)
3. **Ambos nodos**: `./setup-syncthing.sh` (instala y arranca Syncthing, emparejar por Device ID)
4. **Abraham**: copiar `hostfile.example` a `hostfile`
5. **Abraham**: `./run-hello.sh` y `./run-vector-sum.sh`
```

- [ ] **Step 3: Verify README renders sanely**

Run: `cat README.md | head -5`
Expected: starts with `# cluster-py-mpi`

---

### Task 2: Rewrite SSH setup for both nodes (no cross-machine passwords)

**Files:**
- Modify: `Abraham/setup-ssh.sh`
- Create: `André/setup-ssh.sh`
- Modify: `Abraham/hostfile.example`

**Interfaces:**
- Both scripts produce a local `~/.ssh/id_ed25519` keypair and a printed AirDrop instruction; neither script calls `ssh-copy-id` or otherwise touches the peer machine remotely.

**Steps:**

- [ ] **Step 1: Rewrite `Abraham/setup-ssh.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

PEER_HOST="${PEER_HOST:-andre.local}"

KEY="${HOME}/.ssh/id_ed25519"

echo "==> Activando Remote Login local (pide tu password de macOS, no la del otro equipo)"
sudo systemsetup -setremotelogin on

echo "==> Generando clave SSH local (si no existe)"
mkdir -p "${HOME}/.ssh"
chmod 700 "${HOME}/.ssh"

if [[ ! -f "${KEY}" ]]; then
  ssh-keygen -t ed25519 -N "" -f "${KEY}" -q
fi

echo ""
echo "==> Paso manual: comparte tu clave pública por AirDrop"
echo "    Archivo a enviar: ${KEY}.pub"
echo "    Abre Finder, ve a ~/.ssh, arrastra id_ed25519.pub al ícono de AirDrop"
echo "    del Mac de André. NO se pide contraseña, solo aceptar la transferencia."
echo ""
echo "==> Cuando recibas la clave pública de André por AirDrop, agrégala a tu propio authorized_keys:"
echo "    cat ~/Downloads/id_ed25519.pub >> ~/.ssh/authorized_keys"
echo "    chmod 600 ~/.ssh/authorized_keys"
echo ""
read -rp "Presiona Enter cuando ya intercambiaste las claves por AirDrop en ambos equipos... "

echo "==> Probando conexión sin contraseña hacia ${PEER_HOST}"
ssh -o BatchMode=yes -o ConnectTimeout=5 "${PEER_HOST}" hostname

echo "==> SSH configurado correctamente hacia ${PEER_HOST}"
```

- [ ] **Step 2: Create `André/setup-ssh.sh`** (same flow, peer defaults to Abraham)

```bash
#!/usr/bin/env bash
set -euo pipefail

PEER_HOST="${PEER_HOST:-abraham.local}"

KEY="${HOME}/.ssh/id_ed25519"

echo "==> Activando Remote Login local (pide tu password de macOS, no la del otro equipo)"
sudo systemsetup -setremotelogin on

echo "==> Generando clave SSH local (si no existe)"
mkdir -p "${HOME}/.ssh"
chmod 700 "${HOME}/.ssh"

if [[ ! -f "${KEY}" ]]; then
  ssh-keygen -t ed25519 -N "" -f "${KEY}" -q
fi

echo ""
echo "==> Paso manual: comparte tu clave pública por AirDrop"
echo "    Archivo a enviar: ${KEY}.pub"
echo "    Abre Finder, ve a ~/.ssh, arrastra id_ed25519.pub al ícono de AirDrop"
echo "    del Mac de Abraham. NO se pide contraseña, solo aceptar la transferencia."
echo ""
echo "==> Cuando recibas la clave pública de Abraham por AirDrop, agrégala a tu propio authorized_keys:"
echo "    cat ~/Downloads/id_ed25519.pub >> ~/.ssh/authorized_keys"
echo "    chmod 600 ~/.ssh/authorized_keys"
echo ""
read -rp "Presiona Enter cuando ya intercambiaste las claves por AirDrop en ambos equipos... "

echo "==> Probando conexión sin contraseña hacia ${PEER_HOST}"
ssh -o BatchMode=yes -o ConnectTimeout=5 "${PEER_HOST}" hostname

echo "==> SSH configurado correctamente hacia ${PEER_HOST}"
```

- [ ] **Step 3: Update `Abraham/hostfile.example` to use `.local` hostnames**

```
# Copiar a hostfile, no requiere editar IPs — usa hostnames mDNS
abraham.local slots=2
andre.local slots=2
```

- [ ] **Step 4: Make both scripts executable and shellcheck-sane**

```bash
chmod +x Abraham/setup-ssh.sh André/setup-ssh.sh
bash -n Abraham/setup-ssh.sh && bash -n André/setup-ssh.sh
```

Expected: no syntax errors (no output).

---

### Task 3: Add Syncthing setup scripts to both nodes

**Files:**
- Create: `Abraham/setup-syncthing.sh`
- Create: `André/setup-syncthing.sh`

**Steps:**

- [ ] **Step 1: Create `Abraham/setup-syncthing.sh`**

```bash
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
```

- [ ] **Step 2: Create `André/setup-syncthing.sh`** (symmetric)

```bash
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
```

- [ ] **Step 3: Make executable and syntax-check**

```bash
chmod +x Abraham/setup-syncthing.sh André/setup-syncthing.sh
bash -n Abraham/setup-syncthing.sh && bash -n André/setup-syncthing.sh
```

Expected: no output (no syntax errors).

---

### Task 4: Update verify.sh on both nodes with network/sync checks

**Files:**
- Modify: `Abraham/verify.sh`
- Modify: `André/verify.sh`

**Steps:**

- [ ] **Step 1: Append mDNS + Syncthing checks to `Abraham/verify.sh`** (after the existing hostfile check, before the final echo)

```bash

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
```

- [ ] **Step 2: Append the same checks (mirrored) to `André/verify.sh`** (before the final echo)

```bash

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
```

- [ ] **Step 3: Syntax-check both**

```bash
bash -n Abraham/verify.sh && bash -n André/verify.sh
```

Expected: no output.

---

### Task 5: Rewrite INSTRUCCIONES.md for Abraham and André

**Files:**
- Modify: `Abraham/INSTRUCCIONES.md`
- Modify: `André/INSTRUCCIONES.md`

**Steps:**

- [ ] **Step 1: Replace `Abraham/INSTRUCCIONES.md` contents**

```markdown
# Abraham — Nodo maestro (macOS)

Abraham es el **nodo maestro** del clúster de 2 nodos. Instala el stack MPI/Python, establece confianza SSH con André sin usar contraseñas cruzadas, sincroniza `shared/` en tiempo real con Syncthing, y lanza los jobs MPI.

## Rol

| Campo | Valor |
|---|---|
| Sistema | macOS |
| Rol | Maestro (orquestador MPI) |
| Worker | André (macOS) |

## Red

1. Conectar ambos Macs a la **misma red**: hotspot móvil (principal) o Ethernet + Compartir Internet desde Abraham (plan B).
2. Verificar resolución mDNS: `ping andre.local` debe responder sin pérdida.

## Instalación

```bash
cd ~/cluster-py-mpi/Abraham
chmod +x install.sh verify.sh setup-ssh.sh setup-syncthing.sh run-hello.sh run-vector-sum.sh
./install.sh
./verify.sh
```

## SSH sin contraseñas cruzadas

```bash
./setup-ssh.sh
```

El script activa Remote Login localmente, genera tu clave SSH, y te guía para intercambiar la clave pública con André **por AirDrop** (nunca se pide la contraseña del otro Mac). Al final prueba `ssh andre.local hostname` sin prompt.

## Sincronizar `shared/` en tiempo real

```bash
./setup-syncthing.sh
```

Instala y arranca Syncthing, y te guía para emparejar con André por Device ID y compartir la carpeta `shared/` en modo Send & Receive. Una vez emparejado, cualquier cambio en `shared/` en cualquiera de los 2 Macs se refleja automáticamente en el otro en segundos.

## Configurar hostfile

```bash
cp hostfile.example hostfile
```

`hostfile` ya usa hostnames `.local`, no requiere editar IPs:

```txt
abraham.local slots=2
andre.local slots=2
```

Ajusta `slots` según núcleos reales: `sysctl -n hw.logicalcpu`.

## Validación

```bash
./verify.sh
mpirun --version
python3 -c "from mpi4py import MPI; print(MPI.Get_version())"
ssh andre.local "mpirun --version"
```

## Ejecutar programas MPI

```bash
cd ../shared
./run-hello.sh
./run-vector-sum.sh
```

O manualmente:

```bash
mpirun -np 4 --hostfile ../Abraham/hostfile python3 hello_mpi.py
mpirun -np 4 --hostfile ../Abraham/hostfile python3 vector_sum.py
```

## Checklist de aceptación

- [ ] Hotspot móvil (o Ethernet+ICS) activo, ambos Macs conectados
- [ ] `ping andre.local` responde sin pérdida
- [ ] `brew install` completado sin errores
- [ ] `mpi4py` importa correctamente
- [ ] SSH sin contraseña hacia André, sin haber usado `ssh-copy-id`
- [ ] Syncthing: carpeta `shared` "Up to Date" en ambos nodos
- [ ] Editar un archivo en `shared/` se refleja en André en segundos
- [ ] `hello_mpi.py` muestra procesos en `abraham.local` y `andre.local`
- [ ] `vector_sum.py` produce la suma correcta
```

- [ ] **Step 2: Replace `André/INSTRUCCIONES.md` contents**

```markdown
# André — Worker (macOS)

André es el **nodo worker** del clúster de 2 nodos. Recibe conexiones SSH de Abraham y ejecuta procesos MPI remotos. `shared/` se mantiene en sync en tiempo real vía Syncthing.

## Rol

| Campo | Valor |
|---|---|
| Sistema | macOS |
| Rol | Worker |
| Maestro | Abraham |

## Red

1. Conectar este Mac a la **misma red** que Abraham: hotspot móvil (principal) o unirse a la red compartida por Abraham vía Ethernet+ICS (plan B).
2. Verificar resolución mDNS: `ping abraham.local` debe responder sin pérdida.

## Instalación

```bash
cd ~/cluster-py-mpi/André
chmod +x install.sh verify.sh setup-ssh.sh setup-syncthing.sh
./install.sh
./verify.sh
```

## SSH sin contraseñas cruzadas

```bash
./setup-ssh.sh
```

Activa Remote Login localmente, genera tu propia clave SSH, y te guía para intercambiar la clave pública con Abraham **por AirDrop**. En ningún momento se ingresa la contraseña de un Mac en el otro.

## Sincronizar `shared/` en tiempo real

```bash
./setup-syncthing.sh
```

Instala y arranca Syncthing, te guía para aceptar el emparejamiento y la carpeta `shared/` compartida por Abraham. La ruta debe quedar en `~/cluster-py-mpi/shared/`, idéntica a la de Abraham.

## Validación local

```bash
./verify.sh
mpirun --version
python3 -c "from mpi4py import MPI; print(MPI.Get_version())"
```

## Validación desde Abraham

Abraham debe poder ejecutar sin prompt de contraseña:

```bash
ssh andre.local "mpirun --version"
ssh andre.local "python3 -c 'from mpi4py import MPI; print(MPI.Get_version())'"
```

## Notas

- Mantén la **misma versión** de Open MPI que Abraham (`brew install openmpi`).
- No lances `mpirun` distribuido desde André; el maestro orquesta los jobs.
- No edites `shared/` mientras Abraham edita el mismo archivo al mismo tiempo — Syncthing crea un `.sync-conflict-*` si hay choque, resuélvelo manualmente.

## Checklist de aceptación

- [ ] Conectado a la misma red que Abraham
- [ ] `ping abraham.local` responde sin pérdida
- [ ] Open MPI y mpi4py instalados
- [ ] SSH sin contraseña desde Abraham, sin haber recibido `ssh-copy-id`
- [ ] Syncthing: carpeta `shared` "Up to Date"
- [ ] Carpeta `~/cluster-py-mpi/shared/` presente y sincronizando
- [ ] Versión MPI coincide con Abraham
```

- [ ] **Step 3: Sanity check both files have no leftover Alex/WSL2 references**

```bash
grep -il "alex\|wsl" Abraham/INSTRUCCIONES.md André/INSTRUCCIONES.md || echo "OK: sin referencias a Alex/WSL2"
```

Expected: `OK: sin referencias a Alex/WSL2`

---

### Task 6: Final repo-wide check

**Files:** none (verification only)

**Steps:**

- [ ] **Step 1: Confirm archive move preserved Alex's files**

```bash
ls archive/Alex/
```

Expected: `INSTRUCCIONES.md  install.sh  run-hello.sh  run-vector-sum.sh  setup-ssh.sh  verify.sh`

- [ ] **Step 2: Confirm no stray references to old IP-based hostfile pattern remain in active docs**

```bash
grep -rl "192.168" README.md Abraham/ André/ --include=*.md --include=*.sh 2>/dev/null || echo "OK: sin IPs fijas en flujo activo"
```

Expected: `OK: sin IPs fijas en flujo activo`

- [ ] **Step 3: Confirm all new/modified shell scripts are executable and syntactically valid**

```bash
for f in Abraham/setup-ssh.sh André/setup-ssh.sh Abraham/setup-syncthing.sh André/setup-syncthing.sh Abraham/verify.sh André/verify.sh; do
  bash -n "$f" && echo "OK: $f"
done
```

Expected: `OK: <path>` for each of the 6 files.

- [ ] **Step 4: Review full diff**

```bash
git status
git diff --stat
```

Expected: shows moved `Alex/` → `archive/Alex/`, modified README/INSTRUCCIONES/hostfile.example/verify.sh, new setup-ssh.sh (André)/setup-syncthing.sh (both).

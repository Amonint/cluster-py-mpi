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

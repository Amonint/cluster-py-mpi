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

# Abraham — Nodo maestro (macOS)

Abraham es el **nodo maestro** del clúster. Desde aquí se instala el stack MPI/Python, se configura SSH sin contraseña hacia los workers y se lanzan los jobs distribuidos.

## Rol

| Campo | Valor |
|---|---|
| Sistema | macOS |
| Rol | Maestro (orquestador MPI) |
| Workers | André (macOS), Alex (WSL2 Ubuntu) |

## Prerrequisitos

- macOS con acceso a terminal
- Conexión a red local con André y Alex
- IPs estáticas o reservadas en el router (editar `hostfile` con las IPs reales)

## Instalación (ejecutar en orden)

```bash
cd ~/cluster-py-mpi/Abraham
chmod +x install.sh verify.sh setup-ssh.sh run-hello.sh run-vector-sum.sh
./install.sh
./verify.sh
```

## Configuración SSH hacia workers

Edita las variables al inicio de `setup-ssh.sh` con el usuario e IP de cada worker, luego:

```bash
./setup-ssh.sh
```

Comandos manuales equivalentes:

```bash
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519 -q
ssh-copy-id -i ~/.ssh/id_ed25519.pub USUARIO@IP_ANDRE
ssh-copy-id -i ~/.ssh/id_ed25519.pub USUARIO@IP_ALEX
ssh USUARIO@IP_ANDRE hostname
ssh USUARIO@IP_ALEX hostname
```

## Sincronizar proyecto en todos los nodos

Copia la carpeta `shared/` a la misma ruta en cada nodo (`~/cluster-py-mpi/shared/`):

```bash
rsync -avz ../shared/ USUARIO@IP_ANDRE:~/cluster-py-mpi/shared/
rsync -avz ../shared/ USUARIO@IP_ALEX:~/cluster-py-mpi/shared/
```

## Configurar hostfile

Edita `hostfile` con las IPs reales de Abraham, André y Alex:

```txt
IP_ABRAHAM slots=2
IP_ANDRE slots=2
IP_ALEX slots=2
```

## Validación

```bash
./verify.sh
mpirun --version
python3 -c "from mpi4py import MPI; print(MPI.Get_version())"
ssh USUARIO@IP_ANDRE "mpirun --version"
ssh USUARIO@IP_ALEX "mpirun --version"
```

## Ejecutar programas MPI

Desde la carpeta `shared/`:

```bash
./run-hello.sh
./run-vector-sum.sh
```

O manualmente:

```bash
cd ../shared
mpirun -np 6 --hostfile ../Abraham/hostfile python3 hello_mpi.py
mpirun -np 6 --hostfile ../Abraham/hostfile python3 vector_sum.py
```

## Restricción de heterogeneidad

Open MPI **no garantiza** jobs MPI heterogéneos (macOS nativo + Linux/WSL2 en el mismo job). Para clase:

1. **Opción A (recomendada):** jobs solo entre nodos macOS (Abraham + André); Alex como worker alternativo en jobs Linux-only.
2. **Opción B:** los 3 nodos con la misma versión de Open MPI y pruebas incrementales; si falla con errores de tipo de datos, ejecutar solo en nodos homogéneos.

## Checklist de aceptación

- [ ] `brew install` completado sin errores
- [ ] `mpi4py` importa correctamente
- [ ] SSH sin contraseña a André y Alex
- [ ] `hostfile` con IPs correctas
- [ ] `hello_mpi.py` muestra 6 procesos en distintos hostnames
- [ ] `vector_sum.py` produce suma correcta

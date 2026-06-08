# André — Worker 1 (macOS)

André es un **nodo worker** macOS. Recibe conexiones SSH del maestro (Abraham) y ejecuta procesos MPI remotos.

## Rol

| Campo | Valor |
|---|---|
| Sistema | macOS |
| Rol | Worker 1 |
| Maestro | Abraham |

## Prerrequisitos

- macOS en la misma red local que Abraham y Alex
- Usuario con acceso SSH (Remote Login habilitado)

## Habilitar SSH (Remote Login)

```bash
sudo systemsetup -setremotelogin on
# o: Ajustes del Sistema > General > Compartir > Inicio de sesión remoto
```

## Instalación (ejecutar en orden)

```bash
cd ~/cluster-py-mpi/André
chmod +x install.sh verify.sh
./install.sh
./verify.sh
```

## Autorizar clave pública del maestro

Cuando Abraham ejecute `setup-ssh.sh`, tu clave quedará en `~/.ssh/authorized_keys`.

Verificación manual en André:

```bash
ls -la ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

Prueba desde Abraham:

```bash
ssh USUARIO@IP_ANDRE hostname
```

## Sincronizar carpeta shared

Desde Abraham (o copia manual):

```bash
mkdir -p ~/cluster-py-mpi/shared
# Abraham ejecutará: rsync -avz ../shared/ USUARIO@IP_ANDRE:~/cluster-py-mpi/shared/
```

La ruta debe ser **idéntica** en todos los nodos: `~/cluster-py-mpi/shared/`

## Validación local

```bash
./verify.sh
mpirun --version
python3 -c "from mpi4py import MPI; print(MPI.Get_version())"
```

## Validación desde el maestro

Abraham debe poder ejecutar:

```bash
ssh USUARIO@IP_ANDRE "mpirun --version"
ssh USUARIO@IP_ANDRE "python3 -c 'from mpi4py import MPI; print(MPI.Get_version())'"
```

## Notas

- Mantén la **misma versión** de Open MPI que Abraham (`brew install openmpi`).
- No lances `mpirun` distribuido desde André; el maestro orquesta los jobs.
- Jobs macOS-only (Abraham + André) son los más estables para prácticas iniciales.

## Checklist de aceptación

- [ ] Remote Login activo
- [ ] Open MPI y mpi4py instalados
- [ ] Clave pública de Abraham en `authorized_keys`
- [ ] SSH sin contraseña desde Abraham
- [ ] Carpeta `~/cluster-py-mpi/shared/` presente
- [ ] Versión MPI coincide con Abraham

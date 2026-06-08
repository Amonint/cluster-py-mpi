# Alex — Worker 2 (Windows 11 + WSL2 Ubuntu)

Alex es el **único nodo Windows**. Todo el stack MPI/Python corre **dentro de WSL2 Ubuntu**, no en Windows nativo.

## Rol

| Campo | Valor |
|---|---|
| Sistema | Windows 11 + WSL2 (Ubuntu) |
| Rol | Worker 2 |
| Maestro | Abraham |

## Prerrequisitos

- Windows 11 con WSL2 instalado
- Distribución Ubuntu en WSL2
- Acceso a red local desde WSL2 (puede requerir configuración extra de puerto/IP)

## Instalar WSL2 (si no existe)

En **PowerShell como administrador** (Windows):

```powershell
wsl --install -d Ubuntu
```

Reinicia si es necesario y crea usuario de Ubuntu.

## Instalación dentro de WSL2 Ubuntu

Abre terminal WSL2 (Ubuntu) y ejecuta:

```bash
cd ~/cluster-py-mpi/Alex
chmod +x install.sh verify.sh setup-ssh.sh
./install.sh
./verify.sh
./setup-ssh.sh
```

## Configurar SSH en WSL2

El script `setup-ssh.sh` instala y arranca `openssh-server`. Para acceso estable desde la red del laboratorio:

1. Obtén la IP de WSL2: `hostname -I`
2. Opcional: configura puerto fijo en `/etc/ssh/sshd_config` (ej. `Port 2222`)
3. En Windows, puede hacer falta reenvío de puerto (PowerShell admin):

```powershell
# Ejemplo: reenviar puerto 2222 de Windows hacia WSL2
netsh interface portproxy add v4tov4 listenport=2222 listenaddress=0.0.0.0 connectport=2222 connectaddress=IP_WSL2
```

4. Abraham debe usar la IP de Windows + puerto configurado para conectar a Alex.

## Autorizar clave del maestro

Abraham ejecutará `ssh-copy-id` hacia Alex. Verifica en WSL2:

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
# authorized_keys se llena desde Abraham
chmod 600 ~/.ssh/authorized_keys
```

## Sincronizar carpeta shared

```bash
mkdir -p ~/cluster-py-mpi/shared
```

Abraham sincroniza con:

```bash
rsync -avz -e "ssh -p PUERTO" ../shared/ USUARIO@IP_WINDOWS:~/cluster-py-mpi/shared/
```

## Validación local (WSL2)

```bash
./verify.sh
sudo service ssh status
mpirun --version
python3 -c "from mpi4py import MPI; print(MPI.Get_version())"
```

## Validación desde Abraham

```bash
ssh -p PUERTO USUARIO@IP_ALEX hostname
ssh -p PUERTO USUARIO@IP_ALEX "mpirun --version"
ssh -p PUERTO USUARIO@IP_ALEX "python3 -c 'from mpi4py import MPI; print(MPI.Get_version())'"
```

## Restricción de heterogeneidad

Alex (Linux/WSL2) puede fallar en jobs MPI **mixtos** con macOS (Abraham/André) por limitaciones de Open MPI en clusters heterogéneos. Usa Alex en:

- Jobs donde todos los procesos corran en entorno Linux homogéneo, o
- Pruebas SSH/conectividad antes de MPI distribuido mixto.

## Checklist de aceptación

- [ ] WSL2 Ubuntu funcional
- [ ] `openmpi-bin`, `libopenmpi-dev`, `mpi4py` instalados
- [ ] `openssh-server` activo
- [ ] SSH sin contraseña desde Abraham
- [ ] IP/puerto accesibles desde la red del laboratorio
- [ ] Carpeta `~/cluster-py-mpi/shared/` presente

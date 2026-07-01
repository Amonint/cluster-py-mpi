# cluster-py-mpi

Clúster universitario educativo con **Python + MPI + SSH**, 2 nodos macOS.

## Nodos

| Carpeta | Persona | Rol | Sistema |
|---|---|---|---|
| `Abraham/` | Abraham | **Maestro** | macOS |
| `André/` | André | Worker | macOS |

> El nodo de Alex (Windows/WSL2) salió del proyecto. Su configuración quedó en `archive/Alex/` como referencia, fuera del flujo activo.

## Estructura

```
cluster-py-mpi/
├── README.md
├── Abraham/          # Nodo maestro: hostfile, SSH, Syncthing, lanzamiento MPI
├── André/             # Worker macOS
├── archive/Alex/       # Referencia archivada, no usar
└── shared/             # Programas Python + carpeta sincronizada en tiempo real
    ├── hello_mpi.py
    └── vector_sum.py
```

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

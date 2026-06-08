# cluster-py-mpi

Clúster universitario educativo con **Python + MPI + SSH**.

## Nodos

| Carpeta | Persona | Rol | Sistema |
|---|---|---|---|
| `Abraham/` | Abraham | **Maestro** | macOS |
| `André/` | André | Worker 1 | macOS |
| `Alex/` | Alex | Worker 2 | Windows 11 + WSL2 |

## Estructura

```
cluster-py-mpi/
├── README.md
├── Abraham/          # Nodo maestro: hostfile, SSH, lanzamiento MPI
├── André/            # Worker macOS
├── Alex/             # Worker Windows/WSL2
└── shared/           # Programas Python comunes (misma ruta en todos los nodos)
    ├── hello_mpi.py
    └── vector_sum.py
```

## Inicio rápido

1. Copia este repositorio a cada PC en `~/cluster-py-mpi/`
2. Sigue `INSTRUCCIONES.md` en cada carpeta correspondiente
3. En Abraham: configura `hostfile`, SSH y ejecuta los jobs

## Orden recomendado

1. **André** y **Alex**: `./install.sh` + `./verify.sh`
2. **Alex**: `./setup-ssh.sh` (habilitar SSH en WSL2)
3. **Abraham**: `./install.sh` → `./setup-ssh.sh` → copiar `hostfile.example` a `hostfile`
4. Sincronizar `shared/` a todos los nodos
5. **Abraham**: `./run-hello.sh` y `./run-vector-sum.sh`

## Heterogeneidad Open MPI

No mezclar arquitecturas distintas en el mismo job MPI si se espera compatibilidad total. Para prácticas estables, priorizar jobs **macOS + macOS** (Abraham + André) antes de incluir Alex (Linux/WSL2).

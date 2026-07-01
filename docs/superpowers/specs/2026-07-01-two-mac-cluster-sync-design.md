# Clúster 2 Macs con sync en tiempo real — Diseño

Fecha: 2026-07-01
Estado: Aprobado, pendiente de plan de implementación

## Contexto

El proyecto original planteaba 3 nodos (Abraham maestro, André worker macOS, Alex worker Windows/WSL2). El nodo de Alex se eliminó del proyecto. Se necesita:

1. Rediseñar el clúster para 2 nodos macOS (Abraham + André), levantable en campus universitario.
2. Definir método de red entre los 2 Macs en campus (no hay control sobre la red del laboratorio).
3. Sincronización en tiempo real y bidireccional de la carpeta `shared/`: un cambio en un nodo debe reflejarse en el otro automáticamente.
4. Ningún paso de configuración debe requerir ingresar la contraseña de un Mac desde el otro, ni solicitar acceso remoto de esa forma. Toda credencial se gestiona localmente en cada máquina.

## Alcance

- Dentro: red del clúster, SSH sin contraseña, sync en tiempo real de `shared/`, ajuste de scripts/docs del repo a 2 nodos, criterios de validación.
- Fuera: contenido de los programas MPI en sí (`hello_mpi.py`, `vector_sum.py` ya existen y no cambian), CI/CD, nodos adicionales futuros.

## Arquitectura

```
      [Celular — Hotspot móvil]
                | WiFi
        ________|________
       |                 |
   [Abraham]          [André]
   Maestro MPI        Worker MPI
   Syncthing <----sync tiempo real----> Syncthing
```

Maestro-worker igual que el diseño original: Abraham orquesta `mpirun`, André solo ejecuta procesos remotos vía SSH. Se agrega una segunda malla de comunicación paralela (Syncthing) dedicada exclusivamente a mantener `shared/` idéntica en ambos nodos, independiente del flujo MPI.

## Red: hotspot móvil (elegido) + Ethernet/ICS como plan B

**Elegido — Hotspot móvil desde celular:**
- El celular crea una red WiFi propia (Ajustes → Compartir Internet / Hotspot).
- Ambos Macs se conectan a esa red.
- Ventajas: sin depender de políticas de la red universitaria (client isolation, VLANs, firewalls internos), portátil a cualquier punto del campus, setup en minutos.
- Riesgo: IP asignada por DHCP del celular puede cambiar entre sesiones. Mitigación: usar hostnames **mDNS/Bonjour `.local`** (`abraham.local`, `andre.local`) en vez de IPs fijas en hostfile y config SSH — resuelve automáticamente sin importar la IP actual.
- Riesgo secundario: consumo de datos/batería del celular. Aceptable para sesiones de laboratorio cortas.

**Plan B — Ethernet + Internet Sharing (macOS) desde el Maestro:**
- Abraham conectado por cable a la red universitaria, comparte conexión vía WiFi (Compartir Internet en Ajustes del Sistema), creando una subred local propia (normalmente `192.168.2.x` vía bridge).
- André se conecta a esa red WiFi compartida por Abraham.
- Se usa solo si el hotspot móvil no es viable (sin señal, sin datos, batería).
- Misma estrategia de hostnames `.local` aplica.

Ambos escenarios quedan documentados; el flujo de instalación asume hotspot móvil por defecto y marca el Plan B como alternativa con los mismos pasos posteriores (SSH, Syncthing, hostfile) sin cambios.

## SSH sin contraseña — sin credenciales cruzadas

Restricción explícita del usuario: nunca ingresar la contraseña de un Mac estando en el otro, ni usar mecanismos que soliciten ese acceso (se descarta `ssh-copy-id`, que exige la contraseña remota por SSH).

Flujo revisado, todo en orden secuencial y siempre acción local en la propia máquina:

1. En cada Mac, activar Remote Login localmente: `sudo systemsetup -setremotelogin on` (cada usuario en su propio equipo).
2. En cada Mac, generar su propio par de claves localmente: `ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519 -q` (nadie toca el equipo ajeno).
3. Compartir la clave pública (`~/.ssh/id_ed25519.pub`) entre los dos Macs vía **AirDrop**: transferencia nativa macOS que solo pide aceptar en pantalla, sin contraseña ni login remoto.
4. Cada usuario, en su propia máquina, agrega el `.pub` recibido a su propio `~/.ssh/authorized_keys` (`cat archivo_recibido.pub >> ~/.ssh/authorized_keys`, `chmod 600`).
5. Primera prueba `ssh andre.local hostname` desde Abraham (y viceversa) debe entrar sin prompt de password.

Este orden garantiza que el intercambio de confianza ocurre antes de cualquier intento de conexión SSH, evitando que macOS pida contraseña de cuenta del otro equipo en algún punto intermedio.

## Sincronización en tiempo real — Syncthing

- Instalación: `brew install syncthing` en ambos Macs.
- Ejecución como servicio local: `brew services start syncthing`.
- Emparejamiento: se agregan como dispositivos mutuos vía Device ID (mostrado en la UI local de Syncthing, `http://localhost:8384`) — se copia/escanea el ID, se acepta el par en pantalla en cada equipo. No requiere contraseña de cuenta del sistema operativo.
- Carpeta compartida: `shared/` (misma ruta relativa en ambos nodos), modo **Send & Receive** (bidireccional).
- Detección de cambios: FSEvents (nativo macOS vía Syncthing), propagación típica en segundos mientras ambos nodos estén en la misma red.
- Conflictos: si dos nodos editan el mismo archivo simultáneamente antes de sincronizar, Syncthing crea un archivo `.sync-conflict-*` en vez de sobrescribir — no hay pérdida de datos, pero requiere resolución manual ocasional (aceptable para uso educativo).
- Exclusiones: `.DS_Store`, `.stignore` en la carpeta compartida.
- Alternativa descartada: `fswatch` + `rsync` por script — unidireccional (habría que correr instancias en cada nodo con roles distintos), sin manejo de conflictos, más fràgil ante caídas de red del hotspot.

## Cambios al repositorio

- `Alex/` → mover a `archive/Alex/`, con nota en el README de que quedó fuera del flujo activo (no se borra por si se retoma a futuro).
- `README.md`: tabla de nodos reducida a Abraham (maestro) + André (worker), se quita la sección de heterogeneidad Windows/WSL2, se agrega sección de red (hotspot/plan B) y sync (Syncthing).
- `Abraham/hostfile.example`: IPs fijas reemplazadas por hostnames `.local` (`abraham.local`, `andre.local`).
- `Abraham/setup-ssh.sh`: reescrito para el flujo sin `ssh-copy-id` — genera clave local, imprime instrucciones de AirDrop, y solo prueba conexión al final (no copia claves de forma remota).
- `Abraham/INSTRUCCIONES.md` y `André/INSTRUCCIONES.md`: actualizadas con el nuevo flujo de red, SSH y Syncthing; quitan referencias a Alex/WSL2/puertos.
- Nuevo `Abraham/setup-syncthing.sh` (o guía en INSTRUCCIONES): pasos de instalación y emparejamiento de Syncthing (el emparejamiento inicial no es 100% scripteable por requerir aceptar el par en la UI, así que es guía + comandos de instalación/arranque).
- `run-hello.sh` / `run-vector-sum.sh`: sin cambios funcionales, ya son genéricos para N nodos vía hostfile.

## Metas previas a implementar (checklist)

1. Celular con hotspot activo y datos suficientes disponibles (o Ethernet + Internet Sharing como plan B ya viable en Abraham).
2. Homebrew instalado en ambos Macs.
3. Remote Login activo localmente en ambos Macs.
4. Confirmar resolución mDNS: `ping andre.local` desde Abraham y `ping abraham.local` desde André, ambos sin pérdida de paquetes.
5. AirDrop habilitado y probado entre ambos equipos (Wi-Fi + Bluetooth activos).

## Criterios de éxito

- Ping bidireccional entre `abraham.local` y `andre.local` sin pérdida de paquetes, en hotspot móvil.
- SSH sin contraseña en ambas direcciones (`ssh andre.local hostname`, `ssh abraham.local hostname`), sin haber usado `ssh-copy-id` ni ingresado password del otro equipo.
- Syncthing: ambos dispositivos en estado "Connected", carpeta `shared/` en estado "Up to Date" en ambos.
- Editar/crear un archivo en `shared/` en un Mac aparece en el otro Mac en segundos, sin acción manual, y viceversa.
- `mpirun -np N --hostfile hostfile python3 hello_mpi.py` imprime procesos desde ambos hostnames.
- `vector_sum.py` produce el resultado correcto ejecutado de forma distribuida entre los 2 nodos.

## Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| Hotspot cambia IP entre sesiones | Uso de hostnames `.local` (mDNS) en vez de IPs fijas |
| Batería/datos del celular se agotan a mitad de práctica | Documentar Plan B (Ethernet + Internet Sharing) con mismos pasos posteriores |
| Syncthing no sincroniza si ambos nodos no están en la misma red simultáneamente | Es esperado — Syncthing resincroniza automáticamente al reconectar, no requiere intervención |
| Edición simultánea del mismo archivo en `shared/` | Syncthing genera `.sync-conflict-*`, resolución manual documentada como paso normal |
| AirDrop no visible entre los 2 Macs | Checklist previo: confirmar Wi-Fi + Bluetooth activos y "Todos" en visibilidad AirDrop antes de la práctica |

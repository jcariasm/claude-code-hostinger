#!/usr/bin/env bash
# Sincronización BIDIRECCIONAL segura entre /root/workspace y Dropbox.
# Usa rclone bisync: lo que cambie en cualquiera de los dos lados se propaga al otro.
#
# Uso:
#   ./sync.sh            -> sincroniza una vez (manual / forzar)
#   ./sync.sh --daemon   -> bucle cada INTERVAL segundos
#   ./sync.sh --resync   -> reestablece la línea base (úsalo si bisync se queja)
P1="/root/workspace"
P2="dropbox:03 Resources/claude code hostinger"
INTERVAL="${SYNC_INTERVAL:-120}"   # segundos entre sincronizaciones
LOG="/root/workspace/.sync.log"
MARKER="/root/workspace/.bisync_baseline_done"

COMMON_OPTS=(
  --create-empty-src-dirs
  --conflict-resolve newer        # si el mismo archivo cambió en ambos lados, gana el más reciente
  --conflict-loser pathname       # y el perdedor se guarda con sufijo, nunca se pierde
  --exclude ".sync.log"
  --exclude ".bisync_baseline_done"
)

resync() {
  echo "[$(date '+%F %T')] RESYNC (línea base)" >> "$LOG"
  rclone bisync "$P1" "$P2" --resync "${COMMON_OPTS[@]}" >> "$LOG" 2>&1
  touch "$MARKER"
}

do_sync() {
  if [ ! -f "$MARKER" ]; then
    resync
    return
  fi
  if ! rclone bisync "$P1" "$P2" "${COMMON_OPTS[@]}" >> "$LOG" 2>&1; then
    echo "[$(date '+%F %T')] bisync falló -> intento resync de recuperación" >> "$LOG"
    resync
  else
    echo "[$(date '+%F %T')] bisync OK" >> "$LOG"
  fi
}

case "$1" in
  --daemon)
    echo "[$(date '+%F %T')] daemon bisync iniciado (cada ${INTERVAL}s)" >> "$LOG"
    while true; do do_sync; sleep "$INTERVAL"; done
    ;;
  --resync)
    echo "Reestableciendo línea base..."; resync; echo "Hecho. (log: $LOG)"
    ;;
  *)
    echo "Sincronizando (bidireccional) $P1 <-> $P2 ..."; do_sync; echo "Hecho. (log: $LOG)"
    ;;
esac

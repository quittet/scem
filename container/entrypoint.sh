#!/bin/bash
# Lance les deux serveurs d'epater :
#   - websocket (mainweb.py, port 31415) : le simulateur lui-même
#   - HTTP (http_server.py, port 8000)   : pages, statiques, exercices
# Si l'un des deux meurt, on arrête l'autre et on sort en erreur, pour que
# docker (restart policy) relance proprement le conteneur.
set -u
cd /app/epater

python mainweb.py &
WS_PID=$!
python /app/container/http_server.py &
HTTP_PID=$!

stop() {
    kill "$WS_PID" "$HTTP_PID" 2>/dev/null
    wait "$WS_PID" "$HTTP_PID" 2>/dev/null
    exit 0
}
trap stop TERM INT

wait -n
echo "scem: un des serveurs s'est arrêté, arrêt du conteneur." >&2
kill "$WS_PID" "$HTTP_PID" 2>/dev/null
wait
exit 1

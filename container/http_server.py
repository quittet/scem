"""Serveur HTTP d'epater pour le conteneur scem.

Upstream, hors mode DEBUG, mainweb.py ne lance que le serveur websocket et
attend qu'un serveur WSGI externe (Apache mod_wsgi...) serve wsgi.py.
Ce script joue ce rôle avec le serveur gevent embarqué dans bottle, exactement
comme le fait mainweb.http_server() en mode DEBUG, mais sans le mode debug.
"""
import os
import sys

EPATER_DIR = os.environ.get("EPATER_DIR", "/app/epater")
sys.path.insert(0, EPATER_DIR)
os.chdir(EPATER_DIR)

import bottle  # noqa: E402
from wsgi import application  # noqa: E402

if __name__ == "__main__":
    port = int(os.environ.get("EPATER_HTTP_PORT", "8000"))
    bottle.run(app=application, host="0.0.0.0", port=port, server="gevent", quiet=False)

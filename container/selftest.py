"""Auto-test de bout en bout du conteneur scem.

Se connecte au serveur websocket d'epater comme le ferait le navigateur,
assemble un petit programme ARM, l'exécute pas à pas et vérifie que
R2 = 4 + 11 = 15. Vérifie aussi que le serveur HTTP sert la page du simulateur.

Usage (depuis l'hôte) : docker exec epater python /app/container/selftest.py
Codes de sortie : 0 = OK, 1 = échec.
"""
import asyncio
import json
import os
import sys
import urllib.request

import websockets

HOST = os.environ.get("EPATER_HOST", "127.0.0.1")
HTTP_PORT = int(os.environ.get("EPATER_HTTP_PORT", "8000"))
WS_PORT = int(os.environ.get("EPATER_WS_PORT", "31415"))

PROGRAM = """SECTION INTVEC

B main

SECTION CODE

main
MOV R0, #4
MOV R1, #0xB
ADD R2, R0, R1
fin
B fin

SECTION DATA

"""


def check_http():
    url = "http://{}:{}/?sim=nouveau".format(HOST, HTTP_PORT)
    with urllib.request.urlopen(url, timeout=5) as resp:
        body = resp.read()
    assert resp.status == 200, "HTTP {}".format(resp.status)
    assert b"comm.js" in body, "la page du simulateur ne charge pas comm.js"
    print("HTTP  OK  {} ({} octets)".format(url, len(body)))


async def check_ws():
    uri = "ws://{}:{}/".format(HOST, WS_PORT)
    async with websockets.connect(uri) as ws:
        await ws.send(json.dumps(["assemble", PROGRAM, "fr"]))
        for _ in range(4):  # B main, MOV, MOV, ADD
            await ws.send(json.dumps(["stepinto"]))
        r2 = None
        deadline = asyncio.get_event_loop().time() + 10
        while asyncio.get_event_loop().time() < deadline and r2 != 15:
            try:
                raw = await asyncio.wait_for(ws.recv(), timeout=1)
            except asyncio.TimeoutError:
                continue
            for entry in json.loads(raw):
                if entry[0] in ("codeerror", "error"):
                    raise AssertionError("erreur simulateur : {}".format(entry))
                if entry[0] == "r2":
                    r2 = int(entry[1], 16)
        assert r2 is not None, "aucune mise à jour de registres reçue"
        assert r2 == 15, "R2 = {} au lieu de 15".format(r2)
        print("WS    OK  {} (R2 = 0x{:x})".format(uri, r2))


def main():
    try:
        check_http()
        asyncio.get_event_loop().run_until_complete(check_ws())
    except Exception as e:  # noqa: BLE001
        print("ECHEC : {}".format(e))
        sys.exit(1)
    print("scem : auto-test réussi.")


if __name__ == "__main__":
    main()

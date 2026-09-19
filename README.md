# scem — Simuler c'est mal

**scem** cryogenise [epater](https://github.com/mgard/epater), le simulateur
ARM web pédagogique, dans une image Docker autonome. Objectif : le déployer
sur n'importe quel Linux, aujourd'hui ou dans dix ans, sans se soucier des
versions de Python ni des dépendances.

## Contenu du dépôt

| Chemin | Rôle |
| --- | --- |
| `epater/` | Copie figée des sources upstream, non modifiées (commit dans `epater/UPSTREAM_COMMIT`, sans le dossier `doc/`). |
| `container/requirements.txt` | Dépendances Python épinglées (celles d'upstream + `polib` pour générer les traductions). |
| `container/http_server.py` | Serveur HTTP (bottle + gevent) qui sert `wsgi.py`, rôle tenu par Apache/mod_wsgi chez upstream. |
| `container/entrypoint.sh` | Lance le serveur websocket (`mainweb.py`, port 31415) et le serveur HTTP (port 8000). |
| `container/selftest.py` | Auto-test de bout en bout : assemble et exécute un programme ARM via le websocket. |
| `Dockerfile`, `docker-compose.yml`, `Makefile` | Construction, lancement et cryogénisation. |
| `exercices/` | Exercices maison, montés en volume dans le conteneur. |

## Prérequis

Docker (avec le plugin `compose`) et `make`. Rien d'autre.

## Utilisation

```sh
make build   # construit l'image scem/epater:latest
make run     # lance le conteneur en arrière-plan
make test    # vérifie que HTTP et websocket fonctionnent
make logs    # journaux
make stop    # arrêt
```

Le simulateur est ensuite disponible sur <http://localhost:8000/>.

Le navigateur ouvre lui-même `ws://<hôte>:31415/` (port codé en dur dans
`interface/static/js/comm.js`) : le port 31415 doit donc être publié tel quel,
et joignable depuis le poste client, pas seulement le 8000.

## Cryogénisation : déployer ailleurs sans reconstruire

```sh
make save                    # produit dist/scem-epater-latest.tar.gz
# copier l'archive et ce dépôt (au moins docker-compose.yml) sur la machine cible, puis :
make load
make run
```

L'archive contient l'image complète (Python 3.7, dépendances, sources). Elle
ne dépend d'aucun réseau ni d'aucun dépôt PyPI pour être relancée.

## Mettre à jour epater

Remplacer le contenu de `epater/` par une archive du commit voulu
(`git archive <commit> | tar -x -C epater`), mettre à jour
`epater/UPSTREAM_COMMIT`, reconstruire et relancer `make test`.

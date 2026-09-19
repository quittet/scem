# scem — epater cryogénisé

**scem** empaquette [epater](https://github.com/mgard/epater), le simulateur
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

## Choix techniques

- **Python 3.7** : dernière version pour laquelle toutes les dépendances
  épinglées par upstream (gevent 1.4.0, websockets 8.1, greenlet 0.4.15) ont
  des roues binaires. Monter de version oblige à revalider tout le simulateur.
- **Pas d'uvloop** : upstream le recommande, mais `mainweb.py` crée le serveur
  websocket avant de changer de boucle événementielle, ce qui plante avec
  websockets 8.1 (« got Future attached to a different loop »).
- **Mode non DEBUG** : hors DEBUG, epater tente d'envoyer les plantages par
  courriel seulement si `emailpass.txt` existe, ce qui n'est pas le cas dans
  l'image. Pour activer le mode privé, monter un `privepass.txt` dans
  `/app/epater/`.
- **Sources vendorisées** plutôt qu'un sous-module git : la reconstruction de
  l'image ne dépend pas de la disponibilité de GitHub.

## Mettre à jour epater

Remplacer le contenu de `epater/` par une archive du commit voulu
(`git archive <commit> | tar -x -C epater`), mettre à jour
`epater/UPSTREAM_COMMIT`, reconstruire et relancer `make test`.

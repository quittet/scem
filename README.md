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

## Intégrer des exercices

epater lit les exercices dans `/app/epater/exercices`, où `docker-compose.yml`
monte le dossier `exercices/` de ce dépôt en lecture seule. Il suffit donc d'y
déposer les fichiers puis de relancer le conteneur (`make stop && make run`) :
aucune reconstruction de l'image n'est nécessaire.

### Arborescence attendue

Le site a trois rubriques, chacune liée à un sous-dossier. Les rubriques
« Démo » et « Exercices formatifs » sont organisées en sections (un sous-dossier
par section) ; « Travaux pratiques » est une liste plate.

```
exercices/
├── accueil.html                 # contenu de la page d'accueil (optionnel)
├── prive.txt                    # exercices réservés au mode privé (optionnel)
├── demo/                        # rubrique « Démo »
│   └── <section>/
│       ├── nom.txt              # titre affiché de la section (optionnel)
│       └── <exercice>.html
├── exo/                         # rubrique « Exercices formatifs », même structure
│   └── <section>/
│       ├── nom.txt
│       └── <exercice>.html
└── tp/                          # rubrique « Travaux pratiques », sans sections
    └── <tp>.html
```

Les fichiers sont listés par ordre alphabétique de leur chemin : préfixer les
noms de dossiers et de fichiers d'un numéro (`01_Bases`, `02_Boucles`...)
permet de contrôler l'ordre. Sans `nom.txt`, le nom de la section est celui du
dossier, avec les `_` remplacés par des espaces.

### Format d'un exercice

Un exercice est un fichier HTML encodé en UTF-8, sans en-tête `<html>` ni
`<body>`, contenant :

- un `<h1>` : le titre affiché dans le menu (sinon, le nom du fichier) ;
- `<div id="enonce">` : l'énoncé, en HTML libre, affiché dans l'onglet Énoncé ;
- `<div id="code">` : le code ARM préchargé dans l'éditeur, en texte brut ;
- `<div id="solution">` : la solution, affichée dans l'onglet Solution.

Les trois `div` sont optionnels. Exemple minimal, à placer par exemple dans
`exercices/exo/01_Bases/addition.html` :

```html
<h1>Addition de deux registres</h1>
<div id="enonce"><p>Calculer R2 = R0 + R1.</p></div>
<div id="code">SECTION INTVEC

B main

SECTION CODE

main
MOV R0, #4
MOV R1, #0xB
fin
B fin

SECTION DATA

</div>
<div id="solution"><p>Ajouter <code>ADD R2, R0, R1</code> avant <code>fin</code>.</p></div>
```

Le code doit déclarer les sections `INTVEC`, `CODE` et `DATA`, sinon
l'assembleur refuse le programme. Attention aux caractères `<` et `&` dans le
code : les écrire `&lt;` et `&amp;`.

### Page d'accueil

Si `exercices/accueil.html` existe, son contenu remplace le message
« Bienvenue ! » de la page d'accueil.

### Mode privé

Pour cacher certains exercices (par exemple des sujets d'examen) tout en
pouvant les consulter soi-même :

1. lister leurs chemins, relatifs à `exercices/` et un par ligne, dans
   `exercices/prive.txt`, par exemple `exo/03_Examens/partiel.html` ;
2. créer un fichier `privepass.txt` contenant un mot de passe, et le monter
   dans le conteneur en ajoutant à `docker-compose.yml` :
   `- ./privepass.txt:/app/epater/privepass.txt:ro` ;
3. ouvrir `http://<hôte>:8000/?prive=<mot de passe>` : un cookie active alors
   le mode privé et les exercices masqués apparaissent.

Sans `privepass.txt`, les exercices listés dans `prive.txt` restent simplement
invisibles pour tout le monde.

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

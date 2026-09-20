# Surcharges de l'interface

Les fichiers de ce dossier sont copiés par-dessus `/app/epater` à la
construction de l'image (voir `Dockerfile`), sans modifier les sources
upstream dans `epater/`.

- `interface/index.html` : copie de l'original avec le titre de la page
  « R106 ARM Simulateur » à la place de « GIF-1001 -- OSA ». Pour vérifier
  qu'il n'y a pas d'autre écart : `diff epater/interface/index.html
  container/overlay/interface/index.html`.

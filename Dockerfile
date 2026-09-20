# scem : epater (simulateur ARM web) cryogénisé.
#
# Python 3.7 est la dernière version pour laquelle toutes les dépendances
# épinglées par epater (gevent 1.4.0, websockets 8.1...) existent en roues
# binaires précompilées. Ne pas monter de version sans re-tester.
FROM python:3.7-slim-bullseye

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

COPY container/requirements.txt /app/container/requirements.txt
RUN pip install -r /app/container/requirements.txt

COPY epater /app/epater
COPY container /app/container

# Personnalisations locales appliquées par-dessus les sources upstream
# (voir container/overlay/README.md).
COPY container/overlay /app/epater

# Catalogues de traduction (.mo), ignorés par git côté upstream.
RUN cd /app/epater && python utils/po2mo.py

# Répertoire d'exercices (absent du dépôt upstream), à monter en volume.
RUN mkdir -p /app/epater/exercices

EXPOSE 8000 31415
ENTRYPOINT ["/app/container/entrypoint.sh"]

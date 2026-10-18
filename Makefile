IMAGE   ?= scem/epater
TAG     ?= latest
DIST    ?= dist
ARCHIVE  = $(DIST)/scem-epater-$(TAG).tar.gz
EXAM_DIR = $(DIST)/examen
# Le div code est obligatoire : sans lui, mainweb.py plante à l'ouverture.
EXAM_PAGE = <h1>[mode examen]</h1><div id="enonce">[mode examen]</div><div id="code"></div>

.PHONY: help build run exam stop logs shell test save load clean

help:
	@echo "make build  : construit l'image $(IMAGE):$(TAG)"
	@echo "make run    : lance le conteneur (ports 8000 et 31415)"
	@echo "make exam   : lance le conteneur en mode examen (énoncés masqués)"
	@echo "make stop   : arrête le conteneur"
	@echo "make logs   : suit les journaux"
	@echo "make shell  : shell dans le conteneur en cours"
	@echo "make test   : auto-test de bout en bout du conteneur en cours"
	@echo "make save   : cryogénise l'image dans $(ARCHIVE)"
	@echo "make load   : recharge l'image depuis $(ARCHIVE) (sur une autre machine)"

build:
	docker build -t $(IMAGE):$(TAG) .

run:
	docker compose up -d

exam:
	rm -rf $(EXAM_DIR)
	cd exercices && find . -name '*.html' | while read -r f; do \
		mkdir -p "../$(EXAM_DIR)/$$(dirname "$$f")"; \
		echo '$(EXAM_PAGE)' > "../$(EXAM_DIR)/$$f"; \
	done
	echo '[mode examen]' > $(EXAM_DIR)/accueil.html
	docker compose -f docker-compose.yml -f docker-compose.exam.yml up -d

stop:
	docker compose down

logs:
	docker compose logs -f

shell:
	docker exec -it epater bash

test:
	docker exec epater python /app/container/selftest.py

save: build
	mkdir -p $(DIST)
	docker save $(IMAGE):$(TAG) | gzip > $(ARCHIVE)
	@ls -lh $(ARCHIVE)

load:
	gunzip -c $(ARCHIVE) | docker load

clean:
	rm -rf $(DIST)

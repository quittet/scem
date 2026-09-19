IMAGE   ?= scem/epater
TAG     ?= latest
DIST    ?= dist
ARCHIVE  = $(DIST)/scem-epater-$(TAG).tar.gz

.PHONY: help build run stop logs shell test save load clean

help:
	@echo "make build  : construit l'image $(IMAGE):$(TAG)"
	@echo "make run    : lance le conteneur (ports 8000 et 31415)"
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

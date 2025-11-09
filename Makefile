DC := docker compose
APP := app
DB := db

.PHONY: up down restart logs ps psql sh dbsh migrate seed backup restore health

up:
	$(DC) up -d --build

down:
	$(DC) down

restart:
	$(DC) restart $(APP)

logs:
	$(DC) logs -f $(APP)

ps:
	$(DC) ps

# psql in DB container
psql:
	$(DC) exec -it $(DB) psql -U $$POSTGRES_USER -d $$POSTGRES_DB

# shell into app container
sh:
	$(DC) exec -it $(APP) sh

# shell into db container
dbsh:
	$(DC) exec -it $(DB) bash

migrate:
	./scripts/migrate.sh

seed:
	./scripts/seed.sh

backup:
	./scripts/backup.sh

restore:
	@echo "Usage: make restore FILE=backups/backup_xxx.sql"; \
	if [ -z "$(FILE)" ]; then exit 1; fi; \
	./scripts/restore.sh "$(FILE)"

health:
	./scripts/ci_check.sh

# Makefile

SHELL := /usr/bin/env bash

GNUMAKEFLAGS ?=

MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --no-builtin-variables

.SHELLFLAGS := -Eeuo pipefail -c

.DELETE_ON_ERROR:
.SUFFIXES:
.NOTPARALLEL:

DEVCONTAINER_PROJECT := tooling-phpstan-devcontainer
DEVCONTAINER_FILTER := label=com.docker.compose.project=$(DEVCONTAINER_PROJECT)

# Default goal

.DEFAULT_GOAL := never

.PHONY: never
.SILENT: never
never:
	printf '%s\n' 'No default target. Run an explicit target' >&2
	exit 1

# Goals

.PHONY: fix
fix: eslint_fix prettier_fix

.PHONY: check
check: lint static audit

.PHONY: lint
lint: eslint_check prettier_check

.PHONY: static
static: composer_autoload_check

.PHONY: audit
audit: npm_audit composer_audit

.PHONY: deps_install
deps_install: npm_install composer_install

.PHONY: deps_update
deps_update: npm_update composer_update

.PHONY: clean
clean:

.PHONY: deps_clean
deps_clean:
	rm -rf ./node_modules
	rm -rf ./vendor

.PHONY: distclean
distclean: clean deps_clean

.PHONY: nuke
nuke: distclean data_reset

.PHONY: eslint_fix
eslint_fix: ./node_modules ./package.json ./package-lock.json ./eslint.config.js
	npm exec --ignore-scripts -- eslint --concurrency=auto --fix .

.PHONY: prettier_fix
prettier_fix: ./node_modules ./package.json ./package-lock.json ./prettier.config.js
	npm exec --ignore-scripts -- prettier -w .

.PHONY: eslint_check
eslint_check: ./node_modules ./package.json ./package-lock.json ./eslint.config.js
	npm exec --ignore-scripts -- eslint --concurrency=auto .

.PHONY: prettier_check
prettier_check: ./node_modules ./package.json ./package-lock.json ./prettier.config.js
	npm exec --ignore-scripts -- prettier -c .

.PHONY: npm_audit
npm_audit: ./node_modules ./package.json ./package-lock.json
	npm audit --ignore-scripts --audit-level=critical --install-links --include=prod --include=dev --include=peer --include=optional

.PHONY: composer_audit
composer_audit: ./vendor ./composer.json ./composer.lock
	composer audit --no-plugins --no-scripts
	composer check-platform-reqs --no-plugins --no-scripts
	composer validate --no-plugins --no-scripts --strict --with-dependencies --check-lock

.PHONY: composer_autoload_check
composer_autoload_check: ./vendor ./composer.json ./composer.lock
	composer dump-autoload --no-plugins --no-scripts --optimize --strict-psr --strict-ambiguous --dry-run

.PHONY: npm_install
npm_install: ./package.json ./package-lock.json
	npm ci --ignore-scripts --install-links --include=prod --include=dev --include=peer --include=optional

.PHONY: composer_install
composer_install: ./composer.json ./composer.lock
	composer install --no-plugins --no-scripts --no-autoloader
	composer dump-autoload --no-plugins --no-scripts --optimize --strict-psr --strict-ambiguous

.PHONY: npm_update
npm_update: ./package.json
	rm -rf ./node_modules
	npm update --ignore-scripts --install-links --include=prod --include=dev --include=peer --include=optional

.PHONY: composer_update
composer_update: ./composer.json
	rm -rf ./vendor
	composer update --no-plugins --no-scripts --no-autoloader --with-all-dependencies
	composer dump-autoload --no-plugins --no-scripts --optimize --strict-psr --strict-ambiguous

.PHONY: precreate
precreate:
	docker volume create tomaschochola-composer-cache
	docker volume create tomaschochola-npm-cache

.PHONY: postcreate
postcreate: deps_install

.PHONY: devcontainer
devcontainer:
	devcontainer up --workspace-folder .
	devcontainer exec --workspace-folder . /bin/bash

.PHONY: status
status:
	docker container ls --all --filter "$(DEVCONTAINER_FILTER)"
	docker volume ls --filter "$(DEVCONTAINER_FILTER)"
	docker network ls --filter "$(DEVCONTAINER_FILTER)"

.PHONY: stop
stop:
	docker container ls --quiet --filter "$(DEVCONTAINER_FILTER)" | while IFS= read -r container; do docker container stop "$$container"; done

.PHONY: restart
restart:
	docker container ls --all --quiet --filter "$(DEVCONTAINER_FILTER)" | while IFS= read -r container; do docker container restart "$$container"; done

.PHONY: down
down: stop
	docker container ls --all --quiet --filter "$(DEVCONTAINER_FILTER)" | while IFS= read -r container; do docker container rm --force --volumes "$$container"; done
	docker network ls --quiet --filter "$(DEVCONTAINER_FILTER)" | while IFS= read -r network; do docker network rm "$$network"; done

.PHONY: rebuild
rebuild: down
	devcontainer up --workspace-folder .

.PHONY: rebuild_no_cache
rebuild_no_cache: down
	devcontainer up --workspace-folder . --build-no-cache

.PHONY: data_reset
data_reset: down
	docker volume ls --quiet --filter "$(DEVCONTAINER_FILTER)" | while IFS= read -r volume; do docker volume rm "$$volume"; done

# Dependencies

./vendor: ./composer.json ./composer.lock
	${MAKE} composer_install

./node_modules: ./package.json ./package-lock.json
	${MAKE} npm_install

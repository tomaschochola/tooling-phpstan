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

# Default goal

.DEFAULT_GOAL := help

# Options

export DEBIAN_FRONTEND := noninteractive

# Goals

.PHONY: help
.SILENT: help
help:
	printf '\033[1m%s\033[0m\n' "$${PWD##*/} targets"
	printf '%s\n' '--------------------------------------------------------------------------------'
	printf '\033[1m%-23s\033[0m  %s\n' 'help' 'Show this help.'
	printf '\033[1m%-23s\033[0m  %s\n' 'fix' 'Run all automatic fixers.'
	printf '\033[1m%-23s\033[0m  %s\n' 'check' 'Run lint, static analysis, tests, and audits.'
	printf '\033[1m%-23s\033[0m  %s\n' 'lint' 'Run code style checks.'
	printf '\033[1m%-23s\033[0m  %s\n' 'static' 'Run static analysis.'
	printf '\033[1m%-23s\033[0m  %s\n' 'audit' 'Run dependency/security audits.'
	printf '\033[1m%-23s\033[0m  %s\n' 'deps_install' 'Install dependencies from current lock files.'
	printf '\033[1m%-23s\033[0m  %s\n' 'deps_update' 'Refresh dependencies and generated lock files.'
	printf '\033[1m%-23s\033[0m  %s\n' 'clean' 'Remove generated build, dependency, and test artifacts.'
	printf '\033[1m%-23s\033[0m  %s\n' 'distclean' 'Run clean and remove generated lock files.'
	printf '\033[1m%-23s\033[0m  %s\n' 'eslint_fix' 'Fix JavaScript/TypeScript lint issues with ESLint.'
	printf '\033[1m%-23s\033[0m  %s\n' 'prettier_fix' 'Format files with Prettier.'
	printf '\033[1m%-23s\033[0m  %s\n' 'eslint_check' 'Check JavaScript/TypeScript with ESLint.'
	printf '\033[1m%-23s\033[0m  %s\n' 'prettier_check' 'Check formatting with Prettier.'
	printf '\033[1m%-23s\033[0m  %s\n' 'npm_audit' 'Run npm audit at the configured severity level.'
	printf '\033[1m%-23s\033[0m  %s\n' 'composer_audit' 'Run Composer audit.'
	printf '\033[1m%-23s\033[0m  %s\n' 'composer_autoload_check' 'Validate Composer optimized autoload generation.'
	printf '\033[1m%-23s\033[0m  %s\n' 'npm_install' 'Install npm dependencies from package-lock.json.'
	printf '\033[1m%-23s\033[0m  %s\n' 'composer_install' 'Install Composer dependencies from composer.lock.'
	printf '\033[1m%-23s\033[0m  %s\n' 'npm_update' 'Refresh npm dependencies and package-lock.json.'
	printf '\033[1m%-23s\033[0m  %s\n' 'composer_update' 'Refresh Composer dependencies and composer.lock.'
	printf '\033[1m%-23s\033[0m  %s\n' 'precreate' 'Run pre-devcontainer setup hooks.'
	printf '\033[1m%-23s\033[0m  %s\n' 'postcreate' 'Run post-devcontainer setup hooks.'
	printf '\033[1m%-23s\033[0m  %s\n' 'devcontainer' 'Open a devcontainer shell, then stop the container.'

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
	rm -rf ./node_modules
	rm -rf ./vendor

.PHONY: distclean
distclean: clean
	rm -rf ./composer.lock
	rm -rf ./package-lock.json

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
	npm install --ignore-scripts --install-links --include=prod --include=dev --include=peer --include=optional

.PHONY: composer_install
composer_install: ./composer.json ./composer.lock
	composer install --no-plugins --no-scripts --no-autoloader
	composer dump-autoload --no-plugins --no-scripts --optimize --strict-psr --strict-ambiguous

.PHONY: npm_update
npm_update: ./package.json
	rm -rf ./node_modules
	rm -rf ./package-lock.json
	npm update --ignore-scripts --install-links --include=prod --include=dev --include=peer --include=optional

.PHONY: composer_update
composer_update: ./composer.json
	rm -rf ./vendor
	rm -rf ./composer.lock
	composer update --no-plugins --no-scripts --no-autoloader --with-all-dependencies
	composer dump-autoload --no-plugins --no-scripts --optimize --strict-psr --strict-ambiguous

.PHONY: precreate
precreate:
	docker volume create tomaschochola-composer-cache
	docker volume create tomaschochola-npm-cache

.PHONY: postcreate
postcreate: deps_install

.PHONY: devcontainer
devcontainer: precreate
	devcontainer up
	devcontainer exec /bin/bash || true
	docker ps -q --filter "label=devcontainer.local_folder=$${PWD}" | xargs -r docker stop

# Dependencies

./composer.lock ./vendor &: ./composer.json
	${MAKE} composer_update

./package-lock.json ./node_modules &: ./package.json
	${MAKE} npm_update

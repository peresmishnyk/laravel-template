# Makefile for managing the Docker environment

# Default shell for Makefile
SHELL := /bin/bash

# Get current user and group ID for Docker commands, if not set use 1000
UID := $(shell id -u)
GID := $(shell id -g)
USER := $(shell whoami)

# Docker Compose command
COMPOSE = docker compose

# Default target (executed when running `make` without arguments)
.DEFAULT_GOAL := help

# Variables for service names
APP_SERVICE_NAME = app

# Script content for setting HOST_DOCKER_GID is now in .get_docker_gid.sh

# Phony targets (targets that are not files)
.PHONY: init up down restart build logs shell composer npm test cache-clear permissions help full-reset

# Variables
DOCKER_COMPOSE := docker compose
APP_CONTAINER := app
PHP_ARTISAN := $(DOCKER_COMPOSE) exec $(APP_CONTAINER) php artisan
COMPOSER := $(DOCKER_COMPOSE) exec $(APP_CONTAINER) composer
NPM := $(DOCKER_COMPOSE) exec $(APP_CONTAINER) npm

init: ## Initialize project: copy .env, build images, start services
	@echo "Initializing project..."
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
	fi
	@ln -sf .env env
	@ln -sf .env.example env.example
	$(DOCKER_COMPOSE) build
	$(DOCKER_COMPOSE) up -d
	$(PHP_ARTISAN) key:generate
	$(PHP_ARTISAN) storage:link
	$(COMPOSER) install
	$(NPM) install
	@echo "Project initialized! Access at http://localhost"

up: ## Start all services
	$(DOCKER_COMPOSE) up -d

down: ## Stop all services
	$(DOCKER_COMPOSE) down

restart: down up ## Restart all services

build: ## Rebuild all services
	$(DOCKER_COMPOSE) build

logs: ## View logs of all services
	$(DOCKER_COMPOSE) logs -f

shell: ## Access app container shell
	$(DOCKER_COMPOSE) exec $(APP_CONTAINER) sh

composer: ## Run Composer command (e.g., make composer require package)
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "Usage: make composer require package-name"; \
		exit 1; \
	fi
	$(COMPOSER) $(filter-out $@,$(MAKECMDGOALS))

npm: ## Run NPM command (e.g., make npm install)
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "Usage: make npm install"; \
		exit 1; \
	fi
	$(NPM) $(filter-out $@,$(MAKECMDGOALS))

test: ## Run tests
	$(PHP_ARTISAN) test

cache-clear: ## Clear all Laravel caches
	$(PHP_ARTISAN) optimize:clear

permissions: ## Fix storage permissions
	$(DOCKER_COMPOSE) exec -u root $(APP_CONTAINER) chown -R www-data:www-data /var/www/storage
	$(DOCKER_COMPOSE) exec -u root $(APP_CONTAINER) chmod -R 775 /var/www/storage

help: ## Show this help
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

full-reset: ## !! DANGEROUS !! Stash all changes (including untracked), hard reset, and reinitialize
	@echo "WARNING: This will stash all changes, perform git reset --hard, and reset the environment completely!"
	@echo "-----------------------------------------------------"
	@echo "\n--- Step 1: Stashing current changes (including untracked files) ---"
	@BRANCH_NAME=$$(git rev-parse --abbrev-ref HEAD); \
	DATETIME=$$(date +'%Y-%m-%d %H:%M:%S'); \
	STASH_MESSAGE="Auto-stash before full-reset on branch '$$BRANCH_NAME' at $$DATETIME"; \
	if ! git diff --staged --quiet || ! git diff --quiet || [ -n "$$(git ls-files --others --exclude-standard)" ]; then \
		git stash push -u -m "$$STASH_MESSAGE"; \
		echo "Changes stashed with message: '$$STASH_MESSAGE'"; \
	else \
		echo "No changes to stash."; \
	fi

	@echo "\n--- Step 2: Performing git reset --hard ---"
	@git reset --hard HEAD
	@echo "Git repository reset to HEAD."

	@echo "\n--- Step 3: Stopping and removing Docker containers ---"
	$(MAKE) down

	@echo "\n--- Step 4: Removing environment files and symlinks ---"
	@rm -f .env
	@rm -f env
	@rm -f env.example

	@echo "\n--- Step 5: Reinitializing project ---"
	$(MAKE) init

	@echo "\n-----------------------------------------------------"
	@echo "Full reset complete! Your environment has been rebuilt."
	@echo "To recover stashed changes:"
	@echo "1. git stash list - to see your stashes"
	@echo "2. git stash apply - to apply the latest stash"
	@echo "3. git stash drop - to remove the applied stash"
	@echo "-----------------------------------------------------"

%:
	@:

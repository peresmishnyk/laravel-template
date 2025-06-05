.DEFAULT_GOAL := help
.PHONY: init up down stop restart build logs logs-app ps shell artisan composer npm test clear-cache permissions help full-reset

# Variables
DOCKER_COMPOSE := docker compose
APP_CONTAINER_NAME := laravel_app # Matches container_name in docker-compose.yml
PHP_ARTISAN := $(DOCKER_COMPOSE) exec $(APP_CONTAINER_NAME) php artisan
COMPOSER_CMD := $(DOCKER_COMPOSE) exec $(APP_CONTAINER_NAME) composer
NPM_CMD := $(DOCKER_COMPOSE) exec $(APP_CONTAINER_NAME) npm

init: ## Initialize project: Setup .env & symlinks, build images, start services, generate APP_KEY, link storage.
	@echo "Initializing project..."

	@echo "\n--- Step 1: Setting up .env file ---"
	@if [ ! -f .env ]; then \
		echo "'.env' file not found. Copying from '.env.example'..."; \
		cp .env.example .env; \
		echo "'.env' created from '.env.example'. Please review and update if necessary."; \
	else \
		echo "'.env' file already exists."; \
	fi

	@echo "\n--- Step 2: Creating/updating symlinks ---"
	@ln -sf .env env
	@ln -sf .env.example env.example
	@echo "Symlinks ensured: 'env' -> '.env', 'env.example' (symlink) -> '.env.example' (file)"

	@echo "\n--- Step 3: Building Docker images for all services ---"
	$(DOCKER_COMPOSE) build

	@echo "\n--- Step 4: Starting all Docker services ---"
	$(DOCKER_COMPOSE) up -d --remove-orphans

	@echo "\n--- Step 5: Ensuring APP_KEY is set in .env ---"
	@if [ -f .env ] && ! grep -q "^APP_KEY=[^[:space:]].*" .env; then \
		echo "APP_KEY is missing or empty in '.env'. Generating APP_KEY..."; \
		$(PHP_ARTISAN) key:generate; \
		echo "APP_KEY generated successfully."; \
	elif [ ! -f .env ]; then \
		echo "Error: '.env' file not found. Cannot generate APP_KEY. This should not happen after Step 1."; \
	else \
		echo "APP_KEY already exists and is non-empty in '.env'. Skipping automatic generation."; \
	fi
	@echo "To manually regenerate the key later, run 'make artisan key:generate'."

	@echo "\n--- Step 6: Creating storage symlink ---"
	$(PHP_ARTISAN) storage:link
	@echo "Storage symlink created (or already exists)."

	@echo "\nInitialization complete! Project is building and starting."
	@echo "Access your application at http://localhost (or as configured in APP_URL in .env) once services are up."

up: ## Start services in detached mode
	@echo "Starting Docker services..."
	$(DOCKER_COMPOSE) up -d --remove-orphans

down: ## Stop services
	@echo "Stopping Docker services..."
	$(DOCKER_COMPOSE) down

stop: down ## Alias for down

restart: ## Restart services
	@echo "Restarting Docker services..."
	$(MAKE) down
	$(MAKE) up

build: ## Build or rebuild services
	@echo "Building Docker images..."
	$(DOCKER_COMPOSE) build

logs: ## Follow logs of all services
	@echo "Following Docker logs..."
	$(DOCKER_COMPOSE) logs -f

logs-app: ## Follow logs of the app service
	@echo "Following $(APP_CONTAINER_NAME) logs..."
	$(DOCKER_COMPOSE) logs -f $(APP_CONTAINER_NAME)

ps: ## List running containers
	@echo "Listing Docker containers..."
	$(DOCKER_COMPOSE) ps

shell: ## Access the app container's shell (sh)
	@echo "Accessing $(APP_CONTAINER_NAME) container shell..."
	$(DOCKER_COMPOSE) exec $(APP_CONTAINER_NAME) sh

bash: ## Access the app container's shell (bash, if available)
	@echo "Accessing $(APP_CONTAINER_NAME) container shell (bash)..."
	$(DOCKER_COMPOSE) exec $(APP_CONTAINER_NAME) bash

artisan: ## Run an Artisan command (e.g., make artisan migrate)
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "Please provide an Artisan command. Example: make artisan migrate"; \
		exit 1; \
	fi
	@echo "Running Artisan command: $(filter-out $@,$(MAKECMDGOALS))"
	$(PHP_ARTISAN) $(filter-out $@,$(MAKECMDGOALS))

composer: ## Run a Composer command (e.g., make composer install)
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "Please provide a Composer command. Example: make composer install"; \
		exit 1; \
	fi
	@echo "Running Composer command: $(filter-out $@,$(MAKECMDGOALS))"
	$(COMPOSER_CMD) $(filter-out $@,$(MAKECMDGOALS))

npm: ## Run an npm command (e.g., make npm install, make npm run build)
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "Please provide an npm command. Example: make npm install or make npm run build"; \
		exit 1; \
	fi
	@echo "Running npm command: $(filter-out $@,$(MAKECMDGOALS))"
	$(NPM_CMD) $(filter-out $@,$(MAKECMDGOALS))

test: ## Run PHPUnit tests
	@echo "Running PHPUnit tests..."
	$(PHP_ARTISAN) test

clear-cache: ## Clear Laravel caches
	@echo "Clearing Laravel caches..."
	$(PHP_ARTISAN) optimize:clear
	$(PHP_ARTISAN) cache:clear
	$(PHP_ARTISAN) config:clear
	$(PHP_ARTISAN) route:clear
	$(PHP_ARTISAN) view:clear

permissions: ## Set correct permissions for storage and bootstrap/cache (runs as root)
	@echo "Setting permissions for storage and bootstrap/cache..."
	$(DOCKER_COMPOSE) exec -u root $(APP_CONTAINER_NAME) chown -R laravel:laravel /var/www/html/storage /var/www/html/bootstrap/cache
	$(DOCKER_COMPOSE) exec -u root $(APP_CONTAINER_NAME) chmod -R ug+w /var/www/html/storage /var/www/html/bootstrap/cache
	@echo "Permissions set."

full-reset: ## !! DANGEROUS !! Stash changes, hard reset git, FULLY recreate Docker env (volumes, networks), re-init.
	@echo "WARNING: This will stash uncommitted changes, hard reset your current branch, delete Docker volumes, and re-initialize the project."
	@echo "Proceed with caution!"
	@echo "-----------------------------------------------------"

	@echo "\n--- Step 1: Stashing current changes (including untracked files) ---"
	@BRANCH_NAME=$$$(git rev-parse --abbrev-ref HEAD); \
	DATETIME=$$$(date +'%Y-%m-%d %H:%M:%S'); \
	STASH_MESSAGE="Auto-stash before full-reset on branch '$${BRANCH_NAME}' at $${DATETIME}"; \
	git add .; \
	if ! git diff --staged --quiet || ! git diff --quiet || [ -n "$$$(git ls-files --others --exclude-standard)" ]; then \
		git stash push -u -m "$${STASH_MESSAGE}"; \
		echo "Changes stashed with message: '$${STASH_MESSAGE}'"; \
	else \
		echo "No changes to stash."; \
	fi

	@echo "\n--- Step 2: Performing git reset --hard HEAD ---"
	@git reset --hard HEAD
	@echo "Git repository reset to HEAD."

	@echo "\n--- Step 3: Stopping and removing Docker containers, volumes, and orphaned images ---"
	$(DOCKER_COMPOSE) down -v --remove-orphans
	@echo "Docker environment cleaned."

	@echo "\n--- Step 4: Removing symlinks env and env.example ---"
	@rm -f env
	@rm -f env.example
	@echo "Symlinks env and env.example removed."

	@echo "\n--- Step 5: Re-initializing project with 'make init' ---"
	$(MAKE) init

	@echo "\n-----------------------------------------------------"
	@echo "Full reset complete! Your environment has been rebuilt."

help: ## Display this help screen
	@echo "Available commands:"
	@grep -E '^[a-zA-Z0-9_%/-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

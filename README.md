# Laravel Docker Template

This project is a template for quickly starting Laravel application development using Docker. It includes a configured environment with PHP, Nginx, MySQL, and Redis, as well as a Makefile to simplify project management.

## Requirements

*   **Docker** and **Docker Compose**: Ensure they are installed and running on your system. ([Docker Installation Guide](https://docs.docker.com/get-docker/))
*   **Make**: The `make` utility must be installed. It is usually available on most *nix systems. For Windows, you can use `make` from WSL or similar tools.
*   **Git**: For cloning the repository and version control.

## Getting Started

1.  **Clone the repository**:
    ```bash
    git clone <YOUR_REPOSITORY_URL> my-laravel-project
    cd my-laravel-project
    ```

2.  **Initialize the project**:
    This command will perform all necessary steps for the first run: create the `.env` file from `env.example`, build Docker images, start containers, and generate the application key (`APP_KEY`).
    ```bash
    make init
    ```
    After this command, your application should be available at `http://localhost` (or the `APP_URL` value from your `.env` file).

3.  **(Optional) Install Composer dependencies if this is not the first `make init` or if you have manually added new packages:**
    ```bash
    make composer install
    ```

4.  **(Optional) Run database migrations:**
    ```bash
    make artisan migrate
    ```

## Environment File `.env`

When you run `make init`, the `.env` file is automatically created from `env.example`.
The `env.example` file is already configured to work with the Docker services defined in `docker-compose.yml`:
*   Database: MySQL, host `db`, port `3306`.
*   Redis: host `redis`, port `6379`.
*   Session, cache, and queue drivers are configured to use `redis`.

You can edit `.env` to change these settings, such as the database name, user, password (it is recommended to change the default password `password` to a more secure one). After changing `.env`, you may need to restart the containers (`make restart`).

## Available `make` commands

Below is a list of commands available via `Makefile`. You can also run `make help` in the terminal to see this list.

*   `make init`
    *   **Description**: Initializes the project: sets up `.env` and symlinks, builds images, starts services, generates `APP_KEY`, and creates the storage symlink (`storage:link`).
    *   **When to use**: On the first project run or after `make full-reset`.

*   `make up`
    *   **Description**: Starts services in detached mode.
    *   **When to use**: To start stopped Docker containers.

*   `make down` (or `make stop`)
    *   **Description**: Stops services.
    *   **When to use**: To stop Docker containers.

*   `make restart`
    *   **Description**: Restarts services (equivalent to `make down && make up`).
    *   **When to use**: If you need to restart all containers, for example, after configuration changes.

*   `make build`
    *   **Description**: Builds or rebuilds services.
    *   **When to use**: If you have changed `Dockerfile` or other files affecting image builds.

*   `make logs`
    *   **Description**: Shows logs of all services in real-time.
    *   **When to use**: To monitor the operation of all containers.

*   `make logs-app`
    *   **Description**: Shows logs of the application service (`laravel_app`) in real-time.
    *   **When to use**: To specifically monitor your Laravel application logs.

*   `make ps`
    *   **Description**: Lists running containers.
    *   **When to use**: To check the status of Docker containers.

*   `make shell`
    *   **Description**: Accesses the `sh` shell of the application container.
    *   **When to use**: To execute commands inside the application container (e.g., `php -v`).

*   `make bash`
    *   **Description**: Accesses the `bash` shell of the application container (if `bash` is installed in the container).
    *   **When to use**: Similar to `make shell`, but using `bash`.

*   `make artisan [artisan_command]`
    *   **Description**: Executes the specified Artisan command inside the application container.
    *   **Example**: `make artisan migrate`, `make artisan queue:work`, `make artisan make:controller MyController`
    *   **When to use**: To run any Laravel Artisan commands.

*   `make composer [composer_command]`
    *   **Description**: Executes the specified Composer command inside the application container.
    *   **Example**: `make composer install`, `make composer update`, `make composer require laravel/sanctum`
    *   **When to use**: To manage PHP dependencies.

*   `make npm [npm_command]`
    *   **Description**: Executes the specified npm command inside the application container. This is useful for managing JavaScript dependencies and building frontend assets.
    *   **Example**: `make npm install`, `make npm run build`, `make npm run dev`
    *   **When to use**: To install npm packages, build assets (e.g., with Vite, as in the `make npm run build` command), or run the Vite development server (`make npm run dev`).

*   `make test`
    *   **Description**: Runs PHPUnit tests.
    *   **When to use**: To run automated tests for your application.

*   `make clear-cache`
    *   **Description**: Clears various Laravel caches (optimize, cache, config, route, view).
    *   **When to use**: If you encounter caching-related issues.

*   `make permissions`
    *   **Description**: Sets correct permissions for `storage` and `bootstrap/cache` directories inside the application container. Runs as `root`.
    *   **When to use**: If there are write permission issues in these directories.

*   `make full-reset`
    *   **Description**: !! DANGEROUS COMMAND !! Stashes uncommitted changes, runs `git reset --hard HEAD` (resetting all changes in the working directory to the last commit), COMPLETELY recreates the Docker environment (including deleting all Docker volumes, which means **loss of DB data**), removes `env` and `env.example` symlinks, and then re-initializes the project using `make init`.
    *   **When to use**: When you need to completely "reset" the project and start fresh, for example, in case of serious environment problems or to test the initialization process. **Use with extreme caution!** Stashed changes can be recovered from `git stash`.

*   `make help`
    *   **Description**: Displays the help screen with a list of all available `make` commands.

## Development

*   **Your Laravel application code** is in the standard directories (`app`, `routes`, `resources`, etc.).
*   **Docker files** are in the `docker/` directory (`Dockerfile`, `php/local.ini`, `nginx/default.conf`) and in the project root (`docker-compose.yml`).
*   **Nginx configuration** is in `docker/nginx/default.conf`.
*   **PHP configuration** can be extended in `docker/php/local.ini`.

## Troubleshooting

*   **Permission issues**: Try running `make permissions`.
*   **Application not working after changes**: Check logs using `make logs` or `make logs-app`.
*   **Unexpected behavior**: Try clearing the cache with `make clear-cache`.
*   **If nothing else helps**: Consider `make full-reset`, but remember the loss of data in Docker volumes (e.g., in the database).

---

We hope this template helps you get started quickly on your next Laravel project!

# Laravel Template Project

A template for quick deployment of Laravel projects with Docker. Includes a configured development environment with PHP 8.2, MySQL 8.0, Redis for queues, and Memcached for caching.

## Requirements

- Docker
- Docker Compose
- Make

## Project Structure

```
laravel-tpl/
├── app/                  # Application code
├── bootstrap/           # Autoload files
├── config/             # Configuration files
├── database/           # Migrations and seeds
├── docker/             # Docker configuration
│   ├── app/           # PHP-FPM configuration
│   └── nginx/         # Nginx configuration
├── public/            # Public directory
├── resources/         # Views, CSS, JS
├── routes/            # Application routes
├── storage/           # Application files
└── tests/             # Tests
```

## Quick Start

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/laravel-tpl.git
   cd laravel-tpl
   ```

2. Initialize the project:
   ```bash
   make init
   ```
   This will:
   - Create `.env` file from `.env.example`
   - Build Docker containers
   - Install Composer and NPM dependencies
   - Generate application key
   - Create storage symlink

## Available Make Commands

- `make up` - Start all services
- `make down` - Stop all services
- `make restart` - Restart all services
- `make build` - Rebuild containers
- `make logs` - View logs
- `make shell` - Access app container shell
- `make composer` - Run Composer commands
- `make npm` - Run NPM commands
- `make test` - Run tests
- `make cache-clear` - Clear all Laravel caches
- `make permissions` - Fix storage permissions

## Services

- **PHP-FPM (8.2)**
  - Container: laravel_app
  - Port: 9000 (internal)

- **Nginx**
  - Container: laravel_nginx
  - Port: 8080

- **MySQL**
  - Container: laravel_db
  - Port: 3306
  - Data persisted in Docker volume

- **Redis (for queues)**
  - Container: laravel_redis
  - Port: 6379

- **Memcached (for caching)**
  - Container: laravel_memcached
  - Port: 11211

## Development

1. Start services:
   ```bash
   make up
   ```

2. Access container shell:
   ```bash
   make shell
   ```

3. Install new packages:
   ```bash
   make composer require package-name
   ```

4. Frontend development:
   ```bash
   make npm install
   make npm run dev
   ```

## Testing

```bash
make test
```

## Cache Management

```bash
make cache-clear
```

## Additional Information

- All Docker configurations are in the `docker/` directory
- PHP settings can be modified in `docker/app/php/conf.d/`
- Nginx settings are in `docker/nginx/`

## License

MIT

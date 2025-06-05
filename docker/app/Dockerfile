FROM php:8.2-fpm

# Arguments defined in docker-compose.yml
ARG user
ARG uid
ARG DOCKER_GID

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    libzip-dev \
    libpq-dev \
    supervisor \
    cron \
    libmemcached-dev \
    zlib1g-dev \
    redis-tools

# Install Docker CLI (client only, no daemon)
RUN apt-get update && apt-get install -y --no-install-recommends curl docker.io

# Add Docker group and add www-data to it
# This needs to be done before www-data might need to use Docker commands.
# It also assumes www-data is the user PHP-FPM runs as (default for php:fpm images).
RUN apt-get update && apt-get install -y bc && \
    DOCKER_SOCKET_GID_ON_IMAGE=$(getent group docker | cut -d: -f3 || echo "not_found") && \
    TARGET_GID_HOLDER=$(getent group ${DOCKER_GID} | cut -d: -f1 || echo "none") && \
    echo "Target DOCKER_GID: ${DOCKER_GID}" && \
    echo "Current 'docker' group GID on image: ${DOCKER_SOCKET_GID_ON_IMAGE}" && \
    echo "Group holding target GID '${DOCKER_GID}': ${TARGET_GID_HOLDER}" && \
    if [ "${TARGET_GID_HOLDER}" != "none" ] && [ "${TARGET_GID_HOLDER}" != "docker" ]; then \
        echo "Warning: Target GID ${DOCKER_GID} is held by '${TARGET_GID_HOLDER}'. Attempting to delete '${TARGET_GID_HOLDER}'." ; \
        delgroup ${TARGET_GID_HOLDER} || echo "Failed to delete group ${TARGET_GID_HOLDER} or it did not exist." ; \
    fi && \
    if [ "${DOCKER_SOCKET_GID_ON_IMAGE}" != "not_found" ] && [ ! "${DOCKER_SOCKET_GID_ON_IMAGE}" -eq "${DOCKER_GID}" ]; then \
        echo "Deleting existing 'docker' group with GID ${DOCKER_SOCKET_GID_ON_IMAGE}." ; \
        delgroup docker || echo "Failed to delete existing docker group or it did not exist." ; \
        echo "Creating new 'docker' group with GID ${DOCKER_GID}." ; \
        addgroup --gid ${DOCKER_GID} docker ; \
    elif [ "${DOCKER_SOCKET_GID_ON_IMAGE}" = "not_found" ]; then \
        echo "Creating 'docker' group with GID ${DOCKER_GID}." ; \
        addgroup --gid ${DOCKER_GID} docker ; \
    else \
        echo "'docker' group already exists with correct GID ${DOCKER_GID}." ; \
    fi && \
    usermod -aG docker www-data && \
    echo "User www-data added to docker group. Verification: $(id www-data)" && \
    echo "Docker group details: $(getent group docker)"

# Install Node.js and npm
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
RUN apt-get install -y nodejs

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip sockets opcache

# Install Redis extension
RUN pecl install redis-5.3.7 && docker-php-ext-enable redis

# Install Memcached extension
RUN pecl install memcached && docker-php-ext-enable memcached

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Create system user to run Composer and Artisan Commands
RUN useradd -G www-data,root -u $uid -d /home/$user $user
RUN mkdir -p /home/$user/.composer && \
    chown -R $user:$user /home/$user

# Set working directory
WORKDIR /var/www

# Copy cron file to the cron.d directory
COPY cron/laravel-scheduler /etc/cron.d/laravel-scheduler

# Give execution rights on the cron job
RUN chmod 0644 /etc/cron.d/laravel-scheduler
# Ensure crontab is applied by the cron daemon, not strictly necessary for cron.d files but good for completeness
# RUN crontab /etc/cron.d/laravel-scheduler

# Copy supervisor config
COPY supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

USER root

# Expose port 9000 and start php-fpm server
EXPOSE 9000
ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# For development, we might just want to keep the container running
# CMD ["tail", "-f", "/dev/null"]

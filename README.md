# DockTales 🐳

> Docker development environment - simple, fast, and enjoyable!

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

DockTales is a lightweight and user-friendly Docker environment manager designed for web developers. It allows you to configure and manage containers with minimal effort, making Docker work as simple as possible.

## 🚀 Features

- Quick development environment setup via `.env` file
- Easily switch between **PHP**, **MySQL**, and other service versions
- Optional **Redis** and other services integration
- Automatic SSL certificate configuration for local development
- Simple command interface for everyday use
- Unified project structure for better organization

## 🔧 Prerequisites

- Docker Engine
- Docker Compose

## ⚡ Quick Start

1. Clone this repository:
   ```bash
   git clone https://github.com/anik1ng/docktales.git
   cd docktales
   ```

2. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

3. Edit the `.env` file to customize your environment.

4. Start the environment:
   ```bash
   ./app/bin/dev.sh start
   ```

5. Your development environment is now running! Access it at:
   ```
   https://your-configured-domain
   ```

## 🧩 Configuration

DockTales is configured through the `.env` file with variables like:

```
# Project settings
PROJECT_NAME=myproject
DOMAIN_NAME=myproject.test

# Service versions
PHP_VERSION=8.3
MYSQL_VERSION=8.0
NGINX_VERSION=1.25
NODE_VERSION=22-alpine

# Database settings
DB_DATABASE=myproject
DB_USERNAME=root
DB_PASSWORD=password
DB_PORT=3306

# Optional services
USE_REDIS=false
REDIS_VERSION=7.0
```

## 📋 Available Commands

- `./app/bin/dev.sh start` - Start all containers (with auto-initialization)
- `./app/bin/dev.sh stop` - Stop all containers
- `./app/bin/dev.sh restart` - Restart all containers
- `./app/bin/dev.sh status` - Show status of all containers
- `./app/bin/dev.sh logs` - Show logs from all containers
- `./app/bin/dev.sh rebuild` - Rebuild and restart all containers
- `./app/bin/dev.sh help` - Show help menu

## 🗂️ Project Structure

```
/app
/app/mysql
/app/php

/config
/config/mysql
/config/nginx
/config/php

/data/mysql
/data/redis (if Redis is enabled)

/logs
/logs/mysql
/logs/nginx
/logs/php

/www

.env
docker-compose.yml
```

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](https://github.com/anik1ng/docktales/issues).

## 📝 License

This project is [MIT](LICENSE) licensed.

## 🙏 Acknowledgments

- Docker and Docker Compose teams
- All awesome open-source contributors

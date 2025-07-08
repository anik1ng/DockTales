.PHONY: start stop restart status logs rebuild help ssl clean add_hosts init

# Load variables from .env
ifneq (,$(wildcard ./.env))
    include .env
    export $(shell sed 's/=.*//' .env)
endif

# Default project name if not specified in .env
PROJECT_NAME ?= project
DOMAIN_NAME ?= project.test

# Docker commands
DC = docker-compose

# Start project
start: init
	@echo "🚀 Starting containers..."
	@$(DC) up -d
	@echo "✅ Containers started!"
	@echo "🌐 Access your site at https://$(DOMAIN_NAME)"

# Initialize project
init: ssl
	@echo "🔧 Initializing project..."
	@mkdir -p logs/nginx logs/php logs/mysql data/mysql
	@if [ "$(USE_REDIS)" = "true" ]; then \
		mkdir -p data/redis; \
	fi
	@$(MAKE) add_hosts
	@echo "✅ Initialization complete!"

# Add hosts entry
add_hosts:
	@grep -q "$(DOMAIN_NAME)" /etc/hosts || ( \
		echo "🌐 Adding hosts entry for $(DOMAIN_NAME)..."; \
		sudo sh -c 'echo "127.0.0.1 $(DOMAIN_NAME)" >> /etc/hosts'; \
		echo "✅ Hosts entry added"; \
	)

# Setup SSL certificates
ssl:
	@echo "🔒 Checking SSL certificates..."
	@mkdir -p config/nginx/ssl
	@if [ ! -f "config/nginx/ssl/server.crt" ] || [ ! -f "config/nginx/ssl/server.key" ]; then \
		echo "🔒 Generating SSL certificates for $(DOMAIN_NAME)..."; \
		openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
		-keyout config/nginx/ssl/server.key \
		-out config/nginx/ssl/server.crt \
		-subj "/C=US/ST=State/L=City/O=Organization/CN=$(DOMAIN_NAME)" \
		-batch; \
		chmod 644 config/nginx/ssl/server.crt; \
		chmod 600 config/nginx/ssl/server.key; \
		echo "✅ SSL certificates generated successfully"; \
	else \
		echo "✅ SSL certificates exist, using current ones"; \
	fi

# Stop project
stop:
	@echo "🛑 Stopping containers..."
	@$(DC) down
	@echo "✅ Containers stopped!"

# Restart project
restart: stop start

# Show project status
status:
	@echo "📊 Container status:"
	@$(DC) ps
	@echo ""
	@echo "🌐 Website: https://$(DOMAIN_NAME)"
	@if curl -s -o /dev/null -w "%{http_code}" https://$(DOMAIN_NAME) --insecure | grep -q "200\|301\|302"; then \
		echo "✅ Web service is running"; \
	else \
		echo "❌ Web service is not accessible"; \
	fi

# Show container logs
logs:
	@echo "📋 Showing logs (press Ctrl+C to exit)..."
	@$(DC) logs -f

# Rebuild containers
rebuild:
	@echo "🔄 Rebuilding containers..."
	@$(DC) down
	@$(DC) build --no-cache
	@$(DC) up -d
	@echo "✅ Containers rebuilt and started!"

# Clean project data (with confirmation)
clean:
	@echo "⚠️ WARNING: This will remove all project data including database!"
	@read -p "Are you sure you want to continue? [y/N]: " answer; \
	if [ "$$answer" = "y" ] || [ "$$answer" = "Y" ]; then \
		echo "🗑️ Removing all project data..."; \
		$(DC) down -v; \
		sudo rm -rf data/* logs/*; \
		echo "✅ Project data cleaned!"; \
	else \
		echo "🛑 Operation cancelled"; \
	fi

# Run Docker exec to enter PHP container
exec:
	@echo "🔌 Connecting to PHP container..."
	@docker exec -it $$(docker ps -qf "name=php" | head -n 1) bash || echo "❌ Failed to connect! Are containers running?"

# Run artisan command
artisan:
	@if [ -z "$(cmd)" ]; then \
		echo "❌ No command specified! Use: make artisan cmd=\"your-command\""; \
	else \
		echo "🔄 Running: php artisan $(cmd)"; \
		docker exec -it $$(docker ps -qf "name=php" | head -n 1) php artisan $(cmd) || echo "❌ Failed to run command! Are containers running?"; \
	fi

# Run composer command
composer:
	@if [ -z "$(cmd)" ]; then \
		echo "❌ No command specified! Use: make composer cmd=\"your-command\""; \
	else \
		echo "🔄 Running: composer $(cmd)"; \
		docker exec -it $$(docker ps -qf "name=php" | head -n 1) composer $(cmd) || echo "❌ Failed to run command! Are containers running?"; \
	fi

# Run npm command in node container
npm:
	@if [ -z "$(cmd)" ]; then \
		echo "❌ No command specified! Use: make npm cmd=\"your-command\""; \
	else \
		echo "🔄 Running: npm $(cmd)"; \
		docker exec -it $$(docker ps -qf "name=node" | head -n 1) npm $(cmd) || echo "❌ Failed to run command! Are containers running?"; \
	fi

# Run npx command in node container
npx:
	@if [ -z "$(cmd)" ]; then \
		echo "❌ No command specified! Use: make npx cmd=\"your-command\""; \
	else \
		echo "🔄 Running: npx $(cmd)"; \
		docker exec -it $$(docker ps -qf "name=node" | head -n 1) npx $(cmd) || echo "❌ Failed to run command! Are containers running?"; \
	fi

# Show help
help:
	@echo "🐳 DockTales - Docker Environment Manager"
	@echo ""
	@echo "Usage:"
	@echo "  make [command]"
	@echo ""
	@echo "Available commands:"
	@echo ""
	@echo "  📦 Container Management:"
	@echo "  start     - Start all containers with initialization"
	@echo "  stop      - Stop all containers"
	@echo "  restart   - Restart all containers"
	@echo "  status    - Show status of all containers"
	@echo "  logs      - Show logs from all containers"
	@echo "  rebuild   - Rebuild and restart all containers"
	@echo ""
	@echo "  💻 Development Tools:"
	@echo "  exec      - Open bash shell in PHP container"
	@echo "  artisan   - Run artisan command (use: make artisan cmd=\"cache:clear\")"
	@echo "  composer  - Run composer command (use: make composer cmd=\"install\")"
	@echo "  npm       - Run npm command in node container (use: make npm cmd=\"install\")"
	@echo "  npx       - Run npx command in node container (use: make npx cmd=\"vite build\")"
	@echo ""
	@echo "  🔧 Maintenance:"
	@echo "  ssl       - Regenerate SSL certificates"
	@echo "  clean     - Remove all project data (with confirmation)"
	@echo "  help      - Show this help"
	@echo ""
	@echo "Current configuration:"
	@echo "  Project: $(PROJECT_NAME)"
	@echo "  Domain:  $(DOMAIN_NAME)"
	@echo "  PHP:     $(PHP_VERSION)"
	@echo "  MySQL:   $(MYSQL_VERSION)"
	@echo "  Redis:   $(USE_REDIS)"
	@echo ""

# Default target
.DEFAULT_GOAL := help

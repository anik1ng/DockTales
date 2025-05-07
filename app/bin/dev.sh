#!/bin/bash

# Developer environment manager
# =====================================

# colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# load environment variables
if [ -f ".env" ]; then
    set -a
    source .env
    set +a
else
    echo -e "${RED}Error: .env file not found${NC}"
    echo -e "Please create an .env file with required variables"
    exit 1
fi

# print application header
print_header() {
    clear
    echo -e "${BOLD}${BLUE}=======================================${NC}"
    echo -e "${BOLD}${BLUE}   Docker Development Environment    ${NC}"
    echo -e "${BOLD}${BLUE}   Project: ${CYAN}${PROJECT_NAME}${BLUE}              ${NC}"
    echo -e "${BOLD}${BLUE}=======================================${NC}"
    echo ""
}

# setup ssl certificates
setup_ssl() {
    # check if certificates already exist
    if [ -f "./config/nginx/ssl/server.crt" ] && [ -f "./config/nginx/ssl/server.key" ]; then
        # check if domain name matches the one in the certificate
        current_domain=$(openssl x509 -noout -subject -in "./config/nginx/ssl/server.crt" | grep -o "CN = .*" | sed 's/CN = //')
        if [ "$current_domain" != "$DOMAIN_NAME" ]; then
            echo -e "${YELLOW}Domain mismatch. Regenerating certificates for ${DOMAIN_NAME}...${NC}"
        else
            return 0
        fi
    else
        echo -e "${BLUE}Setting up SSL certificates...${NC}"
    fi

    # directory for ssl certificates
    mkdir -p ./config/nginx/ssl

    # generate self-signed ssl certificate for local development
    echo -e "${YELLOW}Generating SSL certificate for ${DOMAIN_NAME}...${NC}"
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout ./config/nginx/ssl/server.key \
        -out ./config/nginx/ssl/server.crt \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=${DOMAIN_NAME}"

    # set correct permissions for security
    chmod 644 ./config/nginx/ssl/server.crt
    chmod 600 ./config/nginx/ssl/server.key

    echo -e "${GREEN}SSL certificates generated successfully for ${DOMAIN_NAME}!${NC}"
}

# create necessary directories
create_directories() {
    # check if directories already exist
    if [ -d "./logs/nginx" ] && [ -d "./logs/php" ] && [ -d "./logs/mysql" ] && [ -d "./data/mysql" ]; then
        return 0
    fi

    echo -e "${BLUE}Creating necessary directories...${NC}"

    # log directories
    mkdir -p ./logs/nginx
    mkdir -p ./logs/php
    mkdir -p ./logs/mysql

    # data directories
    mkdir -p ./data/mysql

    # if redis is enabled, check for redis directory
    if [ "$USE_REDIS" = "true" ] && [ ! -d "./data/redis" ]; then
        mkdir -p ./data/redis
    fi

    echo -e "${GREEN}Directories created successfully.${NC}"
}

# check system requirements
check_requirements() {
    local requirements_ok=true

    # Check Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Docker is not installed.${NC}"
        echo -e "Please install Docker: https://docs.docker.com/get-docker/"
        requirements_ok=false
    fi

    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}Docker Compose is not installed.${NC}"
        echo -e "Please install Docker Compose: https://docs.docker.com/compose/install/"
        requirements_ok=false
    fi

    if $requirements_ok; then
        return 0
    else
        return 1
    fi
}

# add hosts entry
add_hosts_entry() {
    # Check if hosts entry already exists
    if grep -q "${DOMAIN_NAME}" /etc/hosts; then
        return 0
    fi

    echo -e "${YELLOW}Adding hosts entry for ${DOMAIN_NAME}...${NC}"
    if [ "$(id -u)" -eq 0 ]; then
        # if running as root
        echo "127.0.0.1 ${DOMAIN_NAME}" >> /etc/hosts
    else
        # try with sudo
        if command -v sudo &> /dev/null; then
            echo "127.0.0.1 ${DOMAIN_NAME}" | sudo tee -a /etc/hosts > /dev/null
        else
            echo -e "${RED}Cannot update hosts file. Please add manually:${NC}"
            echo -e "${YELLOW}127.0.0.1 ${DOMAIN_NAME}${NC}"
            return 1
        fi
    fi
    echo -e "${GREEN}Hosts entry added successfully!${NC}"
    return 0
}

# remove hosts entry
remove_hosts_entry() {
    # Check if hosts entry exists
    if ! grep -q "${DOMAIN_NAME}" /etc/hosts; then
        return 0
    fi

    echo -e "${YELLOW}Removing hosts entry for ${DOMAIN_NAME}...${NC}"
    if [ "$(id -u)" -eq 0 ]; then
        # if running as root
        sed -i "" "/127.0.0.1 ${DOMAIN_NAME}/d" /etc/hosts 2>/dev/null || \
        sed -i "/127.0.0.1 ${DOMAIN_NAME}/d" /etc/hosts
    else
        # try with sudo
        if command -v sudo &> /dev/null; then
            sudo sed -i "" "/127.0.0.1 ${DOMAIN_NAME}/d" /etc/hosts 2>/dev/null || \
            sudo sed -i "/127.0.0.1 ${DOMAIN_NAME}/d" /etc/hosts
        else
            echo -e "${RED}Cannot update hosts file. Please remove manually:${NC}"
            echo -e "${YELLOW}127.0.0.1 ${DOMAIN_NAME}${NC}"
            return 1
        fi
    fi
    echo -e "${GREEN}Hosts entry removed successfully!${NC}"
    return 0
}

# initialize the project
initialize_project() {
    # Check requirements
    check_requirements || return 1

    # Create directories
    create_directories

    # Setup SSL certificates
    setup_ssl

    # Update hosts file
    add_hosts_entry

    return 0
}

# show status of running containers
show_status() {
    echo -e "${BLUE}Current container status:${NC}"
    docker-compose ps

    echo -e "\n${BLUE}Available at:${NC}"
    echo -e "  ${BOLD}Website:${NC} https://${DOMAIN_NAME}"

    # Check if web is accessible
    if curl -s -o /dev/null -w "%{http_code}" https://${DOMAIN_NAME} --insecure | grep -q "200\|301\|302"; then
        echo -e "  ${GREEN}✓${NC} Web service is running"
    else
        echo -e "  ${RED}✗${NC} Web service is not accessible"
    fi

    # MySQL
    if docker-compose ps mysql | grep -q "Up"; then
        echo -e "  ${GREEN}✓${NC} MySQL service is running"
    else
        echo -e "  ${RED}✗${NC} MySQL service is not running"
    fi

    # Redis (if enabled)
    if [ "$USE_REDIS" = "true" ]; then
        if docker-compose ps redis | grep -q "Up"; then
            echo -e "  ${GREEN}✓${NC} Redis service is running"
        else
            echo -e "  ${RED}✗${NC} Redis service is not running"
        fi
    fi
}

# show help menu
show_help() {
    print_header
    echo -e "${BOLD}Available commands:${NC}"
    echo -e ""
    echo -e "  ${CYAN}start${NC}     - Start all containers (with auto-initialization)"
    echo -e "  ${CYAN}stop${NC}      - Stop all containers"
    echo -e "  ${CYAN}restart${NC}   - Restart all containers"
    echo -e "  ${CYAN}status${NC}    - Show status of all containers"
    echo -e "  ${CYAN}logs${NC}      - Show logs from all containers"
    echo -e "  ${CYAN}rebuild${NC}   - Rebuild and restart all containers"
    echo -e "  ${CYAN}help${NC}      - Show this help menu"
    echo -e ""
    echo -e "${BOLD}Examples:${NC}"
    echo -e "  ${YELLOW}./app/bin/dev.sh start${NC}    - Start the environment"
    echo -e "  ${YELLOW}./app/bin/dev.sh logs${NC}     - Show container logs"
    echo -e ""
    echo -e "${BOLD}Current Configuration:${NC}"
    echo -e "  ${PURPLE}Project:${NC} ${PROJECT_NAME}"
    echo -e "  ${PURPLE}Domain:${NC} ${DOMAIN_NAME}"
    echo -e "  ${PURPLE}PHP Version:${NC} ${PHP_VERSION}"
    echo -e "  ${PURPLE}MySQL Version:${NC} ${MYSQL_VERSION}"
    echo -e "  ${PURPLE}Redis:${NC} ${USE_REDIS}"
    echo -e ""
}

# ask user for confirmation
confirm() {
    read -p "$(echo -e ${YELLOW}"$1 [y/N]: "${NC})" response
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# main execution based on arguments
case "$1" in
    start)
        print_header
        # Auto-initialize if needed
        initialize_project

        echo -e "${BLUE}Starting containers...${NC}"
        docker-compose up -d
        echo -e "${GREEN}Containers started!${NC}"
        echo -e "Access your site at ${BOLD}https://${DOMAIN_NAME}${NC}"
        ;;
    stop)
        print_header
        echo -e "${BLUE}Stopping containers...${NC}"
        docker-compose down
        echo -e "${GREEN}Containers stopped!${NC}"

        # Ask if user wants to remove hosts entry
        if confirm "Do you want to remove the hosts entry for ${DOMAIN_NAME}?"; then
            remove_hosts_entry
        fi
        ;;
    restart)
        print_header
        echo -e "${BLUE}Restarting containers...${NC}"
        docker-compose down
        docker-compose up -d
        echo -e "${GREEN}Containers restarted!${NC}"
        echo -e "Access your site at ${BOLD}https://${DOMAIN_NAME}${NC}"
        ;;
    rebuild)
        print_header
        echo -e "${BLUE}Rebuilding containers...${NC}"
        docker-compose down
        docker-compose build --no-cache
        docker-compose up -d
        echo -e "${GREEN}Containers rebuilt and started!${NC}"
        echo -e "Access your site at ${BOLD}https://${DOMAIN_NAME}${NC}"
        ;;
    logs)
        print_header
        echo -e "${BLUE}Showing logs (press Ctrl+C to exit)...${NC}"
        docker-compose logs -f
        ;;
    status)
        print_header
        show_status
        ;;
    help|"")
        show_help
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        echo -e "Use ${YELLOW}./dev.sh help${NC} to see available commands"
        exit 1
        ;;
esac

exit 0

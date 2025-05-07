-- Create database if not exists
CREATE DATABASE IF NOT EXISTS `${DB_DATABASE}`;

-- Grant privileges
GRANT ALL PRIVILEGES ON `${DB_DATABASE}`.* TO '${DB_USERNAME}'@'%';

FLUSH PRIVILEGES;
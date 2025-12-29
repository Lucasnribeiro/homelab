# Example Docker Compose Configurations

This directory contains example `docker-compose.yml` files for common development stacks.

## Basic Web Stack (docker-compose.yml)

A complete web development stack with:
- **Web server**: Nginx
- **Application**: Node.js
- **Database**: PostgreSQL
- **Cache**: Redis

### Usage

1. Switch to Windows Docker context:
   ```bash
   cd ../macbook
   ./use-windows.sh
   ```

2. Navigate to your project directory (or copy this compose file there)

3. Start the stack:
   ```bash
   docker-compose up -d
   ```

4. Access services:
   - Web: http://WINDOWS-IP:8080
   - App: http://WINDOWS-IP:3000
   - Database: WINDOWS-IP:5432
   - Redis: WINDOWS-IP:6379

### Volume Mounting from MacBook

To mount your MacBook code into containers:

1. **Enable SMB sharing on MacBook:**
   - System Settings > General > Sharing
   - Enable "File Sharing" and "SMB"
   - Share your projects directory

2. **Map network drive on Windows:**
   - Open File Explorer
   - Go to "This PC" > "Map network drive"
   - Map `\\MacBook-IP\Projects` to a drive letter (e.g., `Z:`)

3. **Update docker-compose.yml:**
   ```yaml
   volumes:
     - Z:\myapp:/app  # Use Windows path
   ```

   Or use UNC path directly:
   ```yaml
   volumes:
     - //192.168.1.50/projects/myapp:/app
   ```

### Important Notes

- **Code volumes**: Mount from MacBook SMB share (for live code editing)
- **Data volumes**: Use Docker named volumes on Windows (for databases, cache)
- **Ports**: Services are accessible via Windows IP, not localhost
- **Performance**: Network-mounted code may have slight latency, but container execution is full speed

## Customizing for Your Projects

1. Copy `docker-compose.yml` to your project directory
2. Update image versions, ports, and environment variables
3. Adjust volume mounts for your project structure
4. Add or remove services as needed




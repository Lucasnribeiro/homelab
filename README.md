# Homelab Setup

## Goal
Use Windows desktop as compute resource for Docker containers while developing from MacBook. Manage everything from MacBook using Docker Desktop, with containers running on Windows desktop.

## Architecture

```
MacBook (Development)          Windows Desktop (Compute)
┌─────────────────┐           ┌──────────────────────┐
│ Code/Projects   │           │  Docker Desktop      │
│                 │           │                      │
│ Docker Desktop  │  ────────>│  Containers          │
│                 │  (SSH)    │  (Web, DB, Cache)    │
│ Docker Context  │           │                      │
│ (remote)        │<──────────│  (mounts MacBook     │
└─────────────────┘  (SMB)    │   code via network)  │
                              └──────────────────────┘
```

**Key Challenge**: Code lives on MacBook, but containers run on Windows. Need network-based volume mounting.

## Approach: Docker Context over SSH

### Why This Approach?
- ✅ Seamless experience: Use `docker` commands on MacBook, containers run on Windows
- ✅ Secure: SSH encryption, no direct Docker API exposure
- ✅ Works with Docker Desktop: Can switch contexts easily
- ✅ Trusted network: Simple setup, no complex security overhead
- ✅ Future-proof: Easy to add remote access via VPN/SSH tunnel later

### Components Needed

1. **Windows Desktop Setup**
   - Docker Engine or Docker Desktop
   - SSH server (OpenSSH Server on Windows)
   - User account with Docker permissions

2. **MacBook Setup**
   - Docker Desktop (already have)
   - SSH client (built-in)
   - Docker context configuration

3. **Network**
   - Both devices on same local network
   - Static IP or hostname for Windows desktop (recommended)

## Implementation Plan

### Phase 1: Windows Desktop Setup
1. Install Docker Desktop or Docker Engine on Windows
2. Enable OpenSSH Server on Windows
3. Configure SSH for key-based authentication
4. Test Docker access via SSH

### Phase 2: MacBook Configuration
1. Generate SSH key pair (if not exists)
2. Copy public key to Windows desktop
3. Create Docker context pointing to Windows desktop
4. Test connection and container deployment

### Phase 3: Code Mounting Solution
Since code lives on MacBook but containers run on Windows, we need network-based mounting:

**Option A: SMB/CIFS Share (Recommended)**
- Share project directories from MacBook via SMB
- Mount SMB share in Windows Docker containers
- Pros: Native Windows support, good performance on LAN
- Cons: Requires MacBook to be on and sharing enabled

**Option B: SSHFS on Windows**
- Use SSHFS to mount MacBook directories on Windows
- Mount those directories in containers
- Pros: Secure, no SMB setup needed
- Cons: Requires SSHFS software on Windows, may have performance overhead

**Option C: Hybrid Approach**
- Use SMB for active development directories
- Use Docker volumes for databases/cache (data persistence)
- Use bind mounts for config files

### Phase 4: Development Workflow
1. Switch Docker context to Windows desktop
2. Use standard Docker commands (they'll run on Windows)
3. Services accessible via Windows IP (or SSH port forwarding)
4. Code changes on MacBook reflect in containers via network mount

### Phase 4: Remote Access (Optional)
1. Set up VPN or SSH tunnel for external access
2. Configure port forwarding on router (if needed)
3. Security hardening for external access

## Security Considerations

- **Local Network**: SSH key-based auth (no passwords)
- **Remote Access**: VPN recommended over direct SSH exposure
- **Docker Socket**: Not directly exposed, only via SSH

## Setup Script Approach

The repo will contain a setup script that runs on Windows to configure everything:

```
Windows Desktop:
1. Clone this repo
2. Run setup script (PowerShell)
3. Script configures:
   - Verifies Docker Desktop installation
   - Enables OpenSSH Server
   - Configures SSH for key-based auth
   - Sets up firewall rules
   - Provides connection info for MacBook
```

Then on MacBook:
- Run a separate setup script that:
  - Creates Docker context
  - Configures SSH connection
  - Sets up SMB sharing (if needed)

## Code Mounting - Detailed Discussion

### Recommended: SMB Share Approach

**MacBook Side:**
- Enable File Sharing (System Settings)
- Share specific project directories
- Use SMB protocol (compatible with Windows)

**Windows Side:**
- Map network drive to MacBook share
- Use Windows path in Docker volumes: `//MacBook-IP/projects:/app`
- Or use UNC path directly in docker-compose

**Example docker-compose.yml:**
```yaml
services:
  web:
    image: nginx
    volumes:
      - //192.168.1.50/projects/myapp:/usr/share/nginx/html
    ports:
      - "8080:80"
```

### Alternative: SSHFS (if SMB has issues)

**Windows Side:**
- Install WinFsp + SSHFS-Win
- Mount MacBook directory: `sshfs user@macbook-ip:/path /mnt/macbook`
- Use local Windows path in Docker: `/mnt/macbook/projects:/app`

## Questions to Finalize Approach

1. **SMB vs SSHFS**: Prefer SMB (simpler, native) or SSHFS (more secure, no SMB config)?
2. **Project Structure**: Single shared directory for all projects, or per-project shares?
3. **Performance**: Are you okay with network I/O latency for file operations?
4. **MacBook Always On**: Will MacBook be on whenever you're developing? (Required for network mounts)
5. **Database Data**: Where should database volumes live? (Windows local storage recommended)

## Next Steps

1. Decide on code mounting approach (SMB vs SSHFS)
2. Create Windows setup script (PowerShell)
3. Create MacBook setup script (Bash)
4. Add docker-compose examples for web/db/cache
5. Add troubleshooting guide
6. Optional: Add remote access setup guide

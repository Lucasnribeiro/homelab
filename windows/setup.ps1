# Homelab Windows Setup Script
# This script configures Windows desktop to accept Docker connections from MacBook

param(
    [string]$MacBookIP = "",
    [string]$MacBookUser = ""
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Homelab Windows Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

# Step 1: Check Docker Desktop
Write-Host "[1/5] Checking Docker Desktop installation..." -ForegroundColor Yellow
$dockerPath = Get-Command docker -ErrorAction SilentlyContinue
if (-not $dockerPath) {
    Write-Host "ERROR: Docker Desktop not found!" -ForegroundColor Red
    Write-Host "Please install Docker Desktop from: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
    exit 1
}

# Test Docker is running
try {
    $dockerOutput = docker version --format '{{.Server.Version}}' 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "WARNING: Docker Desktop may not be running. Please start it and try again." -ForegroundColor Yellow
    } else {
        Write-Host "✓ Docker Desktop is installed and running (version: $dockerOutput)" -ForegroundColor Green
    }
} catch {
    Write-Host "WARNING: Could not verify Docker is running. Please ensure Docker Desktop is started." -ForegroundColor Yellow
}

# Step 2: Enable OpenSSH Server
Write-Host ""
Write-Host "[2/5] Configuring OpenSSH Server..." -ForegroundColor Yellow

# Check if OpenSSH Server is installed
$sshService = Get-Service -Name sshd -ErrorAction SilentlyContinue
if (-not $sshService) {
    Write-Host "Installing OpenSSH Server..." -ForegroundColor Yellow
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
}

# Start and enable SSH service
Write-Host "Starting SSH service..." -ForegroundColor Yellow
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'

# Configure SSH to allow key-based authentication
$sshdConfigPath = Join-Path $env:ProgramData "ssh\sshd_config"
$sshdConfigBackup = $sshdConfigPath + ".backup"

# Backup existing config
if (Test-Path $sshdConfigPath) {
    Copy-Item $sshdConfigPath $sshdConfigBackup -Force
    Write-Host "✓ Backed up existing SSH config" -ForegroundColor Green
}

# Ensure required settings in sshd_config
if (Test-Path $sshdConfigPath) {
    $sshdConfig = Get-Content $sshdConfigPath -Raw
} else {
    $sshdConfig = ""
}

$requiredSettings = @{
    'PubkeyAuthentication' = 'yes'
    'PasswordAuthentication' = 'yes'
    'PermitRootLogin' = 'no'
}

foreach ($setting in $requiredSettings.GetEnumerator()) {
    $key = $setting.Key
    $value = $setting.Value
    $escapedKey = [regex]::Escape($key)
    $pattern = '^\s*#?\s*' + $escapedKey + '\s+.*'
    
    if ($sshdConfig -match $pattern) {
        $replacement = $key + ' ' + $value
        $sshdConfig = $sshdConfig -replace $pattern, $replacement
    } else {
        if ($sshdConfig.Length -gt 0) {
            $sshdConfig += [Environment]::NewLine
        }
        $sshdConfig += $key + ' ' + $value
    }
}

Set-Content -Path $sshdConfigPath -Value $sshdConfig -NoNewline
Restart-Service sshd

Write-Host "✓ OpenSSH Server configured and running" -ForegroundColor Green

# Step 3: Configure Windows Firewall
Write-Host ""
Write-Host "[3/5] Configuring Windows Firewall..." -ForegroundColor Yellow

# Allow SSH (port 22)
$firewallRule = Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue
if (-not $firewallRule) {
    New-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -DisplayName "OpenSSH SSH Server (sshd)" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 | Out-Null
    Write-Host "✓ Added firewall rule for SSH (port 22)" -ForegroundColor Green
} else {
    Write-Host "✓ SSH firewall rule already exists" -ForegroundColor Green
}

# Step 4: Get Windows IP and User Info
Write-Host ""
Write-Host "[4/5] Gathering system information..." -ForegroundColor Yellow

$networkAdapters = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" }
$windowsIP = ($networkAdapters | Select-Object -First 1).IPAddress
$windowsHostname = $env:COMPUTERNAME
$windowsUser = $env:USERNAME

Write-Host "✓ Windows Hostname: $windowsHostname" -ForegroundColor Green
Write-Host "✓ Windows IP: $windowsIP" -ForegroundColor Green
Write-Host "✓ Windows User: $windowsUser" -ForegroundColor Green

# Step 5: Create SSH directory and set permissions
Write-Host ""
Write-Host "[5/5] Setting up SSH directory..." -ForegroundColor Yellow

$sshDir = Join-Path $env:USERPROFILE ".ssh"
if (-not (Test-Path $sshDir)) {
    New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
}

# Set proper permissions on .ssh directory
$acl = Get-Acl $sshDir
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($windowsUser, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.SetAccessRule($accessRule)
Set-Acl $sshDir $acl

Write-Host "✓ SSH directory ready for authorized_keys" -ForegroundColor Green

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. On your MacBook, run the setup script:" -ForegroundColor White
Write-Host "   cd macbook" -ForegroundColor Gray
Write-Host "   ./setup.sh" -ForegroundColor Gray
Write-Host ""
Write-Host "2. The MacBook script will:" -ForegroundColor White
Write-Host "   - Generate SSH key (if needed)" -ForegroundColor Gray
Write-Host "   - Copy public key to this Windows machine" -ForegroundColor Gray
Write-Host "   - Create Docker context" -ForegroundColor Gray
Write-Host ""
Write-Host "Connection Information:" -ForegroundColor Yellow
Write-Host "  Windows Hostname: $windowsHostname" -ForegroundColor White
Write-Host "  Windows IP: $windowsIP" -ForegroundColor White
Write-Host "  Windows User: $windowsUser" -ForegroundColor White
Write-Host "  SSH Port: 22" -ForegroundColor White
Write-Host ""
Write-Host "To connect manually, use:" -ForegroundColor Yellow
$sshCommand = "ssh {0}@{1}" -f $windowsUser, $windowsIP
Write-Host "  $sshCommand" -ForegroundColor Gray
Write-Host ""

# setup_antigravity.ps1
# Script de instalacion y configuracion automatica de Blender Skills para Google Antigravity

$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   Blender Skills -> Instalador para Google Antigravity    " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Comprobar / Instalar uv
Write-Host "[1/5] Verificando gestor de paquetes 'uv'..." -ForegroundColor Yellow
$uvxPath = Get-Command uvx -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue
$localBin = "$env:USERPROFILE\.local\bin"

if (-not $uvxPath -and (Test-Path "$localBin\uvx.exe")) {
    $uvxPath = "$localBin\uvx.exe"
}

if (-not $uvxPath) {
    Write-Host "   'uv' no encontrado. Instalando automaticamente..." -ForegroundColor Gray
    try {
        powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://astral.sh/uv/install.ps1 | iex"
        $uvxPath = "$localBin\uvx.exe"
    } catch {
        Write-Error "Error al instalar uv. Por favor intentalo manualmente desde https://astral.sh/uv"
    }
} else {
    Write-Host "   'uv' ya esta instalado en: $uvxPath" -ForegroundColor Green
}

# Anadir a PATH en proceso actual si no esta
$env:Path = "$localBin;$env:Path"
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$localBin*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$localBin", "User")
    Write-Host "   Anadido $localBin a la variable de entorno PATH del usuario." -ForegroundColor Green
}

# 2. Detectar e instalar Addon de Blender
Write-Host ""
Write-Host "[2/5] Buscando instalaciones de Blender..." -ForegroundColor Yellow
$blenderAppData = "$env:APPDATA\Blender Foundation\Blender"
$addonSource = Join-Path $PSScriptRoot "addons\blender_mcp_addon.py"

if (-not (Test-Path $addonSource)) {
    Write-Host "   Descargando addon.py..." -ForegroundColor Gray
    New-Item -ItemType Directory -Force -Path (Join-Path $PSScriptRoot "addons") | Out-Null
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ahujasid/blender-mcp/main/addon.py" -OutFile $addonSource
}

if (Test-Path $blenderAppData) {
    $versions = Get-ChildItem -Directory $blenderAppData | Where-Object { $_.Name -match '^\d+\.\d+$' }
    if ($versions.Count -gt 0) {
        foreach ($v in $versions) {
            $addonDir = Join-Path $v.FullName "scripts\addons"
            New-Item -ItemType Directory -Force -Path $addonDir | Out-Null
            $target = Join-Path $addonDir "blender_mcp_addon.py"
            Copy-Item -Path $addonSource -Destination $target -Force
            Write-Host "   -> Addon instalado para Blender $($v.Name) en: $target" -ForegroundColor Green
        }
    } else {
        Write-Host "   No se detectaron carpetas de versiones de Blender en AppData." -ForegroundColor Yellow
    }
} else {
    Write-Host "   No se encontro directorio de Blender Foundation en AppData." -ForegroundColor Yellow
}

# 3. Configurar mcp_config.json
Write-Host ""
Write-Host "[3/5] Verificando configuracion MCP para Antigravity..." -ForegroundColor Yellow

$mcpConfigContent = @'
{
  "mcpServers": {
    "blender": {
      "command": "cmd",
      "args": [
        "/c",
        "uvx",
        "mcp-for-blender"
      ],
      "env": {
        "BLENDER_HOST": "localhost",
        "BLENDER_PORT": "9876",
        "DISABLE_TELEMETRY": "true"
      }
    }
  }
}
'@

$localMcpPath = Join-Path $PSScriptRoot "mcp_config.json"
Set-Content -Path $localMcpPath -Value $mcpConfigContent -Encoding UTF8
Write-Host "   Configuracion local actualizada: $localMcpPath" -ForegroundColor Green

$globalConfigDir = "$env:USERPROFILE\.gemini\config"
if (Test-Path $globalConfigDir) {
    $globalMcpPath = Join-Path $globalConfigDir "mcp_config.json"
    Set-Content -Path $globalMcpPath -Value $mcpConfigContent -Encoding UTF8
    Write-Host "   Configuracion global actualizada: $globalMcpPath" -ForegroundColor Green
}

# 4. Asegurar skills y reglas de Antigravity
Write-Host ""
Write-Host "[4/5] Verificando Skills de Antigravity (.agents/skills/)..." -ForegroundColor Yellow
$skillsDir = Join-Path $PSScriptRoot ".agents\skills"
if (Test-Path $skillsDir) {
    $skillCount = (Get-ChildItem -Directory $skillsDir).Count
    Write-Host "   Total de paquetes de skills encontrados: $skillCount" -ForegroundColor Green
} else {
    Write-Host "   Copiando skills a .agents/skills/..." -ForegroundColor Gray
    New-Item -ItemType Directory -Force -Path $skillsDir | Out-Null
    Copy-Item -Path (Join-Path $PSScriptRoot ".claude\skills\*") -Destination $skillsDir -Recurse -Force
}

# 5. Pre-calentar entorno uvx blender-mcp
Write-Host ""
Write-Host "[5/5] Pre-descargando dependencias de blender-mcp..." -ForegroundColor Yellow
try {
    & $uvxPath mcp-for-blender --help | Out-Null
    Write-Host "   mcp-for-blender verificado y listo en cache." -ForegroundColor Green
} catch {
    Write-Host "   Nota: El precalentamiento continuo en segundo plano." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Instalacion completada con exito para Antigravity!       " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Pasos siguientes:" -ForegroundColor White
Write-Host "1. Abre Blender." -ForegroundColor Gray
Write-Host "2. En Preferences > Add-ons, activa 'Interface: Blender MCP'." -ForegroundColor Gray
Write-Host "3. En el 3D Viewport de Blender, presiona 'N', ve a la pestana BlenderMCP y pulsa 'Connect to Claude'." -ForegroundColor Gray
Write-Host "4. Listo! Pidele a Antigravity crear, modificar o inspeccionar cualquier escena 3D." -ForegroundColor Gray
Write-Host ""

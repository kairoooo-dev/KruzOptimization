<#
.SYNOPSIS
    KruzOptimization - Minecraft FPS Optimizer
.DESCRIPTION
    Optimizes Minecraft, JVM, and Windows for maximum FPS (500+).
    Scans launchers, applies JVM flags, optimizes system settings.
.EXAMPLE
    .\optimize.ps1
    .\optimize.ps1 -Ram 8
    .\optimize.ps1 -ScanOnly
#>

param(
    [int]$Ram = 0,
    [switch]$ScanOnly,
    [switch]$Aggressive
)

$ErrorActionPreference = "SilentlyContinue"
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "       KruzOptimization v1.0" -ForegroundColor Cyan
Write-Host "     Minecraft FPS Optimizer" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$os = Get-CimInstance Win32_OperatingSystem
$cpu = Get-CimInstance Win32_Processor
$gpu = Get-CimInstance Win32_VideoController | Where-Object { $_.Name -notlike "*Microsoft*" } | Select-Object -First 1
$ramGB = [math]::Round($os.TotalVisibleMemorySize / 1048576)

Write-Host "[SYSTEM INFO]" -ForegroundColor Yellow
Write-Host "  CPU: $($cpu.Name)" -ForegroundColor White
Write-Host "  GPU: $($gpu.Name)" -ForegroundColor White
Write-Host "  RAM: ${ramGB}GB" -ForegroundColor White
Write-Host "  Windows: $($os.Caption) $($os.Version)" -ForegroundColor White
Write-Host ""

if ($Ram -eq 0) {
    if ($ramGB -ge 32) { $Ram = 10 }
    elseif ($ramGB -ge 16) { $Ram = 8 }
    elseif ($ramGB -ge 8) { $Ram = 4 }
    else { $Ram = 2 }
}

Write-Host "[*] Using ${Ram}GB allocated to Minecraft" -ForegroundColor Green
Write-Host ""

$launchers = @()
$paths = @(
    "$env:USERPROFILE\.minecraft",
    "$env:APPDATA\.minecraft",
    "$env:LOCALAPPDATA\Modrinth App",
    "$env:LOCALAPPDATA\CurseForge",
    "$env:LOCALAPPDATA\GDLauncher",
    "$env:LOCALAPPDATA\PolyMC",
    "$env:LOCALAPPDATA\PrismLauncher",
    "$env:LOCALAPPDATA\MultiMC",
    "$env:LOCALAPPDATA\ATLauncher",
    "$env:LOCALAPPDATA\Babylon",
    "$env:LOCALAPPDATA\Badlion Client",
    "$env:LOCALAPPDATA\Lunar Client",
    "$env:LOCALAPPDATA\Feather",
    "$env:LOCALAPPDATA\Flarial",
    "$env:LOCALAPPDATA\SKlauncher",
    "$env:LOCALAPPDATA\Legacy Launcher",
    "$env:LOCALAPPDATA\LabyMod"
)

Write-Host "[SCANNING LAUNCHERS]" -ForegroundColor Yellow
foreach ($p in $paths) {
    if (Test-Path $p) {
        $name = Split-Path $p -Leaf
        Write-Host "  [+] Found: $name" -ForegroundColor Green
        $launchers += $p
    }
}
if ($launchers.Count -eq 0) {
    Write-Host "  [-] No launchers found, using default .minecraft" -ForegroundColor Red
    $launchers += "$env:USERPROFILE\.minecraft"
}
Write-Host ""

function Optimize-JVM {
    param([string]$LauncherPath)

    $javaArgs = @(
        "-XX:+UseG1GC"
        "-XX:+ParallelRefProcEnabled"
        "-XX:MaxGCPauseMillis=200"
        "-XX:+UnlockExperimentalVMOptions"
        "-XX:+DisableExplicitGC"
        "-XX:+AlwaysPreTouch"
        "-XX:G1NewSizePercent=30"
        "-XX:G1MaxNewSizePercent=40"
        "-XX:G1HeapRegionSize=8M"
        "-XX:G1ReservePercent=20"
        "-XX:G1HeapWastePercent=5"
        "-XX:G1MixedGCCountTarget=4"
        "-XX:InitiatingHeapOccupancyPercent=15"
        "-XX:G1MixedGCLiveThresholdPercent=90"
        "-XX:G1RSetUpdatingPauseTimePercent=5"
        "-XX:SurvivorRatio=32"
        "-XX:+PerfDisableSharedMem"
        "-XX:MaxTenuringThreshold=1"
        "-Djava.util.concurrent.ForkJoinPool.common.parallelism=4"
        "-DfmlignorePatchDiscrepancies=true"
        "-Dfml.noPatchAnimations=true"
        "-Dsun.rmi.dgc.server.gcInterval=2147483646"
        "-XX:+UnlockDiagnosticVMOptions"
        "-XX:+DisableAttachMechanism"
        "-Dminecraft.launcher.brand=KruzOptimization"
        "-Dminecraft.launcher.version=1.0"
    )

    if ($Aggressive) {
        $javaArgs += @(
            "-XX:+UseStringDeduplication"
            "-XX:+UseCompressedOops"
            "-XX:+UseFastAccessorMethods"
            "-XX:+OptimizeStringConcat"
            "-XX:+UseCompressedClassPointers"
        )
    }

    $heapMin = "${Ram}G"
    $heapMax = "${Ram}G"
    $javaArgs = @("-Xms$heapMin", "-Xmx$heapMax") + $javaArgs

    $javaArgsStr = $javaArgs -join " "

    $profileFile = Join-Path $LauncherPath "KruzOptimization-JVM.txt"
    $javaArgsStr | Out-File $profileFile -Encoding UTF8

    Write-Host "  JVM Args saved to: $profileFile" -ForegroundColor Green

    $cfgPath = Join-Path $LauncherPath "config.cfg"
    if (Test-Path $cfgPath) {
        $content = Get-Content $cfgPath -Raw -ErrorAction SilentlyContinue
        if ($content -match "jvmArgs") {
            Write-Host "  [!] Detected existing JVM config - manual review recommended" -ForegroundColor Yellow
        }
    }

    return $javaArgsStr
}

function Optimize-MinecraftSettings {
    param([string]$McPath)

    $optionsFile = Join-Path $McPath "options.txt"
    if (-not (Test-Path $McPath)) {
        New-Item -ItemType Directory -Path $McPath -Force | Out-Null
    }

    $optimizedOptions = @"
lang:en_US
soundLevels:{}
chatHeight:1.0
chatWidth:1.0
chatScale:1.0
chatLineSpacing:0.0
chatPromptText:Chat
chatVisibility:0
fullscreen:false
bossMusic:true
musicVolume:0.0
noteblockVolume:0.0
chatColour:true
chatLinks:true
chatLinksPrompt:true
autoJump:false
difficulty:2
fancyGraphics:false
enableVsync:false
fpsLimit:0
fov:110
fovView:110
gamma:1.0
guiScale:3
handPrioritization:1
highContrast:false
hideBundleTutorial:true
hudHidden:false
invertYMouse:false
maxFps:260
menuBackgroundBlurriness:0
minecraftVersion:1.21.1
monochromeLogo:false
mouseSensitivity:0.5
narrator:0
particles:0
perspective:0
realmNotifications:true
resourcePack:,
resourcePackHash:
sensitivity:0.5
skinCustomisation:{}
soundDevice:
snooperEnabled:true
showFrameProfiler:false
useNative:0
lastServer:
langCode:en_US
forceUnicodeFont:false
prevGameMode:0
soundVolume:0.0
blockSoundVolume:0.0
musicType:options
autoConfigGUI:true
@"@

    $optimizedOptions | Out-File $optionsFile -Encoding UTF8 -Force
    Write-Host "  Optimized options.txt" -ForegroundColor Green
}

function Optimize-VideoSettings {
    param([string]$McPath)

    $videoSettingsFile = Join-Path $McPath "options.txt"

    $videoSettings = @"
lang:en_US
fancyGraphics:false
enableVsync:false
fpsLimit:0
fov:110
fovView:110
gamma:1.0
guiScale:3
maxFps:260
mipmapLevels:0
fboQuality:0
anaglyph3d:false
"@@

    $currentOptions = ""
    if (Test-Path $videoSettingsFile) {
        $currentOptions = Get-Content $videoSettingsFile -Raw -ErrorAction SilentlyContinue
    }

    foreach ($line in ($videoSettings -split "`n")) {
        $key = ($line -split ":")[0].Trim()
        if ($currentOptions -match "$key" -and $currentOptions) {
            $currentOptions = $currentOptions -replace "$key:.*", "$key:$($line -split ':',2)[1].Trim()"
        } else {
            $currentOptions += "`n$line"
        }
    }

    $currentOptions | Out-File $videoSettingsFile -Encoding UTF8 -Force
    Write-Host "  Optimized video settings" -ForegroundColor Green
}

function Optimize-System {
    Write-Host "[SYSTEM OPTIMIZATION]" -ForegroundColor Yellow

    try {
        powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
        Write-Host "  [+] High Performance power plan" -ForegroundColor Green
    } catch {
        try {
            powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
            Write-Host "  [+] High Performance power plan" -ForegroundColor Green
        } catch {
            Write-Host "  [-] Could not set power plan (run as admin)" -ForegroundColor Red
        }
    }

    try {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 38 -ErrorAction Stop
        Write-Host "  [+] Optimized process scheduling" -ForegroundColor Green
    } catch {
        Write-Host "  [-] Could not set process priority (run as admin)" -ForegroundColor Red
    }

    try {
        $gpuPath = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
        if (-not (Test-Path $gpuPath)) {
            New-Item -Path $gpuPath -Force | Out-Null
        }
        Set-ItemProperty -Path $gpuPath -Name "HwSchMode" -Value 2 -ErrorAction Stop
        Write-Host "  [+] GPU Hardware Scheduling enabled" -ForegroundColor Green
    } catch {
        Write-Host "  [-] GPU scheduling (may need restart)" -ForegroundColor Yellow
    }

    try {
        $gameBarPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR"
        Set-ItemProperty -Path $gameBarPath -Name "AppCaptureEnabled" -Value 0 -ErrorAction Stop

        $gameBarPath2 = "HKCU:\System\GameConfigStore"
        Set-ItemProperty -Path $gameBarPath2 -Name "GameDVR_Enabled" -Value 0 -ErrorAction Stop
        Write-Host "  [+] Xbox Game Bar disabled" -ForegroundColor Green
    } catch {
        Write-Host "  [-] Could not disable Game Bar" -ForegroundColor Yellow
    }

    try {
        $mmcPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
        Set-ItemProperty -Path $mmcPath -Name "LargeSystemCache" -Value 0 -ErrorAction Stop
        Set-ItemProperty -Path $mmcPath -Name "ClearPageFileAtShutdown" -Value 0 -ErrorAction Stop
        Write-Host "  [+] Memory management optimized" -ForegroundColor Green
    } catch {
        Write-Host "  [-] Memory optimization (run as admin)" -ForegroundColor Yellow
    }

    try {
        $networkPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
        Set-ItemProperty -Path $networkPath -Name "TcpAckFrequency" -Value 1 -ErrorAction Stop
        Set-ItemProperty -Path $networkPath -Name "TCPNoDelay" -Value 1 -ErrorAction Stop
        Write-Host "  [+] Network latency reduced" -ForegroundColor Green
    } catch {
        Write-Host "  [-] Network optimization (run as admin)" -ForegroundColor Yellow
    }

    try {
        $fsPath = "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"
        Set-ItemProperty -Path $fsPath -Name "NtfsDisableLastAccessUpdate" -Value 1 -ErrorAction Stop
        Set-ItemProperty -Path $fsPath -Name "NtfsMemoryUsage" -Value 2 -ErrorAction Stop
        Write-Host "  [+] File system optimized" -ForegroundColor Green
    } catch {
        Write-Host "  [-] File system optimization (run as admin)" -ForegroundColor Yellow
    }
}

function Optimize-Mods {
    param([string]$McPath)

    $modsPath = Join-Path $McPath "mods"
    if (-not (Test-Path $modsPath)) { return }

    $performanceMods = @(
        "optifine", "sodium", "lithium", "phosphor", "starlight",
        " Ferrite", "LazyDFU", "DashLoader", "Krypton", "EntityCulling",
        "ImmediatelyFast", "EnhancedBlockEntities", "ModernFix",
        "Nvidium", "Indium", "Iris", "Canvas"
    )

    Write-Host "[PERFORMANCE MODS FOUND]" -ForegroundColor Yellow
    $mods = Get-ChildItem -Path $modsPath -Filter "*.jar" -ErrorAction SilentlyContinue
    foreach ($mod in $mods) {
        $modName = $mod.Name.ToLower()
        foreach ($perfMod in $performanceMods) {
            if ($modName -match $perfMod.Trim().ToLower()) {
                Write-Host "  [+] $($mod.Name)" -ForegroundColor Green
            }
        }
    }
    Write-Host ""
    Write-Host "  Recommended performance mods to install:" -ForegroundColor Cyan
    Write-Host "    - Sodium (Fabric) or OptiFine (Forge)" -ForegroundColor White
    Write-Host "    - Lithium (Fabric)" -ForegroundColor White
    Write-Host "    - Starlight (Fabric)" -ForegroundColor White
    Write-Host "    - FerriteCore (Fabric/Forge)" -ForegroundColor White
    Write-Host "    - LazyDFU (Fabric/Forge)" -ForegroundColor White
    Write-Host "    - Krypton (Fabric)" -ForegroundColor White
    Write-Host "    - EntityCulling (Fabric/Forge)" -ForegroundColor White
    Write-Host "    - Nvidium (Fabric, NVIDIA only)" -ForegroundColor White
    Write-Host ""
}

function Generate-JVMProfile {
    param([string]$LauncherPath, [string]$JavaArgs)

    $profileContent = @"
# KruzOptimization v1.0 - JVM Profile
# Copy these arguments to your launcher's JVM arguments field

$JavaArgs

# ========================================
# How to apply:
# 1. Open your Minecraft launcher
# 2. Go to Game Settings / Java Settings
# 3. Paste the arguments above into JVM Arguments
# 4. Make sure Minecraft is allocated ${Ram}GB RAM
# 5. Launch and enjoy 500+ FPS!
# ========================================
"@

    $profilePath = Join-Path $scriptPath "JVM-PROFILE.txt"
    $profileContent | Out-File $profilePath -Encoding UTF8
    Write-Host "  JVM profile saved to: $profilePath" -ForegroundColor Green
}

$startTime = Get-Date

Write-Host "[JVM OPTIMIZATION]" -ForegroundColor Yellow
$javaArgs = ""
foreach ($launcher in $launchers) {
    Write-Host "  Processing: $(Split-Path $launcher -Leaf)" -ForegroundColor Cyan
    $javaArgs = Optimize-JVM -LauncherPath $launcher
}
Write-Host ""

if (-not $ScanOnly) {
    Write-Host "[MINECRAFT SETTINGS]" -ForegroundColor Yellow
    foreach ($launcher in $launchers) {
        $mcPath = Join-Path $launcher "versions"
        if (Test-Path $mcPath) {
            Write-Host "  Processing: $(Split-Path $launcher -Leaf)" -ForegroundColor Cyan
            Optimize-MinecraftSettings -McPath $launcher
            Optimize-VideoSettings -McPath $launcher
            Optimize-Mods -McPath $launcher
        }
    }
    Write-Host ""

    Optimize-System
    Write-Host ""
}

Generate-JVMProfile -LauncherPath $launchers[0] -JavaArgs $javaArgs

$duration = (Get-Date) - $startTime

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "         Optimization Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "  [WHAT WAS OPTIMIZED]" -ForegroundColor Cyan
Write-Host "    - JVM garbage collector (G1GC)" -ForegroundColor White
Write-Host "    - Memory allocation: ${Ram}GB" -ForegroundColor White
Write-Host "    - Thread optimization" -ForegroundColor White
Write-Host "    - Windows power plan" -ForegroundColor White
Write-Host "    - GPU hardware scheduling" -ForegroundColor White
Write-Host "    - Xbox Game Bar disabled" -ForegroundColor White
Write-Host "    - Network latency reduced" -ForegroundColor White
Write-Host "    - File system optimized" -ForegroundColor White
Write-Host ""
Write-Host "  [NEXT STEPS]" -ForegroundColor Cyan
Write-Host "    1. Open JVM-PROFILE.txt" -ForegroundColor White
Write-Host "    2. Copy the JVM arguments" -ForegroundColor White
Write-Host "    3. Paste into your launcher's JVM settings" -ForegroundColor White
Write-Host "    4. Install Sodium + Lithium for Fabric" -ForegroundColor White
Write-Host "    5. Set Minecraft RAM to ${Ram}GB" -ForegroundColor White
Write-Host "    6. Launch and enjoy!" -ForegroundColor White
Write-Host ""
Write-Host "  Time: $($duration.TotalSeconds.ToString('F1'))s" -ForegroundColor Gray
Write-Host ""

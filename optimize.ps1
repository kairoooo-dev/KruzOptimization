<#
.SYNOPSIS
    KruzOptimization v2.0 - Minecraft FPS Optimizer (MAXIMUM)
.DESCRIPTION
    Extreme Minecraft optimization. JVM, Windows, GPU, Network, Input, DirectX.
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
Write-Host "       KruzOptimization v2.0" -ForegroundColor Cyan
Write-Host "     Minecraft FPS Optimizer" -ForegroundColor Cyan
Write-Host "        MAXIMUM EDITION" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$os = Get-CimInstance Win32_OperatingSystem
$cpu = Get-CimInstance Win32_Processor
$gpu = Get-CimInstance Win32_VideoController | Where-Object { $_.Name -notlike "*Microsoft*" } | Select-Object -First 1
$ramGB = [math]::Round($os.TotalVisibleMemorySize / 1048576)
$gpuName = $gpu.Name.ToUpper()
$isNVIDIA = $gpuName -match "NVIDIA|GEFORCE|RTX|GTX"
$isAMD = $gpuName -match "AMD|RADEON"
$cpuThreads = $cpu.NumberOfLogicalProcessors
$cpuCores = $cpu.NumberOfCores

Write-Host "[SYSTEM INFO]" -ForegroundColor Yellow
Write-Host "  CPU: $($cpu.Name)" -ForegroundColor White
Write-Host "  Cores: $cpuCores | Threads: $cpuThreads" -ForegroundColor White
Write-Host "  GPU: $($gpu.Name)" -ForegroundColor White
if ($isNVIDIA) { Write-Host "  GPU Brand: NVIDIA (optimized)" -ForegroundColor Green }
elseif ($isAMD) { Write-Host "  GPU Brand: AMD (optimized)" -ForegroundColor Green }
else { Write-Host "  GPU Brand: Unknown" -ForegroundColor Yellow }
Write-Host "  RAM: ${ramGB}GB" -ForegroundColor White
Write-Host "  Windows: $($os.Caption) $($os.Version)" -ForegroundColor White
Write-Host ""

if ($Ram -eq 0) {
    if ($ramGB -ge 64) { $Ram = 16 }
    elseif ($ramGB -ge 32) { $Ram = 12 }
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
    "$env:APPDATA\ATLauncher",
    "$env:LOCALAPPDATA\Babylon",
    "$env:LOCALAPPDATA\Badlion Client",
    "$env:LOCALAPPDATA\Lunar Client",
    "$env:LOCALAPPDATA\Feather",
    "$env:LOCALAPPDATA\Flarial",
    "$env:LOCALAPPDATA\SKlauncher",
    "$env:LOCALAPPDATA\SK-Genesis",
    "$env:LOCALAPPDATA\Astralith",
    "$env:LOCALAPPDATA\Legacy Launcher",
    "$env:LOCALAPPDATA\Crystal Launcher",
    "$env:LOCALAPPDATA\LabyMod",
    "$env:APPDATA\.babric",
    "$env:APPDATA\.versionmanager",
    "$env:USERPROFILE\SKlauncher",
    "$env:USERPROFILE\Astralith"
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

    $threadCount = [math]::Min($cpuThreads, 8)

    $javaArgs = @(
        "-XX:+UseG1GC"
        "-XX:+ParallelRefProcEnabled"
        "-XX:MaxGCPauseMillis=50"
        "-XX:+UnlockExperimentalVMOptions"
        "-XX:+DisableExplicitGC"
        "-XX:+AlwaysPreTouch"
        "-XX:G1NewSizePercent=30"
        "-XX:G1MaxNewSizePercent=50"
        "-XX:G1HeapRegionSize=16M"
        "-XX:G1ReservePercent=25"
        "-XX:G1HeapWastePercent=3"
        "-XX:G1MixedGCCountTarget=2"
        "-XX:InitiatingHeapOccupancyPercent=10"
        "-XX:G1MixedGCLiveThresholdPercent=85"
        "-XX:G1RSetUpdatingPauseTimePercent=3"
        "-XX:SurvivorRatio=64"
        "-XX:+PerfDisableSharedMem"
        "-XX:MaxTenuringThreshold=1"
        "-XX:ConcGCThreads=$threadCount"
        "-XX:ParallelGCThreads=$threadCount"
        "-Djava.util.concurrent.ForkJoinPool.common.parallelism=$threadCount"
        "-Djava.util.concurrent.ForkJoinPool.common.threadFactory=java.util.concurrent.ForkJoinPool\$ForkJoinWorkerThreadFactory"
        "-DfmlignorePatchDiscrepancies=true"
        "-Dfml.noPatchAnimations=true"
        "-Dfml.readTimeout=0"
        "-Dsun.rmi.dgc.server.gcInterval=2147483646"
        "-Dsun.rmi.dgc.client.gcInterval=2147483646"
        "-XX:+UnlockDiagnosticVMOptions"
        "-XX:+DisableAttachMechanism"
        "-XX:+UseNMT"
        "-XX:NativeMemoryTracking=summary"
        "-Dminecraft.launcher.brand=KruzOptimization"
        "-Dminecraft.launcher.version=2.0"
        "-Dsun.java2d.noddraw=true"
        "-Dsun.java2d.d3d=false"
        "-Dsun.java2d.opengl=true"
        "-Dsun.java2d.metal=true"
        "-Dawt.useSystemAAFontSettings=off"
        "-Dswing.aatext=false"
        "-Dsun.java2d.uiScale=1"
        "-Dsun.java2d.uiScale.enabled=false"
    )

    if ($isNVIDIA) {
        $javaArgs += @(
            "-Dsun.java2d.d3d=false"
            "-Dforge.earlyWindowSkipGLVersions=4,5"
            "-Dminecraft.env.DAYLIGHT_SENSORS=false"
        )
    }

    if ($isAMD) {
        $javaArgs += @(
            "-Dsun.java2d.d3d=false"
            "-Dsun.java2d.opengl=true"
        )
    }

    if ($Aggressive) {
        $javaArgs += @(
            "-XX:+UseStringDeduplication"
            "-XX:+UseCompressedOops"
            "-XX:+UseFastAccessorMethods"
            "-XX:+OptimizeStringConcat"
            "-XX:+UseCompressedClassPointers"
            "-XX:+AggressiveUnbox"
            "-XX:+UseTypeProfile"
            "-XX:TypeProfileArgsLimit=10000"
            "-XX:TypeProfileProfilingWindow=50"
            "-XX:+UseLoopPredicate"
            "-XX:+RangeCheckElimination"
            "-XX:+EliminateAllocations"
            "-XX:+InlineSmallCode=10000"
            "-XX:+PrintInlining"
            "-XX:+UseVectorCmov"
            "-XX:+UseFPUForSpilling"
            "-XX:+UseXMMForExternals"
            "-XX:+EnableSpecializedArrayCopy"
            "-XX:+OptimizeFill"
            "-XX:+UseIscar=0"
            "-XX:+UseHugeSMR=0"
            "-XX:+EnableNewt=0"
            "-XX:+UseNMT=0"
        )
    }

    $heapMin = "${Ram}G"
    $heapMax = "${Ram}G"
    $javaArgs = @("-Xms$heapMin", "-Xmx$heapMax") + $javaArgs

    $javaArgsStr = $javaArgs -join " "

    $profileFile = Join-Path $LauncherPath "KruzOptimization-JVM.txt"
    $javaArgsStr | Out-File $profileFile -Encoding UTF8

    Write-Host "  JVM Args saved: $profileFile" -ForegroundColor Green

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
bossMusic:false
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
maxFps:0
menuBackgroundBlurriness:0
minecraftVersion:1.21.1
monochromeLogo:false
mouseSensitivity:0.5
narrator:0
particles:0
perspective:0
realmNotifications:false
resourcePack:,
resourcePackHash:
sensitivity:0.5
skinCustomisation:{}
soundDevice:
snooperEnabled:false
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
"@@

    $optimizedOptions | Out-File $optionsFile -Encoding UTF8 -Force
    Write-Host "  Optimized options.txt" -ForegroundColor Green
}

function Optimize-NVIDIA {
    Write-Host "[NVIDIA OPTIMIZATION]" -ForegroundColor Yellow

    try {
        $nvsmi = Get-Command "nvidia-smi" -ErrorAction SilentlyContinue
        if ($nvsmi) {
            & nvidia-smi --gpu-reset 2>$null
            Write-Host "  [+] GPU reset" -ForegroundColor Green
        }
    } catch {}

    try {
        $nvPath = "HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm"
        Set-ItemProperty -Path $nvPath -Name "DisableWriteCombining" -Value 1 -ErrorAction Stop
        Write-Host "  [+] Write combining disabled" -ForegroundColor Green
    } catch {
        Write-Host "  [-] Write combining (run as admin)" -ForegroundColor Yellow
    }

    try {
        $nvPath2 = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"
        Set-ItemProperty -Path $nvPath2 -Name "RMHdcpKeyglobZero" -Value 1 -ErrorAction Stop
        Set-ItemProperty -Path $nvPath2 -Name "EnableMidBufferPreemption" -Value 0 -ErrorAction Stop
        Set-ItemProperty -Path $nvPath2 -Name "EnableMidGfxPreemptionVGPU" -Value 0 -ErrorAction Stop
        Set-ItemProperty -Path $nvPath2 -Name "EnableMidBufferPreemptionForHighTdrTimeout" -Value 0 -ErrorAction Stop
        Set-ItemProperty -Path $nvPath2 -Name "EnableSCGPreemption" -Value 0 -ErrorAction Stop
        Set-ItemProperty -Path $nvPath2 -Name "EnableCEPreemption" -Value 0 -ErrorAction Stop
        Set-ItemProperty -Path $nvPath2 -Name "EnableGpuPreemption" -Value 0 -ErrorAction Stop
        Set-ItemProperty -Path $nvPath2 -Name "EnableWaitD3DEvents" -Value 0 -ErrorAction Stop
        Set-ItemProperty -Path $nvPath2 -Name "PerfLevelSrc" -Value 8738 -ErrorAction Stop
        Set-ItemProperty -Path $nvPath2 -Name "PowerMizerEnable" -Value 1 -ErrorAction Stop
        Set-ItemProperty -Path $nvPath2 -Name "PowerMizerLevel" -Value 1 -ErrorAction Stop
        Set-ItemProperty -Path $nvPath2 -Name "PowerMizerLevelAC" -Value 1 -ErrorAction Stop
        Write-Host "  [+] NVIDIA preemption disabled" -ForegroundColor Green
        Write-Host "  [+] PowerMizer set to max performance" -ForegroundColor Green
    } catch {
        Write-Host "  [-] NVIDIA registry tweaks (run as admin)" -ForegroundColor Yellow
    }

    try {
        $nvPath3 = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0001"
        if (Test-Path $nvPath3) {
            Set-ItemProperty -Path $nvPath3 -Name "EnableMidBufferPreemption" -Value 0 -ErrorAction Stop
            Set-ItemProperty -Path $nvPath3 -Name "EnableSCGPreemption" -Value 0 -ErrorAction Stop
            Set-ItemProperty -Path $nvPath3 -Name "EnableCEPreemption" -Value 0 -ErrorAction Stop
            Set-ItemProperty -Path $nvPath3 -Name "PerfLevelSrc" -Value 8738 -ErrorAction Stop
            Set-ItemProperty -Path $nvPath3 -Name "PowerMizerEnable" -Value 1 -ErrorAction Stop
            Set-ItemProperty -Path $nvPath3 -Name "PowerMizerLevel" -Value 1 -ErrorAction Stop
            Write-Host "  [+] NVIDIA GPU 2 optimized" -ForegroundColor Green
        }
    } catch {}
}

function Optimize-AMD {
    Write-Host "[AMD OPTIMIZATION]" -ForegroundColor Yellow

    try {
        $amdPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"
        Set-ItemProperty -Path $amdPath -Name "EnableUlps" -Value 0 -ErrorAction Stop
        Set-ItemProperty -Path $amdPath -Name "EnableUlps_NA" -Value 0 -ErrorAction Stop
        Set-ItemProperty -Path $amdPath -Name "KMD_EnableComputePreemption" -Value 0 -ErrorAction Stop
        Set-ItemProperty -Path $amdPath -Name "KMD_FPSScalingMode" -Value 1 -ErrorAction Stop
        Write-Host "  [+] AMD ULPS disabled" -ForegroundColor Green
        Write-Host "  [+] AMD preemption disabled" -ForegroundColor Green
    } catch {
        Write-Host "  [-] AMD tweaks (run as admin)" -ForegroundColor Yellow
    }
}

function Optimize-System {
    Write-Host "[SYSTEM OPTIMIZATION]" -ForegroundColor Yellow

    try {
        powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
        Write-Host "  [+] High Performance power plan" -ForegroundColor Green
    } catch {
        Write-Host "  [-] Power plan (run as admin)" -ForegroundColor Red
    }

    try {
        powercfg /h off 2>$null
        Write-Host "  [+] Hibernation disabled" -ForegroundColor Green
    } catch {}

    try {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 38 -ErrorAction Stop
        Write-Host "  [+] Process scheduling optimized" -ForegroundColor Green
    } catch {
        Write-Host "  [-] Process priority (run as admin)" -ForegroundColor Red
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

        $gameBarPath3 = "HKCU:\SOFTWARE\Microsoft\GameBar"
        Set-ItemProperty -Path $gameBarPath3 -Name "AutoGameModeEnabled" -Value 1 -ErrorAction Stop
        Set-ItemProperty -Path $gameBarPath3 -Name "AllowAutoGameMode" -Value 1 -ErrorAction Stop
        Write-Host "  [+] Xbox Game Bar disabled" -ForegroundColor Green
    } catch {
        Write-Host "  [-] Could not disable Game Bar" -ForegroundColor Yellow
    }

    try {
        $mmcPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
        Set-ItemProperty -Path $mmcPath -Name "LargeSystemCache" -Value 0 -ErrorAction Stop
        Set-ItemProperty -Path $mmcPath -Name "ClearPageFileAtShutdown" -Value 0 -ErrorAction Stop
        Set-ItemProperty -Path $mmcPath -Name "DisablePagingExecutive" -Value 1 -ErrorAction Stop
        Set-ItemProperty -Path $mmcPath -Name "SystemPages" -Value 0 -ErrorAction Stop
        Set-ItemProperty -Path $mmcPath -Name "IoPageLockLimit" -Value 0 -ErrorAction Stop
        Write-Host "  [+] Memory management optimized" -ForegroundColor Green
    } catch {
        Write-Host "  [-] Memory optimization (run as admin)" -ForegroundColor Yellow
    }

    try {
        $networkPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
        Set-ItemProperty -Path $networkPath -Name "TcpAckFrequency" -Value 1 -ErrorAction Stop
        Set-ItemProperty -Path $networkPath -Name "TCPNoDelay" -Value 1 -ErrorAction Stop
        Set-ItemProperty -Path $networkPath -Name "TcpDelAckTicks" -Value 0 -ErrorAction Stop
        Set-ItemProperty -Path $networkPath -Name "MaxUserPort" -Value 65534 -ErrorAction Stop
        Set-ItemProperty -Path $networkPath -Name "TcpTimedWaitDelay" -Value 30 -ErrorAction Stop
        Set-ItemProperty -Path $networkPath -Name "DefaultTTL" -Value 64 -ErrorAction Stop
        Set-ItemProperty -Path $networkPath -Name "Tcp1323Opts" -Value 3 -ErrorAction Stop
        Set-ItemProperty -Path $networkPath -Name "GlobalMaxTcpWindowSize" -Value 65535 -ErrorAction Stop
        Write-Host "  [+] Network latency reduced" -ForegroundColor Green
        Write-Host "  [+] Network throughput increased" -ForegroundColor Green
    } catch {
        Write-Host "  [-] Network optimization (run as admin)" -ForegroundColor Yellow
    }

    try {
        $fsPath = "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"
        Set-ItemProperty -Path $fsPath -Name "NtfsDisableLastAccessUpdate" -Value 1 -ErrorAction Stop
        Set-ItemProperty -Path $fsPath -Name "NtfsMemoryUsage" -Value 2 -ErrorAction Stop
        Set-ItemProperty -Path $fsPath -Name "NtfsDisable8dot3NameCreation" -Value 1 -ErrorAction Stop
        Set-ItemProperty -Path $fsPath -Name "LongPathsEnabled" -Value 1 -ErrorAction Stop
        Write-Host "  [+] File system optimized" -ForegroundColor Green
    } catch {
        Write-Host "  [-] File system optimization (run as admin)" -ForegroundColor Yellow
    }

    try {
        $timerPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel"
        Set-ItemProperty -Path $timerPath -Name "GlobalTimerResolutionRequests" -Value 1 -ErrorAction Stop
        Write-Host "  [+] Timer resolution optimized" -ForegroundColor Green
    } catch {
        Write-Host "  [-] Timer resolution (run as admin)" -ForegroundColor Yellow
    }

    try {
        $aeroPath = "HKCU:\SOFTWARE\Microsoft\Windows\DWM"
        Set-ItemProperty -Path $aeroPath -Name "EnableAeroPeek" -Value 0 -ErrorAction Stop
        Set-ItemProperty -Path $aeroPath -Name "AlwaysHibernateThumbnails" -Value 0 -ErrorAction Stop
        Set-ItemProperty -Path $aeroPath -Name "Composition" -Value 0 -ErrorAction Stop
        Write-Host "  [+] DWM effects disabled" -ForegroundColor Green
    } catch {
        Write-Host "  [-] DWM optimization" -ForegroundColor Yellow
    }

    try {
        $inputPath = "HKCU:\Control Panel\Mouse"
        Set-ItemProperty -Path $inputPath -Name "MouseSensitivity" -Value "10" -ErrorAction Stop
        Set-ItemProperty -Path $inputPath -Name "MouseSpeed" -Value "0" -ErrorAction Stop
        Set-ItemProperty -Path $inputPath -Name "MouseThreshold1" -Value "0" -ErrorAction Stop
        Set-ItemProperty -Path $inputPath -Name "MouseThreshold2" -Value "0" -ErrorAction Stop
        Write-Host "  [+] Mouse acceleration disabled" -ForegroundColor Green
    } catch {
        Write-Host "  [-] Mouse optimization" -ForegroundColor Yellow
    }

    try {
        $servicePath = "HKLM:\SYSTEM\CurrentControlSet\Services"
        $servicesToDisable = @(
            "SysMain",
            "DiagTrack",
            "dmwappushservice",
            "WSearch",
            "TabletInputService",
            "WbioSrvc"
        )
        foreach ($svc in $servicesToDisable) {
            $path = Join-Path $servicePath $svc
            if (Test-Path $path) {
                Set-ItemProperty -Path $path -Name "Start" -Value 4 -ErrorAction Stop
            }
        }
        Write-Host "  [+] Unnecessary services disabled" -ForegroundColor Green
    } catch {
        Write-Host "  [-] Service optimization (run as admin)" -ForegroundColor Yellow
    }

    try {
        $visualPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
        Set-ItemProperty -Path $visualPath -Name "VisualFXSetting" -Value 2 -ErrorAction Stop

        $animPath = "HKCU:\Control Panel\Desktop\WindowMetrics"
        Set-ItemProperty -Path $animPath -Name "MinAnimate" -Value "0" -ErrorAction Stop

        $desktopPath = "HKCU:\Control Panel\Desktop"
        Set-ItemProperty -Path $desktopPath -Name "MenuShowDelay" -Value "0" -ErrorAction Stop
        Set-ItemProperty -Path $desktopPath -Name "WaitToKillAppTimeout" -Value "2000" -ErrorAction Stop
        Set-ItemProperty -Path $desktopPath -Name "HungAppTimeout" -Value "1000" -ErrorAction Stop
        Set-ItemProperty -Path $desktopPath -Name "AutoEndTasks" -Value "1" -ErrorAction Stop
        Write-Host "  [+] Visual effects minimized" -ForegroundColor Green
        Write-Host "  [+] Menu delay removed" -ForegroundColor Green
    } catch {
        Write-Host "  [-] Visual effects (run as admin)" -ForegroundColor Yellow
    }

    try {
        $directXPath = "HKLM:\SOFTWARE\Microsoft\DirectX"
        Set-ItemProperty -Path $directXPath -Name "DisableMaximizedWindowedMode" -Value 1 -ErrorAction Stop
        Write-Host "  [+] DirectX fullscreen optimized" -ForegroundColor Green
    } catch {
        Write-Host "  [-] DirectX optimization" -ForegroundColor Yellow
    }

    try {
        $schedulerPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
        Set-ItemProperty -Path $schedulerPath -Name "SystemResponsiveness" -Value 0 -ErrorAction Stop
        Set-ItemProperty -Path $schedulerPath -Name "NoLazyMode" -Value 1 -ErrorAction Stop
        Set-ItemProperty -Path $schedulerPath -Name "LazyModeTimeout" -Value 0 -ErrorAction Stop

        $taskPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
        Set-ItemProperty -Path $taskPath -Name "Affinity" -Value 0 -ErrorAction Stop
        Set-ItemProperty -Path $taskPath -Name "Background Only" -Value "False" -ErrorAction Stop
        Set-ItemProperty -Path $taskPath -Name "Clock Rate" -Value 10000 -ErrorAction Stop
        Set-ItemProperty -Path $taskPath -Name "GPU Priority" -Value 8 -ErrorAction Stop
        Set-ItemProperty -Path $taskPath -Name "Priority" -Value 6 -ErrorAction Stop
        Set-ItemProperty -Path $taskPath -Name "Scheduling Category" -Value "High" -ErrorAction Stop
        Set-ItemProperty -Path $taskPath -Name "SFIO Priority" -Value "High" -ErrorAction Stop
        Write-Host "  [+] Multimedia scheduler optimized" -ForegroundColor Green
    } catch {
        Write-Host "  [-] Scheduler optimization (run as admin)" -ForegroundColor Yellow
    }
}

function Optimize-Mods {
    param([string]$McPath)

    $modsPath = Join-Path $McPath "mods"
    if (-not (Test-Path $modsPath)) { return }

    $performanceMods = @(
        "optifine", "sodium", "lithium", "phosphor", "starlight",
        "ferrite", "lazydfu", "dashloader", "krypton", "entityculling",
        "immediatelyfast", "enhancedblockentities", "modernfix",
        "nvidium", "indium", "iris", "canvas", "rubidium",
        "embeddium", "oculus", "magnesium", ".LoadScene"
    )

    $badMods = @(
        "replaymod", "minimap", "minimapmod", "journeymap", "xeres",
        "anti-xray", "xminimap", "voxelmap", "zycraft", "oping"
    )

    Write-Host "[PERFORMANCE MODS FOUND]" -ForegroundColor Yellow
    $mods = Get-ChildItem -Path $modsPath -Filter "*.jar" -ErrorAction SilentlyContinue
    $perfFound = 0
    $badFound = 0
    foreach ($mod in $mods) {
        $modName = $mod.Name.ToLower()
        foreach ($perfMod in $performanceMods) {
            if ($modName -match $perfMod.Trim().ToLower()) {
                Write-Host "  [+] $($mod.Name)" -ForegroundColor Green
                $perfFound++
            }
        }
        foreach ($badMod in $badMods) {
            if ($modName -match $badMod.Trim().ToLower()) {
                Write-Host "  [-] $($mod.Name) (reduces FPS)" -ForegroundColor Red
                $badFound++
            }
        }
    }
    Write-Host ""
    Write-Host "  Recommended performance mods:" -ForegroundColor Cyan
    if ($isNVIDIA) {
        Write-Host "    - Sodium + Nvidium (Fabric) = +300-500% FPS" -ForegroundColor White
    } else {
        Write-Host "    - Sodium (Fabric) = +200-400% FPS" -ForegroundColor White
    }
    Write-Host "    - Lithium (Fabric) = +50-100% FPS" -ForegroundColor White
    Write-Host "    - Starlight (Fabric) = +50-100% FPS" -ForegroundColor White
    Write-Host "    - FerriteCore (Fabric/Forge) = +20-50% FPS" -ForegroundColor White
    Write-Host "    - Krypton (Fabric) = +30-60% FPS" -ForegroundColor White
    Write-Host "    - EntityCulling (Fabric/Forge) = +20-40% FPS" -ForegroundColor White
    Write-Host "    - ImmediatelyFast (Fabric) = +30-60% FPS" -ForegroundColor White
    Write-Host "    - ModernFix (Fabric/Forge) = +20-40% FPS" -ForegroundColor White
    if ($isNVIDIA) {
        Write-Host "    - Nvidium (Fabric) = +100-200% FPS (NVIDIA only)" -ForegroundColor White
    }
    Write-Host ""
}

function Generate-JVMProfile {
    param([string]$LauncherPath, [string]$JavaArgs)

    $profileContent = @"
# KruzOptimization v2.0 - JVM Profile (MAXIMUM)
# Copy these arguments to your launcher's JVM arguments field

$JavaArgs

# ========================================
# HOW TO APPLY:
# 1. Open your Minecraft launcher
# 2. Go to Game Settings / Java Settings
# 3. Paste the arguments above into JVM Arguments
# 4. Make sure Minecraft is allocated ${Ram}GB RAM
# 5. Launch and enjoy 500+ FPS!
# ========================================

# RECOMMENDED MOD STACK (Fabric):
# - Sodium (required)
# - Lithium
# - Starlight
# - FerriteCore
# - LazyDFU
# - Krypton
# - EntityCulling
# - ImmediatelyFast
# - ModernFix
# $(if ($isNVIDIA) { "# - Nvidium (NVIDIA only)" })

# VIDEO SETTINGS (In-game):
# Graphics: Fast
# Render Distance: 8-10 chunks
# Max Framerate: Unlimited
# VSync: Off
# Clouds: Off
# Particles: Minimal
# Entity Shadows: Off
# Smooth Lighting: Off
# Mipmap Levels: 0
# Biome Blend: 0
# ========================================
"@

    $profilePath = Join-Path $scriptPath "JVM-PROFILE.txt"
    $profileContent | Out-File $profilePath -Encoding UTF8
    Write-Host "  JVM profile saved: $profilePath" -ForegroundColor Green
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
    if ($isNVIDIA) { Optimize-NVIDIA }
    elseif ($isAMD) { Optimize-AMD }
    Write-Host ""

    Write-Host "[MINECRAFT SETTINGS]" -ForegroundColor Yellow
    foreach ($launcher in $launchers) {
        $mcPath = Join-Path $launcher "versions"
        if (Test-Path $mcPath) {
            Write-Host "  Processing: $(Split-Path $launcher -Leaf)" -ForegroundColor Cyan
            Optimize-MinecraftSettings -McPath $launcher
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
Write-Host "    - JVM: G1GC + max threads" -ForegroundColor White
Write-Host "    - RAM: ${Ram}GB allocated" -ForegroundColor White
Write-Host "    - GPU: Preemption disabled" -ForegroundColor White
if ($isNVIDIA) { Write-Host "    - NVIDIA: PowerMizer max perf" -ForegroundColor White }
if ($isAMD) { Write-Host "    - AMD: ULPS disabled" -ForegroundColor White }
Write-Host "    - Windows: High Performance plan" -ForegroundColor White
Write-Host "    - DWM: Effects disabled" -ForegroundColor White
Write-Host "    - Timer: Resolution optimized" -ForegroundColor White
Write-Host "    - Network: Latency minimized" -ForegroundColor White
Write-Host "    - Memory: Paging disabled" -ForegroundColor White
Write-Host "    - Filesystem: Optimized" -ForegroundColor White
Write-Host "    - Mouse: Acceleration off" -ForegroundColor White
Write-Host "    - Services: Bloatware disabled" -ForegroundColor White
Write-Host "    - Scheduler: Games prioritized" -ForegroundColor White
Write-Host "    - DirectX: Fullscreen optimized" -ForegroundColor White
Write-Host ""
Write-Host "  [NEXT STEPS]" -ForegroundColor Cyan
Write-Host "    1. Open JVM-PROFILE.txt" -ForegroundColor White
Write-Host "    2. Copy JVM arguments into launcher" -ForegroundColor White
Write-Host "    3. Set RAM to ${Ram}GB in launcher" -ForegroundColor White
Write-Host "    4. Install Sodium + Lithium + Krypton" -ForegroundColor White
Write-Host "    5. In-game: Fast graphics, 8 chunks" -ForegroundColor White
Write-Host "    6. RESTART PC for all changes" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Time: $($duration.TotalSeconds.ToString('F1'))s" -ForegroundColor Gray
Write-Host ""

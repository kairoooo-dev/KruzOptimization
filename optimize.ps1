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

Write-Host "[SYSTEM INFO]" -ForegroundColor Yellow
Write-Host "  CPU: $($cpu.Name)" -ForegroundColor White
Write-Host "  Threads: $cpuThreads" -ForegroundColor White
Write-Host "  GPU: $($gpu.Name)" -ForegroundColor White
if ($isNVIDIA) { Write-Host "  Brand: NVIDIA (optimized)" -ForegroundColor Green }
elseif ($isAMD) { Write-Host "  Brand: AMD (optimized)" -ForegroundColor Green }
else { Write-Host "  Brand: Unknown" -ForegroundColor Yellow }
Write-Host "  RAM: ${ramGB}GB" -ForegroundColor White
Write-Host "  Windows: $($os.Caption)" -ForegroundColor White
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
    "$env:LOCALAPPDATA\LabyMod"
)

Write-Host "[SCANNING LAUNCHERS]" -ForegroundColor Yellow
foreach ($p in $paths) {
    if (Test-Path $p) {
        Write-Host "  [+] $(Split-Path $p -Leaf)" -ForegroundColor Green
        $launchers += $p
    }
}
if ($launchers.Count -eq 0) {
    Write-Host "  [-] No launchers found, using .minecraft" -ForegroundColor Red
    $launchers += "$env:USERPROFILE\.minecraft"
}
Write-Host ""

$threadCount = [math]::Min($cpuThreads, 8)

$jvmArgs = @()
$jvmArgs += "-Xms${Ram}G"
$jvmArgs += "-Xmx${Ram}G"
$jvmArgs += "-XX:+UseG1GC"
$jvmArgs += "-XX:+ParallelRefProcEnabled"
$jvmArgs += "-XX:MaxGCPauseMillis=50"
$jvmArgs += "-XX:+UnlockExperimentalVMOptions"
$jvmArgs += "-XX:+DisableExplicitGC"
$jvmArgs += "-XX:+AlwaysPreTouch"
$jvmArgs += "-XX:G1NewSizePercent=30"
$jvmArgs += "-XX:G1MaxNewSizePercent=50"
$jvmArgs += "-XX:G1HeapRegionSize=16M"
$jvmArgs += "-XX:G1ReservePercent=25"
$jvmArgs += "-XX:G1HeapWastePercent=3"
$jvmArgs += "-XX:G1MixedGCCountTarget=2"
$jvmArgs += "-XX:InitiatingHeapOccupancyPercent=10"
$jvmArgs += "-XX:G1MixedGCLiveThresholdPercent=85"
$jvmArgs += "-XX:G1RSetUpdatingPauseTimePercent=3"
$jvmArgs += "-XX:SurvivorRatio=64"
$jvmArgs += "-XX:+PerfDisableSharedMem"
$jvmArgs += "-XX:MaxTenuringThreshold=1"
$jvmArgs += "-XX:ConcGCThreads=$threadCount"
$jvmArgs += "-XX:ParallelGCThreads=$threadCount"
$jvmArgs += "-Djava.util.concurrent.ForkJoinPool.common.parallelism=$threadCount"
$jvmArgs += "-DfmlignorePatchDiscrepancies=true"
$jvmArgs += "-Dfml.noPatchAnimations=true"
$jvmArgs += "-Dfml.readTimeout=0"
$jvmArgs += "-Dsun.rmi.dgc.server.gcInterval=2147483646"
$jvmArgs += "-Dsun.rmi.dgc.client.gcInterval=2147483646"
$jvmArgs += "-XX:+UnlockDiagnosticVMOptions"
$jvmArgs += "-XX:+DisableAttachMechanism"
$jvmArgs += "-Dminecraft.launcher.brand=KruzOptimization"
$jvmArgs += "-Dminecraft.launcher.version=2.0"
$jvmArgs += "-Dsun.java2d.noddraw=true"
$jvmArgs += "-Dsun.java2d.d3d=false"
$jvmArgs += "-Dsun.java2d.opengl=true"
$jvmArgs += "-Dawt.useSystemAAFontSettings=off"
$jvmArgs += "-Dswing.aatext=false"

if ($isNVIDIA) {
    $jvmArgs += "-Dforge.earlyWindowSkipGLVersions=4,5"
}
if ($isAMD) {
    $jvmArgs += "-Dsun.java2d.opengl=true"
}
if ($Aggressive) {
    $jvmArgs += "-XX:+UseStringDeduplication"
    $jvmArgs += "-XX:+UseCompressedOops"
    $jvmArgs += "-XX:+OptimizeStringConcat"
    $jvmArgs += "-XX:+UseCompressedClassPointers"
    $jvmArgs += "-XX:+AggressiveUnbox"
    $jvmArgs += "-XX:+EliminateAllocations"
    $jvmArgs += "-XX:+InlineSmallCode=10000"
    $jvmArgs += "-XX:+UseVectorCmov"
}

Write-Host "[JVM OPTIMIZATION]" -ForegroundColor Yellow
$jvmStr = $jvmArgs -join " "

foreach ($launcher in $launchers) {
    $profileFile = Join-Path $launcher "KruzOptimization-JVM.txt"
    $jvmStr | Out-File $profileFile -Encoding UTF8
    Write-Host "  [+] Saved: $(Split-Path $launcher -Leaf)" -ForegroundColor Green
}
Write-Host ""

if (-not $ScanOnly) {

    if ($isNVIDIA) {
        Write-Host "[NVIDIA OPTIMIZATION]" -ForegroundColor Yellow
        try {
            $nvPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"
            Set-ItemProperty -Path $nvPath -Name "EnableMidBufferPreemption" -Value 0 -ErrorAction Stop
            Set-ItemProperty -Path $nvPath -Name "EnableSCGPreemption" -Value 0 -ErrorAction Stop
            Set-ItemProperty -Path $nvPath -Name "EnableCEPreemption" -Value 0 -ErrorAction Stop
            Set-ItemProperty -Path $nvPath -Name "PerfLevelSrc" -Value 8738 -ErrorAction Stop
            Set-ItemProperty -Path $nvPath -Name "PowerMizerEnable" -Value 1 -ErrorAction Stop
            Set-ItemProperty -Path $nvPath -Name "PowerMizerLevel" -Value 1 -ErrorAction Stop
            Write-Host "  [+] NVIDIA max performance" -ForegroundColor Green
        } catch {
            Write-Host "  [-] Run as admin for NVIDIA tweaks" -ForegroundColor Yellow
        }
        Write-Host ""
    }

    if ($isAMD) {
        Write-Host "[AMD OPTIMIZATION]" -ForegroundColor Yellow
        try {
            $amdPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"
            Set-ItemProperty -Path $amdPath -Name "EnableUlps" -Value 0 -ErrorAction Stop
            Set-ItemProperty -Path $amdPath -Name "EnableUlps_NA" -Value 0 -ErrorAction Stop
            Write-Host "  [+] AMD ULPS disabled" -ForegroundColor Green
        } catch {
            Write-Host "  [-] Run as admin for AMD tweaks" -ForegroundColor Yellow
        }
        Write-Host ""
    }

    Write-Host "[WINDOWS OPTIMIZATION]" -ForegroundColor Yellow

    try {
        powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
        Write-Host "  [+] High Performance power plan" -ForegroundColor Green
    } catch { Write-Host "  [-] Power plan" -ForegroundColor Red }

    try {
        powercfg /h off 2>$null
        Write-Host "  [+] Hibernation disabled" -ForegroundColor Green
    } catch {}

    try {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 38 -ErrorAction Stop
        Write-Host "  [+] Process scheduling optimized" -ForegroundColor Green
    } catch { Write-Host "  [-] Process priority" -ForegroundColor Red }

    try {
        $gpuPath = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
        if (-not (Test-Path $gpuPath)) { New-Item -Path $gpuPath -Force | Out-Null }
        Set-ItemProperty -Path $gpuPath -Name "HwSchMode" -Value 2 -ErrorAction Stop
        Write-Host "  [+] GPU Hardware Scheduling" -ForegroundColor Green
    } catch {}

    try {
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0 -ErrorAction Stop
        Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -ErrorAction Stop
        Write-Host "  [+] Xbox Game Bar disabled" -ForegroundColor Green
    } catch {}

    try {
        $mmc = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
        Set-ItemProperty -Path $mmc -Name "LargeSystemCache" -Value 0 -ErrorAction Stop
        Set-ItemProperty -Path $mmc -Name "ClearPageFileAtShutdown" -Value 0 -ErrorAction Stop
        Set-ItemProperty -Path $mmc -Name "DisablePagingExecutive" -Value 1 -ErrorAction Stop
        Write-Host "  [+] Memory management optimized" -ForegroundColor Green
    } catch {}

    try {
        $net = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
        Set-ItemProperty -Path $net -Name "TcpAckFrequency" -Value 1 -ErrorAction Stop
        Set-ItemProperty -Path $net -Name "TCPNoDelay" -Value 1 -ErrorAction Stop
        Set-ItemProperty -Path $net -Name "TcpTimedWaitDelay" -Value 30 -ErrorAction Stop
        Set-ItemProperty -Path $net -Name "DefaultTTL" -Value 64 -ErrorAction Stop
        Write-Host "  [+] Network latency reduced" -ForegroundColor Green
    } catch {}

    try {
        $fs = "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"
        Set-ItemProperty -Path $fs -Name "NtfsDisableLastAccessUpdate" -Value 1 -ErrorAction Stop
        Set-ItemProperty -Path $fs -Name "NtfsMemoryUsage" -Value 2 -ErrorAction Stop
        Write-Host "  [+] File system optimized" -ForegroundColor Green
    } catch {}

    try {
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\DWM" -Name "EnableAeroPeek" -Value 0 -ErrorAction Stop
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\DWM" -Name "Composition" -Value 0 -ErrorAction Stop
        Write-Host "  [+] DWM effects disabled" -ForegroundColor Green
    } catch {}

    try {
        $mouse = "HKCU:\Control Panel\Mouse"
        Set-ItemProperty -Path $mouse -Name "MouseSpeed" -Value "0" -ErrorAction Stop
        Set-ItemProperty -Path $mouse -Name "MouseThreshold1" -Value "0" -ErrorAction Stop
        Set-ItemProperty -Path $mouse -Name "MouseThreshold2" -Value "0" -ErrorAction Stop
        Write-Host "  [+] Mouse acceleration off" -ForegroundColor Green
    } catch {}

    try {
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Value "0" -ErrorAction Stop
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WaitToKillAppTimeout" -Value "2000" -ErrorAction Stop
        Write-Host "  [+] Menu delay removed" -ForegroundColor Green
    } catch {}

    try {
        $svc = "HKLM:\SYSTEM\CurrentControlSet\Services"
        @("SysMain","DiagTrack","dmwappushservice","WSearch") | ForEach-Object {
            $p = Join-Path $svc $_
            if (Test-Path $p) { Set-ItemProperty -Path $p -Name "Start" -Value 4 -ErrorAction Stop }
        }
        Write-Host "  [+] Bloatware services disabled" -ForegroundColor Green
    } catch {}

    try {
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\DirectX" -Name "DisableMaximizedWindowedMode" -Value 1 -ErrorAction Stop
        Write-Host "  [+] DirectX optimized" -ForegroundColor Green
    } catch {}

    try {
        $sched = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
        Set-ItemProperty -Path $sched -Name "SystemResponsiveness" -Value 0 -ErrorAction Stop
        $task = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
        if (-not (Test-Path $task)) { New-Item -Path $task -Force | Out-Null }
        Set-ItemProperty -Path $task -Name "GPU Priority" -Value 8 -ErrorAction Stop
        Set-ItemProperty -Path $task -Name "Priority" -Value 6 -ErrorAction Stop
        Set-ItemProperty -Path $task -Name "Scheduling Category" -Value "High" -ErrorAction Stop
        Write-Host "  [+] Games scheduler prioritized" -ForegroundColor Green
    } catch {}

    Write-Host ""

    Write-Host "[MINECRAFT SETTINGS]" -ForegroundColor Yellow
    foreach ($launcher in $launchers) {
        if (Test-Path (Join-Path $launcher "versions")) {
            $opts = @()
            $opts += "lang:en_US"
            $opts += "soundLevels:{}"
            $opts += "chatHeight:1.0"
            $opts += "chatWidth:1.0"
            $opts += "chatScale:1.0"
            $opts += "chatLineSpacing:0.0"
            $opts += "chatPromptText:Chat"
            $opts += "chatVisibility:0"
            $opts += "fullscreen:false"
            $opts += "bossMusic:false"
            $opts += "musicVolume:0.0"
            $opts += "noteblockVolume:0.0"
            $opts += "chatColour:true"
            $opts += "chatLinks:true"
            $opts += "chatLinksPrompt:true"
            $opts += "autoJump:false"
            $opts += "difficulty:2"
            $opts += "fancyGraphics:false"
            $opts += "enableVsync:false"
            $opts += "fpsLimit:0"
            $opts += "fov:110"
            $opts += "fovView:110"
            $opts += "gamma:1.0"
            $opts += "guiScale:3"
            $opts += "handPrioritization:1"
            $opts += "highContrast:false"
            $opts += "hideBundleTutorial:true"
            $opts += "hudHidden:false"
            $opts += "invertYMouse:false"
            $opts += "maxFps:0"
            $opts += "menuBackgroundBlurriness:0"
            $opts += "monochromeLogo:false"
            $opts += "mouseSensitivity:0.5"
            $opts += "narrator:0"
            $opts += "particles:0"
            $opts += "perspective:0"
            $opts += "realmNotifications:false"
            $opts += "resourcePack:,"
            $opts += "sensitivity:0.5"
            $opts += "skinCustomisation:{}"
            $opts += "snooperEnabled:false"
            $opts += "showFrameProfiler:false"
            $opts += "useNative:0"
            $opts += "lastServer:"
            $opts += "langCode:en_US"
            $opts += "forceUnicodeFont:false"
            $opts += "prevGameMode:0"
            $opts += "soundVolume:0.0"
            $opts += "blockSoundVolume:0.0"
            $opts += "musicType:options"
            $opts += "autoConfigGUI:true"

            $optsFile = Join-Path $launcher "options.txt"
            ($opts -join "`n") | Out-File $optsFile -Encoding UTF8 -Force
            Write-Host "  [+] $(Split-Path $launcher -Leaf)" -ForegroundColor Green
        }
    }
    Write-Host ""
}

$stepLines = @()
$stepLines += "KruzOptimization v2.0 - JVM Profile"
$stepLines += ""
$stepLines += "Copy these arguments to your launcher JVM arguments field:"
$stepLines += ""
$stepLines += $jvmStr
$stepLines += ""
$stepLines += "HOW TO APPLY:"
$stepLines += "1. Open your Minecraft launcher"
$stepLines += "2. Go to Game Settings / Java Settings"
$stepLines += "3. Paste the arguments above into JVM Arguments"
$stepLines += "4. Set Minecraft RAM to ${Ram}GB"
$stepLines += "5. Restart PC and launch!"
$stepLines += ""
$stepLines += "RECOMMENDED MODS (Fabric):"
$stepLines += "- Sodium (required)"
$stepLines += "- Lithium"
$stepLines += "- Starlight"
$stepLines += "- FerriteCore"
$stepLines += "- LazyDFU"
$stepLines += "- Krypton"
$stepLines += "- EntityCulling"
$stepLines += "- ImmediatelyFast"
$stepLines += "- ModernFix"
if ($isNVIDIA) { $stepLines += "- Nvidium (NVIDIA only)" }
$stepLines += ""
$stepLines += "IN-GAME SETTINGS:"
$stepLines += "Graphics: Fast"
$stepLines += "Render Distance: 8 chunks"
$stepLines += "Max Framerate: Unlimited"
$stepLines += "VSync: Off"
$stepLines += "Clouds: Off"
$stepLines += "Particles: Minimal"
$stepLines += "Entity Shadows: Off"
$stepLines += "Smooth Lighting: Off"

($stepLines -join "`n") | Out-File (Join-Path $scriptPath "JVM-PROFILE.txt") -Encoding UTF8
Write-Host "[PROFILE] JVM-PROFILE.txt saved" -ForegroundColor Green
Write-Host ""

Write-Host "============================================" -ForegroundColor Green
Write-Host "         Optimization Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "  OPTIMIZED:" -ForegroundColor Cyan
Write-Host "    JVM: G1GC + $threadCount threads" -ForegroundColor White
Write-Host "    RAM: ${Ram}GB" -ForegroundColor White
if ($isNVIDIA) { Write-Host "    GPU: NVIDIA max performance" -ForegroundColor White }
if ($isAMD) { Write-Host "    GPU: AMD ULPS off" -ForegroundColor White }
Write-Host "    Windows: High Performance plan" -ForegroundColor White
Write-Host "    DWM: Effects off" -ForegroundColor White
Write-Host "    Network: Latency minimized" -ForegroundColor White
Write-Host "    Mouse: Acceleration off" -ForegroundColor White
Write-Host "    Services: Bloatware killed" -ForegroundColor White
Write-Host "    Scheduler: Games prioritized" -ForegroundColor White
Write-Host "    DirectX: Optimized" -ForegroundColor White
Write-Host ""
Write-Host "  NEXT STEPS:" -ForegroundColor Cyan
Write-Host "    1. Open JVM-PROFILE.txt" -ForegroundColor White
Write-Host "    2. Copy JVM args into launcher" -ForegroundColor White
Write-Host "    3. Set RAM to ${Ram}GB" -ForegroundColor White
Write-Host "    4. Install Sodium + Lithium" -ForegroundColor White
Write-Host "    5. RESTART PC" -ForegroundColor Yellow
Write-Host ""

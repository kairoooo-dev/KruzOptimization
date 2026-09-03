# KruzOptimization

**Minecraft FPS Optimizer** - Get 500+ FPS with one click.

## What It Does

- Optimizes JVM garbage collector (G1GC)
- Allocates optimal RAM based on your system
- Enables GPU Hardware Scheduling
- Sets High Performance power plan
- Disables Xbox Game Bar
- Reduces network latency
- Optimizes file system
- Generates JVM profile for your launcher

## Usage

```powershell
# Default (auto-detects RAM)
.\optimize.ps1

# Specify RAM allocation (GB)
.\optimize.ps1 -Ram 8

# Aggressive optimization (advanced JVM flags)
.\optimize.ps1 -Aggressive

# Scan only, no system changes
.\optimize.ps1 -ScanOnly
```

## Requirements

- Windows 10/11
- Minecraft Java Edition
- PowerShell 5.1+

## Recommended Mods

| Mod | FPS Boost | Loader |
|-----|-----------|--------|
| Sodium | +200-400% | Fabric |
| Lithium | +50-100% | Fabric |
| Starlight | +50-100% | Fabric |
| FerriteCore | +20-50% | Fabric/Forge |
| Krypton | +30-60% | Fabric |
| EntityCulling | +20-40% | Fabric/Forge |
| Nvidium | +100-200% | Fabric (NVIDIA) |
| OptiFine | +50-150% | Forge |

## Launcher Support

- Vanilla (.minecraft)
- Modrinth
- CurseForge
- GDLauncher
- PolyMC / PrismLauncher
- MultiMC
- ATLauncher
- Badlion Client
- Lunar Client
- Flarial
- SKlauncher
- Legacy Launcher
- LabyMod

## How To Apply JVM Args

1. Open your Minecraft launcher
2. Go to **Game Settings** > **Java Settings**
3. Open `JVM-PROFILE.txt` from this folder
4. Copy the JVM arguments
5. Paste into your launcher's **JVM Arguments** field
6. Set Minecraft RAM to match the allocated amount
7. Launch and enjoy!

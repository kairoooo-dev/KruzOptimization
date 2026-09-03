# KruzOptimization v2.0

**Minecraft FPS Optimizer** - MAXIMUM EDITION. Get 500+ FPS with one click.

## What It Does

### JVM Optimization
- G1GC garbage collector (tuned for gaming)
- Max parallel/concurrent GC threads
- AlwaysPreTouch, disable explicit GC
- Aggressive mode: string dedup, compressed pointers, vector CMOV

### GPU Optimization
- **NVIDIA**: PowerMizer max performance, preemption disabled, write combining off
- **AMD**: ULPS disabled, preemption disabled
- GPU Hardware Scheduling enabled

### Windows Optimization
- High Performance power plan
- Hibernation disabled
- DWM effects disabled (Aero Peek off)
- Timer resolution optimized
- Mouse acceleration disabled
- Visual effects minimized
- Menu delay removed
- Xbox Game Bar disabled
- Unnecessary services disabled (SysMain, DiagTrack, WSearch, etc.)
- Multimedia scheduler set to Games mode

### Network Optimization
- TCP ACK frequency reduced
- TCP NoDelay enabled
- Max user port increased
- Timed wait delay reduced
- TTL optimized

### Memory Optimization
- Paging executive disabled
- Large system cache disabled
- Clear page file at shutdown disabled

### File System
- Last access update disabled
- 8.3 name creation disabled
- Long paths enabled

### DirectX
- Maximized windowed mode disabled

## Usage

```powershell
# Default (auto-detects RAM, GPU, CPU)
.\optimize.ps1

# Specify RAM allocation (GB)
.\optimize.ps1 -Ram 8

# Aggressive (advanced JVM flags)
.\optimize.ps1 -Aggressive

# Scan only, no system changes
.\optimize.ps1 -ScanOnly
```

## Requirements

- Windows 10/11
- Minecraft Java Edition
- PowerShell 5.1+
- Run as Administrator for full optimization

## Recommended Mods (Fabric)

| Mod | FPS Boost | Description |
|-----|-----------|-------------|
| Sodium | +200-400% | Rendering engine |
| Nvidium | +100-200% | NVIDIA GPU acceleration |
| Lithium | +50-100% | Game logic optimization |
| Starlight | +50-100% | Light engine rewrite |
| Krypton | +30-60% | Network stack optimization |
| ImmediatelyFast | +30-60% | Immediate mode rendering |
| FerriteCore | +20-50% | Memory optimization |
| EntityCulling | +20-40% | Skip hidden entities |
| ModernFix | +20-40% | Various bug fixes |
| LazyDFU | +10-20% | Disable DataFixerUpper |

## In-Game Settings

```
Graphics: Fast
Render Distance: 8-10 chunks
Max Framerate: Unlimited
VSync: Off
Clouds: Off
Particles: Minimal
Entity Shadows: Off
Smooth Lighting: Off
Mipmap Levels: 0
Biome Blend: 0
Entity Distance: 50%
```

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
- Astralith

## How To Apply

1. Run `.\optimize.ps1` as Administrator
2. Open `JVM-PROFILE.txt`
3. Copy the JVM arguments
4. Open your Minecraft launcher
5. Go to **Game Settings** > **Java Settings**
6. Paste JVM arguments
7. Set RAM to match allocation
8. **Restart PC**
9. Launch Minecraft and enjoy 500+ FPS!

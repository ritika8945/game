# FaceRun Offline

**Your face. Your enemies. Your offline adventure.**

A fully offline retro 2D platformer Android game where users can select photos from their phone, detect/crop faces offline using ML Kit, and assign those faces to game entities like Hero, Enemy, Boss, NPC, and collectibles. Users can also assign custom voice/audio files (.mp3/.wav) from their device to game events.

---

## Features

### Gameplay
- 5 unique themed levels: City Rooftops, Jungle Ruins, School Chaos, Space Factory, Lava Lab
- 2 enemy types: Slime Bot (ground patrol) and Flying Bug (aerial sine-wave)
- Boss fight in Level 5 with state machine AI (patrol → charge → stunned → vulnerable)
- Gem collectibles, energy orbs, checkpoints
- Health/lives system with invincibility frames
- Double jump with coyote time and jump buffer
- Touch controls optimized for mobile
- Pause menu, level select, game over, level complete screens
- Local progress save (highest level, total score, total gems)

### Face Customization
- **Phase 1 — Manual crop**: Select image from gallery → crop manually → assign to entity
- **Phase 2 — ML Kit auto-detect**: Bundled offline ML Kit face detection → bounding box selection → auto-crop → manual adjustment
- Assign faces to: Hero, Enemy Type 1, Enemy Type 2, Boss, NPC, Collectible
- Preview face on entity before applying
- Delete all face data with one button

### Voice & Audio Customization
- Pick `.mp3` or `.wav` files from device for any game sound
- 10 voice categories: Hero Jump, Hero Damage, Hero Death, Enemy Hit, Enemy Death, Boss Roar, Boss Death, Background Music, Level Complete, Game Over
- Background music loops continuously during gameplay
- Preview assigned audio before playing a level
- Delete all voice data with one button
- If no custom voice is assigned, default game sounds play

### Offline-First
- **No backend, no login, no Firebase, no cloud**
- All photos and face data stay locally on device
- ML Kit bundled model — works immediately after install
- No internet permission requested
- No analytics, no ads in MVP

### Privacy
- "Only use photos you own or have permission to use"
- "All face images stay on your device"
- "All voice/audio files stay on your device"
- "This app detects face location only. It does not identify who the person is."
- Delete all face and voice data button
- Reset customization button
- Privacy screen with full policy

---

## Technical Architecture

### Engine & Platform
- **Godot 4.4** (GDScript)
- **Android** target (minSdk 24 / Android 7.0+)
- **Mobile renderer** for performance on low-end devices
- Package: `com.aman.facerunoffline`

### Project Structure

```
game/
├── project.godot              # Godot project config
├── export_presets.cfg         # Android export presets
├── Scripts/
│   ├── Autoload/
│   │   ├── GameManager.gd     # Score, lives, health, level management
│   │   ├── SaveManager.gd     # Local save/load, settings
│   │   └── FaceManager.gd     # Face assignment, texture loading, plugin bridge
│   ├── Player/
│   │   └── player.gd          # Player controller with coyote time, touch input
│   ├── Enemies/
│   │   ├── slime_bot.gd       # Ground patrol enemy
│   │   └── flying_bug.gd      # Aerial sine-wave enemy
│   ├── Boss/
│   │   └── boss_robot.gd      # Boss with FSM (idle/patrol/charge/stunned)
│   ├── Collectibles/
│   │   ├── gem.gd             # Star/gem collectible
│   │   ├── energy_orb.gd      # Health pickup
│   │   └── checkpoint.gd      # Mid-level checkpoint
│   ├── UI/
│   │   ├── main_menu.gd       # Main menu with all navigation
│   │   ├── level_select.gd    # Level selection with unlock state
│   │   ├── game_ui.gd         # HUD with health, score, touch controls
│   │   ├── pause_menu.gd      # Pause overlay
│   │   ├── game_over.gd       # Game over screen
│   │   ├── level_complete.gd  # Level complete screen
│   │   ├── face_setup.gd      # Face assignment UI
│   │   ├── settings.gd        # Settings (audio, touch, reset)
│   │   ├── about.gd           # Credits and attribution
│   │   └── privacy.gd         # Privacy policy and data deletion
│   └── LevelFinishDoor.gd     # Level exit trigger
├── Scenes/
│   ├── UI/                    # All UI scenes (.tscn)
│   ├── Levels/                # Level_01 through Level_05
│   ├── Prefabs/               # Player, enemies, collectibles, boss
│   └── Managers/              # AudioManager, SceneTransition
├── Assets/                    # Sprites, sounds, fonts (from Kenney.nl)
├── android-plugin/            # Godot Android plugin (Kotlin)
│   └── plugin/
│       ├── build.gradle.kts   # ML Kit + Godot dependencies
│       ├── src/main/java/.../FaceRunPlugin.kt  # Face detection bridge
│       └── export_scripts_template/             # Godot export integration
├── LICENSES/                  # Original license files
├── LICENSE                    # Project license with attribution
└── export_presets.cfg         # Android debug + release presets
```

### Android Plugin (FaceRunPlugin)
The plugin bridges Godot with Android native APIs:

| Method | Description |
|--------|-------------|
| `pickImageFromGallery()` | Opens Android gallery picker |
| `detectFacesFromImage(path)` | Runs ML Kit face detection on image |
| `cropFaceToPng(path, l, t, w, h)` | Crops face region and saves as PNG |
| `saveFaceAssignment(type, path)` | Persists face-entity mapping |
| `deleteAllFaceData()` | Removes all face images and assignments |
| `getSavedFaceAssignments()` | Returns JSON of all assignments |

**Signals**: `image_picked`, `faces_detected`, `face_cropped`, `face_detection_failed`, `no_faces_found`, `plugin_ready`

---

## Build Instructions

### Quick Build (One Command)

```bash
git clone https://github.com/ritika8945/game.git
cd game
./build_apk.sh
```

That's it! The script builds the Android plugin, copies everything into place, and exports the APK. Output: `FaceRunOffline-debug.apk`

Install on phone: `adb install FaceRunOffline-debug.apk`

> **Prerequisites:** [Godot 4.4+](https://godotengine.org/download) (with Android export templates), Android SDK (API 24+), Java 17+
>
> If Godot isn't in your PATH, set it: `GODOT_BIN=/path/to/godot ./build_apk.sh`

### Manual Build (Step by Step)

<details>
<summary>Click to expand manual steps</summary>

#### Step 1: Build the Android Plugin
```bash
cd android-plugin
./gradlew assemble
```

#### Step 2: Install Plugin in Godot Project
```bash
mkdir -p addons/FaceRunPlugin/bin/debug addons/FaceRunPlugin/bin/release
cp android-plugin/plugin/build/outputs/aar/FaceRunPlugin-debug.aar addons/FaceRunPlugin/bin/debug/
cp android-plugin/plugin/build/outputs/aar/FaceRunPlugin-release.aar addons/FaceRunPlugin/bin/release/
cp android-plugin/plugin/export_scripts_template/* addons/FaceRunPlugin/
```

#### Step 3: Open in Godot
1. Open `project.godot` in Godot 4.4+
2. Go to Project → Project Settings → Plugins → Enable FaceRunPlugin
3. Install Android Build Template: Project → Install Android Build Template

#### Step 4: Export APK
1. Go to Project → Export
2. Select "Android Debug" preset
3. Click "Export Project"
4. Choose output path for `.apk`

#### Step 5: Export AAB (Release)
1. Select "Android Release" preset
2. Configure signing keystore
3. Export as `.aab`

</details>

### Voice & Audio
Users assign voice/audio files from within the app on their phone (Main Menu → Voice & Audio Setup). No need to add audio files before building.

---

## Attribution & Licenses

### Base Project
**2D Platformer Starter Kit** by AdilDevStuff (Leon Oscar Kidando)
- License: MIT
- Source: https://github.com/AdilDevStuff/2D-Platformer-Starter-Kit
- Used as: Primary game foundation (platformer controller, sprites, levels, audio)

### Android Plugin Template
**Godot Android Plugin Template** by m4gr3d (Fredia Huya-Kouadio)
- License: MIT
- Source: https://github.com/m4gr3d/Godot-Android-Plugin-Template
- Used as: Template for Android plugin architecture

### Face Detection Reference
**ML Kit Samples** by Google
- License: Apache 2.0
- Source: https://github.com/googlesamples/mlkit
- Used as: Reference for ML Kit face detection implementation

### Game Assets
**Kenney.nl** — 2D platformer asset packs
- License: CC0 (Public Domain)
- Source: https://kenney.nl

### Sound Effects
Generated with **Gdfxr** (Sfxr plugin for Godot)

### Engine
**Godot Engine 4.4** — MIT License
- Source: https://godotengine.org

### Face Detection SDK
**Google ML Kit Face Detection** (Bundled)
- Dependency: `com.google.mlkit:face-detection:16.1.7`
- Bundled model — fully offline

---

## Changes from Original Base

### Added
- FaceRun Offline branding, splash, UI identity
- 5 original themed levels (City Rooftops, Jungle Ruins, School Chaos, Space Factory, Lava Lab)
- 2 enemy types (Slime Bot, Flying Bug) with patrol/wave AI
- Boss robot with state machine (idle → patrol → charge → stunned)
- Health/lives system with invincibility frames
- Checkpoint system
- Gem/star collectibles and energy orb health pickups
- Face customization system (manual crop + ML Kit auto-detect)
- Android plugin with gallery picker, face detection, face crop
- Main menu, level select, face setup, settings, about, privacy screens
- Touch controls for mobile
- Pause menu system
- Local save/load system (ConfigFile-based)
- Coyote time and jump buffer for better feel
- Mobile renderer for performance
- Export presets for Android debug APK and release AAB
- Privacy policy and data deletion
- License attribution and compliance

### Changed
- Renamed project from "2D-Platformer-Starter" to "FaceRun Offline"
- Package name: `com.aman.facerunoffline`
- Main scene changed from Level_01 to MainMenu
- Player script rewritten with face texture support, touch input, health system
- GameManager expanded with lives, health, level management
- Coins replaced with Gems (different visual style)
- Rendering mode changed to "mobile"
- Added autoload managers: SaveManager, FaceManager

### Removed
- Original tutorial text from levels
- Original GameUI script (replaced with new HUD)
- Original branding/splash

---

## Dependencies

### Godot Project
- Godot Engine 4.4+
- Android export templates

### Android Plugin
- `org.godotengine:godot:4.4.1.stable`
- `com.google.mlkit:face-detection:16.1.7` (bundled offline model)
- `androidx.activity:activity-ktx:1.9.3`
- `androidx.exifinterface:exifinterface:1.3.7`

---

## Offline Architecture

```
┌─────────────────────────────────────┐
│           Godot Game Engine         │
│  ┌─────────┐  ┌──────────────────┐  │
│  │ Levels  │  │  FaceManager.gd  │  │
│  │ Player  │  │  (loads PNGs at  │  │
│  │ Enemies │  │   runtime)       │  │
│  │ Boss    │  └────────┬─────────┘  │
│  └─────────┘           │            │
│                        │ Godot Plugin API
│  ┌─────────────────────┴──────────┐ │
│  │     FaceRunPlugin (Kotlin)     │ │
│  │  ┌──────────┐  ┌────────────┐  │ │
│  │  │ Gallery  │  │  ML Kit    │  │ │
│  │  │ Picker   │  │  Face Det  │  │ │
│  │  │ (Intent) │  │  (Bundled) │  │ │
│  │  └──────────┘  └────────────┘  │ │
│  │  ┌──────────────────────────┐  │ │
│  │  │  Local File Storage      │  │ │
│  │  │  (app-private /faces/)   │  │ │
│  │  └──────────────────────────┘  │ │
│  └────────────────────────────────┘ │
└─────────────────────────────────────┘
         NO INTERNET REQUIRED
```

---

## Known Issues & Next Steps

### Known Issues
- Level tilemap data needs to be regenerated in Godot editor for proper visual layout
- Touch controls use basic Button/TouchScreenButton — can be improved with custom touch zones
- Boss health bar positioning needs tuning in Godot editor
- Font references may need updating if custom fonts are not imported

### Next Steps
- Add more enemy types (Spike Drone)
- Add NPC characters with face assignment
- Add face accessories (crown, cap, sunglasses, helmet)
- Add pixel-art preview for faces
- Add onboarding tutorial screens
- Add background music tracks
- Add more detailed level art and parallax backgrounds
- Add face swap for collectible cards
- Improve touch control feel with custom input zones
- Add haptic feedback on Android
- Performance optimization pass
- Google Play Store listing assets

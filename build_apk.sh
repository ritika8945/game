#!/bin/bash
set -e

# ============================================================
# FaceRun Offline — One-liner APK Build Script
# Usage: ./build_apk.sh
# Prerequisites: Godot 4.4+, Android SDK, Java 17+
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN} FaceRun Offline — APK Builder${NC}"
echo -e "${GREEN}========================================${NC}"

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

OUTPUT_APK="$PROJECT_DIR/FaceRunOffline-debug.apk"

# --- Detect Godot binary ---
if [ -z "${GODOT_BIN:-}" ]; then
GODOT_BIN=""
for cmd in godot godot4 "Godot_v4" godot-mono; do
    if command -v "$cmd" &>/dev/null; then
        GODOT_BIN="$cmd"
        break
    fi
done

# Check common install locations
if [ -z "$GODOT_BIN" ]; then
    for path in \
        "/Applications/Godot.app/Contents/MacOS/Godot" \
        "$HOME/Godot/Godot_v4"* \
        "/usr/local/bin/godot"* \
        "/opt/godot/godot"* \
        "$HOME/.local/bin/godot"*; do
        if [ -x "$path" ] 2>/dev/null; then
            GODOT_BIN="$path"
            break
        fi
    done
fi
fi

if [ -z "$GODOT_BIN" ]; then
    echo -e "${RED}ERROR: Godot not found in PATH.${NC}"
    echo "Please either:"
    echo "  1. Add Godot to your PATH, or"
    echo "  2. Set GODOT_BIN environment variable:"
    echo "     GODOT_BIN=/path/to/godot ./build_apk.sh"
    exit 1
fi

echo -e "${GREEN}[1/5]${NC} Using Godot: $GODOT_BIN"

# Helper: run Godot headless with a timeout to prevent hangs.
# Godot loads project autoloads which may print warnings — that's normal.
run_godot() {
    local description="$1"
    shift
    local timeout_secs="${GODOT_TIMEOUT:-120}"

    if command -v timeout &>/dev/null; then
        timeout "$timeout_secs" "$GODOT_BIN" --headless "$@" 2>&1 || {
            local rc=$?
            # timeout returns 124 on timeout
            if [ $rc -eq 124 ]; then
                echo -e "${YELLOW}WARNING: $description timed out after ${timeout_secs}s, continuing...${NC}"
            fi
            return 0
        }
    else
        "$GODOT_BIN" --headless "$@" 2>&1 &
        local pid=$!
        local waited=0
        while kill -0 "$pid" 2>/dev/null; do
            sleep 1
            waited=$((waited + 1))
            if [ "$waited" -ge "$timeout_secs" ]; then
                echo -e "${YELLOW}WARNING: $description timed out after ${timeout_secs}s, continuing...${NC}"
                kill "$pid" 2>/dev/null || true
                wait "$pid" 2>/dev/null || true
                break
            fi
        done
        wait "$pid" 2>/dev/null || true
    fi
}

# --- Build Android Plugin ---
echo -e "${GREEN}[2/5]${NC} Building Android plugin (ML Kit + audio picker)..."
cd "$PROJECT_DIR/android-plugin"

if [ -f "./gradlew" ]; then
    chmod +x ./gradlew
    ./gradlew assemble --quiet
else
    echo -e "${RED}ERROR: gradlew not found in android-plugin/${NC}"
    exit 1
fi

# --- Copy plugin AARs to Godot addons ---
echo -e "${GREEN}[3/5]${NC} Installing plugin into Godot project..."
cd "$PROJECT_DIR"
mkdir -p addons/FaceRunPlugin/bin/debug addons/FaceRunPlugin/bin/release

cp android-plugin/plugin/build/outputs/aar/FaceRunPlugin-debug.aar addons/FaceRunPlugin/bin/debug/
cp android-plugin/plugin/build/outputs/aar/FaceRunPlugin-release.aar addons/FaceRunPlugin/bin/release/
cp android-plugin/plugin/export_scripts_template/* addons/FaceRunPlugin/

# --- Install Android build template if not present ---
echo -e "${GREEN}[4/5]${NC} Setting up Android build template..."
if [ ! -d "$PROJECT_DIR/android/build" ]; then
    run_godot "Install Android build template" --quit --install-android-build-template
    echo -e "  Android build template installed."
else
    echo -e "  Android build template already exists, skipping."
fi

# --- Export APK ---
echo -e "${GREEN}[5/5]${NC} Exporting debug APK..."
rm -f "$OUTPUT_APK"
run_godot "Export APK" --quit --export-debug "Android Debug" "$OUTPUT_APK"

if [ -f "$OUTPUT_APK" ]; then
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN} BUILD SUCCESSFUL${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "APK: ${YELLOW}$OUTPUT_APK${NC}"
    APK_SIZE=$(du -h "$OUTPUT_APK" | cut -f1)
    echo -e "Size: ${YELLOW}$APK_SIZE${NC}"
    echo ""
    echo "Install on phone:"
    echo "  adb install $OUTPUT_APK"
else
    echo ""
    echo -e "${RED}========================================${NC}"
    echo -e "${RED} BUILD FAILED${NC}"
    echo -e "${RED}========================================${NC}"
    echo ""
    echo "Common fixes:"
    echo "  1. Install Android export templates in Godot:"
    echo "     Editor → Manage Export Templates → Download"
    echo "  2. Make sure Android SDK is installed and ANDROID_HOME is set"
    echo "  3. Try running manually in Godot: Project → Export → Android Debug"
    echo ""
    echo "For debug output, run:"
    echo "  $GODOT_BIN --headless --export-debug \"Android Debug\" $OUTPUT_APK"
    exit 1
fi

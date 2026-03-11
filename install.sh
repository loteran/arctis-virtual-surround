#!/usr/bin/env bash
# arctis-virtual-surround — install.sh
#
# Sets up virtual surround 7.1 (HeSuVi / PipeWire filter-chain)
# and WirePlumber priority rules for the SteelSeries Arctis Nova Pro Wireless.
#
# Usage:
#   bash install.sh [--skip-wireplumber] [--skip-hrir] [--hrir-path /path/to/hrir.wav]
#
# Options:
#   --skip-wireplumber    Skip WirePlumber priority config (if you don't have HDMI / C-Media)
#   --skip-hrir           Skip HRIR download (bring your own hrir.wav)
#   --hrir-path PATH      Use a local HRIR file instead of downloading one
#
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PIPEWIRE_CONF_DST="$HOME/.config/pipewire/filter-chain.conf.d"
WIREPLUMBER_CONF_DST="$HOME/.config/wireplumber/wireplumber.conf.d"
HRIR_DIR="$HOME/.local/share/pipewire/hrir_hesuvi"

SKIP_WIREPLUMBER=false
SKIP_HRIR=false
HRIR_PATH=""

# ── Parse arguments ────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-wireplumber) SKIP_WIREPLUMBER=true ;;
        --skip-hrir)        SKIP_HRIR=true ;;
        --hrir-path)        HRIR_PATH="$2"; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

echo ""
echo "==> arctis-virtual-surround installer"
echo ""

# ── 1. PipeWire filter-chain config ───────────────────────────────────────────
echo "[1/3] Installing PipeWire filter-chain config..."
mkdir -p "$PIPEWIRE_CONF_DST"
cp "$REPO_DIR/pipewire/sink-virtual-surround-7.1-hesuvi.conf" \
   "$PIPEWIRE_CONF_DST/sink-virtual-surround-7.1-hesuvi.conf"
echo "      Installed to: $PIPEWIRE_CONF_DST/sink-virtual-surround-7.1-hesuvi.conf"

# ── 2. HRIR file ──────────────────────────────────────────────────────────────
echo "[2/3] Setting up HRIR file..."
mkdir -p "$HRIR_DIR"

if [ -n "$HRIR_PATH" ]; then
    cp "$HRIR_PATH" "$HRIR_DIR/hrir.wav"
    echo "      Copied from: $HRIR_PATH"
elif [ -f "$HRIR_DIR/hrir.wav" ]; then
    echo "      Already present — skipping. (Use --hrir-path to replace.)"
elif [ "$SKIP_HRIR" = true ]; then
    echo "      Skipped. Place your HeSuVi-compatible WAV at:"
    echo "      $HRIR_DIR/hrir.wav"
    echo "      Then run: systemctl --user restart filter-chain.service"
else
    echo "      Downloading KEMAR Gardner 1995 HRIR (HeSuVi)..."
    HRIR_URL="https://github.com/nicehash/HeSuVi/raw/master/hrir/44/KEMAR%20Gardner%201995/kemar.wav"
    if command -v curl &>/dev/null; then
        curl -fsSL -o "$HRIR_DIR/hrir.wav" "$HRIR_URL"
    elif command -v wget &>/dev/null; then
        wget -q -O "$HRIR_DIR/hrir.wav" "$HRIR_URL"
    else
        echo "      [!] curl and wget not found."
        echo "          Download manually from: https://github.com/nicehash/HeSuVi/tree/master/hrir/44"
        echo "          Save as: $HRIR_DIR/hrir.wav"
        echo "          Then run: systemctl --user restart filter-chain.service"
        exit 1
    fi
    echo "      Downloaded to: $HRIR_DIR/hrir.wav"
fi

# ── 3. WirePlumber priority config ────────────────────────────────────────────
if [ "$SKIP_WIREPLUMBER" = false ]; then
    echo "[3/3] Installing WirePlumber priority config..."
    mkdir -p "$WIREPLUMBER_CONF_DST"
    cp "$REPO_DIR/wireplumber/50-lower-hdmi-priority.conf" \
       "$WIREPLUMBER_CONF_DST/50-lower-hdmi-priority.conf"
    echo "      Installed to: $WIREPLUMBER_CONF_DST/50-lower-hdmi-priority.conf"
    echo "      (HDMI / C-Media priority = 200, Arctis Nova Pro = 1500)"
else
    echo "[3/3] WirePlumber config skipped."
fi

# ── Restart services ──────────────────────────────────────────────────────────
echo ""
echo "==> Restarting audio services..."
systemctl --user restart pipewire wireplumber pipewire-pulse filter-chain 2>/dev/null || true

echo ""
echo "==> Done!"
echo ""
echo "    A new audio sink 'Virtual Surround Sink' is now available."
echo "    Select it as your output in your desktop audio settings (KDE, GNOME…)"
echo "    to apply 7.1 surround virtualisation to any stereo headset."
echo ""
echo "    To use a different HRIR profile:"
echo "      Replace $HRIR_DIR/hrir.wav"
echo "      with any HeSuVi-compatible 14-channel WAV from:"
echo "      https://github.com/nicehash/HeSuVi/tree/master/hrir/44"
echo "      Then run: systemctl --user restart filter-chain.service"
echo ""

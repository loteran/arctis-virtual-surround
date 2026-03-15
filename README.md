# arctis-virtual-surround

One-command setup for **virtual surround 7.1** on a SteelSeries Arctis Nova Pro Wireless (or any stereo headset) using PipeWire + HeSuVi HRTF convolution.

Designed to work standalone or alongside [Arctis Sound Manager](https://github.com/loteran/Arctis-Sound-Manager).

---

## What it does

- Creates a **Virtual Surround Sink** in PipeWire (8-channel input → stereo output via HRTF convolution)
- Copies the bundled HRIR file (`hrir/EAC_Default.wav` — HeSuVi 14-channel, 44100 Hz) — no internet required
- Configures WirePlumber to always prefer the Arctis over HDMI / USB DAC as default sink
- Restarts audio services so everything is live immediately

```
 Game / movie (7.1) ──► Virtual Surround Sink ──► Arctis Nova Pro (stereo)
                         (HeSuVi HRTF filter)
```

---

## Requirements

- Linux with **PipeWire** + `pipewire-pulse` + `wireplumber`
- The `filter-chain` PipeWire module (package: `pipewire` on Arch, included by default)
- No internet required — the HRIR file is bundled in the repo (`hrir/EAC_Default.wav`)

---

## Install

```bash
git clone https://github.com/loteran/arctis-virtual-surround.git
cd arctis-virtual-surround
bash install.sh
```

Then select **Virtual Surround Sink** as your audio output in your desktop settings (KDE, GNOME…).

### Options

| Flag | Description |
|---|---|
| `--skip-wireplumber` | Skip WirePlumber priority config (no HDMI / C-Media on your system) |
| `--skip-hrir` | Skip HRIR download (provide your own `hrir.wav`) |
| `--hrir-path /path/to/hrir.wav` | Use a local HRIR file instead of downloading |

---

## Custom HRIR profiles

The bundled default is `hrir/EAC_Default.wav` (EAC Default — HeSuVi 14-channel, 44100 Hz).

Replace `~/.local/share/pipewire/hrir_hesuvi/hrir.wav` with any other 14-channel HeSuVi-compatible WAV:

- Bundled profile: [`hrir/EAC_Default.wav`](hrir/EAC_Default.wav) (included, no download needed)
- More profiles: [ArtTuneDB/hrir/44](https://github.com/ArtIsWar/ArtTuneDB/tree/main/hrir/44)
- Use the non-`*-.wav` variants

Then restart:
```bash
systemctl --user restart filter-chain.service
```

---

## WirePlumber priority config

`wireplumber/50-lower-hdmi-priority.conf` sets:

| Sink | Priority |
|---|---|
| Arctis Nova Pro Wireless | 1500 (always preferred) |
| HDMI (`pci-0000_09_00.1`) | 200 (never auto-selected) |
| C-Media USB DAC | 200 (never auto-selected) |

If your HDMI or GPU PCI address differs, edit the `node.name` values in that file before running `install.sh`. Find your sink names with:
```bash
pactl list sinks short
```

---

## Uninstall

```bash
rm ~/.config/pipewire/filter-chain.conf.d/sink-virtual-surround-7.1-hesuvi.conf
rm ~/.config/wireplumber/wireplumber.conf.d/50-lower-hdmi-priority.conf
systemctl --user restart pipewire wireplumber pipewire-pulse
```

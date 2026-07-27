# Tennis Ball Machine — Firmware

Firmware for a DIY 3D-printed tennis ball machine. An ESP32 drives two
brushless flywheels (speed and spin), a servo feed gate, an optional tilt
servo (height), and a stepper turntable (left/right placement). Control is
over WiFi — a web UI served by the board, with the same REST endpoints
available to any client.

No Raspberry Pi. No Arduino IDE. Built and flashed entirely from the
command line with PlatformIO, so it works from any editor.

---

## Hardware summary

| Subsystem | Parts | Controls |
|---|---|---|
| Launch | 2× brushless motors + 2× 40A ESCs | ball speed, topspin/backspin |
| Feed | MG996R servo gate | rate of fire |
| Oscillation | NEMA 17 + DRV8825 on a turntable | left / right / random / sweep |
| Height | MG996R tilt servo (optional) | trajectory |
| Brain | ESP32 (ESP-WROOM-32) | everything |
| Power | 4S LiPo 14.8V → UBEC → 5V logic | — |

Wheels are stacked **vertically**: top wheel faster gives backspin, bottom
wheel faster gives topspin, equal speeds gives a flat ball.

Full electrical detail lives in the wiring reference; mechanical assembly
lives in the build guide. This README covers software only.

### Pin map

Mirrors `include/config.h`, which is the single source of truth.

| Signal | GPIO |
|---|---|
| ESC 1 throttle (top wheel) | 25 |
| ESC 2 throttle (bottom wheel) | 26 |
| Feed servo | 27 |
| Tilt servo | 14 |
| Stepper STEP | 32 |
| Stepper DIR | 33 |
| Stepper EN | 13 |
| DRV8825 VDD | 3V3 |

Avoid GPIO 6–11 (flash). GPIO 34–39 are input-only.

---

## Prerequisites

**PlatformIO Core** (no IDE extension required):

```bash
pip install platformio
pio --version
```

If `pio` is not found after installing via the VS Code extension, it lives
in its own virtualenv:

```bash
export PATH="$HOME/.platformio/penv/bin:$PATH"
```

**USB driver.** Most ESP-WROOM-32 boards use a CP210x or CH340 bridge.
macOS 12+ and Windows 11 both need the vendor driver installed manually.
Confirm the board enumerates before building:

```bash
pio device list
```

You want a `/dev/cu.usbserial-*` (macOS) or `COMx` (Windows) entry. If
nothing appears, suspect a charge-only USB cable before anything else.

---

## Layout

```
.
├── platformio.ini          build targets and pinned dependencies
├── include/
│   └── config.h            pin map — single source of truth
├── src/
│   └── main.cpp            wiring-up only, kept thin
├── lib/
│   ├── drills/             PURE LOGIC — no Arduino headers
│   │   ├── ShotCommand.h
│   │   └── DrillSequencer.{h,cpp}
│   └── hal/                HARDWARE — the only place that touches pins
│       ├── ILauncher.h
│       ├── EscLauncher.cpp
│       ├── FeedGate.cpp
│       ├── Tilt.cpp
│       └── Turntable.cpp
├── test/
│   ├── test_drills/        runs on your machine
│   └── test_hardware/      runs on the board
└── .github/workflows/ci.yml
```

### The one architectural rule

`lib/drills/` must not include `<Arduino.h>`.

Drill sequencing, spin-to-throttle mapping, random placement within bounds,
and JSON parsing are plain C++ with no hardware in them. Keeping them
framework-free means they compile for your laptop, so tests run in seconds
in CI without an ESP32 attached to a build server.

`lib/hal/` is the only code that touches pins. The logic depends on the
`ILauncher` interface rather than a concrete driver, so tests substitute a
fake and assert on what the sequencer *commanded*.

---

## Commands

### Build

```bash
pio run                      # default env (esp32dev)
pio run -e esp32dev          # explicit
pio run -t clean             # clean
```

First build downloads the toolchain — a few hundred MB, several minutes.
Later builds take seconds.

### Upload

```bash
pio run -e esp32dev -t upload
```

Port is auto-detected. To force one:

```bash
pio run -e esp32dev -t upload --upload-port /dev/cu.usbserial-0001
```

If it stalls at `Connecting....`, hold the **BOOT** button until writing
starts. Some boards do not auto-reset into the bootloader.

### Serial monitor

```bash
pio device monitor           # baud comes from platformio.ini
```

`Ctrl+C` to exit. Only one program may hold the port — close any other
monitor first.

### Test

```bash
pio test -e native           # host-side logic tests, fast
pio test -e esp32dev         # on-device tests, needs the board connected
```

`native` is a **test** environment. `pio run -e native` is not meaningful
and will fail; use `pio test`.

### Editor intelligence

Generates `compile_commands.json` for clangd, so vim, emacs, or any
LSP-aware editor gets completion and diagnostics:

```bash
pio run -t compiledb
```

### Over-the-air upload

Commented out in `platformio.ini` until the machine is on the network and
running ArduinoOTA. Once it is, uncomment `[env:esp32dev_ota]` and:

```bash
pio run -e esp32dev_ota -t upload
```

---

## Control API

A drill is a sequence of shots. One shot:

```json
{ "angle": -15, "tilt": 30, "speed": 0.7, "spin": -0.3, "delay": 3.0 }
```

| Field | Meaning |
|---|---|
| `angle` | turntable position in degrees, negative is left |
| `tilt` | height servo in degrees |
| `speed` | wheel throttle, 0.0–1.0 |
| `spin` | wheel differential, −1.0 backspin … +1.0 topspin |
| `delay` | seconds until the next ball |

Endpoints: `POST /shot`, `POST /drill`, `POST /stop`, `GET /status`.

Test them with curl before writing any client:

```bash
curl -X POST http://192.168.4.1/shot \
  -H 'Content-Type: application/json' \
  -d '{"angle":0,"tilt":30,"speed":0.5,"spin":0.2,"delay":3.0}'
```

WiFi boots dual-mode: joins a known network if present, otherwise hosts its
own access point so the machine works on any court.

---

## CI

`.github/workflows/ci.yml` runs on every push:

1. `pio test -e native` — logic tests
2. `pio check -e esp32dev` — static analysis
3. `pio run -e esp32dev` — build
4. uploads `firmware.bin` as an artifact

Same commands you run locally, so a green local build means a green CI run.

---

## Firmware safety rules

These are requirements, not preferences. The machine throws balls at speed
using wheels spinning near 15,000 RPM.

- **Min throttle at boot, unconditionally.** ESCs arm on a low signal. A
  reset, brownout, or OTA reboot must never spin the wheels up.
- **Gate OTA behind a disarmed check.** OTA triggers a reboot; that reboot
  has to be boring every single time.
- **`POST /stop` must cut throttle before anything else**, then stop the
  feed.
- **Never treat software as the primary kill.** The master switch is the
  hardware stop and always wins.
- **Ramp throttle rather than stepping it.** Reduces inrush current — which
  protects the 40A fuse — and reduces mechanical shock on the wheels.
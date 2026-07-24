# Firmware project structure

```
tennis-ball-machine/
├── platformio.ini              build targets + pinned deps
├── include/
│   └── config.h                PIN MAP — single source of truth,
│                               mirrors the wiring reference doc
├── src/
│   └── main.cpp                thin: wire things together, then loop()
├── lib/
│   ├── drills/                 PURE LOGIC — no Arduino headers
│   │   ├── ShotCommand.h       {angle, tilt, speed, spin, delay}
│   │   ├── DrillSequencer.h    steps through a drill, decides next shot
│   │   └── DrillSequencer.cpp
│   └── hal/                    HARDWARE — talks to real pins
│       ├── ILauncher.h         interface the logic depends on
│       ├── EscLauncher.cpp     two ESCs, speed + spin
│       ├── FeedGate.cpp        SV1
│       ├── Tilt.cpp            SV2
│       └── Turntable.cpp       NEMA 17 via DRV8825
├── test/
│   ├── test_drills/            runs on your Mac (pio test -e native)
│   └── test_hardware/          runs on the board (pio test -e esp32dev)
└── .github/workflows/ci.yml
```

## The one rule that makes this testable

`lib/drills/` must not `#include <Arduino.h>`.

Drill sequencing, spin-to-throttle mapping, random placement within
bounds, and JSON parsing are all plain C++ with no hardware in them.
Keep them hardware-free and they compile for your laptop, so CI can
test them in seconds without an ESP32 plugged into a build server.

`lib/hal/` is the only place that touches pins. The logic depends on
an interface (`ILauncher`), not on `EscLauncher` directly — so tests
substitute a fake and assert on what the sequencer *commanded* rather
than needing a motor to spin.

## What CI actually catches

- drill logic regressions (host tests, seconds)
- code that no longer compiles for ESP32
- static analysis defects
- and it hands you a flashable `firmware.bin` per commit

## CD = OTA

`pio run -e esp32dev_ota -t upload` pushes firmware over WiFi. The
machine already has WiFi for its control UI, so deployment is free.

SAFETY: gate OTA behind an "motors disarmed" check in firmware, and
keep min-throttle-at-boot unconditional. A reboot mid-session must
never spin the wheels.

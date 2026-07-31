// SPIN TEST v3 — DUAL ESC for launch testing.
// ESC A (top wheel)    -> GPIO 25   ESC B (bottom wheel) -> GPIO 26
// Both servo-lead GNDs -> ESP32 GND. Reds taped, never connected.
// Flash + monitor FIRST (holds min), THEN battery switch; both ESCs beep.
//
// Commands:
//   1000..2000    BOTH motors, microseconds
//   a<us> b<us>   one motor  (a1300 = top only)
//   r<rpm>        BOTH via rpm estimate (kick-start if from standstill)
//   u / d         both +/- 25us     s or 0   STOP BOTH
//
// LAUNCH PROTOCOL (read before feeding a ball):
//   direction check at 1100 first — at the GAP both surfaces must
//   move toward the exit; wrong motor => power off, swap 2 bullets.

#include <Arduino.h>
#include <ESP32Servo.h>

constexpr int PIN_A = 25, PIN_B = 26;
constexpr int MIN_US = 1000, MAX_US = 2000, STEP_US = 25;
constexpr int KICK_US = 1300, KICK_MS = 600;
constexpr float KV = 750.0, VBATT = 15.5;

Servo escA, escB;
int thrA = MIN_US, thrB = MIN_US;

int rpmEst(int us)  { return (int)((us - 1000) / 1000.0 * KV * VBATT); }
int usForRpm(int r) { return 1000 + (int)(1000.0 * r / (KV * VBATT)); }

void apply(int a, int b) {
  thrA = constrain(a, MIN_US, MAX_US);
  thrB = constrain(b, MIN_US, MAX_US);
  escA.writeMicroseconds(thrA);
  escB.writeMicroseconds(thrB);
  Serial.printf("A %d us (~%d rpm)   B %d us (~%d rpm)\n",
                thrA, rpmEst(thrA), thrB, rpmEst(thrB));
}

void setBoth(int us) {
  us = constrain(us, MIN_US, MAX_US);
  bool standstill = (thrA == MIN_US && thrB == MIN_US);
  if (standstill && us > MIN_US && us < KICK_US) {
    Serial.printf("kick-start both: %d us for %d ms...\n", KICK_US, KICK_MS);
    escA.writeMicroseconds(KICK_US);
    escB.writeMicroseconds(KICK_US);
    delay(KICK_MS);
  }
  apply(us, us);
}

void setup() {
  Serial.begin(115200);
  escA.setPeriodHertz(50);  escA.attach(PIN_A, MIN_US, 2000);
  escB.setPeriodHertz(50);  escB.attach(PIN_B, MIN_US, 2000);
  escA.writeMicroseconds(MIN_US);
  escB.writeMicroseconds(MIN_US);
  Serial.println("holding min on BOTH — toggle the switch, wait for beeps.");
  Serial.println("us=both | a<us> | b<us> | r<rpm> | u | d | s");
}

void loop() {
  if (!Serial.available()) return;
  String cmd = Serial.readStringUntil('\n');
  cmd.trim();
  if (cmd == "s" || cmd == "0")        apply(MIN_US, MIN_US);
  else if (cmd == "u")                 apply(thrA + STEP_US, thrB + STEP_US);
  else if (cmd == "d")                 apply(thrA - STEP_US, thrB - STEP_US);
  else if (cmd.startsWith("a"))        apply(cmd.substring(1).toInt(), thrB);
  else if (cmd.startsWith("b"))        apply(thrA, cmd.substring(1).toInt());
  else if (cmd.startsWith("r"))        setBoth(usForRpm(cmd.substring(1).toInt()));
  else if (cmd.toInt() >= MIN_US)      setBoth(cmd.toInt());
  else Serial.println("us=both | a<us> | b<us> | r<rpm> | u | d | s");
}
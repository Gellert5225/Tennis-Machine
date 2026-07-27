#include <Arduino.h>
#include <ESP32Servo.h>

Servo feedServo;

void setup() {
  Serial.begin(115200);
  feedServo.setPeriodHertz(50);
  feedServo.attach(27, 500, 2400);   // GPIO 27 = feed gate
}

bool running = true;

void loop() {
//   if (Serial.available()) {
//     char c = Serial.read();
//     if (c == 'g') { feedServo.attach(27, 500, 2400); running = true;  }
//     if (c == 's') { feedServo.detach();              running = false; Serial.println("stopped"); }
//   }
  feedServo.write(0);    delay(1000);
  feedServo.write(90);   delay(1000);
  feedServo.write(180);  delay(1000);
}
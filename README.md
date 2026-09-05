# HexaBot Tactical Controller

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Riverpod](https://img.shields.io/badge/State-Riverpod_2.x-00D2B8?style=for-the-badge&logo=flutter&logoColor=black)
![WebSocket](https://img.shields.io/badge/Protocol-WebSockets-010101?style=for-the-badge&logo=socket.io&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Linux%20%7C%20Windows-4E73DF?style=for-the-badge)

**A high-performance, industrial tactical telemetry and ground control station (GCS) mobile application built with Flutter for multi-legged hexapods, robotic rovers, and ESP32-powered robotics.**

[Features](#key-features) • [Controller Layout](#controller-layout--ui) • [System Architecture](#system-architecture) • [Telemetry Protocol](#telemetry--communication-protocol) • [Project Structure](#project-structure) • [Getting Started](#getting-started)

</div>

---

## Key Features

* **Dual-Grip Gamepad UI:** Optimized for low-latency landscape tactile interaction with directional D-Pad, 4-button Diamond cluster, 6-key auxiliary matrix, and granular Servo Jog controls.
* **Real-Time Glass Cockpit HUD:**
  * **Artificial Horizon & IMU Deck:** 3D pitch/roll horizon ball, roll arc indicator, inverted acceleration tilt circle, and angular velocity (Gyro XYZ) telemetry tiles.
  * **Interactive GPS Nav Deck:** Integrated OpenStreetMap (`flutter_map`) tracking live latitude, longitude, altitude, ground speed, satellite count, HDOP, and intelligent campus geolocation fallbacks.
  * **6-Axis Servo Monitor:** Multi-channel PWM pulse width gauge (500us - 2500us) with real-time feedback and channel selector.
* **Smart 2S Li-ion Battery Management:**
  * Calibrated for 2S battery packs across active operating range (4.5V to 8.1V).
  * Asymmetric Exponential Moving Average (EMA) filtering (alpha_drop = 0.03, alpha_rise = 0.08) to reject motor voltage sag and load jitter.
  * Multi-stage visual battery gauges (100% - 0% with adaptive color alert states).
* **Fail-Safe Safety Kill Switch & Diagnostics:** Instant app-level command isolation, ESP32 E-Stop trigger, live WebSocket ping/RSSI signal strength indicator, and headlight relay controls.

---

## Controller Layout & UI

```
+----------------------------------------------------------------------------------------+
|                                HEXABOT TACTICAL HUD                                    |
+-------------------+------------------------------------------------+-------------------+
|    LEFT GRIP      |                 CENTRAL HUD                    |    RIGHT GRIP     |
+-------------------+------------------------------------------------+-------------------+
|                   | [ CONNECTED ]  RSSI: -45dBm  84% | 7.68V  [LIGHT]  |                   |
|      +---+        | [ KILL SWITCH ]                                |        ( Y )      |
|      | ^ |        +------------------------------------------------+   ( X )     ( B ) |
|  +---+---+---+    |  [ HORIZON ]     [ GPS MAP ]     [ SERVOS ]    |        ( A )      |
|  | < |   | > |    +------------------------------------------------+                   |
|  +---+---+---+    |  +------------------------------------------+  |  +---+---+---+    |
|      | v |        |  |         Pitch: +4.2 deg  Roll: -1.8 deg  |  |  | 1 | 2 | 3 |    |
|      +---+        |  |              +---------+                 |  |  +---+---+---+    |
|                   |  |              |  ---o---│                 |  |  | 4 | 5 | 6 |    |
|  SERVO JOG [S3]   |  |              +---------+                 |  |  +---+---+---+    |
|  [ -10 ] [ +10 ]  |  |   Accel: 0.12G   |   Gyro: 2.1 rad/s     |  |   AUXILIARY KEYS  |
|  Step: (*)10 ( )50|  +------------------------------------------+  |   (CUSTOM ACTION) |
+-------------------+------------------------------------------------+-------------------+
```

---

## System Architecture

```mermaid
flowchart TB
    subgraph FlutterApp["Flutter Ground Control Station (bot_controller)"]
        UI["Tactical HUD & Gamepad UI\n(CenterDisplay, DPad, ServoJog, DiamondButtons)"]
        
        subgraph StateManagement["Riverpod State Management"]
            RC["RobotController\n(Command Dispatcher & Safety Interlock)"]
            TC["TelemetryController\n(Asymmetric EMA Battery & State Filter)"]
        end
        
        WS["WebSocketService\n(Auto-reconnect, JSON stream & Heartbeat)"]
    end

    subgraph Hardware["ESP32 Robotic Platform"]
        ESP["ESP32 WebSocket Server\n(AsyncTCP / WiFi SoftAP or STA)"]
        IMU["MPU6050 / BNO055\n(Pitch, Roll, Accel, Gyro)"]
        GPS["Neo-6M / Neo-8M GPS\n(Lat, Lng, Alt, Speed, Sats)"]
        PWM["PCA9685 / Servo Drivers\n(Hexapod Legs / Gimbal)"]
        BAT["ADC Voltage Divider\n(2S 18650 Battery Pack)"]
    end

    UI -->|User Touch Events| RC
    RC -->|JSON Command Packets| WS
    WS <-->|Bidirectional WS Stream (ws://192.168.4.1:81)| ESP
    ESP -->|High-Frequency Telemetry JSON| WS
    WS -->|Raw Telemetry Stream| TC
    TC -->|Smoothed & Filtered State| UI

    ESP --> PWM
    IMU --> ESP
    GPS --> ESP
    BAT --> ESP
```

---

## Telemetry & Communication Protocol

All communication is transported over lightweight JSON packets over WebSocket (`ws://<robot-ip>:81`).

### 1. Command Packet (App -> ESP32)
```json
{
  "cmd": "walk",
  "dir": "forward",
  "speed": 180,
  "eStop": false,
  "light": true
}
```

### 2. Telemetry Packet (ESP32 -> App)
```json
{
  "type": "telemetry",
  "batteryVoltage": 7.42,
  "wifiRSSI": -58,
  "queue": 0,
  "light": true,
  "imu": {
    "ok": true,
    "pitch": 3.45,
    "roll": -1.20,
    "accelX": 0.02,
    "accelY": -0.05,
    "accelZ": 9.81,
    "gyroX": 0.01,
    "gyroY": -0.02,
    "gyroZ": 0.00
  },
  "gps": {
    "valid": true,
    "lat": 22.476097,
    "lng": 88.414935,
    "alt": 12.4,
    "speed": 0.85,
    "sats": 9,
    "hdop": 0.8
  },
  "servos": [1500, 1420, 1600, 1500, 1480, 1520]
}
```

### 3. Battery Filtering Formula
For the 2S battery pack across the active $V_{\text{min}} = 4.5\text{V}$ to $V_{\text{max}} = 8.1\text{V}$ range:

$$\text{Percentage} = \text{clamp}\left( \frac{V - 4.5}{3.6} \times 100, 0.0, 100.0 \right)$$

$$\bar{V}_t = \bar{V}_{t-1} + \alpha (V_t - \bar{V}_{t-1}) \quad \text{where} \quad \alpha = \begin{cases} 0.03 & V_t < \bar{V}_{t-1} \text{ (motor sag filter)} \\ 0.08 & V_t \ge \bar{V}_{t-1} \text{ (voltage recovery)} \end{cases}$$

---

## Project Structure

```
bot_controller/
├── lib/
│   ├── controllers/
│   │   ├── robot_controller.dart        # Safety checks, E-stop, command sender
│   │   └── telemetry_controller.dart    # Telemetry stream processor & EMA battery filter
│   ├── core/
│   │   ├── models/
│   │   │   ├── commands.dart            # Command definitions & encoders
│   │   │   └── telemetry.dart           # IMU, GPS, Servo, & 2S Battery models
│   │   └── websocket/
│   │       └── websocket_service.dart   # Resilient WebSocket client & connection manager
│   ├── screens/
│   │   └── controller_screen.dart       # Main landscape dual-grip tactical cockpit
│   ├── widgets/
│   │   ├── artificial_horizon.dart      # 3D IMU artificial horizon & acceleration circle
│   │   ├── center_display.dart          # Central Glass HUD (Status, Kill switch, Tabs)
│   │   ├── d_pad.dart                   # Tactical directional pad
│   │   ├── diamond_buttons.dart         # Action button cluster (A, B, X, Y)
│   │   ├── gps_map_card.dart            # OpenStreetMap live tracking deck
│   │   ├── servo_jog.dart               # Granular servo pulse jog controller
│   │   ├── servo_monitor_card.dart      # Real-time 6-axis servo PWM meters
│   │   └── six_buttons.dart             # 6-key custom auxiliary matrix
│   ├── theme.dart                       # Cyberpunk industrial dark UI theme
│   └── main.dart                        # Application bootstrap & landscape lock
├── test/
│   ├── telemetry_test.dart              # Battery & telemetry parser unit tests
│   └── widget_test.dart                 # Smoke & UI integration tests
└── pubspec.yaml                         # Project dependencies & assets
```

---

## Getting Started

### Prerequisites
* Flutter SDK (`^3.11.5` or later)
* An ESP32 or simulated WebSocket server broadcasting telemetry packets

### Installation & Run

1. **Clone the repository:**
   ```bash
   git clone https://github.com/My-Mation/bot-controller.git
   cd bot-controller
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run tests:**
   ```bash
   flutter test
   ```

4. **Launch on connected device:**
   ```bash
   flutter run
   ```

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

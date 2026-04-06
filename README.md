# AimShield (Unlocked) – FiveM

This repository contains the **unlocked version of AimShield** for FiveM.  
It is shared so people can **learn from it, test it, and improve it**, instead of others selling files they originally obtained through me.

This project is mainly intended for **educational and development purposes**.

---

# Overview

AimShield is an **anti-aimbot detection script for FiveM servers**.  
It is designed to detect cheats such as:

- Aimbot
- Silent Aim
- Aimlock

The script monitors player behaviour and logs suspicious actions so server owners can review them.

---

# Installation

1. **Download the repository**

Download or clone this repository.

```
git clone https://github.com/Yorbentje/Aimshield
```

or download it as a ZIP.

---

2. **Place the resource**

Move the AimShield folder into your server:

```
resources/
```

Example:

```
resources/[anticheat]/aimshield
```

---

3. **Add to server.cfg**

Add this line to your `server.cfg`:

```
ensure vSync-snow
```

Make sure the **resource name matches the folder name**.

---

4. **Required Dependencies**

AimShield requires:

- **screenshot-basic**  
  Used for capturing evidence when detections happen.

- **txAdmin (recommended)**  
  For easier server management and logging.

---

# Configuration

Open:

```
config.lua
```

Here you can adjust things like:

- Detection thresholds
- Logging settings
- Discord webhook logging
- Detection behaviour

Adjust the values depending on your **server environment**.

---

# Current Behaviour & Tweaks

Below are some important behaviours in this version of AimShield.

### Drive-by situations

AimShield is **disabled for drive-bys**.

This allows **silent aim with unlimited FOV**, because otherwise there would be a large amount of **false detections**.

You do not even need to directly aim at players.

---

### Shooting at players inside vehicles

AimShield is also **disabled when shooting at players inside vehicles**.

Example vehicles:

- Cars
- Helicopters
- Boats
- Motorcycles

This is disabled because vehicle fights can cause **many false detections**.

Unlimited FOV can therefore be used in these scenarios.

---

### Foot vs Foot fights

In **player vs player fights on foot**, detection can still happen.

Silent aim can still be used **if done carefully**.

Recommended method:

1. First **aim legitimately at the player**
2. Shoot **within 0.5 seconds**

So:

- Legit aim first
- Fire quickly afterwards

This method works **best for long range fights**.

The further the distance, the **smaller the FOV should be**.

---

### Shotguns

AimShield is **disabled for shotguns**.

Shotgun shells often cause **false detections**, so the system does not check them.

This means **unlimited FOV can also be used with shotguns**.

---

### When can detection happen?

The main way detection can happen is during:

**Foot vs Foot fights**

If you:

- Do **not actually aim at the player**
- But still **hit them using silent aim**

Then detection may occur.

---

# Improving the Script

This project is shared so developers can:

- Learn from the detection logic
- Improve the system
- Fix weaknesses
- Create better anti-cheat solutions

Contributions and improvements are always welcome.

---

# Community

If you want to discuss development, improvements or other projects:

**Wave Development**

Discord:  
https://discord.gg/jEeNEsD2sz

---

# Disclaimer

This repository is shared for **educational and development purposes**.

It was made public because multiple people were **reselling the files despite being told not to**.

The goal is transparency and learning — not reselling.

---

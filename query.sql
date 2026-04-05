CREATE TABLE IF NOT EXISTS aimshield (
    id INT AUTO_INCREMENT PRIMARY KEY,
    identifier VARCHAR(50) NOT NULL,
    playerName VARCHAR(100) NOT NULL,
    weapon_hash VARCHAR(50) NOT NULL,
    attacker_coords VARCHAR(100),
    victim_coords VARCHAR(100),
    detected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS aimshield_settings (
  id INT AUTO_INCREMENT PRIMARY KEY,
  identifier VARCHAR(50) NOT NULL,
  settings JSON NOT NULL
);

ALTER TABLE users ADD COLUMN IF NOT EXISTS detection_count INT DEFAULT 0;

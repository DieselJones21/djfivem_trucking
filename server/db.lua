DB = {}

local ready = false

local SCHEMA = {
    [[
        CREATE TABLE IF NOT EXISTS `dj_trucking_profiles` (
          `citizenid` VARCHAR(64) NOT NULL,
          `license` VARCHAR(80) DEFAULT NULL,
          `name` VARCHAR(80) DEFAULT NULL,
          `xp` INT NOT NULL DEFAULT 0,
          `skill_points` INT NOT NULL DEFAULT 0,
          `skills` LONGTEXT,
          `certs` LONGTEXT,
          `company_name` VARCHAR(64) DEFAULT NULL,
          `company_balance` INT NOT NULL DEFAULT 0,
          `reputation` INT NOT NULL DEFAULT 0,
          `insurance` TINYINT NOT NULL DEFAULT 0,
          `stats` LONGTEXT,
          `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
          PRIMARY KEY (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]],
    [[
        CREATE TABLE IF NOT EXISTS `dj_trucking_trucks` (
          `id` INT NOT NULL AUTO_INCREMENT,
          `citizenid` VARCHAR(64) NOT NULL,
          `truck_id` VARCHAR(64) NOT NULL,
          `model` VARCHAR(64) NOT NULL,
          `plate` VARCHAR(16) NOT NULL,
          `label` VARCHAR(64) DEFAULT NULL,
          `body` FLOAT NOT NULL DEFAULT 1000,
          `engine` FLOAT NOT NULL DEFAULT 1000,
          `mileage` INT NOT NULL DEFAULT 0,
          `stored` TINYINT NOT NULL DEFAULT 1,
          `upgrades` LONGTEXT,
          `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          PRIMARY KEY (`id`),
          KEY `citizenid` (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]],
    [[
        CREATE TABLE IF NOT EXISTS `dj_trucking_history` (
          `id` INT NOT NULL AUTO_INCREMENT,
          `citizenid` VARCHAR(64) NOT NULL,
          `job_type` VARCHAR(24) NOT NULL,
          `cargo` VARCHAR(64) NOT NULL,
          `pickup` VARCHAR(64) DEFAULT NULL,
          `dropoff` VARCHAR(64) DEFAULT NULL,
          `distance` INT NOT NULL DEFAULT 0,
          `payout` INT NOT NULL DEFAULT 0,
          `xp` INT NOT NULL DEFAULT 0,
          `damage` INT NOT NULL DEFAULT 0,
          `integrity` INT NOT NULL DEFAULT 100,
          `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          PRIMARY KEY (`id`),
          KEY `citizenid` (`citizenid`),
          KEY `created_at` (`created_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]],
    [[
        CREATE TABLE IF NOT EXISTS `dj_trucking_loans` (
          `id` INT NOT NULL AUTO_INCREMENT,
          `citizenid` VARCHAR(64) NOT NULL,
          `product` VARCHAR(32) NOT NULL,
          `amount` INT NOT NULL,
          `remaining` INT NOT NULL,
          `daily_fee` INT NOT NULL,
          `taken_at` INT NOT NULL,
          `last_fee_at` INT NOT NULL,
          PRIMARY KEY (`id`),
          KEY `citizenid` (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]],
    [[
        CREATE TABLE IF NOT EXISTS `dj_trucking_employees` (
          `id` INT NOT NULL AUTO_INCREMENT,
          `citizenid` VARCHAR(64) NOT NULL,
          `employee_id` VARCHAR(64) NOT NULL,
          `name` VARCHAR(64) NOT NULL,
          `skill` INT NOT NULL DEFAULT 1,
          `wage` INT NOT NULL,
          `status` VARCHAR(24) DEFAULT 'idle',
          `lifetime` INT NOT NULL DEFAULT 0,
          `hired_at` INT NOT NULL,
          PRIMARY KEY (`id`),
          UNIQUE KEY `owner_driver` (`citizenid`, `employee_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]],
}

function DB.Encode(value)
    return json.encode(value or {})
end

function DB.Decode(value, fallback)
    if type(value) == 'table' then return value end
    if type(value) ~= 'string' or value == '' then
        return fallback or {}
    end
    local ok, decoded = pcall(json.decode, value)
    if ok and type(decoded) == 'table' then
        return decoded
    end
    return fallback or {}
end

function DB.Ready()
    return ready
end

CreateThread(function()
    if GetResourceState('oxmysql') ~= 'started' then
        lib.print.error('oxmysql is required for djfivem_trucking')
        return
    end

    for i = 1, #SCHEMA do
        MySQL.query.await(SCHEMA[i])
    end
    ready = true
    lib.print.info('DJ Logistics database ready')
end)

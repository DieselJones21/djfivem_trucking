Config = {}

----------------------------------------------------------------
-- Framework
-- 'auto' detects qbx_core first, then qb-core, then es_extended.
-- Money falls back to an ox_inventory item if no framework is running.
-- Edit framework.lua to hook custom inventories, keys, or banking.
----------------------------------------------------------------
Config.Framework = 'auto'

Config.Money = {
    method = 'auto',      -- 'auto' | 'framework' | 'item'
    item = 'money',
    account = 'bank',     -- 'cash' or 'bank' — trucking is a business, default bank
    companyAccount = 'bank',
}

Config.Debug = false
Config.Command = 'trucking'
Config.AdminCommand = 'truckingadmin'
Config.AdminAce = 'djfivem.trucking.admin'

Config.Brand = {
    name = 'DJ FiveM Scripts',
    short = 'DJ FiveM',
    initials = 'DJ',
    title = 'DJ Logistics',
    role = 'Contract driver',
    footer = 'DJ FIVEM SCRIPTS',
}

Config.DepotDistance = 3.4
Config.JobMarkerDistance = 8.0
Config.LoadDistance = 6.0
Config.Interact = {
    distance = 8.0,
    interactDst = 2.2,
    offset = vec3(0.0, 0.0, 0.18),
}

-- How the player opens the tablet at a depot.
-- 'interact' uses darktrovx/interact when started, otherwise ox_lib points + text UI.
Config.Target = 'interact'

----------------------------------------------------------------
-- Vehicle keys
-- Qbox: qbx_vehiclekeys GiveKeys / RemoveKeys (entity handle).
-- Also supports qb-vehiclekeys and a few common fallbacks.
----------------------------------------------------------------
Config.Keys = {
    resource = 'auto', -- 'auto' | 'qbx_vehiclekeys' | 'qb-vehiclekeys' | 'none'
    notify = true,
}

----------------------------------------------------------------
-- Economy knobs — tune these against your other civilian jobs
----------------------------------------------------------------
Config.Economy = {
    payoutScale = 1.0,          -- global multiplier
    xpScale = 1.0,
    quickJobPay = 0.72,         -- rental jobs pay less
    freightJobPay = 1.18,       -- owned truck jobs pay more
    partyShare = 0.22,          -- extra % split among party members
    convoyBonus = 0.08,         -- extra % when 2+ players finish together
    nightBonus = 0.10,          -- 21:00–05:00
    rainBonus = 0.06,
    fuelCostPerKm = 2.4,        -- deducted from payout
    repairPerDamage = 18,       -- $ per 1% body/engine loss on owned trucks
    rentalDeposit = 400,        -- held and returned if the rental comes back
    rentalKeepDepositBelow = 35,-- keep deposit if truck health drops below this %
    cancelPenalty = 150,
    abandonPenalty = 350,
    sellDepreciation = 0.62,    -- sell-back of an owned truck
    insurancePrice = 8500,      -- one-time company insurance
    insuranceRepairDiscount = 0.55,
    maxActiveJobs = 1,
    jobTimeout = 75,            -- minutes before a job auto-fails
    loadDuration = 6500,
    unloadDuration = 6500,
}

----------------------------------------------------------------
-- Progression
----------------------------------------------------------------
Config.MaxLevel = 20
Config.LevelXP = {
    0, 250, 600, 1100, 1800, 2700, 3800, 5200, 7000, 9200,
    12000, 15500, 19800, 25000, 31200, 38500, 47000, 56800, 68000, 81000,
}

function Config.LevelFromXP(xp)
    xp = math.floor(tonumber(xp) or 0)
    local level = 1
    for i = Config.MaxLevel, 1, -1 do
        if xp >= (Config.LevelXP[i] or 0) then
            level = i
            break
        end
    end
    return level
end

function Config.XPForLevel(level)
    level = math.max(1, math.min(Config.MaxLevel, math.floor(tonumber(level) or 1)))
    return Config.LevelXP[level] or 0
end

function Config.XPToNext(xp)
    local level = Config.LevelFromXP(xp)
    if level >= Config.MaxLevel then
        return 0, Config.LevelXP[Config.MaxLevel], Config.LevelXP[Config.MaxLevel]
    end
    local current = Config.LevelXP[level]
    local nxt = Config.LevelXP[level + 1]
    return math.max(0, nxt - xp), current, nxt
end

function Config.SkillPointsForLevel(level)
    local points = math.max(0, level - 1)
    if level >= 5 then points = points + 1 end
    if level >= 10 then points = points + 1 end
    if level >= 15 then points = points + 1 end
    if level >= 20 then points = points + 2 end
    return points
end

----------------------------------------------------------------
-- Company / NPC drivers
----------------------------------------------------------------
Config.Company = {
    renamePrice = 2500,
    startingName = 'Independent Driver',
    maxEmployees = 8,
    employeeTick = 8,           -- minutes between simulated hauls
    incidentChance = 0.08,
    incidentCost = { min = 220, max = 980 },
}

----------------------------------------------------------------
-- Loans — daily fee is a flat dollar amount, not compound interest
----------------------------------------------------------------
Config.Loans = {
    enabled = true,
    maxActive = 1,
    feeHours = 24,
    products = {
        { id = 'starter', label = 'Starter Note', amount = 25000, fee = 350, minLevel = 2 },
        { id = 'fleet', label = 'Fleet Note', amount = 75000, fee = 900, minLevel = 6 },
        { id = 'terminal', label = 'Terminal Note', amount = 175000, fee = 1900, minLevel = 12 },
        { id = 'logistics', label = 'Logistics Note', amount = 350000, fee = 3600, minLevel = 16 },
    },
}

----------------------------------------------------------------
-- Daily contracts
----------------------------------------------------------------
Config.Contracts = {
    count = 3,
    bonusPay = 0.28,
    bonusXp = 0.35,
}

----------------------------------------------------------------
-- Parties
----------------------------------------------------------------
Config.Party = {
    maxSize = 4,
    inviteDistance = 12.0,
    startDistance = 18.0,
}

----------------------------------------------------------------
-- Discord webhooks
-- Paste channel webhook URLs. Empty string = that event group is off.
-- Every gameplay action can log: jobs, fleet, company, money, admin.
----------------------------------------------------------------
Config.Webhooks = {
    enabled = true,
    username = 'DJ Logistics',
    color = 16731932, -- red-orange #ff4d1c
    jobs = '',
    fleet = '',
    company = '',
    money = '',
    progression = '',
    admin = '',
}

----------------------------------------------------------------
-- Optional fuel resources. If none are started, a flat fuel cost is used.
----------------------------------------------------------------
Config.Fuel = {
    resources = { 'ox_fuel', 'LegacyFuel', 'cdn-fuel', 'ps-fuel', 'lc_fuel' },
}

----------------------------------------------------------------
-- Blips
----------------------------------------------------------------
Config.Blips = {
    depot = { sprite = 477, color = 17, scale = 0.78, label = 'DJ Logistics' },
    pickup = { sprite = 478, color = 5, scale = 0.85, label = 'Pickup' },
    dropoff = { sprite = 473, color = 2, scale = 0.85, label = 'Drop-off' },
}

----------------------------------------------------------------
-- Ped used at each depot tablet
----------------------------------------------------------------
Config.DepotPed = {
    model = 's_m_m_dockwork_01',
    scenario = 'WORLD_HUMAN_CLIPBOARD',
}

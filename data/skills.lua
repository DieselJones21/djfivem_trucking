----------------------------------------------------------------
-- Skill tree + certifications
-- Skill points come from leveling. Certs unlock cargo classes.
----------------------------------------------------------------
Config.Skills = {
    hauler = {
        id = 'hauler',
        label = 'Heavy Hauler',
        description = '+4% job payout per rank. The money skill.',
        max = 5,
        cost = { 1, 1, 2, 2, 3 },
        payout = 0.04,
        icon = 'cash',
    },
    caretaker = {
        id = 'caretaker',
        label = 'Cargo Care',
        description = 'Cargo integrity drops slower when you hit bumps.',
        max = 5,
        cost = { 1, 1, 2, 2, 3 },
        integrity = 0.10,
        icon = 'shield',
    },
    mechanic = {
        id = 'mechanic',
        label = 'Yard Mechanic',
        description = 'Owned-truck repair bills drop 8% per rank.',
        max = 5,
        cost = { 1, 1, 2, 2, 3 },
        repair = 0.08,
        icon = 'wrench',
    },
    convoy = {
        id = 'convoy',
        label = 'Convoy Lead',
        description = '+5% party / convoy bonus per rank.',
        max = 4,
        cost = { 1, 2, 2, 3 },
        party = 0.05,
        icon = 'users',
    },
    broker = {
        id = 'broker',
        label = 'Freight Broker',
        description = 'Daily contracts pay more and refresh with better cargo.',
        max = 4,
        cost = { 1, 2, 2, 3 },
        contract = 0.08,
        icon = 'clipboard',
    },
    dispatcher = {
        id = 'dispatcher',
        label = 'Dispatcher',
        description = 'NPC drivers earn +10% net per rank.',
        max = 5,
        cost = { 1, 1, 2, 2, 3 },
        employee = 0.10,
        icon = 'radio',
    },
    negotiator = {
        id = 'negotiator',
        label = 'Note Negotiator',
        description = 'Loan daily fees drop 8% per rank.',
        max = 3,
        cost = { 2, 2, 3 },
        loan = 0.08,
        icon = 'bank',
    },
    endurance = {
        id = 'endurance',
        label = 'Long Haul',
        description = 'Fuel cost drops and long routes grant bonus XP.',
        max = 4,
        cost = { 1, 2, 2, 3 },
        fuel = 0.10,
        distanceXp = 0.08,
        icon = 'road',
    },
}

Config.SkillOrder = {
    'hauler', 'caretaker', 'mechanic', 'endurance',
    'convoy', 'broker', 'dispatcher', 'negotiator',
}

Config.Certs = {
    general = {
        id = 'general',
        label = 'CDL Class B',
        description = 'Issued on day one. General and box freight.',
        level = 1,
        cost = 0,
        cargo = { 'general' },
        auto = true,
    },
    food = {
        id = 'food',
        label = 'Reefer Ticket',
        description = 'Certification for refrigerated food loads.',
        level = 2,
        cost = 1,
        cargo = { 'food' },
    },
    machinery = {
        id = 'machinery',
        label = 'Heavy Equipment',
        description = 'Unlocks machinery and plant moves.',
        level = 4,
        cost = 2,
        cargo = { 'machinery' },
    },
    chemicals = {
        id = 'chemicals',
        label = 'Hazmat Endorsement',
        description = 'Required for industrial chemical totes.',
        level = 6,
        cost = 2,
        cargo = { 'chemicals' },
    },
    fuel = {
        id = 'fuel',
        label = 'Tanker Endorsement',
        description = 'Required to haul flammable liquids.',
        level = 8,
        cost = 3,
        cargo = { 'fuel' },
    },
    valuables = {
        id = 'valuables',
        label = 'High-Value Permit',
        description = 'Bonded permit for jewelry and secured freight.',
        level = 10,
        cost = 3,
        cargo = { 'valuables' },
    },
}

Config.CertOrder = { 'general', 'food', 'machinery', 'chemicals', 'fuel', 'valuables' }

function Config.GetSkill(id)
    return Config.Skills[id]
end

function Config.GetCert(id)
    return Config.Certs[id]
end

function Config.SkillRankBonus(skills, id, field)
    local skill = Config.Skills[id]
    if not skill then return 0 end
    local rank = 0
    if skills and skills[id] then
        rank = math.floor(tonumber(skills[id]) or 0)
    end
    return (skill[field] or 0) * rank
end

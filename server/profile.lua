Profile = {}

local cache = {}
local cidIndex = {}

local function blankStats()
    return {
        jobs = 0,
        quickJobs = 0,
        freightJobs = 0,
        failed = 0,
        earned = 0,
        spent = 0,
        xpEarned = 0,
        miles = 0,
        bestPayout = 0,
        todayJobs = 0,
        todayEarned = 0,
        todayKey = os.date('%Y-%m-%d'),
        lastEmployeeTick = os.time(),
        lastLoanTick = os.time(),
        contracts = {},
        contractDay = '',
        achievements = {},
    }
end

local function defaultProfile(src)
    return {
        citizenid = Framework.GetCitizenId(src),
        license = Framework.GetLicense(src),
        name = Framework.GetPlayerName(src),
        xp = 0,
        skill_points = 0,
        skills = {},
        certs = { general = true },
        company_name = Config.Company.startingName,
        company_balance = 0,
        reputation = 0,
        insurance = 0,
        stats = blankStats(),
        dirty = true,
    }
end

local function rollover(stats)
    local today = os.date('%Y-%m-%d')
    if stats.todayKey ~= today then
        stats.todayKey = today
        stats.todayJobs = 0
        stats.todayEarned = 0
    end
    return stats
end

function Profile.Hydrate(row)
    local stats = rollover(DB.Decode(row.stats, blankStats()))
    return {
        citizenid = row.citizenid,
        license = row.license,
        name = row.name,
        xp = row.xp or 0,
        skill_points = row.skill_points or 0,
        skills = DB.Decode(row.skills),
        certs = DB.Decode(row.certs, { general = true }),
        company_name = row.company_name or Config.Company.startingName,
        company_balance = row.company_balance or 0,
        reputation = row.reputation or 0,
        insurance = row.insurance or 0,
        stats = stats,
        dirty = false,
    }
end

function Profile.Load(src)
    local cid = Framework.GetCitizenId(src)
    if not cid then return nil end

    if cache[src] and cache[src].citizenid == cid then
        cache[src].stats = rollover(cache[src].stats)
        return cache[src]
    end

    local row
    if DB.Ready() then
        row = MySQL.single.await('SELECT * FROM dj_trucking_profiles WHERE citizenid = ?', { cid })
    end

    local profile
    if row then
        profile = Profile.Hydrate(row)
        profile.name = Framework.GetPlayerName(src)
        profile.license = Framework.GetLicense(src)
    else
        profile = defaultProfile(src)
        if DB.Ready() then
            MySQL.insert.await([[
                INSERT INTO dj_trucking_profiles
                    (citizenid, license, name, xp, skill_points, skills, certs, company_name, company_balance, reputation, insurance, stats)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ]], {
                profile.citizenid,
                profile.license,
                profile.name,
                profile.xp,
                profile.skill_points,
                DB.Encode(profile.skills),
                DB.Encode(profile.certs),
                profile.company_name,
                profile.company_balance,
                profile.reputation,
                profile.insurance,
                DB.Encode(profile.stats),
            })
            profile.dirty = false
        end
    end

    cache[src] = profile
    cidIndex[cid] = src
    return profile
end

function Profile.Get(src)
    return cache[src] or Profile.Load(src)
end

function Profile.ByCitizen(cid)
    local src = cidIndex[cid]
    if src then return cache[src], src end
end

function Profile.Save(src)
    local profile = cache[src]
    if not profile or not DB.Ready() then return end

    MySQL.update.await([[
        UPDATE dj_trucking_profiles SET
            license = ?, name = ?, xp = ?, skill_points = ?, skills = ?, certs = ?,
            company_name = ?, company_balance = ?, reputation = ?, insurance = ?, stats = ?
        WHERE citizenid = ?
    ]], {
        profile.license,
        profile.name,
        profile.xp,
        profile.skill_points,
        DB.Encode(profile.skills),
        DB.Encode(profile.certs),
        profile.company_name,
        profile.company_balance,
        profile.reputation,
        profile.insurance,
        DB.Encode(profile.stats),
        profile.citizenid,
    })
    profile.dirty = false
end

function Profile.Drop(src)
    if cache[src] then
        local cid = cache[src].citizenid
        Profile.Save(src)
        cache[src] = nil
        if cidIndex[cid] == src then
            cidIndex[cid] = nil
        end
    end
end

function Profile.Level(src)
    local profile = Profile.Get(src)
    return profile and Config.LevelFromXP(profile.xp) or 1
end

function Profile.HasCert(src, cert)
    if not cert or cert == 'general' then return true end
    local profile = Profile.Get(src)
    return profile and profile.certs and profile.certs[cert] == true
end

function Profile.AddXP(src, amount, reason)
    amount = math.floor((amount or 0) * Config.Economy.xpScale)
    if amount <= 0 then return 0, Profile.Level(src) end

    local profile = Profile.Get(src)
    if not profile then return 0, 1 end

    local before = Config.LevelFromXP(profile.xp)
    profile.xp = profile.xp + amount
    profile.stats.xpEarned = (profile.stats.xpEarned or 0) + amount
    local after = Config.LevelFromXP(profile.xp)

    if after > before then
        local earned = Config.SkillPointsForLevel(after) - Config.SkillPointsForLevel(before)
        profile.skill_points = profile.skill_points + math.max(0, earned)
        Framework.Notify(src, 'notify_skill', 'success', 'Level ' .. after, after)
        Webhooks.Player(src, 'progression', 'Level up', {
            { name = 'Level', value = tostring(after), inline = true },
            { name = 'XP', value = tostring(profile.xp), inline = true },
        })
    end

    profile.dirty = true
    Profile.Save(src)
    return amount, after, before
end

function Profile.SpendPoints(src, cost)
    local profile = Profile.Get(src)
    cost = math.floor(cost or 0)
    if not profile or cost < 0 or profile.skill_points < cost then
        return false
    end
    profile.skill_points = profile.skill_points - cost
    profile.dirty = true
    return true
end

function Profile.AddCompany(src, amount)
    local profile = Profile.Get(src)
    if not profile then return false end
    profile.company_balance = math.max(0, (profile.company_balance or 0) + math.floor(amount))
    profile.dirty = true
    return true
end

function Profile.ChargeCompany(src, amount)
    local profile = Profile.Get(src)
    amount = math.floor(amount or 0)
    if not profile or amount <= 0 then return true end
    if (profile.company_balance or 0) >= amount then
        profile.company_balance = profile.company_balance - amount
        profile.dirty = true
        return true
    end
    return false
end

function Profile.Public(src)
    local profile = Profile.Get(src)
    if not profile then return nil end

    local xp = profile.xp
    local level = Config.LevelFromXP(xp)
    local toNext, current, nxt = Config.XPToNext(xp)
    local spent = 0
    for id, rank in pairs(profile.skills or {}) do
        local skill = Config.Skills[id]
        if skill then
            for i = 1, math.min(rank, skill.max) do
                spent = spent + (skill.cost[i] or 1)
            end
        end
    end
    for id, owned in pairs(profile.certs or {}) do
        local cert = Config.Certs[id]
        if owned and cert and not cert.auto then
            spent = spent + (cert.cost or 0)
        end
    end

    return {
        name = profile.name,
        citizenid = profile.citizenid,
        xp = xp,
        level = level,
        toNext = toNext,
        xpCurrent = current,
        xpNext = nxt,
        skillPoints = profile.skill_points,
        skills = profile.skills,
        certs = profile.certs,
        company = profile.company_name,
        balance = profile.company_balance,
        reputation = profile.reputation,
        insurance = profile.insurance == 1,
        cash = Framework.GetMoney(src),
        stats = profile.stats,
        maxLevel = Config.MaxLevel,
        pointsEarned = Config.SkillPointsForLevel(level),
        pointsSpent = spent,
    }
end

CreateThread(function()
    while true do
        Wait(60000)
        for src, profile in pairs(cache) do
            if profile.dirty then
                Profile.Save(src)
            end
        end
    end
end)

AddEventHandler('playerDropped', function()
    Profile.Drop(source)
end)

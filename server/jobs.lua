Jobs = {}

local active = {}
local offers = {}
local offerSeq = 0

local function now()
    return os.time()
end

local function playerCoords(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    return GetEntityCoords(ped)
end

local function nearDepot(src, depotId, extra)
    local depot = Config.GetDepot(depotId)
    local coords = playerCoords(src)
    if not depot or not coords then return false end
    return #(coords - depot.pos) <= (Config.DepotDistance + (extra or 4.0))
end

local function nearPoint(src, point, range)
    local coords = playerCoords(src)
    if not coords or not point then return false end
    local pos = vec3(point.x, point.y, point.z)
    return #(coords - pos) <= (range or Config.JobMarkerDistance)
end

local function clockBonus(raining)
    local hour = tonumber(os.date('%H')) or 12
    local bonus = 0
    if hour >= 21 or hour < 5 then
        bonus = bonus + Config.Economy.nightBonus
    end
    if raining then
        bonus = bonus + (Config.Economy.rainBonus or 0)
    end
    return bonus
end

local function skillPayout(src)
    local profile = Profile.Get(src)
    return 1.0 + Config.SkillRankBonus(profile and profile.skills, 'hauler', 'payout')
end

local function skillIntegrity(src)
    local profile = Profile.Get(src)
    return Config.SkillRankBonus(profile and profile.skills, 'caretaker', 'integrity')
end

local function skillFuel(src)
    local profile = Profile.Get(src)
    return Config.SkillRankBonus(profile and profile.skills, 'endurance', 'fuel')
end

local function skillRepair(src)
    local profile = Profile.Get(src)
    return Config.SkillRankBonus(profile and profile.skills, 'mechanic', 'repair')
end

local function skillParty(src)
    local profile = Profile.Get(src)
    return Config.SkillRankBonus(profile and profile.skills, 'convoy', 'party')
end

local function skillContract(src)
    local profile = Profile.Get(src)
    return Config.SkillRankBonus(profile and profile.skills, 'broker', 'contract')
end

local function compatibleTrucks(src, cargoId, kind)
    local owned = Fleet.List(src)
    local list = {}
    if kind == 'freight' then
        for i = 1, #owned do
            local row = owned[i]
            local def = Config.GetTruck(row.truck_id)
            if def then
                for c = 1, #def.cargo do
                    if def.cargo[c] == cargoId then
                        list[#list + 1] = row
                        break
                    end
                end
            end
        end
        return list
    end

    for i = 1, #Config.Trucks do
        local truck = Config.Trucks[i]
        if truck.rentable then
            for c = 1, #truck.cargo do
                if truck.cargo[c] == cargoId then
                    list[#list + 1] = truck
                    break
                end
            end
        end
    end
    return list
end

local function estimatePay(src, cargo, fromId, toId, kind, truckPayout, contract)
    local meters = Config.RouteDistance(fromId, toId)
    local km = math.max(0.8, meters / 1000.0)
    local base = cargo.payPerKm * km
    base = base * (truckPayout or 1.0)
    base = base * (kind == 'freight' and Config.Economy.freightJobPay or Config.Economy.quickJobPay)
    base = base * skillPayout(src)
    base = base * (1.0 + clockBonus())
    if contract then
        base = base * (1.0 + Config.Contracts.bonusPay + skillContract(src))
    end
    return math.floor(base * Config.Economy.payoutScale), math.floor(meters)
end

local function nextOffers(src)
    offerSeq = offerSeq + 1
    local bucket = { at = now(), items = {} }
    offers[src] = bucket
    return bucket
end

function Jobs.Get(src)
    return active[src]
end

function Jobs.Clear(src)
    active[src] = nil
    offers[src] = nil
end

function Jobs.Generate(src, depotId, kind)
    kind = kind == 'freight' and 'freight' or 'quick'
    if not nearDepot(src, depotId, 6.0) then
        return nil, 'notify_too_far'
    end
    if active[src] then
        return nil, 'notify_busy'
    end

    local level = Profile.Level(src)
    local bucket = nextOffers(src)
    local from = Config.GetDepot(depotId)
    if not from then return {}, nil end

    local contracts = Company.DailyContracts(src)
    local used = {}

    for i = 1, #Config.CargoOrder do
        local cargo = Config.Cargo[Config.CargoOrder[i]]
        if cargo and level >= cargo.level and Profile.HasCert(src, cargo.cert) then
            local trucks = compatibleTrucks(src, cargo.id, kind)
            if #trucks > 0 then
                for d = 1, #Config.Depots do
                    local dest = Config.Depots[d]
                    if dest.id ~= depotId and not used[dest.id .. cargo.id] then
                        local meters = Config.RouteDistance(depotId, dest.id)
                        if meters >= 800 then
                            local truck = trucks[1]
                            local truckPayout = truck.payout or (Config.GetTruck(truck.truck_id) and Config.GetTruck(truck.truck_id).payout) or 1.0
                            local isContract = false
                            for c = 1, #contracts do
                                if contracts[c].cargo == cargo.id and contracts[c].dropoff == dest.id and not contracts[c].done then
                                    isContract = true
                                    break
                                end
                            end
                            local pay, distance = estimatePay(src, cargo, depotId, dest.id, kind, truckPayout, isContract)
                            local id = ('%s-%s-%s'):format(src, offerSeq, #bucket.items + 1)
                            bucket.items[#bucket.items + 1] = {
                                id = id,
                                kind = kind,
                                cargo = cargo.id,
                                cargoLabel = cargo.label,
                                pickup = depotId,
                                pickupLabel = from.label,
                                dropoff = dest.id,
                                dropoffLabel = dest.label,
                                distance = distance,
                                payout = pay,
                                xp = math.floor((cargo.xpPerKm * (distance / 1000.0)) * 12),
                                level = cargo.level,
                                cert = cargo.cert,
                                contract = isContract,
                                truckHint = truck.label or (Config.GetTruck(truck.truck_id) and Config.GetTruck(truck.truck_id).label),
                            }
                            used[dest.id .. cargo.id] = true
                            if #bucket.items >= 8 then
                                break
                            end
                        end
                    end
                end
            end
        end
    end

    table.sort(bucket.items, function(a, b)
        if a.contract ~= b.contract then return a.contract end
        return a.payout > b.payout
    end)

    return bucket.items
end

function Jobs.Start(src, offerId, truckRowId)
    if active[src] then
        return nil, 'notify_busy'
    end
    local bucket = offers[src]
    if not bucket then return nil, 'notify_invalid' end

    local offer
    for i = 1, #bucket.items do
        if bucket.items[i].id == offerId then
            offer = bucket.items[i]
            break
        end
    end
    if not offer then return nil, 'notify_invalid' end
    if now() - bucket.at > 180 then return nil, 'notify_invalid' end
    if not nearDepot(src, offer.pickup, 8.0) then
        return nil, 'notify_too_far'
    end
    if not Profile.HasCert(src, offer.cert) then
        return nil, 'notify_cert'
    end

    local truckDef
    local owned
    if offer.kind == 'freight' then
        owned = Fleet.GetOwned(src, truckRowId)
        if not owned then return nil, 'notify_no_truck' end
        if owned.stored ~= 1 then return nil, 'notify_truck_out' end
        truckDef = Config.GetTruck(owned.truck_id)
        if not truckDef then return nil, 'notify_no_truck' end
        local okCargo = false
        for i = 1, #truckDef.cargo do
            if truckDef.cargo[i] == offer.cargo then
                okCargo = true
                break
            end
        end
        if not okCargo then return nil, 'notify_no_truck' end
    else
        local rentals = compatibleTrucks(src, offer.cargo, 'quick')
        truckDef = rentals[1]
        if not truckDef then return nil, 'notify_no_truck' end
        if Config.Economy.rentalDeposit > 0 then
            if not Framework.RemoveMoney(src, Config.Economy.rentalDeposit, 'trucking-rental-deposit') then
                return nil, 'notify_no_money'
            end
            Webhooks.Money(src, 'Rental deposit held', Config.Economy.rentalDeposit, offer.cargo)
        end
    end

    local party = Parties.Snapshot(src)
    local job = {
        id = offer.id,
        kind = offer.kind,
        cargo = offer.cargo,
        pickup = offer.pickup,
        dropoff = offer.dropoff,
        distance = offer.distance,
        payout = offer.payout,
        xp = offer.xp,
        contract = offer.contract == true,
        stage = 'spawn',
        started = now(),
        integrity = 100,
        startBody = 1000,
        startEngine = 1000,
        truck = truckDef,
        owned = owned,
        deposit = offer.kind == 'quick' and Config.Economy.rentalDeposit or 0,
        party = party,
        plate = owned and owned.plate or nil,
    }

    active[src] = job
    offers[src] = nil

    if party then
        for i = 1, #party.members do
            local member = party.members[i]
            if member ~= src then
                active[member] = {
                    id = job.id,
                    kind = job.kind,
                    cargo = job.cargo,
                    pickup = job.pickup,
                    dropoff = job.dropoff,
                    distance = job.distance,
                    payout = job.payout,
                    xp = math.floor(job.xp * 0.7),
                    contract = false,
                    stage = 'spawn',
                    started = job.started,
                    integrity = 100,
                    party = party,
                    host = src,
                }
            end
        end
    end

    Webhooks.Player(src, 'jobs', 'Job started', {
        { name = 'Type', value = offer.kind, inline = true },
        { name = 'Cargo', value = offer.cargoLabel or offer.cargo, inline = true },
        { name = 'Route', value = ('%s → %s'):format(offer.pickupLabel, offer.dropoffLabel), inline = false },
        { name = 'Quoted', value = ('$%s'):format(offer.payout), inline = true },
    })

    return job
end

function Jobs.SetVehicle(src, netId, plate, trailerNet)
    local job = active[src]
    if not job or job.host then return false end
    job.netId = netId
    job.plate = plate
    job.trailerNet = trailerNet
    job.stage = 'pickup'
    return true
end

function Jobs.Report(src, payload)
    local job = active[src]
    if not job then return end
    payload = payload or {}
    if payload.integrity then
        job.integrity = math.max(5, math.min(100, tonumber(payload.integrity) or job.integrity))
    end
    if payload.body then job.body = tonumber(payload.body) end
    if payload.engine then job.engine = tonumber(payload.engine) end
    if payload.mileage then job.mileage = tonumber(payload.mileage) end
    if payload.raining then job.raining = true end
end

function Jobs.Advance(src, stage)
    local job = active[src]
    if not job then return nil, 'notify_invalid' end
    if now() - job.started > (Config.Economy.jobTimeout * 60) then
        return Jobs.Fail(src, 'Timed out', Config.Economy.abandonPenalty)
    end

    if stage == 'loaded' then
        if job.stage ~= 'pickup' then return nil, 'notify_invalid' end
        local depot = Config.GetDepot(job.pickup)
        if not nearPoint(src, depot and depot.load or depot and depot.pos, Config.LoadDistance + 8.0) then
            return nil, 'notify_too_far'
        end
        job.stage = 'dropoff'
        return job
    end

    if stage == 'delivered' then
        if job.stage ~= 'dropoff' then return nil, 'notify_invalid' end
        local depot = Config.GetDepot(job.dropoff)
        if not nearPoint(src, depot and depot.load or depot and depot.pos, Config.LoadDistance + 8.0) then
            return nil, 'notify_too_far'
        end
        return Jobs.Complete(src)
    end

    return nil, 'notify_invalid'
end

function Jobs.Complete(src)
    local job = active[src]
    if not job or job.host then
        return nil, 'notify_invalid'
    end

    local cargo = Config.GetCargo(job.cargo)
    local integrity = math.max(5, math.min(100, job.integrity or 100))
    local care = skillIntegrity(src)
    integrity = math.min(100, integrity + (care * 8))

    local km = math.max(0.8, (job.distance or 0) / 1000.0)
    local truckPay = job.truck and job.truck.payout or 1.0
    local pay = (cargo and cargo.payPerKm or 40) * km * truckPay
    pay = pay * (job.kind == 'freight' and Config.Economy.freightJobPay or Config.Economy.quickJobPay)
    pay = pay * skillPayout(src)
    pay = pay * (1.0 + clockBonus(job.raining))
    if job.contract then
        pay = pay * (1.0 + Config.Contracts.bonusPay + skillContract(src))
    end
    pay = pay * (integrity / 100.0)

    local fuel = math.floor(km * Config.Economy.fuelCostPerKm * (1.0 - skillFuel(src)))
    pay = pay - fuel

    local body = job.body or 1000
    local engine = job.engine or 1000
    local startBody = job.startBody or 1000
    local damagePct = 0
    if job.kind == 'freight' then
        damagePct = math.max(0, ((startBody - body) + ((job.startEngine or 1000) - engine)) / 20.0)
        local repair = math.floor(damagePct * Config.Economy.repairPerDamage)
        repair = math.floor(repair * (1.0 - skillRepair(src)))
        local profile = Profile.Get(src)
        if profile and profile.insurance == 1 then
            repair = math.floor(repair * Config.Economy.insuranceRepairDiscount)
        end
        pay = pay - repair
        job.repair = repair
        if job.owned then
            Fleet.ApplyReturn(src, job.owned.id, body, engine, job.mileage or 0)
        end
    else
        local healthPct = ((body + engine) / 20.0)
        if job.deposit > 0 then
            if healthPct < Config.Economy.rentalKeepDepositBelow then
                job.depositKept = true
            else
                Framework.AddMoney(src, job.deposit, 'trucking-rental-deposit')
            end
        end
    end

    pay = math.max(25, math.floor(pay * Config.Economy.payoutScale))

    local xp = math.floor((cargo and cargo.xpPerKm or 1) * km * 14)
    if job.contract then
        xp = math.floor(xp * (1.0 + Config.Contracts.bonusXp))
    end
    xp = math.floor(xp * (1.0 + Config.SkillRankBonus(Profile.Get(src) and Profile.Get(src).skills, 'endurance', 'distanceXp')))

    local partyBonus = 0
    if job.party and #(job.party.members or {}) > 1 then
        partyBonus = Config.Economy.convoyBonus + skillParty(src)
        pay = math.floor(pay * (1.0 + partyBonus))
    end

    Framework.AddMoney(src, pay, 'trucking-job')
    local _, level = Profile.AddXP(src, xp, 'job')

    local profile = Profile.Get(src)
    if profile then
        profile.stats.jobs = (profile.stats.jobs or 0) + 1
        profile.stats.todayJobs = (profile.stats.todayJobs or 0) + 1
        profile.stats.earned = (profile.stats.earned or 0) + pay
        profile.stats.todayEarned = (profile.stats.todayEarned or 0) + pay
        profile.stats.miles = (profile.stats.miles or 0) + math.floor(km * 0.621)
        profile.stats.bestPayout = math.max(profile.stats.bestPayout or 0, pay)
        if job.kind == 'freight' then
            profile.stats.freightJobs = (profile.stats.freightJobs or 0) + 1
        else
            profile.stats.quickJobs = (profile.stats.quickJobs or 0) + 1
        end
        profile.reputation = math.min(100, (profile.reputation or 0) + 1)
        profile.dirty = true
        if job.contract then
            Company.CompleteContract(src, job.cargo, job.dropoff)
        end
    end

    if DB.Ready() then
        MySQL.insert.await([[
            INSERT INTO dj_trucking_history
                (citizenid, job_type, cargo, pickup, dropoff, distance, payout, xp, damage, integrity)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ]], {
            Framework.GetCitizenId(src),
            job.kind,
            job.cargo,
            job.pickup,
            job.dropoff,
            job.distance or 0,
            pay,
            xp,
            math.floor(damagePct),
            math.floor(integrity),
        })
    end

    if job.party then
        local share = math.floor(pay * Config.Economy.partyShare)
        for i = 1, #job.party.members do
            local member = job.party.members[i]
            if member ~= src and GetPlayerPing(member) > 0 then
                Framework.AddMoney(member, share, 'trucking-party')
                Profile.AddXP(member, math.floor(xp * 0.55), 'party')
                Framework.Notify(member, 'notify_complete', 'success', share, math.floor(xp * 0.55))
                active[member] = nil
            end
        end
    end

    Webhooks.Player(src, 'jobs', 'Job completed', {
        { name = 'Type', value = job.kind, inline = true },
        { name = 'Cargo', value = job.cargo, inline = true },
        { name = 'Payout', value = ('$%s'):format(pay), inline = true },
        { name = 'XP', value = tostring(xp), inline = true },
        { name = 'Integrity', value = ('%s%%'):format(math.floor(integrity)), inline = true },
        { name = 'Repair', value = ('$%s'):format(job.repair or 0), inline = true },
        { name = 'Level', value = tostring(level), inline = true },
    })

    local result = {
        ok = true,
        payout = pay,
        xp = xp,
        integrity = integrity,
        repair = job.repair or 0,
        deposit = job.deposit,
        depositKept = job.depositKept == true,
        kind = job.kind,
        cargo = job.cargo,
        plate = job.plate,
        netId = job.netId,
        trailerNet = job.trailerNet,
    }

    active[src] = nil
    return result
end

function Jobs.Fail(src, reason, penalty)
    local job = active[src]
    if not job then return { ok = true } end

    penalty = penalty or Config.Economy.cancelPenalty
    if job.host then
        active[src] = nil
        return { ok = true, cancelled = true }
    end

    if penalty > 0 then
        if not Profile.ChargeCompany(src, penalty) then
            Framework.RemoveMoney(src, penalty, 'trucking-penalty')
        end
    end

    if job.kind == 'quick' and job.deposit and job.deposit > 0 and not job.depositKept then
        -- deposit stays with the company when a rental is abandoned
        job.depositKept = true
    end

    local profile = Profile.Get(src)
    if profile then
        profile.stats.failed = (profile.stats.failed or 0) + 1
        profile.reputation = math.max(0, (profile.reputation or 0) - 2)
        profile.dirty = true
        Profile.Save(src)
    end

    if job.party then
        for i = 1, #job.party.members do
            active[job.party.members[i]] = nil
        end
    end

    Webhooks.Player(src, 'jobs', 'Job failed', {
        { name = 'Reason', value = reason or 'cancelled', inline = false },
        { name = 'Penalty', value = ('$%s'):format(penalty), inline = true },
        { name = 'Cargo', value = job.cargo or '-', inline = true },
    })

    local result = {
        ok = true,
        cancelled = true,
        reason = reason,
        penalty = penalty,
        netId = job.netId,
        trailerNet = job.trailerNet,
        plate = job.plate,
        kind = job.kind,
    }
    active[src] = nil
    return result
end

function Jobs.History(src, limit)
    if not DB.Ready() then return {} end
    local rows = MySQL.query.await(
        'SELECT job_type, cargo, pickup, dropoff, distance, payout, xp, damage, integrity, created_at FROM dj_trucking_history WHERE citizenid = ? ORDER BY id DESC LIMIT ?',
        { Framework.GetCitizenId(src), limit or 12 }
    ) or {}
    return rows
end

function Jobs.Board()
    if not DB.Ready() then
        return { today = {}, all = {} }
    end
    local today = MySQL.query.await([[
        SELECT name, SUM(payout) AS value, COUNT(*) AS jobs
        FROM dj_trucking_history h
        LEFT JOIN dj_trucking_profiles p ON p.citizenid = h.citizenid
        WHERE h.created_at >= CURDATE()
        GROUP BY h.citizenid
        ORDER BY value DESC
        LIMIT 8
    ]]) or {}
    local all = MySQL.query.await([[
        SELECT name, SUM(payout) AS value, COUNT(*) AS jobs
        FROM dj_trucking_history h
        LEFT JOIN dj_trucking_profiles p ON p.citizenid = h.citizenid
        GROUP BY h.citizenid
        ORDER BY value DESC
        LIMIT 8
    ]]) or {}
    return { today = today, all = all }
end

AddEventHandler('playerDropped', function()
    local src = source
    if active[src] and not active[src].host then
        Jobs.Fail(src, 'disconnected', Config.Economy.abandonPenalty)
    end
    active[src] = nil
    offers[src] = nil
end)

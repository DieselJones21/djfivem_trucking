Fleet = {}

local function plateFor(src)
    return ('DJ%05d'):format(math.random(1000, 99999))
end

function Fleet.List(src)
    if not DB.Ready() then return {} end
    return MySQL.query.await(
        'SELECT * FROM dj_trucking_trucks WHERE citizenid = ? ORDER BY id DESC',
        { Framework.GetCitizenId(src) }
    ) or {}
end

function Fleet.GetOwned(src, rowId)
    if not DB.Ready() then return nil end
    return MySQL.single.await(
        'SELECT * FROM dj_trucking_trucks WHERE id = ? AND citizenid = ?',
        { rowId, Framework.GetCitizenId(src) }
    )
end

function Fleet.Catalog(src)
    local level = Profile.Level(src)
    local owned = Fleet.List(src)
    local have = {}
    for i = 1, #owned do
        have[owned[i].truck_id] = (have[owned[i].truck_id] or 0) + 1
    end

    local list = {}
    for i = 1, #Config.Trucks do
        local truck = Config.Trucks[i]
        if truck.buyable then
            list[#list + 1] = {
                id = truck.id,
                model = truck.model,
                label = truck.label,
                description = truck.description,
                class = truck.class,
                price = truck.price,
                level = truck.level,
                locked = level < truck.level,
                owned = have[truck.id] or 0,
                payout = truck.payout,
                cargo = truck.cargo,
                trailer = truck.trailer == true,
            }
        end
    end
    return list, owned
end

function Fleet.Buy(src, truckId)
    if not Framework.RateLimit(src, 'buy', 1.2) then
        return nil, 'notify_invalid'
    end
    local truck = Config.GetTruck(truckId)
    if not truck or not truck.buyable then
        return nil, 'notify_invalid'
    end
    if Profile.Level(src) < truck.level then
        return nil, 'notify_level'
    end
    if not Framework.RemoveMoney(src, truck.price, 'trucking-truck') then
        return nil, 'notify_no_money'
    end

    local plate = plateFor(src)
    local id = MySQL.insert.await([[
        INSERT INTO dj_trucking_trucks (citizenid, truck_id, model, plate, label, body, engine, mileage, stored, upgrades)
        VALUES (?, ?, ?, ?, ?, 1000, 1000, 0, 1, '{}')
    ]], {
        Framework.GetCitizenId(src),
        truck.id,
        truck.model,
        plate,
        truck.label,
    })

    local profile = Profile.Get(src)
    if profile then
        profile.stats.spent = (profile.stats.spent or 0) + truck.price
        profile.dirty = true
        Profile.Save(src)
    end

    Webhooks.Player(src, 'fleet', 'Truck purchased', {
        { name = 'Truck', value = truck.label, inline = true },
        { name = 'Plate', value = plate, inline = true },
        { name = 'Price', value = ('$%s'):format(truck.price), inline = true },
        { name = 'Spawn', value = truck.model, inline = true },
    })
    Webhooks.Money(src, 'Truck purchased', truck.price, truck.id)

    return { id = id, plate = plate, truck = truck }
end

function Fleet.Sell(src, rowId)
    local row = Fleet.GetOwned(src, rowId)
    if not row then return nil, 'notify_invalid' end
    if row.stored ~= 1 then return nil, 'notify_truck_out' end

    local truck = Config.GetTruck(row.truck_id)
    local price = math.floor((truck and truck.price or 10000) * Config.Economy.sellDepreciation)
    local health = ((row.body or 1000) + (row.engine or 1000)) / 2000.0
    price = math.max(500, math.floor(price * math.max(0.45, health)))

    MySQL.update.await('DELETE FROM dj_trucking_trucks WHERE id = ? AND citizenid = ?', {
        rowId, Framework.GetCitizenId(src),
    })
    Framework.AddMoney(src, price, 'trucking-sell-truck')

    Webhooks.Player(src, 'fleet', 'Truck sold', {
        { name = 'Truck', value = row.label or row.truck_id, inline = true },
        { name = 'Payout', value = ('$%s'):format(price), inline = true },
    })
    return { price = price, label = row.label }
end

function Fleet.Repair(src, rowId)
    local row = Fleet.GetOwned(src, rowId)
    if not row then return nil, 'notify_invalid' end

    local missing = math.max(0, (2000 - (row.body or 1000) - (row.engine or 1000)) / 20.0)
    if missing < 1 then
        return { price = 0, already = true }
    end

    local price = math.floor(missing * Config.Economy.repairPerDamage)
    local profile = Profile.Get(src)
    price = math.floor(price * (1.0 - Config.SkillRankBonus(profile and profile.skills, 'mechanic', 'repair')))
    if profile and profile.insurance == 1 then
        price = math.floor(price * Config.Economy.insuranceRepairDiscount)
    end
    price = math.max(25, price)

    if not Profile.ChargeCompany(src, price) then
        if not Framework.RemoveMoney(src, price, 'trucking-repair') then
            return nil, 'notify_no_money'
        end
    end

    MySQL.update.await('UPDATE dj_trucking_trucks SET body = 1000, engine = 1000 WHERE id = ?', { rowId })
    Webhooks.Player(src, 'fleet', 'Truck repaired', {
        { name = 'Truck', value = row.label or row.plate, inline = true },
        { name = 'Cost', value = ('$%s'):format(price), inline = true },
    })
    return { price = price, label = row.label }
end

function Fleet.SetStored(src, rowId, stored)
    if not rowId then return end
    MySQL.update.await('UPDATE dj_trucking_trucks SET stored = ? WHERE id = ? AND citizenid = ?', {
        stored and 1 or 0, rowId, Framework.GetCitizenId(src),
    })
end

function Fleet.ApplyReturn(src, rowId, body, engine, mileage)
    local row = Fleet.GetOwned(src, rowId)
    if not row then return end
    MySQL.update.await(
        'UPDATE dj_trucking_trucks SET body = ?, engine = ?, mileage = ?, stored = 1 WHERE id = ? AND citizenid = ?',
        {
            body or row.body,
            engine or row.engine,
            math.floor((row.mileage or 0) + (mileage or 0)),
            rowId,
            Framework.GetCitizenId(src),
        }
    )
end

function Fleet.Diagnostics(src)
    local owned = Fleet.List(src)
    local list = {}
    for i = 1, #owned do
        local row = owned[i]
        local body = row.body or 1000
        local engine = row.engine or 1000
        list[#list + 1] = {
            id = row.id,
            truckId = row.truck_id,
            label = row.label,
            plate = row.plate,
            model = row.model,
            body = math.floor(body / 10),
            engine = math.floor(engine / 10),
            health = math.floor(((body + engine) / 20)),
            mileage = row.mileage or 0,
            stored = row.stored == 1,
            repair = math.max(0, math.floor(((2000 - body - engine) / 20) * Config.Economy.repairPerDamage)),
        }
    end
    return list
end

lib.locale()
math.randomseed(os.time() % 2147483646)

local function packCoord(v)
    if not v then return nil end
    return {
        x = (v.x or v[1] or 0.0) + 0.0,
        y = (v.y or v[2] or 0.0) + 0.0,
        z = (v.z or v[3] or 0.0) + 0.0,
        w = (v.w or v[4] or 0.0) + 0.0,
    }
end

local function payload(src, depotId)
    Profile.Load(src)
    Company.TickOwner(src)
    Company.CollectFees(src)

    local public = Profile.Public(src)
    local catalog, owned = Fleet.Catalog(src)
    local depot = Config.GetDepot(depotId)

    return {
        ok = true,
        player = public,
        depot = depot and {
            id = depot.id,
            label = depot.label,
            subtitle = depot.subtitle,
        } or nil,
        trucks = catalog,
        garage = owned,
        diagnostics = Fleet.Diagnostics(src),
        skills = Config.Skills,
        skillOrder = Config.SkillOrder,
        certs = Config.Certs,
        certOrder = Config.CertOrder,
        cargo = Config.Cargo,
        cargoOrder = Config.CargoOrder,
        loans = {
            products = Config.Loans.products,
            active = Company.Loans(src),
        },
        employees = Company.Roster(src),
        contracts = Company.DailyContracts(src),
        party = Parties.Public(src),
        nearby = Parties.Nearby(src),
        history = Jobs.History(src, 10),
        board = Jobs.Board(),
        brand = Config.Brand,
        job = Jobs.Get(src),
    }
end

lib.callback.register('djfivem_trucking:open', function(source, depotId)
    if not Framework.RateLimit(source, 'open', 0.4) then
        return { ok = false, error = 'notify_invalid' }
    end
    if depotId and not Config.GetDepot(depotId) then
        return { ok = false, error = 'notify_invalid' }
    end
    if depotId then
        local depot = Config.GetDepot(depotId)
        local ped = GetPlayerPed(source)
        if ped and ped ~= 0 then
            local coords = GetEntityCoords(ped)
            if #(coords - depot.pos) > (Config.DepotDistance + 6.0) then
                return { ok = false, error = 'notify_too_far' }
            end
        end
    end
    return payload(source, depotId)
end)

lib.callback.register('djfivem_trucking:offers', function(source, depotId, kind)
    local items, err = Jobs.Generate(source, depotId, kind)
    if not items then
        return { ok = false, error = err }
    end
    return { ok = true, offers = items }
end)

lib.callback.register('djfivem_trucking:startJob', function(source, offerId, truckRowId)
    local job, err = Jobs.Start(source, offerId, truckRowId)
    if not job then
        return { ok = false, error = err }
    end

    local pickup = Config.GetDepot(job.pickup)
    local dropoff = Config.GetDepot(job.dropoff)
    local cargo = Config.GetCargo(job.cargo)

    return {
        ok = true,
        job = {
            id = job.id,
            kind = job.kind,
            cargo = job.cargo,
            cargoLabel = cargo and cargo.label,
            pickup = job.pickup,
            dropoff = job.dropoff,
            pickupLabel = pickup and pickup.label,
            dropoffLabel = dropoff and dropoff.label,
            pickupLoad = packCoord(pickup and pickup.load),
            dropoffLoad = packCoord(dropoff and dropoff.load),
            truck = job.truck,
            owned = job.owned,
            trailer = job.truck and job.truck.trailer and Config.Trailers[job.cargo] or nil,
            spawn = pickup and {
                truck = packCoord(pickup.truck),
                trailer = packCoord(pickup.trailer),
            } or nil,
            deposit = job.deposit,
            payout = job.payout,
            speedSoftCap = cargo and cargo.speedSoftCap or 0,
            integrityLoss = cargo and cargo.integrityLoss or 0.4,
        },
    }
end)

lib.callback.register('djfivem_trucking:registerVehicle', function(source, netId, plate, trailerNet)
    if not Jobs.Get(source) then return { ok = false } end
    local vehicle = netId and NetworkGetEntityFromNetworkId(netId)
    if vehicle and vehicle ~= 0 then
        Framework.GiveKeys(source, vehicle, plate)
    end
    Jobs.SetVehicle(source, netId, plate, trailerNet)
    return { ok = true }
end)

lib.callback.register('djfivem_trucking:advance', function(source, stage)
    local job, err = Jobs.Advance(source, stage)
    if not job then
        return { ok = false, error = err }
    end
    return { ok = true, job = job, result = job.payout and job or nil }
end)

lib.callback.register('djfivem_trucking:complete', function(source, report)
    Jobs.Report(source, report)
    local result, err = Jobs.Complete(source)
    if not result then
        return { ok = false, error = err }
    end
    if result.netId then
        local vehicle = NetworkGetEntityFromNetworkId(result.netId)
        if vehicle and vehicle ~= 0 then
            Framework.RemoveKeys(source, vehicle, result.plate)
        end
    end
    return { ok = true, result = result }
end)

lib.callback.register('djfivem_trucking:cancel', function(source)
    local result = Jobs.Fail(source, 'cancelled', Config.Economy.cancelPenalty)
    return { ok = true, result = result }
end)

RegisterNetEvent('djfivem_trucking:report', function(report)
    Jobs.Report(source, report)
end)

lib.callback.register('djfivem_trucking:buyTruck', function(source, truckId)
    local result, err = Fleet.Buy(source, truckId)
    if not result then return { ok = false, error = err } end
    return { ok = true, result = result, player = Profile.Public(source), garage = Fleet.List(source), trucks = select(1, Fleet.Catalog(source)) }
end)

lib.callback.register('djfivem_trucking:sellTruck', function(source, rowId)
    local result, err = Fleet.Sell(source, rowId)
    if not result then return { ok = false, error = err } end
    return { ok = true, result = result, player = Profile.Public(source), garage = Fleet.List(source), diagnostics = Fleet.Diagnostics(source) }
end)

lib.callback.register('djfivem_trucking:repairTruck', function(source, rowId)
    local result, err = Fleet.Repair(source, rowId)
    if not result then return { ok = false, error = err } end
    return { ok = true, result = result, player = Profile.Public(source), garage = Fleet.List(source), diagnostics = Fleet.Diagnostics(source) }
end)

lib.callback.register('djfivem_trucking:takeTruck', function(source, rowId, depotId)
    local row = Fleet.GetOwned(source, rowId)
    if not row then return { ok = false, error = 'notify_invalid' } end
    if row.stored ~= 1 then return { ok = false, error = 'notify_truck_out' } end
    local depot = Config.GetDepot(depotId)
    if not depot then return { ok = false, error = 'notify_invalid' } end
    Fleet.SetStored(source, rowId, false)
    return {
        ok = true,
        spawn = packCoord(depot.truck),
        truck = Config.GetTruck(row.truck_id),
        row = row,
    }
end)

lib.callback.register('djfivem_trucking:storeTruck', function(source, rowId, body, engine, mileage)
    Fleet.ApplyReturn(source, rowId, body, engine, mileage)
    return { ok = true, garage = Fleet.List(source), diagnostics = Fleet.Diagnostics(source) }
end)

lib.callback.register('djfivem_trucking:issuedKeys', function(source, netId, plate)
    local vehicle = netId and NetworkGetEntityFromNetworkId(netId)
    if vehicle and vehicle ~= 0 then
        Framework.GiveKeys(source, vehicle, plate)
    end
    return { ok = true }
end)

lib.callback.register('djfivem_trucking:upgradeSkill', function(source, skillId)
    local result, err = Company.UnlockSkill(source, skillId)
    if not result then return { ok = false, error = err } end
    return { ok = true, result = result, player = Profile.Public(source) }
end)

lib.callback.register('djfivem_trucking:unlockCert', function(source, certId)
    local result, err = Company.UnlockCert(source, certId)
    if not result then return { ok = false, error = err } end
    return { ok = true, result = result, player = Profile.Public(source) }
end)

lib.callback.register('djfivem_trucking:rename', function(source, name)
    local result, err = Company.Rename(source, name)
    if not result then return { ok = false, error = err } end
    return { ok = true, result = result, player = Profile.Public(source) }
end)

lib.callback.register('djfivem_trucking:deposit', function(source, amount)
    local result, err = Company.Deposit(source, amount)
    if not result then return { ok = false, error = err } end
    return { ok = true, result = result, player = Profile.Public(source) }
end)

lib.callback.register('djfivem_trucking:withdraw', function(source, amount)
    local result, err = Company.Withdraw(source, amount)
    if not result then return { ok = false, error = err } end
    return { ok = true, result = result, player = Profile.Public(source) }
end)

lib.callback.register('djfivem_trucking:insurance', function(source)
    local result, err = Company.BuyInsurance(source)
    if not result then return { ok = false, error = err } end
    return { ok = true, result = result, player = Profile.Public(source) }
end)

lib.callback.register('djfivem_trucking:hire', function(source, employeeId)
    local result, err = Company.Hire(source, employeeId)
    if not result then return { ok = false, error = err } end
    return { ok = true, result = result, employees = Company.Roster(source), player = Profile.Public(source) }
end)

lib.callback.register('djfivem_trucking:fire', function(source, employeeId)
    local result, err = Company.Fire(source, employeeId)
    if not result then return { ok = false, error = err } end
    return { ok = true, result = result, employees = Company.Roster(source) }
end)

lib.callback.register('djfivem_trucking:loan', function(source, productId)
    local result, err = Company.TakeLoan(source, productId)
    if not result then return { ok = false, error = err } end
    return { ok = true, result = result, loans = { products = Config.Loans.products, active = Company.Loans(source) }, player = Profile.Public(source) }
end)

lib.callback.register('djfivem_trucking:payLoan', function(source, loanId, amount)
    local result, err = Company.PayLoan(source, loanId, amount)
    if not result then return { ok = false, error = err } end
    return { ok = true, result = result, loans = { products = Config.Loans.products, active = Company.Loans(source) }, player = Profile.Public(source) }
end)

lib.callback.register('djfivem_trucking:partyCreate', function(source)
    return { ok = true, party = Parties.Create(source) }
end)

lib.callback.register('djfivem_trucking:partyInvite', function(source, target)
    local result, err = Parties.Invite(source, target)
    if not result then return { ok = false, error = err } end
    return { ok = true, nearby = Parties.Nearby(source) }
end)

lib.callback.register('djfivem_trucking:partyJoin', function(source, partyId)
    local result, err = Parties.Join(source, partyId)
    if not result then return { ok = false, error = err } end
    return { ok = true, party = result }
end)

lib.callback.register('djfivem_trucking:partyLeave', function(source)
    return { ok = true, party = Parties.Leave(source) }
end)

lib.addCommand(Config.AdminCommand, {
    help = 'DJ Logistics admin',
    params = {
        { name = 'action', help = 'givexp | setxp | reset', type = 'string' },
        { name = 'target', help = 'Player id', type = 'number', optional = true },
        { name = 'amount', help = 'XP amount', type = 'number', optional = true },
    },
    restricted = Config.AdminAce,
}, function(source, args)
    if source > 0 and not Framework.IsAdmin(source) then return end
    local action = args.action
    local target = args.target or source
    if action == 'givexp' then
        Profile.AddXP(target, args.amount or 0, 'admin')
        if source > 0 then
            Framework.Notify(source, 'admin_xp', 'success', args.amount or 0, Framework.GetPlayerName(target))
        end
        Webhooks.Player(target, 'admin', 'Admin XP grant', {
            { name = 'Amount', value = tostring(args.amount or 0), inline = true },
            { name = 'Staff', value = source > 0 and Framework.GetPlayerName(source) or 'console', inline = true },
        })
    elseif action == 'setxp' then
        local profile = Profile.Get(target)
        if profile then
            profile.xp = math.max(0, math.floor(args.amount or 0))
            profile.dirty = true
            Profile.Save(target)
        end
    elseif action == 'reset' then
        local cid = Framework.GetCitizenId(target)
        if DB.Ready() and cid then
            MySQL.update.await('DELETE FROM dj_trucking_profiles WHERE citizenid = ?', { cid })
            MySQL.update.await('DELETE FROM dj_trucking_trucks WHERE citizenid = ?', { cid })
            MySQL.update.await('DELETE FROM dj_trucking_loans WHERE citizenid = ?', { cid })
            MySQL.update.await('DELETE FROM dj_trucking_employees WHERE citizenid = ?', { cid })
        end
        Profile.Drop(target)
        Profile.Load(target)
        if source > 0 then
            Framework.Notify(source, 'admin_reset', 'success', Framework.GetPlayerName(target))
        end
        Webhooks.Player(target, 'admin', 'Trucking data reset', {
            { name = 'Staff', value = source > 0 and Framework.GetPlayerName(source) or 'console', inline = true },
        })
    end
end)

exports('GetProfile', function(src)
    return Profile.Public(src)
end)

exports('IsOnJob', function(src)
    return Jobs.Get(src) ~= nil
end)

exports('AddXP', function(src, amount, reason)
    return Profile.AddXP(src, amount, reason)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for _, playerId in ipairs(GetPlayers()) do
        Profile.Drop(tonumber(playerId))
    end
end)

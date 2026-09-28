local currentDepot
local nuiReadyAt = 0
local openingTablet = false

local function reply(cb, result)
    result = result or { ok = false }
    if result.error and not result.message then
        local ok, text = pcall(locale, result.error)
        result.message = (ok and text) or result.error
    end
    cb(result)
end

local function run(cb, fn)
    local ok, result = pcall(fn)
    if not ok then
        reply(cb, { ok = false, error = 'notify_invalid' })
        return
    end
    reply(cb, result)
end

local function closeTablet()
    currentDepot = nil
    ReleaseTablet()
    NuiCall('close')
end

CloseTablet = closeTablet

function OpenTablet(depot)
    depot = depot or Config.GetHq()
    if not depot then return end
    if openingTablet then return end
    if IsTabletOpen() then
        local focused = false
        pcall(function()
            focused = IsNuiFocused()
        end)
        if focused then
            return
        end
        closeTablet()
    end

    openingTablet = true
    SetTimeout(8000, function()
        openingTablet = false
    end)
    local payload = lib.callback.await('djfivem_trucking:open', false, depot.id)
    if not payload or not payload.ok then
        openingTablet = false
        Notify(payload and payload.error or 'notify_too_far', 'error')
        ReleaseTablet()
        return
    end

    currentDepot = depot
    nuiReadyAt = 0
    SetTabletOpen(true)
    SetNuiFocus(true, true)
    NuiCall('open', payload)
    openingTablet = false

    SetTimeout(4000, function()
        if IsTabletOpen() and nuiReadyAt == 0 then
            closeTablet()
            Notify('notify_invalid', 'error')
        end
    end)
end

RegisterNUICallback('ready', function(_, cb)
    nuiReadyAt = GetGameTimer()
    cb({ ok = true })
end)

RegisterNUICallback('close', function(_, cb)
    currentDepot = nil
    ReleaseTablet()
    cb({ ok = true })
end)

RegisterNUICallback('offers', function(data, cb)
    run(cb, function()
        local kind = data and data.kind or 'quick'
        local depotId = currentDepot and currentDepot.id or (data and data.depotId)
        return lib.callback.await('djfivem_trucking:offers', false, depotId, kind) or { ok = false, error = 'notify_invalid' }
    end)
end)

RegisterNUICallback('startJob', function(data, cb)
    local result
    local ok, err = pcall(function()
        result = lib.callback.await('djfivem_trucking:startJob', false, data and data.offerId, data and data.truckId)
    end)
    if not ok or not result or not result.ok then
        if not ok then
            reply(cb, { ok = false, error = 'notify_invalid' })
        else
            reply(cb, result or { ok = false, error = 'notify_invalid' })
        end
        return
    end

    -- Ack the tablet first so the UI can unfreeze, then spawn off-thread.
    reply(cb, { ok = true })
    closeTablet()
    SetTimeout(200, function()
        StartDelivery(result.job)
    end)
end)

RegisterNUICallback('buyTruck', function(data, cb)
    run(cb, function()
        return lib.callback.await('djfivem_trucking:buyTruck', false, data and data.truckId) or { ok = false }
    end)
end)

RegisterNUICallback('sellTruck', function(data, cb)
    run(cb, function()
        return lib.callback.await('djfivem_trucking:sellTruck', false, data and data.rowId) or { ok = false }
    end)
end)

RegisterNUICallback('repairTruck', function(data, cb)
    run(cb, function()
        return lib.callback.await('djfivem_trucking:repairTruck', false, data and data.rowId) or { ok = false }
    end)
end)

RegisterNUICallback('takeTruck', function(data, cb)
    local result
    local ok = pcall(function()
        result = lib.callback.await('djfivem_trucking:takeTruck', false, data and data.rowId, currentDepot and currentDepot.id)
    end)
    if not ok or not result or not result.ok then
        reply(cb, result or { ok = false, error = 'notify_invalid' })
        return
    end
    reply(cb, { ok = true })
    closeTablet()
    SetTimeout(200, function()
        SpawnOwnedTruck(result)
    end)
end)

RegisterNUICallback('upgradeSkill', function(data, cb)
    run(cb, function()
        return lib.callback.await('djfivem_trucking:upgradeSkill', false, data and data.skillId) or { ok = false }
    end)
end)

RegisterNUICallback('unlockCert', function(data, cb)
    run(cb, function()
        return lib.callback.await('djfivem_trucking:unlockCert', false, data and data.certId) or { ok = false }
    end)
end)

RegisterNUICallback('rename', function(data, cb)
    run(cb, function()
        return lib.callback.await('djfivem_trucking:rename', false, data and data.name) or { ok = false }
    end)
end)

RegisterNUICallback('deposit', function(data, cb)
    run(cb, function()
        return lib.callback.await('djfivem_trucking:deposit', false, data and data.amount) or { ok = false }
    end)
end)

RegisterNUICallback('withdraw', function(data, cb)
    run(cb, function()
        return lib.callback.await('djfivem_trucking:withdraw', false, data and data.amount) or { ok = false }
    end)
end)

RegisterNUICallback('insurance', function(_, cb)
    run(cb, function()
        return lib.callback.await('djfivem_trucking:insurance', false) or { ok = false }
    end)
end)

RegisterNUICallback('hire', function(data, cb)
    run(cb, function()
        return lib.callback.await('djfivem_trucking:hire', false, data and data.employeeId) or { ok = false }
    end)
end)

RegisterNUICallback('fire', function(data, cb)
    run(cb, function()
        return lib.callback.await('djfivem_trucking:fire', false, data and data.employeeId) or { ok = false }
    end)
end)

RegisterNUICallback('loan', function(data, cb)
    run(cb, function()
        return lib.callback.await('djfivem_trucking:loan', false, data and data.productId) or { ok = false }
    end)
end)

RegisterNUICallback('payLoan', function(data, cb)
    run(cb, function()
        return lib.callback.await('djfivem_trucking:payLoan', false, data and data.loanId, data and data.amount) or { ok = false }
    end)
end)

RegisterNUICallback('partyCreate', function(_, cb)
    run(cb, function()
        return lib.callback.await('djfivem_trucking:partyCreate', false) or { ok = false }
    end)
end)

RegisterNUICallback('partyInvite', function(data, cb)
    run(cb, function()
        return lib.callback.await('djfivem_trucking:partyInvite', false, data and data.target) or { ok = false }
    end)
end)

RegisterNUICallback('partyLeave', function(_, cb)
    run(cb, function()
        return lib.callback.await('djfivem_trucking:partyLeave', false) or { ok = false }
    end)
end)

RegisterNUICallback('cancelJob', function(_, cb)
    CreateThread(function()
        CancelHaul(true)
    end)
    reply(cb, { ok = true })
end)

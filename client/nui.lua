local currentDepot

local function closeTablet()
    if not IsTabletOpen() then return end
    SetTabletOpen(false)
    currentDepot = nil
    SetNuiFocus(false, false)
    NuiCall('close')
end

CloseTablet = closeTablet

function OpenTablet(depot)
    if IsTabletOpen() or IsOnDelivery() then return end
    local payload = lib.callback.await('djfivem_trucking:open', false, depot and depot.id)
    if not payload or not payload.ok then
        Notify(payload and payload.error or 'notify_too_far', 'error')
        return
    end

    currentDepot = depot
    SetTabletOpen(true)
    SetNuiFocus(true, true)
    NuiCall('open', payload)
end

RegisterNUICallback('close', function(_, cb)
    closeTablet()
    cb(1)
end)

RegisterNUICallback('offers', function(data, cb)
    local kind = data and data.kind or 'quick'
    local depotId = currentDepot and currentDepot.id or (data and data.depotId)
    local result = lib.callback.await('djfivem_trucking:offers', false, depotId, kind)
    cb(result or { ok = false, error = 'notify_invalid' })
end)

RegisterNUICallback('startJob', function(data, cb)
    local result = lib.callback.await('djfivem_trucking:startJob', false, data and data.offerId, data and data.truckId)
    if result and result.ok then
        closeTablet()
        StartDelivery(result.job)
    end
    cb(result or { ok = false })
end)

RegisterNUICallback('buyTruck', function(data, cb)
    cb(lib.callback.await('djfivem_trucking:buyTruck', false, data and data.truckId) or { ok = false })
end)

RegisterNUICallback('sellTruck', function(data, cb)
    cb(lib.callback.await('djfivem_trucking:sellTruck', false, data and data.rowId) or { ok = false })
end)

RegisterNUICallback('repairTruck', function(data, cb)
    cb(lib.callback.await('djfivem_trucking:repairTruck', false, data and data.rowId) or { ok = false })
end)

RegisterNUICallback('takeTruck', function(data, cb)
    local depotId = currentDepot and currentDepot.id
    local result = lib.callback.await('djfivem_trucking:takeTruck', false, data and data.rowId, depotId)
    if result and result.ok then
        closeTablet()
        SpawnOwnedTruck(result)
    end
    cb(result or { ok = false })
end)

RegisterNUICallback('upgradeSkill', function(data, cb)
    cb(lib.callback.await('djfivem_trucking:upgradeSkill', false, data and data.skillId) or { ok = false })
end)

RegisterNUICallback('unlockCert', function(data, cb)
    cb(lib.callback.await('djfivem_trucking:unlockCert', false, data and data.certId) or { ok = false })
end)

RegisterNUICallback('rename', function(data, cb)
    cb(lib.callback.await('djfivem_trucking:rename', false, data and data.name) or { ok = false })
end)

RegisterNUICallback('deposit', function(data, cb)
    cb(lib.callback.await('djfivem_trucking:deposit', false, data and data.amount) or { ok = false })
end)

RegisterNUICallback('withdraw', function(data, cb)
    cb(lib.callback.await('djfivem_trucking:withdraw', false, data and data.amount) or { ok = false })
end)

RegisterNUICallback('insurance', function(_, cb)
    cb(lib.callback.await('djfivem_trucking:insurance', false) or { ok = false })
end)

RegisterNUICallback('hire', function(data, cb)
    cb(lib.callback.await('djfivem_trucking:hire', false, data and data.employeeId) or { ok = false })
end)

RegisterNUICallback('fire', function(data, cb)
    cb(lib.callback.await('djfivem_trucking:fire', false, data and data.employeeId) or { ok = false })
end)

RegisterNUICallback('loan', function(data, cb)
    cb(lib.callback.await('djfivem_trucking:loan', false, data and data.productId) or { ok = false })
end)

RegisterNUICallback('payLoan', function(data, cb)
    cb(lib.callback.await('djfivem_trucking:payLoan', false, data and data.loanId, data and data.amount) or { ok = false })
end)

RegisterNUICallback('partyCreate', function(_, cb)
    cb(lib.callback.await('djfivem_trucking:partyCreate', false) or { ok = false })
end)

RegisterNUICallback('partyInvite', function(data, cb)
    cb(lib.callback.await('djfivem_trucking:partyInvite', false, data and data.target) or { ok = false })
end)

RegisterNUICallback('partyLeave', function(_, cb)
    cb(lib.callback.await('djfivem_trucking:partyLeave', false) or { ok = false })
end)

RegisterNUICallback('cancelJob', function(_, cb)
    local result = lib.callback.await('djfivem_trucking:cancel', false)
    EndDelivery(true)
    cb(result or { ok = true })
end)

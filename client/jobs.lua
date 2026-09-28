local delivery
local routeBlip
local lastReport = 0
local lastHealth = 1000.0
local warnedMissing = false

function IsOnDelivery()
    return delivery ~= nil
end

function GetDelivery()
    return delivery
end

local function setBlip(coords, kind)
    if routeBlip then
        RemoveBlip(routeBlip)
        routeBlip = nil
    end
    if not coords then return end
    local cfg = Config.Blips[kind] or Config.Blips.pickup
    routeBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(routeBlip, cfg.sprite)
    SetBlipColour(routeBlip, cfg.color)
    SetBlipScale(routeBlip, cfg.scale)
    SetBlipRoute(routeBlip, true)
    SetBlipRouteColour(routeBlip, cfg.color)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(cfg.label)
    EndTextCommandSetBlipName(routeBlip)
end

local function hud(status)
    if not delivery then
        NuiCall('hud', { show = false })
        return
    end
    NuiCall('hud', {
        show = true,
        cargo = delivery.cargoLabel or delivery.cargo,
        status = status,
        dest = delivery.stage == 'pickup' and delivery.pickupLabel or delivery.dropoffLabel,
        integrity = math.floor(delivery.integrity or 100),
        kind = delivery.kind,
    })
end

local function pointOf(job, stage)
    if stage == 'pickup' then
        return job.pickupLoad
    end
    return job.dropoffLoad
end

function StartDelivery(job)
    if delivery then return end
    delivery = job
    delivery.stage = 'pickup'
    delivery.integrity = 100
    lastHealth = 1000.0
    warnedMissing = false

    local truck = SpawnJobRig(job)
    if not truck then
        lib.callback.await('djfivem_trucking:cancel', false)
        delivery = nil
        NuiCall('hud', { show = false })
        return
    end

    setBlip(job.pickupLoad, 'pickup')
    Notify('notify_job_started', 'success', job.kind == 'freight' and 'Freight' or 'Quick', job.pickupLabel)
    hud(locale('hud_pickup'))
end

function EndDelivery(deleteVehicles)
    if routeBlip then
        RemoveBlip(routeBlip)
        routeBlip = nil
    end
    NuiCall('hud', { show = false })
    lib.hideTextUI()
    if deleteVehicles or (delivery and delivery.kind == 'quick') then
        ClearSpawnedRig(true)
    else
        ClearSpawnedRig(false)
    end
    delivery = nil
    warnedMissing = false
end

function CancelHaul(skipConfirm)
    if not delivery then
        lib.callback.await('djfivem_trucking:cancel', false)
        EndDelivery(true)
        return true
    end
    if not skipConfirm then
        local confirm = lib.alertDialog({
            header = Config.Brand.title,
            content = locale('notify_cancel_prompt'),
            centered = true,
            cancel = true,
        })
        if confirm ~= 'confirm' then
            return false
        end
    end
    lib.callback.await('djfivem_trucking:cancel', false)
    EndDelivery(true)
    Notify('notify_cancelled', 'inform')
    return true
end

local function doProgress(label, duration)
    return lib.progressCircle({
        duration = duration,
        label = label,
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
    })
end

local function atPoint(coords, range)
    if not coords then return false end
    local pos = vec3(coords.x, coords.y, coords.z)
    return #(GetEntityCoords(cache.ped) - pos) <= (range or Config.LoadDistance)
end

local function reportIntegrity()
    if not delivery then return end
    local body, engine = RigHealth()
    if lastHealth - body > 2.0 then
        local loss = (lastHealth - body) * (delivery.integrityLoss or 0.4) * 0.08
        delivery.integrity = math.max(8, (delivery.integrity or 100) - loss)
    end
    lastHealth = body
    local now = GetGameTimer()
    if now - lastReport > 4000 then
        lastReport = now
        TriggerServerEvent('djfivem_trucking:report', {
            integrity = delivery.integrity,
            body = body,
            engine = engine,
            raining = (GetRainLevel and GetRainLevel() or 0) > 0.15,
        })
        hud(delivery.stage == 'pickup' and locale('hud_pickup') or locale('hud_dropoff'))
    end
end

CreateThread(function()
    while true do
        if delivery then
            reportIntegrity()
            if not JobTruckReady() then
                if not warnedMissing then
                    warnedMissing = true
                    Notify('notify_truck_gone', 'error')
                end
            else
                warnedMissing = false
            end

            local dest = pointOf(delivery, delivery.stage)
            if dest and atPoint(dest, Config.JobMarkerDistance) then
                DrawMarker(1, dest.x, dest.y, dest.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 4.0, 4.0, 0.8, 255, 77, 28, 140, false, false, 2, false, nil, nil, false)
                if atPoint(dest, Config.LoadDistance) then
                    if not JobTruckReady() then
                        lib.showTextUI(locale('textui_need_truck'))
                    elseif delivery.stage == 'pickup' then
                        lib.showTextUI('[E] Load cargo')
                        if IsControlJustReleased(0, 38) then
                            lib.hideTextUI()
                            if doProgress(locale('progress_load'), Config.Economy.loadDuration) then
                                if not JobTruckReady() then
                                    Notify('notify_need_truck', 'error')
                                else
                                    local result = lib.callback.await('djfivem_trucking:advance', false, 'loaded')
                                    if result and result.ok then
                                        delivery.stage = 'dropoff'
                                        setBlip(delivery.dropoffLoad, 'dropoff')
                                        Notify('notify_loaded', 'success', delivery.dropoffLabel)
                                        hud(locale('hud_dropoff'))
                                    else
                                        Notify(result and result.error or 'notify_invalid', 'error')
                                    end
                                end
                            end
                        end
                    else
                        lib.showTextUI('[E] Unload cargo')
                        if IsControlJustReleased(0, 38) then
                            lib.hideTextUI()
                            if doProgress(locale('progress_unload'), Config.Economy.unloadDuration) then
                                if not JobTruckReady() then
                                    Notify('notify_need_truck', 'error')
                                else
                                    local body, engine = RigHealth()
                                    local result = lib.callback.await('djfivem_trucking:complete', false, {
                                        integrity = delivery.integrity,
                                        body = body,
                                        engine = engine,
                                        mileage = math.floor((delivery.distance or 0) / 1000),
                                        raining = (GetRainLevel and GetRainLevel() or 0) > 0.15,
                                    })
                                    if result and result.ok and result.result then
                                        local pay = result.result
                                        Notify('notify_complete', 'success', pay.payout, pay.xp)
                                        if pay.depositKept then
                                            Notify('notify_rental_kept', 'error')
                                        elseif pay.deposit and pay.deposit > 0 then
                                            Notify('notify_rental_back', 'success', pay.deposit)
                                        end
                                        EndDelivery(delivery.kind == 'quick')
                                    else
                                        Notify(result and result.error or 'notify_invalid', 'error')
                                    end
                                end
                            end
                        end
                    end
                elseif lib.isTextUIOpen() then
                    lib.hideTextUI()
                end
            elseif lib.isTextUIOpen() then
                lib.hideTextUI()
            end
            Wait(0)
        else
            Wait(800)
        end
    end
end)

CreateThread(function()
    while true do
        if delivery and delivery.speedSoftCap and delivery.speedSoftCap > 0 and PlayerInJobTruck() then
            local speed = GetEntitySpeed(GetSpawnedRig().truck or 0) * 2.236936
            if speed > delivery.speedSoftCap then
                delivery.integrity = math.max(8, (delivery.integrity or 100) - 0.08)
            end
            Wait(500)
        else
            Wait(1500)
        end
    end
end)

lib.addKeybind({
    name = 'djfivem_trucking_cancel',
    description = 'Cancel current DJ Logistics haul',
    defaultKey = '',
    onPressed = function()
        if not delivery then return end
        CancelHaul(false)
    end,
})

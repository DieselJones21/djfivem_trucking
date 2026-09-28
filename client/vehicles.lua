local spawned = {}

local function headingOf(coords)
    return (coords.w or coords.heading or coords[4] or 0.0) + 0.0
end

local function xyz(coords)
    return (coords.x or coords[1]) + 0.0, (coords.y or coords[2]) + 0.0, (coords.z or coords[3] or 0.0) + 0.0
end

local function loadModel(name)
    local hash = type(name) == 'number' and name or joaat(name)
    if hash == 0 then return nil end
    if not IsModelInCdimage(hash) and not IsModelValid(hash) then
        return nil
    end
    lib.requestModel(hash, 10000)
    if not HasModelLoaded(hash) then
        return nil
    end
    return hash
end

local function keepVehicle(veh)
    if not veh or veh == 0 or not DoesEntityExist(veh) then return end
    SetEntityAsMissionEntity(veh, true, true)
    SetVehicleHasBeenOwnedByPlayer(veh, true)
    SetVehicleNeedsToBeHotwired(veh, false)
    SetVehicleAutoRepairDisabled(veh, true)
    SetEntityLoadCollisionFlag(veh, true)
    pcall(function()
        SetEntityCleanupByEngine(veh, false)
    end)
    pcall(function()
        SetEntityOrphanMode(veh, 2)
    end)
    pcall(function()
        if not NetworkGetEntityIsNetworked(veh) then
            NetworkRegisterEntityAsNetworked(veh)
        end
    end)
    local netId = NetworkGetNetworkIdFromEntity(veh)
    if netId and netId ~= 0 then
        SetNetworkIdExistsOnAllMachines(netId, true)
        -- Allow OneSync to migrate ownership to the driver. Locking
        -- migration is a common reason a just-spawned truck vanishes.
        SetNetworkIdCanMigrate(netId, true)
    end
end

function CreateJobVehicle(modelName, coords)
    if not coords then return nil end
    local hash = loadModel(modelName)
    if not hash then return nil end

    local x, y, spawnZ = xyz(coords)
    local w = headingOf(coords)
    -- Sit slightly above the configured pad so we do not spawn inside
    -- dock collision, then snap back if ground-place drops us through.
    local z = spawnZ + 0.35

    RequestCollisionAtCoord(x, y, spawnZ)
    local colUntil = GetGameTimer() + 1200
    while GetGameTimer() < colUntil do
        RequestCollisionAtCoord(x, y, spawnZ)
        Wait(0)
        if HasCollisionLoadedAroundEntity(cache.ped) then
            break
        end
    end

    -- isNetwork true, netMissionEntity false: mission-entity-on-create
    -- is tied to the calling thread (NUI callbacks) and gets deleted
    -- when that thread finishes. We promote it ourselves after spawn.
    local veh = CreateVehicle(hash, x, y, z, w, true, false)
    if not veh or veh == 0 or not DoesEntityExist(veh) then
        SetModelAsNoLongerNeeded(hash)
        return nil
    end

    keepVehicle(veh)
    SetEntityCoordsNoOffset(veh, x, y, z, false, false, false)
    SetEntityHeading(veh, w)
    FreezeEntityPosition(veh, true)
    SetVehicleEngineOn(veh, false, true, false)

    local deadline = GetGameTimer() + 2500
    while not HasCollisionLoadedAroundEntity(veh) and GetGameTimer() < deadline do
        RequestCollisionAtCoord(x, y, spawnZ)
        Wait(0)
    end

    SetVehicleOnGroundProperly(veh)
    Wait(120)
    if not DoesEntityExist(veh) then
        SetModelAsNoLongerNeeded(hash)
        return nil
    end

    local placed = GetEntityCoords(veh)
    if placed.z < (spawnZ - 2.5) or placed.z > (spawnZ + 8.0) then
        SetEntityCoordsNoOffset(veh, x, y, spawnZ + 0.6, false, false, false)
        SetEntityHeading(veh, w)
    end

    Wait(80)
    if not DoesEntityExist(veh) then
        SetModelAsNoLongerNeeded(hash)
        return nil
    end

    FreezeEntityPosition(veh, false)
    SetVehicleEngineOn(veh, true, true, false)
    SetVehicleUndriveable(veh, false)
    SetVehicleDoorsLocked(veh, 1)
    SetVehRadioStation(veh, 'OFF')
    keepVehicle(veh)
    SetModelAsNoLongerNeeded(hash)
    return veh
end

local function plateOf(veh)
    if not veh or not DoesEntityExist(veh) then return '' end
    return (GetVehicleNumberPlateText(veh) or ''):gsub('%s+', '')
end

function GiveLocalKeys(veh)
    if not veh or not DoesEntityExist(veh) then return end
    local netId = NetworkGetNetworkIdFromEntity(veh)
    lib.callback.await('djfivem_trucking:issuedKeys', false, netId, plateOf(veh))
end

function DeleteJobVehicle(veh)
    if not veh or veh == 0 then return end
    if DoesEntityExist(veh) then
        SetEntityAsMissionEntity(veh, true, true)
        DeleteEntity(veh)
        if DoesEntityExist(veh) then
            DeleteVehicle(veh)
        end
    end
end

function SpawnJobRig(job)
    local spawn = job.spawn
    if not spawn or not spawn.truck then
        return nil
    end

    local model = job.owned and job.owned.model or (job.truck and job.truck.model)
    local truck = CreateJobVehicle(model, spawn.truck)
    if not truck then
        Notify('notify_spawn_fail', 'error', model or 'truck')
        return nil
    end

    if job.owned and job.owned.plate then
        SetVehicleNumberPlateText(truck, job.owned.plate)
    end
    if job.owned then
        SetVehicleBodyHealth(truck, job.owned.body or 1000.0)
        SetVehicleEngineHealth(truck, job.owned.engine or 1000.0)
    end

    local trailer
    if type(job.trailer) == 'string' and job.trailer ~= '' then
        Wait(200)
        trailer = CreateJobVehicle(job.trailer, spawn.trailer or spawn.truck)
        if trailer then
            FreezeEntityPosition(truck, true)
            FreezeEntityPosition(trailer, true)
            AttachVehicleToTrailer(truck, trailer, 20.0)
            Wait(100)
            FreezeEntityPosition(trailer, false)
            FreezeEntityPosition(truck, false)
        end
    end

    keepVehicle(truck)
    TaskWarpPedIntoVehicle(cache.ped, truck, -1)
    local warpUntil = GetGameTimer() + 1500
    while GetVehiclePedIsIn(cache.ped, false) ~= truck and GetGameTimer() < warpUntil do
        TaskWarpPedIntoVehicle(cache.ped, truck, -1)
        Wait(50)
    end

    if not DoesEntityExist(truck) then
        Notify('notify_spawn_fail', 'error', model or 'truck')
        DeleteJobVehicle(trailer)
        return nil
    end

    GiveLocalKeys(truck)
    local plate = plateOf(truck)
    local netId = NetworkGetNetworkIdFromEntity(truck)
    lib.callback.await(
        'djfivem_trucking:registerVehicle',
        false,
        netId,
        plate,
        trailer and NetworkGetNetworkIdFromEntity(trailer) or nil
    )

    spawned.truck = truck
    spawned.trailer = trailer
    spawned.plate = plate
    spawned.netId = netId
    spawned.ownedId = job.owned and job.owned.id
    spawned.model = model
    return truck, trailer, plate
end

function SpawnOwnedTruck(payload)
    if not payload or not payload.spawn then return end
    local truck = CreateJobVehicle(payload.truck.model, payload.spawn)
    if not truck then
        Notify('notify_spawn_fail', 'error', payload.truck.model)
        return
    end
    SetVehicleNumberPlateText(truck, payload.row.plate)
    SetVehicleBodyHealth(truck, payload.row.body or 1000.0)
    SetVehicleEngineHealth(truck, payload.row.engine or 1000.0)
    TaskWarpPedIntoVehicle(cache.ped, truck, -1)
    GiveLocalKeys(truck)
    spawned.truck = truck
    spawned.ownedId = payload.row.id
    spawned.plate = payload.row.plate
    spawned.model = payload.truck.model
    Notify('notify_spawned', 'success', payload.truck.label)
end

function GetSpawnedRig()
    return spawned
end

function JobTruckReady()
    local truck = spawned.truck
    if not truck or not DoesEntityExist(truck) then
        return false
    end
    if GetVehiclePedIsIn(cache.ped, false) == truck then
        return true
    end
    return #(GetEntityCoords(cache.ped) - GetEntityCoords(truck)) <= 8.0
end

function ClearSpawnedRig(delete)
    if delete then
        DeleteJobVehicle(spawned.trailer)
        DeleteJobVehicle(spawned.truck)
    elseif spawned.ownedId and spawned.truck and DoesEntityExist(spawned.truck) then
        local body = GetVehicleBodyHealth(spawned.truck)
        local engine = GetVehicleEngineHealth(spawned.truck)
        lib.callback.await('djfivem_trucking:storeTruck', false, spawned.ownedId, body, engine, 0)
        DeleteJobVehicle(spawned.truck)
        DeleteJobVehicle(spawned.trailer)
    end
    spawned = {}
end

function RigHealth()
    local truck = spawned.truck
    if not truck or not DoesEntityExist(truck) then
        return 1000.0, 1000.0
    end
    return GetVehicleBodyHealth(truck), GetVehicleEngineHealth(truck)
end

function PlayerInJobTruck()
    local truck = spawned.truck
    if not truck or not DoesEntityExist(truck) then return false end
    return GetVehiclePedIsIn(cache.ped, false) == truck
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    ClearSpawnedRig(true)
end)

local spawned = {}

local function loadModel(name)
    local hash = type(name) == 'number' and name or joaat(name)
    if not IsModelInCdimage(hash) then
        return nil
    end
    lib.requestModel(hash, 8000)
    if not HasModelLoaded(hash) then
        return nil
    end
    return hash
end

local function createVehicle(modelName, coords)
    local hash = loadModel(modelName)
    if not hash then
        return nil
    end
    local veh = CreateVehicle(hash, coords.x, coords.y, coords.z, coords.w or 0.0, true, false)
    if not veh or veh == 0 then
        SetModelAsNoLongerNeeded(hash)
        return nil
    end
    SetVehicleOnGroundProperly(veh)
    SetVehicleHasBeenOwnedByPlayer(veh, true)
    SetVehicleNeedsToBeHotwired(veh, false)
    SetVehicleEngineOn(veh, true, true, false)
    SetEntityAsMissionEntity(veh, true, true)
    SetModelAsNoLongerNeeded(hash)
    return veh
end

local function plateOf(veh)
    return GetVehicleNumberPlateText(veh):gsub('%s+', '')
end

function GiveLocalKeys(veh)
    local netId = NetworkGetNetworkIdFromEntity(veh)
    local plate = plateOf(veh)
    lib.callback.await('djfivem_trucking:issuedKeys', false, netId, plate)
end

function DeleteJobVehicle(veh)
    if veh and DoesEntityExist(veh) then
        DeleteEntity(veh)
    end
end

function SpawnJobRig(job)
    local spawn = job.spawn
    if not spawn or not spawn.truck then
        return nil
    end

    local model = job.owned and job.owned.model or job.truck.model
    local truck = createVehicle(model, spawn.truck)
    if not truck then
        Notify('notify_spawn_fail', 'error')
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
    if job.trailer then
        trailer = createVehicle(job.trailer, spawn.trailer or spawn.truck)
        if trailer then
            AttachVehicleToTrailer(truck, trailer, 12.0)
        end
    end

    TaskWarpPedIntoVehicle(cache.ped, truck, -1)
    GiveLocalKeys(truck)

    local plate = plateOf(truck)
    lib.callback.await('djfivem_trucking:registerVehicle', false, NetworkGetNetworkIdFromEntity(truck), plate, trailer and NetworkGetNetworkIdFromEntity(trailer) or nil)

    spawned.truck = truck
    spawned.trailer = trailer
    spawned.plate = plate
    spawned.ownedId = job.owned and job.owned.id
    return truck, trailer, plate
end

function SpawnOwnedTruck(payload)
    if not payload or not payload.spawn then return end
    local truck = createVehicle(payload.truck.model, payload.spawn)
    if not truck then
        Notify('notify_spawn_fail', 'error')
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
    Notify('notify_spawned', 'success', payload.truck.label)
end

function GetSpawnedRig()
    return spawned
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

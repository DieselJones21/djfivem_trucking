lib.locale()

local depotPeds = {}
local depotBlips = {}
local tabletOpen = false

function Notify(key, nType, ...)
    lib.notify({
        title = Config.Brand.title,
        description = locale(key, ...),
        type = nType or 'inform',
    })
end

function NuiCall(name, data)
    SendNUIMessage({ action = name, data = data or {} })
end

function IsTabletOpen()
    return tabletOpen
end

function SetTabletOpen(state)
    tabletOpen = state == true
end

local function waitForInteract()
    if GetResourceState('interact') == 'started' then
        return true
    end
    local started = pcall(function()
        lib.waitFor(function()
            return GetResourceState('interact') == 'started' or nil
        end, 'interact resource is not started', 8000)
    end)
    return started and GetResourceState('interact') == 'started'
end

local function addInteract(entity, depot)
    local id = 'djfivem_trucking_' .. depot.id
    pcall(function()
        exports.interact:RemoveLocalEntityInteraction(entity, id)
    end)
    exports.interact:AddLocalEntityInteraction({
        entity = entity,
        id = id,
        name = id,
        distance = Config.Interact.distance,
        interactDst = Config.Interact.interactDst,
        offset = Config.Interact.offset,
        options = {
            {
                label = locale('depot_open'),
                action = function()
                    OpenTablet(depot)
                end,
            },
        },
    })
end

local function addPoint(depot)
    local point = lib.points.new({
        coords = depot.pos,
        distance = 24.0,
    })

    function point:nearby()
        if self.currentDistance <= Config.DepotDistance then
            if not IsTabletOpen() then
                lib.showTextUI(locale('textui_depot'))
                if IsControlJustReleased(0, 38) then
                    OpenTablet(depot)
                end
            end
        elseif lib.isTextUIOpen() then
            lib.hideTextUI()
        end
    end

    function point:onExit()
        if lib.isTextUIOpen() then
            lib.hideTextUI()
        end
    end
end

local function keepPed(ped)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return end
    SetEntityAsMissionEntity(ped, true, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    SetPedDiesWhenInjured(ped, false)
    SetPedCanRagdollFromPlayerImpact(ped, false)
    SetPedCanRagdoll(ped, false)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 46, true)
    SetEntityProofs(ped, true, true, true, true, true, true, true, true)
end

local function spawnDepot(depot, index)
    local model = joaat(Config.DepotPed.model)
    lib.requestModel(model)
    -- Local script ped, script-host flag true so the engine does not
    -- treat it as ambient population and despawn it.
    local ped = CreatePed(0, model, depot.coords.x, depot.coords.y, depot.coords.z - 1.0, depot.coords.w, false, true)
    keepPed(ped)
    if Config.DepotPed.scenario then
        TaskStartScenarioInPlace(ped, Config.DepotPed.scenario, 0, true)
    end
    SetModelAsNoLongerNeeded(model)

    local hadPoint = depotPeds[index] and depotPeds[index].point
    depotPeds[index] = { ped = ped, depot = depot, point = hadPoint }

    local useInteract = Config.Target ~= 'ox' and waitForInteract()
    if useInteract then
        addInteract(ped, depot)
    end
    -- Always keep an E fallback. If interact silently drops the option
    -- (entity recycle), the clerk is still usable.
    if not depotPeds[index].point then
        addPoint(depot)
        depotPeds[index].point = true
    end

    if Config.Blips.depot and not depotBlips[index] then
        local blip = AddBlipForCoord(depot.coords.x, depot.coords.y, depot.coords.z)
        SetBlipSprite(blip, Config.Blips.depot.sprite)
        SetBlipColour(blip, Config.Blips.depot.color)
        SetBlipScale(blip, Config.Blips.depot.scale)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(Config.Blips.depot.label)
        EndTextCommandSetBlipName(blip)
        depotBlips[index] = blip
    end
end

CreateThread(function()
    for i = 1, #Config.Depots do
        spawnDepot(Config.Depots[i], i)
        Wait(0)
    end
end)

CreateThread(function()
    while true do
        Wait(5000)
        for i = 1, #Config.Depots do
            local entry = depotPeds[i]
            if not entry or not entry.ped or not DoesEntityExist(entry.ped) then
                spawnDepot(Config.Depots[i], i)
            end
        end
    end
end)

lib.addKeybind({
    name = 'djfivem_trucking_tablet',
    description = locale('keybind_tablet'),
    defaultKey = Config.Command and '' or '',
    onPressed = function()
        -- depot-only tablet; command still works
    end,
})

lib.addCommand(Config.Command, {
    help = 'Open DJ Logistics if you are at a depot',
}, function()
    local coords = GetEntityCoords(cache.ped)
    for i = 1, #Config.Depots do
        local depot = Config.Depots[i]
        if #(coords - depot.pos) <= (Config.DepotDistance + 2.0) then
            OpenTablet(depot)
            return
        end
    end
    Notify('notify_too_far', 'error')
end)

lib.addCommand(Config.CancelCommand, {
    help = 'Cancel the current DJ Logistics haul',
}, function()
    if not IsOnDelivery() then
        -- Server may still have a stuck job even if the client HUD is gone.
        lib.callback.await('djfivem_trucking:cancel', false)
        EndDelivery(true)
        Notify('notify_cancelled', 'inform')
        return
    end
    CancelHaul(false)
end)

RegisterNetEvent('djfivem_trucking:notify', function(description, nType)
    lib.notify({ title = Config.Brand.title, description = description, type = nType or 'inform' })
end)

RegisterNetEvent('djfivem_trucking:partyInvite', function(data)
    local accept = lib.alertDialog({
        header = Config.Brand.title,
        content = locale('notify_party_invite', data.name),
        centered = true,
        cancel = true,
        labels = { confirm = 'Join', cancel = 'Decline' },
    })
    if accept == 'confirm' then
        local result = lib.callback.await('djfivem_trucking:partyJoin', false, data.party)
        if result and result.ok then
            Notify('notify_party_joined', 'success', data.name)
        elseif result and result.error then
            Notify(result.error, 'error')
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for i = 1, #depotPeds do
        local entry = depotPeds[i]
        local ped = type(entry) == 'table' and entry.ped or entry
        if ped and DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
    for i = 1, #depotBlips do
        if depotBlips[i] then
            RemoveBlip(depotBlips[i])
        end
    end
    lib.hideTextUI()
    SetNuiFocus(false, false)
end)

lib.locale()

local officePed
local officeBlip
local officePoint
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

function ReleaseTablet()
    tabletOpen = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
end

local function waitForInteract()
    if GetResourceState('interact') == 'started' then
        return true
    end
    local started = pcall(function()
        lib.waitFor(function()
            return GetResourceState('interact') == 'started' or nil
        end, 'interact resource is not started', 2500)
    end)
    return started and GetResourceState('interact') == 'started'
end

local function addInteract(entity, depot)
    local id = 'djfivem_trucking_hq'
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
    if officePoint then return end
    officePoint = lib.points.new({
        coords = depot.pos,
        distance = 24.0,
    })

    function officePoint:nearby()
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

    function officePoint:onExit()
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
    SetPedCanRagdoll(ped, false)
    SetPedFleeAttributes(ped, 0, false)
end

local function spawnOffice()
    local depot = Config.GetHq()
    if not depot then return end
    if officePed and DoesEntityExist(officePed) then return end

    local model = joaat(Config.DepotPed.model)
    lib.requestModel(model)
    if not HasModelLoaded(model) then return end

    local ped = CreatePed(0, model, depot.coords.x, depot.coords.y, depot.coords.z - 1.0, depot.coords.w, false, true)
    keepPed(ped)
    if Config.DepotPed.scenario then
        TaskStartScenarioInPlace(ped, Config.DepotPed.scenario, 0, true)
    end
    SetModelAsNoLongerNeeded(model)
    officePed = ped

    if Config.Target ~= 'ox' and waitForInteract() then
        addInteract(ped, depot)
    else
        addPoint(depot)
    end

    if Config.Blips.depot and not officeBlip then
        local blip = AddBlipForCoord(depot.coords.x, depot.coords.y, depot.coords.z)
        SetBlipSprite(blip, Config.Blips.depot.sprite)
        SetBlipColour(blip, Config.Blips.depot.color)
        SetBlipScale(blip, Config.Blips.depot.scale)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(Config.Blips.depot.label)
        EndTextCommandSetBlipName(blip)
        officeBlip = blip
    end
end

CreateThread(function()
    spawnOffice()
end)

CreateThread(function()
    while true do
        Wait(8000)
        spawnOffice()
    end
end)

CreateThread(function()
    while true do
        if tabletOpen then
            DisableControlAction(0, 200, true)
            DisableControlAction(0, 199, true)
        end
        Wait(0)
    end
end)

lib.addCommand(Config.Command, {
    help = 'Open DJ Logistics at HQ',
}, function()
    local hq = Config.GetHq()
    if not hq then return end
    local coords = GetEntityCoords(cache.ped)
    if #(coords - hq.pos) <= (Config.DepotDistance + 2.0) then
        OpenTablet(hq)
        return
    end
    Notify('notify_too_far', 'error')
end)

lib.addCommand(Config.CancelCommand, {
    help = 'Cancel the current DJ Logistics haul',
}, function()
    if not IsOnDelivery() then
        lib.callback.await('djfivem_trucking:cancel', false)
        EndDelivery(true)
        Notify('notify_cancelled', 'inform')
        return
    end
    CancelHaul(true)
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
    if officePed and DoesEntityExist(officePed) then
        DeleteEntity(officePed)
    end
    if officeBlip then
        RemoveBlip(officeBlip)
    end
    lib.hideTextUI()
    ReleaseTablet()
end)

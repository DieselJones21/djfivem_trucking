--[[
    DJ FiveM Trucking — editable framework layer
    Hook money, identifiers, notifications, and vehicle keys here.
    Qbox + qbx_vehiclekeys is first-class. QBCore and ESX still work.
]]

Framework = {}

local actionStamp = {}
local detected
local ESX
local QBCore

local function detectFramework()
    if Config.Framework ~= 'auto' then
        return Config.Framework
    end
    if GetResourceState('qbx_core') == 'started' then
        return 'qbx'
    end
    if GetResourceState('qb-core') == 'started' then
        return 'qb'
    end
    if GetResourceState('es_extended') == 'started' then
        return 'esx'
    end
    return 'ox'
end

local function ensureFramework()
    if detected then return detected end
    detected = detectFramework()
    if detected == 'esx' then
        ESX = exports['es_extended']:getSharedObject()
    elseif detected == 'qb' then
        QBCore = exports['qb-core']:GetCoreObject()
    end
    return detected
end

local function moneyMethod()
    if Config.Money.method == 'item' then return 'item' end
    if Config.Money.method == 'framework' then return 'framework' end
    local fw = ensureFramework()
    if fw == 'esx' or fw == 'qb' or fw == 'qbx' then
        return 'framework'
    end
    return 'item'
end

local function getEsxPlayer(src)
    ensureFramework()
    return ESX and ESX.GetPlayerFromId(src) or nil
end

local function getQbPlayer(src)
    local fw = ensureFramework()
    if fw == 'qbx' then
        return exports.qbx_core:GetPlayer(src)
    end
    if fw == 'qb' then
        if not QBCore then
            QBCore = exports['qb-core']:GetCoreObject()
        end
        return QBCore.Functions.GetPlayer(src)
    end
end

function Framework.Id()
    return ensureFramework()
end

function Framework.RateLimit(src, key, wait)
    wait = wait or 0.4
    local now = os.clock()
    local bucket = actionStamp[src]
    if not bucket then
        bucket = {}
        actionStamp[src] = bucket
    end
    local last = bucket[key]
    if last and (now - last) < wait then
        return false
    end
    bucket[key] = now
    return true
end

function Framework.ClearRate(src)
    actionStamp[src] = nil
end

AddEventHandler('playerDropped', function()
    actionStamp[source] = nil
end)

function Framework.GetPlayer(src)
    local fw = ensureFramework()
    if fw == 'esx' then
        return getEsxPlayer(src)
    end
    if fw == 'qb' or fw == 'qbx' then
        return getQbPlayer(src)
    end
end

function Framework.GetPlayerName(src)
    local fw = ensureFramework()
    if fw == 'esx' then
        local player = getEsxPlayer(src)
        if player then return player.getName() end
    elseif fw == 'qb' or fw == 'qbx' then
        local player = getQbPlayer(src)
        if player and player.PlayerData and player.PlayerData.charinfo then
            local info = player.PlayerData.charinfo
            local name = ((info.firstname or '') .. ' ' .. (info.lastname or '')):gsub('^%s+', ''):gsub('%s+$', '')
            if name ~= '' then return name end
        end
    end
    return GetPlayerName(src) or ('ID ' .. src)
end

function Framework.GetCitizenId(src)
    local fw = ensureFramework()
    if fw == 'qb' or fw == 'qbx' then
        local player = getQbPlayer(src)
        if player and player.PlayerData and player.PlayerData.citizenid then
            return player.PlayerData.citizenid
        end
    end
    if fw == 'esx' then
        local player = getEsxPlayer(src)
        if player and player.identifier then
            return player.identifier
        end
    end
    return Framework.GetLicense(src)
end

function Framework.GetLicense(src)
    if GetPlayerIdentifierByType then
        local license = GetPlayerIdentifierByType(src, 'license2') or GetPlayerIdentifierByType(src, 'license')
        if license and license ~= '' then
            return license
        end
    end
    for _, value in ipairs(GetPlayerIdentifiers(src) or {}) do
        if value and value:find('license', 1, true) then
            return value
        end
    end
    return ('name:%s'):format(GetPlayerName(src) or src)
end

function Framework.GetMoney(src, account)
    account = account or Config.Money.account or 'bank'
    if moneyMethod() == 'item' then
        if GetResourceState('ox_inventory') == 'started' then
            return exports.ox_inventory:GetItemCount(src, Config.Money.item) or 0
        end
        return 0
    end

    local fw = ensureFramework()
    if fw == 'esx' then
        local player = getEsxPlayer(src)
        if not player then return 0 end
        if account == 'bank' then
            local data = player.getAccount('bank')
            return data and data.money or 0
        end
        return player.getMoney() or 0
    end

    if fw == 'qb' or fw == 'qbx' then
        local player = getQbPlayer(src)
        if not player then return 0 end
        return player.Functions.GetMoney(account) or 0
    end

    if GetResourceState('ox_inventory') == 'started' then
        return exports.ox_inventory:GetItemCount(src, Config.Money.item) or 0
    end
    return 0
end

function Framework.RemoveMoney(src, amount, reason, account)
    amount = math.floor(amount or 0)
    if amount <= 0 then return true end
    account = account or Config.Money.account or 'bank'
    if Framework.GetMoney(src, account) < amount then
        local other = account == 'bank' and 'cash' or 'bank'
        if Framework.GetMoney(src, other) >= amount then
            account = other
        else
            return false
        end
    end

    if moneyMethod() == 'item' then
        return exports.ox_inventory:RemoveItem(src, Config.Money.item, amount) == true
    end

    local fw = ensureFramework()
    if fw == 'esx' then
        local player = getEsxPlayer(src)
        if not player then return false end
        if account == 'bank' then
            player.removeAccountMoney('bank', amount)
        else
            player.removeMoney(amount)
        end
        return true
    end

    if fw == 'qb' or fw == 'qbx' then
        local player = getQbPlayer(src)
        if not player then return false end
        local removed = player.Functions.RemoveMoney(account, amount, reason or 'djfivem-trucking')
        if removed == false then return false end
        return true
    end

    return exports.ox_inventory:RemoveItem(src, Config.Money.item, amount) == true
end

function Framework.AddMoney(src, amount, reason, account)
    amount = math.floor(amount or 0)
    if amount <= 0 then return true end
    account = account or Config.Money.account or 'bank'

    if moneyMethod() == 'item' then
        return exports.ox_inventory:AddItem(src, Config.Money.item, amount) == true
    end

    local fw = ensureFramework()
    if fw == 'esx' then
        local player = getEsxPlayer(src)
        if not player then return false end
        if account == 'bank' then
            player.addAccountMoney('bank', amount)
        else
            player.addMoney(amount)
        end
        return true
    end

    if fw == 'qb' or fw == 'qbx' then
        local player = getQbPlayer(src)
        if not player then return false end
        player.Functions.AddMoney(account, amount, reason or 'djfivem-trucking')
        return true
    end

    return exports.ox_inventory:AddItem(src, Config.Money.item, amount) == true
end

function Framework.Notify(src, key, nType, ...)
    local description = locale(key, ...)
    if GetResourceState('ox_lib') == 'started' then
        TriggerClientEvent('ox_lib:notify', src, {
            title = Config.Brand.title,
            description = description,
            type = nType or 'inform',
        })
        return
    end
    TriggerClientEvent('djfivem_trucking:notify', src, description, nType or 'inform')
end

function Framework.IsAdmin(src)
    if IsPlayerAceAllowed and IsPlayerAceAllowed(src, Config.AdminAce) then
        return true
    end
    if IsPlayerAceAllowed and IsPlayerAceAllowed(src, 'command') then
        return true
    end
    local fw = ensureFramework()
    if fw == 'qbx' then
        return exports.qbx_core:HasPermission(src, 'admin') == true
            or exports.qbx_core:HasGroup(src, 'admin') == true
    end
    if fw == 'qb' then
        local player = getQbPlayer(src)
        local perm = player and player.PlayerData and player.PlayerData.permission
        return perm == 'admin' or perm == 'god'
    end
    return false
end

----------------------------------------------------------------
-- Vehicle keys — Qbox first
----------------------------------------------------------------
local function keyResource()
    if Config.Keys.resource ~= 'auto' then
        return Config.Keys.resource
    end
    if GetResourceState('qbx_vehiclekeys') == 'started' then
        return 'qbx_vehiclekeys'
    end
    if GetResourceState('qb-vehiclekeys') == 'started' then
        return 'qb-vehiclekeys'
    end
    if GetResourceState('qbx_core') == 'started' then
        return 'qbx_core'
    end
    return 'none'
end

function Framework.GiveKeys(src, vehicle, plate)
    local res = keyResource()
    local skip = Config.Keys.notify == false

    if res == 'qbx_vehiclekeys' and vehicle and vehicle ~= 0 then
        exports.qbx_vehiclekeys:GiveKeys(src, vehicle, skip)
        return true
    end

    if res == 'qb-vehiclekeys' and plate then
        exports['qb-vehiclekeys']:GiveKeys(src, plate)
        TriggerClientEvent('qb-vehiclekeys:client:AddKeys', src, plate)
        return true
    end

    if res == 'qbx_core' and vehicle and vehicle ~= 0 then
        local ok = pcall(function()
            exports.qbx_core:GiveVehicleKey(src, vehicle)
        end)
        if ok then return true end
    end

    if plate then
        TriggerClientEvent('vehiclekeys:client:SetOwner', src, plate)
        TriggerClientEvent('qb-vehiclekeys:client:AddKeys', src, plate)
    end
    return true
end

function Framework.RemoveKeys(src, vehicle, plate)
    local res = keyResource()
    local skip = Config.Keys.notify == false

    if res == 'qbx_vehiclekeys' and vehicle and vehicle ~= 0 then
        exports.qbx_vehiclekeys:RemoveKeys(src, vehicle, skip)
        return true
    end

    if res == 'qb-vehiclekeys' and plate then
        pcall(function()
            exports['qb-vehiclekeys']:RemoveKeys(src, plate)
        end)
        TriggerClientEvent('qb-vehiclekeys:client:RemoveKeys', src, plate)
        return true
    end

    if plate then
        TriggerClientEvent('qb-vehiclekeys:client:RemoveKeys', src, plate)
    end
    return true
end

function Framework.HasKeys(src, vehicle)
    if GetResourceState('qbx_vehiclekeys') == 'started' and vehicle and vehicle ~= 0 then
        return exports.qbx_vehiclekeys:HasKeys(src, vehicle) == true
    end
    return true
end

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    ensureFramework()
    lib.print.info(('DJ Logistics  |  Framework: %s  |  Money: %s  |  Keys: %s'):format(
        ensureFramework(),
        moneyMethod(),
        keyResource()
    ))
end)

Parties = {}

local byPlayer = {}
local parties = {}
local seq = 0

local function coordsOf(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    return GetEntityCoords(ped)
end

local function nearby(a, b, range)
    local ca, cb = coordsOf(a), coordsOf(b)
    if not ca or not cb then return false end
    return #(ca - cb) <= (range or Config.Party.inviteDistance)
end

function Parties.Get(src)
    local id = byPlayer[src]
    return id and parties[id] or nil
end

function Parties.Snapshot(src)
    local party = Parties.Get(src)
    if not party then return nil end
    local members = {}
    for i = 1, #party.members do
        members[i] = party.members[i]
    end
    return { id = party.id, host = party.host, members = members }
end

function Parties.Public(src)
    local party = Parties.Get(src)
    if not party then
        return { active = false, members = {} }
    end
    local members = {}
    for i = 1, #party.members do
        local id = party.members[i]
        members[#members + 1] = {
            id = id,
            name = Framework.GetPlayerName(id),
            host = id == party.host,
            me = id == src,
        }
    end
    return { active = true, id = party.id, host = party.host, members = members }
end

function Parties.Create(src)
    if Parties.Get(src) then
        return Parties.Public(src)
    end
    seq = seq + 1
    local id = seq
    parties[id] = { id = id, host = src, members = { src } }
    byPlayer[src] = id
    Webhooks.Player(src, 'jobs', 'Crew created', {})
    return Parties.Public(src)
end

function Parties.Invite(src, target)
    target = tonumber(target)
    local party = Parties.Get(src) or Parties.Create(src) and Parties.Get(src)
    if not party or party.host ~= src or not target then
        return nil, 'notify_invalid'
    end
    if #party.members >= Config.Party.maxSize then
        return nil, 'notify_party_full'
    end
    if Parties.Get(target) then
        return nil, 'notify_invalid'
    end
    if not nearby(src, target, Config.Party.inviteDistance) then
        return nil, 'notify_too_far'
    end
    TriggerClientEvent('djfivem_trucking:partyInvite', target, {
        host = src,
        name = Framework.GetPlayerName(src),
        party = party.id,
    })
    return { ok = true }
end

function Parties.Join(src, partyId)
    local party = parties[tonumber(partyId)]
    if not party then return nil, 'notify_invalid' end
    if Parties.Get(src) then return nil, 'notify_invalid' end
    if #party.members >= Config.Party.maxSize then
        return nil, 'notify_party_full'
    end
    if not nearby(src, party.host, Config.Party.startDistance) then
        return nil, 'notify_too_far'
    end
    party.members[#party.members + 1] = src
    byPlayer[src] = party.id
    for i = 1, #party.members do
        Framework.Notify(party.members[i], 'notify_party_joined', 'success', Framework.GetPlayerName(src))
    end
    Webhooks.Player(src, 'jobs', 'Joined crew', {
        { name = 'Host', value = Framework.GetPlayerName(party.host), inline = true },
    })
    return Parties.Public(src)
end

function Parties.Leave(src)
    local party = Parties.Get(src)
    if not party then return { active = false } end

    local nextMembers = {}
    for i = 1, #party.members do
        if party.members[i] ~= src then
            nextMembers[#nextMembers + 1] = party.members[i]
        end
    end
    byPlayer[src] = nil

    if #nextMembers == 0 or src == party.host then
        for i = 1, #nextMembers do
            byPlayer[nextMembers[i]] = nil
            Framework.Notify(nextMembers[i], 'notify_party_left', 'inform', Framework.GetPlayerName(src))
        end
        parties[party.id] = nil
    else
        party.members = nextMembers
        for i = 1, #nextMembers do
            Framework.Notify(nextMembers[i], 'notify_party_left', 'inform', Framework.GetPlayerName(src))
        end
    end
    return { active = false }
end

function Parties.Nearby(src)
    local origin = coordsOf(src)
    if not origin then return {} end
    local list = {}
    for _, playerId in ipairs(GetPlayers()) do
        local id = tonumber(playerId)
        if id and id ~= src then
            local pos = coordsOf(id)
            if pos and #(origin - pos) <= Config.Party.inviteDistance then
                list[#list + 1] = { id = id, name = Framework.GetPlayerName(id) }
            end
        end
    end
    return list
end

AddEventHandler('playerDropped', function()
    Parties.Leave(source)
end)

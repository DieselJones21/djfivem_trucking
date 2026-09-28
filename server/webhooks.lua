Webhooks = {}

local queue = {}
local sending = false

local function endpoint(group)
    if not Config.Webhooks.enabled then return end
    local url = Config.Webhooks[group]
    if type(url) == 'string' and url:find('http', 1, true) then
        return url
    end
end

local function flush()
    if sending then return end
    sending = true
    CreateThread(function()
        while queue[1] do
            local item = table.remove(queue, 1)
            PerformHttpRequest(item.url, function() end, 'POST', item.body, {
                ['Content-Type'] = 'application/json',
            })
            Wait(650)
        end
        sending = false
    end)
end

function Webhooks.Send(group, title, fields, extra)
    local url = endpoint(group)
    if not url then return end

    extra = extra or {}
    local embed = {
        title = title,
        color = extra.color or Config.Webhooks.color,
        description = extra.description,
        fields = fields or {},
        footer = { text = Config.Brand.name .. ' · DJ Logistics' },
        timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
    }

    queue[#queue + 1] = {
        url = url,
        body = json.encode({
            username = Config.Webhooks.username,
            embeds = { embed },
        }),
    }
    flush()
end

function Webhooks.Player(src, group, title, fields, extra)
    local name = Framework.GetPlayerName(src)
    local cid = Framework.GetCitizenId(src)
    local list = {
        { name = 'Player', value = ('%s (`%s`)'):format(name, cid), inline = false },
    }
    for i = 1, #(fields or {}) do
        list[#list + 1] = fields[i]
    end
    Webhooks.Send(group, title, list, extra)
end

function Webhooks.Money(src, title, amount, reason)
    Webhooks.Player(src, 'money', title, {
        { name = 'Amount', value = ('$%s'):format(amount), inline = true },
        { name = 'Reason', value = reason or '-', inline = true },
    })
end

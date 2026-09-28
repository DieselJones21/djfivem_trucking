----------------------------------------------------------------
-- Depots and haul lanes
-- ONE clerk ped exists, at Config.HqDepot (Port of LS).
-- Every other entry is only a load / drop-off pad — no ped, no tablet.
----------------------------------------------------------------
Config.HqDepot = Config.HqDepot or 'lsport'

Config.Depots = {
    {
        id = 'lsport',
        label = 'Port of Los Santos',
        subtitle = 'DJ Logistics HQ',
        office = true,
        coords = vec4(1200.42, -3114.18, 5.54, 0.4),
        truck = vec4(1182.16, -3098.55, 5.64, 356.0),
        trailer = vec4(1171.40, -3098.80, 5.64, 356.0),
        load = vec3(1194.20, -3108.40, 5.80),
    },
    {
        id = 'lamesa',
        label = 'La Mesa Yard',
        subtitle = 'Popular Street',
        coords = vec4(875.18, -2493.66, 28.33, 175.0),
        truck = vec4(858.44, -2494.90, 28.12, 175.0),
        trailer = vec4(848.10, -2496.20, 28.10, 175.0),
        load = vec3(868.20, -2494.10, 28.40),
    },
    {
        id = 'lsia',
        label = 'LSIA Cargo',
        subtitle = 'New Empire Way',
        coords = vec4(-1070.55, -2013.42, 13.16, 135.0),
        truck = vec4(-1058.80, -2024.10, 13.16, 135.0),
        trailer = vec4(-1048.40, -2033.60, 13.16, 135.0),
        load = vec3(-1064.20, -2018.80, 13.30),
    },
    {
        id = 'elburro',
        label = 'El Burro Depot',
        subtitle = 'Oil Fields',
        coords = vec4(1546.22, -2115.84, 77.22, 0.0),
        truck = vec4(1558.40, -2112.20, 77.20, 0.0),
        trailer = vec4(1570.10, -2112.40, 77.20, 0.0),
        load = vec3(1552.10, -2114.40, 77.40),
    },
    {
        id = 'sandy',
        label = 'Sandy Airfield',
        subtitle = 'Senora Desert',
        coords = vec4(1724.84, 3294.55, 41.16, 195.0),
        truck = vec4(1736.22, 3312.80, 41.22, 195.0),
        trailer = vec4(1748.10, 3324.40, 41.22, 195.0),
        load = vec3(1730.40, 3304.20, 41.30),
    },
    {
        id = 'harmony',
        label = 'Harmony Freight',
        subtitle = 'Route 68',
        coords = vec4(588.42, 2736.18, 42.06, 275.0),
        truck = vec4(602.10, 2736.80, 42.00, 275.0),
        trailer = vec4(614.40, 2737.20, 42.00, 275.0),
        load = vec3(594.80, 2736.40, 42.20),
    },
    {
        id = 'grapeseed',
        label = 'Grapeseed Co-op',
        subtitle = 'Union Rd',
        coords = vec4(2553.18, 4687.05, 33.81, 25.0),
        truck = vec4(2566.40, 4694.20, 33.80, 25.0),
        trailer = vec4(2578.10, 4699.80, 33.80, 25.0),
        load = vec3(2559.40, 4690.40, 34.00),
    },
    {
        id = 'paleto',
        label = 'Paleto Bay Yard',
        subtitle = 'Great Ocean Hwy',
        coords = vec4(152.28, 6402.10, 31.25, 35.0),
        truck = vec4(140.60, 6404.80, 31.20, 35.0),
        trailer = vec4(129.40, 6407.20, 31.20, 35.0),
        load = vec3(146.80, 6403.20, 31.40),
    },
    {
        id = 'humane',
        label = 'Humane Labs Gate',
        subtitle = 'Senora Way',
        coords = vec4(3426.48, 3763.82, 30.60, 25.0),
        truck = vec4(3440.20, 3770.10, 30.55, 25.0),
        trailer = vec4(3452.40, 3776.20, 30.55, 25.0),
        load = vec3(3433.10, 3766.80, 30.80),
    },
    {
        id = 'zancudo',
        label = 'Zancudo Staging',
        subtitle = 'Outside the gates',
        coords = vec4(-2140.52, 3254.18, 32.81, 150.0),
        truck = vec4(-2154.80, 3244.40, 32.81, 150.0),
        trailer = vec4(-2166.20, 3236.80, 32.81, 150.0),
        load = vec3(-2147.20, 3249.40, 33.00),
    },
}

Config.DepotsById = {}
for i = 1, #Config.Depots do
    local depot = Config.Depots[i]
    depot.pos = vec3(depot.coords.x, depot.coords.y, depot.coords.z)
    Config.DepotsById[depot.id] = depot
end

function Config.GetDepot(id)
    return Config.DepotsById[id]
end

function Config.GetHq()
    return Config.GetDepot(Config.HqDepot) or Config.Depots[1]
end

function Config.IsHq(id)
    local hq = Config.GetHq()
    if not hq then return false end
    if type(id) == 'table' then
        return id.id == hq.id
    end
    return id == hq.id
end

function Config.RouteDistance(fromId, toId)
    local a = Config.GetDepot(fromId)
    local b = Config.GetDepot(toId)
    if not a or not b then return 0 end
    return #(a.pos - b.pos)
end

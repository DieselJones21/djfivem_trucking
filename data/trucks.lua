----------------------------------------------------------------
-- Truck catalog
-- model = the spawn code from your stream folder.
-- _hi.yft files are LODs, not extra vehicles.
-- brickades+.ytd is a texture, still spawned as 'brickades'.
--
-- Your pack:
--   linerunner, aerocab, blacktop, brickades, vetirs
-- Mule / Benson stay as cheap vanilla rentals so a new driver
-- can work before the addon pack is started.
----------------------------------------------------------------
Config.Trucks = {
    {
        id = 'mule',
        model = 'mule',
        label = 'Mule Box',
        description = 'Vanilla starter box. Always streams. First rental seat.',
        class = 'box',
        price = 18500,
        rentable = true,
        buyable = true,
        level = 1,
        capacity = 1,
        payout = 1.00,
        cargo = { 'general', 'food' },
        trailer = false,
        addon = false,
    },
    {
        id = 'benson',
        model = 'benson',
        label = 'Benson',
        description = 'Vanilla mid box. Grocery and light machinery.',
        class = 'box',
        price = 42000,
        rentable = true,
        buyable = true,
        level = 3,
        capacity = 1,
        payout = 1.10,
        cargo = { 'general', 'food', 'machinery' },
        trailer = false,
        addon = false,
    },
    {
        id = 'linerunner',
        model = 'linerunner',
        label = 'Linerunner',
        description = 'Addon long-nose. Your first real DJ freight tractor.',
        class = 'heavy',
        price = 135000,
        rentable = true,
        buyable = true,
        level = 4,
        capacity = 2,
        payout = 1.34,
        cargo = { 'general', 'food', 'machinery', 'chemicals' },
        trailer = true,
        addon = true,
    },
    {
        id = 'blacktop',
        model = 'blacktop',
        label = 'Blacktop',
        description = 'Addon heavy. Built for plant, asphalt, and yard work.',
        class = 'heavy',
        price = 168000,
        rentable = false,
        buyable = true,
        level = 6,
        capacity = 2,
        payout = 1.40,
        cargo = { 'general', 'machinery', 'chemicals' },
        trailer = true,
        addon = true,
    },
    {
        id = 'aerocab',
        model = 'aerocab',
        label = 'Aerocab',
        description = 'Addon sleeper cab. Long-haul money and fuel lanes.',
        class = 'heavy',
        price = 195000,
        rentable = true,
        buyable = true,
        level = 8,
        capacity = 2,
        payout = 1.46,
        cargo = { 'general', 'food', 'machinery', 'chemicals', 'fuel' },
        trailer = true,
        addon = true,
    },
    {
        id = 'vetirs',
        model = 'vetirs',
        label = 'Vetir',
        description = 'Addon 6x6. Off-road and hazmat. No fifth-wheel needed.',
        class = 'offroad',
        price = 220000,
        rentable = false,
        buyable = true,
        level = 10,
        capacity = 1,
        payout = 1.42,
        cargo = { 'machinery', 'chemicals', 'fuel' },
        trailer = false,
        addon = true,
    },
    {
        id = 'brickades',
        model = 'brickades',
        label = 'Brickade',
        description = 'Addon armored yard truck. Highest ticket. High-value ready.',
        class = 'armored',
        price = 265000,
        rentable = false,
        buyable = true,
        level = 12,
        capacity = 1,
        payout = 1.55,
        cargo = { 'general', 'machinery', 'chemicals', 'fuel', 'valuables' },
        trailer = false,
        addon = true,
    },
}

Config.Trailers = {
    general = 'trailers2',
    food = 'trailers3',
    machinery = 'tr2',
    chemicals = 'tanker2',
    fuel = 'tanker',
    valuables = 'tvtrailer',
    logging = 'trailerlogs',
}

function Config.GetTruck(id)
    for i = 1, #Config.Trucks do
        if Config.Trucks[i].id == id then
            return Config.Trucks[i]
        end
    end
end

function Config.TrucksForCargo(cargoId, ownedOnly)
    local list = {}
    for i = 1, #Config.Trucks do
        local truck = Config.Trucks[i]
        local okCargo = false
        for c = 1, #truck.cargo do
            if truck.cargo[c] == cargoId then
                okCargo = true
                break
            end
        end
        if okCargo and (not ownedOnly or truck.buyable) then
            list[#list + 1] = truck
        end
    end
    return list
end

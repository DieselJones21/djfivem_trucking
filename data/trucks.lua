----------------------------------------------------------------
-- Truck catalog
-- model = the spawn code. Swap these for your addon pack.
-- class: light | box | heavy | tanker | logging | carhauler
-- owned trucks can run freight jobs. rentals are listed per class.
----------------------------------------------------------------
Config.Trucks = {
    {
        id = 'mule',
        model = 'mule',
        label = 'Mule Box',
        description = 'Light rental box truck. Perfect first seat for quick jobs.',
        class = 'box',
        price = 18500,
        rentable = true,
        buyable = true,
        level = 1,
        capacity = 1,
        payout = 1.00,
        cargo = { 'general', 'food' },
        trailer = false,
        image = 'truck',
    },
    {
        id = 'mule3',
        model = 'mule3',
        label = 'Mule 3',
        description = 'Newer box truck with a cleaner ride and slightly better payout.',
        class = 'box',
        price = 24500,
        rentable = true,
        buyable = true,
        level = 2,
        capacity = 1,
        payout = 1.06,
        cargo = { 'general', 'food' },
        trailer = false,
        image = 'truck',
    },
    {
        id = 'benson',
        model = 'benson',
        label = 'Benson',
        description = 'Mid-size box. Handles grocery and general freight cleanly.',
        class = 'box',
        price = 42000,
        rentable = true,
        buyable = true,
        level = 3,
        capacity = 1,
        payout = 1.12,
        cargo = { 'general', 'food', 'machinery' },
        trailer = false,
        image = 'truck',
    },
    {
        id = 'pounder',
        model = 'pounder',
        label = 'Pounder',
        description = 'Heavy box. Better money, harder to place in tight yards.',
        class = 'box',
        price = 68000,
        rentable = false,
        buyable = true,
        level = 5,
        capacity = 1,
        payout = 1.20,
        cargo = { 'general', 'food', 'machinery' },
        trailer = false,
        image = 'truck',
    },
    {
        id = 'pounder2',
        model = 'pounder2',
        label = 'Pounder Custom',
        description = 'Boxed heavy with a stronger payout for long grocery runs.',
        class = 'box',
        price = 88000,
        rentable = false,
        buyable = true,
        level = 7,
        capacity = 1,
        payout = 1.26,
        cargo = { 'general', 'food', 'machinery' },
        trailer = false,
        image = 'truck',
    },
    {
        id = 'phantom',
        model = 'phantom',
        label = 'Phantom',
        description = 'Day-cab tractor. Your first real freight investment.',
        class = 'heavy',
        price = 125000,
        rentable = true,
        buyable = true,
        level = 4,
        capacity = 2,
        payout = 1.32,
        cargo = { 'general', 'food', 'machinery', 'chemicals' },
        trailer = true,
        image = 'semi',
    },
    {
        id = 'phantom3',
        model = 'phantom3',
        label = 'Phantom Custom',
        description = 'Sleeper-style Phantom. Preferred for chemicals and long hauls.',
        class = 'heavy',
        price = 165000,
        rentable = false,
        buyable = true,
        level = 8,
        capacity = 2,
        payout = 1.40,
        cargo = { 'general', 'food', 'machinery', 'chemicals', 'fuel' },
        trailer = true,
        image = 'semi',
    },
    {
        id = 'hauler',
        model = 'hauler',
        label = 'Hauler',
        description = 'Classic long-nose. Strong on machinery and logging.',
        class = 'heavy',
        price = 145000,
        rentable = true,
        buyable = true,
        level = 6,
        capacity = 2,
        payout = 1.36,
        cargo = { 'general', 'machinery', 'chemicals' },
        trailer = true,
        image = 'semi',
    },
    {
        id = 'hauler2',
        model = 'hauler2',
        label = 'Hauler Custom',
        description = 'Lifted heavy hauler. Highest standard freight multiplier.',
        class = 'heavy',
        price = 210000,
        rentable = false,
        buyable = true,
        level = 10,
        capacity = 2,
        payout = 1.48,
        cargo = { 'general', 'machinery', 'chemicals', 'fuel', 'valuables' },
        trailer = true,
        image = 'semi',
    },
    {
        id = 'packer',
        model = 'packer',
        label = 'Packer',
        description = 'Cab-over tractor. Compact yard truck for tanker work.',
        class = 'tanker',
        price = 138000,
        rentable = true,
        buyable = true,
        level = 8,
        capacity = 2,
        payout = 1.38,
        cargo = { 'chemicals', 'fuel' },
        trailer = true,
        image = 'semi',
    },
    {
        id = 'mixer2',
        model = 'mixer2',
        label = 'Mixer',
        description = 'Specialized mixer. Construction and machinery contracts only.',
        class = 'machinery',
        price = 72000,
        rentable = false,
        buyable = true,
        level = 5,
        capacity = 1,
        payout = 1.22,
        cargo = { 'machinery' },
        trailer = false,
        image = 'truck',
    },
}

--[[
    ADDON TRUCKS
    Copy a block above and change model to your spawn code.

    {
        id = 'pete389',
        model = 'pete389',          -- << your spawn code
        label = 'Peterbilt 389',
        description = 'Custom long-nose. Put your livery pack here.',
        class = 'heavy',
        price = 285000,
        rentable = false,
        buyable = true,
        level = 12,
        capacity = 2,
        payout = 1.55,
        cargo = { 'general', 'machinery', 'chemicals', 'fuel', 'valuables' },
        trailer = true,
        image = 'semi',
    },

    Common addon names people drop in:
    - l1024, w900, pete389, kwt680, volvo780, scania, actros, man
    Keep id unique. model must match the streaming folder spawn name.
]]

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

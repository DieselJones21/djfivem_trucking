----------------------------------------------------------------
-- Cargo classes
-- Players start on general freight and unlock certifications
-- as they level / spend skill points.
----------------------------------------------------------------
Config.Cargo = {
    general = {
        id = 'general',
        label = 'General Freight',
        description = 'Pallets, parcels, and dry goods. No special ticket required.',
        cert = 'general',
        payPerKm = 42,
        xpPerKm = 1.15,
        integrityLoss = 0.35,   -- how hard cargo is dinged by rough driving
        speedSoftCap = 0,       -- 0 = no cap
        color = '#d5dee6',
        icon = 'box',
        level = 1,
    },
    food = {
        id = 'food',
        label = 'Refrigerated Food',
        description = 'Produce and frozen loads. Keep the box intact.',
        cert = 'food',
        payPerKm = 54,
        xpPerKm = 1.30,
        integrityLoss = 0.55,
        speedSoftCap = 0,
        color = '#7ef6a0',
        icon = 'food',
        level = 2,
    },
    machinery = {
        id = 'machinery',
        label = 'Machinery',
        description = 'Plant, engines, and construction gear. Heavy and awkward.',
        cert = 'machinery',
        payPerKm = 68,
        xpPerKm = 1.45,
        integrityLoss = 0.70,
        speedSoftCap = 0,
        color = '#9fd0ff',
        icon = 'gear',
        level = 4,
    },
    chemicals = {
        id = 'chemicals',
        label = 'Chemicals',
        description = 'Industrial totes. Requires a hazmat certification.',
        cert = 'chemicals',
        payPerKm = 84,
        xpPerKm = 1.65,
        integrityLoss = 0.90,
        speedSoftCap = 95,
        color = '#c9f07e',
        icon = 'flask',
        level = 6,
    },
    fuel = {
        id = 'fuel',
        label = 'Flammable Liquids',
        description = 'Fuel oil and petrol. Certification required. Drive smooth.',
        cert = 'fuel',
        payPerKm = 102,
        xpPerKm = 1.85,
        integrityLoss = 1.15,
        speedSoftCap = 85,
        color = '#ff4d1c',
        icon = 'fuel',
        level = 8,
    },
    valuables = {
        id = 'valuables',
        label = 'High-Value Cargo',
        description = 'Jewelry, art, and secured freight. Highest ticket in the book.',
        cert = 'valuables',
        payPerKm = 128,
        xpPerKm = 2.10,
        integrityLoss = 1.35,
        speedSoftCap = 90,
        color = '#e8c36a',
        icon = 'gem',
        level = 10,
    },
}

Config.CargoOrder = { 'general', 'food', 'machinery', 'chemicals', 'fuel', 'valuables' }

function Config.GetCargo(id)
    return Config.Cargo[id]
end

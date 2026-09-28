----------------------------------------------------------------
-- NPC driver roster
-- These are simulated employees — they do not wander the map.
-- They tick on a timer and deposit into the company account.
----------------------------------------------------------------
Config.Employees = {
    {
        id = 'ray',
        name = 'Ray Campos',
        title = 'Day Cab Rookie',
        description = 'Cheap, reliable, slow. Good first hire.',
        wage = 220,
        skill = 1,
        cargo = { 'general', 'food' },
        hireLevel = 4,
        hirePrice = 1500,
    },
    {
        id = 'lena',
        name = 'Lena Ortiz',
        title = 'Reefer Driver',
        description = 'Keeps the box cold. Strong on grocery lanes.',
        wage = 340,
        skill = 2,
        cargo = { 'general', 'food' },
        hireLevel = 6,
        hirePrice = 2800,
    },
    {
        id = 'dmitri',
        name = 'Dmitri Hale',
        title = 'Heavy Hauler',
        description = 'Plant and machinery specialist.',
        wage = 480,
        skill = 3,
        cargo = { 'machinery', 'general' },
        hireLevel = 8,
        hirePrice = 4200,
    },
    {
        id = 'amina',
        name = 'Amina Cole',
        title = 'Hazmat Lead',
        description = 'Licensed for chemicals. Tight on incidents.',
        wage = 620,
        skill = 4,
        cargo = { 'chemicals', 'machinery' },
        hireLevel = 10,
        hirePrice = 6500,
    },
    {
        id = 'jonas',
        name = 'Jonas Reed',
        title = 'Tanker Ace',
        description = 'Fuel lanes only. Highest base take, highest wage.',
        wage = 780,
        skill = 5,
        cargo = { 'fuel', 'chemicals' },
        hireLevel = 12,
        hirePrice = 8800,
    },
    {
        id = 'suki',
        name = 'Suki Tran',
        title = 'Bonded Courier',
        description = 'High-value specialist. Quiet and expensive.',
        wage = 940,
        skill = 5,
        cargo = { 'valuables', 'food' },
        hireLevel = 14,
        hirePrice = 12000,
    },
    {
        id = 'marco',
        name = 'Marco Velez',
        title = 'Night Dispatcher',
        description = 'Runs mixed freight after dark. Solid all-rounder.',
        wage = 510,
        skill = 3,
        cargo = { 'general', 'food', 'machinery' },
        hireLevel = 9,
        hirePrice = 5000,
    },
    {
        id = 'priya',
        name = 'Priya Shah',
        title = 'Owner-Op Mentor',
        description = 'Teaches the books. Slightly safer incident rate.',
        wage = 700,
        skill = 4,
        cargo = { 'general', 'machinery', 'chemicals' },
        hireLevel = 11,
        hirePrice = 7600,
        incidentMod = 0.5,
    },
}

function Config.GetEmployeeDef(id)
    for i = 1, #Config.Employees do
        if Config.Employees[i].id == id then
            return Config.Employees[i]
        end
    end
end

Company = {}

local function dayKey()
    return os.date('%Y-%m-%d')
end

local function loanProduct(id)
    for i = 1, #Config.Loans.products do
        if Config.Loans.products[i].id == id then
            return Config.Loans.products[i]
        end
    end
end

function Company.Rename(src, name)
    name = tostring(name or ''):gsub('^%s+', ''):gsub('%s+$', '')
    if #name < 3 or #name > 32 then
        return nil, 'notify_invalid'
    end
    if not Framework.RemoveMoney(src, Config.Company.renamePrice, 'trucking-rename') then
        return nil, 'notify_no_money'
    end
    local profile = Profile.Get(src)
    profile.company_name = name
    profile.dirty = true
    Profile.Save(src)
    Webhooks.Player(src, 'company', 'Company renamed', {
        { name = 'Name', value = name, inline = true },
    })
    return { name = name }
end

function Company.Deposit(src, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount < 50 then return nil, 'notify_invalid' end
    if not Framework.RemoveMoney(src, amount, 'trucking-company-deposit') then
        return nil, 'notify_no_money'
    end
    Profile.AddCompany(src, amount)
    Profile.Save(src)
    Webhooks.Money(src, 'Company deposit', amount, 'company')
    return { balance = Profile.Get(src).company_balance }
end

function Company.Withdraw(src, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount < 50 then return nil, 'notify_invalid' end
    if not Profile.ChargeCompany(src, amount) then
        return nil, 'notify_no_money'
    end
    Framework.AddMoney(src, amount, 'trucking-company-withdraw')
    Profile.Save(src)
    Webhooks.Money(src, 'Company withdraw', amount, 'company')
    return { balance = Profile.Get(src).company_balance }
end

function Company.BuyInsurance(src)
    local profile = Profile.Get(src)
    if profile.insurance == 1 then
        return { already = true }
    end
    if not Framework.RemoveMoney(src, Config.Economy.insurancePrice, 'trucking-insurance') then
        return nil, 'notify_no_money'
    end
    profile.insurance = 1
    profile.dirty = true
    Profile.Save(src)
    Webhooks.Player(src, 'company', 'Insurance purchased', {
        { name = 'Cost', value = ('$%s'):format(Config.Economy.insurancePrice), inline = true },
    })
    return { insurance = true }
end

function Company.DailyContracts(src)
    local profile = Profile.Get(src)
    if not profile then return {} end
    if profile.stats.contractDay == dayKey() and profile.stats.contracts and #profile.stats.contracts > 0 then
        return profile.stats.contracts
    end

    local level = Config.LevelFromXP(profile.xp)
    local pool = {}
    for i = 1, #Config.CargoOrder do
        local cargo = Config.Cargo[Config.CargoOrder[i]]
        if cargo and level >= cargo.level and profile.certs[cargo.cert] then
            pool[#pool + 1] = cargo.id
        end
    end
    if #pool == 0 then pool[1] = 'general' end

    local list = {}
    local used = {}
    for i = 1, Config.Contracts.count do
        local cargoId = pool[((i - 1) % #pool) + 1]
        local dest = Config.Depots[math.random(1, #Config.Depots)]
        local key = cargoId .. dest.id
        if not used[key] then
            used[key] = true
            list[#list + 1] = {
                id = ('c-%s-%s'):format(i, dest.id),
                cargo = cargoId,
                dropoff = dest.id,
                dropoffLabel = dest.label,
                bonus = math.floor((Config.Contracts.bonusPay + Config.SkillRankBonus(profile.skills, 'broker', 'contract')) * 100),
                done = false,
            }
        end
    end
    profile.stats.contractDay = dayKey()
    profile.stats.contracts = list
    profile.dirty = true
    return list
end

function Company.CompleteContract(src, cargo, dropoff)
    local profile = Profile.Get(src)
    if not profile or not profile.stats.contracts then return end
    for i = 1, #profile.stats.contracts do
        local row = profile.stats.contracts[i]
        if row.cargo == cargo and row.dropoff == dropoff and not row.done then
            row.done = true
            profile.dirty = true
            return
        end
    end
end

function Company.Employees(src)
    if not DB.Ready() then return {} end
    return MySQL.query.await(
        'SELECT * FROM dj_trucking_employees WHERE citizenid = ?',
        { Framework.GetCitizenId(src) }
    ) or {}
end

function Company.Roster(src)
    local hired = Company.Employees(src)
    local have = {}
    for i = 1, #hired do
        have[hired[i].employee_id] = hired[i]
    end
    local level = Profile.Level(src)
    local list = {}
    for i = 1, #Config.Employees do
        local def = Config.Employees[i]
        list[#list + 1] = {
            id = def.id,
            name = def.name,
            title = def.title,
            description = def.description,
            wage = def.wage,
            skill = def.skill,
            cargo = def.cargo,
            hireLevel = def.hireLevel,
            hirePrice = def.hirePrice,
            locked = level < def.hireLevel,
            hired = have[def.id] ~= nil,
            status = have[def.id] and have[def.id].status or 'available',
            lifetime = have[def.id] and have[def.id].lifetime or 0,
            rowId = have[def.id] and have[def.id].id or nil,
        }
    end
    return list
end

function Company.Hire(src, employeeId)
    if not Framework.RateLimit(src, 'hire', 1.0) then
        return nil, 'notify_invalid'
    end
    local def = Config.GetEmployeeDef(employeeId)
    if not def then return nil, 'notify_invalid' end
    if Profile.Level(src) < def.hireLevel then
        return nil, 'notify_level'
    end
    local hired = Company.Employees(src)
    if #hired >= Config.Company.maxEmployees then
        return nil, 'notify_invalid'
    end
    for i = 1, #hired do
        if hired[i].employee_id == employeeId then
            return nil, 'notify_invalid'
        end
    end
    if not Framework.RemoveMoney(src, def.hirePrice, 'trucking-hire') then
        return nil, 'notify_no_money'
    end

    MySQL.insert.await([[
        INSERT INTO dj_trucking_employees (citizenid, employee_id, name, skill, wage, status, lifetime, hired_at)
        VALUES (?, ?, ?, ?, ?, 'hauling', 0, ?)
    ]], {
        Framework.GetCitizenId(src), def.id, def.name, def.skill, def.wage, os.time(),
    })

    Webhooks.Player(src, 'company', 'Driver hired', {
        { name = 'Driver', value = def.name, inline = true },
        { name = 'Signing', value = ('$%s'):format(def.hirePrice), inline = true },
        { name = 'Wage', value = ('$%s / tick'):format(def.wage), inline = true },
    })
    return { name = def.name }
end

function Company.Fire(src, employeeId)
    MySQL.update.await(
        'DELETE FROM dj_trucking_employees WHERE citizenid = ? AND employee_id = ?',
        { Framework.GetCitizenId(src), employeeId }
    )
    local def = Config.GetEmployeeDef(employeeId)
    Webhooks.Player(src, 'company', 'Driver released', {
        { name = 'Driver', value = def and def.name or employeeId, inline = true },
    })
    return { name = def and def.name or employeeId }
end

function Company.TickOwner(src)
    local profile = Profile.Get(src)
    if not profile then return end

    local hired = Company.Employees(src)
    if #hired == 0 then return end

    local last = profile.stats.lastEmployeeTick or os.time()
    local interval = Config.Company.employeeTick * 60
    local ticks = math.floor((os.time() - last) / interval)
    ticks = math.max(0, math.min(ticks, 8))
    if ticks <= 0 then return end

    local bonus = 1.0 + Config.SkillRankBonus(profile.skills, 'dispatcher', 'employee')
    local net = 0
    local incidents = 0

    for _ = 1, ticks do
        for i = 1, #hired do
            local row = hired[i]
            local def = Config.GetEmployeeDef(row.employee_id)
            local cargoId = (def and def.cargo[1]) or 'general'
            local cargo = Config.GetCargo(cargoId)
            local gross = math.floor(((cargo and cargo.payPerKm or 40) * (8 + row.skill * 3)) * bonus)
            local wage = row.wage or (def and def.wage) or 200
            local take = gross - wage
            local incidentMod = def and def.incidentMod or 1.0
            if math.random() < (Config.Company.incidentChance * incidentMod) then
                local hit = math.random(Config.Company.incidentCost.min, Config.Company.incidentCost.max)
                take = take - hit
                incidents = incidents + 1
            end
            take = math.max(-wage, take)
            net = net + take
            row.lifetime = (row.lifetime or 0) + math.max(0, take)
        end
    end

    for i = 1, #hired do
        MySQL.update.await('UPDATE dj_trucking_employees SET lifetime = ?, status = ? WHERE id = ?', {
            hired[i].lifetime, 'hauling', hired[i].id,
        })
    end

    Profile.AddCompany(src, net)
    profile.stats.lastEmployeeTick = os.time()
    profile.dirty = true
    Profile.Save(src)

    if net ~= 0 then
        Webhooks.Player(src, 'company', 'NPC drivers settled', {
            { name = 'Ticks', value = tostring(ticks), inline = true },
            { name = 'Net', value = ('$%s'):format(net), inline = true },
            { name = 'Incidents', value = tostring(incidents), inline = true },
        })
    end

    return net
end

function Company.Loans(src)
    if not DB.Ready() then return {} end
    return MySQL.query.await(
        'SELECT * FROM dj_trucking_loans WHERE citizenid = ?',
        { Framework.GetCitizenId(src) }
    ) or {}
end

function Company.TakeLoan(src, productId)
    if not Config.Loans.enabled then return nil, 'notify_invalid' end
    local product = loanProduct(productId)
    if not product then return nil, 'notify_invalid' end
    if Profile.Level(src) < product.minLevel then
        return nil, 'notify_level'
    end
    local existing = Company.Loans(src)
    if #existing >= Config.Loans.maxActive then
        return nil, 'notify_invalid'
    end

    local profile = Profile.Get(src)
    local fee = math.floor(product.fee * (1.0 - Config.SkillRankBonus(profile and profile.skills, 'negotiator', 'loan')))
    MySQL.insert.await([[
        INSERT INTO dj_trucking_loans (citizenid, product, amount, remaining, daily_fee, taken_at, last_fee_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], {
        Framework.GetCitizenId(src), product.id, product.amount, product.amount, fee, os.time(), os.time(),
    })
    Framework.AddMoney(src, product.amount, 'trucking-loan')
    Webhooks.Player(src, 'money', 'Loan issued', {
        { name = 'Product', value = product.label, inline = true },
        { name = 'Amount', value = ('$%s'):format(product.amount), inline = true },
        { name = 'Daily fee', value = ('$%s'):format(fee), inline = true },
    })
    return { amount = product.amount, fee = fee, label = product.label }
end

function Company.PayLoan(src, loanId, amount)
    local loan = MySQL.single.await(
        'SELECT * FROM dj_trucking_loans WHERE id = ? AND citizenid = ?',
        { loanId, Framework.GetCitizenId(src) }
    )
    if not loan then return nil, 'notify_invalid' end
    amount = math.floor(tonumber(amount) or 0)
    if amount < 100 then return nil, 'notify_invalid' end
    amount = math.min(amount, loan.remaining)

    if not Profile.ChargeCompany(src, amount) then
        if not Framework.RemoveMoney(src, amount, 'trucking-loan-pay') then
            return nil, 'notify_no_money'
        end
    end

    local remaining = loan.remaining - amount
    if remaining <= 0 then
        MySQL.update.await('DELETE FROM dj_trucking_loans WHERE id = ?', { loanId })
        Webhooks.Player(src, 'money', 'Loan cleared', {
            { name = 'Paid', value = ('$%s'):format(amount), inline = true },
        })
        return { remaining = 0, cleared = true }
    end

    MySQL.update.await('UPDATE dj_trucking_loans SET remaining = ? WHERE id = ?', { remaining, loanId })
    Webhooks.Money(src, 'Loan payment', amount, 'loan')
    return { remaining = remaining }
end

function Company.CollectFees(src)
    local loans = Company.Loans(src)
    if #loans == 0 then return end
    local hours = Config.Loans.feeHours * 3600
    local collected = 0
    for i = 1, #loans do
        local loan = loans[i]
        local due = math.floor((os.time() - (loan.last_fee_at or os.time())) / hours)
        due = math.max(0, math.min(due, 5))
        if due > 0 then
            local fee = loan.daily_fee * due
            if not Profile.ChargeCompany(src, fee) then
                Framework.RemoveMoney(src, fee, 'trucking-loan-fee')
            end
            local remaining = loan.remaining + 0
            MySQL.update.await('UPDATE dj_trucking_loans SET last_fee_at = ? WHERE id = ?', { os.time(), loan.id })
            collected = collected + fee
        end
    end
    if collected > 0 then
        Webhooks.Money(src, 'Loan fee collected', collected, 'loan-fee')
        Framework.Notify(src, 'notify_loan_fee', 'inform', collected)
    end
    return collected
end

function Company.UnlockSkill(src, skillId)
    local skill = Config.GetSkill(skillId)
    if not skill then return nil, 'notify_invalid' end
    local profile = Profile.Get(src)
    local rank = math.floor(tonumber(profile.skills[skillId]) or 0)
    if rank >= skill.max then return nil, 'notify_invalid' end
    local cost = skill.cost[rank + 1] or 1
    if not Profile.SpendPoints(src, cost) then
        return nil, 'notify_no_points'
    end
    profile.skills[skillId] = rank + 1
    profile.dirty = true
    Profile.Save(src)
    Webhooks.Player(src, 'progression', 'Skill upgraded', {
        { name = 'Skill', value = skill.label, inline = true },
        { name = 'Rank', value = tostring(rank + 1), inline = true },
    })
    return { id = skillId, rank = rank + 1, label = skill.label }
end

function Company.UnlockCert(src, certId)
    local cert = Config.GetCert(certId)
    if not cert then return nil, 'notify_invalid' end
    local profile = Profile.Get(src)
    if profile.certs[certId] then return { already = true } end
    if Profile.Level(src) < cert.level then
        return nil, 'notify_level'
    end
    if (cert.cost or 0) > 0 and not Profile.SpendPoints(src, cert.cost) then
        return nil, 'notify_no_points'
    end
    profile.certs[certId] = true
    profile.dirty = true
    Profile.Save(src)
    Webhooks.Player(src, 'progression', 'Certification earned', {
        { name = 'Cert', value = cert.label, inline = true },
    })
    return { id = certId, label = cert.label }
end

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'djfivem_trucking'
author 'DJ FiveM Scripts'
description 'DJ FiveM trucking career: quick jobs, freight, owned trucks, skill tree, parties, NPC drivers, loans, and Discord webhooks. Built for Qbox + qbx_vehiclekeys.'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'data/trucks.lua',
    'data/cargo.lua',
    'data/routes.lua',
    'data/skills.lua',
    'data/employees.lua',
}

client_scripts {
    'client/main.lua',
    'client/vehicles.lua',
    'client/jobs.lua',
    'client/nui.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'framework.lua',
    'server/webhooks.lua',
    'server/db.lua',
    'server/profile.lua',
    'server/jobs.lua',
    'server/fleet.lua',
    'server/company.lua',
    'server/parties.lua',
    'server/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/brand/*.png',
    'locales/*.json',
}

ox_libs {
    'locale',
}

dependencies {
    'ox_lib',
    'oxmysql',
}

-- Optional but recommended on Qbox:
-- qbx_core, qbx_vehiclekeys, interact

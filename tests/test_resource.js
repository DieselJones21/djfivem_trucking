#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, '..');
const required = [
  'fxmanifest.lua',
  'config.lua',
  'framework.lua',
  'data/trucks.lua',
  'data/cargo.lua',
  'data/routes.lua',
  'data/skills.lua',
  'data/employees.lua',
  'server/webhooks.lua',
  'server/db.lua',
  'server/profile.lua',
  'server/jobs.lua',
  'server/fleet.lua',
  'server/company.lua',
  'server/parties.lua',
  'server/main.lua',
  'client/main.lua',
  'client/nui.lua',
  'client/jobs.lua',
  'client/vehicles.lua',
  'html/index.html',
  'html/style.css',
  'html/app.js',
  'html/brand/logo.png',
  'locales/en.json',
  'sql/install.sql',
  'README.md',
];

let failed = 0;
for (const file of required) {
  const full = path.join(root, file);
  if (!fs.existsSync(full)) {
    console.error('missing', file);
    failed += 1;
  }
}

const html = fs.readFileSync(path.join(root, 'html/index.html'), 'utf8');
for (const id of ['app', 'nav', 'tabs', 'stats', 'content', 'hud', 'toast', 'shop-title']) {
  if (!html.includes(`id="${id}"`)) {
    console.error('html missing id', id);
    failed += 1;
  }
}

const css = fs.readFileSync(path.join(root, 'html/style.css'), 'utf8');
for (const token of ['--accent: #ff4d1c', 'brand/logo.png', '.nav-btn.active', '.hud', '--grad']) {
  if (!css.includes(token)) {
    console.error('css missing', token);
    failed += 1;
  }
}

const js = fs.readFileSync(path.join(root, 'html/app.js'), 'utf8');
for (const token of ['jobs', 'fleet', 'skills', 'company', 'crew', 'stats', 'DEMO', 'startJob', 'buyTruck']) {
  if (!js.includes(token)) {
    console.error('app.js missing', token);
    failed += 1;
  }
}

const trucks = fs.readFileSync(path.join(root, 'data/trucks.lua'), 'utf8');
for (const model of ['mule', 'linerunner', 'aerocab', 'blacktop', 'brickades', 'vetirs']) {
  if (!trucks.includes(`model = '${model}'`)) {
    console.error('truck spawn missing', model);
    failed += 1;
  }
}

const fw = fs.readFileSync(path.join(root, 'framework.lua'), 'utf8');
if (!fw.includes('qbx_vehiclekeys') || !fw.includes('GiveKeys')) {
  console.error('framework missing qbx_vehiclekeys GiveKeys');
  failed += 1;
}

const hooks = fs.readFileSync(path.join(root, 'server/webhooks.lua'), 'utf8');
if (!hooks.includes('PerformHttpRequest')) {
  console.error('webhooks missing PerformHttpRequest');
  failed += 1;
}

const manifest = fs.readFileSync(path.join(root, 'fxmanifest.lua'), 'utf8');
if (!manifest.includes('ox_lib') || !manifest.includes('oxmysql')) {
  console.error('manifest missing dependencies');
  failed += 1;
}

const jobs = fs.readFileSync(path.join(root, 'client/jobs.lua'), 'utf8');
for (const token of ['JobTruckReady', 'CancelHaul', 'notify_need_truck']) {
  if (!jobs.includes(token)) {
    console.error('jobs.lua missing', token);
    failed += 1;
  }
}

const vehicles = fs.readFileSync(path.join(root, 'client/vehicles.lua'), 'utf8');
for (const token of ['CreateJobVehicle', 'JobTruckReady', 'SetEntityAsMissionEntity', 'netMissionEntity']) {
  if (!vehicles.includes(token)) {
    console.error('vehicles.lua missing', token);
    failed += 1;
  }
}

const nui = fs.readFileSync(path.join(root, 'client/nui.lua'), 'utf8');
for (const token of ['SetTimeout', 'startJob', 'RegisterNUICallback(\'ready\'']) {
  if (!nui.includes(token)) {
    console.error('nui.lua missing', token);
    failed += 1;
  }
}

const clientMain = fs.readFileSync(path.join(root, 'client/main.lua'), 'utf8');
if (!clientMain.includes('CancelCommand') || !clientMain.includes('GetHq') || clientMain.includes('for i = 1, #Config.Depots do')) {
  console.error('client/main.lua should spawn only HQ, not every depot');
  failed += 1;
}

const serverJobs = fs.readFileSync(path.join(root, 'server/jobs.lua'), 'utf8');
if (!serverJobs.includes('notify_need_truck') || !serverJobs.includes('vehicleAtPoint') || !serverJobs.includes('AbortUnspawned')) {
  console.error('server/jobs.lua missing vehicle load check or AbortUnspawned');
  failed += 1;
}

const serverMain = fs.readFileSync(path.join(root, 'server/main.lua'), 'utf8');
if (!serverMain.includes('packCoord')) {
  console.error('server/main.lua missing packCoord');
  failed += 1;
}

const locales = fs.readFileSync(path.join(root, 'locales/en.json'), 'utf8');
for (const token of ['notify_truck_gone', 'notify_cancel_prompt', 'textui_need_truck']) {
  if (!locales.includes(token)) {
    console.error('locales missing', token);
    failed += 1;
  }
}

const config = fs.readFileSync(path.join(root, 'config.lua'), 'utf8');
if (!config.includes('CancelCommand') || !config.includes('HqDepot')) {
  console.error('config missing CancelCommand or HqDepot');
  failed += 1;
}

const routes = fs.readFileSync(path.join(root, 'data/routes.lua'), 'utf8');
if (!routes.includes('GetHq') || !routes.includes('office = true')) {
  console.error('routes missing HQ office');
  failed += 1;
}

if (failed) {
  console.error(`FAILED ${failed} checks`);
  process.exit(1);
}
console.log('djfivem_trucking resource checks passed');

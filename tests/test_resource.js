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

if (failed) {
  console.error(`FAILED ${failed} checks`);
  process.exit(1);
}
console.log('djfivem_trucking resource checks passed');

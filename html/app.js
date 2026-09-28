const resourceName = (() => {
  try { return GetParentResourceName(); } catch { return null; }
})();

const inFiveM = Boolean(resourceName);
const app = document.getElementById('app');
const content = document.getElementById('content');
const statsEl = document.getElementById('stats');
const tabsEl = document.getElementById('tabs');
const navEl = document.getElementById('nav');
const search = document.getElementById('search');
const toastEl = document.getElementById('toast');
const playerNameEl = document.getElementById('player-name');
const playerAvatarEl = document.getElementById('player-avatar');
const playerRoleEl = document.getElementById('player-role');
const titleEl = document.getElementById('shop-title');
const subtitleEl = document.getElementById('shop-subtitle');
const hudEl = document.getElementById('hud');
const hudCargo = document.getElementById('hud-cargo');
const hudDest = document.getElementById('hud-dest');
const hudKind = document.getElementById('hud-kind');
const hudStatus = document.getElementById('hud-status');
const hudIntegrity = document.getElementById('hud-integrity');
const hudIntegrityLabel = document.getElementById('hud-integrity-label');

const ICONS = {
  jobs: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M4 17h16l-2-8H6l-2 8z"/><path d="M8 9V7a4 4 0 0 1 8 0v2"/></svg>',
  fleet: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M3 13h13l3 4h2v3h-3"/><circle cx="7" cy="18" r="2"/><circle cx="17" cy="18" r="2"/><path d="M3 13V8h8l5 5"/></svg>',
  skills: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M12 3 14 8l5 .4-3.8 3.4L16.5 17 12 14.6 7.5 17l1.3-5.2L5 8.4 10 8z"/></svg>',
  company: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M4 20V8l8-4 8 4v12"/><path d="M9 20v-6h6v6"/></svg>',
  crew: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="9" cy="8" r="3"/><circle cx="17" cy="9" r="2.4"/><path d="M3.5 19c.6-3 2.8-5 5.5-5s4.9 2 5.5 5M14 19c.3-2 1.6-3.4 3.5-3.4 1.4 0 2.6.8 3.2 2"/></svg>',
  stats: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M4 19V5M4 19h16M8 15v4M12 11v8M16 8v11"/></svg>',
  truck: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M3 7h11v8H3z"/><path d="M14 10h4l3 3v2h-7z"/><circle cx="7" cy="18" r="1.6"/><circle cx="17" cy="18" r="1.6"/></svg>',
  box: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M4 8 12 4l8 4-8 4-8-4z"/><path d="M4 8v8l8 4 8-4V8"/></svg>',
};

const BRAND_LOGO = '<img class="empty-logo" src="brand/logo.png" alt="DJ FiveM Scripts" decoding="async" draggable="false" />';

const NAV = [
  { id: 'jobs', label: 'Jobs', icon: 'jobs' },
  { id: 'fleet', label: 'Fleet', icon: 'fleet' },
  { id: 'skills', label: 'Skills', icon: 'skills' },
  { id: 'company', label: 'Company', icon: 'company' },
  { id: 'crew', label: 'Crew', icon: 'crew' },
  { id: 'stats', label: 'Stats', icon: 'stats' },
];

const TABS = {
  jobs: [
    { id: 'quick', label: 'Quick jobs' },
    { id: 'freight', label: 'Freight' },
    { id: 'contracts', label: 'Contracts' },
  ],
  fleet: [
    { id: 'garage', label: 'Garage' },
    { id: 'dealership', label: 'Dealership' },
    { id: 'diagnostics', label: 'Diagnostics' },
  ],
  skills: [
    { id: 'tree', label: 'Skill tree' },
    { id: 'certs', label: 'Certifications' },
  ],
  company: [
    { id: 'office', label: 'Office' },
    { id: 'drivers', label: 'Drivers' },
    { id: 'loans', label: 'Loans' },
    { id: 'bank', label: 'Bank' },
  ],
  crew: [
    { id: 'party', label: 'Convoy' },
    { id: 'nearby', label: 'Nearby' },
  ],
  stats: [
    { id: 'career', label: 'Career' },
    { id: 'board', label: 'Board' },
  ],
};

const DEMO = {
  ok: true,
  brand: { title: 'DJ Logistics', role: 'Owner-operator', initials: 'DJ', footer: 'DJ FIVEM SCRIPTS' },
  depot: { id: 'lsport', label: 'Port of Los Santos', subtitle: 'Terminal 4' },
  player: {
    name: 'Diesel Jones',
    level: 8,
    xp: 5400,
    toNext: 1600,
    skillPoints: 3,
    company: 'Chrome Lane Freight',
    balance: 18450,
    reputation: 42,
    insurance: false,
    cash: 27600,
    certs: { general: true, food: true, machinery: true, chemicals: false, fuel: false, valuables: false },
    skills: { hauler: 2, caretaker: 1, mechanic: 1, convoy: 0, broker: 1, dispatcher: 0, negotiator: 0, endurance: 1 },
    stats: { jobs: 47, quickJobs: 31, freightJobs: 16, earned: 91240, miles: 1840, todayJobs: 3, todayEarned: 4120, bestPayout: 2860, failed: 2 },
    maxLevel: 20,
  },
  trucks: [
    { id: 'mule', model: 'mule', label: 'Mule Box', description: 'Vanilla starter box. Always streams.', class: 'box', price: 18500, level: 1, locked: false, owned: 0, payout: 1.0, cargo: ['general', 'food'], addon: false },
    { id: 'linerunner', model: 'linerunner', label: 'Linerunner', description: 'Addon long-nose. First real DJ freight tractor.', class: 'heavy', price: 135000, level: 4, locked: false, owned: 1, payout: 1.34, cargo: ['general', 'food', 'machinery', 'chemicals'], trailer: true, addon: true },
    { id: 'blacktop', model: 'blacktop', label: 'Blacktop', description: 'Addon heavy. Plant, asphalt, and yard work.', class: 'heavy', price: 168000, level: 6, locked: false, owned: 0, payout: 1.40, cargo: ['general', 'machinery', 'chemicals'], trailer: true, addon: true },
    { id: 'aerocab', model: 'aerocab', label: 'Aerocab', description: 'Addon sleeper cab. Long-haul and fuel lanes.', class: 'heavy', price: 195000, level: 8, locked: false, owned: 0, payout: 1.46, cargo: ['general', 'machinery', 'chemicals', 'fuel'], trailer: true, addon: true },
    { id: 'vetirs', model: 'vetirs', label: 'Vetir', description: 'Addon 6x6. Off-road and hazmat.', class: 'offroad', price: 220000, level: 10, locked: true, owned: 0, payout: 1.42, cargo: ['machinery', 'chemicals', 'fuel'], addon: true },
    { id: 'brickades', model: 'brickades', label: 'Brickade', description: 'Addon armored yard truck. High-value ready.', class: 'armored', price: 265000, level: 12, locked: true, owned: 0, payout: 1.55, cargo: ['machinery', 'fuel', 'valuables'], addon: true },
  ],
  garage: [
    { id: 1, truck_id: 'linerunner', label: 'Linerunner', plate: 'DJ18420', model: 'linerunner', body: 910, engine: 940, mileage: 428, stored: 1 },
  ],
  diagnostics: [
    { id: 1, label: 'Linerunner', plate: 'DJ18420', model: 'linerunner', body: 91, engine: 94, health: 92, mileage: 428, stored: true, repair: 144 },
  ],
  offers: [
    { id: 'q1', kind: 'quick', cargo: 'general', cargoLabel: 'General Freight', pickupLabel: 'Port of Los Santos', dropoffLabel: 'Sandy Airfield', distance: 4200, payout: 1860, xp: 58, contract: false, truckHint: 'Mule Box' },
    { id: 'q2', kind: 'quick', cargo: 'food', cargoLabel: 'Refrigerated Food', pickupLabel: 'Port of Los Santos', dropoffLabel: 'Grapeseed Co-op', distance: 6100, payout: 2480, xp: 74, contract: true, truckHint: 'Benson' },
    { id: 'q3', kind: 'quick', cargo: 'machinery', cargoLabel: 'Machinery', pickupLabel: 'Port of Los Santos', dropoffLabel: 'Harmony Freight', distance: 3800, payout: 2210, xp: 66, contract: false, truckHint: 'Benson' },
    { id: 'f1', kind: 'freight', cargo: 'chemicals', cargoLabel: 'Chemicals', pickupLabel: 'Port of Los Santos', dropoffLabel: 'Humane Labs Gate', distance: 7200, payout: 4120, xp: 110, contract: false, truckHint: 'Linerunner' },
    { id: 'f2', kind: 'freight', cargo: 'food', cargoLabel: 'Refrigerated Food', pickupLabel: 'Port of Los Santos', dropoffLabel: 'Paleto Bay Yard', distance: 9100, payout: 3640, xp: 98, contract: true, truckHint: 'Aerocab' },
  ],
  contracts: [
    { id: 'c-1-sandy', cargo: 'food', dropoff: 'sandy', dropoffLabel: 'Sandy Airfield', bonus: 36, done: false },
    { id: 'c-2-paleto', cargo: 'machinery', dropoff: 'paleto', dropoffLabel: 'Paleto Bay Yard', bonus: 36, done: false },
    { id: 'c-3-humane', cargo: 'general', dropoff: 'humane', dropoffLabel: 'Humane Labs Gate', bonus: 36, done: true },
  ],
  employees: [
    { id: 'ray', name: 'Ray Campos', title: 'Day Cab Rookie', description: 'Cheap, reliable, slow.', wage: 220, skill: 1, hireLevel: 4, hirePrice: 1500, locked: false, hired: true, status: 'hauling', lifetime: 8420 },
    { id: 'lena', name: 'Lena Ortiz', title: 'Reefer Driver', description: 'Keeps the box cold.', wage: 340, skill: 2, hireLevel: 6, hirePrice: 2800, locked: false, hired: false, status: 'available' },
    { id: 'jonas', name: 'Jonas Reed', title: 'Tanker Ace', description: 'Fuel lanes only.', wage: 780, skill: 5, hireLevel: 12, hirePrice: 8800, locked: true, hired: false, status: 'available' },
    { id: 'suki', name: 'Suki Tran', title: 'Bonded Courier', description: 'High-value specialist.', wage: 940, skill: 5, hireLevel: 14, hirePrice: 12000, locked: true, hired: false, status: 'available' },
  ],
  loans: {
    products: [
      { id: 'starter', label: 'Starter Note', amount: 25000, fee: 350, minLevel: 2 },
      { id: 'fleet', label: 'Fleet Note', amount: 75000, fee: 900, minLevel: 6 },
      { id: 'terminal', label: 'Terminal Note', amount: 175000, fee: 1900, minLevel: 12 },
    ],
    active: [{ id: 9, product: 'starter', remaining: 16400, daily_fee: 322 }],
  },
  party: { active: true, host: 1, members: [{ id: 1, name: 'Diesel Jones', host: true, me: true }, { id: 2, name: 'Kai Reyes', host: false, me: false }] },
  nearby: [{ id: 12, name: 'Reese Cole' }, { id: 18, name: 'Nova Park' }],
  history: [
    { job_type: 'freight', cargo: 'food', pickup: 'lsport', dropoff: 'paleto', distance: 9100, payout: 2860, xp: 92, integrity: 94 },
    { job_type: 'quick', cargo: 'general', pickup: 'lsport', dropoff: 'sandy', distance: 4200, payout: 1640, xp: 51, integrity: 100 },
    { job_type: 'quick', cargo: 'machinery', pickup: 'lamesa', dropoff: 'harmony', distance: 2100, payout: 980, xp: 34, integrity: 88 },
  ],
  board: {
    today: [{ name: 'Diesel Jones', value: 4120, jobs: 3 }, { name: 'Kai Reyes', value: 2980, jobs: 2 }, { name: 'Reese Cole', value: 1540, jobs: 2 }],
    all: [{ name: 'Kai Reyes', value: 128400, jobs: 80 }, { name: 'Diesel Jones', value: 91240, jobs: 47 }, { name: 'Nova Park', value: 64010, jobs: 39 }],
  },
  skillOrder: ['hauler', 'caretaker', 'mechanic', 'endurance', 'convoy', 'broker', 'dispatcher', 'negotiator'],
  skills: {
    hauler: { id: 'hauler', label: 'Heavy Hauler', description: '+4% job payout per rank.', max: 5, cost: [1, 1, 2, 2, 3] },
    caretaker: { id: 'caretaker', label: 'Cargo Care', description: 'Integrity drops slower.', max: 5, cost: [1, 1, 2, 2, 3] },
    mechanic: { id: 'mechanic', label: 'Yard Mechanic', description: 'Repair bills drop 8% per rank.', max: 5, cost: [1, 1, 2, 2, 3] },
    endurance: { id: 'endurance', label: 'Long Haul', description: 'Fuel costs drop. Bonus XP on long routes.', max: 4, cost: [1, 2, 2, 3] },
    convoy: { id: 'convoy', label: 'Convoy Lead', description: '+5% party bonus per rank.', max: 4, cost: [1, 2, 2, 3] },
    broker: { id: 'broker', label: 'Freight Broker', description: 'Daily contracts pay more.', max: 4, cost: [1, 2, 2, 3] },
    dispatcher: { id: 'dispatcher', label: 'Dispatcher', description: 'NPC drivers earn +10% net.', max: 5, cost: [1, 1, 2, 2, 3] },
    negotiator: { id: 'negotiator', label: 'Note Negotiator', description: 'Loan fees drop 8% per rank.', max: 3, cost: [2, 2, 3] },
  },
  certOrder: ['general', 'food', 'machinery', 'chemicals', 'fuel', 'valuables'],
  certs: {
    general: { id: 'general', label: 'CDL Class B', description: 'Issued on day one.', level: 1, cost: 0, auto: true },
    food: { id: 'food', label: 'Reefer Ticket', description: 'Refrigerated food loads.', level: 2, cost: 1 },
    machinery: { id: 'machinery', label: 'Heavy Equipment', description: 'Plant and machinery moves.', level: 4, cost: 2 },
    chemicals: { id: 'chemicals', label: 'Hazmat Endorsement', description: 'Industrial chemical totes.', level: 6, cost: 2 },
    fuel: { id: 'fuel', label: 'Tanker Endorsement', description: 'Flammable liquids.', level: 8, cost: 3 },
    valuables: { id: 'valuables', label: 'High-Value Permit', description: 'Jewelry and secured freight.', level: 10, cost: 3 },
  },
};

let state = {
  view: 'jobs',
  tab: 'quick',
  query: '',
  data: null,
  offers: [],
  loadingOffers: false,
};

function escapeHtml(value) {
  return String(value ?? '').replace(/[&<>"']/g, (ch) => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
  }[ch]));
}

function money(n) {
  return '$' + Math.floor(Number(n) || 0).toLocaleString('en-US');
}

function emptyState(title, copy) {
  return `<div class="empty">${BRAND_LOGO}<strong>${escapeHtml(title)}</strong><p>${escapeHtml(copy)}</p></div>`;
}

function toast(text) {
  toastEl.textContent = text;
  toastEl.classList.remove('hidden');
  clearTimeout(toast._t);
  toast._t = setTimeout(() => toastEl.classList.add('hidden'), 3200);
}

function post(name, payload) {
  if (!inFiveM) {
    return Promise.resolve(previewAction(name, payload));
  }
  return fetch(`https://${resourceName}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(payload || {}),
  }).then((r) => r.json()).catch(() => ({ ok: false }));
}

function previewAction(name, payload) {
  const data = state.data;
  const player = data.player;
  if (name === 'offers') {
    const kind = payload.kind;
    return { ok: true, offers: DEMO.offers.filter((o) => o.kind === kind) };
  }
  if (name === 'startJob') {
    const offer = (data.offers || DEMO.offers).find((o) => o.id === payload.offerId) || DEMO.offers[0];
    toast('Haul locked in — ' + offer.cargoLabel + ' to ' + offer.dropoffLabel + '.');
    showHud({
      show: true,
      cargo: offer.cargoLabel,
      dest: offer.pickupLabel,
      kind: offer.kind,
      status: 'Pickup',
      integrity: 100,
    });
    return { ok: true };
  }
  if (name === 'buyTruck') {
    const truck = (data.trucks || []).find((t) => t.id === payload.truckId);
    if (truck && player.cash >= truck.price && !truck.locked) {
      player.cash -= truck.price;
      truck.owned = (truck.owned || 0) + 1;
      data.garage = data.garage || [];
      data.garage.unshift({
        id: Date.now(),
        truck_id: truck.id,
        label: truck.label,
        plate: 'DJ' + Math.floor(10000 + Math.random() * 89999),
        model: truck.id,
        mileage: 0,
        stored: 1,
      });
      toast('Purchased ' + truck.label + ' for ' + money(truck.price) + '.');
    } else {
      toast('Need more cash or a higher level.');
    }
    return { ok: true, player: player, trucks: data.trucks, garage: data.garage };
  }
  if (name === 'upgradeSkill') {
    const id = payload.skillId;
    const skill = data.skills[id];
    const rank = (player.skills[id] || 0);
    const cost = (skill && skill.cost && skill.cost[rank]) || 1;
    if (skill && rank < skill.max && player.skillPoints >= cost) {
      player.skills[id] = rank + 1;
      player.skillPoints -= cost;
      toast(skill.label + ' is now rank ' + player.skills[id] + '.');
    } else {
      toast('Need a skill point for that.');
    }
    return { ok: true, player: player };
  }
  if (name === 'unlockCert') {
    const cert = data.certs[payload.certId];
    if (cert && player.level >= cert.level && !player.certs[payload.certId] && player.skillPoints >= (cert.cost || 0)) {
      player.certs[payload.certId] = true;
      player.skillPoints -= cert.cost || 0;
      toast('Earned ' + cert.label + '.');
    } else {
      toast('Certification still locked.');
    }
    return { ok: true, player: player };
  }
  if (name === 'deposit') {
    const amt = Math.max(50, Number(payload.amount) || 1000);
    if (player.cash >= amt) {
      player.cash -= amt;
      player.balance += amt;
      toast('Deposited ' + money(amt) + ' into the company account.');
    } else {
      toast('Not enough personal cash.');
    }
    return { ok: true, player: player };
  }
  if (name === 'withdraw') {
    const amt = Math.max(50, Number(payload.amount) || 1000);
    if (player.balance >= amt) {
      player.balance -= amt;
      player.cash += amt;
      toast('Withdrew ' + money(amt) + ' from the company account.');
    }
    return { ok: true, player: player };
  }
  if (name === 'close') return { ok: true };
  toast('Preview: ' + name.replace(/([A-Z])/g, ' $1').toLowerCase());
  return { ok: true, player: player, employees: data.employees, loans: data.loans, party: data.party };
}

function applyPlayer(player, brand, depot) {
  if (!player) return;
  playerNameEl.textContent = player.name || 'Driver';
  playerRoleEl.textContent = player.company || (brand && brand.role) || 'Contract driver';
  playerAvatarEl.textContent = ((player.name || 'DJ').split(' ').map((p) => p[0]).join('').slice(0, 2) || 'DJ').toUpperCase();
  titleEl.textContent = (brand && brand.title) || 'DJ Logistics';
  subtitleEl.textContent = depot ? `${depot.label} · ${depot.subtitle}` : 'Los Santos freight desk';

  const xpPct = player.toNext === 0 ? 100 : Math.max(8, 100 - Math.min(100, Math.floor((player.toNext / 4000) * 100)));
  statsEl.innerHTML = `
    <article class="stat"><span>Level</span><strong>${player.level}</strong><em>${player.skillPoints} pts</em></article>
    <article class="stat"><span>Bank / yard</span><strong>${money(player.cash)}</strong><em>${money(player.balance)} co.</em></article>
    <article class="stat"><span>Today</span><strong>${money(player.stats.todayEarned || 0)}</strong><em>${player.stats.todayJobs || 0} jobs</em></article>
    <article class="stat"><span>Reputation</span><strong>${player.reputation || 0}</strong><em>${player.insurance ? 'Insured' : 'Uninsured'}</em></article>
  `;
}

function renderNav() {
  navEl.innerHTML = NAV.map((item) => `
    <button class="nav-btn ${state.view === item.id ? 'active' : ''}" data-view="${item.id}">
      ${ICONS[item.icon] || ''}<span>${item.label}</span>
    </button>
  `).join('');
}

function renderTabs() {
  const tabs = TABS[state.view] || [];
  tabsEl.innerHTML = tabs.map((tab) => `
    <button class="tab ${state.tab === tab.id ? 'active' : ''}" data-tab="${tab.id}">${tab.label}</button>
  `).join('');
}

function matchesQuery(text) {
  const q = state.query.trim().toLowerCase();
  if (!q) return true;
  return String(text || '').toLowerCase().includes(q);
}

function renderJobs() {
  content.className = 'content';
  if (state.tab === 'contracts') {
    const rows = (state.data.contracts || []).filter((c) => matchesQuery(c.cargo + c.dropoffLabel));
    if (!rows.length) {
      content.innerHTML = emptyState('No contracts', 'Daily bonus lanes refresh at midnight.');
      return;
    }
    content.innerHTML = rows.map((c) => `
      <article class="card">
        <div class="card-head">
          <div class="icon">${ICONS.box}</div>
          <span class="badge ${c.done ? 'quick' : 'contract'}">${c.done ? 'Done' : '+' + c.bonus + '%'}</span>
        </div>
        <h3>${escapeHtml((c.cargo || '').replace(/^./, (s) => s.toUpperCase()))}</h3>
        <p>Deliver to ${escapeHtml(c.dropoffLabel)}. Bonus applies when you take a matching haul.</p>
        <div class="buy-row"><span class="price">${c.done ? 'Complete' : 'Open'}</span></div>
      </article>
    `).join('');
    return;
  }

  const kind = state.tab === 'freight' ? 'freight' : 'quick';
  const rows = (state.offers || []).filter((o) => o.kind === kind && matchesQuery(o.cargoLabel + o.dropoffLabel));
  if (state.loadingOffers) {
    content.innerHTML = emptyState('Checking the board', 'Pulling live lanes from this depot...');
    return;
  }
  if (!rows.length) {
    content.innerHTML = emptyState(
      kind === 'freight' ? 'No freight lanes' : 'No rental jobs',
      kind === 'freight' ? 'Buy a truck or unlock a cert to see owner-op work.' : 'Level up or grab a cert to open more cargo.'
    );
    return;
  }
  content.innerHTML = rows.map((job) => `
    <article class="card">
      <div class="card-head">
        <div class="icon">${ICONS.box}</div>
        <span class="badge ${job.contract ? 'contract' : job.kind}">${job.contract ? 'Contract' : job.kind}</span>
      </div>
      <h3>${escapeHtml(job.cargoLabel)}</h3>
      <p>${escapeHtml(job.pickupLabel)} → ${escapeHtml(job.dropoffLabel)} · ${Math.round((job.distance || 0) / 1000)} km · ${escapeHtml(job.truckHint || '')}</p>
      <div class="meta-row"><span>${job.xp} XP</span><span class="price">${money(job.payout)}</span></div>
      <div class="buy-row">
        <span></span>
        <button class="btn" data-start="${escapeHtml(job.id)}">Accept haul</button>
      </div>
    </article>
  `).join('');
}

function renderFleet() {
  content.className = 'content';
  if (state.tab === 'dealership') {
    const rows = (state.data.trucks || []).filter((t) => matchesQuery(t.label + t.description + (t.model || '')));
    content.innerHTML = rows.map((truck) => `
      <article class="card">
        <div class="card-head">
          <div class="icon">${ICONS.truck}</div>
          <span class="badge ${truck.locked ? 'locked' : truck.addon ? 'addon' : 'freight'}">${truck.locked ? 'Lv ' + truck.level : truck.addon ? 'Addon' : truck.class}</span>
        </div>
        <h3>${escapeHtml(truck.label)}</h3>
        <p>${escapeHtml(truck.description)}</p>
        <div class="meta-row"><span>+${Math.round((truck.payout - 1) * 100)}% pay · ${escapeHtml((truck.cargo || []).join(', '))}</span></div>
        <div class="buy-row">
          <div>
            <div class="price">${money(truck.price)}</div>
            <div class="spawn">${escapeHtml(truck.model || truck.id)}</div>
          </div>
          <button class="btn" data-buy="${escapeHtml(truck.id)}" ${truck.locked ? 'disabled' : ''}>Buy</button>
        </div>
      </article>
    `).join('') || emptyState('Empty lot', 'Add spawn codes in data/trucks.lua.');
    return;
  }

  if (state.tab === 'diagnostics') {
    const rows = state.data.diagnostics || [];
    if (!rows.length) {
      content.innerHTML = emptyState('No diagnostics', 'Buy a truck and the yard computer will track body, engine, and mileage.');
      return;
    }
    content.innerHTML = rows.map((row) => `
      <article class="card">
        <div class="card-head">
          <div class="icon">${ICONS.fleet}</div>
          <span class="badge ${row.health < 70 ? 'locked' : 'freight'}">${row.health}% health</span>
        </div>
        <h3>${escapeHtml(row.label)}</h3>
        <p>${escapeHtml(row.plate)} · ${row.mileage} mi · spawn <b>${escapeHtml(row.model)}</b></p>
        <div class="bar"><i style="width:${row.health}%"></i></div>
        <div class="buy-row">
          <span>Repair ${money(row.repair)}</span>
          <button class="btn" data-repair="${row.id}" ${row.repair < 1 ? 'disabled' : ''}>Repair</button>
        </div>
      </article>
    `).join('');
    return;
  }

  const rows = (state.data.garage || []).filter((t) => matchesQuery(t.label + t.plate));
  if (!rows.length) {
    content.innerHTML = emptyState('Empty garage', 'Start on quick jobs, bank the money, then buy a Linerunner.');
    return;
  }
  content.innerHTML = rows.map((row) => `
    <article class="card">
      <div class="card-head">
        <div class="icon">${ICONS.truck}</div>
        <span class="badge freight">${row.stored ? 'Stored' : 'Out'}</span>
      </div>
      <h3>${escapeHtml(row.label)}</h3>
      <p>${escapeHtml(row.plate)} · ${row.mileage || 0} mi · ${escapeHtml(row.model)}</p>
      <div class="buy-row">
        <button class="btn ghost" data-sell="${row.id}">Sell</button>
        <button class="btn" data-take="${row.id}" ${row.stored ? '' : 'disabled'}>Take out</button>
      </div>
    </article>
  `).join('');
}

function pips(rank, max) {
  let html = '<div class="ranks">';
  for (let i = 1; i <= max; i += 1) html += `<i class="pip ${i <= rank ? 'on' : ''}"></i>`;
  return html + '</div>';
}

function renderSkills() {
  content.className = 'content';
  const player = state.data.player;
  if (state.tab === 'certs') {
    content.innerHTML = (state.data.certOrder || []).map((id) => {
      const cert = state.data.certs[id];
      const owned = player.certs && player.certs[id];
      return `
        <article class="card">
          <div class="card-head">
            <div class="icon">${ICONS.skills}</div>
            <span class="badge ${owned ? 'contract' : 'locked'}">${owned ? 'Owned' : 'Lv ' + cert.level}</span>
          </div>
          <h3>${escapeHtml(cert.label)}</h3>
          <p>${escapeHtml(cert.description)}</p>
          <div class="buy-row">
            <span>${cert.cost ? cert.cost + ' pts' : 'Free'}</span>
            <button class="btn" data-cert="${id}" ${owned || player.level < cert.level ? 'disabled' : ''}>Unlock</button>
          </div>
        </article>
      `;
    }).join('');
    return;
  }

  content.innerHTML = (state.data.skillOrder || []).map((id) => {
    const skill = state.data.skills[id];
    const rank = (player.skills && player.skills[id]) || 0;
    return `
      <article class="card">
        <div class="card-head">
          <div class="icon">${ICONS.skills}</div>
          <span class="badge freight">${rank}/${skill.max}</span>
        </div>
        <h3>${escapeHtml(skill.label)}</h3>
        <p>${escapeHtml(skill.description)}</p>
        ${pips(rank, skill.max)}
        <div class="buy-row">
          <span>${rank >= skill.max ? 'Maxed' : 'Next ' + ((skill.cost && skill.cost[rank]) || 1) + ' pt'}</span>
          <button class="btn" data-skill="${id}" ${rank >= skill.max ? 'disabled' : ''}>Upgrade</button>
        </div>
      </article>
    `;
  }).join('');
}

function renderCompany() {
  const player = state.data.player;
  if (state.tab === 'drivers') {
    content.className = 'content';
    content.innerHTML = (state.data.employees || []).filter((e) => matchesQuery(e.name + e.title)).map((emp) => `
      <article class="card">
        <div class="card-head">
          <div class="icon">${ICONS.crew}</div>
          <span class="badge ${emp.hired ? 'contract' : emp.locked ? 'locked' : 'quick'}">${emp.hired ? emp.status : emp.locked ? 'Lv ' + emp.hireLevel : 'Available'}</span>
        </div>
        <h3>${escapeHtml(emp.name)}</h3>
        <p>${escapeHtml(emp.title)} · ${escapeHtml(emp.description)}</p>
        <div class="meta-row"><span>Wage ${money(emp.wage)}</span><span>${emp.lifetime ? money(emp.lifetime) + ' lifetime' : money(emp.hirePrice) + ' hire'}</span></div>
        <div class="buy-row">
          ${emp.hired
            ? `<button class="btn ghost" data-fire="${emp.id}">Release</button>`
            : `<button class="btn" data-hire="${emp.id}" ${emp.locked ? 'disabled' : ''}>Hire</button>`}
        </div>
      </article>
    `).join('');
    return;
  }

  if (state.tab === 'loans') {
    content.className = 'content';
    const active = (state.data.loans && state.data.loans.active) || [];
    const products = (state.data.loans && state.data.loans.products) || [];
    content.innerHTML = [
      ...active.map((loan) => `
        <article class="card">
          <div class="card-head"><div class="icon">${ICONS.company}</div><span class="badge locked">Active note</span></div>
          <h3>${escapeHtml(loan.product)}</h3>
          <p>Remaining ${money(loan.remaining)}. Daily fee ${money(loan.daily_fee)}.</p>
          <div class="form-row">
            <input data-loan-amt="${loan.id}" type="number" min="100" step="100" value="1000" />
            <button class="btn" data-payloan="${loan.id}">Pay</button>
          </div>
        </article>
      `),
      ...products.map((p) => `
        <article class="card">
          <div class="card-head"><div class="icon">${ICONS.company}</div><span class="badge freight">Lv ${p.minLevel}</span></div>
          <h3>${escapeHtml(p.label)}</h3>
          <p>Borrow ${money(p.amount)}. Daily fee ${money(p.fee)} until you clear the note.</p>
          <div class="buy-row">
            <span class="price">${money(p.amount)}</span>
            <button class="btn" data-loan="${p.id}" ${player.level < p.minLevel || active.length ? 'disabled' : ''}>Borrow</button>
          </div>
        </article>
      `),
    ].join('');
    return;
  }

  content.className = 'content wide-view';
  if (state.tab === 'bank') {
    content.innerHTML = `
      <article class="card">
        <h3>Company account</h3>
        <p>Keep operating cash in the yard so NPC wages and repairs do not touch your pocket.</p>
        <div class="price">${money(player.balance)}</div>
        <div class="form-row">
          <input id="bank-amt" type="number" min="50" step="50" value="1000" />
          <button class="btn" data-bank="deposit">Deposit</button>
          <button class="btn ghost" data-bank="withdraw">Withdraw</button>
        </div>
      </article>
      <article class="card">
        <h3>Personal bank</h3>
        <p>Framework account used for truck purchases and loan draws.</p>
        <div class="price">${money(player.cash)}</div>
      </article>
    `;
    return;
  }

  content.innerHTML = `
    <article class="card">
      <h3>${escapeHtml(player.company)}</h3>
      <p>Rename the company, buy insurance, and watch reputation climb with clean deliveries.</p>
      <div class="form-row">
        <input id="rename-input" maxlength="32" value="${escapeHtml(player.company)}" />
        <button class="btn" data-rename="1">Rename</button>
      </div>
    </article>
    <article class="card">
      <h3>Yard insurance</h3>
      <p>Cuts owned-truck repair bills. One-time company policy.</p>
      <div class="buy-row">
        <span class="price">${player.insurance ? 'Active' : '$8,500'}</span>
        <button class="btn" data-insure="1" ${player.insurance ? 'disabled' : ''}>Insure fleet</button>
      </div>
    </article>
  `;
}

function renderCrew() {
  content.className = 'content wide-view';
  if (state.tab === 'nearby') {
    const rows = state.data.nearby || [];
    content.innerHTML = rows.length ? rows.map((p) => `
      <article class="card">
        <h3>${escapeHtml(p.name)}</h3>
        <p>In range of this depot. Invite them into the convoy.</p>
        <div class="buy-row"><span></span><button class="btn" data-invite="${p.id}">Invite</button></div>
      </article>
    `).join('') : emptyState('Nobody nearby', 'Stand next to a friend at the depot to invite them.');
    return;
  }

  const party = state.data.party || { active: false, members: [] };
  content.innerHTML = `
    <article class="card">
      <h3>${party.active ? 'Active convoy' : 'Start a crew'}</h3>
      <p>Party hauls split bonus money. Host drives; friends ride the same ticket.</p>
      <div class="buy-row">
        <span>${party.members.length || 0} / 4</span>
        ${party.active
          ? '<button class="btn ghost" data-leave="1">Leave</button>'
          : '<button class="btn" data-create="1">Create crew</button>'}
      </div>
    </article>
    <article class="board-col">
      <h3>Members</h3>
      ${(party.members || []).map((m) => `<div class="board-row ${m.me ? 'me' : ''}"><b>${m.host ? 'H' : '•'}</b><span>${escapeHtml(m.name)}</span><span></span></div>`).join('') || '<p>No crew yet.</p>'}
    </article>
  `;
}

function renderStats() {
  const player = state.data.player;
  if (state.tab === 'board') {
    content.className = 'content wide-view';
    const board = state.data.board || { today: [], all: [] };
    const col = (title, rows) => `
      <article class="board-col">
        <h3>${title}</h3>
        ${rows.map((r, i) => `<div class="board-row ${r.name === player.name ? 'me' : ''}"><b>${i + 1}</b><span>${escapeHtml(r.name)}</span><span class="value">${money(r.value)}</span></div>`).join('') || '<p>No hauls logged.</p>'}
      </article>
    `;
    content.innerHTML = col('Today', board.today || []) + col('All time', board.all || []);
    return;
  }

  content.className = 'content';
  const s = player.stats || {};
  const history = state.data.history || [];
  content.innerHTML = `
    <article class="card"><h3>Jobs</h3><p>Quick ${s.quickJobs || 0} · Freight ${s.freightJobs || 0} · Failed ${s.failed || 0}</p><div class="price">${s.jobs || 0}</div></article>
    <article class="card"><h3>Earned</h3><p>Best ticket ${money(s.bestPayout || 0)}</p><div class="price">${money(s.earned || 0)}</div></article>
    <article class="card"><h3>Miles</h3><p>Logged wheel time across every haul.</p><div class="price">${s.miles || 0}</div></article>
    ${history.map((h) => `
      <article class="card">
        <div class="card-head"><span class="badge ${h.job_type}">${h.job_type}</span></div>
        <h3>${escapeHtml(h.cargo)}</h3>
        <p>${escapeHtml(h.pickup)} → ${escapeHtml(h.dropoff)} · ${h.integrity}% cargo</p>
        <div class="buy-row"><span>${h.xp} XP</span><span class="price">${money(h.payout)}</span></div>
      </article>
    `).join('')}
  `;
}

function render() {
  if (!state.data) return;
  renderNav();
  renderTabs();
  document.querySelector('.toolbar').classList.toggle('search-hidden', state.view === 'company' && state.tab === 'office');
  if (state.view === 'jobs') renderJobs();
  else if (state.view === 'fleet') renderFleet();
  else if (state.view === 'skills') renderSkills();
  else if (state.view === 'company') renderCompany();
  else if (state.view === 'crew') renderCrew();
  else renderStats();
}

async function loadOffers(kind) {
  state.loadingOffers = true;
  render();
  const result = await post('offers', { kind });
  state.loadingOffers = false;
  state.offers = (result && result.offers) || [];
  if (result && result.error) toast(result.error);
  render();
}

function openUi(data) {
  state.data = data;
  state.view = 'jobs';
  state.tab = 'quick';
  state.query = '';
  search.value = '';
  applyPlayer(data.player, data.brand, data.depot);
  app.classList.remove('hidden');
  app.setAttribute('aria-hidden', 'false');
  if (inFiveM) loadOffers('quick');
  else {
    state.offers = DEMO.offers;
    render();
  }
}

function closeUi() {
  app.classList.add('hidden');
  app.setAttribute('aria-hidden', 'true');
  post('close', {});
}

function showHud(data) {
  if (!data || !data.show) {
    hudEl.classList.add('hidden');
    hudEl.setAttribute('aria-hidden', 'true');
    return;
  }
  hudCargo.textContent = data.cargo || 'Cargo';
  hudDest.textContent = data.dest || '';
  hudKind.textContent = (data.kind || 'job').toUpperCase();
  hudStatus.textContent = data.status || '';
  const pct = Math.max(0, Math.min(100, Number(data.integrity) || 100));
  hudIntegrity.style.width = pct + '%';
  hudIntegrityLabel.textContent = Math.floor(pct) + '%';
  hudEl.classList.remove('hidden');
  hudEl.setAttribute('aria-hidden', 'false');
}

function mergePlayer(next) {
  if (!next) return;
  state.data.player = Object.assign(state.data.player, next);
  applyPlayer(state.data.player, state.data.brand, state.data.depot);
}

navEl.addEventListener('click', (event) => {
  const btn = event.target.closest('[data-view]');
  if (!btn) return;
  state.view = btn.dataset.view;
  state.tab = (TABS[state.view] || [{ id: 'quick' }])[0].id;
  if (state.view === 'jobs') loadOffers(state.tab === 'freight' ? 'freight' : 'quick');
  else render();
});

tabsEl.addEventListener('click', (event) => {
  const btn = event.target.closest('[data-tab]');
  if (!btn) return;
  state.tab = btn.dataset.tab;
  if (state.view === 'jobs' && (state.tab === 'quick' || state.tab === 'freight')) loadOffers(state.tab);
  else render();
});

search.addEventListener('input', () => {
  state.query = search.value;
  render();
});

content.addEventListener('click', async (event) => {
  const start = event.target.closest('[data-start]');
  if (start) {
    const result = await post('startJob', { offerId: start.dataset.start });
    if (result && result.error) toast(result.error);
    return;
  }
  const buy = event.target.closest('[data-buy]');
  if (buy) {
    const result = await post('buyTruck', { truckId: buy.dataset.buy });
    if (result && result.ok) {
      if (result.trucks) state.data.trucks = result.trucks;
      if (result.garage) state.data.garage = result.garage;
      mergePlayer(result.player);
      toast('Truck purchased.');
      render();
    } else toast((result && result.error) || 'Could not buy.');
    return;
  }
  const take = event.target.closest('[data-take]');
  if (take) { await post('takeTruck', { rowId: Number(take.dataset.take) }); return; }
  const sell = event.target.closest('[data-sell]');
  if (sell) {
    const result = await post('sellTruck', { rowId: Number(sell.dataset.sell) });
    if (result && result.ok) {
      if (result.garage) state.data.garage = result.garage;
      mergePlayer(result.player);
      render();
    }
    return;
  }
  const repair = event.target.closest('[data-repair]');
  if (repair) {
    const result = await post('repairTruck', { rowId: Number(repair.dataset.repair) });
    if (result && result.ok) {
      if (result.diagnostics) state.data.diagnostics = result.diagnostics;
      mergePlayer(result.player);
      toast('Truck repaired.');
      render();
    }
    return;
  }
  const skill = event.target.closest('[data-skill]');
  if (skill) {
    const result = await post('upgradeSkill', { skillId: skill.dataset.skill });
    if (result && result.ok) { mergePlayer(result.player); toast('Skill upgraded.'); render(); }
    else toast((result && result.error) || 'Need more points.');
    return;
  }
  const cert = event.target.closest('[data-cert]');
  if (cert) {
    const result = await post('unlockCert', { certId: cert.dataset.cert });
    if (result && result.ok) { mergePlayer(result.player); toast('Certification earned.'); render(); }
    else toast((result && result.error) || 'Locked.');
    return;
  }
  const hire = event.target.closest('[data-hire]');
  if (hire) {
    const result = await post('hire', { employeeId: hire.dataset.hire });
    if (result && result.ok) { if (result.employees) state.data.employees = result.employees; mergePlayer(result.player); render(); }
    return;
  }
  const fire = event.target.closest('[data-fire]');
  if (fire) {
    const result = await post('fire', { employeeId: fire.dataset.fire });
    if (result && result.ok) { if (result.employees) state.data.employees = result.employees; render(); }
    return;
  }
  const loan = event.target.closest('[data-loan]');
  if (loan) {
    const result = await post('loan', { productId: loan.dataset.loan });
    if (result && result.ok) { if (result.loans) state.data.loans = result.loans; mergePlayer(result.player); render(); }
    return;
  }
  const pay = event.target.closest('[data-payloan]');
  if (pay) {
    const input = content.querySelector(`[data-loan-amt="${pay.dataset.payloan}"]`);
    const result = await post('payLoan', { loanId: Number(pay.dataset.payloan), amount: Number(input && input.value) });
    if (result && result.ok) { if (result.loans) state.data.loans = result.loans; mergePlayer(result.player); render(); }
    return;
  }
  const bank = event.target.closest('[data-bank]');
  if (bank) {
    const amt = Number(document.getElementById('bank-amt') && document.getElementById('bank-amt').value);
    const result = await post(bank.dataset.bank, { amount: amt });
    if (result && result.ok) { mergePlayer(result.player); render(); }
    return;
  }
  if (event.target.closest('[data-rename]')) {
    const name = document.getElementById('rename-input').value;
    const result = await post('rename', { name });
    if (result && result.ok) { mergePlayer(result.player); toast('Company renamed.'); render(); }
    return;
  }
  if (event.target.closest('[data-insure]')) {
    const result = await post('insurance', {});
    if (result && result.ok) { mergePlayer(result.player); render(); }
    return;
  }
  if (event.target.closest('[data-create]')) {
    const result = await post('partyCreate', {});
    if (result && result.party) state.data.party = result.party;
    render();
    return;
  }
  if (event.target.closest('[data-leave]')) {
    const result = await post('partyLeave', {});
    if (result && result.party) state.data.party = result.party;
    render();
    return;
  }
  const invite = event.target.closest('[data-invite]');
  if (invite) {
    await post('partyInvite', { target: Number(invite.dataset.invite) });
    toast('Invite sent.');
  }
});

window.addEventListener('message', (event) => {
  const msg = event.data || {};
  if (msg.action === 'open') openUi(msg.data);
  if (msg.action === 'close') {
    app.classList.add('hidden');
    app.setAttribute('aria-hidden', 'true');
  }
  if (msg.action === 'hud') showHud(msg.data);
});

window.addEventListener('keydown', (event) => {
  if (event.key === 'Escape' && !app.classList.contains('hidden')) closeUi();
});

if (!inFiveM) {
  document.body.classList.add('preview');
  openUi(DEMO);
  showHud({ show: true, cargo: 'Refrigerated Food', dest: 'Sandy Airfield', kind: 'freight', status: 'Deliver', integrity: 86 });
}

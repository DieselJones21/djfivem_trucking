# DJ FiveM Trucking

Tebex-ready logistics career for **Qbox** (and QBCore / ESX). Players start on rental **Quick Jobs**, bank money, buy a truck, then run **Freight Jobs** on their own iron. Progression, certifications, parties, NPC drivers, loans, damage, and Discord webhooks are all included.

The tablet UI matches the DJ FiveM fishing / hunting shell — chrome + red-orange instead of cyan or hunting red — and is branded with the DJ FiveM Scripts crown logo.

There is **one clerk ped** on the map, at Port of Los Santos HQ. Every other yard is only a load / drop-off pad.

## Requirements

| Resource | Required | Notes |
| --- | --- | --- |
| [ox_lib](https://github.com/overextended/ox_lib) | Yes | Callbacks, locales, progress, points |
| [oxmysql](https://github.com/overextended/oxmysql) | Yes | Profiles, trucks, loans, employees |
| [qbx_core](https://github.com/Qbox-project/qbx_core) | Recommended | First-class. Auto-detected |
| [qbx_vehiclekeys](https://github.com/Qbox-project/qbx_vehiclekeys) | Recommended | `GiveKeys` / `RemoveKeys` on the spawned entity |
| [interact](https://github.com/darktrovx/interact) | Optional | Same depot ped targeting as fishing / hunting |
| qb-core / es_extended | Optional | Fallback frameworks |
| ox_inventory | Optional | Money-as-item fallback |

Qbox is officially supported. `framework.lua` is the only file you need to touch if you use a custom banking or key resource.

## Install

1. Drop `djfivem_trucking` into `resources`.
2. Run `sql/install.sql` **or** just start the resource — tables are created automatically.
3. Add to `server.cfg`:

```cfg
ensure ox_lib
ensure oxmysql
ensure qbx_core
ensure qbx_vehiclekeys
ensure djfivem_trucking
```

4. Paste Discord webhook URLs in `config.lua` → `Config.Webhooks`.
5. Restart the server. Look for `DJ Logistics | Framework: qbx | Keys: qbx_vehiclekeys`.

## Player loop

```
New driver
  → Quick Jobs (rental truck + deposit)
  → Earn money + XP
  → Unlock certs / skill tree
  → Buy a truck at the dealership
  → Freight Jobs (owned truck, higher pay, repair bills)
  → Name the company, deposit operating cash
  → Hire NPC drivers
  → Optionally take a loan
  → Build a logistics company
```

### Job types

- **Quick Jobs** — company rents the truck. Deposit is held and returned if the rental is not wrecked.
- **Freight Jobs** — player uses an owned truck. Higher payout. Damage becomes a repair bill.
- **Daily contracts** — three bonus lanes that refresh at midnight.

### Cargo / certifications

| Cargo | Cert | Default unlock |
| --- | --- | --- |
| General Freight | CDL Class B | Level 1 (auto) |
| Refrigerated Food | Reefer Ticket | Level 2 + 1 skill point |
| Machinery | Heavy Equipment | Level 4 |
| Chemicals | Hazmat Endorsement | Level 6 |
| Flammable Liquids | Tanker Endorsement | Level 8 |
| High-Value Cargo | High-Value Permit | Level 10 |

Rough driving drops **cargo integrity**, which cuts the payout. Fuel and chemicals also have a speed soft-cap.

### Skills

Heavy Hauler, Cargo Care, Yard Mechanic, Long Haul, Convoy Lead, Freight Broker, Dispatcher, Note Negotiator. Points come from leveling (bonus points at 5 / 10 / 15 / 20).

### Fleet

Buy / sell / take out / store / repair. Diagnostics track body, engine, and mileage. Company insurance discounts repairs.

### Crews

Create a party at the depot, invite nearby players, run the haul together. Host gets the main ticket; members get a share plus convoy bonus.

### Company

Rename, company bank, insurance, NPC drivers (simulated ticks — they do not wander the map), loans with a flat daily fee.

## Custom trucks (spawn codes)

Your addon pack is already in `data/trucks.lua`. `model` **is** the spawn code. `_hi.yft` files are LODs, not extra vehicles. `brickades+.ytd` is a texture for `brickades`.

| Spawn | Role | Level |
| --- | --- | --- |
| `mule` / `benson` | Vanilla starter rentals (always stream) | 1 / 3 |
| `linerunner` | Addon long-nose tractor | 4 |
| `blacktop` | Addon heavy / plant | 6 |
| `aerocab` | Addon sleeper, fuel lanes | 8 |
| `vetirs` | Addon 6x6, no trailer | 10 |
| `brickades` | Addon armored, high-value | 12 |

Ensure the vehicle pack **before** this resource. If a spawn fails, the tablet tells you which code was missing.

Trailer models live in `Config.Trailers` and are mapped per cargo class (`tanker`, `trailers2`, `tr2`, …).

## Qbox vehicle keys

`framework.lua` calls, in order:

1. `exports.qbx_vehiclekeys:GiveKeys(src, vehicle, skipNotification)`
2. `exports['qb-vehiclekeys']:GiveKeys(src, plate)`
3. Common `vehiclekeys:client:SetOwner` fallback

Keys are given when a rental or owned truck is spawned, and removed when a rental job ends.

## Webhooks

`Config.Webhooks` groups:

| Key | Events |
| --- | --- |
| `jobs` | start, complete, fail, party create/join |
| `fleet` | buy, sell, repair |
| `company` | rename, hire, fire, NPC settle, insurance |
| `money` | deposits, withdrawals, loans, fees, rental deposits |
| `progression` | level up, skill rank, certification |
| `admin` | XP grants, data reset |

Leave a URL empty to disable that group. Requests are queued so Discord rate limits do not hitch the server.

## Economy

Tune `Config.Economy` against your other civilian jobs:

- `payoutScale` / `xpScale` — global
- `quickJobPay` / `freightJobPay` — job type split
- `fuelCostPerKm`, `repairPerDamage`, `rentalDeposit`
- `partyShare`, `convoyBonus`, `nightBonus`

Do **not** edit payouts on the client. Every dollar and XP tick is server-authoritative.

## Commands

| Command | Who | What |
| --- | --- | --- |
| `/trucking` | Players at a depot | Open the tablet |
| `/truckingcancel` | Players on a haul | Cancel the current job (penalty). Use this if the truck vanishes and the clerk looks unresponsive. |
| `/truckingadmin givexp [id] [amount]` | ACE `djfivem.trucking.admin` | Grant XP |
| `/truckingadmin setxp [id] [amount]` | Admin | Set XP |
| `/truckingadmin reset [id]` | Admin | Wipe that character's trucking data |

ACE example:

```cfg
add_ace group.admin djfivem.trucking.admin allow
```

## Exports

```lua
exports.djfivem_trucking:GetProfile(source)
exports.djfivem_trucking:IsOnJob(source)
exports.djfivem_trucking:AddXP(source, amount, reason)
```

## Editable files

| File | Purpose |
| --- | --- |
| `config.lua` | Economy, webhooks, keys, brand |
| `framework.lua` | Framework money, citizenid, qbx keys |
| `data/trucks.lua` | Spawn codes and prices |
| `data/cargo.lua` | Cargo classes |
| `data/routes.lua` | Depot coords |
| `data/skills.lua` | Skill tree + certs |
| `data/employees.lua` | NPC roster |
| `locales/en.json` | Translations |
| `html/` | Tablet UI |

Only server gameplay logic needs to stay closed if you escrow this for Tebex. Everything listed above is meant to stay open.

## Depots

**One clerk** at Port of Los Santos HQ opens the tablet (clipboard ped, or **E** if `interact` is not started). La Mesa, LSIA, Sandy, Paleto, and the other yards are delivery pads only — no extra peds.

## Performance

- Depot peds and blips spawn once.
- Delivery thread sleeps 800ms when idle and only draws markers near the load point.
- Damage / integrity reports every 4 seconds, not every frame.
- Webhooks are queued.
- Profiles cache in memory and flush every 60 seconds or on drop.

## Preview the UI

Open `html/index.html` in a browser (or serve the `html` folder). Outside FiveM the tablet loads demo data so you can click every tab.

## Support

DJ FiveM Scripts — DieselJones21

# bcc-water

`bcc-water` gives players a complete water system for RedM servers running VORP. Players can carry water, fill containers, drink, wash, clean dirty water, and treat sickness caused by unsafe water.

## What Players Can Do

- Fill canteens, bottles, and buckets at pumps, sinks, rivers, and lakes.
- Drink straight from pumps or natural water sources.
- Get several drinks or uses from each full container.
- Clean dirty water with purification items such as tablets.
- Wash at pumps or in natural water.
- Use soap when the server requires it.
- Get sick from dirty water and use an antidote before the sickness becomes fatal.
- Fill several bottles or buckets at once with a simple arrow menu.

Containers also wear out over time. Their durability follows them when they change between full and empty, so a worn bucket does not become new again after it is emptied or refilled.

## What You Need

- [vorp_core](https://github.com/VORPCORE/vorp-core-lua)
- [vorp_inventory](https://github.com/VORPCORE/vorp_inventory-lua)
- [oxmysql](https://github.com/overextended/oxmysql)
- [bcc-utils](https://github.com/BryceCanyonCounty/bcc-utils)
- [feather-menu](https://github.com/FeatherFramework/feather-menu)

Make sure these resources start before `bcc-water`.

## Installation

1. Put the `bcc-water` folder in your server's resources folder.
2. Copy the images from `bcc-water/img` to the VORP Inventory item image folder.
3. Open `shared/configs/main.lua` and adjust the settings for your server.
4. Add the water items to your shops, crafting recipes, or another way for players to obtain them.
5. Start `bcc-water` after its dependencies and your metabolism resource:

```cfg
ensure bcc-water
```

6. Restart the server.

## Setting Up the Database

The resource can add its standard items to the database for you. This is enabled by default:

```lua
Config.autoSeedDatabase = true
```

The item names come from your current config. The setup also includes the first antidote, first soap item, and first item required by the `tablets` purification method.

If you add more antidotes, soaps, or purification ingredients, you will need to add those extra items to the VORP Inventory `items` table yourself.

All item updates are handled together. If one fails, none of them are saved and the database version is not moved forward.

### Server Console Commands

Run these from the server console, not from the in-game chat:

```text
bcc-water:seed
bcc-water:verify
```

- `bcc-water:seed` creates or updates the standard configured items.
- `bcc-water:verify` checks the database and lists any standard configured items that are missing.

## Configuration

Most settings are in [shared/configs/main.lua](shared/configs/main.lua). The natural water areas are listed in [shared/configs/locations.lua](shared/configs/locations.lua).

Here are the main settings server owners will likely want to change:

| Setting | What it controls |
| --- | --- |
| `Config.app` | The metabolism or HUD script that receives thirst updates. |
| `Config.showMessages` | Player messages for successful actions, problems, and broken items. |
| `Config.usePrompt` | Hold prompts or floating key text. |
| `Config.pump` | What players can do at pumps and sinks. |
| `Config.wild` | What players can do at rivers and lakes, including whether the water is dirty. |
| `Config.objects` | The world objects treated as pumps or sinks. |
| `Config.useable` | Which filled containers and antidotes players can use from their inventory. |
| `Config.durability` | Starting durability and wear from each use. |
| `Config.usesPerFill` | How many drinks or uses a full container provides. |
| `Config.useCooldowns` | How long a player must wait between uses, in milliseconds. |
| `Config.purification` | Purification methods, animations, and required items. |
| `Config.sickness` | The chance, damage, timing, and fatal limit for dirty-water sickness. |
| `Config.soapItem` | Soap items accepted by the washing system. |
| `Config.requireSoap` | Whether players need soap to wash. |
| `Config.consumeSoap` | Whether soap wears out and is eventually removed. |
| `Config.canteenDrink` | Health, stamina, and thirst gained from clean water. |
| `Config.wildDrink` | Health, stamina, and thirst changes from dirty or natural water. |

For a live server, set `Config.devMode.active` to `false` unless you need the development command and extra debug messages.

## How Containers Work

Every filled container keeps track of two separate values:

- Uses left tells the script how much water remains.
- Durability tells the script how worn the container is.

Each accepted use removes one water use and lowers durability by the amount in your config.

When a bucket or bottle runs out of water, it becomes the matching empty item. Its remaining durability carries over to that empty item. If durability reaches zero, the container breaks and no empty item is returned.

A canteen stays as the same inventory item. Its water type, drinks left, and durability are stored in its item information.

## Dirty Water and Purification

When `Config.wild.dirtyItems` is enabled, water collected from rivers and lakes is dirty. Drinking it can make the player sick based on `Config.sickness.chance`.

Dirty containers show a purification option in VORP Inventory for each method you enable. Before cleaning the water, the server checks that the player selected a valid dirty container and has the required ingredients.

Cleaning the water:

- Changes the water from dirty to clean.
- Keeps the same number of drinks or uses.
- Keeps the container's current durability.
- Uses the required ingredient only after the server approves the action.

You can add more choices under `Config.purification.methods`. Each choice can have its own button name and required items.

## Sickness and Antidotes

Sickness does not disappear simply because the player waits. Once a player becomes sick, they must use a valid antidote or die. If they reach the time limit in `Config.sickness.duration`, the sickness becomes fatal.

Add accepted antidote item names to `Config.antidoteItems`. When `Config.useable.antidotes` is enabled, players can use each listed antidote from their inventory.

### Treating Another Player

Doctor and medic resources can check and treat a patient through server exports. The doctor resource should check the doctor's job, permissions, distance from the patient, and treatment animation before calling them.

```lua
local sick, secondsLeft = exports['bcc-water']:IsPlayerSick(patientSource)
if not sick then
    return
end

local cured, reason = exports['bcc-water']:UseAntidoteOnPlayer(
    doctorSource,
    patientSource,
    antidoteItemId
)
```

`UseAntidoteOnPlayer` checks that the patient is still sick and that the exact item belongs to the doctor and appears in `Config.antidoteItems`. When successful, it removes one antidote from the doctor and cures the patient.

The export returns `true, 'cured'` when treatment succeeds. A failed treatment returns `false` with one of these reasons:

- `invalid_provider`
- `invalid_patient`
- `invalid_item`
- `not_sick`
- `expired`
- `patient_changed_character`
- `remove_failed`
- `item_busy`

These are server-only exports. Do not create a client event that calls the cure without your doctor script first checking permissions and distance.

## Washing and Soap

Players can wash anywhere you have enabled washing for pumps or natural water.

- `Config.requireSoap` stops players from washing without one of the listed soap items.
- `Config.consumeSoap` makes the exact bar of soap wear out with use.
- `Config.soapUses` sets how many washes a new bar provides.

Add accepted soap item names to `Config.soapItem`.

## Metabolism and HUD Support

Choose an option from the `MetabolismApps` list at the top of `shared/configs/main.lua`:

- VORP Metabolism
- Fred Metabolism Free
- Fred Metabolism Paid v1 and v2
- Outsider Needs
- RSD Metabolism
- NXT Metabolism
- Andrade Metabolism
- FX HUD
- Mega Metabolism
- POS Metabolism
- BLN HUD
- SS Metabolism
- BCC CoreHud
- CAS Metabolism

## Using Water from Another Script

Other server scripts can use a filled bucket or bottle through one export. `bcc-water` will handle the water use, durability, cooldown, breakage, and empty container for you.

```lua
local consumed = exports['bcc-water']:ConsumeContainer(source, 'bucket')
if not consumed then
    return
end

-- Continue the other script's action here.
```

### Export Format

```lua
exports['bcc-water']:ConsumeContainer(source, itemType, itemId)
```

| Value | Type | Required | Meaning |
| --- | --- | --- | --- |
| `source` | `number` | Yes | The player's server ID. |
| `itemType` | `string` | Yes | Use `bucket` or `bottle`. |
| `itemId` | `number` | No | The exact VORP Inventory item ID to use. |

The export returns `true` when the container was successfully used. It returns `false` when the request was rejected, such as when the item is missing, invalid, or still on cooldown.

If you do not provide an item ID, `bcc-water` looks for a configured clean or dirty container in the player's inventory:

```lua
local consumed = exports['bcc-water']:ConsumeContainer(source, 'bottle')
```

If the other script already knows which inventory item the player chose, pass its item ID. This prevents the wrong container from being used.

Do not remove, replace, or change the container again in the calling script. `bcc-water` has already handled those changes.

## Credits

Inspired by `green_canteen` and maintained by the BCC Team.

Repository: [BryceCanyonCounty/bcc-water](https://github.com/BryceCanyonCounty/bcc-water)

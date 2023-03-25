# Water

#### Description
Water script for RedM servers using the [VORP framework](https://github.com/VORPCORE).
Crouch and hold still in wild waters to show drink, wash and fill prompts.

#### Features
- Carry a canteen of water to drink
- Drink 4 times from a full canteen
- Quenches thirst when using [vorp_metabolism](https://github.com/VORPCORE/vorp_metabolism-lua)
- Refill canteen at waterpumps, rivers and lakes
- Directly drink from rivers and lakes to save the water in your canteen
- Seperate health, stamina and thirst config values for drinking from canteen and wild waters
- Players can wash in rivers and lakes

#### Dependencies
- [vorp_core](https://github.com/VORPCORE/vorp-core-lua)
- [vorp_inventory](https://github.com/VORPCORE/vorp_inventory-lua)
- [vorp_utils](https://github.com/VORPCORE/vorp_utils)
- [vorp_metabolism](https://github.com/VORPCORE/vorp_metabolism-lua)

#### Installation
- Add `oss_water` folder to your resources folder
- Add `ensure oss_water` to your `resources.cfg`
- Run the included database file `oss_water.sql`
- Add canteen image to: `...\vorp_inventory\html\img`
- Add canteen to a store or crafting station for player use

#### Credits
- green_canteen

#### GitHub
- https://github.com/JusCampin/oss_water
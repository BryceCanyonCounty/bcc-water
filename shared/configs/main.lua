local MetabolismApps <const> = {
    VORP = 'vorp',
    FRED_FREE = 'fred_free',
    OUTSIDER_NEEDS = 'outsider',
    FRED_PAID_V1 = 'fred_paid_v1',
    FRED_PAID_V2 = 'fred_paid_v2',
    RSD_METABOLISM = 'rsd',
    NXT_METABOLISM = 'nxt',
    ANDRADE_METABOLISM = 'andrade',
    FX_HUD = 'fx_hud',
    MEGA_METABOLISM = 'mega',
    POS_METABOLISM = 'pos',
    BLN_HUD = 'bln',
    SS_METABOLISM = 'ss',
    BCC_COREHUD = 'bcc_corehud',
    CAS_METABOLISM = 'cas',
}

Config = {
    -- General
    defaultlang = 'en_lang', -- Locale file to use.
    autoSeedDatabase = true, -- Automatically add the included inventory items to the database.
    showMessages = true,     -- Show success and failure notifications to players.
    usePrompt = true,        -- Use RedM hold prompts; false uses floating key text.

    devMode = {
        active = true,        -- Enable the client restart command and debug messages for testing.
        command = 'WaterDev', -- Command name used when developer mode is enabled.
    },

    -- Metabolism integration
    -- Select one entry from the MetabolismApps table above.
    app = MetabolismApps.VORP, -- Metabolism or HUD integration used for drinking effects.

    -- Interaction controls
    keys = {
        drink       = { code = 0x760A9C6F, char = 'G' }, -- Drink directly from the water source.
        wash        = { code = 0x80F28E95, char = 'L' }, -- Wash at the water source.
        fillBucket  = { code = 0xCEFD9220, char = 'E' }, -- Fill an empty bucket.
        fillBottle  = { code = 0xD3ECF82F, char = 'B' }, -- Fill an empty bottle.
        fillCanteen = { code = 0x27D1C284, char = 'R' }, -- Fill the player's canteen.
    },

    -- Pump interactions
    pump = {
        active = true,        -- Enable interactions at configured pump objects.
        canteen = true,       -- Allow canteens to be filled at pumps.
        bucket = true,        -- Allow buckets to be filled at pumps.
        bottle = true,        -- Allow bottles to be filled at pumps.
        wash = true,          -- Allow players to wash at pumps.
        drink = true,         -- Allow players to drink directly from pumps.
        multi = {
            bottles = true,   -- Allow several bottles to be filled in one action.
            bottleAmount = 5, -- Maximum bottles allowed per pump fill action.
            buckets = true,   -- Allow several buckets to be filled in one action.
            bucketAmount = 5, -- Maximum buckets allowed per pump fill action.
        },
    },

    -- River and lake interactions
    wild = {
        active = true,        -- Enable interactions in rivers and lakes.
        canteen = true,       -- Allow canteens to be filled from wild water.
        bucket = true,        -- Allow buckets to be filled from wild water.
        bottle = true,        -- Allow bottles to be filled from wild water.
        wash = true,          -- Allow players to wash in wild water.
        drink = true,         -- Allow players to drink directly from wild water.
        dirtyItems = true,    -- Make wild-filled containers dirty; false makes them clean.
        multi = {
            bottles = true,   -- Allow several bottles to be filled in one action.
            bottleAmount = 5, -- Maximum bottles allowed per wild-water fill action.
            buckets = true,   -- Allow several buckets to be filled in one action.
            bucketAmount = 5, -- Maximum buckets allowed per wild-water fill action.
        },
    },
    crouch = true, -- Require crouching and standing still for wild-water prompts.

    -- Objects treated as water pumps
    objects = {
        'p_waterpump01x',    -- Standard hand-operated water pump.
        'p_wellpumpnbx01x',  -- Well pump.
        'p_sink02x',         -- Sink variant.
        'p_drysink01x',      -- Dry-sink variant.
        'p_sink03x',         -- Sink variant.
        'p_barrel_ladle01x', -- Water barrel with ladle.
        'p_barrel_wash01x',  -- Washing barrel.
    },

    -- Inventory item names
    canteen = 'canteen',                    -- Refillable canteen item.
    emptyBucket = 'wateringcan_empty',      -- Empty bucket received after all water uses.
    cleanBucket = 'wateringcan',            -- Bucket containing clean water.
    dirtyBucket = 'wateringcan_dirtywater', -- Bucket containing dirty water.
    emptyBottle = 'bcc_empty_bottle',       -- Empty bottle received after all water uses.
    cleanBottle = 'bcc_clean_bottle',       -- Bottle containing clean water.
    dirtyBottle = 'bcc_dirty_bottle',       -- Bottle containing dirty water.

    antidoteItems = {
        'antidote', -- Inventory item that cures water sickness.
        -- 'strong_antidote',                         -- Add more valid antidote item names here.
    },
    antidoteAnimation = {
        dictionary = 'mech_inventory@item@fallbacks@tonic@unarmed', -- Tonic-drinking animation dictionary.
        name = 'quick_consume_drink_small',                         -- Animation played when using an antidote.
        duration = 2000,                                            -- Animation time in milliseconds.
    },

    useable = {
        cleanBottle = true, -- Register clean bottles as usable inventory items.
        dirtyBottle = true, -- Register dirty bottles as usable inventory items.
        cleanBucket = true, -- Register clean buckets as usable inventory items.
        dirtyBucket = true, -- Register dirty buckets as usable inventory items.
        antidotes = true,   -- Register every configured antidote as usable.
    },

    -- Container continuity and degradation
    durability = {
        defaults = {
            canteen = 100, -- Starting durability for canteens without durability metadata.
            bucket = 100,  -- Starting durability for buckets without durability metadata.
            bottle = 100,  -- Starting durability for bottles without durability metadata.
        },
        usage = {
            canteen = 5, -- Canteen durability removed per drink.
            bucket = 5,  -- Bucket durability removed per water use.
            bottle = 5,  -- Bottle durability removed per drink.
        },
    },

    usesPerFill = {
        canteen = 5, -- Drinks provided by a full canteen.
        bucket = 5,  -- Water uses provided by a full bucket.
        bottle = 5,  -- Drinks provided by a full bottle.
    },

    -- Minimum time between accepted uses, in milliseconds
    useCooldowns = {
        canteen = 6000, -- Delay between accepted canteen drinks.
        bucket = 6000,  -- Delay between accepted bucket uses.
        bottle = 6000,  -- Delay between accepted bottle drinks.
    },

    purification = {
        enabled = true,                                       -- Enable purification context buttons on dirty containers.
        animation = {
            maleDictionary = 'amb_camp@prop_camp_cauldron_stir@male_a@idle_b',     -- Male purification animation.
            femaleDictionary = 'amb_camp@prop_camp_cauldron_stir@female_a@idle_b', -- Female purification animation.
            name = 'idle_d',                                  -- Stirring animation played during purification.
            duration = 3000,                                  -- Animation time in milliseconds.
        },
        methods = {
            tablets = {
                enabled = true,                                   -- Enable this purification method.
                label = 'Use Purification Tablet',                -- Inventory context-menu button text.
                requiredItems = {
                    { name = 'purification_tablet', amount = 1 }, -- Item and quantity consumed.
                },
            },
        },
    },

    -- Dirty-water sickness. Reaching zero health or the duration limit is fatal.
    sickness = {
        chance = 25,    -- Sickness chance from dirty water, from 0 to 100.
        duration = 600, -- Seconds before untreated sickness becomes fatal.
        interval = 15,  -- Seconds between sickness damage ticks.
        health = 50,    -- Health removed on each sickness tick.
    },

    -- Washing and soap
    soapItem = {
        'bcc_soap_bar', -- Soap item accepted by the washing system.
        -- 'perfumed_soap',       -- Add more accepted soap item names here.
    },
    requireSoap = false, -- Require one configured soap item before washing.
    consumeSoap = true,  -- Track soap uses and remove it when depleted.
    soapUses = 10,       -- Washes provided by newly used soap.

    -- Drinking effects
    canteenDrink = {
        health = 10,  -- Health gained from clean container or pump water; 0 disables.
        stamina = 20, -- Stamina gained from clean container or pump water; 0 disables.
        thirst = 50,  -- Thirst restored through the selected metabolism system.
    },

    wildDrink = {
        gainHealth = true,  -- true adds health; false removes it.
        health = 5,         -- Health changed by dirty or direct wild-water drinking.
        gainStamina = true, -- true adds stamina; false removes it.
        stamina = 10,       -- Stamina changed by dirty or direct wild-water drinking.
        thirst = 25,        -- Thirst restored by dirty or direct wild-water drinking.
    },
}

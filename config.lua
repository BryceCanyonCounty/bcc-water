Config = {}

Config.defaultlang = "en_lang"

-- Fill Canteen at Water Pumps and Wild Waters
Config.fillKey = 0xB2F377E8 -- [F] - 0xB2F377E8

-- Wash Player in Wild Waters
Config.washKey = 0xD9D0E1C0 -- [Space] - 0xD9D0E1C0

-- Drink from Wild Waters
Config.drinkKey = 0x760A9C6F -- [G] - 0x760A9C6F

-- Show / Hide Canteen Level Messages
Config.showMessages = true

-- Boosts Drinking from Canteen
Config.health = 10 -- Default: 10 / Value is 0 - 100

Config.stamina = 20 -- Default: 20 / Value is 0 - 100

Config.thirst = 500 -- Default: 500 / Value is 0 - 1000

-- Boosts Drinking Directly from Wild Waters
Config.wildHealth = 5 -- Default: 5 / Value is 0 - 100

Config.wildStamina = 10 -- Default: 10 / Value is 0 - 100

Config.wildThirst = 250 -- Default: 250 / Value is 0 - 1000

Config.locations = { -- Wild Water Locations
    [1]  = { name = "Sea of Coronado",     hash = -247856387  },
    [2]  = { name = "San Luis River",      hash = -1504425495 },
    [3]  = { name = "Lake Don Julio",      hash = -1369817450 },
    [4]  = { name = "Flat Iron Lake",      hash = -1356490953 },
    [5]  = { name = "Upper Montana River", hash = -1781130443 },
    [6]  = { name = "Owanjila",            hash = -1300497193 },
    [7]  = { name = "HawkEye Creek",       hash = -1276586360 },
    [8]  = { name = "Little Creek River",  hash = -1410384421 },
    [9]  = { name = "Dakota River",        hash =  370072007  },
    [10] = { name = "Beartooth Beck",      hash =  650214731  },
    [11] = { name = "Lake Isabella",       hash =  592454541  },
    [12] = { name = "Cattail Pond",        hash = -804804953  },
    [13] = { name = "Deadboot Creek",      hash =  1245451421 },
    [14] = { name = "Spider Gorge",        hash = -218679770  },
    [15] = { name = "O'Creagh's Run",      hash = -1817904483 },
    [16] = { name = "Moonstone Pond",      hash = -811730579  },
    [17] = { name = "Roanoke Valley",      hash = -1229593481 },
    [18] = { name = "Elysian Pool",        hash = -105598602  },
    [19] = { name = "Heartland Overflow",  hash =  1755369577 },
    [20] = { name = "Lagras",              hash = -557290573  },
    [21] = { name = "Lannahechee River",   hash = -2040708515 },
    [22] = { name = "Random1",             hash =  231313522  },
    [23] = { name = "Random2",             hash =  2005774838 },
    [24] = { name = "Random3",             hash = -1287619521 },
    [25] = { name = "Random4",             hash = -1308233316 },
    [26] = { name = "Random5",             hash = -196675805  }
}
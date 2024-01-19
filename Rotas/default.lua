DPSGenie = LibStub("AceAddon-3.0"):GetAddon("DPSGenie")

--DPSGenie:Print("Default Rotas loaded!")

local defaultRotas = {
    ["Lava Sweep Build"] = {
        ["icon"] = "Interface\\Icons\\spell_shaman_lavasurge",
        ["spells"] = {
            {
                ["spellId"] = 60043,
                ["conditions"] = {
                    {
                        ["subject"] = "Buffs",
                        ["compare_value"] = "4",
                        ["search"] = 53817,
                        ["comparer"] = "more than",
                        ["unit"] = "Player",
                    }, -- [1]
                },
            }, -- [1]
            {
                ["spellId"] = 271579,
                ["conditions"] = {
                },
            }, -- [2]
            {
                ["spellId"] = 285092,
                ["conditions"] = {
                },
            }, -- [3]
            {
                ["spellId"] = 29228,
                ["conditions"] = {
                },
            }, -- [4]
            {
                ["spellId"] = 10199,
                ["conditions"] = {
                },
            }, -- [5]
            {
                ["spellId"] = 17348,
                ["conditions"] = {
                },
            }, -- [6]
        },
        ["name"] = "Lava Sweep Build",
        ["description"] = "Lava Sweep Build - Hezghul on Elune",
    },
    ["Consecrated Strikes"] = {
        name = "Consecrated Strikes",
        description = "Build for Consecrated Strikes", 
        icon = "Interface\\Icons\\ability_paladin_righteousvengeance",
        spells = {
            [1] = {
                spellId = 879,
                conditions = {
                    [1] = {
                        unit = "Player",
                        subject = "Buffs",
                        comparer = "contains",
                        search = 853489
                    },
                },
            },
        }
    },
    ["Aimed Explosive Shot"] = {
        name = "Aimed Explosive Shot",
        description = "Build for Aimed Explosive Shot",
        icon = "Interface\\Icons\\ability_hunter_explosiveshot",
    },
}

function DPSGenie:GetDefaultRotas()
    return defaultRotas
end


DPSGenie = LibStub("AceAddon-3.0"):GetAddon("DPSGenie")

--DPSGenie:Print("Default Rotas loaded!")

local defaultRotas = {
    ["Lava Sweep Build"] = {
        ["icon"] = "Interface\\Icons\\spell_shaman_lavasurge",
        ["spells"] = {
            {
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
            }
        },
        ["name"] = "Lava Sweep Build",
        ["description"] = "Lava Sweep Build - Hezghul on Elune",
    },
    ["Sub Lava Sweep Build"] = {
        ["icon"] = "Interface\\Icons\\spell_shaman_lavasurge",
        ["spells"] = {
             {
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
            {
                {
                    ["spellId"] = 20217,
                    ["conditions"] = {
                        {
                            ["subject"] = "Buffs",
                            ["search"] = 20217,
                            ["comparer"] = "not contains",
                            ["unit"] = "Player",
                        }
                    }, -- [1]
                },
                {
                    ["spellId"] = 20166,
                    ["conditions"] = {
                        {
                            ["subject"] = "Buffs",
                            ["search"] = 20166,
                            ["comparer"] = "not contains",
                            ["unit"] = "Player",
                        }
                    }, -- [2]
                },
            }
        },
        ["name"] = "Sub Lava Sweep Build",
        ["description"] = "Sub Lava Sweep Build - Hezghul on Elune",
    },
    ["Consecrated Strikes"] = {
        name = "Consecrated Strikes",
        description = "Build for Consecrated Strikes", 
        icon = "Interface\\Icons\\ability_paladin_righteousvengeance",
        spells = {
            {
                {
                    spellId = 879,
                    conditions = {
                        {
                            unit = "Player",
                            subject = "Buffs",
                            comparer = "contains",
                            search = 853489
                        },
                    },
                }
            },
        }
    },
    ["Aimed Explosive Shot"] = {
        name = "Aimed Explosive Shot",
        description = "Build for Aimed Explosive Shot",
        icon = "Interface\\Icons\\ability_hunter_explosiveshot",
        spells = {
            {
                {
                    spellId = 14287,
                    conditions = {
                        {
                            unit = "Target",
                            subject = "Buffs",
                            comparer = "contains",
                            search = 25295
                        },
                    },
                }
            },
        }
    },
}

function DPSGenie:GetDefaultRotas()
    return defaultRotas
end


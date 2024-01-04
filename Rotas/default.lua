DPSGenie = LibStub("AceAddon-3.0"):GetAddon("DPSGenie")

DPSGenie:Print("Default Rotas loaded!")

local defaultRotas = {
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
    ["Battle Fervor"] = {
        name = "Battle Fervor",
        description = "Build for Battle Fervor", 
        icon = "Interface\\Icons\\ability_warrior_bloodfrenzy",
    },
    ["Carnage Incarnate"] = {
        name = "Carnage Incarnate",
        description = "Build for Carnage Incarnate", 
        icon = "Interface\\Icons\\spell_druid_bearhug",
    },
}

function DPSGenie:GetDefaultRotas()
    return defaultRotas
end


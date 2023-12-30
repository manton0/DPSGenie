DPSGenie = LibStub("AceAddon-3.0"):GetAddon("DPSGenie")

DPSGenie:Print("Custom Rotas loaded!")

local db
local defaults = {
    profile = {
      setting = true,
    }
  }
db = LibStub("AceDB-3.0"):New("DPSGenieDB", defaults, true)

db.global.customRotas =
{
    ["Test 1"] = {
        name = "Test 1",
        description = "Build for the lulz", 
        icon = "Interface\\Icons\\ability_paladin_righteousvengeance",
    },
    ["Pala / Fire Tank"] =
    {
        name = "Pala / Fire Tank",
        description = "Build for Pala / Fire Tank",
        icon = "Interface\\Icons\\spell_holy_blessingofprotection_red",
        spells = {
            [1] = {
                spellId = 35395,

            },
            [2] = {
                spellId = 19943,
                conditions = {
                    [1] = {
                        pool = "playerBuffs",
                        compare = "contains",
                        what = 853489
                    },
                    [2] = {
                        pool = "playerHP",
                        compare = "less than",
                        what = 80
                    }
                }
            }
        }
    },
}

function DPSGenie:GetCustomRotas()
    return db.global.customRotas
end
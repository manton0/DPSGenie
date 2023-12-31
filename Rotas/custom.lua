DPSGenie = LibStub("AceAddon-3.0"):GetAddon("DPSGenie")

DPSGenie:Print("Custom Rotas loaded!")

local defaultSettings = {
    global = { }
}

function DPSGenie:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("DPSGenieRotaDB", defaultSettings)
    --DPSGenie:SetFewCustomRotas()
end

function DPSGenie:SetFewCustomRotas()
    self.db.global.customRotas =
    {
        ["Test 1"] = {
            name = "Test 1",
            description = "Build for the lulz", 
            icon = "Interface\\Icons\\ability_paladin_righteousvengeance",
            spells = {} 
        },
        ["Pala / Fire Tank"] =
        {
            name = "Pala / Fire Tank",
            description = "Build for Pala / Fire Tank",
            icon = "Interface\\Icons\\spell_holy_blessingofprotection_red",
            spells = {
                [1] = {
                    spellId = 35395,
                    conditions = {},
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
end

function DPSGenie:GetCustomRotas()
    return self.db.global.customRotas
end

function DPSGenie:SaveCustomRota(rota, data)
    self.db.global.customRotas[rota] = data
end
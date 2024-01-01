DPSGenie = LibStub("AceAddon-3.0"):GetAddon("DPSGenie")

DPSGenie:Print("Custom Rotas loaded!")

local defaultSettings = {
    global = { }
}

function DPSGenie:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("DPSGenieRotaDB", defaultSettings)
    --DPSGenie:SetTestCustomRotas()
end

function DPSGenie:SetTestCustomRotas()
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
                    spellId = 285790,
                    conditions = {
                        [1] = {
                            unit = "Player",
                            subject = "Buffs",
                            comparer = "less than",
                            compare_value = "3",
                            search = 285789
                        },
                    },
                }, 
                [2] = {
                    spellId = 19943,
                    conditions = {
                        [1] = {
                            unit = "Player",
                            subject = "Buffs",
                            comparer = "contains",
                            search = 853489
                        },
                        [2] = {
                            unit = "Player",
                            subject = "Health",
                            comparer = "less than",
                            search = 80
                        },
                    },
                },
                [3] = {
                    spellId = 35395,
                },
            },
        },
    }
end

function DPSGenie:GetCustomRotas()
    return self.db.global.customRotas
end

function DPSGenie:SaveCustomRota(rota, data)
    self.db.global.customRotas[rota] = data
end
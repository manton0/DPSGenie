DPSGenie = LibStub("AceAddon-3.0"):GetAddon("DPSGenie")

DPSGenie:Print("Custom Rotas loaded!")

local defaultSettings = {
    global = { customRotas = {} }
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


local baselayout = {
    name = "",
    description = "", 
    icon = "Interface\\Icons\\INV_Misc_QuestionMark",
    spells = {} 
}

function DPSGenie:CreateNewRota(name, descr)
    if descr == nil or descr == "" then descr = name end
    baselayout.name = name
    baselayout.description = descr
    local baseRota = DPSGenie:deepcopy(baselayout)
    self.db.global.customRotas[name] = baseRota
end

function DPSGenie:GetCustomRotas()
    return self.db.global.customRotas
end

function DPSGenie:GetCustomRota(name)
    return self.db.global.customRotas[name] or false
end

function DPSGenie:SaveCustomRota(rota, data)
    self.db.global.customRotas[rota] = data
end


--TODO: copy and import should check for name collisions / display name change popup
function DPSGenie:CopyRotaToCustom(rota)
    local rotaCopy = DPSGenie:deepcopy(rota)
    local rotaName = "Copy of " .. rota.name
    rotaCopy.name = rotaName
    self.db.global.customRotas[rotaName] = rotaCopy
end

function DPSGenie:ImportRotaToCustom(rota)
    local rotaCopy = DPSGenie:deepcopy(rota)
    local rotaName = "Import " .. rota.name
    rotaCopy.name = rotaName
    self.db.global.customRotas[rotaName] = rotaCopy
end

function DPSGenie:DeleteCustomRota(rotaName)
    self.db.global.customRotas[rotaName] = nil
end
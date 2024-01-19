local addonName, ns = ...
DPSGenie = LibStub("AceAddon-3.0"):NewAddon("DPSGenie", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")

local optionsFrame

local options = {
    name = "DPSGenie",
    handler = DPSGenie,
    type = 'group',
    args = {
        config = {
            guiHidden = true,
            type = "execute",
            name = "Show Addon Config",
            func = function()
                --InterfaceOptionsFrame_OpenToCategory(optionsFrame)
                DPSGenie:showRotaBuilder()
            end
        },
        capture = {
            guiHidden = true,
            type = "execute",
            name = "Show Spell Capture Window",
            func = function()
                DPSGenie:showCapture()
            end
        },
        rota = {
            guiHidden = true,
            type = "execute",
            name = "Show Rota Setup Window",
            func = function()
                DPSGenie:showRotaBuilder()
            end
        },
        debug = {
            guiHidden = true,
            type = "execute",
            name = "Toggle Debug Window",
            func = function()
                DPSGenie:toggleDebug()
            end
        },
        showOutOfRange = {
            name = "showOutOfRange",
            desc = "Shows Spells if out of range?",
            type = "toggle",
            set = function(info, val) DPSGenie:SaveSettingToProfile("showOutOfRange", val) end,
            get = function(info) return DPSGenie:LoadSettingFromProfile("showOutOfRange") end
        },
        showEmpty = {
            name = "showEmpty",
            desc = "Shows Spellbutton if has no spell?",
            type = "toggle",
            set = function(info, val) DPSGenie:SaveSettingToProfile("showEmpty", val) end,
            get = function(info) return DPSGenie:LoadSettingFromProfile("showEmpty") end
        },
    },
}


LibStub("AceConfig-3.0"):RegisterOptionsTable("DPSGenie", options, {"dps", "dpsgenie"})
optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("DPSGenie", "DPSGenie")

local defaultSettings = {
    global = { customRotas = {} },
    char = {
        showOutOfRange = true,
        showEmpty = false,
    }
}

function DPSGenie:OnInitialize()
    --self.db = LibStub("AceDB-3.0"):New("DPSGenieDB", defaultSettings)
    self.db = LibStub("AceDB-3.0"):New("DPSGenieRotaDB", defaultSettings)
end

function DPSGenie:SaveSettingToProfile(setting, value)
    --print("setting " .. setting .. " -> " .. tostring(value))
    self.db.char[setting] = value;
end

function DPSGenie:LoadSettingFromProfile(setting)
    --print("getting " .. setting .. " -> " .. (tostring(self.db.char[setting]) or "flase"))
    return self.db.char[setting] or false;
end

function DPSGenie:OnEnable()
    
end

function DPSGenie:OnDisable()
    
end
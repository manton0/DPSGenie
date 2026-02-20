local addonName, ns = ...
DPSGenie = LibStub("AceAddon-3.0"):NewAddon("DPSGenie", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")

local options = {
    name = "DPSGenie",
    handler = DPSGenie,
    type = 'group',
    args = {
        settings = {
            guiHidden = true,
            type = "execute",
            name = "Open Settings",
            func = function()
                DPSGenie:showRotaBuilder("settings")
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
    },
}

LibStub("AceConfig-3.0"):RegisterOptionsTable("DPSGenie", options, {"dps", "dpsgenie"})

local defaultSettings = {
    global = { customRotas = {} },
    char = {
        showOutOfRange = true,
        showEmpty = false,
        showSpellFlash = true,
        showKeybind = true,
        showPrediction = false,
        spellFlashType = "default",
        onlyInCombat = false,
        onlyWithTarget = false,
    }
}

function DPSGenie:OnInitialize()
    --self.db = LibStub("AceDB-3.0"):New("DPSGenieDB", defaultSettings)
    self.db = LibStub("AceDB-3.0"):New("DPSGenieRotaDB", defaultSettings)

    -- Register with the shared Genie minimap button
    local GenieMinimap = LibStub("GenieMinimap-1.0", true)
    if GenieMinimap then
        GenieMinimap:Register("DPSGenie", {
            { label = "Rotation Editor", onClick = function() DPSGenie:showRotaBuilder() end },
            { label = "Spell Capture",   onClick = function() DPSGenie:showCapture() end },
            { label = "Settings",        onClick = function() DPSGenie:showRotaBuilder("settings") end },
        })
    end
end

function DPSGenie:SaveSettingToProfile(setting, value)
    --print("setting " .. setting .. " -> " .. tostring(value))
    self.db.char[setting] = value;
end

function DPSGenie:LoadSettingFromProfile(setting)
    --print("getting " .. setting .. " -> " .. (tostring(self.db.char[setting]) or "flase"))
    if self.db.char[setting] ~= nil then
        return self.db.char[setting];
    else
        return defaultSettings.char[setting]
    end
end

-- OnEnable and OnDisable are defined in Core.lua (single lifecycle owner)
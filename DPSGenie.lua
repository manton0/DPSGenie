DPSGenie = LibStub("AceAddon-3.0"):NewAddon("DPSGenie", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")

local optionsFrame
local db

local options = {
    name = "DPSGenie",
    handler = DPSGenie,
    type = 'group',
    args = {
        config = {
            type = "execute",
            name = "Show Addon Config",
            func = function()
                InterfaceOptionsFrame_OpenToCategory(optionsFrame)
            end
        },
        msg = {
            type = 'input',
            name = 'My Message',
            desc = 'The message for my addon',
            set = 'SetMyMessage',
            get = 'GetMyMessage',
        },
        showCapture = {
            type = "execute",
            name = "Show Spell Capture Window",
            func = function()
                DPSGenie:Print("would show spell capture window now!")
                DPSGenie:showCapture()
            end
        }
    },
}


function DPSGenie:GetMyMessage(info)
    return db.profile.message
end

function DPSGenie:SetMyMessage(info, input)
    print("set msg to: " .. input)
    db.profile.message = input
end


LibStub("AceConfig-3.0"):RegisterOptionsTable("DPSGenie", options, {"dps", "dpsgenie"})
optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("DPSGenie", "DPSGenie")

function DPSGenie:OnInitialize()
    local defaults = {
        profile = {
          setting = true,
        }
      }
    db = LibStub("AceDB-3.0"):New("DPSGenieDB", defaults, true)
end

function DPSGenie:OnEnable()
    
end

function DPSGenie:OnDisable()
    
end
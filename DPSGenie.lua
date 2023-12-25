DPSGenie = LibStub("AceAddon-3.0"):NewAddon("DPSGenie", "AceConsole-3.0")
DPSGenieConsole = LibStub("AceConsole-3.0")

-- Überprüfe, ob addon.spellSet existiert, andernfalls initialisiere es
DPSGenie.spellSet = DPSGenie.spellSet or {}
DPSGenie.buffList = DPSGenie.buffList or {}

function DPSGenie:OnInitialize()
    -- Code that you want to run when the addon is first loaded goes here.
end


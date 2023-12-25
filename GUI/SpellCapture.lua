DPSGenie = LibStub("AceAddon-3.0"):GetAddon("DPSGenie")

DPSGenie:Print("SpellCapture loaded!")

local AceGUI = LibStub("AceGUI-3.0")
local Captureframe

DPSGenie.spellSet = DPSGenie.spellSet or {}
DPSGenie.buffList = DPSGenie.buffList or {}

function DPSGenie:showCapture()
    Captureframe = AceGUI:Create("Frame")
    Captureframe:SetTitle("DPSGenie Spell Capture")
    --Captureframe:SetStatusText("AceGUI-3.0 Example Container Frame")

    local button = AceGUI:Create("Button")
    button:SetText("Start Capture")
    button:SetWidth(200)
    button:SetCallback("OnClick", function() DPSGenie:startSpellCapture() end)
    Captureframe:AddChild(button)
end

function DPSGenie:startSpellCapture()
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    DPSGenie:Print("Register COMBAT_LOG_EVENT_UNFILTERED...")
end

function DPSGenie:stopSpellCapture()
    self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    DPSGenie:Print("Unregister COMBAT_LOG_EVENT_UNFILTERED...")
end

function DPSGenie:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
    local time, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags = select(1, ...)
    if event:sub(1, 5) == "SPELL" then
        local spellId, spellName = select(9, ...)
        local _, _, spellIcon = GetSpellInfo(spellId)
        -- Überprüfe, ob das Event von einem Spieler stammt
        if sourceName == UnitName("player") then
            -- Wenn es sich um einen Spell handelt, füge ihn zum Set hinzu
            if event == "SPELL_DAMAGE" and not DPSGenie.spellSet[spellId] then
                DPSGenie.spellSet[spellId] = {id = spellId, name = spellName, icon = spellIcon}
                local label = AceGUI:Create("Label")
                label:SetWidth(300)
                label:SetImage(spellIcon)
                label:SetImageSize(32, 32)
                label:SetText(spellId .. " - " .. spellName)
                Captureframe:AddChild(label)
                DPSGenie:SetFirstSuggestSpell(spellIcon)
            end
            -- Wenn es sich um eine Aura handelt, füge sie zur Buff-Liste hinzu
            if (event == "SPELL_AURA_APPLIED" or event == "SPELL_AURA_REFRESH") and not DPSGenie.buffList[spellId] then
                local spellId, spellName, spellSchool, auraType = select(9, ...)
                DPSGenie.buffList[spellId] = {id = spellId, name = spellName, icon = spellIcon, type = auraType}
                -- Füge hier die Aktualisierung der Buff-Liste in der GUI hinzu, wenn nötig
            end
        end
    end
end

function DPSGenie:PrintLists()
    print("Spell Set:")
    for _, spell in pairs(DPSGenie.spellSet) do
        print(string.format("ID: %d, Name: %s", spell.id, spell.name))
    end

    print("Buff List:")
    for _, buff in pairs(DPSGenie.buffList) do
        print(string.format("ID: %d, Name: %s, Type: %s", buff.id, buff.name, buff.type))
    end
end
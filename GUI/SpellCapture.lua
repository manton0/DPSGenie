DPSGenie = LibStub("AceAddon-3.0"):GetAddon("DPSGenie")

DPSGenie:Print("SpellCapture loaded!")

local AceGUI = LibStub("AceGUI-3.0")
local Captureframe
local startButton, stopButton

DPSGenie.spellSet = DPSGenie.spellSet or {}
DPSGenie.buffList = DPSGenie.buffList or {}

function DPSGenie:showCapture()
    Captureframe = AceGUI:Create("Frame")
    Captureframe:SetTitle("DPSGenie Spell Capture")
    --Captureframe:SetStatusText("AceGUI-3.0 Example Container Frame")

    startButton = AceGUI:Create("Button")
    startButton:SetText("Start Capture")
    startButton:SetWidth(200)
    startButton:SetCallback("OnClick", function() DPSGenie:startSpellCapture() end)
    Captureframe:AddChild(startButton)

    stopButton = AceGUI:Create("Button")
    stopButton:SetText("Stop Capture")
    stopButton:SetWidth(200)
    stopButton:SetCallback("OnClick", function() DPSGenie:stopSpellCapture() end)
    stopButton:SetDisabled(true)
    Captureframe:AddChild(stopButton)
end

function DPSGenie:startSpellCapture()
    startButton:SetDisabled(true)
    stopButton:SetDisabled(false)
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    DPSGenie:Print("Register COMBAT_LOG_EVENT_UNFILTERED...")
end

function DPSGenie:stopSpellCapture()
    startButton:SetDisabled(false)
    stopButton:SetDisabled(true)
    self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    DPSGenie:Print("Unregister COMBAT_LOG_EVENT_UNFILTERED...")
end

function DPSGenie:addSpellToCaptureList(spellId, spellName, spellIcon, spellType)
    local label = AceGUI:Create("Label")
    label:SetWidth(300)
    label:SetImage(spellIcon)
    label:SetImageSize(32, 32)
    label:SetText(spellId .. " - " .. spellName .. " - " .. spellType)
    Captureframe:AddChild(label)
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
                DPSGenie:addSpellToCaptureList(spellId, spellName, spellIcon, "SPELL")
                DPSGenie:SetFirstSuggestSpell(spellIcon)
            end
            -- Wenn es sich um eine Aura handelt, füge sie zur Buff-Liste hinzu
            if (event == "SPELL_AURA_APPLIED" or event == "SPELL_AURA_REFRESH") and not DPSGenie.buffList[spellId] then
                local spellId, spellName, spellSchool, auraType = select(9, ...)
                DPSGenie.buffList[spellId] = {id = spellId, name = spellName, icon = spellIcon, type = auraType}
                DPSGenie:addSpellToCaptureList(spellId, spellName, spellIcon, string.upper(auraType))
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
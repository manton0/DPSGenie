DPSGenie = LibStub("AceAddon-3.0"):GetAddon("DPSGenie")

DPSGenie:Print("SpellButton loaded!")

-- AnnounceButtonAddon.lua

local AceGUI = LibStub("AceGUI-3.0")

local FirstSpellFrame, SecondSpellFrame
local DPSGenieButtonHolderFrame1, DPSGenieButtonHolderFrame2

function DPSGenie:SetFirstSuggestSpell(spellId)
    if not spellId then
        FirstSpellFrame:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    else
        local name, rank, icon, castTime, minRange, maxRange, spellID, originalIcon = GetSpellInfo(spellId)
        FirstSpellFrame:SetTexture(icon)
        FirstSpellFrame:SetAllPoints(true)
    end
end

function DPSGenie:SetSecondSuggestSpell(spellId)
    if not spellId then
        SecondSpellFrame:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    else
        local name, rank, icon, castTime, minRange, maxRange, spellID, originalIcon = GetSpellInfo(spellId)
        SecondSpellFrame:SetTexture(icon)
        SecondSpellFrame:SetAllPoints(true)
    end
end

-- Erstelle das Hauptframe des Addons
local DPSGenieButtonHolderFrame = CreateFrame("Frame", "DPSGenieButtonHolderFrame", UIParent)
DPSGenieButtonHolderFrame:SetSize(300, 84)
DPSGenieButtonHolderFrame:SetPoint("TOP", UIParent, "TOP", 0, -10) -- Setze den Frame oben und verschiebe ihn um 10 Pixel nach unten
DPSGenieButtonHolderFrame:SetMovable(true)
DPSGenieButtonHolderFrame:EnableMouse(true)
DPSGenieButtonHolderFrame:RegisterForDrag("LeftButton")
DPSGenieButtonHolderFrame:SetScript("OnDragStart", DPSGenieButtonHolderFrame.StartMoving)
DPSGenieButtonHolderFrame:SetScript("OnDragStop", DPSGenieButtonHolderFrame.StopMovingOrSizing)

-- Rahmen und Hintergrund für den Hauptframe hinzufügen
DPSGenieButtonHolderFrame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
DPSGenieButtonHolderFrame:SetBackdropColor(0, 0, 0, 0.7)

-- Erstelle den ersten Frame mit Textur
DPSGenieButtonHolderFrame1 = CreateFrame("Frame", "DPSGenieButtonHolderFrame1", DPSGenieButtonHolderFrame)
DPSGenieButtonHolderFrame1:SetSize(64, 64)
DPSGenieButtonHolderFrame1:SetPoint("TOPLEFT", DPSGenieButtonHolderFrame, "TOPLEFT", 10, -10)

DPSGenieButtonHolderFrame1.text = DPSGenieButtonHolderFrame1:CreateFontString(nil, "OVERLAY", "GameFontNormal")
DPSGenieButtonHolderFrame1.text:SetPoint("BOTTOMLEFT", DPSGenieButtonHolderFrame1, "BOTTOMLEFT", 5, 5)
DPSGenieButtonHolderFrame1.text:SetTextColor(1, 1, 1, 1)
DPSGenieButtonHolderFrame1.text:SetText("1")

FirstSpellFrame = DPSGenieButtonHolderFrame1:CreateTexture(nil, "ARTWORK")
FirstSpellFrame:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
FirstSpellFrame:SetAllPoints(true)


-- Erstelle den zweiten Frame mit Textur
DPSGenieButtonHolderFrame2 = CreateFrame("Frame", "DPSGenieButtonHolderFrame2", DPSGenieButtonHolderFrame)
DPSGenieButtonHolderFrame2:SetSize(64, 64)
DPSGenieButtonHolderFrame2:SetPoint("TOPLEFT", DPSGenieButtonHolderFrame, "TOPLEFT", 79, -10)

DPSGenieButtonHolderFrame2.text = DPSGenieButtonHolderFrame2:CreateFontString(nil, "OVERLAY", "GameFontNormal")
DPSGenieButtonHolderFrame2.text:SetPoint("BOTTOMLEFT", DPSGenieButtonHolderFrame2, "BOTTOMLEFT", 5, 5)
DPSGenieButtonHolderFrame2.text:SetTextColor(1, 1, 1, 1)
DPSGenieButtonHolderFrame2.text:SetText("2")

SecondSpellFrame = DPSGenieButtonHolderFrame2:CreateTexture(nil, "ARTWORK")
SecondSpellFrame:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
SecondSpellFrame:SetAllPoints(true)



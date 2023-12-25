DPSGenie = LibStub("AceAddon-3.0"):GetAddon("DPSGenie")

DPSGenie:Print("SpellButton loaded!")

-- AnnounceButtonAddon.lua

local AceGUI = LibStub("AceGUI-3.0")
local addonFrameName = "DPSGenieSpellSuggest"

local texture1, texture2

function DPSGenie:SetFirstSuggestSpell(path)
    texture1:SetTexture(path)
    texture1:SetAllPoints(true)
end

-- Erstelle das Hauptframe des Addons
local addonFrame = CreateFrame("Frame", addonFrameName, UIParent)
addonFrame:SetSize(300, 84)
addonFrame:SetPoint("TOP", UIParent, "TOP", 0, -10) -- Setze den Frame oben und verschiebe ihn um 10 Pixel nach unten
addonFrame:SetMovable(true)
addonFrame:EnableMouse(true)
addonFrame:RegisterForDrag("LeftButton")
addonFrame:SetScript("OnDragStart", addonFrame.StartMoving)
addonFrame:SetScript("OnDragStop", addonFrame.StopMovingOrSizing)

-- Rahmen und Hintergrund für den Hauptframe hinzufügen
addonFrame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
addonFrame:SetBackdropColor(0, 0, 0, 0.7)

-- Erstelle den ersten Frame mit Textur
local frame1 = CreateFrame("Frame", "MyAddonFrame1", addonFrame)
frame1:SetSize(64, 64)
frame1:SetPoint("TOPLEFT", addonFrame, "TOPLEFT", 10, -10)

texture1 = frame1:CreateTexture(nil, "ARTWORK")
texture1:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
texture1:SetAllPoints(true)

-- Erstelle den zweiten Frame mit Textur
local frame2 = CreateFrame("Frame", "MyAddonFrame2", addonFrame)
frame2:SetSize(64, 64)
frame2:SetPoint("TOPLEFT", addonFrame, "TOPLEFT", 79, -10)

texture2 = frame2:CreateTexture(nil, "ARTWORK")
texture2:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
texture2:SetAllPoints(true)



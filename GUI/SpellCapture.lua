DPSGenie = LibStub("AceAddon-3.0"):GetAddon("DPSGenie")

DPSGenie:Print("AuraCapture loaded!")

local AceGUI = LibStub("AceGUI-3.0")
local Captureframe
local startButton, stopButton
local spellScrollFrame, buffScrollFrame

DPSGenie.spellSet = DPSGenie.spellSet or {}
DPSGenie.buffList = DPSGenie.buffList or {}

DPSGenie.playerBuffs = {}
DPSGenie.targetBuffs = {}


function DPSGenie:showCapture()
    if not Captureframe then
        Captureframe = AceGUI:Create("Window")
        Captureframe:SetTitle("DPSGenie Aura Capture")
        Captureframe:SetLayout("Flow")
        Captureframe:SetWidth(800)

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

        scrollContainer = AceGUI:Create("SimpleGroup") -- "InlineGroup" is also good
        scrollContainer:SetFullWidth(true)
        scrollContainer:SetHeight(Captureframe.frame:GetHeight() - 100)
        scrollContainer:SetLayout("Fill") -- important!

        Captureframe:AddChild(scrollContainer)

        buffScrollFrame = AceGUI:Create("ScrollFrame")
        buffScrollFrame:SetLayout("List") -- probably?
        buffScrollFrame:SetWidth(175)
        scrollContainer:AddChild(buffScrollFrame)

    else
        if Captureframe:IsVisible() then
            Captureframe:Hide()
        else
            Captureframe:Show()
        end
    end
end

function DPSGenie:startSpellCapture()
    startButton:SetDisabled(true)
    stopButton:SetDisabled(false)
    self:RegisterEvent("UNIT_AURA")
end

function DPSGenie:stopSpellCapture()
    startButton:SetDisabled(false)
    stopButton:SetDisabled(true)
    self:UnregisterEvent("UNIT_AURA")
end


local labelList = {}

--TODO: refactor!!
function DPSGenie:printBuffsToFrame()
    --DPSGenie:Print("printBuffsToFrame")
    for k, v in pairs(DPSGenie.playerBuffs) do
        if not labelList[k] then  
            local name, rank, icon, castTime, minRange, maxRange, spellID, originalIcon = GetSpellInfo(k)

            local label = AceGUI:Create("InteractiveLabel")
            label:SetWidth(300)
            label:SetImage(icon)
            label:SetImageSize(16, 16)
            label:SetText("\124cFF00FF00" .. k .. " - " .. v .. "\124r")
            label:SetCallback("OnEnter", function(widget) 
                GameTooltip:SetOwner(label.frame, "ANCHOR_CURSOR") -- Positioniere den Tooltip rechts vom Frame
                GameTooltip:SetHyperlink("spell:" .. k) -- Setze den Spell-Link im Tooltip
                GameTooltip:Show()
            end)
            label:SetCallback("OnLeave", function(widget) 
                GameTooltip:Hide()
            end)

            buffScrollFrame:AddChild(label)
            labelList[k] = true
        end
    end

    for k, v in pairs(DPSGenie.targetBuffs) do
        if not labelList[k] then  
            local name, rank, icon, castTime, minRange, maxRange, spellID, originalIcon = GetSpellInfo(k)

            local label = AceGUI:Create("InteractiveLabel")
            label:SetWidth(300)
            label:SetImage(icon)
            label:SetImageSize(16, 16)
            label:SetText("\124cFFFF0000" .. k .. " - " .. v .. "\124r")
            label:SetCallback("OnEnter", function(widget) 
                GameTooltip:SetOwner(label.frame, "ANCHOR_CURSOR") -- Positioniere den Tooltip rechts vom Frame
                GameTooltip:SetHyperlink("spell:" .. k) -- Setze den Spell-Link im Tooltip
                GameTooltip:Show()
            end)
            label:SetCallback("OnLeave", function(widget) 
                GameTooltip:Hide()
            end)

            buffScrollFrame:AddChild(label)
            labelList[k] = true
        end
    end
end

function DPSGenie:UNIT_AURA(event, ...)
    for i = 1, 99 do 
        local name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID = UnitAura("player", i)
        if name then
            --DPSGenie:Print("Player gained Buff: " .. name)
            DPSGenie.playerBuffs[spellID] = name
        end
    end

    for i = 1, 99 do 
        local name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID = UnitAura("target", i, "PLAYER|HARMFUL")
        if name then
            --DPSGenie:Print("Target gained Buff: " .. name)
            DPSGenie.targetBuffs[spellID] = name
        end
    end

    DPSGenie:printBuffsToFrame()

end
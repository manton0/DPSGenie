DPSGenie = LibStub("AceAddon-3.0"):GetAddon("DPSGenie")

DPSGenie:Print("SpellButton loaded!")

local AceGUI = LibStub("AceGUI-3.0")

local FirstSpellFrame, SecondSpellFrame
local DPSGenieButtonHolderFrame1, DPSGenieButtonHolderFrame2

local currentPulseFrame

function DPSGenie:CreatePulseFrame(parentFrame)
    local pulseFrame = CreateFrame("Frame", nil, UIParent)
    pulseFrame:SetSize(parentFrame:GetWidth(), parentFrame:GetHeight())
    pulseFrame:SetPoint("CENTER", parentFrame, "CENTER")
    pulseFrame:SetBackdrop({
          bgFile = "Interface/Tooltips/UI-Tooltip-Background",
          edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
          tile = true, tileSize = 16, edgeSize = 16,
          insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    pulseFrame:SetBackdropColor(0, 0, 0, 0)  -- Hintergrundfarbe transparent machen
    pulseFrame:SetBackdropBorderColor(1, 1, 0, 1)  -- Gelbe Border setzen
    pulseFrame:SetAlpha(0.8)
    pulseFrame:SetFrameStrata("HIGH")
    
    local scaleUp = true
    local scaleFactor = 1.0
    local pulseSpeed = 0.01
    
    local function PulseFrame()
       if scaleUp then
          scaleFactor = scaleFactor + pulseSpeed
       else
          scaleFactor = scaleFactor - pulseSpeed
       end
       
       pulseFrame:SetScale(scaleFactor)
       
       if scaleFactor > 1.2 then
          scaleUp = false
       elseif scaleFactor < 1.0 then
          scaleUp = true
       end
    end
    
    local onUpdate = function()
       PulseFrame()
    end
    
    pulseFrame:SetScript("OnUpdate", onUpdate)
    
    pulseFrame.HidePulse = function()
       pulseFrame:SetScript("OnUpdate", nil)
       pulseFrame:SetScale(1.0)
       pulseFrame:Hide()
    end
    
    return pulseFrame
 end
 
 function DPSGenie:ShowPulseFrame(parentFrame)
    DPSGenie:HidePulseFrame()
    currentPulseFrame = DPSGenie:CreatePulseFrame(parentFrame)
    currentPulseFrame:Show()
 end

 function DPSGenie:HidePulseFrame()
    if currentPulseFrame then
        currentPulseFrame:HidePulse()
    end
 end


local actionSort = {}
--local actionMacro = {}
--local actionObjet = {}
local shortCut = {}

function DPSGenie:IndexSpells(i)
    shortCut[i] = DPSGenie:FindKeybind(i)
    local actionText = GetActionText(i);
    --if (actionText) then
    --   actionMacro[actionText] = i
    --else
        local type, id = GetActionInfo(i);
        if (type=="spell") then
            if (id~=0) then
            local spellName, spellRank = GetSpellName(id, BOOKTYPE_SPELL);
            actionSort[spellName] = i
            end
            --elseif (type =="item") then
            --   self.actionObjet[id] = i
        end
    --end
end

function DPSGenie:FindKeybind(id)
   -- ACTIONBUTTON1..12 => principale (1..12, 13..24, 73..108)
   -- MULTIACTIONBAR1BUTTON1..12 => bas gauche (61..72)
   -- MULTIACTIONBAR2BUTTON1..12 => bas droite (49..60)
   -- MULTIACTIONBAR3BUTTON1..12 => haut droit (25..36)
   -- MULTIACTIONBAR4BUTTON1..12 => haut gauche (37..48)
   local name;
   if (id<=24 or id>72) then
      name = "ACTIONBUTTON"..(((id-1)%12)+1);
   elseif (id<=36) then
      name = "MULTIACTIONBAR3BUTTON"..(id-24);
   elseif (id<=48) then
      name = "MULTIACTIONBAR4BUTTON"..(id-36);
   elseif (id<=60) then
      name = "MULTIACTIONBAR2BUTTON"..(id-48);
   else
      name = "MULTIACTIONBAR1BUTTON"..(id-60);
   end
   local key = GetBindingKey(name);
   --[[
    if (not key) then
        DEFAULT_CHAT_FRAME:AddMessage(id.."=>"..name.." introuvable")
    else
        DEFAULT_CHAT_FRAME:AddMessage(id.."=>"..name.."="..key)
    end
]]--
   return key;
end

function DPSGenie:GetSpellKeybinds()
    actionSort = {}
    actionMacro = {}
    actionObjet = {}
    shortCut = {}
    for i=1,120 do
        DPSGenie:IndexSpells(i)
    end
end

local DPSGenieSpellButtonHandler = CreateFrame("FRAME", "DPSGenieSpellButtonHandler");
DPSGenieSpellButtonHandler:RegisterEvent("PLAYER_ENTERING_WORLD");
DPSGenieSpellButtonHandler:RegisterEvent("ACTIONBAR_PAGE_CHANGED");
DPSGenieSpellButtonHandler:RegisterEvent("ACTIONBAR_SLOT_CHANGED");

local function eventHandler(self, event, ...)
    --print("DPSGenieSpellButtonHandler " .. event);
    DPSGenie:GetSpellKeybinds()
end
DPSGenieSpellButtonHandler:SetScript("OnEvent", eventHandler);


function DPSGenie:SetFirstSuggestSpell(spellId, iconModifiers)
    DPSGenie:HidePulseFrame()
    if not spellId then
        FirstSpellFrame:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark") 
        FirstSpellFrame:SetVertexColor(0.99, 0.99, 0.99, 0.99)
        DPSGenieButtonHolderFrame1.text:SetText("?")
    else
        local name, rank, icon, castTime, minRange, maxRange, spellID, originalIcon = GetSpellInfo(spellId)
        FirstSpellFrame:SetTexture(icon)
        FirstSpellFrame:SetAllPoints(true)

        if iconModifiers and iconModifiers['vertexColor'] ~= nil then
            FirstSpellFrame:SetVertexColor(unpack(iconModifiers['vertexColor']))
        else
            FirstSpellFrame:SetVertexColor(0.99, 0.99, 0.99, 0.99)
        end

        if actionSort[name] then
            local keybind = shortCut[actionSort[name]]
            if actionSort[name] <= 12 then

                --TODO: get addon on first run, no need to check on every pulse
                if _G["BT4Button1"] and _G["BT4Button1"]:IsVisible() then
                    DPSGenie:ShowPulseFrame(_G["BT4Button"..tostring(actionSort[name])])
                elseif _G["ElvUI_Bar1Button1"] and _G["ElvUI_Bar1Button1"]:IsVisible() then
                    DPSGenie:ShowPulseFrame(_G["ElvUI_Bar1Button"..tostring(actionSort[name])])
                else
                    DPSGenie:ShowPulseFrame(_G["ActionButton"..tostring(actionSort[name])])
                end
            end
            DPSGenieButtonHolderFrame1.text:SetText(tostring(keybind))
        else
            DPSGenieButtonHolderFrame1.text:SetText("?")
        end

    end
    --print(FirstSpellFrame:GetVertexColor())
end

function DPSGenie:SetSecondSuggestSpell(spellId, iconModifiers)
    if not spellId then
        SecondSpellFrame:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        SecondSpellFrame:SetVertexColor(0.99, 0.99, 0.99, 0.99) 
    else
        local name, rank, icon, castTime, minRange, maxRange, spellID, originalIcon = GetSpellInfo(spellId)
        SecondSpellFrame:SetTexture(icon)
        SecondSpellFrame:SetAllPoints(true)
        if iconModifiers and iconModifiers['vertexColor'] ~= nil then
            SecondSpellFrame:SetVertexColor(unpack(iconModifiers['vertexColor']))
        else
            SecondSpellFrame:SetVertexColor(0.99, 0.99, 0.99, 0.99)
        end
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
DPSGenieButtonHolderFrame:SetScript('OnEnter', function() 
    DPSGenieButtonHolderFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    DPSGenieButtonHolderFrame:SetBackdropColor(0, 0, 0, 0.7)
end)
DPSGenieButtonHolderFrame:SetScript('OnLeave', function() 
    DPSGenieButtonHolderFrame:SetBackdrop(nil)
    DPSGenieButtonHolderFrame:SetBackdropColor(0, 0, 0, 1) 
end)


-- Erstelle den ersten Frame mit Textur
DPSGenieButtonHolderFrame1 = CreateFrame("Frame", "DPSGenieButtonHolderFrame1", DPSGenieButtonHolderFrame)
DPSGenieButtonHolderFrame1:SetSize(64, 64)
DPSGenieButtonHolderFrame1:SetPoint("TOPLEFT", DPSGenieButtonHolderFrame, "TOPLEFT", 10, -10)

DPSGenieButtonHolderFrame1.text = DPSGenieButtonHolderFrame1:CreateFontString(nil, "OVERLAY", "GameFontNormal")
DPSGenieButtonHolderFrame1.text:SetPoint("BOTTOMLEFT", DPSGenieButtonHolderFrame1, "BOTTOMLEFT", 5, 5)
DPSGenieButtonHolderFrame1.text:SetTextColor(1, 1, 1, 1)
DPSGenieButtonHolderFrame1.text:SetText("?")

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
DPSGenieButtonHolderFrame2.text:SetText("?")

SecondSpellFrame = DPSGenieButtonHolderFrame2:CreateTexture(nil, "ARTWORK")
SecondSpellFrame:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
SecondSpellFrame:SetAllPoints(true)



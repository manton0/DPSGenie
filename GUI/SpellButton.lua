local addonName, ns = ...
DPSGenie = LibStub("AceAddon-3.0"):GetAddon("DPSGenie")

--DPSGenie:Print("SpellButton loaded!")

local AceGUI = LibStub("AceGUI-3.0")

local FirstSpellFrame, SecondSpellFrame
local DPSGenieButtonHolderFrame1, DPSGenieButtonHolderFrame2

local currentPulseFrame = {}
local pulseFrame = {}

local borderColors = {
    [1] = {1, 1, 0, 1},
    [2] = {0, 1, 1, 1},
    [3] = {0, 1, 0.5, 1},
    [4] = {1, 0, 1, 1}
}

--TODO: add option for user defined color
function DPSGenie:CreatePulseFrame(id, parentFrame)
    pulseFrame[id] = CreateFrame("Frame", nil, UIParent)
    pulseFrame[id]:SetSize(parentFrame:GetWidth(), parentFrame:GetHeight())
    pulseFrame[id]:SetPoint("CENTER", parentFrame, "CENTER")
    pulseFrame[id]:SetBackdrop({
          bgFile = "Interface/Tooltips/UI-Tooltip-Background",
          edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
          tile = true, tileSize = 16, edgeSize = 16,
          insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    pulseFrame[id]:SetBackdropColor(0, 0, 0, 0)  
    pulseFrame[id]:SetBackdropBorderColor(unpack(borderColors[id]))
    pulseFrame[id]:SetAlpha(0.8)
    pulseFrame[id]:SetFrameStrata("TOOLTIP")
    
    local scaleUp = true
    local scaleFactor = 1.0
    local pulseSpeed = 0.01
    
    local function PulseFrame(id)
       if scaleUp then
          scaleFactor = scaleFactor + pulseSpeed
       else
          scaleFactor = scaleFactor - pulseSpeed
       end
       
       pulseFrame[id]:SetScale(scaleFactor)
       
       if scaleFactor > 1.2 then
          scaleUp = false
       elseif scaleFactor < 1.0 then
          scaleUp = true
       end
    end
    
    local elapsed_acc = 0
    local onUpdate = function(self, elapsed)
       elapsed_acc = elapsed_acc + elapsed
       if elapsed_acc < 0.03 then return end
       elapsed_acc = 0
       PulseFrame(id)
    end

    pulseFrame[id]:SetScript("OnUpdate", onUpdate)
    
    pulseFrame[id].HidePulse = function()
       pulseFrame[id]:SetScript("OnUpdate", nil)
       pulseFrame[id]:SetScale(1.0)
       pulseFrame[id]:Hide()
    end
    
    return pulseFrame[id]
 end
 
 function DPSGenie:ShowPulseFrame(id, parentFrame)
    for pulseId, _ in pairs(currentPulseFrame) do
        DPSGenie:HidePulseFrame(pulseId)
    end
    currentPulseFrame[id] = DPSGenie:CreatePulseFrame(id, parentFrame)
    currentPulseFrame[id]:Show()
 end

 function DPSGenie:HidePulseFrame(id)
    if currentPulseFrame[id] then
        currentPulseFrame[id]:HidePulse()
    end
 end


local actionSort = {}
local actionMacro = {}
local actionObjet = {}
local shortCut = {}

function DPSGenie:IndexSpells(i)
    shortCut[i] = DPSGenie:FindKeybind(i)
    local actionText = GetActionText(i);

    if actionText then
       actionMacro[actionText] = i
    else
        local type, id = GetActionInfo(i);
        if type == "spell" then
            if id ~= 0 then
                local spellName, spellRank = GetSpellName(id, BOOKTYPE_SPELL);
                actionSort[spellName] = i
            end
        elseif type == "item" then
            actionObjet[id] = i
        end
    end
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
DPSGenieSpellButtonHandler:RegisterEvent("SPELLS_CHANGED");

local keybindUpdatePending = false
local function eventHandler(self, event, ...)
    if not keybindUpdatePending then
        keybindUpdatePending = true
        DPSGenie:ScheduleTimer(function()
            DPSGenie:GetSpellKeybinds()
            keybindUpdatePending = false
        end, 0.1)
    end
    if event == "SPELLS_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
        DPSGenie:RebuildSpellBookCache()
        DPSGenie.cachedSpellList = nil
    end
end
DPSGenieSpellButtonHandler:SetScript("OnEvent", eventHandler);



--hacky!
--TODO: decrease _G calls
local numCreatedButtons = 0
function DPSGenie:SetupSpellButtons(count)
    --print("setting up " .. count .. " buttons")
    if numCreatedButtons > 0 then
        --clear old buttons
        --print("have " .. numCreatedButtons .. " old buttons, clearing")
        for i = 1, numCreatedButtons, 1 do
            --print("clearing no: " .. i)
            _G["DPSGenieButtonHolderFrame" .. i]:Hide()
            _G["DPSGenieButtonHolderFrame" .. i] = nil
            _G["DPSGenieSpellFrame" .. i]:Hide()
            _G["DPSGenieSpellFrame" .. i] = nil
            if _G["DPSGenieCooldownFrame" .. i] then
                _G["DPSGenieCooldownFrame" .. i]:Hide()
                _G["DPSGenieCooldownFrame" .. i] = nil
            end
        end
        numCreatedButtons = 0
    end

    for i = 1, count, 1 do
        _G["DPSGenieButtonHolderFrame" .. i] = CreateFrame("Frame", ("DPSGenieButtonHolderFrame"..i), DPSGenieButtonHolderFrame)
        _G["DPSGenieButtonHolderFrame" .. i]:SetSize(64, 64)
        _G["DPSGenieButtonHolderFrame" .. i]:SetPoint("TOPLEFT", DPSGenieButtonHolderFrame, "TOPLEFT", (10 + (69 * (i-1))), -10)

        _G["DPSGenieButtonHolderFrame" .. i].text = _G["DPSGenieButtonHolderFrame" .. i]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        _G["DPSGenieButtonHolderFrame" .. i].text:SetPoint("BOTTOMLEFT", _G["DPSGenieButtonHolderFrame" .. i], "BOTTOMLEFT", 5, 5)
        _G["DPSGenieButtonHolderFrame" .. i].text:SetTextColor(1, 1, 1, 1)
        _G["DPSGenieButtonHolderFrame" .. i].text:SetText("?")

        _G["DPSGenieSpellFrame" .. i] = _G["DPSGenieButtonHolderFrame" .. i]:CreateTexture(nil, "ARTWORK")
        _G["DPSGenieSpellFrame" .. i]:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        _G["DPSGenieSpellFrame" .. i]:SetAllPoints(true)

        _G["DPSGenieCooldownFrame" .. i] = CreateFrame("Cooldown", "DPSGenieCooldownFrame" .. i, _G["DPSGenieButtonHolderFrame" .. i])
        _G["DPSGenieCooldownFrame" .. i]:SetAllPoints(_G["DPSGenieButtonHolderFrame" .. i])

        if not DPSGenie:LoadSettingFromProfile("showEmpty") then
            _G["DPSGenieButtonHolderFrame" .. i]:Hide()
        else
            _G["DPSGenieButtonHolderFrame" .. i]:Show()
        end

        numCreatedButtons = numCreatedButtons + 1
    end
end


function DPSGenie:SetSuggestSpell(buttonNum, spellId, iconModifiers)
    if buttonNum == nil then
        return
    end

    --print("setting button " .. buttonNum .. " so spell " .. tostring(spellId))
    DPSGenie:HidePulseFrame(buttonNum)
    if not spellId then
        _G["DPSGenieSpellFrame"..buttonNum]:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        _G["DPSGenieSpellFrame"..buttonNum]:SetVertexColor(0.99, 0.99, 0.99, 0.99)
        _G["DPSGenieButtonHolderFrame"..buttonNum].text:SetText("?")
        if _G["DPSGenieCooldownFrame"..buttonNum] then
            _G["DPSGenieCooldownFrame"..buttonNum]:Hide()
        end
        if not DPSGenie:LoadSettingFromProfile("showEmpty") then
            _G["DPSGenieButtonHolderFrame"..buttonNum]:Hide()
        else
            _G["DPSGenieButtonHolderFrame"..buttonNum]:Show()
        end
    else

        local actionType = string.sub(spellId, 1, 1)
        local actionId = string.match(spellId, "%d+")

        local buttonTexture = "Interface\\Icons\\INV_Misc_QuestionMark"
        local name

        if actionType == "l" then
            name = "Lua Script"
        elseif actionType == "i" then
            local itemName, _, _, _, _, _, _, _, _, itemIcon = GetItemInfo(tonumber(actionId))
            if itemIcon then buttonTexture = itemIcon end
            name = itemName or "Unknown Item"
        else
            --spell
            local rank, icon, castTime, minRange, maxRange, spellID, originalIcon
            name, rank, icon, castTime, minRange, maxRange, spellID, originalIcon = GetSpellInfo(actionId)
            if icon then buttonTexture = icon end
        end
        


        _G["DPSGenieSpellFrame"..buttonNum]:SetTexture(buttonTexture)
        _G["DPSGenieSpellFrame"..buttonNum]:SetAllPoints(true)

        if iconModifiers and iconModifiers['vertexColor'] ~= nil then
            _G["DPSGenieSpellFrame"..buttonNum]:SetVertexColor(unpack(iconModifiers['vertexColor']))
        else
            _G["DPSGenieSpellFrame"..buttonNum]:SetVertexColor(0.99, 0.99, 0.99, 0.99)
        end

        if _G["DPSGenieCooldownFrame"..buttonNum] then
            if iconModifiers and iconModifiers['cooldown'] then
                local cd = iconModifiers['cooldown']
                _G["DPSGenieCooldownFrame"..buttonNum]:Show()
                _G["DPSGenieCooldownFrame"..buttonNum]:SetCooldown(cd.start, cd.duration)
            else
                _G["DPSGenieCooldownFrame"..buttonNum]:Hide()
            end
        end

        _G["DPSGenieButtonHolderFrame"..buttonNum]:Show()

        -- Determine action bar slot: spells use actionSort, items use actionObjet
        local actionBarSlot
        if actionType == "i" then
            actionBarSlot = actionObjet[tonumber(actionId)]
        elseif name then
            actionBarSlot = actionSort[name]
        end

        if actionBarSlot then
            local keybind = shortCut[actionBarSlot]

                if DPSGenie:LoadSettingFromProfile("showSpellFlash") then
                    if _G["BT4Button1"] and _G["BT4Button1"]:IsVisible() then
                        DPSGenie:ShowPulseFrame(buttonNum, _G["BT4Button"..tostring(actionBarSlot)])
                    elseif _G["ElvUI_Bar1Button1"] and _G["ElvUI_Bar1Button1"]:IsVisible() then
                        DPSGenie:ShowPulseFrame(buttonNum, _G["ElvUI_Bar1Button"..tostring(actionBarSlot)])
                    else
                        --default action bar
                        if actionBarSlot > 60 then
                            DPSGenie:ShowPulseFrame(buttonNum, _G["MultiBarBottomLeftButton"..tostring((actionBarSlot - 60))])
                        elseif actionBarSlot > 48 then
                            DPSGenie:ShowPulseFrame(buttonNum, _G["MultiBarBottomRightButton"..tostring((actionBarSlot - 48))])
                        elseif actionBarSlot > 36 then
                            DPSGenie:ShowPulseFrame(buttonNum, _G["MultiBarLeftButton"..tostring((actionBarSlot - 36))])
                        elseif actionBarSlot > 24 then
                            DPSGenie:ShowPulseFrame(buttonNum, _G["MultiBarRightButton"..tostring((actionBarSlot - 24))])
                        else
                            DPSGenie:ShowPulseFrame(buttonNum, _G["ActionButton"..tostring(actionBarSlot)])
                        end
                    end
                end

            if keybind then
                _G["DPSGenieButtonHolderFrame"..buttonNum].text:SetText(keybind)
            else
                _G["DPSGenieButtonHolderFrame"..buttonNum].text:SetText("?")
            end
        else
            _G["DPSGenieButtonHolderFrame"..buttonNum].text:SetText("?")
        end

    end
end



local DPSGenieButtonHolderFrame = CreateFrame("Frame", "DPSGenieButtonHolderFrame", UIParent)
DPSGenieButtonHolderFrame:SetSize(300, 84)
DPSGenieButtonHolderFrame:SetPoint("TOP", UIParent, "TOP", 0, -10)
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

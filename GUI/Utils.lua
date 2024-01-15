DPSGenie = LibStub("AceAddon-3.0"):GetAddon("DPSGenie")

DPSGenie:Print("Utils loaded!")

local showDebug = false
local debugWindow, debugText
local AceGUI = LibStub("AceGUI-3.0")

function DPSGenie:debugEnabled()
  return showDebug
end

function DPSGenie:debug(text)
  if showDebug then
    ChatFrame3:AddMessage(text)
  end
end

function DPSGenie:stateToColor(state, compare)
  if state == compare then
    return "|cFF00FF00" .. state .. "|r"
  else
    return "|cFFFF0000" .. state .. "|r"
  end
end


function DPSGenie:deepcopy(o, seen)
    seen = seen or {}
    if o == nil then return nil end
    if seen[o] then return seen[o] end
  
    local no
    if type(o) == 'table' then
      no = {}
      seen[o] = no
  
      for k, v in next, o, nil do
        no[DPSGenie:deepcopy(k, seen)] = DPSGenie:deepcopy(v, seen)
      end
      setmetatable(no, DPSGenie:deepcopy(getmetatable(o), seen))
    else -- number, string, boolean, etc
      no = o
    end
    return no
end


function DPSGenie:toggleDebug()
  showDebug = not showDebug
  DPSGenie:Print("Debug is now: " .. tostring(showDebug));
  if showDebug then
    if not debugWindow then
      DPSGenie:showDebugWindow()
    else
      debugWindow:Show()
    end
  else
    debugWindow:Hide()
  end
end

function DPSGenie:showDebugWindow()
  debugWindow = AceGUI:Create("Window")
  debugWindow:SetPoint("TOPLEFT", UIParent, "TOPLEFT")
  debugWindow:SetTitle("DPSGenie Debug Window")
  debugWindow:SetWidth(300)
  debugWindow:SetHeight(GetScreenHeight())
  debugWindow:SetLayout("Fill")
  debugWindow:EnableResize(false)
  debugWindow.title:SetScript("OnMouseDown", nil)
  --debugWindow.frame:SetScript("closeOnClick", nil)
  debugWindow.frame:SetFrameStrata("HIGH")

  local dialogbg = debugWindow.frame:CreateTexture(nil, "BACKGROUND")
  dialogbg:SetTexture([[Interface\Tooltips\UI-Tooltip-Background]])
  dialogbg:SetPoint("TOPLEFT", 8, -24)
  dialogbg:SetPoint("BOTTOMRIGHT", -6, 8)
  dialogbg:SetVertexColor(0, 0, 0, 1)

  debugText = AceGUI:Create("Label")
  debugText:SetFullWidth(true)
  debugText:SetFont([[Fonts\ARIALN.TTF]], 11, nil)
  debugText:SetText("debug|ntest")

  debugWindow:AddChild(debugText)

  --debugWindow:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
  debugWindow:Show()
end

function DPSGenie:setDebugWindowContent(debugTable)
  if debugWindow:IsVisible() then
    local tmpText = "|cFFFF0000Warning: Spellsuggest will not work while Debug is active!|nDon't use in real Combat!|r|n|n"
    for k,v in pairs(debugTable) do
      if string.find(v, "conditon passed!") then
        v = "|cFF34eb77" .. v .. "|r"
      end
      tmpText = tmpText .. v .. "|n"
    end
    debugText:SetText(tmpText)
  end
end

-- Erstelle den Hauptframe (wie ein Tooltip)
local mainFrame = CreateFrame("Frame", "MyAddonMainFrame", UIParent)
mainFrame:SetSize(220, 50)
mainFrame:SetPoint("CENTER", UIParent, "CENTER")
mainFrame:SetMovable(true)
mainFrame:EnableMouse(true)
mainFrame:RegisterForDrag("LeftButton")
mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
mainFrame:SetScript("OnDragStop", mainFrame.StopMovingOrSizing)

-- Erstelle die Hintergrundtextur für den Hauptframe
mainFrame.texture = mainFrame:CreateTexture(nil, "BACKGROUND")
mainFrame.texture:SetAllPoints(mainFrame)
mainFrame.texture:SetTexture(0, 0, 0, 0.5)  -- Schwarzer transparenter Hintergrund

-- Erstelle den Button-Frame
local buttonFrame = CreateFrame("Frame", "MyAddonButtonFrame", mainFrame)
buttonFrame:SetSize(220, 50)
buttonFrame:SetPoint("BOTTOM", mainFrame, "BOTTOM", 0, 0)

-- Funktion zum Erstellen von Buttons
local function CreateButton(parent, text, command)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(60, 22)
    button:SetText(text)
    button:SetScript("OnClick", function()
        --print("Button '" .. text .. "' wurde geklickt!")
        -- Füge hier den Befehl hinzu, den der Button ausführen soll
        if command then
            RunScript(command)
        end
    end)
    return button
end

-- Erstelle drei Buttons im Button-Frame
local button1 = CreateButton(buttonFrame, "Capture", "DPSGenie:showCapture()")
button1:SetPoint("LEFT", buttonFrame, "LEFT", 10, 0)

local button2 = CreateButton(buttonFrame, "Rota", "DPSGenie:showRotaBuilder()")
button2:SetPoint("LEFT", buttonFrame, "LEFT", 80, 0)

local button3 = CreateButton(buttonFrame, "Debug", "DPSGenie:toggleDebug()")
button3:SetPoint("LEFT", buttonFrame, "LEFT", 150, 0)

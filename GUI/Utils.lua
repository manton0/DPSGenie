DPSGenie = LibStub("AceAddon-3.0"):GetAddon("DPSGenie")

DPSGenie:Print("Utils loaded!")


local showDebug = false
function DPSGenie:debug(text)
    if showDebug then
        ChatFrame3:AddMessage(text)
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

local button3 = CreateButton(buttonFrame, "None", "return")
button3:SetPoint("LEFT", buttonFrame, "LEFT", 150, 0)

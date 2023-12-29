DPSGenie = LibStub("AceAddon-3.0"):GetAddon("DPSGenie")

DPSGenie:Print("RotaEditor loaded!")

local AceGUI = LibStub("AceGUI-3.0")
local Rotaframe
local defaultRotas


function DPSGenie:showRotaBuilder()
    if not Rotaframe then
        DPSGenie:CreateRotaBuilder()
    else
        if Rotaframe:IsVisible() then
            Rotaframe:Hide()
        else
            Rotaframe:Show()
        end
    end
end

function DPSGenie:GetRotaList()

    defaultRotas = DPSGenie:GetDefaultRotas()

	local tree = 
	{ 
		{
			value = "newRotation",
			text = "new Rotation",
            icon = "Interface\\Icons\\Spell_chargepositive",
		},
        {
			value = "importRotation",
			text = "import Rotation",
            icon = "Interface\\Icons\\Spell_chargepositive",
		},
		{
			value = "Rotations",
			text = "Rotations",
			children = {
				{
					value = "example code 1",
					text = "example code 1",
					icon = "Interface\\Icons\\custom_t_nhance_rpg_icons_firerealm_border",
				},
				{
					value = "example code 2",
					text = "example code 2",
                    icon = "Interface\\Icons\\inv_hammer_unique_sulfuras",
				},
			}
		},
	}

    for k, v in pairs(defaultRotas) do
        local entry = {value = v.name, text = v.name, icon = v.icon}
        table.insert(tree[3].children, entry)
    end 

	return tree
end

function DPSGenie:CreateRotaBuilder()
    Rotaframe = AceGUI:Create("Frame")
    Rotaframe:SetTitle("DPSGenie Rota Editor")
    Rotaframe:SetWidth(600)
    Rotaframe:SetHeight(525)
    Rotaframe:SetLayout("Fill")

    local rotaTree = AceGUI:Create("TreeGroup")
    rotaTree:SetFullHeight(true)
    rotaTree:SetLayout("Flow")
    rotaTree:SetTree(DPSGenie:GetRotaList())
    Rotaframe:AddChild(rotaTree)

    rotaTree:SetCallback("OnGroupSelected", function(container, _, selected)
        container:ReleaseChildren()

        if selected == "newRotation" then
            print("Create a new rotation.")
        else
            -- Finding out the selected path to get the rotaTitle
            -- Not conerned with ever clicking on Active/Inactive itself
            local rotaTitle = {strsplit("\001", selected)}
            tremove(rotaTitle, 1)
            rotaTitle = strjoin("?", unpack(rotaTitle))

            if rotaTitle ~= "" then
                DPSGenie:DrawRotaGroup(container, rotaTitle)
            end
        end
    end)

rotaTree:SelectByPath("Rotations")
end


local testObjTable = {}

function DPSGenie:DrawRotaGroup(group, rotaTitle)

    group.rotaTitle = rotaTitle
 
    -- Need to redraw again for when icon editbox/button are shown and hidden
    group:ReleaseChildren()
 
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    -- groupScrollContainer
 
    local groupScrollContainer = AceGUI:Create("SimpleGroup")
    groupScrollContainer:SetFullWidth(true)
    groupScrollContainer:SetFullHeight(true)
    groupScrollContainer:SetLayout("Fill")
    group:AddChild(groupScrollContainer)
 
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    -- groupScrollFrame
 
    local groupScrollFrame = AceGUI:Create("ScrollFrame")
    groupScrollFrame:SetFullWidth(true)
    groupScrollFrame:SetLayout("Flow")
    groupScrollContainer:AddChild(groupScrollFrame)
 
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    -- titleEditBox
 
    local titleEditBox = AceGUI:Create("EditBox")
    titleEditBox:SetFullWidth(true)
    titleEditBox:SetLabel("Title")
    titleEditBox:SetText(group.rotaTitle)
    groupScrollFrame:AddChild(titleEditBox)
 
    titleEditBox:SetCallback("OnEnterPressed", function(self)
        local success, err = DPSGenie:UpdateRotaTitle(group.rotaTitle, self:GetText())
 
        self:ClearFocus()
 
        if err and err == "exists" then
            -- If err is because objective exists, restore title, focus and highlight for user to change
            -- The other err would be because the title hasn't changed
            self:SetText(group.rotaTitle)
            self:SetFocus()
            self:HighlightText()
        elseif success then
            -- Update the objectiveTree to repopulate rotaTitles
            group:SetTree(DPSGenie:GetRotaList())
            -- Update the container's title reference
            group.rotaTitle = self:GetText()
        end
    end)
end
DPSGenie = LibStub("AceAddon-3.0"):GetAddon("DPSGenie")

DPSGenie:Print("RotaEditor loaded!")

local AceGUI = LibStub("AceGUI-3.0")
local Rotaframe, rotaTree
local defaultRotas
local customRotas


function DPSGenie:showAllPicker()
    DPSGenie:showSpellPicker("internal test")
end

function DPSGenie:showSpellPicker(origin)
    local spellPickerFrame = AceGUI:Create("Window")
    spellPickerFrame:SetPoint("TOPLEFT", Rotaframe.frame, "TOPRIGHT")
    spellPickerFrame:SetTitle("DPSGenie Spell Picker")
    spellPickerFrame:SetWidth(300)
    spellPickerFrame:SetHeight(200)
    spellPickerFrame:SetLayout("List")

    local templist = {}
       -- Iteriere über alle Zaubersprüche im Buch des Spielers
    for i = 1, MAX_SKILLLINE_TABS do
        local name, texture, offset, numSpells = GetSpellTabInfo(i)
        
        for j = offset + 1, offset + numSpells do
        spellLink, tradeLink = GetSpellLink(j, BOOKTYPE_SPELL)
        usable, nomana = IsUsableSpell(j, BOOKTYPE_SPELL)
        isPassive = IsPassiveSpell(j, BOOKTYPE_SPELL);
        if spellLink and usable and not isPassive then
            local spellID = tonumber(string.match(spellLink, "spell:(%d+)"))
            local name, rank, icon, powerCost, isFunnel, powerType, castingTime, minRange, maxRange = GetSpellInfo(spellID)
            templist[name] = spellID
            --print(spellID)
        end
        end
    end

    --table.sort(templist)

    local list = {}
    for k, v in pairs(templist) do
        list[v] = k
    end 


    local addSpellLabel = AceGUI:Create("Label")
    addSpellLabel:SetFullWidth(true)
    addSpellLabel:SetText("Add spell to: " .. origin)

    local label = AceGUI:Create("InteractiveLabel")
    label:SetWidth(300)

    local selectedSpell

    local spellPickerDropdown = AceGUI:Create("Dropdown")
    spellPickerDropdown:SetList(list)
    spellPickerDropdown:SetLabel("Spell Picker")
    spellPickerDropdown:SetFullWidth()
    spellPickerDropdown:SetHeight(75)
    spellPickerDropdown:SetCallback("OnValueChanged", function(widget, event, key) 
        local name, rank, icon, powerCost, isFunnel, powerType, castingTime, minRange, maxRange = GetSpellInfo(key)
        selectedSpell = key
        label:SetImage(icon)
        label:SetImageSize(32, 32)
        label:SetText(name)
        label:SetCallback("OnEnter", function(widget) 
            GameTooltip:SetOwner(label.frame, "ANCHOR_CURSOR") -- Positioniere den Tooltip rechts vom Frame
            GameTooltip:SetHyperlink("spell:" .. key) -- Setze den Spell-Link im Tooltip
            GameTooltip:Show()
        end)
        label:SetCallback("OnLeave", function(widget) 
            GameTooltip:Hide()
        end)
    end)

    local buttonsContainer = AceGUI:Create("SimpleGroup")
    buttonsContainer:SetFullWidth(true)
    buttonsContainer:SetFullHeight(true)
    buttonsContainer:SetLayout("Flow")

    local saveButton = AceGUI:Create("Button")
    saveButton:SetText("Save")
    saveButton:SetWidth(75) 
    saveButton:SetCallback("OnClick", function(widget) 
        DPSGenie:addSpellToRota(origin, selectedSpell)
    end)                 
    buttonsContainer:AddChild(saveButton)

    local cancelButton = AceGUI:Create("Button")
    cancelButton:SetText("Cancel")
    cancelButton:SetWidth(75)                  
    buttonsContainer:AddChild(cancelButton)

    spellPickerFrame:AddChild(addSpellLabel)
    spellPickerFrame:AddChild(spellPickerDropdown)
    spellPickerFrame:AddChild(label)
    spellPickerFrame:AddChild(buttonsContainer)
    
    spellPickerFrame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
    spellPickerFrame:Show()
end


function DPSGenie:addSpellToRota(rota, spell)
    --print("adding " .. spell .. " to " .. rota)
    table.insert(customRotas[rota].spells, {spellId = spell, conditions = {}})
    DPSGenie:SaveCustomRota(rota, customRotas[rota])
    DPSGenie:DrawRotaGroup(rotaTree, rota, "custom")
end


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
    customRotas = DPSGenie:GetCustomRotas()

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
			value = "defaultRotations",
			text = "Default Rotations",
			children = {
			}
		},
        {
			value = "customRotations",
			text = "Custom Rotations",
			children = {
			}
		},
	}

    for k, v in pairs(defaultRotas) do
        local entry = {value = v.name, text = v.name, icon = v.icon}
        table.insert(tree[3].children, entry)
    end 

    for k, v in pairs(customRotas) do
        local entry = {value = v.name, text = v.name, icon = v.icon}
        table.insert(tree[4].children, entry)
    end 

	return tree
end

function DPSGenie:CreateRotaBuilder()
    Rotaframe = AceGUI:Create("Window")
    Rotaframe:SetTitle("DPSGenie Rota Editor")
    Rotaframe:SetWidth(600)
    Rotaframe:SetHeight(525)
    Rotaframe:SetLayout("Fill")

    rotaTree = AceGUI:Create("TreeGroup")
    rotaTree:SetFullHeight(true)
    rotaTree:SetLayout("Flow")
    rotaTree:EnableButtonTooltips(false)
    rotaTree:SetTree(DPSGenie:GetRotaList())
    Rotaframe:AddChild(rotaTree)

    rotaTree:SetCallback("OnGroupSelected", function(container, arg1, selected)
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
                DPSGenie:DrawRotaGroup(container, rotaTitle, selected)
            end
        end
    end)

    rotaTree:SelectByPath("defaultRotations")
    rotaTree:SelectByPath("customRotations")
end


local testObjTable = {}

function DPSGenie:DrawRotaGroup(group, rotaTitle, selected)

    local rotaData
    if string.find(selected, "custom") then
        rotaData = customRotas[rotaTitle]
    else
        rotaData = defaultRotas[rotaTitle]
    end

    --group.rotaTitle = rotaTitle
 
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
    titleEditBox:SetText(rotaData.name)
    groupScrollFrame:AddChild(titleEditBox)
 
    --[[
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
    ]]--

    local titleEditBox = AceGUI:Create("EditBox")
    titleEditBox:SetFullWidth(true)
    titleEditBox:SetLabel("Description")
    titleEditBox:SetText(rotaData.description)
    groupScrollFrame:AddChild(titleEditBox)

    local labelRotaHeaderLabel = AceGUI:Create("Heading")
    labelRotaHeaderLabel:SetFullWidth(true)
    labelRotaHeaderLabel:SetText("Rotation Setup")
    groupScrollFrame:AddChild(labelRotaHeaderLabel)

    local labelRotaHeader = AceGUI:Create("SimpleGroup")
    labelRotaHeader:SetFullWidth(true)
    --labelRotaHeader:SetTitle("Spell Rotation")
    groupScrollFrame:AddChild(labelRotaHeader)


    if rotaData.spells then
        for ks, vs in pairs(rotaData.spells) do

            local name, rank, icon, castTime, minRange, maxRange, spellID, originalIcon = GetSpellInfo(vs.spellId)

            local rotaPartHolder = AceGUI:Create("InlineGroup")
            rotaPartHolder:SetTitle(ks .. ". " .. name)
            rotaPartHolder:SetFullWidth(true)

            local currentRotaPartLabel = AceGUI:Create("Label")
            currentRotaPartLabel:SetFullWidth(true)
            currentRotaPartLabel:SetText(name)
            currentRotaPartLabel:SetImage(icon)
            currentRotaPartLabel:SetImageSize(32, 32)
            rotaPartHolder:AddChild(currentRotaPartLabel)

            if vs.conditions then
                for kc, vc in pairs(vs.conditions) do
                    local conditionPartHolder = AceGUI:Create("InlineGroup")
                    conditionPartHolder:SetTitle(kc .. ". Condition")
                    conditionPartHolder:SetFullWidth(true)
                    
                    local currentConditionPartPool = AceGUI:Create("Label")
                    currentConditionPartPool:SetFullWidth(true)
                    currentConditionPartPool:SetText("Pool: " .. vc.pool)
                    conditionPartHolder:AddChild(currentConditionPartPool)

                    local currentConditionPartCompare = AceGUI:Create("Label")
                    currentConditionPartCompare:SetFullWidth(true)
                    currentConditionPartCompare:SetText("Compare: " .. vc.compare)
                    conditionPartHolder:AddChild(currentConditionPartCompare)


                    local currentConditionPartWhat = AceGUI:Create("Label")
                    currentConditionPartWhat:SetFullWidth(true)
                    if vc.what > 100 then
                        local name, rank, icon, castTime, minRange, maxRange, spellID, originalIcon = GetSpellInfo(vc.what)
                        currentConditionPartWhat:SetText("What: " .. name .. " (ID: " .. vc.what .. ")")
                    else
                        currentConditionPartWhat:SetText("What: " .. vc.what)
                    end
                    conditionPartHolder:AddChild(currentConditionPartWhat)

                    local editButton = AceGUI:Create("Button")
                    editButton:SetText("Edit")
                    editButton:SetWidth(75)                  
                    conditionPartHolder:AddChild(editButton)

                    rotaPartHolder:AddChild(conditionPartHolder)
                end
            else
                local addConditionButton = AceGUI:Create("Button")
                addConditionButton:SetText("Add Condition")
                addConditionButton:SetWidth(150)                  
                rotaPartHolder:AddChild(addConditionButton)
            end

            --should be called last
            labelRotaHeader:AddChild(rotaPartHolder)
        end
    end

    local addSpellButton = AceGUI:Create("Button")
    addSpellButton:SetText("Add Spell")
    addSpellButton:SetWidth(150)              
    addSpellButton:SetCallback("OnClick", function(widget) 
        DPSGenie:showSpellPicker(rotaTitle, selected)
    end)   

    groupScrollFrame:AddChild(addSpellButton)

    --[[
    local mlCodeEdit = AceGUI:Create("MultiLineEditBox")
    mlCodeEdit:SetFullWidth(true)
    mlCodeEdit:SetHeight(400)
    --mlCodeEdit:SetLayout("Fill")
	mlCodeEdit:SetNumLines(30)
    groupScrollFrame:AddChild(mlCodeEdit)
    ]]--
end
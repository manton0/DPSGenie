DPSGenie = LibStub("AceAddon-3.0"):GetAddon("DPSGenie")

DPSGenie:Print("RotaEditor loaded!")

local AceGUI = LibStub("AceGUI-3.0")
local Rotaframe, rotaTree
local defaultRotas
local customRotas
local conditionPickerFrame, spellPickerFrame


StaticPopupDialogs["CONFIRM_DELETE_SPELL"] = {
    text = "Do you want to delete the Spell %s?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function (self, data, data2)
        --print("deleting " .. data .. " from " .. data2)
        DPSGenie:removeSpellFromRota(data2, data)
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["CONFIRM_DELETE_ROTA"] = {
    text = "Do you want to delete the Rota %s?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function (self, data)
        --print("deleting " .. data .. " from " .. data2)
        DPSGenie:DeleteCustomRota(data)
        rotaTree:SetTree(DPSGenie:GetRotaList())
        rotaTree:SelectByPath("customRotations")
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local conditionsUnit = {
    "Player",
    "Target",
}

local conditionsSubjects = {
    "Buffs",
    --"Debuffs",
    "Health",
    "Mana",
    "Combopoints",
}

local conditionsComparer = {
    "contains",
    "more than",
    "less than",
    "equals",
}


local conditionTree = {
    ["Player"] = {
        ["Buffs"] = {
            "contains",
            "more than",
            "less than"
        },
        ["Health"] = {
            "more than",
            "less than",
            "equals"
        },
        ["Mana"] = {
            "more than",
            "less than",
            "equals"
        },
        ["Combopoints"] = {
            "more than",
            "less than",
            "equals"
        },
    },
    ["Target"] = {
        ["Buffs"] = {
            "contains",
            "more than",
            "less than"
        },
        ["Health"] = {
            "more than",
            "less than",
            "equals"
        },
       ["Mana"] = {
            "more than",
            "less than",
            "equals"
        },
    }
}


function DPSGenie:showAllPicker()
    --DPSGenie:showSpellPicker("internal test")
end


function DPSGenie:dumpTable(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. DPSGenie:dumpTable(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
 end

function DPSGenie:showConditionPicker(rotaTitle, rotaSpell)

    local baseConditon = {
        unit,
        subject,
        comparer,
        compare_value,
        search
    }

    conditionPickerFrame = AceGUI:Create("Window")
    conditionPickerFrame:SetPoint("TOPLEFT", Rotaframe.frame, "TOPRIGHT")
    conditionPickerFrame:SetTitle("DPSGenie Condition Picker")
    conditionPickerFrame:SetWidth(300)
    conditionPickerFrame:SetHeight(400)
    conditionPickerFrame:SetLayout("List")
    conditionPickerFrame:EnableResize(false)
    conditionPickerFrame.title:SetScript("OnMouseDown", nil)
    conditionPickerFrame.frame:SetFrameStrata("HIGH")

    local addConditionLabel = AceGUI:Create("Label")
    addConditionLabel:SetFullWidth(true)
    addConditionLabel:SetText("Add Condition to: " .. rotaTitle .. " Spell: " .. rotaSpell)

    local saveButton = AceGUI:Create("Button")
    saveButton:SetDisabled(true)

    local drop1 = false
    local drop2 = false
    local drop3 = false
    local edittext = false

    local unitPickerDropdown = AceGUI:Create("Dropdown")
    unitPickerDropdown:SetList(conditionsUnit)
    unitPickerDropdown:SetLabel("Unit Picker")
    unitPickerDropdown:SetFullWidth()
    unitPickerDropdown:SetCallback("OnValueChanged", function(widget, event, key) 
        --print("unit: " .. conditionsUnit[key])
        baseConditon.unit = conditionsUnit[key]
        drop1 = true
        saveButton:SetDisabled(not (drop1 and drop2 and drop3 and edittext))
    end)

    local subjectPickerDropdown = AceGUI:Create("Dropdown")
    subjectPickerDropdown:SetList(conditionsSubjects)
    subjectPickerDropdown:SetLabel("Subject Picker")
    subjectPickerDropdown:SetFullWidth()
    subjectPickerDropdown:SetCallback("OnValueChanged", function(widget, event, key) 
        --print("subject: " .. conditionsSubjects[key])
        baseConditon.subject = conditionsSubjects[key]
        drop2 = true
        saveButton:SetDisabled(not (drop1 and drop2 and drop3 and edittext))
    end)

    local comparerPickerDropdown = AceGUI:Create("Dropdown")
    comparerPickerDropdown:SetList(conditionsComparer)
    comparerPickerDropdown:SetLabel("Comparer Picker")
    comparerPickerDropdown:SetFullWidth()
    comparerPickerDropdown:SetCallback("OnValueChanged", function(widget, event, key) 
        --print("comparer: " .. conditionsComparer[key])
        baseConditon.comparer = conditionsComparer[key]
        drop3 = true
        saveButton:SetDisabled(not (drop1 and drop2 and drop3 and edittext))
    end)

    local searchValue = AceGUI:Create("EditBox")
    searchValue:SetFullWidth(true)
    searchValue:SetLabel("Search: ")
    searchValue:DisableButton(true)
    searchValue:SetCallback("OnTextChanged", function(widget, event, text) 
        if text ~= ""  then
            edittext = true
        else
            edittext = false
        end
        saveButton:SetDisabled(not (drop1 and drop2 and drop3 and edittext))
    end)  

    local buttonsContainer = AceGUI:Create("SimpleGroup")
    buttonsContainer:SetFullWidth(true)
    buttonsContainer:SetFullHeight(true)
    buttonsContainer:SetLayout("Flow")

    saveButton:SetText("Save")
    saveButton:SetWidth(75) 
    saveButton:SetCallback("OnClick", function(widget) 
        --AceGUI:Release(widget.parent.parent)
        baseConditon.search = searchValue:GetText()
        --print("add condition to " .. rotaTitle .. " Spell " .. rotaSpell)
        --print(DPSGenie:dumpTable(baseConditon))
        DPSGenie:addConditionToSpell(rotaTitle, rotaSpell, baseConditon)
        if conditionPickerFrame then
            conditionPickerFrame:Fire("OnClose")
        end

    end)                 
    buttonsContainer:AddChild(saveButton)

    local cancelButton = AceGUI:Create("Button")
    cancelButton:SetText("Cancel")
    cancelButton:SetWidth(75)   
    cancelButton:SetCallback("OnClick", function(widget) 
        if conditionPickerFrame then
            conditionPickerFrame:Fire("OnClose")
        end
    end)                
    buttonsContainer:AddChild(cancelButton)

    conditionPickerFrame:AddChild(addConditionLabel)
    conditionPickerFrame:AddChild(unitPickerDropdown)
    conditionPickerFrame:AddChild(subjectPickerDropdown)
    conditionPickerFrame:AddChild(comparerPickerDropdown)
    conditionPickerFrame:AddChild(searchValue)
    conditionPickerFrame:AddChild(buttonsContainer)
    
    conditionPickerFrame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
    conditionPickerFrame:Show()

end

function DPSGenie:showSpellPicker(rotaTitle)
    spellPickerFrame = AceGUI:Create("Window")
    spellPickerFrame:SetPoint("TOPLEFT", Rotaframe.frame, "TOPRIGHT")
    spellPickerFrame:SetTitle("DPSGenie Spell Picker")
    spellPickerFrame:SetWidth(300)
    spellPickerFrame:SetHeight(200)
    spellPickerFrame:SetLayout("List")
    spellPickerFrame:EnableResize(false)
    spellPickerFrame.title:SetScript("OnMouseDown", nil)
    spellPickerFrame.frame:SetFrameStrata("HIGH")

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
            if IsHarmfulSpell(name) or IsHelpfulSpell(name) then
                templist[format("|T%s:32:32|t %s", icon, name)] = spellID
            end
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
    addSpellLabel:SetText("Add spell to: " .. rotaTitle)

    local label = AceGUI:Create("InteractiveLabel")
    label:SetWidth(300)


    local saveButton = AceGUI:Create("Button")
    saveButton:SetDisabled(true)

    local selectedSpell

    local spellPickerDropdown = AceGUI:Create("Dropdown")
    spellPickerDropdown:SetList(list)
    spellPickerDropdown:SetLabel("Spell Picker")
    spellPickerDropdown:SetFullWidth()
    spellPickerDropdown:SetCallback("OnValueChanged", function(widget, event, key) 
        local name, rank, icon, powerCost, isFunnel, powerType, castingTime, minRange, maxRange = GetSpellInfo(key)
        selectedSpell = key
        saveButton:SetDisabled(false)
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

    saveButton:SetText("Save")
    saveButton:SetWidth(75) 
    saveButton:SetCallback("OnClick", function(widget) 
        DPSGenie:addSpellToRota(rotaTitle, selectedSpell)
        if spellPickerFrame then
            spellPickerFrame:Fire("OnClose")
        end
    end)                 
    buttonsContainer:AddChild(saveButton)

    local cancelButton = AceGUI:Create("Button")
    cancelButton:SetText("Cancel")
    cancelButton:SetWidth(75)       
    cancelButton:SetCallback("OnClick", function(widget) 
        if spellPickerFrame then
            spellPickerFrame:Fire("OnClose")
        end
    end)           
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

function DPSGenie:addConditionToSpell(rotaTitle, rotaSpell, condition)
    table.insert(customRotas[rotaTitle]["spells"][rotaSpell]["conditions"], condition)
    DPSGenie:SaveCustomRota(rotaTitle, customRotas[rotaTitle])
    DPSGenie:DrawRotaGroup(rotaTree, rotaTitle, "custom")
end

function DPSGenie:removeSpellFromRota(rota, index)
    table.remove(customRotas[rota].spells, index)
    DPSGenie:SaveCustomRota(rota, customRotas[rota])
    DPSGenie:DrawRotaGroup(rotaTree, rota, "custom")
end

function DPSGenie:swapSpells(rota, index1, index2)
    tbl = customRotas[rota]
    if tbl and tbl.spells and tbl.spells[index1] and tbl.spells[index2] then
        --print("would swap")
        tbl.spells[index1], tbl.spells[index2] = tbl.spells[index2], tbl.spells[index1]
    end
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
        local activeName = v.name
        --if v.name == DPSGenie:LoadSettingFromProfile("activeRota") then
        --    activeName = "\124cFF00FF00" .. v.name .. "\124r"
        --end
        local entry = {value = v.name, text = activeName, icon = v.icon}
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
    Rotaframe.frame:SetFrameStrata("HIGH")

    Rotaframe:SetCallback("OnClose", function(widget) 
        if spellPickerFrame then
            spellPickerFrame:Fire("OnClose")
        end
        if conditionPickerFrame then
            conditionPickerFrame:Fire("OnClose")
        end
        --AceGUI:Release(widget) 
    end)

    rotaTree = AceGUI:Create("TreeGroup")
    rotaTree:SetFullHeight(true)
    rotaTree:SetLayout("Flow")
    rotaTree:EnableButtonTooltips(false)
    rotaTree:SetTree(DPSGenie:GetRotaList())
    Rotaframe:AddChild(rotaTree)

    rotaTree:SetCallback("OnGroupSelected", function(container, arg1, selected)
        container:ReleaseChildren()

        if selected == "newRotation" then
            DPSGenie:DrawNewRotaWindow(container)
        elseif selected == "importRotation" then
            print("Import rotation.")
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

function DPSGenie:DrawNewRotaWindow(container)

    local groupScrollContainer = AceGUI:Create("SimpleGroup")
    groupScrollContainer:SetFullWidth(true)
    groupScrollContainer:SetFullHeight(true)
    groupScrollContainer:SetLayout("Fill")
    container:AddChild(groupScrollContainer)

    local groupScrollFrame = AceGUI:Create("ScrollFrame")
    groupScrollFrame:SetFullWidth(true)
    groupScrollFrame:SetLayout("Flow")
    groupScrollContainer:AddChild(groupScrollFrame)


    local saveNewRotaButton = AceGUI:Create("Button")
    saveNewRotaButton:SetText("Create Rota")
    saveNewRotaButton:SetWidth(150)      

    local rotaExistsError = AceGUI:Create("Label")
    rotaExistsError:SetFullWidth(true)
    rotaExistsError:SetHeight(50)

    local rotaNameInput
    local rotaDescrInput

    local titleEditBox = AceGUI:Create("EditBox")
    titleEditBox:SetFullWidth(true)
    titleEditBox:SetLabel("Title")
    titleEditBox:DisableButton(true)
    titleEditBox:SetCallback("OnTextChanged", function(widget, event, text) 
        rotaNameInput = text
        if DPSGenie:GetCustomRota(rotaNameInput) then
            saveNewRotaButton:SetDisabled(true)
            rotaExistsError:SetText("\124cFFFF0000Error: Rotation with this name already exists!\124r\n\n")
        else
            saveNewRotaButton:SetDisabled(false)
            rotaExistsError:SetText("")
        end
    end)                 

    groupScrollFrame:AddChild(titleEditBox)

    groupScrollFrame:AddChild(rotaExistsError)

    local descrEditBox = AceGUI:Create("EditBox")
    descrEditBox:SetFullWidth(true)
    descrEditBox:SetLabel("Description")
    descrEditBox:DisableButton(true)
    descrEditBox:SetCallback("OnTextChanged", function(widget, event, text) 
        rotaDescrInput = text
    end)
    groupScrollFrame:AddChild(descrEditBox)
  
    saveNewRotaButton:SetCallback("OnClick", function(widget) 
        --print("create new rota: " .. rotaNameInput .. " / " .. rotaDescrInput)
        DPSGenie:CreateNewRota(rotaNameInput, rotaDescrInput)
        rotaTree:SetTree(DPSGenie:GetRotaList())
        rotaTree:SelectByValue("customRotations\001"..rotaNameInput)
        --DPSGenie:DrawRotaGroup(rotaTree, rotaNameInput, "custom")
    end)
    groupScrollFrame:AddChild(saveNewRotaButton)


end

function DPSGenie:DrawImportRotaWindow(container)
end

local customButtons = {}

function DPSGenie:DrawRotaGroup(group, rotaTitle, selected)

    --remove custom buttons as they were not added as childs
    for btnCnt = 1, #customButtons do
        customButtons[btnCnt].frame:Hide();
    end

    local readOnly
    local rotaData
    if string.find(selected, "custom") then
        rotaData = customRotas[rotaTitle]
        readOnly = false
    else
        rotaData = defaultRotas[rotaTitle]
        readOnly = true
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
    titleEditBox:SetDisabled(readOnly)
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

    local descrEditBox = AceGUI:Create("EditBox")
    descrEditBox:SetFullWidth(true)
    descrEditBox:SetLabel("Description")
    descrEditBox:SetText(rotaData.description)
    descrEditBox:SetDisabled(readOnly)
    groupScrollFrame:AddChild(descrEditBox)

    local useRotaButton = AceGUI:Create("Button")
    useRotaButton:SetText("Use Rota")
    useRotaButton:SetWidth(100) 
    useRotaButton:SetCallback("OnClick", function(widget) 
        DPSGenie:SetActiveRota(rotaData)
    end)                 
    groupScrollFrame:AddChild(useRotaButton)


    local copyRotaButton = AceGUI:Create("Button")
    copyRotaButton:SetText("Copy Rota")
    copyRotaButton:SetWidth(100) 
    copyRotaButton:SetCallback("OnClick", function(widget) 
        DPSGenie:CopyRotaToCustom(rotaData)
        rotaTree:SetTree(DPSGenie:GetRotaList())
        rotaTree:SelectByValue("customRotations\001".."Copy of ".. rotaData.name)
        --DPSGenie:DrawRotaGroup(rotaTree, "Copy of ".. rotaData.name, "custom")
    end)                 
    groupScrollFrame:AddChild(copyRotaButton)

    local deleteRotaButton = AceGUI:Create("Button")
    deleteRotaButton:SetText("Delete Rota")
    deleteRotaButton:SetWidth(120) 
    deleteRotaButton:SetCallback("OnClick", function(widget) 
        --DPSGenie:Print("would delete rota: " .. rotaData.name)
        local dialog = StaticPopup_Show("CONFIRM_DELETE_ROTA", rotaData.name)
        if dialog then
            dialog.data = rotaData.name
        end       
    end)                 
    groupScrollFrame:AddChild(deleteRotaButton)


    local RotaHeaderHeader = AceGUI:Create("Heading")
    RotaHeaderHeader:SetFullWidth(true)
    RotaHeaderHeader:SetText("Rotation Setup")
    groupScrollFrame:AddChild(RotaHeaderHeader)

    local labelRotaHeader = AceGUI:Create("SimpleGroup")
    labelRotaHeader:SetFullWidth(true)
    --labelRotaHeader:SetTitle("Spell Rotation")
    groupScrollFrame:AddChild(labelRotaHeader)

    if rotaData.spells then
        for ks, vs in ipairs(rotaData.spells) do

            local name, rank, icon, castTime, minRange, maxRange, spellID, originalIcon = GetSpellInfo(vs.spellId)

            local rotaPartHolder = AceGUI:Create("InlineGroup")
            rotaPartHolder:SetTitle(ks .. ". " .. name)
            rotaPartHolder:SetFullWidth(true)
            rotaPartHolder:SetLayout("List")

            local currentRotaPartLabel = AceGUI:Create("Label")
            currentRotaPartLabel:SetFullWidth(true)
            currentRotaPartLabel:SetText(name)
            currentRotaPartLabel:SetImage(icon)
            currentRotaPartLabel:SetImageSize(32, 32)
            rotaPartHolder:AddChild(currentRotaPartLabel)

            if vs.conditions then
                for kc, vc in ipairs(vs.conditions) do
                    local conditionPartHolder = AceGUI:Create("InlineGroup")
                    conditionPartHolder:SetTitle(kc .. ". Condition")
                    conditionPartHolder:SetFullWidth(true)
                    
                    local currentConditionPartUnit = AceGUI:Create("Label")
                    currentConditionPartUnit:SetFullWidth(true)
                    currentConditionPartUnit:SetText("\124cFF00FF00Unit:\124r " .. vc.unit)
                    conditionPartHolder:AddChild(currentConditionPartUnit)

                    local currentConditionPartSubject = AceGUI:Create("Label")
                    currentConditionPartSubject:SetFullWidth(true)
                    currentConditionPartSubject:SetText("\124cFF00FF00Subject:\124r " .. vc.subject)
                    conditionPartHolder:AddChild(currentConditionPartSubject)

                    local currentConditionPartComparer = AceGUI:Create("Label")
                    currentConditionPartComparer:SetFullWidth(true)
                    currentConditionPartComparer:SetText("\124cFF00FF00Comparer:\124r " .. vc.comparer)
                    conditionPartHolder:AddChild(currentConditionPartComparer)

                    if vc.compare_value then
                        local currentConditionPartCompareValue = AceGUI:Create("Label")
                        currentConditionPartCompareValue:SetFullWidth(true)
                        currentConditionPartCompareValue:SetText("\124cFF00FF00Compare Value:\124r " .. vc.compare_value)
                        conditionPartHolder:AddChild(currentConditionPartCompareValue)
                    end

                    local currentConditionPartSearch = AceGUI:Create("Label")
                    currentConditionPartSearch:SetFullWidth(true)
                    if tonumber(vc.search) > 100 then
                        local name, rank, icon, castTime, minRange, maxRange, spellID, originalIcon = GetSpellInfo(vc.search)
                        currentConditionPartSearch:SetText("\124cFF00FF00Search:\124r " .. name .. " (ID: " .. vc.search .. ")")
                    else
                        currentConditionPartSearch:SetText("\124cFF00FF00Search:\124r " .. vc.search)
                    end
                    conditionPartHolder:AddChild(currentConditionPartSearch)

                    local editButton = AceGUI:Create("Button")
                    editButton:SetText("Edit")
                    editButton:SetWidth(75)    
                    if not readOnly then              
                        conditionPartHolder:AddChild(editButton)
                    end

                    rotaPartHolder:AddChild(conditionPartHolder)
                end
            end

            local addConditionButton = AceGUI:Create("Button")
            addConditionButton:SetText("Add Condition")
            addConditionButton:SetWidth(150)      
            addConditionButton:SetCallback("OnClick", function(widget) 
                if spellPickerFrame then
                    spellPickerFrame:Fire("OnClose")
                end
                DPSGenie:showConditionPicker(rotaTitle, ks)
            end)        
            if not readOnly then    
                rotaPartHolder:AddChild(addConditionButton)
            end

            local deleteSpellButton = AceGUI:Create("Button")
            deleteSpellButton:SetText("Delete Spell")
            deleteSpellButton:SetWidth(20)  
            deleteSpellButton:SetHeight(20)          
            deleteSpellButton:SetCallback("OnClick", function(widget) 
                local dialog = StaticPopup_Show("CONFIRM_DELETE_SPELL", name)
                if dialog then
                    dialog.data = ks
                    dialog.data2 = rotaTitle
                end
            end)   
            table.insert(customButtons, deleteSpellButton)   
            --rotaPartHolder:AddChild(deleteSpellButton)
            
            deleteSpellButton.frame:ClearAllPoints()
            deleteSpellButton.frame:SetParent(rotaPartHolder.frame)
            deleteSpellButton.frame:SetPoint("TOPRIGHT", rotaPartHolder.frame, "TOPRIGHT", -10, -30)
            deleteSpellButton.frame:SetNormalTexture("Interface\\Addons\\DPSGenie\\Images\\close.tga")
            if not readOnly then
                deleteSpellButton.frame:Show()
            end

            local moveSpellUpButton = AceGUI:Create("Button")
            moveSpellUpButton:SetWidth(20)   
            moveSpellUpButton:SetHeight(20)           
            moveSpellUpButton:SetCallback("OnClick", function(widget) 
                --print("moveup " .. rotaTitle .. " io: " .. ks .. " in: " .. ks-1)
                DPSGenie:swapSpells(rotaTitle, ks, ks-1)
            end) 
            
            moveSpellUpButton.frame:ClearAllPoints()
            moveSpellUpButton.frame:SetParent(rotaPartHolder.frame)
            moveSpellUpButton.frame:SetPoint("TOPRIGHT", rotaPartHolder.frame, "TOPRIGHT", -35, -30)
            moveSpellUpButton.frame:SetNormalTexture("Interface\\Addons\\DPSGenie\\Images\\up.tga")
            if ks ~= 1 then
                if not readOnly then
                    moveSpellUpButton.frame:Show()
                end
            end
            table.insert(customButtons, moveSpellUpButton)
            --rotaPartHolder:AddChild(moveSpellUpButton)

            local moveSpellDownButton = AceGUI:Create("Button")
            moveSpellDownButton:SetWidth(20)   
            moveSpellDownButton:SetHeight(20)           
            moveSpellDownButton:SetCallback("OnClick", function(widget) 
                --print("movedown " .. rotaTitle .. " io: " .. ks .. " in: " .. ks+1)
                DPSGenie:swapSpells(rotaTitle, ks, ks+1)
            end)   
            moveSpellDownButton.frame:ClearAllPoints()
            moveSpellDownButton.frame:SetParent(rotaPartHolder.frame)
            local xpos = -60
            if ks == 1 then
                xpos = -35
            end
            moveSpellDownButton.frame:SetPoint("TOPRIGHT", rotaPartHolder.frame, "TOPRIGHT", xpos, -30)
            moveSpellDownButton.frame:SetNormalTexture("Interface\\Addons\\DPSGenie\\Images\\down.tga")
            if ks ~= #rotaData.spells then
                if not readOnly then
                    moveSpellDownButton.frame:Show()
                end
            end
            table.insert(customButtons, moveSpellDownButton)
            --rotaPartHolder:AddChild(moveSpellDownButton)


            --should be called last
            labelRotaHeader:AddChild(rotaPartHolder)
        end
    end

    local addSpellButton = AceGUI:Create("Button")
    addSpellButton:SetText("Add Spell")
    addSpellButton:SetWidth(150)              
    addSpellButton:SetCallback("OnClick", function(widget) 
        if conditionPickerFrame then
            conditionPickerFrame:Fire("OnClose")
        end
        DPSGenie:showSpellPicker(rotaTitle)
    end)   

    if not readOnly then
        groupScrollFrame:AddChild(addSpellButton)
    end

    --[[
    local mlCodeEdit = AceGUI:Create("MultiLineEditBox")
    mlCodeEdit:SetFullWidth(true)
    mlCodeEdit:SetHeight(400)
    --mlCodeEdit:SetLayout("Fill")
	mlCodeEdit:SetNumLines(30)
    groupScrollFrame:AddChild(mlCodeEdit)
    ]]--
end
local addonName, ns = ...
DPSGenie = LibStub("AceAddon-3.0"):GetAddon("DPSGenie")

--DPSGenie:Print("RotaEditor loaded!")

local AceGUI = LibStub("AceGUI-3.0")
local Rotaframe, rotaTree
local defaultRotas
local customRotas
local conditionPickerFrame, spellPickerFrame

DPSGenieExportString = ""

StaticPopupDialogs["COPY_ROTA_STRING"] = {
    text = "You can now copy the rota string with CRTL+C",
    button1 = "Done",
    OnShow = function (self)
        self.editBox:SetText(_G["DPSGenieExportString"])
        self.editBox:HighlightText()
        self.editBox:SetFocus()
    end,
    EditBoxOnTextChanged = function (self)
        local parent = self:GetParent();
        parent.editBox:SetText(_G["DPSGenieExportString"])
        parent.editBox:HighlightText()
        parent.editBox:SetFocus()
    end,
    hasEditBox = true,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["CONFIRM_DELETE_SPELL"] = {
    text = "Do you want to delete the Spell %s?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function (self, data, data2)
        --print("deleting " .. data .. " from " .. data2)
        DPSGenie:removeSpellFromRota(data2.rota, data2.group, data)
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

StaticPopupDialogs["CONFIRM_DELETE_CONDITION"] = {
    text = "Do you want to delete the Condition?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function (self, data, data2)
        --print("delete condition: " .. data.c .. " from spell " .. data.s .. " from rota " .. data2)
        DPSGenie:removeConditionFromSpell(data2.rota, data2.group, data.s, data.c)
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}


local conditionTree = {
    ["Player"] = {
        ["Buffs"] = {
            "contains",
            "not contains",
            "more than",
            "less than",
            "equals"
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
        ["Rage"] = {
            "more than",
            "less than",
            "equals"
        },
        ["Energy"] = {
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
            "not contains",
            "more than",
            "less than",
            "equals"
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


local function get_keys(t)
    local keys = {}
    for key,_ in pairs(t) do
        table.insert(keys, key)
    end
    return keys
end


function DPSGenie:showConditionPicker(rotaTitle, group, rotaSpell)

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
    addConditionLabel:SetText("Add Condition to: " .. rotaTitle .. " Group: " .. group .. " Spell: " .. rotaSpell)

    local saveButton = AceGUI:Create("Button")
    saveButton:SetDisabled(true)

    local drop1 = false
    local drop2 = false
    local drop3 = false
    local drop4 = false
    local edittext = false

    local unitPickerDropdown = AceGUI:Create("Dropdown")
    local subjectPickerDropdown = AceGUI:Create("Dropdown")
    subjectPickerDropdown:SetList({})
    local comparerPickerDropdown = AceGUI:Create("Dropdown")
    comparerPickerDropdown:SetList({})
    local buffPickerDropdown = AceGUI:Create("Dropdown")
    local searchValue = AceGUI:Create("EditBox")

    local unitPickerDropdownList = get_keys(conditionTree)
    local subjectPickerDropdownList = {}
    local comparerPickerDropdownList = {}

    local unitPickerDropdownListKey 
    local subjectPickerDropdownListKey

    local buffSelectList = {}

    unitPickerDropdown:SetList(unitPickerDropdownList)
    unitPickerDropdown:SetLabel("Unit Picker")
    unitPickerDropdown:SetFullWidth()
    unitPickerDropdown:SetCallback("OnValueChanged", function(widget, event, key) 
        --print("unit: " .. unitPickerDropdownList[key])
        unitPickerDropdownListKey = key
        baseConditon.unit = unitPickerDropdownList[key]
        subjectPickerDropdownList = get_keys(conditionTree[unitPickerDropdownList[unitPickerDropdownListKey]])
        subjectPickerDropdown:SetList(subjectPickerDropdownList)
        subjectPickerDropdown:SetValue(1)
        subjectPickerDropdown:Fire("OnValueChanged")
        --comparerPickerDropdown:SetList({})
        --comparerPickerDropdown:SetText("")
        --comparerPickerDropdown:Fire("OnValueChanged")
        drop1 = true
        saveButton:SetDisabled(not (drop1 and drop2 and drop3))
    end)

    
    
    subjectPickerDropdown:SetLabel("Subject Picker")
    subjectPickerDropdown:SetFullWidth()
    subjectPickerDropdown:SetCallback("OnValueChanged", function(widget, event, key) 
        key = key or 1
        --print("subject: " .. subjectPickerDropdownList[key])
        subjectPickerDropdownListKey = key
        baseConditon.subject = subjectPickerDropdownList[key]

        if baseConditon.subject == "Buffs" then
            --show buffpicker, hide search
            searchValue.frame:Hide()
            buffPickerDropdown.frame:Show()
            buffSelectList = {}
            local buffSelect 

            if baseConditon.unit == "Player" then
                buffSelect = DPSGenie:getCapturedPlayerBuffs()
            else
                buffSelect = DPSGenie:getCapturedTargetBuffs()
            end

            for k, v in pairs(buffSelect) do
                local name, rank, icon, powerCost, isFunnel, powerType, castingTime, minRange, maxRange = GetSpellInfo(k)
                buffSelectList[k] = format("|T%s:32:32|t %s", icon, name)
            end

            buffPickerDropdown:SetList(buffSelectList)

        else
            searchValue.frame:Show()
            buffPickerDropdown.frame:Hide()
        end

        comparerPickerDropdownList = conditionTree[unitPickerDropdownList[unitPickerDropdownListKey]][subjectPickerDropdownList[subjectPickerDropdownListKey]]
        comparerPickerDropdown:SetList(comparerPickerDropdownList)
        comparerPickerDropdown:SetValue(1)
        comparerPickerDropdown:Fire("OnValueChanged")
        drop2 = true
        saveButton:SetDisabled(not (drop1 and drop2 and drop3))
    end)

    
    comparerPickerDropdown:SetLabel("Comparer Picker")
    comparerPickerDropdown:SetFullWidth()
    comparerPickerDropdown:SetCallback("OnValueChanged", function(widget, event, key)
        key = key or 1
        --print("comparer: " .. conditionTree[unitPickerDropdownList[unitPickerDropdownListKey]][subjectPickerDropdownList[subjectPickerDropdownListKey]][key])
        baseConditon.comparer = conditionTree[unitPickerDropdownList[unitPickerDropdownListKey]][subjectPickerDropdownList[subjectPickerDropdownListKey]][key]

        if baseConditon.subject == "Buffs" and (baseConditon.comparer == "more than" or baseConditon.comparer == "less than") then
            --show buffpicker, hide search
            searchValue.frame:Show()
            buffPickerDropdown.frame:Show()
        elseif baseConditon.subject == "Buffs" and baseConditon.comparer == "contains" then
            searchValue.frame:Hide()
            buffPickerDropdown.frame:Show()
        end

        drop3 = true
        saveButton:SetDisabled(not (drop1 and drop2 and drop3))
    end)


    --buffpicker needs condition -> only if subject buffs and respecting unit
    

    buffPickerDropdown:SetLabel("Buff Select")
    buffPickerDropdown:SetFullWidth()
    buffPickerDropdown:SetCallback("OnValueChanged", function(widget, event, key) 
        --key = key or 1
        --print("buff select: " .. key)
        baseConditon.compare_value = key
        drop4 = true
        --saveButton:SetDisabled(not (drop1 and drop2 and drop3 and edittext))
    end)
    buffPickerDropdown.frame:Hide()

    searchValue:SetFullWidth(true)
    searchValue:SetLabel("Search: ")
    searchValue:DisableButton(true)
    searchValue:SetCallback("OnTextChanged", function(widget, event, text) 
        if text ~= ""  then
            edittext = true
        else
            edittext = false
        end
        saveButton:SetDisabled(not (drop1 and drop2 and drop3))
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

        --swap for convenience
        if baseConditon.search and baseConditon.compare_value then
            baseConditon.search, baseConditon.compare_value = baseConditon.compare_value, baseConditon.search
        end

        if not baseConditon.compare_value or baseConditon.compare_value == "" then
            baseConditon.compare_value = nil
        end

        --print("add condition to " .. rotaTitle .. " Spell " .. rotaSpell)
        --print(DPSGenie:dumpTable(baseConditon))
        DPSGenie:addConditionToSpell(rotaTitle, group, rotaSpell, baseConditon)
        if conditionPickerFrame then
            pcall(conditionPickerFrame:Fire("OnClose")) --pcall ...
        end

    end)                 
    buttonsContainer:AddChild(saveButton)

    local cancelButton = AceGUI:Create("Button")
    cancelButton:SetText("Cancel")
    cancelButton:SetWidth(75)   
    cancelButton:SetCallback("OnClick", function(widget) 
        if conditionPickerFrame then
            pcall(conditionPickerFrame:Fire("OnClose"))
        end
    end)                
    buttonsContainer:AddChild(cancelButton)

    conditionPickerFrame:AddChild(addConditionLabel)
    conditionPickerFrame:AddChild(unitPickerDropdown)
    conditionPickerFrame:AddChild(subjectPickerDropdown)
    conditionPickerFrame:AddChild(comparerPickerDropdown)
    conditionPickerFrame:AddChild(buffPickerDropdown)
    buffPickerDropdown.frame:Hide()
    conditionPickerFrame:AddChild(searchValue)
    conditionPickerFrame:AddChild(buttonsContainer)

    conditionPickerFrame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
    conditionPickerFrame:SetCallback("OnAcquire", function(widget) print("OnAcquire") buffPickerDropdown.frame:Hide() end)
    conditionPickerFrame:Show()

end

--TODO: add option to show all spells available for players, not just learned
--TODO: add option to ignore rank so spellsuggest will always show hightest rank known
function DPSGenie:showSpellPicker(rotaTitle, group)
    spellPickerFrame = AceGUI:Create("Window")
    spellPickerFrame:SetPoint("TOPLEFT", Rotaframe.frame, "TOPRIGHT")
    spellPickerFrame:SetTitle("DPSGenie Spell Picker")
    spellPickerFrame:SetWidth(300)
    --spellPickerFrame:SetHeight(200)
    spellPickerFrame:SetHeight(350)
    spellPickerFrame:SetLayout("List")
    spellPickerFrame:EnableResize(false)
    spellPickerFrame.title:SetScript("OnMouseDown", nil)
    spellPickerFrame.frame:SetFrameStrata("HIGH")

    local templist = {}
    local tablelist = {}
       -- Iteriere über alle Zaubersprüche im Buch des Spielers
    for i = 3, MAX_SKILLLINE_TABS do
        local name, texture, offset, numSpells = GetSpellTabInfo(i)
        
        for j = offset + 1, offset + numSpells do
        spellLink, tradeLink = GetSpellLink(j, BOOKTYPE_SPELL)
        --usable, nomana = IsUsableSpell(j, BOOKTYPE_SPELL)
        isPassive = IsPassiveSpell(j, BOOKTYPE_SPELL);
        if spellLink and not isPassive then
            local spellID = tonumber(string.match(spellLink, "spell:(%d+)"))
            local name, rank, icon, powerCost, isFunnel, powerType, castingTime, minRange, maxRange = GetSpellInfo(spellID)
            --if IsHarmfulSpell(name) or IsHelpfulSpell(name) then
                templist[format("|T%s:32:32|t %s", icon, name)] = spellID
                --if DPSGenie:isValidSpell(spellID) then
                    --table.insert(tablelist, {format("|T%s:48:48|t %s (%s)", icon, name, rank), spellID})
                --end
            --end
            --print(spellID)
        end
        end
    end

    local entries = C_CharacterAdvancement.GetKnownSpellEntries()

    for index, value in pairs(entries) do
    --print("num spells: " .. #value.Spells)
    if value["Type"] == "Ability" or value["Type"] == "TalentAbility" then
        for si, sv in pairs(value.Spells) do
            --print(sv)
            local name, rank, icon, castTime, minRange, maxRange, spellID, originalIcon = GetSpellInfo(sv)
            --print(name .. " " .. rank)
            --table.insert(spelltable, sv)
            table.insert(tablelist, {format("|T%s:48:48|t %s", icon, name), sv}) 
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
    addSpellLabel:SetText("Add spell to: " .. rotaTitle .. " group " .. group)

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



    --TODO: make better spellpicker 
    local ScrollingTable = LibStub("ScrollingTable");
    local cols = {
        {
            ["name"] = "",
            ["width"] = 240,
            ["align"] = "LEFT",
            ["color"] = { 
                ["r"] = 1, 
                ["g"] = 1, 
                ["b"] = 1.0, 
                ["a"] = 1.0 
            },
        },
        {
            ["name"] = "ID",
            ["width"] = 0,
            ["align"] = "LEFT",
            ["color"] = { 
                ["r"] = 1, 
                ["g"] = 1, 
                ["b"] = 1.0, 
                ["a"] = 1.0 
            },
        }
    }
    local spTable = ScrollingTable:CreateST(cols, 7, 35, nil, spellPickerFrame.frame)
    spTable.frame:SetPoint("TOPLEFT", spellPickerFrame.frame, "TOPLEFT", 15, -50)
    local data = tablelist
    spTable:SetData(data, true)
    spTable:EnableSelection(true)

    spTable:RegisterEvents({
        ["OnClick"] = function (rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable, ...)
            --print("spell selected: " .. data[realrow][2])
            local name, rank, icon, powerCost, isFunnel, powerType, castingTime, minRange, maxRange = GetSpellInfo(data[realrow][2])
            selectedSpell = data[realrow][2]
            saveButton:SetDisabled(false)
            label:SetImage(icon)
            label:SetImageSize(32, 32)
            label:SetText(name)
        end,
        ["OnEnter"] = function (rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable, ...)
            --print("on enter spell selected: " .. data[realrow][2])
            --if data[realrow] ~= nil and data[realrow][2] ~= nil then
            --    GameTooltip:SetOwner(rowFrame, "ANCHOR_CURSOR")
            --    GameTooltip:SetHyperlink("spell:" .. data[realrow][2])
            --    GameTooltip:Show()
            --end
        end,
        ["OnLeave"] = function (rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable, ...)
            --print("on leave spell selected: " .. data[realrow][2])
            --GameTooltip:Hide()
        end,
    });

    --pcall(spellPickerFrame:AddChild(table))

    local buttonsContainer = AceGUI:Create("SimpleGroup")
    buttonsContainer:SetFullWidth(true)
    buttonsContainer:SetHeight(50)
    buttonsContainer:SetLayout("Flow")

    saveButton:SetText("Save")
    saveButton:SetWidth(75) 
    saveButton:SetCallback("OnClick", function(widget) 
        DPSGenie:addSpellToRota(rotaTitle, group, selectedSpell)
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
    --spellPickerFrame:AddChild(spellPickerDropdown)
    --spellPickerFrame:AddChild(label)
    --spellPickerFrame:AddChild(buttonsContainer)
    buttonsContainer.frame:SetPoint("BOTTOMLEFT", spellPickerFrame.frame, "BOTTOMLEFT", 15, 15)
    
    spellPickerFrame:SetCallback("OnClose", function(widget) 
        AceGUI:Release(widget); 
        spTable:Hide(); 
        spTable.frame = nil; 
        spTable = nil; 
        buttonsContainer.frame:Hide();
    end)
    spellPickerFrame:Show()
end

function DPSGenie:addSpellToRota(rota, group, spell)
    --print("adding " .. spell .. " to " .. rota)
    table.insert(customRotas[rota].spells[group], {spellId = spell, conditions = {}})
    DPSGenie:SaveCustomRota(rota, customRotas[rota])
    DPSGenie:DrawRotaGroup(rotaTree, rota, "custom", group)
end

function DPSGenie:addConditionToSpell(rotaTitle, group, rotaSpell, condition)
    table.insert(customRotas[rotaTitle].spells[group][rotaSpell]["conditions"], condition)
    DPSGenie:SaveCustomRota(rotaTitle, customRotas[rotaTitle])
    DPSGenie:DrawRotaGroup(rotaTree, rotaTitle, "custom", group)
end

function DPSGenie:removeSpellFromRota(rota, group, index)
    table.remove(customRotas[rota].spells[group], index)
    DPSGenie:SaveCustomRota(rota, customRotas[rota])
    DPSGenie:DrawRotaGroup(rotaTree, rota, "custom", group)
end

function DPSGenie:removeConditionFromSpell(rota, group, spell, index)
    table.remove(customRotas[rota].spells[group][spell].conditions, index)
    DPSGenie:SaveCustomRota(rota, customRotas[rota])
    DPSGenie:DrawRotaGroup(rotaTree, rota, "custom", group)
end

function DPSGenie:swapSpells(rota, group, index1, index2)
    tbl = customRotas[rota]
    if tbl and tbl.spells and tbl.spells[group] and tbl.spells[group][index1] and tbl.spells[group][index2] then
        --print("would swap")
        tbl.spells[group][index1], tbl.spells[group][index2] = tbl.spells[group][index2], tbl.spells[group][index1]
    end
    DPSGenie:SaveCustomRota(rota, customRotas[rota])
    DPSGenie:DrawRotaGroup(rotaTree, rota, "custom", group)
end 

function DPSGenie:AddNewGroupToRota(rota)
    table.insert(customRotas[rota].spells, {})
    DPSGenie:SaveCustomRota(rota, customRotas[rota])
    DPSGenie:DrawRotaGroup(rotaTree, rota, "custom", 1)
end

function DPSGenie:ConvertOldProfileToSubProfile(rota)
    local oldSpells = {}
    --Internal_CopyToClipboard(DPSGenie:dumpTable(customRotas[rota]))
    print(rota)
    for index, value in ipairs(customRotas[rota].spells) do
        table.insert(oldSpells, value)
    end
    print(#oldSpells .. " spells in old rota " .. rota)

    for k in pairs (customRotas[rota].spells) do
        customRotas[rota].spells[k] = nil
    end

    table.insert(customRotas[rota].spells, {})
    customRotas[rota].spells[1] = oldSpells

    DPSGenie:SaveCustomRota(rota, customRotas[rota])
    DPSGenie:DrawRotaGroup(rotaTree, rota, "custom", 1)
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
			value = "welcome",
			text = "Welcome",
            icon = "Interface\\Icons\\inv_misc_book_06",
		},
		{
			value = "newRotation",
			text = "new Rotation",
            icon = "Interface\\Icons\\Spell_chargepositive",
		},
        {
			value = "importRotation",
			text = "import Rotation",
            icon = "Interface\\Addons\\DPSGenie\\Images\\save.tga",
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
        table.insert(tree[4].children, entry)
    end 

    if customRotas then
        for k, v in pairs(customRotas) do
            local activeName = v.name
            --if v.name == DPSGenie:LoadSettingFromProfile("activeRota") then
            --    activeName = "\124cFF00FF00" .. v.name .. "\124r"
            --end
            local entry = {value = v.name, text = activeName, icon = v.icon}
            table.insert(tree[5].children, entry)
        end 
    end

	return tree
end

function DPSGenie:DrawWelcomeWindow(container)

    local dpsgVersion = GetAddOnMetadata("DPSGenie", "Version") 

    local groupScrollContainer = AceGUI:Create("SimpleGroup")
    groupScrollContainer:SetFullWidth(true)
    groupScrollContainer:SetFullHeight(true)
    groupScrollContainer:SetLayout("List")
    

    local DPSGenieHeader = AceGUI:Create("Heading")
    DPSGenieHeader:SetFullWidth(true)
    DPSGenieHeader:SetText("DPSGenie - " .. dpsgVersion)
    groupScrollContainer:AddChild(DPSGenieHeader)

    local DPSGenieImage = AceGUI:Create("Icon")
    DPSGenieImage:SetImage("Interface\\Addons\\DPSGenie\\Images\\genie.tga")
    DPSGenieImage:SetImageSize(256, 256)
    DPSGenieImage.frame:SetPushedTexture(nil, "ARTWORK")
    DPSGenieImage.frame:SetHighlightTexture(nil, "ARTWORK")
    DPSGenieImage.frame:ClearAllPoints()
    DPSGenieImage.frame:SetParent(groupScrollContainer.frame)
    DPSGenieImage.frame:SetPoint("TOP", groupScrollContainer.frame, "TOP", 0, -20)
    DPSGenieImage.frame:EnableMouse(false)
    DPSGenieImage.frame:Show()
    --groupScrollContainer:AddChild(DPSGenieImage)

    local DPSGenieWelcomeText = AceGUI:Create("Label")
    --DPSGenieWelcomeText:SetFullWidth(true)
    DPSGenieWelcomeText:SetHeight(50)
    DPSGenieWelcomeText:SetWidth(380)
    DPSGenieWelcomeText:SetText([[Ahoy, brave adventurers of Azeroth!
Your wishes are my commands with the dazzling, brand-new addon that's here to revolutionize your gameplay.
Ever felt lost in the heat of battle, unsure of your next move?
Fear not, for I, your digital genie, have conjured up the ultimate solution!
Introducing DPSGenie, an addon that's all-knowing and all-seeing.
Whether it's the fiercest dragon or the trickiest dungeon, I'll whisper in your ear the perfect spell or attack, ensuring you never miss a beat.
Say goodbye to missed buffs and overlooked procs; with my guidance, your DPS will soar to new, unimaginable heights!
Let's turn the tables on your foes and show them the true power of a master strategist. 
Ready to unleash your full potential? Let the magic begin!]])

    DPSGenieWelcomeText.frame:ClearAllPoints()
    DPSGenieWelcomeText.frame:SetParent(groupScrollContainer.frame)
    DPSGenieWelcomeText.frame:SetPoint("TOP", DPSGenieImage.frame, "BOTTOM", 0, -10)
    DPSGenieWelcomeText.label:SetWidth(380)
    DPSGenieWelcomeText.frame:Show()
    --groupScrollContainer:AddChild(DPSGenieWelcomeText)


    groupScrollContainer:SetCallback("OnRelease", function(widget) DPSGenieImage.frame:Hide() DPSGenieWelcomeText.frame:Hide() end)
    container:AddChild(groupScrollContainer)

end


function DPSGenie:DrawImportWindow(container)
    local groupScrollContainer = AceGUI:Create("SimpleGroup")
    groupScrollContainer:SetFullWidth(true)
    groupScrollContainer:SetFullHeight(true)
    groupScrollContainer:SetLayout("List")

    local DPSGenieHeader = AceGUI:Create("Heading")
    DPSGenieHeader:SetFullWidth(true)
    DPSGenieHeader:SetText("DPSGenie Rota Import")
    groupScrollContainer:AddChild(DPSGenieHeader)

    local rotaText

    local rotaInput = AceGUI:Create("MultiLineEditBox")
    rotaInput:SetFullWidth(true)
    rotaInput:SetLabel("Compressed Rota String")
    rotaInput:SetNumLines(10)
    rotaInput:DisableButton(true)
    rotaInput:SetCallback("OnTextChanged", function(widget, event, text) 
        rotaText = text
    end)
    groupScrollContainer:AddChild(rotaInput)

    local importRotaButton = AceGUI:Create("Button")
    importRotaButton:SetText("Import")
    importRotaButton:SetWidth(75) 
    importRotaButton:SetCallback("OnClick", function(widget) 
        local rotaData = stringToTable(DPSGenie:decompress(rotaText))
        --DPSGenie:Print(DPSGenie:decompress(rotaText))
        local importrotaname = DPSGenie:ImportRotaToCustom(rotaData)
        rotaTree:SetTree(DPSGenie:GetRotaList())
        rotaTree:SelectByValue("customRotations\001"..importrotaname)
    end)                 
    groupScrollContainer:AddChild(importRotaButton)


    container:AddChild(groupScrollContainer)
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
            DPSGenie:DrawImportWindow(container)
        elseif selected == "welcome" then
            DPSGenie:DrawWelcomeWindow(container)
        else
            -- Finding out the selected path to get the rotaTitle
            -- Not conerned with ever clicking on Active/Inactive itself
            local rotaTitle = {strsplit("\001", selected)}
            tremove(rotaTitle, 1)
            rotaTitle = strjoin("?", unpack(rotaTitle))

            if rotaTitle ~= "" then
                DPSGenie:DrawRotaGroup(container, rotaTitle, selected, 1)
            end
        end
    end)

    rotaTree:SelectByPath("defaultRotations")
    rotaTree:SelectByPath("customRotations")
    rotaTree:SelectByPath("welcome")

    --TODO: if active rota, select by name -> but, active rota dont have to be the current version in the editor...
    --TODO: add versioning to rotas, lastedit timestamp or whatever
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


--TODO: make editbox for name and description a new window, as well for other options
function DPSGenie:DrawRotaGroup(group, rotaTitle, selected, tabindex)

    if not tabindex then
        tabindex = 1
    end

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


    --convert old format to new one
    if rotaData.spells[1].spellId ~= nil then
        print("this is an old profile!")
        DPSGenie:ConvertOldProfileToSubProfile(rotaTitle)
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


    local useRotaButton = AceGUI:Create("Button")
    useRotaButton:SetText("Use")
    useRotaButton:SetWidth(75) 
    useRotaButton:SetCallback("OnClick", function(widget) 
        DPSGenie:SetActiveRota(rotaData)
    end)                 
    groupScrollFrame:AddChild(useRotaButton)


    local copyRotaButton = AceGUI:Create("Button")
    copyRotaButton:SetText("Copy")
    copyRotaButton:SetWidth(75) 
    copyRotaButton:SetCallback("OnClick", function(widget) 
        local copyrotaname = DPSGenie:CopyRotaToCustom(rotaData)
        rotaTree:SetTree(DPSGenie:GetRotaList())
        rotaTree:SelectByValue("customRotations\001".. copyrotaname)
        --DPSGenie:DrawRotaGroup(rotaTree, "Copy of ".. rotaData.name, "custom")
    end)                 
    groupScrollFrame:AddChild(copyRotaButton)


    local deleteRotaButton = AceGUI:Create("Button")
    deleteRotaButton:SetText("Delete")
    deleteRotaButton:SetWidth(75) 
    deleteRotaButton:SetCallback("OnClick", function(widget) 
        --DPSGenie:Print("would delete rota: " .. rotaData.name)
        local dialog = StaticPopup_Show("CONFIRM_DELETE_ROTA", rotaData.name)
        if dialog then
            dialog.data = rotaData.name
        end       
    end)     
    if not readOnly then            
        groupScrollFrame:AddChild(deleteRotaButton)
    end


    local exportRotaButton = AceGUI:Create("Button")
    exportRotaButton:SetText("Export")
    exportRotaButton:SetWidth(75) 
    exportRotaButton:SetCallback("OnClick", function(widget) 
        local compressed = DPSGenie:compress(rotaData)
        --DPSGenie:Print(compressed)      
        --Internal_CopyToClipboard(compressed)
        DPSGenieExportString = compressed
        local dialog = StaticPopup_Show("COPY_ROTA_STRING")
    end)  
    if not readOnly then               
        groupScrollFrame:AddChild(exportRotaButton)
    end

    local rotainfoheader = AceGUI:Create("Heading")
    rotainfoheader:SetFullWidth(true)
    rotainfoheader:SetText("Rotation Infos")
    groupScrollFrame:AddChild(rotainfoheader)

 
    local titleEditBox = AceGUI:Create("EditBox")
    titleEditBox:SetWidth(290)
    titleEditBox:SetLabel("Title")
    titleEditBox:SetText(rotaData.name)
    titleEditBox:SetDisabled(readOnly)
    titleEditBox:DisableButton(true)

    local saveNewName = ""
    local titleSaveButton = AceGUI:Create("Button")
    titleSaveButton:SetText("Save")
    titleSaveButton:SetWidth(60) 
    titleSaveButton:SetDisabled(true)
    titleSaveButton:SetCallback("OnClick", function(widget) 
        if saveNewName ~= "" then
            DPSGenie:RenameCustomRota(rotaData.name, saveNewName)
            rotaTree:SetTree(DPSGenie:GetRotaList())
            rotaTree:SelectByValue("customRotations\001"..saveNewName)
        end
    end)                 

    titleEditBox:SetCallback("OnTextChanged", function(self) 
        local newname = self:GetText():match( "^%s*(.-)%s*$" )
        if DPSGenie:GetCustomRota(newname) and newname ~= rotaData.name and string.len(newname) < 1 then 
            self.editbox:SetTextColor(1,0,0)
            titleSaveButton:SetDisabled(true)
        else
            self.editbox:SetTextColor(1,1,1)
            titleSaveButton:SetDisabled(false)
            saveNewName = newname
        end
    end)

    groupScrollFrame:AddChild(titleEditBox)
    groupScrollFrame:AddChild(titleSaveButton)

    local descrEditBox = AceGUI:Create("MultiLineEditBox")
    descrEditBox:SetWidth(290)
    descrEditBox:SetNumLines(3)
    descrEditBox:SetLabel("Description")
    descrEditBox:SetText(rotaData.description)
    descrEditBox:SetDisabled(readOnly)
    descrEditBox:DisableButton(true)

    local saveNewDescr = ""
    local descrSaveButton = AceGUI:Create("Button")
    descrSaveButton:SetText("Save")
    descrSaveButton:SetWidth(60) 
    descrSaveButton:SetDisabled(true)
    descrSaveButton:SetCallback("OnClick", function(widget) 
        DPSGenie:UpdateRotaField(rotaData.name, "description", saveNewDescr)
    end)     

    descrEditBox:SetCallback("OnTextChanged", function(self) 
        local newdescr = self:GetText():match( "^%s*(.-)%s*$" )
        if newdescr ~= rotaData.description then
            descrSaveButton:SetDisabled(false)
            saveNewDescr = newdescr
        end
    end)

    groupScrollFrame:AddChild(descrEditBox)
    groupScrollFrame:AddChild(descrSaveButton)


    local RotaHeaderHeader = AceGUI:Create("Heading")
    RotaHeaderHeader:SetFullWidth(true)
    RotaHeaderHeader:SetText("Rotation Setup")
    groupScrollFrame:AddChild(RotaHeaderHeader)


    local tabList = {{text="+", value="addtab"}}

    --print("subs: " .. #rotaData.spells)
    --Internal_CopyToClipboard(DPSGenie:dumpTable(rotaData))
    for ksub, vsub in ipairs(rotaData.spells) do
        --print("sub: " .. ksub)
        local newTab = {}
        newTab.text = ksub
        newTab.value = ksub
        table.insert(tabList, #tabList, newTab)
    end

    local tab =  AceGUI:Create("TabGroup")
    tab:SetLayout("Flow")
    tab:SetFullWidth(true)
    tab:SetTabs(tabList)
    tab:SetCallback("OnGroupSelected", function(self, event, group)
        if group == "addtab" then
            local newTab = {}
            newTab.text = #tabList
            newTab.value = #tabList
            table.insert(tabList, #tabList, newTab)
            self:SetTabs(tabList)
            self:SelectTab(#tabList) --why u no work???
            DPSGenie:AddNewGroupToRota(rotaTitle)
            groupScrollFrame:DoLayout()
        else
            self:ReleaseChildren()


            for btnCnt = 1, #customButtons do
                customButtons[btnCnt].frame:Hide();
            end

             --containing frame for all the spells
            local labelRotaHeader = AceGUI:Create("SimpleGroup")
            labelRotaHeader:SetFullWidth(true)
            --labelRotaHeader:SetTitle("Spell Rotation")
            self:AddChild(labelRotaHeader)

            if rotaData.spells[group] then
                for ks, vs in ipairs(rotaData.spells[group]) do

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
                            if vc.subject == "Buffs" then
                                local name, rank, icon, castTime, minRange, maxRange, spellID, originalIcon = GetSpellInfo(vc.search)
                                currentConditionPartSearch:SetText("\124cFF00FF00Search:\124r " .. name .. " (ID: " .. vc.search .. ")")
                            else
                                currentConditionPartSearch:SetText("\124cFF00FF00Search:\124r " .. vc.search)
                            end
                            conditionPartHolder:AddChild(currentConditionPartSearch)


                            local deleteConditionButton = AceGUI:Create("Button")
                            deleteConditionButton:SetText("Delete Spell")
                            deleteConditionButton:SetWidth(20)  
                            deleteConditionButton:SetHeight(20)          
                            deleteConditionButton:SetCallback("OnClick", function(widget) 
                                local dialog = StaticPopup_Show("CONFIRM_DELETE_CONDITION")
                                if dialog then
                                    dialog.data = {s = ks, c = kc}
                                    dialog.data2 = {rota = rotaTitle, group = group}
                                end
                            end)   
                            table.insert(customButtons, deleteConditionButton)

                            deleteConditionButton.frame:ClearAllPoints()
                            deleteConditionButton.frame:SetParent(conditionPartHolder.frame)
                            deleteConditionButton.frame:SetPoint("TOPRIGHT", conditionPartHolder.frame, "TOPRIGHT", -10, -25)
                            deleteConditionButton.frame:SetNormalTexture("Interface\\Addons\\DPSGenie\\Images\\close.tga")
                            if not readOnly then
                                deleteConditionButton.frame:Show()
                            end

                            --[[
                            --TODO: reenable edit button
                            local editButton = AceGUI:Create("Button")
                            editButton:SetText("Edit")
                            editButton:SetWidth(75)    
                            if not readOnly then              
                                conditionPartHolder:AddChild(editButton)
                            end
                            ]]
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
                        DPSGenie:showConditionPicker(rotaTitle, group, ks)
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
                            dialog.data2 = {rota = rotaTitle, group = group}
                        end
                    end)   
                    table.insert(customButtons, deleteSpellButton)   
                    --rotaPartHolder:AddChild(deleteSpellButton)
                    
                    deleteSpellButton.frame:ClearAllPoints()
                    deleteSpellButton.frame:SetParent(rotaPartHolder.frame)
                    deleteSpellButton.frame:SetPoint("TOPRIGHT", rotaPartHolder.frame, "TOPRIGHT", -10, -25)
                    deleteSpellButton.frame:SetNormalTexture("Interface\\Addons\\DPSGenie\\Images\\close.tga")
                    if not readOnly then
                        deleteSpellButton.frame:Show()
                    end

                    local moveSpellUpButton = AceGUI:Create("Button")
                    moveSpellUpButton:SetWidth(20)   
                    moveSpellUpButton:SetHeight(20)           
                    moveSpellUpButton:SetCallback("OnClick", function(widget) 
                        --print("moveup " .. rotaTitle .. " io: " .. ks .. " in: " .. ks-1)
                        DPSGenie:swapSpells(rotaTitle, group, ks, ks-1)
                    end) 
                    
                    moveSpellUpButton.frame:ClearAllPoints()
                    moveSpellUpButton.frame:SetParent(rotaPartHolder.frame)
                    moveSpellUpButton.frame:SetPoint("TOPRIGHT", rotaPartHolder.frame, "TOPRIGHT", -35, -25)
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
                        DPSGenie:swapSpells(rotaTitle, group, ks, ks+1, group)
                    end)   
                    moveSpellDownButton.frame:ClearAllPoints()
                    moveSpellDownButton.frame:SetParent(rotaPartHolder.frame)
                    local xpos = -60
                    if ks == 1 then
                        xpos = -35
                    end
                    moveSpellDownButton.frame:SetPoint("TOPRIGHT", rotaPartHolder.frame, "TOPRIGHT", xpos, -25)
                    moveSpellDownButton.frame:SetNormalTexture("Interface\\Addons\\DPSGenie\\Images\\down.tga")
                    if ks ~= #rotaData.spells[group] then
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
                DPSGenie:showSpellPicker(rotaTitle, group)
            end)   

            if not readOnly then
                self:AddChild(addSpellButton)
            end

            groupScrollFrame:DoLayout()

        end
    end)
    tab:SelectTab(tabindex)
    groupScrollFrame:AddChild(tab)
    tab:SelectTab(tabindex)

end
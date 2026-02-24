local addonName, ns = ...
DPSGenie = LibStub("AceAddon-3.0"):GetAddon("DPSGenie")

--DPSGenie:Print("RotaEditor loaded!")

local AceGUI = LibStub("AceGUI-3.0")
local Rotaframe, rotaTree
local defaultRotas
local customRotas
local conditionPickerFrame, spellPickerFrame
local rotaGroupScrollFrame = nil  -- reference to current rota scroll frame
local rotaScrollValue = nil       -- saved scroll position for rota redraw

DPSGenie.exportString = ""

StaticPopupDialogs["COPY_ROTA_STRING"] = {
    text = "You can now copy the rota string with CTRL+C",
    button1 = "Done",
    OnShow = function (self)
        self.editBox:SetText(DPSGenie.exportString)
        self.editBox:HighlightText()
        self.editBox:SetFocus()
    end,
    EditBoxOnTextChanged = function (self)
        local parent = self:GetParent();
        parent.editBox:SetText(DPSGenie.exportString)
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


local numericOps = { "more than", "less than", "equals", "at least", "at most" }
local auraOps = { "contains", "not contains", "more than", "less than", "equals", "time left more than", "time left less than" }

local conditionTree = {
    ["Player"] = {
        ["Buffs"] = auraOps,
        ["Debuffs"] = auraOps,
        ["Health"] = numericOps,
        ["Mana"] = numericOps,
        ["Rage"] = numericOps,
        ["Energy"] = numericOps,
        ["Runic Power"] = numericOps,
        ["Combopoints"] = numericOps,
        ["Combat"] = { "in combat", "not in combat" },
        ["Stance"] = { "equals", "not equals" },
        ["Spell Cooldown"] = { "available", "on cooldown", "more than", "less than" },
        ["Spell Charges"] = { "more than", "less than", "equals" },
        ["Spell Known"] = { "known", "not known" },
        ["Item Cooldown"] = { "available", "on cooldown" },
        ["Item Equipped"] = { "is equipped", "is not equipped" },
        ["Threat"] = {
            "more than", "less than", "equals",
            "at least", "at most",
            "is tanking", "is not tanking",
        },
    },
    ["Target"] = {
        ["Buffs"] = auraOps,
        ["Debuffs"] = auraOps,
        ["Health"] = numericOps,
        ["Mana"] = numericOps,
        ["Casting"] = { "is casting", "is not casting", "is interruptible", "is not interruptible" },
        ["Classification"] = { "is boss", "is elite", "is player", "is normal" },
    },
    ["Focus"] = {
        ["Buffs"] = auraOps,
        ["Debuffs"] = auraOps,
        ["Health"] = numericOps,
        ["Mana"] = numericOps,
        ["Casting"] = { "is casting", "is not casting", "is interruptible", "is not interruptible" },
    },
    ["Mouseover"] = {
        ["Buffs"] = auraOps,
        ["Debuffs"] = auraOps,
        ["Health"] = numericOps,
        ["Mana"] = numericOps,
    },
    ["Pet"] = {
        ["Active"] = { "is active", "is not active" },
        ["Health"] = numericOps,
        ["Mana"] = numericOps,
        ["Buffs"] = auraOps,
        ["Debuffs"] = auraOps,
        ["Happy"] = { "is happy", "is not happy" },
        ["Threat"] = {
            "more than", "less than", "equals",
            "at least", "at most",
            "is tanking", "is not tanking",
        },
    },
}

-- Map condition unit names to WoW API unit tokens
local unitMap = { ["Player"] = "player", ["Target"] = "target", ["Pet"] = "pet", ["Focus"] = "focus", ["Mouseover"] = "mouseover" }

-- Live-scan current auras on a unit
local function scanCurrentAuras(wowUnit, filter)
    local auras = {}
    for i = 1, 40 do
        local name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID = UnitAura(wowUnit, i, filter)
        if not name then break end
        auras[spellID] = name
    end
    return auras
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


local function get_keys(t)
    local keys = {}
    for key,_ in pairs(t) do
        table.insert(keys, key)
    end
    return keys
end


function DPSGenie:showConditionPicker(rotaTitle, group, rotaSpell)

    local baseCondition = {
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
        baseCondition.unit = unitPickerDropdownList[key]
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
        baseCondition.subject = subjectPickerDropdownList[key]
        baseCondition.compare_value = nil
        drop4 = false

        local subject = baseCondition.subject
        local wowUnit = unitMap[baseCondition.unit] or "player"

        if subject == "Buffs" or subject == "Debuffs" then
            -- Show aura picker, hide search initially
            searchValue.frame:Hide()
            buffPickerDropdown.frame:Show()
            buffPickerDropdown:SetLabel(subject == "Buffs" and "Buff Select" or "Debuff Select")
            buffSelectList = {}

            -- Determine aura filter
            local filter = subject == "Buffs" and "HELPFUL" or "HARMFUL"
            if subject == "Debuffs" and baseCondition.unit == "Target" then
                filter = "PLAYER|HARMFUL"
            end

            -- Merge captured auras with live scan
            local mergedAuras = scanCurrentAuras(wowUnit, filter)
            local capturedAuras = {}
            if subject == "Buffs" and baseCondition.unit == "Player" then
                capturedAuras = DPSGenie:getCapturedPlayerBuffs()
            elseif subject == "Debuffs" and baseCondition.unit == "Target" then
                capturedAuras = DPSGenie:getCapturedTargetBuffs()
            end
            for id, name in pairs(capturedAuras) do mergedAuras[id] = name end

            for id, name in pairs(mergedAuras) do
                local spellName, rank, icon = GetSpellInfo(id)
                if spellName and icon then
                    buffSelectList[id] = format("|T%s:32:32|t %s", icon, spellName)
                end
            end
            buffPickerDropdown:SetList(buffSelectList)

        elseif subject == "Spell Cooldown" or subject == "Spell Charges" or subject == "Spell Known" then
            -- Reuse buff picker dropdown for spell selection
            searchValue.frame:Hide()
            buffPickerDropdown.frame:Show()
            buffPickerDropdown:SetLabel("Spell Select")
            buffSelectList = {}

            local spellList = DPSGenie.cachedSpellList or DPSGenie:BuildSpellList()
            DPSGenie.cachedSpellList = spellList
            for _, row in ipairs(spellList) do
                buffSelectList[row[2]] = row[1]
            end
            buffPickerDropdown:SetList(buffSelectList)

        elseif subject == "Item Cooldown" or subject == "Item Equipped" then
            -- Reuse buff picker dropdown for item selection
            searchValue.frame:Hide()
            buffPickerDropdown.frame:Show()
            buffPickerDropdown:SetLabel("Item Select")
            buffSelectList = {}

            local itemTable = DPSGenie:BuildItemList()
            for _, row in pairs(itemTable) do
                buffSelectList[row[2]] = row[1]
            end
            buffPickerDropdown:SetList(buffSelectList)

        elseif subject == "Stance" then
            -- Show stance picker dropdown (populated with current stances)
            searchValue.frame:Hide()
            buffPickerDropdown.frame:Show()
            buffPickerDropdown:SetLabel("Stance/Form Select")
            buffSelectList = {}
            -- Index 0 = no stance/form
            buffSelectList[0] = "No Stance/Form"
            local numForms = GetNumShapeshiftForms and GetNumShapeshiftForms() or 0
            for i = 1, numForms do
                local icon, name, isActive = GetShapeshiftFormInfo(i)
                if name then
                    buffSelectList[i] = format("|T%s:32:32|t %s", icon or "", name)
                else
                    buffSelectList[i] = "Form " .. i
                end
            end
            buffPickerDropdown:SetList(buffSelectList)

        elseif subject == "Combat" or subject == "Active" or subject == "Happy"
            or subject == "Casting" or subject == "Classification" then
            -- No additional input needed — comparer alone is sufficient
            searchValue.frame:Hide()
            buffPickerDropdown.frame:Hide()

        else
            -- Numeric subjects (Health, Mana, Rage, Energy, Runic Power, Combopoints, Threat)
            searchValue.frame:Show()
            searchValue:SetLabel("Value")
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
        baseCondition.comparer = conditionTree[unitPickerDropdownList[unitPickerDropdownListKey]][subjectPickerDropdownList[subjectPickerDropdownListKey]][key]

        local subject = baseCondition.subject
        local comparer = baseCondition.comparer

        if subject == "Buffs" or subject == "Debuffs" then
            buffPickerDropdown.frame:Show()
            if comparer == "contains" or comparer == "not contains" then
                searchValue.frame:Hide()
            elseif comparer == "time left more than" or comparer == "time left less than" then
                searchValue.frame:Show()
                searchValue:SetLabel("Seconds")
            else -- "more than", "less than", "equals"
                searchValue.frame:Show()
                searchValue:SetLabel("Stack Count")
            end

        elseif subject == "Spell Cooldown" then
            buffPickerDropdown.frame:Show()
            if comparer == "available" or comparer == "on cooldown" then
                searchValue.frame:Hide()
            else -- "more than", "less than"
                searchValue.frame:Show()
                searchValue:SetLabel("Seconds")
            end

        elseif subject == "Spell Charges" then
            buffPickerDropdown.frame:Show()
            searchValue.frame:Show()
            searchValue:SetLabel("Charges")

        elseif subject == "Spell Known" or subject == "Item Cooldown" or subject == "Item Equipped" then
            buffPickerDropdown.frame:Show()
            searchValue.frame:Hide()

        elseif subject == "Stance" then
            buffPickerDropdown.frame:Show()
            searchValue.frame:Hide()

        elseif subject == "Combat" or subject == "Active" or subject == "Happy"
            or subject == "Casting" or subject == "Classification" then
            searchValue.frame:Hide()
            buffPickerDropdown.frame:Hide()

        elseif subject == "Threat" then
            buffPickerDropdown.frame:Hide()
            if comparer == "is tanking" or comparer == "is not tanking" then
                searchValue.frame:Hide()
            else
                searchValue.frame:Show()
                searchValue:SetLabel("Percentage")
            end

        else
            -- Numeric (Health, Mana, Rage, Energy, Runic Power, Combopoints)
            buffPickerDropdown.frame:Hide()
            searchValue.frame:Show()
            searchValue:SetLabel("Value")
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
        baseCondition.compare_value = key
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
        baseCondition.search = searchValue:GetText()

        -- Swap search and compare_value when both are set (buff/spell picker + threshold)
        if baseCondition.search and baseCondition.search ~= "" and baseCondition.compare_value then
            baseCondition.search, baseCondition.compare_value = baseCondition.compare_value, baseCondition.search
        elseif baseCondition.compare_value and (not baseCondition.search or baseCondition.search == "") then
            -- Only picker value set, no threshold — move to search
            baseCondition.search = baseCondition.compare_value
            baseCondition.compare_value = nil
        end

        if not baseCondition.compare_value or baseCondition.compare_value == "" then
            baseCondition.compare_value = nil
        end
        if not baseCondition.search or baseCondition.search == "" then
            baseCondition.search = nil
        end

        --print("add condition to " .. rotaTitle .. " Spell " .. rotaSpell)
        --print(DPSGenie:dumpTable(baseCondition))
        DPSGenie:addConditionToSpell(rotaTitle, group, rotaSpell, baseCondition)
        if conditionPickerFrame then
            pcall(function() conditionPickerFrame:Fire("OnClose") end)
        end

    end)                 
    buttonsContainer:AddChild(saveButton)

    local cancelButton = AceGUI:Create("Button")
    cancelButton:SetText("Cancel")
    cancelButton:SetWidth(75)   
    cancelButton:SetCallback("OnClick", function(widget) 
        if conditionPickerFrame then
            pcall(function() conditionPickerFrame:Fire("OnClose") end)
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

function DPSGenie:BuildSpellList()
    local spellList = {}
    local ok, entries = pcall(function() return C_CharacterAdvancement.GetKnownSpellEntries() end)
    if ok and entries then
        for index, value in pairs(entries) do
            if value["Type"] == "Ability" or value["Type"] == "TalentAbility" then
                for si, sv in pairs(value.Spells) do
                    local name, rank, icon = GetSpellInfo(sv)
                    if name and icon then
                        local rankText = (rank and rank ~= "") and rank or ""
                        table.insert(spellList, {format("|T%s:32:32|t %s", icon, name), sv, rankText})
                    end
                end
            end
        end
    end
    -- Fallback: spellbook scan for class-bound realms
    if #spellList == 0 then
        local numTabs = GetNumSpellTabs()
        for tab = 1, numTabs do
            local tabName, tabTexture, offset, numSpells = GetSpellTabInfo(tab)
            for i = offset + 1, offset + numSpells do
                local spellName, spellRank = GetSpellBookItemName(i, BOOKTYPE_SPELL)
                if spellName then
                    local link = GetSpellLink(i, BOOKTYPE_SPELL)
                    if link then
                        local sv = tonumber(link:match("spell:(%d+)"))
                        if sv then
                            local name, rank, icon = GetSpellInfo(sv)
                            if name and icon then
                                local rankText = (rank and rank ~= "") and rank or ""
                                table.insert(spellList, {format("|T%s:32:32|t %s", icon, name), sv, rankText})
                            end
                        end
                    end
                end
            end
        end
    end
    return spellList
end

function DPSGenie:BuildItemList()
    local itemList = {}
    -- Scan bags (0-4) for usable items
    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local itemID = GetContainerItemID(bag, slot)
            if itemID then
                local itemSpell = GetItemSpell(itemID)
                if itemSpell then
                    local itemName, _, itemQuality, _, _, _, _, _, _, itemIcon = GetItemInfo(itemID)
                    if itemName and itemIcon then
                        local itemCount = GetItemCount(itemID)
                        local infoText = "x" .. itemCount
                        if not itemList["i:" .. itemID] then
                            local r, g, b = 1, 1, 1
                            if itemQuality then
                                r, g, b = GetItemQualityColor(itemQuality)
                            end
                            local displayName = format("|T%s:32:32|t |cff%02x%02x%02x%s|r", itemIcon, r*255, g*255, b*255, itemName)
                            itemList["i:" .. itemID] = {displayName, "i:" .. itemID, infoText}
                        end
                    end
                end
            end
        end
    end
    -- Scan equipped items (trinkets slots 13-14, plus other on-use slots)
    for equipSlot = 1, 19 do
        local itemID = GetInventoryItemID("player", equipSlot)
        if itemID then
            local itemSpell = GetItemSpell(itemID)
            if itemSpell then
                local itemName, _, itemQuality, _, _, _, _, _, _, itemIcon = GetItemInfo(itemID)
                if itemName and itemIcon and not itemList["i:" .. itemID] then
                    local r, g, b = 1, 1, 1
                    if itemQuality then
                        r, g, b = GetItemQualityColor(itemQuality)
                    end
                    local displayName = format("|T%s:32:32|t |cff%02x%02x%02x%s|r", itemIcon, r*255, g*255, b*255, itemName)
                    itemList["i:" .. itemID] = {displayName, "i:" .. itemID, "Equipped"}
                end
            end
        end
    end
    -- Convert to array
    local result = {}
    for _, row in pairs(itemList) do
        table.insert(result, row)
    end
    return result
end

function DPSGenie:showSpellPicker(rotaTitle, group)
    spellPickerFrame = AceGUI:Create("Window")
    spellPickerFrame:SetPoint("TOPLEFT", Rotaframe.frame, "TOPRIGHT")
    spellPickerFrame:SetTitle("DPSGenie Spell Picker")
    spellPickerFrame:SetWidth(420)
    spellPickerFrame:SetHeight(610)
    spellPickerFrame:SetLayout("List")
    spellPickerFrame:EnableResize(false)
    spellPickerFrame.title:SetScript("OnMouseDown", nil)
    spellPickerFrame.frame:SetFrameStrata("HIGH")

    -- Build or reuse cached lists
    if not DPSGenie.cachedSpellList then
        DPSGenie.cachedSpellList = DPSGenie:BuildSpellList()
    end

    local fullSpellTable = DPSGenie.cachedSpellList
    local fullItemTable = DPSGenie:BuildItemList()
    local spTable
    local pickerMode = "spells"

    -- Filter state
    local showHighestRankOnly = true
    local searchQuery = ""
    local emptyLabel

    local function applyFilters()
        local source
        if pickerMode == "items" then
            source = fullItemTable
        else
            source = fullSpellTable
        end

        -- Highest rank filter (spells only)
        if pickerMode == "spells" and showHighestRankOnly then
            local highestByName = {}
            for _, row in ipairs(source) do
                local name = select(1, GetSpellInfo(row[2]))
                if name then
                    if not highestByName[name] or row[2] > highestByName[name][2] then
                        highestByName[name] = row
                    end
                end
            end
            source = {}
            for _, row in pairs(highestByName) do
                table.insert(source, row)
            end
        end

        -- Text search filter
        if searchQuery ~= "" then
            local query = string.lower(searchQuery)
            local result = {}
            for _, row in ipairs(source) do
                local name
                local id = row[2]
                if type(id) == "string" and string.sub(id, 1, 2) == "i:" then
                    name = select(1, GetItemInfo(tonumber(string.sub(id, 3)))) or ""
                else
                    name = select(1, GetSpellInfo(id)) or ""
                end
                if string.find(string.lower(name), query, 1, true) then
                    table.insert(result, row)
                end
            end
            source = result
        end

        if spTable then
            spTable:SetData(source, true)
        end
        -- Show/hide empty state message
        if emptyLabel then
            if #source == 0 then
                emptyLabel:SetText("|cFFFF0000No " .. pickerMode .. " found.|r")
                emptyLabel.frame:Show()
            else
                emptyLabel.frame:Hide()
            end
        end
        return source
    end

    -- Header label
    local addSpellLabel = AceGUI:Create("Label")
    addSpellLabel:SetFullWidth(true)
    addSpellLabel:SetText("Add spell to: " .. rotaTitle .. " group " .. group)

    -- Picker mode dropdown (Spells / Items)
    local modeDropdown = AceGUI:Create("Dropdown")
    modeDropdown:SetWidth(120)
    modeDropdown:SetList({["spells"] = "Spells", ["items"] = "Items"})
    modeDropdown:SetValue("spells")
    modeDropdown:SetLabel("Type")
    modeDropdown:SetCallback("OnValueChanged", function(widget, event, key)
        pickerMode = key
        applyFilters()
    end)

    -- Search box
    local searchBox = AceGUI:Create("EditBox")
    searchBox:SetWidth(250)
    searchBox:SetLabel("Search")
    searchBox:DisableButton(true)
    searchBox:SetCallback("OnTextChanged", function(widget, event, text)
        searchQuery = text or ""
        applyFilters()
    end)

    -- Highest rank toggle
    local rankToggle = AceGUI:Create("CheckBox")
    rankToggle:SetFullWidth(true)
    rankToggle:SetLabel("Only show highest rank")
    rankToggle:SetValue(true)
    rankToggle:SetCallback("OnValueChanged", function(widget, event, value)
        showHighestRankOnly = value
        applyFilters()
    end)

    -- Empty state label
    emptyLabel = AceGUI:Create("Label")
    emptyLabel:SetFullWidth(true)
    emptyLabel:SetText("")
    emptyLabel.frame:Hide()

    local saveButton = AceGUI:Create("Button")
    saveButton:SetDisabled(true)
    local selectedSpell

    -- Scrolling table
    local ScrollingTable = LibStub("ScrollingTable")
    local cols = {
        {
            ["name"] = "",
            ["width"] = 280,
            ["align"] = "LEFT",
            ["color"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1.0, ["a"] = 1.0 },
        },
        {
            ["name"] = "ID",
            ["width"] = 0,
            ["align"] = "LEFT",
        },
        {
            ["name"] = "Info",
            ["width"] = 80,
            ["align"] = "RIGHT",
            ["color"] = { ["r"] = 0.7, ["g"] = 0.7, ["b"] = 0.7, ["a"] = 1.0 },
        },
    }
    spTable = ScrollingTable:CreateST(cols, 10, 32, nil, spellPickerFrame.frame)
    spTable.frame:SetPoint("TOPLEFT", spellPickerFrame.frame, "TOPLEFT", 15, -190)
    spTable:EnableSelection(true)
    applyFilters()

    spTable:RegisterEvents({
        ["OnClick"] = function(rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable, ...)
            if realrow and data[realrow] then
                selectedSpell = data[realrow][2]
                saveButton:SetDisabled(false)
            end
        end,
        ["OnEnter"] = function(rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable, ...)
            if realrow and data[realrow] then
                local id = data[realrow][2]
                GameTooltip:SetOwner(cellFrame, "ANCHOR_RIGHT")
                if type(id) == "string" and string.sub(id, 1, 2) == "i:" then
                    local itemID = tonumber(string.sub(id, 3))
                    GameTooltip:SetHyperlink("item:" .. itemID)
                else
                    GameTooltip:SetSpellByID(tonumber(id))
                end
                GameTooltip:Show()
            end
        end,
        ["OnLeave"] = function(rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable, ...)
            GameTooltip:Hide()
        end,
    })

    -- Buttons
    local buttonsContainer = AceGUI:Create("SimpleGroup")
    buttonsContainer:SetFullWidth(true)
    buttonsContainer:SetHeight(50)
    buttonsContainer:SetLayout("Flow")

    saveButton:SetText("Save")
    saveButton:SetWidth(75)
    saveButton:SetCallback("OnClick", function(widget)
        DPSGenie:addSpellToRota(rotaTitle, group, selectedSpell)
        if spellPickerFrame then
            pcall(function() spellPickerFrame:Fire("OnClose") end)
        end
    end)
    buttonsContainer:AddChild(saveButton)

    local cancelButton = AceGUI:Create("Button")
    cancelButton:SetText("Cancel")
    cancelButton:SetWidth(75)
    cancelButton:SetCallback("OnClick", function(widget)
        if spellPickerFrame then
            pcall(function() spellPickerFrame:Fire("OnClose") end)
        end
    end)
    buttonsContainer:AddChild(cancelButton)

    spellPickerFrame:AddChild(addSpellLabel)
    spellPickerFrame:AddChild(modeDropdown)
    spellPickerFrame:AddChild(searchBox)
    spellPickerFrame:AddChild(rankToggle)
    spellPickerFrame:AddChild(emptyLabel)

    buttonsContainer.frame:SetPoint("BOTTOMLEFT", spellPickerFrame.frame, "BOTTOMLEFT", 15, 15)
    buttonsContainer.frame:SetFrameStrata("DIALOG")
    buttonsContainer.frame:Show()

    spellPickerFrame:SetCallback("OnClose", function(widget)
        AceGUI:Release(widget)
        if spTable then
            spTable:Hide()
            spTable.frame = nil
            spTable = nil
        end
        buttonsContainer.frame:Hide()
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
    if not customRotas[rotaTitle] or not customRotas[rotaTitle].spells
        or not customRotas[rotaTitle].spells[group]
        or not customRotas[rotaTitle].spells[group][rotaSpell] then
        DPSGenie:Print("Error: Cannot add condition — rotation/spell no longer exists.")
        return
    end
    if not customRotas[rotaTitle].spells[group][rotaSpell]["conditions"] then
        customRotas[rotaTitle].spells[group][rotaSpell]["conditions"] = {}
    end
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
    local tbl = customRotas[rota]
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


function DPSGenie:showRotaBuilder(selectPage)
    if not Rotaframe then
        DPSGenie:CreateRotaBuilder()
    else
        if Rotaframe:IsVisible() and not selectPage then
            Rotaframe:Hide()
            return
        else
            Rotaframe:Show()
        end
    end
    if rotaTree then
        if selectPage then
            rotaTree:SelectByPath(selectPage)
        else
            DPSGenie:SelectActiveRotaInTree()
        end
    end
end

function DPSGenie:SelectActiveRotaInTree()
    local rota = DPSGenie:LoadSettingFromProfile("activeRota")
    if rota and rota.name then
        local customs = DPSGenie:GetCustomRotas()
        if customs and customs[rota.name] then
            rotaTree:SelectByPath("customRotations", rota.name)
            return
        end
        local defaults = DPSGenie:GetDefaultRotas()
        if defaults and defaults[rota.name] then
            rotaTree:SelectByPath("defaultRotations", rota.name)
            return
        end
    end
    -- No active rota found — show new rotation page
    rotaTree:SelectByPath("newRotation")
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
			value = "settings",
			text = "Settings",
            icon = "Interface\\Icons\\Trade_Engineering",
		},
        {
			value = "debug",
			text = "Debug",
            icon = "Interface\\Icons\\INV_Misc_Gear_01",
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
        table.insert(tree[6].children, entry)
    end

    if customRotas then
        for k, v in pairs(customRotas) do
            local activeName = v.name
            --if v.name == DPSGenie:LoadSettingFromProfile("activeRota") then
            --    activeName = "\124cFF00FF00" .. v.name .. "\124r"
            --end
            local entry = {value = v.name, text = activeName, icon = v.icon}
            table.insert(tree[7].children, entry)
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


function DPSGenie:DrawSettingsPanel(container)
    local groupScrollContainer = AceGUI:Create("SimpleGroup")
    groupScrollContainer:SetFullWidth(true)
    groupScrollContainer:SetFullHeight(true)
    groupScrollContainer:SetLayout("List")

    local header = AceGUI:Create("Heading")
    header:SetFullWidth(true)
    header:SetText("Settings")
    groupScrollContainer:AddChild(header)

    -- Helper to create a setting checkbox
    local function addCheckbox(settingKey, label, description)
        local cb = AceGUI:Create("CheckBox")
        cb:SetFullWidth(true)
        cb:SetLabel(label)
        cb:SetDescription(description)
        cb:SetValue(DPSGenie:LoadSettingFromProfile(settingKey) and true or false)
        cb:SetCallback("OnValueChanged", function(widget, event, val)
            DPSGenie:SaveSettingToProfile(settingKey, val)
        end)
        groupScrollContainer:AddChild(cb)
    end

    -- Display settings
    local displayHeader = AceGUI:Create("Heading")
    displayHeader:SetFullWidth(true)
    displayHeader:SetText("Display")
    groupScrollContainer:AddChild(displayHeader)

    addCheckbox("showOutOfRange", "Show Out Of Range", "Show spells even when the target is out of range")
    addCheckbox("showEmpty", "Show Empty Button", "Show the spell button even when no spell is suggested")
    addCheckbox("showSpellFlash", "Show SpellFlash", "Highlight the matching action bar button with a pulse animation")
    addCheckbox("showKeybind", "Show Keybind", "Display the keybind text on the spell button")
    addCheckbox("showPrediction", "Show Prediction", "When no spell is ready, show the next spell that would be available (dimmed with cooldown)")

    -- Behavior settings
    local behaviorHeader = AceGUI:Create("Heading")
    behaviorHeader:SetFullWidth(true)
    behaviorHeader:SetText("Behavior")
    groupScrollContainer:AddChild(behaviorHeader)

    addCheckbox("onlyInCombat", "Only Show in Combat", "Only show spell buttons while you are in combat")
    addCheckbox("onlyWithTarget", "Only Show with Target", "Only show spell buttons when you have a target selected")

    container:AddChild(groupScrollContainer)
end


function DPSGenie:DrawDebugPanel(container)
    local groupScrollContainer = AceGUI:Create("SimpleGroup")
    groupScrollContainer:SetFullWidth(true)
    groupScrollContainer:SetFullHeight(true)
    groupScrollContainer:SetLayout("List")

    local header = AceGUI:Create("Heading")
    header:SetFullWidth(true)
    header:SetText("Debug Tools")
    groupScrollContainer:AddChild(header)

    -- Helper to create a debug action button
    local function addButton(label, description, onClick)
        local btn = AceGUI:Create("Button")
        btn:SetFullWidth(true)
        btn:SetText(label)
        btn:SetCallback("OnClick", onClick)
        groupScrollContainer:AddChild(btn)

        if description then
            local desc = AceGUI:Create("Label")
            desc:SetFullWidth(true)
            desc:SetText("|cFF999999" .. description .. "|r")
            groupScrollContainer:AddChild(desc)
        end
    end

    -- Toggle debug side pane
    addButton("Toggle Debug Side Pane", "Opens the debug overlay that shows real-time rotation evaluation details", function()
        DPSGenie:toggleDebug()
    end)

    -- Test SpellFlash
    addButton("Test SpellFlash", "Pauses the rotation engine and flashes action bar slot 1 for 5 seconds", function()
        if DPSGenie.RotaSchedule then
            DPSGenie:CancelTimer(DPSGenie.RotaSchedule)
        end
        if _G["BT4Button1"] and _G["BT4Button1"]:IsVisible() then
            DPSGenie:ShowPulseFrame(1, _G["BT4Button1"])
        elseif _G["ElvUI_Bar1Button1"] and _G["ElvUI_Bar1Button1"]:IsVisible() then
            DPSGenie:ShowPulseFrame(1, _G["ElvUI_Bar1Button1"])
        else
            DPSGenie:ShowPulseFrame(1, _G["ActionButton1"])
        end
        DPSGenie:Print("SpellFlash test: pulsing action bar slot 1 for 5 seconds.")
        DPSGenie:ScheduleTimer(function()
            DPSGenie:HidePulseFrame(1)
            DPSGenie.RotaSchedule = DPSGenie:ScheduleRepeatingTimer("runRotaTable", .250)
        end, 5)
    end)

    -- Test suggest buttons
    addButton("Test Suggest Buttons", "Pauses the rotation engine and shows 2 test spell buttons for 5 seconds", function()
        if DPSGenie.RotaSchedule then
            DPSGenie:CancelTimer(DPSGenie.RotaSchedule)
        end
        DPSGenie:SetupSpellButtons(2)
        -- Use Fireball (133) and Frostbolt (116) as recognizable test spells
        DPSGenie:SetSuggestSpell(1, "133", nil)
        DPSGenie:SetSuggestSpell(2, "116", nil)
        DPSGenie:Print("Suggest buttons test: showing 2 test buttons for 5 seconds.")
        DPSGenie:ScheduleTimer(function()
            DPSGenie:SetSuggestSpell(1, false, nil)
            DPSGenie:SetSuggestSpell(2, false, nil)
            DPSGenie.RotaSchedule = DPSGenie:ScheduleRepeatingTimer("runRotaTable", .250)
        end, 5)
    end)

    -- Rebuild spellbook cache
    addButton("Rebuild Spellbook Cache", "Force a rebuild of the spellbook index cache used for spell lookups", function()
        DPSGenie:RebuildSpellBookCache()
        DPSGenie:Print("Spellbook cache rebuilt.")
    end)

    -- Reindex action bar keybinds
    addButton("Reindex Keybinds", "Rescan all action bar slots and refresh keybind mappings", function()
        DPSGenie:GetSpellKeybinds()
        DPSGenie:Print("Action bar keybinds reindexed.")
    end)

    -- Open spell capture window
    addButton("Open Spell Capture", "Opens the aura/spell capture window for recording buff and debuff IDs", function()
        DPSGenie:showCapture()
    end)

    -- Print active rota info
    addButton("Print Active Rota Info", "Prints the currently active rotation name and spell count to chat", function()
        local rota = DPSGenie:GetActiveRota()
        if rota then
            local groupCount = #rota.spells
            local totalSpells = 0
            for _, group in ipairs(rota.spells) do
                totalSpells = totalSpells + #group
            end
            DPSGenie:Print("Active rota: " .. rota.name .. " (" .. groupCount .. " groups, " .. totalSpells .. " spells)")
        else
            DPSGenie:Print("No active rotation loaded.")
        end
    end)

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
        if not rotaText or rotaText == "" then
            DPSGenie:Print("Error: Please paste a rota string first.")
            return
        end
        if string.len(rotaText) > 102400 then
            DPSGenie:Print("Error: Import string too large (max 100KB).")
            return
        end
        local ok, rotaData = pcall(function()
            return stringToTable(DPSGenie:decompress(rotaText))
        end)
        if not ok or not rotaData then
            DPSGenie:Print("Error: Invalid rota string.")
            return
        end
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
            pcall(function() spellPickerFrame:Fire("OnClose") end)
        end
        if conditionPickerFrame then
            pcall(function() conditionPickerFrame:Fire("OnClose") end)
        end
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
        elseif selected == "settings" then
            DPSGenie:DrawSettingsPanel(container)
        elseif selected == "debug" then
            DPSGenie:DrawDebugPanel(container)
        else
            -- Finding out the selected path to get the rotaTitle
            -- Not conerned with ever clicking on Active/Inactive itself
            local rotaTitle = {strsplit("\001", selected)}
            tremove(rotaTitle, 1)
            rotaTitle = strjoin("\001", unpack(rotaTitle))

            if rotaTitle ~= "" then
                DPSGenie:DrawRotaGroup(container, rotaTitle, selected, 1)
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

local customButtons = {}


--TODO: make editbox for name and description a new window, as well for other options
function DPSGenie:DrawRotaGroup(group, rotaTitle, selected, tabindex)

    if not tabindex then
        tabindex = 1
    end

    --release custom buttons to prevent memory leaks
    for btnCnt = 1, #customButtons do
        customButtons[btnCnt].frame:SetNormalTexture(nil)
        customButtons[btnCnt].frame:Hide()
        AceGUI:Release(customButtons[btnCnt])
    end
    customButtons = {}

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

    -- Save scroll position from previous scroll frame before rebuilding
    if rotaGroupScrollFrame then
        local status = rotaGroupScrollFrame.status or rotaGroupScrollFrame.localstatus
        if status then
            rotaScrollValue = status.scrollvalue
        end
    end

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
    rotaGroupScrollFrame = groupScrollFrame

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
        DPSGenie.exportString = compressed
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
        if string.len(newname) < 1 or (DPSGenie:GetCustomRota(newname) and newname ~= rotaData.name) then
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
                customButtons[btnCnt].frame:SetNormalTexture(nil)
                customButtons[btnCnt].frame:Hide()
                AceGUI:Release(customButtons[btnCnt])
            end
            customButtons = {}

             --containing frame for all the spells
            local labelRotaHeader = AceGUI:Create("SimpleGroup")
            labelRotaHeader:SetFullWidth(true)
            --labelRotaHeader:SetTitle("Spell Rotation")
            self:AddChild(labelRotaHeader)

            if rotaData.spells[group] then
                for ks, vs in ipairs(rotaData.spells[group]) do

                    local name, icon
                    local actionPrefix = string.sub(vs.spellId, 1, 1)
                    if actionPrefix == "i" then
                        local itemId = tonumber(string.match(vs.spellId, "%d+"))
                        local itemName, _, _, _, _, _, _, _, _, itemIcon = GetItemInfo(itemId)
                        name = itemName
                        icon = itemIcon
                    elseif actionPrefix == "l" then
                        name = "Lua Script"
                    else
                        name, _, icon = GetSpellInfo(vs.spellId)
                    end
                    if not name then name = "Unknown" end
                    if not icon then icon = "Interface\\Icons\\INV_Misc_QuestionMark" end

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

                            -- Show search/value info based on subject type
                            if vc.search then
                                local currentConditionPartSearch = AceGUI:Create("Label")
                                currentConditionPartSearch:SetFullWidth(true)

                                if vc.subject == "Buffs" or vc.subject == "Debuffs" then
                                    local spellName = GetSpellInfo(vc.search)
                                    currentConditionPartSearch:SetText("\124cFF00FF00" .. vc.subject .. ":\124r " .. (spellName or "Unknown") .. " (ID: " .. vc.search .. ")")
                                elseif vc.subject == "Spell Cooldown" or vc.subject == "Spell Charges" or vc.subject == "Spell Known" then
                                    local spellName = GetSpellInfo(vc.search)
                                    currentConditionPartSearch:SetText("\124cFF00FF00Spell:\124r " .. (spellName or "Unknown") .. " (ID: " .. vc.search .. ")")
                                elseif vc.subject == "Item Cooldown" or vc.subject == "Item Equipped" then
                                    local itemID = vc.search
                                    if type(itemID) == "string" and string.sub(itemID, 1, 2) == "i:" then
                                        itemID = tonumber(string.sub(itemID, 3))
                                    end
                                    local itemName = select(1, GetItemInfo(itemID or 0)) or "Unknown"
                                    currentConditionPartSearch:SetText("\124cFF00FF00Item:\124r " .. itemName .. " (ID: " .. tostring(vc.search) .. ")")
                                elseif vc.subject == "Stance" then
                                    local formName = "No Stance/Form"
                                    local formIdx = tonumber(vc.search) or 0
                                    if formIdx > 0 then
                                        local _, name = GetShapeshiftFormInfo(formIdx)
                                        formName = name or ("Form " .. formIdx)
                                    end
                                    currentConditionPartSearch:SetText("\124cFF00FF00Form:\124r " .. formName .. " (" .. formIdx .. ")")
                                elseif vc.subject == "Threat" then
                                    currentConditionPartSearch:SetText("\124cFF00FF00Percentage:\124r " .. vc.search .. "%")
                                else
                                    currentConditionPartSearch:SetText("\124cFF00FF00Value:\124r " .. vc.search)
                                end
                                conditionPartHolder:AddChild(currentConditionPartSearch)
                            end

                            if vc.compare_value then
                                local currentConditionPartCompareValue = AceGUI:Create("Label")
                                currentConditionPartCompareValue:SetFullWidth(true)

                                if vc.subject == "Buffs" or vc.subject == "Debuffs" then
                                    if vc.comparer == "time left more than" or vc.comparer == "time left less than" then
                                        currentConditionPartCompareValue:SetText("\124cFF00FF00Time:\124r " .. vc.compare_value .. "s")
                                    else
                                        currentConditionPartCompareValue:SetText("\124cFF00FF00Stacks:\124r " .. vc.compare_value)
                                    end
                                elseif vc.subject == "Spell Cooldown" then
                                    currentConditionPartCompareValue:SetText("\124cFF00FF00Threshold:\124r " .. vc.compare_value .. "s")
                                elseif vc.subject == "Spell Charges" then
                                    currentConditionPartCompareValue:SetText("\124cFF00FF00Charges:\124r " .. vc.compare_value)
                                else
                                    currentConditionPartCompareValue:SetText("\124cFF00FF00Compare Value:\124r " .. vc.compare_value)
                                end
                                conditionPartHolder:AddChild(currentConditionPartCompareValue)
                            end


                            local deleteConditionButton = AceGUI:Create("Button")
                            deleteConditionButton:SetText("Delete Condition")
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
                            pcall(function() spellPickerFrame:Fire("OnClose") end)
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
                        DPSGenie:swapSpells(rotaTitle, group, ks, ks+1)
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
                    pcall(function() conditionPickerFrame:Fire("OnClose") end)
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

    -- Restore scroll position after a redraw (deferred one frame so layout completes)
    if rotaScrollValue then
        local pending = rotaScrollValue
        rotaScrollValue = nil
        local restoreFrame = CreateFrame("Frame")
        restoreFrame:SetScript("OnUpdate", function(self)
            self:SetScript("OnUpdate", nil)
            groupScrollFrame:SetScroll(pending)
        end)
    end

end
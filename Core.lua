local addonName, ns = ...
DPSGenie = LibStub("AceAddon-3.0"):GetAddon("DPSGenie")

DPSGenie:Print("Core loaded!")

DPSGenie.debugTable = {}

function DPSGenie:addToDebugTable(text)
    if not DPSGenie:debugEnabled() then return end
    table.insert(DPSGenie.debugTable, text)
end

-- Spellbook index cache for reliable spell lookups (name -> bookIndex)
local spellBookIndexCache = {}

function DPSGenie:RebuildSpellBookCache()
    spellBookIndexCache = {}
    local numTabs = GetNumSpellTabs()
    for tab = 1, numTabs do
        local _, _, offset, numSpells = GetSpellTabInfo(tab)
        for i = offset + 1, offset + numSpells do
            local bName = GetSpellBookItemName(i, BOOKTYPE_SPELL)
            if bName then
                spellBookIndexCache[bName] = i
            end
        end
    end
end

function DPSGenie:FindSpellBookIndex(spellName)
    if not next(spellBookIndexCache) then
        DPSGenie:RebuildSpellBookCache()
    end
    return spellBookIndexCache[spellName]
end

local activeRota

function DPSGenie:SetActiveRota(rotaTable)
    DPSGenie:Print("Setting active Rota to: " .. rotaTable.name)
    activeRota = DPSGenie:deepcopy(rotaTable)
    DPSGenie:SaveSettingToProfile("activeRota", rotaTable)

    -- Migrate old Target/Buffs conditions to Target/Debuffs (backward compat)
    for sindex, svalue in pairs(activeRota.spells) do
        for index, value in ipairs(svalue) do
            if value.conditions then
                for _, cond in ipairs(value.conditions) do
                    if cond.unit == "Target" and cond.subject == "Buffs" then
                        cond.subject = "Debuffs"
                    end
                end
            end
        end
    end

    -- build cache with, spellinfo, harmful, helpful

    --setup number suggestbuttons
    --print("buttons setup: " .. #activeRota.spells)
    DPSGenie:SetupSpellButtons(#activeRota.spells)
end

function DPSGenie:GetActiveRota()
    return activeRota
end

function DPSGenie:evaluateNumericComparison(comparer, value, threshold, cindex)
    if comparer == "less than" then
        if value < threshold then
            DPSGenie:addToDebugTable("less than condition passed!")
            return true
        end
    elseif comparer == "more than" then
        if value > threshold then
            DPSGenie:addToDebugTable("more than condition passed!")
            return true
        end
    elseif comparer == "equals" then
        if value == threshold then
            DPSGenie:addToDebugTable("equals condition passed!")
            return true
        end
    elseif comparer == "at least" then
        if value >= threshold then
            DPSGenie:addToDebugTable("at least condition passed!")
            return true
        end
    elseif comparer == "at most" then
        if value <= threshold then
            DPSGenie:addToDebugTable("at most condition passed!")
            return true
        end
    end
    return false
end

function DPSGenie:evaluateCondition(condition, cindex)
    local conditionUnit = string.lower(condition.unit)

    -- Pet guard: if unit is pet but no pet exists, only "is not active" passes
    if conditionUnit == "pet" and not UnitExists("pet") then
        DPSGenie:addToDebugTable("- c" .. cindex .. ": Pet does not exist")
        if condition.subject == "Active" and condition.comparer == "is not active" then
            DPSGenie:addToDebugTable("is not active condition passed!")
            return true
        end
        return false
    end

    -- Focus/Mouseover guard: if unit doesn't exist, condition fails
    if (conditionUnit == "focus" or conditionUnit == "mouseover") and not UnitExists(conditionUnit) then
        DPSGenie:addToDebugTable("- c" .. cindex .. ": " .. conditionUnit .. " does not exist")
        return false
    end

    -- Buffs / Debuffs
    if condition.subject == "Buffs" or condition.subject == "Debuffs" then
        local auraName = select(1, GetSpellInfo(condition.search))
        DPSGenie:addToDebugTable("- c" .. cindex .. ": " .. condition.subject .. " condition")
        DPSGenie:addToDebugTable("-- unit: " .. conditionUnit .. ", aura: " .. (auraName or "Unknown") .. " (" .. condition.search .. ")")

        -- Determine UnitAura filter
        local filter
        if condition.subject == "Buffs" then
            filter = "HELPFUL"
        else
            if conditionUnit == "player" then
                filter = "HARMFUL"
            else
                filter = "PLAYER|HARMFUL"
            end
        end

        local name, rank, icon, count, dispelType, duration, expires = UnitAura(conditionUnit, auraName, nil, filter)

        if condition.comparer == "contains" then
            DPSGenie:addToDebugTable("-- contains: count=" .. tostring(count))
            if count ~= nil then
                DPSGenie:addToDebugTable("contains condition passed!")
                return true
            end
        elseif condition.comparer == "not contains" then
            DPSGenie:addToDebugTable("-- not contains: count=" .. tostring(count))
            if count == nil then
                DPSGenie:addToDebugTable("not contains condition passed!")
                return true
            end
        elseif condition.comparer == "more than" then
            DPSGenie:addToDebugTable("-- more than: count=" .. tostring(count) .. " threshold=" .. condition.compare_value)
            if count ~= nil and count > tonumber(condition.compare_value) then
                DPSGenie:addToDebugTable("more than condition passed!")
                return true
            end
        elseif condition.comparer == "less than" then
            DPSGenie:addToDebugTable("-- less than: count=" .. tostring(count) .. " threshold=" .. condition.compare_value)
            if count ~= nil and count < tonumber(condition.compare_value) then
                DPSGenie:addToDebugTable("less than condition passed!")
                return true
            end
        elseif condition.comparer == "equals" then
            DPSGenie:addToDebugTable("-- equals: count=" .. tostring(count) .. " threshold=" .. condition.compare_value)
            if count ~= nil and count == tonumber(condition.compare_value) then
                DPSGenie:addToDebugTable("equals condition passed!")
                return true
            end
        elseif condition.comparer == "time left more than" then
            if expires and expires > 0 then
                local remaining = expires - GetTime()
                DPSGenie:addToDebugTable("-- time left: " .. string.format("%.1f", remaining) .. "s, threshold=" .. condition.compare_value)
                if remaining > tonumber(condition.compare_value) then
                    DPSGenie:addToDebugTable("time left more than condition passed!")
                    return true
                end
            else
                DPSGenie:addToDebugTable("-- aura not found, time left = 0")
            end
        elseif condition.comparer == "time left less than" then
            if not expires or expires == 0 then
                DPSGenie:addToDebugTable("-- aura not found, time left less than passes (needs refresh)")
                return true
            end
            local remaining = expires - GetTime()
            DPSGenie:addToDebugTable("-- time left: " .. string.format("%.1f", remaining) .. "s, threshold=" .. condition.compare_value)
            if remaining < tonumber(condition.compare_value) then
                DPSGenie:addToDebugTable("time left less than condition passed!")
                return true
            end
        end

        if count == nil then
            DPSGenie:addToDebugTable("-- aura count was nil")
        end
        return false
    end

    -- Health / Power types
    if condition.subject == "Health" or condition.subject == "Mana" or condition.subject == "Rage"
        or condition.subject == "Energy" or condition.subject == "Runic Power" then
        local percent = 0
        if condition.subject == "Health" then
            DPSGenie:addToDebugTable("- c" .. cindex .. ": Health condition")
            local max = UnitHealthMax(conditionUnit)
            local cur = UnitHealth(conditionUnit)
            if max > 0 then percent = (cur / max) * 100 end
        else
            local powertypes = { ["Mana"] = 0, ["Rage"] = 1, ["Focus"] = 2, ["Energy"] = 3, ["Runic Power"] = 6 }
            local powertype = powertypes[condition.subject]
            DPSGenie:addToDebugTable("- c" .. cindex .. ": " .. condition.subject .. " condition")
            local max = UnitPowerMax(conditionUnit, powertype)
            local cur = UnitPower(conditionUnit, powertype)
            if max > 0 then percent = (cur / max) * 100 end
        end
        percent = math.floor(percent)
        DPSGenie:addToDebugTable("-- current " .. condition.subject .. " of " .. conditionUnit .. ": " .. percent .. "%")
        DPSGenie:addToDebugTable("-- comparer: " .. condition.comparer .. " threshold: " .. condition.search)
        return DPSGenie:evaluateNumericComparison(condition.comparer, percent, tonumber(condition.search), cindex)
    end

    -- Combopoints
    if condition.subject == "Combopoints" then
        DPSGenie:addToDebugTable("- c" .. cindex .. ": Combopoints condition")
        local comboPoints = GetComboPoints("player", "target")
        DPSGenie:addToDebugTable("-- combo points: " .. comboPoints .. ", threshold: " .. condition.search)
        return DPSGenie:evaluateNumericComparison(condition.comparer, comboPoints, tonumber(condition.search), cindex)
    end

    -- Combat
    if condition.subject == "Combat" then
        DPSGenie:addToDebugTable("- c" .. cindex .. ": Combat condition")
        local inCombat = UnitAffectingCombat(conditionUnit)
        if condition.comparer == "in combat" and inCombat then
            DPSGenie:addToDebugTable("in combat condition passed!")
            return true
        elseif condition.comparer == "not in combat" and not inCombat then
            DPSGenie:addToDebugTable("not in combat condition passed!")
            return true
        end
        return false
    end

    -- Spell Cooldown
    if condition.subject == "Spell Cooldown" then
        local spellID = tonumber(condition.search)
        local spellName = select(1, GetSpellInfo(spellID)) or "Unknown"
        DPSGenie:addToDebugTable("- c" .. cindex .. ": Spell Cooldown for " .. spellName)
        local start, duration, enabled = GetSpellCooldown(spellID)
        local remaining = 0
        if start and start > 0 and duration and duration > 1.5 then
            remaining = (start + duration) - GetTime()
            if remaining < 0 then remaining = 0 end
        end
        DPSGenie:addToDebugTable("-- CD remaining: " .. string.format("%.1f", remaining) .. "s")
        if condition.comparer == "available" then
            if remaining == 0 then
                DPSGenie:addToDebugTable("available condition passed!")
                return true
            end
        elseif condition.comparer == "on cooldown" then
            if remaining > 0 then
                DPSGenie:addToDebugTable("on cooldown condition passed!")
                return true
            end
        elseif condition.comparer == "more than" then
            if remaining > tonumber(condition.compare_value) then
                DPSGenie:addToDebugTable("more than condition passed!")
                return true
            end
        elseif condition.comparer == "less than" then
            if remaining < tonumber(condition.compare_value) then
                DPSGenie:addToDebugTable("less than condition passed!")
                return true
            end
        end
        return false
    end

    -- Spell Charges
    if condition.subject == "Spell Charges" then
        local spellID = tonumber(condition.search)
        local spellName = select(1, GetSpellInfo(spellID)) or "Unknown"
        DPSGenie:addToDebugTable("- c" .. cindex .. ": Spell Charges for " .. spellName)
        local currentCharges, maxCharges = GetSpellCharges(spellID)
        if currentCharges == nil then
            DPSGenie:addToDebugTable("-- spell has no charges")
            return false
        end
        DPSGenie:addToDebugTable("-- charges: " .. currentCharges .. "/" .. maxCharges)
        return DPSGenie:evaluateNumericComparison(condition.comparer, currentCharges, tonumber(condition.compare_value), cindex)
    end

    -- Pet Active
    if condition.subject == "Active" then
        DPSGenie:addToDebugTable("- c" .. cindex .. ": Pet Active condition")
        local petExists = UnitExists("pet") and not UnitIsDead("pet")
        if condition.comparer == "is active" and petExists then
            DPSGenie:addToDebugTable("is active condition passed!")
            return true
        elseif condition.comparer == "is not active" and not petExists then
            DPSGenie:addToDebugTable("is not active condition passed!")
            return true
        end
        return false
    end

    -- Pet Happy
    if condition.subject == "Happy" then
        DPSGenie:addToDebugTable("- c" .. cindex .. ": Pet Happy condition")
        local happiness = GetPetHappiness()
        if condition.comparer == "is happy" and happiness == 3 then
            DPSGenie:addToDebugTable("is happy condition passed!")
            return true
        elseif condition.comparer == "is not happy" and (not happiness or happiness < 3) then
            DPSGenie:addToDebugTable("is not happy condition passed!")
            return true
        end
        return false
    end

    -- Threat
    if condition.subject == "Threat" then
        DPSGenie:addToDebugTable("- c" .. cindex .. ": Threat condition")
        local isTanking, status, scaledPercent, rawPercent, threatValue = UnitDetailedThreatSituation(conditionUnit, "target")
        local threatPercent = math.floor(scaledPercent or 0)
        DPSGenie:addToDebugTable("-- threat: " .. threatPercent .. "%, tanking: " .. tostring(isTanking))
        if condition.comparer == "is tanking" then
            if isTanking then
                DPSGenie:addToDebugTable("is tanking condition passed!")
                return true
            end
        elseif condition.comparer == "is not tanking" then
            if not isTanking then
                DPSGenie:addToDebugTable("is not tanking condition passed!")
                return true
            end
        else
            return DPSGenie:evaluateNumericComparison(condition.comparer, threatPercent, tonumber(condition.search), cindex)
        end
        return false
    end

    -- Spell Known
    if condition.subject == "Spell Known" then
        local spellID = tonumber(condition.search)
        local spellName = select(1, GetSpellInfo(spellID)) or "Unknown"
        DPSGenie:addToDebugTable("- c" .. cindex .. ": Spell Known for " .. spellName)
        local isKnown = IsSpellKnown(spellID, false)
        DPSGenie:addToDebugTable("-- known: " .. tostring(isKnown))
        if condition.comparer == "known" and isKnown then
            DPSGenie:addToDebugTable("known condition passed!")
            return true
        elseif condition.comparer == "not known" and not isKnown then
            DPSGenie:addToDebugTable("not known condition passed!")
            return true
        end
        return false
    end

    -- Item Cooldown
    if condition.subject == "Item Cooldown" then
        local itemIdentifier = condition.search
        local itemID
        if type(itemIdentifier) == "string" and string.sub(itemIdentifier, 1, 2) == "i:" then
            itemID = tonumber(string.sub(itemIdentifier, 3))
        else
            itemID = tonumber(itemIdentifier)
        end
        local itemName = select(1, GetItemInfo(itemID or 0)) or "Unknown"
        DPSGenie:addToDebugTable("- c" .. cindex .. ": Item Cooldown for " .. itemName)
        if itemID then
            local start, duration, enable = GetItemCooldown(itemID)
            local onCooldown = start and start > 0 and duration and duration > 0
            DPSGenie:addToDebugTable("-- on cooldown: " .. tostring(onCooldown))
            if condition.comparer == "available" and not onCooldown then
                DPSGenie:addToDebugTable("available condition passed!")
                return true
            elseif condition.comparer == "on cooldown" and onCooldown then
                DPSGenie:addToDebugTable("on cooldown condition passed!")
                return true
            end
        end
        return false
    end

    -- Item Equipped
    if condition.subject == "Item Equipped" then
        local itemIdentifier = condition.search
        local itemID
        if type(itemIdentifier) == "string" and string.sub(itemIdentifier, 1, 2) == "i:" then
            itemID = tonumber(string.sub(itemIdentifier, 3))
        else
            itemID = tonumber(itemIdentifier)
        end
        local itemName = select(1, GetItemInfo(itemID or 0)) or "Unknown"
        DPSGenie:addToDebugTable("- c" .. cindex .. ": Item Equipped for " .. itemName)
        if itemID then
            local equipped = IsEquippedItem(itemID)
            DPSGenie:addToDebugTable("-- equipped: " .. tostring(equipped))
            if condition.comparer == "is equipped" and equipped then
                DPSGenie:addToDebugTable("is equipped condition passed!")
                return true
            elseif condition.comparer == "is not equipped" and not equipped then
                DPSGenie:addToDebugTable("is not equipped condition passed!")
                return true
            end
        end
        return false
    end

    -- Stance / Shapeshift Form
    if condition.subject == "Stance" then
        DPSGenie:addToDebugTable("- c" .. cindex .. ": Stance condition")
        local currentForm = GetShapeshiftForm()
        local searchForm = tonumber(condition.search) or 0
        DPSGenie:addToDebugTable("-- current form: " .. currentForm .. ", check: " .. searchForm)
        if condition.comparer == "equals" and currentForm == searchForm then
            DPSGenie:addToDebugTable("equals condition passed!")
            return true
        elseif condition.comparer == "not equals" and currentForm ~= searchForm then
            DPSGenie:addToDebugTable("not equals condition passed!")
            return true
        end
        return false
    end

    -- Target Casting / Channeling
    if condition.subject == "Casting" then
        DPSGenie:addToDebugTable("- c" .. cindex .. ": Casting condition on " .. conditionUnit)
        local spellName, _, _, _, _, _, _, _, notInterruptible = UnitCastingInfo(conditionUnit)
        local channelName, _, _, _, _, _, _, notInterruptibleCh = UnitChannelInfo(conditionUnit)
        local isCasting = (spellName ~= nil) or (channelName ~= nil)
        local canInterrupt = false
        if spellName and not notInterruptible then
            canInterrupt = true
        elseif channelName and not notInterruptibleCh then
            canInterrupt = true
        end
        DPSGenie:addToDebugTable("-- casting: " .. tostring(isCasting) .. ", interruptible: " .. tostring(canInterrupt))
        if condition.comparer == "is casting" and isCasting then
            DPSGenie:addToDebugTable("is casting condition passed!")
            return true
        elseif condition.comparer == "is not casting" and not isCasting then
            DPSGenie:addToDebugTable("is not casting condition passed!")
            return true
        elseif condition.comparer == "is interruptible" and isCasting and canInterrupt then
            DPSGenie:addToDebugTable("is interruptible condition passed!")
            return true
        elseif condition.comparer == "is not interruptible" and isCasting and not canInterrupt then
            DPSGenie:addToDebugTable("is not interruptible condition passed!")
            return true
        end
        return false
    end

    -- Target Classification
    if condition.subject == "Classification" then
        DPSGenie:addToDebugTable("- c" .. cindex .. ": Classification condition on " .. conditionUnit)
        local classification = UnitClassification(conditionUnit)
        local isPlayer = UnitIsPlayer(conditionUnit)
        DPSGenie:addToDebugTable("-- classification: " .. tostring(classification) .. ", isPlayer: " .. tostring(isPlayer))
        if condition.comparer == "is boss" and classification == "worldboss" then
            DPSGenie:addToDebugTable("is boss condition passed!")
            return true
        elseif condition.comparer == "is elite" and (classification == "elite" or classification == "rareelite" or classification == "worldboss") then
            DPSGenie:addToDebugTable("is elite condition passed!")
            return true
        elseif condition.comparer == "is player" and isPlayer then
            DPSGenie:addToDebugTable("is player condition passed!")
            return true
        elseif condition.comparer == "is normal" and classification == "normal" and not isPlayer then
            DPSGenie:addToDebugTable("is normal condition passed!")
            return true
        end
        return false
    end

    DPSGenie:addToDebugTable("- c" .. cindex .. ": Unknown condition subject: " .. (condition.subject or "nil"))
    return false
end

function DPSGenie:runRotaTable()
    if DPSGenie:debugEnabled() then
        DPSGenie:setDebugWindowContent(DPSGenie.debugTable)
    end
    DPSGenie.debugTable = {}

    local shouldHide = false
    if DPSGenie:LoadSettingFromProfile("onlyInCombat") and not UnitAffectingCombat("player") then
        shouldHide = true
    end
    if DPSGenie:LoadSettingFromProfile("onlyWithTarget") and not UnitExists("target") then
        shouldHide = true
    end
    if shouldHide then
        if _G["DPSGenieButtonHolderFrame"] then
            _G["DPSGenieButtonHolderFrame"]:Hide()
        end
        return
    else
        if _G["DPSGenieButtonHolderFrame"] then
            _G["DPSGenieButtonHolderFrame"]:Show()
        end
    end

    if activeRota then
        local currentIndex 

        for sindex, svalue in pairs(activeRota.spells) do
            currentIndex = sindex
            local success = false
            local fallbackSpell = nil
            local fallbackIconModifiers = nil
            for index, value in ipairs(activeRota.spells[sindex]) do
                local unit = "target"

                --check if its an item ie spell = i:25413
                --create fallback for spells so non prefixed values are always spells
                --skip all spell checks (or better group spell checks and item checks with one final spellOrItemOk = true)

                --get max rank
                --local maxSpellID = C_Spell.GetMaxLearnableRank(spell, UnitLevel("player"))
                --override, for special spells? rankless

                local basechecks = false
                local predictionCandidate = false
                local iconModifiers = {}

                local action = value["spellId"]
                local actionType = string.sub(action, 1, 1)
                local actionName = nil
                local actionId = string.match(action, "%d+")

                if actionType == "l" then
                    --bacsecheck for lua
                elseif actionType == "i" then
                    local itemID = tonumber(actionId)
                    local itemName, _, _, _, _, _, _, _, _, itemIcon = GetItemInfo(itemID)
                    actionName = itemName or "Unknown Item"

                    DPSGenie:addToDebugTable("-------------------------------------------- " .. GetTime())
                    DPSGenie:addToDebugTable("Running checks for item " .. index .. " " .. actionName)

                    local itemCount = GetItemCount(itemID)
                    local isEquipped = IsEquippedItem(itemID)
                    if itemCount > 0 or isEquipped then
                        local start, duration, enable = GetItemCooldown(itemID)
                        local itemReady = (start == 0 and duration == 0)

                        local inRange = IsItemInRange(itemID, unit)
                        if inRange == nil then inRange = 1 end

                        if start > 0 and duration > 0 then
                            iconModifiers['cooldown'] = {start = start, duration = duration}
                        end

                        DPSGenie:addToDebugTable("ItemCount: " .. itemCount)
                        DPSGenie:addToDebugTable("ItemReady: " .. DPSGenie:stateToColor(tostring(itemReady), "true"))
                        DPSGenie:addToDebugTable("ItemInRange: " .. DPSGenie:stateToColor((inRange or 0), 1))

                        if itemReady and inRange ~= 0 then
                            basechecks = true
                        elseif not itemReady and inRange ~= 0 and not fallbackSpell then
                            predictionCandidate = true
                        end
                    else
                        DPSGenie:addToDebugTable("Item not in inventory or equipped")
                    end
                else
                    --basecheck for spell, prefixed with s: or nothing
                    local spell = actionId

                    local spellName = select(1, GetSpellInfo(spell))
                    if not spellName then spellName = "Unknown" end
                    actionName = spellName
                    local spellLink = GetSpellLink(spellName)

                    if spellLink ~= nil then
                        local maxSpellID = string.match(spellLink, "spell:(%d+)")

                        if maxSpellID == nil then
                            maxSpellID = spell
                        end

                        local isKnown = IsSpellKnown(maxSpellID, false)
                        if isKnown then
                            --print("is known")
                            spell = maxSpellID
                            local name, rank, icon, castTime, minRange, maxRange, spellID, originalIcon = GetSpellInfo(spell)
                            DPSGenie:addToDebugTable("-------------------------------------------- " .. GetTime())
                            DPSGenie:addToDebugTable("Running checks and conditions for spell " .. index .. " " .. name)

                            if IsHelpfulSpell(name) then
                                DPSGenie:addToDebugTable("is helpful, override unit to player")
                                unit = "player"
                            else
                                DPSGenie:addToDebugTable("is harmful")
                            end

                            local usable, nomana = IsUsableSpell(name)
                            local start, duration, enable = GetSpellCooldown(tonumber(spell))
                            local currentCharges, maxCharges, cooldownStart, cooldownDuration, chargeModRate = GetSpellCharges(tonumber(spell))

                            -- Range check: try spell name first, fall back to spellbook index
                            local spellInRange = IsSpellInRange(name, unit)
                            if spellInRange == nil then
                                local bookIndex = DPSGenie:FindSpellBookIndex(name)
                                if bookIndex then
                                    spellInRange = IsSpellInRange(bookIndex, BOOKTYPE_SPELL, unit)
                                end
                            end

                            if IsHelpfulSpell(name) then
                                spellInRange = 1
                            end

                            if spellInRange == 0 then
                                iconModifiers['vertexColor'] = {0.9, 0.5, 0.5, 0.7}
                            end

                            if start > 0 and duration > 0 then
                                iconModifiers['cooldown'] = {start = start, duration = duration}
                            end

                            --check for GCD vs actual spell cooldown
                            --duration <= 1.5 means it's only the global cooldown, not a real spell cooldown
                            local isOnlyGCD = (start > 0 and duration > 0 and duration <= 1.5)
                            local spellReady = (start == 0 and duration == 0) or isOnlyGCD

                            DPSGenie:addToDebugTable("IsUsableSpell: " .. DPSGenie:stateToColor((usable or 0), 1))
                            DPSGenie:addToDebugTable("IsSpellInRange: " .. DPSGenie:stateToColor((spellInRange or 0), 1))

                            DPSGenie:addToDebugTable("SpellReady: " .. DPSGenie:stateToColor(tostring(spellReady), "true"))

                            if usable and (spellInRange ~= 0 or DPSGenie:LoadSettingFromProfile("showOutOfRange")) and (spellReady or (maxCharges and maxCharges > 0 and currentCharges and currentCharges > 0)) then
                                --may recheck this for buffs in combat?
                                if (UnitCanAttack("player", unit) and IsHarmfulSpell(name)) or IsHelpfulSpell(name) then
                                    basechecks = true
                                end
                            end

                            -- Prediction candidate: passes all checks except cooldown
                            if not basechecks and usable and (spellInRange ~= 0 or DPSGenie:LoadSettingFromProfile("showOutOfRange")) and not fallbackSpell then
                                if (UnitCanAttack("player", unit) and IsHarmfulSpell(name)) or IsHelpfulSpell(name) then
                                    predictionCandidate = true
                                end
                            end
                        end
                    end
                end

                if basechecks == true then
                    DPSGenie:addToDebugTable("GetUnitName: " .. (GetUnitName(unit) or 0))
                    DPSGenie:addToDebugTable("UnitIsDead: " .. DPSGenie:stateToColor((UnitIsDead(unit) or 0), 0))
                    DPSGenie:addToDebugTable("UnitIsDeadOrGhost: " .. DPSGenie:stateToColor((UnitIsDeadOrGhost("player") or 0), 0))
                    DPSGenie:addToDebugTable("UnitExists: " .. DPSGenie:stateToColor((UnitExists(unit) or 0), 1))

                    if not UnitIsDead(unit) and not UnitIsDeadOrGhost("player") and GetUnitName(unit) and UnitExists(unit) then
                        local conditionsPassed = 0
                        --check all conditions
                        if value["conditions"] then
                            DPSGenie:addToDebugTable("spell " .. actionName .. " has " .. #value["conditions"] .. " conditions")
                            for cindex, condition in ipairs(value["conditions"]) do
                                if DPSGenie:evaluateCondition(condition, cindex) then
                                    conditionsPassed = conditionsPassed + 1
                                end
                            end
                        end

                        if value["conditions"] and conditionsPassed == #value["conditions"] then
                            DPSGenie:addToDebugTable("|cFF00FF00"..actionName .. " passed " .. conditionsPassed .. " conditions!|r")
                            DPSGenie:SetSuggestSpell(sindex, action, iconModifiers);
                            success = true
                        end

                        --base checks were ok but no conditions, pass
                        if not value["conditions"] then
                            DPSGenie:addToDebugTable("|cFF00FF00"..actionName .. " has no conditions and passed|r")
                            DPSGenie:SetSuggestSpell(sindex, action, iconModifiers);
                            success = true
                        end

                        if value["conditions"] and false then
                            DPSGenie:addToDebugTable("|cFFeb8f34"..actionName .. " passed only " .. conditionsPassed .. " conditions of " .. #value["conditions"].."|r")
                        end
                    else
                        DPSGenie:addToDebugTable("|cFFFF0000" .. actionName .. " failed basechecks!|r")
                    end

                    if success and not DPSGenie:debugEnabled() then
                        break
                    else
                        DPSGenie:SetSuggestSpell(sindex, false, nil)
                    end
                end

                -- Prediction: evaluate conditions for spells/items on cooldown
                if predictionCandidate and not fallbackSpell then
                    if not UnitIsDead(unit) and not UnitIsDeadOrGhost("player") and GetUnitName(unit) and UnitExists(unit) then
                        local conditionsPassed = 0
                        if value["conditions"] then
                            for cindex, condition in ipairs(value["conditions"]) do
                                if DPSGenie:evaluateCondition(condition, cindex) then
                                    conditionsPassed = conditionsPassed + 1
                                end
                            end
                        end
                        if (value["conditions"] and conditionsPassed == #value["conditions"]) or not value["conditions"] then
                            fallbackSpell = action
                            fallbackIconModifiers = iconModifiers
                        end
                    end
                end
            end

            -- After evaluating all spells: show prediction fallback or clear button
            if not success then
                if DPSGenie:LoadSettingFromProfile("showPrediction") and fallbackSpell then
                    fallbackIconModifiers['vertexColor'] = {0.5, 0.5, 0.5, 0.7}
                    DPSGenie:SetSuggestSpell(currentIndex, fallbackSpell, fallbackIconModifiers)
                else
                    DPSGenie:SetSuggestSpell(currentIndex, false, nil)
                end
            end
        end
    else
        DPSGenie:SetSuggestSpell(currentIndex, false, nil)
    end
end

function DPSGenie:OnEnable()
    self.RotaSchedule = self:ScheduleRepeatingTimer("runRotaTable", .250)

    local rota = DPSGenie:LoadSettingFromProfile("activeRota")
    if rota then
        DPSGenie:SetActiveRota(rota)
    end
end

function DPSGenie:OnDisable()
    if self.RotaSchedule then
        self:CancelTimer(self.RotaSchedule)
    end
end

local addonName, ns = ...
DPSGenie = LibStub("AceAddon-3.0"):GetAddon("DPSGenie")

DPSGenie:Print("Core loaded!")

debugTable = {}

function DPSGenie:addToDebugTable(text)
    table.insert(debugTable, text)
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

local acitveRota

function DPSGenie:SetActiveRota(rotaTable)
    DPSGenie:Print("Setting active Rota to: " .. rotaTable.name)
    acitveRota = DPSGenie:deepcopy(rotaTable)
    DPSGenie:SaveSettingToProfile("activeRota", rotaTable)
    -- build cache with, spellinfo, harmful, helpful

    --setup number suggestbuttons
    --print("buttons setup: " .. #acitveRota.spells)
    DPSGenie:SetupSpellButtons(#acitveRota.spells)
end

function DPSGenie:GetActiveRota()
    return acitveRota
end

function DPSGenie:runRotaTable()
    if DPSGenie:debugEnabled() then
        DPSGenie:setDebugWindowContent(debugTable)
    end
    debugTable = {}

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

    if acitveRota then
        local currentIndex 

        for sindex, svalue in pairs(acitveRota.spells) do
            currentIndex = sindex
            local success = false
            for index, value in ipairs(acitveRota.spells[sindex]) do
                local unit = "target"

                --check if its an item ie spell = i:25413
                --create fallback for spells so non prefixed values are always spells
                --skip all spell checks (or better group spell checks and item checks with one final spellOrItemOk = true)

                --get max rank
                --local maxSpellID = C_Spell.GetMaxLearnableRank(spell, UnitLevel("player"))
                --override, for special spells? rankless

                local basechecks = false
                local iconModifiers = {}

                local action = value["spellId"]
                local actionType = string.sub(action, 1, 1)
                local actionName = nil
                local actionId = string.match(action, "%d+")

                if actionType == "l" then
                    --bacsecheck for lua
                elseif actionType == "i" then
                    --basecheck for item
                else
                    --basecheck for spell, prefixed with s: or nothing
                    local spell = actionId

                    local spellName = select(1, GetSpellInfo(spell))
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
                        --check all conditions, break on fail
                        if value["conditions"] then
                            DPSGenie:addToDebugTable("spell " .. actionName .. " has " .. #value["conditions"] .. " conditions")
                            for cindex, condition in ipairs(value["conditions"]) do
                                --buffs start
                                if condition.subject == "Buffs" then
                                    DPSGenie:addToDebugTable("- c" .. cindex ..": buff condition")
                                    local auraName = select(1, GetSpellInfo(condition.search))
                                    local unit = string.lower(condition.unit)
                                    DPSGenie:addToDebugTable("-- c" .. cindex ..": buff unit: " .. unit)
                                    DPSGenie:addToDebugTable("-- c" .. cindex ..": buff buff: " .. auraName .. " (".. condition.search ..")")
                                    --is this if needed??
                                    local name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID
                                    if unit == "player" then
                                        name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID = UnitAura(unit, auraName)
                                    else
                                        name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID = UnitAura(unit, auraName, nil, "PLAYER|HARMFUL")
                                    end
                                    --if not count then count = 0 end    
                                    if not name then name = "" end
                                    --buffs less than start
                                    if condition.comparer == "less than" then
                                        DPSGenie:addToDebugTable("-- c".. cindex ..": less than: " .. auraName .. " value: " .. condition.compare_value .. " count: " .. tostring(count))
                                        if count ~= nil and not (count >= tonumber(condition.compare_value)) then
                                            DPSGenie:debug("less than conditon passed!")
                                            conditionsPassed = conditionsPassed + 1
                                        end
                                    --buffs less than end
                                    --buffs more than start
                                    elseif condition.comparer == "more than" then
                                        DPSGenie:addToDebugTable("-- c".. cindex ..": more than: " .. auraName .. " value: " .. condition.compare_value .. " count: " .. tostring(count))
                                        if count ~= nil and not (count <= tonumber(condition.compare_value)) then
                                            DPSGenie:addToDebugTable("more than conditon passed!")
                                            conditionsPassed = conditionsPassed + 1
                                        end
                                    --buffs more than end
                                    --buffs equals start
                                    elseif condition.comparer == "equals" then
                                        DPSGenie:addToDebugTable("-- c".. cindex ..": equals: " .. auraName .. " value: " .. condition.compare_value .. " count: " .. tostring(count))
                                        if count ~= nil and (count == tonumber(condition.compare_value)) then
                                            DPSGenie:addToDebugTable("equals conditon passed!")
                                            conditionsPassed = conditionsPassed + 1
                                        end
                                    --buffs equals end
                                    --buffs contains start
                                    elseif condition.comparer == "contains" then
                                        DPSGenie:addToDebugTable("-- c" .. cindex .. ": contains: " .. auraName .. " count: " .. tostring(count))
                                        if count ~= nil then
                                            DPSGenie:addToDebugTable("contains conditon passed!")
                                            conditionsPassed = conditionsPassed + 1
                                        end
                                    --buffs contains end
                                    --buffs not contains start
                                    elseif condition.comparer == "not contains" then
                                        DPSGenie:addToDebugTable("-- c" .. cindex .. ": not contains: " .. auraName .. " count: " .. tostring(count))
                                        if count == nil then
                                            DPSGenie:addToDebugTable("not contains conditon passed!")
                                            conditionsPassed = conditionsPassed + 1
                                        end
                                    --buffs not contains end
                                    end
                                    DPSGenie:addToDebugTable("-- c" .. cindex ..": buff count was nil")
                                --buffs end
                                --health/powertype start
                                elseif condition.subject == "Health" or condition.subject == "Mana" or condition.subject == "Rage" or condition.subject == "Energy" then
                                    local percent = 0
                                    local unit = string.lower(condition.unit)

                                    if condition.subject == "Health" then
                                        DPSGenie:addToDebugTable("- c" .. cindex ..": Health condition")
                                        local max = UnitHealthMax(unit)
                                        local cur = UnitHealth(unit)
                                        percent = (cur / max) * 100
                                    else
                                        local powertypes = {
                                            ["Mana"] = 0,
                                            ["Rage"] = 1,
                                            ["Focus"] = 2,
                                            ["Energy"] = 3,
                                        }
                                        local powertype = powertypes[condition.subject]
                                        DPSGenie:addToDebugTable("- c" .. cindex ..": " .. condition.subject .. " condition")
                                        local max = UnitPowerMax(unit, powertype)
                                        local cur = UnitPower(unit, powertype)
                                        percent = (cur / max) * 100
                                    end

                                    percent = math.floor(percent)

                                    DPSGenie:addToDebugTable("-- c" .. cindex .." current " .. condition.subject .. " of " .. unit .. ": " .. percent .. "%")
                                    DPSGenie:addToDebugTable("-- c" .. cindex .." comparer: " .. condition.comparer .. " search: " .. condition.search)

                                    if condition.comparer == "less than" then
                                        if not (percent >= tonumber(condition.search)) then
                                            DPSGenie:addToDebugTable("less than conditon passed!")
                                            conditionsPassed = conditionsPassed + 1
                                        end
                                    elseif condition.comparer == "more than" then
                                        if not (percent <= tonumber(condition.search)) then
                                            DPSGenie:addToDebugTable("more than conditon passed!")
                                            conditionsPassed = conditionsPassed + 1
                                        end
                                    elseif condition.comparer == "equals" then
                                        if percent == tonumber(condition.search) then
                                            DPSGenie:addToDebugTable("equals conditon passed!")
                                            conditionsPassed = conditionsPassed + 1
                                        end
                                    end
                                --health/powertype end
                                --combopoints start
                                elseif condition.subject == "Combopoints" then
                                    DPSGenie:addToDebugTable("- c" .. cindex ..": Combopoints condition")
                                    local comboPoints = GetComboPoints("player", "target")
                                    if condition.comparer == "less than" then
                                        if not (comboPoints >= tonumber(condition.search)) then
                                            DPSGenie:addToDebugTable("less than conditon passed!")
                                            conditionsPassed = conditionsPassed + 1
                                        end
                                    elseif condition.comparer == "more than" then
                                        if not (comboPoints <= tonumber(condition.search)) then
                                            DPSGenie:addToDebugTable("more than conditon passed!")
                                            conditionsPassed = conditionsPassed + 1
                                        end
                                    elseif condition.comparer == "equals" then
                                        if comboPoints == tonumber(condition.search) then
                                            DPSGenie:addToDebugTable("equals conditon passed!")
                                            conditionsPassed = conditionsPassed + 1
                                        end
                                    end
                                --combopoints end
                                end
                            end
                        end

                        if value["conditions"] and conditionsPassed == #value["conditions"] then
                            DPSGenie:addToDebugTable("|cFF00FF00"..actionName .. " passed " .. conditionsPassed .. " conditions!|r")
                            DPSGenie:SetSuggestSpell(sindex, actionId, iconModifiers);
                            success = true
                        end

                        --base checks were ok but no conditions, pass
                        if not value["conditions"] then
                            DPSGenie:addToDebugTable("|cFF00FF00"..actionName .. " has no conditions and passed|r")
                            DPSGenie:SetSuggestSpell(sindex, actionId, iconModifiers);
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

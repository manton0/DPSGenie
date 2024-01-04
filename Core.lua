DPSGenie = LibStub("AceAddon-3.0"):GetAddon("DPSGenie")

DPSGenie:Print("Core loaded!")

local playerStats = {}
local targetStats = {}

local testTable = {
    [1] = {
        ["Spell"] = 53408,
        ["Condition"] = "usable",
    },
    [2] = {
        ["Spell"] = 81384,
        ["Condition"] = "usable",
    },
    [3] = {
        ["Spell"] = 35395,
        ["Condition"] = "usable",
    }
}

DPSGenie.settings = {
    showOutOfRange = true,
}

local baseEval = [[

local inRange = 0
local spell = SPELLID
local unit = "target"

if GetUnitName(unit) and UnitExists(unit) then
    local name, rank, icon, castTime, minRange, maxRange, spellID, originalIcon = GetSpellInfo(spell)
    usable, nomana = IsUsableSpell(name)

    local start, duration, enable = GetSpellCooldown(name)

    local currentCharges, maxCharges, cooldownStart, cooldownDuration, chargeModRate = GetSpellCharges(spell)

    if usable and IsSpellInRange(name, unit) ~= 0 and ((start == 0 and duration == 0) or (maxCharges > 0 and currentCharges > 0)) then
        DPSGenie:SetFirstSuggestSpell(icon);
        return true
    end
end

]]


local acitveRota

local function deepcopy(o, seen)
    seen = seen or {}
    if o == nil then return nil end
    if seen[o] then return seen[o] end
  
    local no
    if type(o) == 'table' then
      no = {}
      seen[o] = no
  
      for k, v in next, o, nil do
        no[deepcopy(k, seen)] = deepcopy(v, seen)
      end
      setmetatable(no, deepcopy(getmetatable(o), seen))
    else -- number, string, boolean, etc
      no = o
    end
    return no
  end

function DPSGenie:SetActiveRota(rotaTable)
    DPSGenie:Print("Setting active Rota to: " .. rotaTable.name)
    acitveRota = deepcopy(rotaTable)
    DPSGenie:SaveSettingToProfile("activeRota", rotaTable)
    -- build cache with, spellinfo, harmful, helpful
end

function DPSGenie:GetActiveRota()
    return acitveRota
end


function DPSGenie:runRotaTable()

    if acitveRota then

        local success = false

        --table.sort(testTable)

        for index, value in ipairs(acitveRota.spells) do
 
            local unit = "target"

            local spell = value["spellId"]

            local name, rank, icon, castTime, minRange, maxRange, spellID, originalIcon = GetSpellInfo(spell)

            DPSGenie:debug("-------------------------------------------------- " .. GetTime())
            DPSGenie:debug("Running checks and conditions for spell " .. index .. " " .. name)

            if IsHelpfulSpell(name) then
                DPSGenie:debug(" - is helpful, override unit to player")
                unit = "player"
            else
                DPSGenie:debug(" - is harmful")
            end

            local usable, nomana = IsUsableSpell(name)
            local start, duration, enable = GetSpellCooldown(name)
            local currentCharges, maxCharges, cooldownStart, cooldownDuration, chargeModRate = GetSpellCharges(spell)
            local spellInRange = IsSpellInRange(name, unit)

            if IsHelpfulSpell(name) then
                spellInRange = 1
            end

            local iconModifiers = {}
            if spellInRange == 0 then
                iconModifiers['vertexColor'] = {0.9, 0.5, 0.5, 0.7}
            end


            DPSGenie:debug("UnitIsDead " .. (UnitIsDead(unit) or 0))
            DPSGenie:debug("UnitIsDeadOrGhost " .. (UnitIsDeadOrGhost("player") or 0))
            DPSGenie:debug("GetUnitName " .. (GetUnitName(unit) or 0))
            DPSGenie:debug("UnitExists " .. (UnitExists(unit) or 0))

            if not UnitIsDead(unit) and not UnitIsDeadOrGhost("player") and GetUnitName(unit) and UnitExists(unit) then


                --quick hack to check for "gcd"
                local gcdremain = 1.5
                if start > 0 then
                    gcdremain = start + duration - GetTime()
                end

                DPSGenie:debug("spell " .. name .. " is usable: " .. (usable or "0"))
                DPSGenie:debug("spell " .. name .. " spellInRange: " .. (spellInRange or "0"))

                if usable and (spellInRange ~= 0 or DPSGenie.settings.showOutOfRange) and (((start == 0 and duration == 0) or gcdremain < 1.5) or (maxCharges > 0 and currentCharges > 0)) then

                    if (UnitCanAttack("player", unit) and IsHarmfulSpell(name)) or IsHelpfulSpell(name) then

                        local conditionsPassed = 0
                        --check all conditions, break on fail
                        if value["conditions"] then
                            DPSGenie:debug("spell " .. name .. " has " .. #value["conditions"] .. " conditions")
                            for cindex, condition in ipairs(value["conditions"]) do
                                --buffs start
                                if condition.subject == "Buffs" then
                                    DPSGenie:debug("- c" .. cindex ..": buff condition")
                                    local auraName = select(1, GetSpellInfo(condition.search))
                                    local unit = string.lower(condition.unit)
                                    local name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID = UnitAura(unit, auraName)
                                    if not count then count = 0 end    
                                    if not name then name = "" end

                                    --buffs less than start
                                    if condition.comparer == "less than" then
                                        DPSGenie:debug("-- c".. cindex ..": less than: " .. auraName .. " value: " .. condition.compare_value .. " count: " .. count)
                                        if not (count >= tonumber(condition.compare_value)) then
                                            DPSGenie:debug("conditon passed!")
                                            conditionsPassed = conditionsPassed + 1
                                        end
                                    --buffs less than end
                                    --buffs contains start
                                    elseif condition.comparer == "contains" then
                                        DPSGenie:debug("-- c" .. cindex .. ": contains: " .. auraName .. " count: " .. count)
                                        if count > 0 then
                                            DPSGenie:debug("conditon passed!")
                                            conditionsPassed = conditionsPassed + 1
                                        end
                                    --buffs contains end
                                    end
                                    
                                --buffs end
                                --healt start
                                elseif condition.subject == "Health" then
                                    DPSGenie:debug("- c" .. cindex ..": Health condition")
                                    local unit = string.lower(condition.unit)
                                    local maxHP = UnitHealthMax(unit)
                                    local curHP = UnitHealth(unit)
                                    local percent = (curHP / maxHP) * 100
                                    DPSGenie:debug("current HP of " .. unit .. ": " .. percent .. "%")
                                    DPSGenie:debug("conditon passed!")
                                    conditionsPassed = conditionsPassed + 1
                                --healt end
                                end
                            end
                        end

                        if value["conditions"] and conditionsPassed == #value["conditions"] then
                            DPSGenie:debug(name .. " passed " .. conditionsPassed .. " conditions")
                            DPSGenie:SetFirstSuggestSpell(spell, iconModifiers);
                            success = true
                        end

                        --base checks were ok but no conditions, pass
                        if not value["conditions"] then
                            DPSGenie:debug(name .. " has no conditions and passed")
                            DPSGenie:SetFirstSuggestSpell(spell, iconModifiers);
                            success = true
                        end

                        if value["conditions"] then
                            DPSGenie:debug(name .. " passed only " .. conditionsPassed .. " conditions of " .. #value["conditions"])
                        end

                    end


                end
            else
                DPSGenie:debug(name .. " failed basechecks! ")
            end

            if success then          
                break
            end
        end

        if not success then
            DPSGenie:SetFirstSuggestSpell(false, nil)
        end

    else
        DPSGenie:SetFirstSuggestSpell(false, nil)
    end
end


function DPSGenie:runTree()

    --do basic checks, has target, is target alive, is player alive
    local unit = "target"

    if not UnitIsDead(unit) and not UnitIsDeadOrGhost("player") and GetUnitName(unit) and UnitExists(unit) and UnitCanAttack("player", unit) then

        local success

        for index, value in pairs(testTable) do
            --print("eval: " .. index .. " with spell: " .. value["Spell"])


            -- more checks here regarding spell cooldown etc


            local preparedCode = string.gsub(baseEval, "SPELLID", value["Spell"])
            preparedCode = [[ DPSGenie = LibStub("AceAddon-3.0"):GetAddon("DPSGenie");  ]] .. preparedCode



            -- check for success and break
            success = DPSGenie:runCore(preparedCode)
            --print("success: " .. success)
            if success then
                --print("breaking, success")
                break
            end
        end

        if not success then
            DPSGenie:SetFirstSuggestSpell("Interface\\Icons\\INV_Misc_QuestionMark")
        end

    else
        DPSGenie:SetFirstSuggestSpell("Interface\\Icons\\INV_Misc_QuestionMark")
    end
end

function DPSGenie:runCore(preparedCode)
    local success, result = pcall(loadstring(preparedCode))

    if success then
        --print("Code erfolgreich ausgeführt.")
        return result
    else
        --print("Fehler beim Ausführen des Codes:")
        --print(result)
        return false
    end
    
end


function DPSGenie:OnEnable()
    self.testTimer = self:ScheduleRepeatingTimer("runRotaTable", .250)
    local rota = DPSGenie:LoadSettingFromProfile("activeRota")
    if rota then
        DPSGenie:SetActiveRota(rota)
    end
end

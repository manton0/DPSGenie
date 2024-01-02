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

function DPSGenie:SetActiveRota(rotaTable)
    acitveRota = rotaTable
    DPSGenie:SaveSettingToProfile("activeRota", rotaTable)
    -- build cache with, spellinfo, harmful, helpful
end

function DPSGenie:GetActiveRota()
    return acitveRota
end


function DPSGenie:runRotaTable()

    local unit = "target"
    if acitveRota then

        local success = false

        --table.sort(testTable)

        for index, value in pairs(acitveRota.spells) do
 
            local spell = value["spellId"]

            local name, rank, icon, castTime, minRange, maxRange, spellID, originalIcon = GetSpellInfo(spell)
            local usable, nomana = IsUsableSpell(name)
            local start, duration, enable = GetSpellCooldown(name)
            local currentCharges, maxCharges, cooldownStart, cooldownDuration, chargeModRate = GetSpellCharges(spell)
            local spellInRange = IsSpellInRange(name, unit)

            local iconModifiers = {}
            if spellInRange == 0 then
                iconModifiers['vertexColor'] = {0.9, 0.5, 0.5, 0.7}
            end

            -- UnitCanAttack("player", unit) if harmfull spell
            -- helpfulspell unit = player
            --TODO: ignore gc here, rota will break to next 
            if not UnitIsDead(unit) and not UnitIsDeadOrGhost("player") and GetUnitName(unit) and UnitExists(unit) then
                if usable and (spellInRange ~= 0 or DPSGenie.settings.showOutOfRange) and ((start == 0 and duration == 0) or (maxCharges > 0 and currentCharges > 0)) then
                    DPSGenie:SetFirstSuggestSpell(spell, iconModifiers);
                    success = true
                end
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

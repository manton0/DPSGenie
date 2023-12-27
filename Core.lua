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

local baseEval = [[

DPSGenie = LibStub("AceAddon-3.0"):GetAddon("DPSGenie"); 

local inRange = 0
local spell = SPELLID
local unit = "target"

if GetUnitName(unit) and UnitExists(unit) then
--print("name: " .. GetUnitName(unit))
--print("exists: " .. UnitExists(unit))
local name, rank, icon, castTime, minRange, maxRange, spellID, originalIcon = GetSpellInfo(spell)
    usable, nomana = IsUsableSpell(name)
    --print("usable: " .. usable)
    local start, duration, enable = GetSpellCooldown(name)
    if start == 0 and duration == 0 then
        --print("cooldown: no")
    else
        --print("cooldown: " .. (start + duration - GetTime()) .. "s")
    end
    local currentCharges, maxCharges, cooldownStart, cooldownDuration, chargeModRate = GetSpellCharges(spell)
    --print("inrange: " .. IsSpellInRange(name, unit))
    if usable and IsSpellInRange(name, unit) ~= 0 and ((start == 0 and duration == 0) or (maxCharges > 0 and currentCharges > 0)) then
        DPSGenie:SetFirstSuggestSpell(icon);
        return true
    end
end

]]

function DPSGenie:runTree()

    --do basic checks, has target, is target alive, is player alive
    local unit = "target"

    if not UnitIsDead(unit) and not UnitIsDeadOrGhost("player") and GetUnitName(unit) and UnitExists(unit) and UnitCanAttack("player", unit) then

        local success

        for index, value in pairs(testTable) do
            --print("eval: " .. index .. " with spell: " .. value["Spell"])
            local preparedCode = string.gsub(baseEval, "SPELLID", value["Spell"])
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
    self.testTimer = self:ScheduleRepeatingTimer("runTree", .250)
end

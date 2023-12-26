DPSGenie = LibStub("AceAddon-3.0"):GetAddon("DPSGenie")

DPSGenie:Print("Core loaded!")

function DPSGenie:runCore()
    local func, errorMessage  = loadstring([[

    DPSGenie = LibStub("AceAddon-3.0"):GetAddon("DPSGenie"); 

    --DPSGenie:Print("Core eval done!")

    local inRange = 0
    local jow = 53408
    local cs = 35395
    local unit = "target"

    if GetUnitName(unit) and UnitExists(unit) then
    print("name: " .. GetUnitName(unit))
    print("exists: " .. UnitExists(unit))
    local name, rank, icon, castTime, minRange, maxRange, spellID, originalIcon = GetSpellInfo(jow)
        usable, nomana = IsUsableSpell(name)
        print("usable: " .. usable)
        local start, duration, enable = GetSpellCooldown(name)
        if start == 0 and duration == 0 then
            print("cooldown: no")
        else
            print("cooldown: " .. (start + duration - GetTime()) .. "s")
        end
        print("inrange: " .. IsSpellInRange(name, unit))
        if usable and IsSpellInRange(name, unit) ~= 0 then
            local _, _, spellIcon = GetSpellInfo(jow)
            DPSGenie:SetFirstSuggestSpell(spellIcon);
        else
            local _, _, spellIcon = GetSpellInfo(cs)
            DPSGenie:SetFirstSuggestSpell(spellIcon);
        end
    end


    ]]);

    
    if(not func) then
    print(errorMessage)
    end

    local success, errorMessage = pcall(func);
    if(not success) then
    print(errorMessage)
    end
    
end

function DPSGenie:TimerFeedback()
    print("testtimer")
end


function DPSGenie:OnEnable()
    self.testTimer = self:ScheduleRepeatingTimer("runCore", .250)
end

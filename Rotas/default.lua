DPSGenie = LibStub("AceAddon-3.0"):GetAddon("DPSGenie")

DPSGenie:Print("Default Rotas loaded!")

local defaultRotas = {
    {
        name = "Consecrated Strikes",
        description = "Build for Consecrated Strikes", 
        icon = "Interface\\Icons\\ability_paladin_righteousvengeance",
    },
    {
        name = "Aimed Explosive Shot",
        description = "Build for Aimed Explosive Shot",
        icon = "Interface\\Icons\\ability_hunter_explosiveshot",
    },
    {
        name = "Battle Fervor",
        description = "Build for Battle Fervor", 
        icon = "Interface\\Icons\\ability_warrior_bloodfrenzy",
    },
    {
        name = "Carnage Incarnate",
        description = "Build for Carnage Incarnate", 
        icon = "Interface\\Icons\\spell_druid_bearhug",
    },
}

function DPSGenie:GetDefaultRotas()
    return defaultRotas
end


local mod	= DBM:NewMod(454, "DBM-Party-Vanilla", 16, 236)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("@file-date-integer@")
mod:SetCreatureID(10435)
mod:SetEncounterID(482)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_SUCCESS 10887 14099"
)

local warningCrowdPummel		= mod:NewSpellAnnounce(10887, 2)
local warningMightyBlow			= mod:NewSpellAnnounce(14099, 2, nil, "Tank", 2)

local timerCrowdPummelCD		= mod:NewAITimer(180, 10887, nil, nil, nil, 2)
local timerMightyBlowCD			= mod:NewAITimer(180, 14099, nil, "Tank", 2, 5, nil, DBM_COMMON_L.TANK_ICON)

function mod:OnCombatStart(delay)
	timerCrowdPummelCD:Start(1-delay)
	timerMightyBlowCD:Start(1-delay)
end

do
	local CrowdPummel, MightyBlow = DBM:GetSpellInfo(10887), DBM:GetSpellInfo(14099)
	function mod:SPELL_CAST_SUCCESS(args)
		--if args.spellId == 10887 then
		if args.spellName == CrowdPummel then
			warningCrowdPummel:Show()
			timerCrowdPummelCD:Start()
		--elseif args.spellId == 14099 then
		elseif args.spellName == MightyBlow then
			warningMightyBlow:Show()
			timerMightyBlowCD:Start()
		end
	end
end

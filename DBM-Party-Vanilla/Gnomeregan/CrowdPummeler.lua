local mod	= DBM:NewMod(418, "DBM-Party-Vanilla", 7, 231)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("@file-date-integer@")
mod:SetCreatureID(6229)
mod:SetEncounterID(381)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_SUCCESS 10887 8374"
)

local specWarnCrowdPummel			= mod:NewSpecialWarningSpell(10887, "Melee", nil, nil, 2, 2)

local timerCrowdPummelCD			= mod:NewAITimer(180, 10887, nil, nil, nil, 2)

local timerArcingSmashD				= mod:NewAITimer(180, 8374, nil, "Tank", 2, 5, nil, DBM_COMMON_L.TANK_ICON)

function mod:OnCombatStart(delay)
	timerCrowdPummelCD:Start(1-delay)
	timerArcingSmashD:Start(1-delay)
end

do
	local CrowdPummel, ArcingSmash = DBM:GetSpellInfo(10887), DBM:GetSpellInfo(8374)
	function mod:SPELL_CAST_SUCCESS(args)
		--if args.spellId == 10887 then
		if args.spellName == CrowdPummel then
			specWarnCrowdPummel:Show()
			specWarnCrowdPummel:Play("carefly")
			timerCrowdPummelCD:Start()
		--elseif args.spellId == 8374 then
		elseif args.ArcingSmash == 8374 then
			timerArcingSmashD:Start()
		end
	end
end

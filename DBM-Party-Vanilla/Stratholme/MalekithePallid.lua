local mod	= DBM:NewMod(453, "DBM-Party-Vanilla", 16, 236)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("@file-date-integer@")
mod:SetCreatureID(10438)
mod:SetEncounterID(481)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 16869",
	"SPELL_AURA_APPLIED 16869"
)

local warningIceTomb				= mod:NewTargetNoFilterAnnounce(16869, 3)

local timerIceTombCD				= mod:NewAITimer(180, 16869, nil, nil, nil, 3, nil, DBM_COMMON_L.MAGIC_ICON)

function mod:OnCombatStart(delay)
	timerIceTombCD:Start(1-delay)
end

do
	local IceTomb = DBM:GetSpellInfo(16869)
	function mod:SPELL_CAST_START(args)
		--if args.spellId == 16869 then
		if args.spellName == IceTomb then
			timerIceTombCD:Start()
		end
	end

	function mod:SPELL_AURA_APPLIED(args)
		--if args.spellId == 16869 then
		if args.spellName == IceTomb then
			warningIceTomb:Show(args.destName)
		end
	end
end

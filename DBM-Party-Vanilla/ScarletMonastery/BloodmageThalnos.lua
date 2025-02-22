local mod	= DBM:NewMod("BloodmageThalnos", "DBM-Party-Vanilla", 12)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("@file-date-integer@")
mod:SetCreatureID(4543)
--mod:SetEncounterID(585)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 8814",
	"SPELL_CAST_SUCCESS 12470"
)

--TODO, still can't use CD timer yet because only have initial timers from a single log, Fire nova timer too variable (8.5, 21 wtf?) to be useful
local warningFlameSpike				= mod:NewSpellAnnounce(8814, 2)
local warningFireNova				= mod:NewSpellAnnounce(12470, 2)

local timerFlameSpikeCD				= mod:NewAITimer(180, 8814, nil, nil, nil, 3)

function mod:OnCombatStart(delay)
--	timerFlameSpikeCD:Start(15.8-delay)
end

do
	local Flamespike = DBM:GetSpellInfo(8814)
	function mod:SPELL_CAST_START(args)
		--if args.spellId == 8814 then
		if args.spellName == Flamespike then
			warningFlameSpike:Show()
			timerFlameSpikeCD:Start()
		end
	end
end

do
	local FireNova = DBM:GetSpellInfo(12470)
	function mod:SPELL_CAST_SUCCESS(args)
		--if args.spellId == 12470 then
		if args.spellName == FireNova then
			warningFireNova:Show()
		end
	end
end

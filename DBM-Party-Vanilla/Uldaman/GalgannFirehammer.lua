local mod	= DBM:NewMod(471, "DBM-Party-Vanilla", 18, 239)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("@file-date-integer@")
mod:SetCreatureID(7291)
mod:SetEncounterID(552)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 6725 3356 11969"
)

local warningFireNova				= mod:NewSpellAnnounce(11969, 2)

local specWarnFlameSpike			= mod:NewSpecialWarningInterrupt(6725, "HasInterrupt", nil, nil, 1, 2)
local specWarnFlameLash				= mod:NewSpecialWarningInterrupt(3356, "HasInterrupt", nil, nil, 1, 2)

local timerFireNovaCD				= mod:NewAITimer(180, 11969, nil, nil, nil, 2)

function mod:OnCombatStart(delay)
	timerFireNovaCD:Start(1-delay)
end

do
	local FlameSpike, FlameLash, FireNova = DBM:GetSpellInfo(6725), DBM:GetSpellInfo(3356), DBM:GetSpellInfo(11969)
	function mod:SPELL_CAST_START(args)
		--if args.spellId == 6725 then
		if args.spellName == FlameSpike then
			if self:CheckInterruptFilter(args.sourceGUID, false, true) then
				specWarnFlameSpike:Show(args.sourceName)
				specWarnFlameSpike:Play("kickcast")
			end
		--elseif args.spellId == 3356 then
		elseif args.spellName == FlameLash then
			if self:CheckInterruptFilter(args.sourceGUID, false, true) then
				specWarnFlameLash:Show(args.sourceName)
				specWarnFlameLash:Play("kickcast")
			end
		--elseif args.spellId == 11969 then
		elseif args.spellName == FireNova then
			warningFireNova:Show()
			timerFireNovaCD:Start()
		end
	end
end

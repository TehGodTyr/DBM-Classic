local mod	= DBM:NewMod(451, "DBM-Party-Vanilla", 16, 236)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("@file-date-integer@")
mod:SetCreatureID(10436)
mod:SetEncounterID(479)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
--	"SPELL_CAST_SUCCESS 17244",
	"SPELL_AURA_APPLIED 17244 16867 18327"
)

local warningBansheeCurse		= mod:NewTargetNoFilterAnnounce(16867, 2, nil, "RemoveCurse")
local warningSilence			= mod:NewTargetNoFilterAnnounce(18327, 2, nil, "RemoveMagic")

local specWarnPossess			= mod:NewSpecialWarningTargetChange(17244, nil, nil, nil, 1, 2)

--local timerPossessCD			= mod:NewAITimer(180, 17244, nil, nil, nil, 3, nil, DBM_COMMON_L.DAMAGE_ICON)

--function mod:OnCombatStart(delay)
--	timerPossessCD:Start(1-delay)
--end

--[[
function mod:SPELL_CAST_SUCCESS(args)
	if args.spellId == 17244 then
--		timerPossessCD:Start()
	end
end
--]]

do
	local Possess, BansheeCurse, Silence = DBM:GetSpellInfo(17244), DBM:GetSpellInfo(16867), DBM:GetSpellInfo(18327)
	function mod:SPELL_AURA_APPLIED(args)
		--if args.spellId == 17244 then
		if args.spellName == Possess then
			specWarnPossess:Show(args.destName)
			specWarnPossess:Play("targetchange")
		--elseif args.spellId == 16867 then
		elseif args.spellName == BansheeCurse then
			warningBansheeCurse:CombinedShow(0.5, args.destName)
		--elseif args.spellId == 18327 then
		elseif args.spellName == Silence and args:IsDestTypePlayer() then
			warningSilence:CombinedShow(0.5, args.destName)
		end
	end
end

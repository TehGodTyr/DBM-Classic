local mod	= DBM:NewMod(430, "DBM-Party-Vanilla", 8, 232)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("@file-date-integer@")
mod:SetCreatureID(13596)
mod:SetEncounterID(428)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_SUCCESS 16495"
)

--Puncture too random, and not important enough, so removed. Fatal bite was never seen?
local warningFatalBite				= mod:NewSpellAnnounce(16495, 3)

local timerFatalBiteCD				= mod:NewAITimer(180, 16495, nil, nil, nil, 5, nil, DBM_COMMON_L.TANK_ICON)

function mod:OnCombatStart(delay)
	timerFatalBiteCD:Start(1-delay)
end

do
	local FatalBite = DBM:GetSpellInfo(16495)
	function mod:SPELL_CAST_SUCCESS(args)
		--if args.spellId == 15976 then
		if args.spellName == FatalBite then
			warningFatalBite:Show()
			timerFatalBiteCD:Start()
		end
	end
end

local mod	= DBM:NewMod("Golemagg", "DBM-MC", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("@file-date-integer@")
mod:SetCreatureID(11988)--, 11672
mod:SetEncounterID(670)
mod:SetModelID(11986)
mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_SUCCESS 20553"
)

local warnQuake		= mod:NewSpellAnnounce(20553)

do
	local Quake = DBM:GetSpellInfo(20553)
	function mod:SPELL_AURA_APPLIED(args)
		--if args.spellId == 20553 then
		if args.spellName == Quake then
			warnQuake:Show()
		end
	end
end

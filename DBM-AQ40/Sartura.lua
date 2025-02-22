local mod	= DBM:NewMod("Sartura", "DBM-AQ40", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("@file-date-integer@")
mod:SetCreatureID(15516)
mod:SetEncounterID(711)
mod:SetModelID(15583)
mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_SUCCESS 26083 8269",
	"UNIT_HEALTH mouseover target"
)

--Add sundering cleave?
local warnEnrageSoon	= mod:NewSoonAnnounce(8269, 2)
local warnEnrage		= mod:NewSpellAnnounce(8269, 4)
local warnWhirlwind		= mod:NewSpellAnnounce(26083, 3)

local specWarnWhirlwind	= mod:NewSpecialWarningRun(26083, false, nil, nil, 4, 2)

mod.vb.prewarn_enrage = false

function mod:OnCombatStart(delay)
	self.vb.prewarn_enrage = false
end

do
	local Whirlwind, Enrage = DBM:GetSpellInfo(26083), DBM:GetSpellInfo(8269)
	function mod:SPELL_CAST_SUCCESS(args)
		--if args:IsSpellID(26083) and self:AntiSpam() then--26084
		if args.spellName == Whirlwind and args:IsSrcTypeHostile() and self:AntiSpam(4, 1) then--26084
			if self:CheckInterruptFilter(args.sourceGUID, true) and self.Options.SpecWarn26083run then
				specWarnWhirlwind:Show()
				specWarnWhirlwind:Play("justrun")
			else
				warnWhirlwind:Show()
			end
		--elseif args.spellId == 8269 then
		elseif args.spellName == Enrage and args:IsSrcTypeHostile() then
			warnEnrage:Show()
		end
	end
end

function mod:UNIT_HEALTH(uId)
	if self:GetUnitCreatureId(uId) == 15516 and not self.vb.prewarn_enrage and UnitHealthMax(uId) and UnitHealthMax(uId) > 0 and (UnitHealth(uId) / UnitHealthMax(uId)) <= 0.35 then
		warnEnrageSoon:Show()
		self.vb.prewarn_enrage = true
	end
end

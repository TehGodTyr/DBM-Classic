local mod	= DBM:NewMod("Ayamiss", "DBM-AQ20", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("@file-date-integer@")
mod:SetCreatureID(15369)
mod:SetEncounterID(722)
mod:SetModelID(15431)
mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_AURA_APPLIED 25725 8269",
	"SPELL_AURA_REMOVED 25725",
	"UNIT_HEALTH mouseover target"
)

local warnPhase2	= mod:NewPhaseAnnounce(2)
local warnParalyze	= mod:NewTargetNoFilterAnnounce(25725, 3)
local warnEnrage	= mod:NewTargetNoFilterAnnounce(8269, 3)

local timerParalyze	= mod:NewTargetTimer(10, 25725, nil, nil, nil, 3)

function mod:OnCombatStart(delay)
	self:SetStage(1)
end

do
	local Paralyze, Enrage = DBM:GetSpellInfo(25725), DBM:GetSpellInfo(8269)
	function mod:SPELL_AURA_APPLIED(args)
		--if args.spellId == 25725 then
		if args.spellName == Paralyze then
			warnParalyze:Show(args.destName)
			timerParalyze:Start(args.destName)
		elseif args.spellName == Enrage and args:IsDestTypeHostile() then
			warnEnrage:Show(args.destName)
		end
	end

	function mod:SPELL_AURA_REMOVED(args)
		--if args.spellId == 25725 then
		if args.spellName == Paralyze then
			timerParalyze:Stop(args.destName)
		end
	end
end

function mod:UNIT_HEALTH(uId)
	if self.vb.phase < 2 and self:GetUnitCreatureId(uId) == 15369 and UnitHealthMax(uId) and UnitHealthMax(uId) > 0 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.70 then
		self:SetStage(2)
		warnPhase2:Show()
	end
end

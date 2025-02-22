local mod	= DBM:NewMod(478, "DBM-Party-Vanilla", 19, 240)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("@file-date-integer@")
mod:SetCreatureID(3674)
mod:SetEncounterID(589)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 6254"
)

--TODO, fix range to one classic actually supports
local timerChainedBoltCD			= mod:NewAITimer(180, 6254, nil, nil, nil, 3)

mod:AddRangeFrameOption(10, 6254)

function mod:OnCombatStart(delay)
	timerChainedBoltCD:Start(1-delay)
	if self.Options.RangeFrame then
		DBM.RangeCheck:Show(10)
	end
end

function mod:OnCombatEnd()
	if self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	end
end

do
	local ChainedBolt = DBM:GetSpellInfo(6254)
	function mod:SPELL_CAST_START(args)
		--if args.spellId == 6254 then
		if args.spellName == ChainedBolt and args:IsSrcTypeHostile() then
			timerChainedBoltCD:Start()
		end
	end
end

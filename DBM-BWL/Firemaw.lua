local mod	= DBM:NewMod("Firemaw", "DBM-BWL", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("@file-date-integer@")
mod:SetCreatureID(11983)
mod:SetEncounterID(613)
mod:SetModelID(6377)
mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 23339 22539",
	"SPELL_AURA_APPLIED_DOSE 23341"
)

--(ability.id = 23339 or ability.id = 22539) and type = "begincast" or ability.id = 23341 and type = "cast"
local warnWingBuffet		= mod:NewCastAnnounce(23339, 2)
local warnShadowFlame		= mod:NewCastAnnounce(22539, 2)
local warnFlameBuffet		= mod:NewCountAnnounce(23341, 3, nil, nil, DBM_CORE_L.AUTO_ANNOUNCE_OPTIONS.stack:format(23341))

local timerWingBuffet		= mod:NewCDTimer(31, 23339, nil, nil, nil, 2)--Verified on classic 31-36
local timerShadowFlameCD	= mod:NewCDTimer(14, 22539, nil, false)--14-21

if mod:IsSeasonal() then
	mod:AddTimerLine(DBM_COMMON_L.SEASONAL)
	mod:AddRangeFrameOption(10, 366305)
end

function mod:OnCombatStart(delay)
	timerShadowFlameCD:Start(18-delay)
	timerWingBuffet:Start(30-delay)
	if self:IsSeasonal() and self.Options.RangeFrame then
		DBM.RangeCheck:Show(10)
	end
end

function mod:OnCombatEnd()
	if self:IsSeasonal() and self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	end
end

do
	local WingBuffet, ShadowFlame = DBM:GetSpellInfo(23339), DBM:GetSpellInfo(22539)
	function mod:SPELL_CAST_START(args)--did not see ebon use any of these abilities
		--if args.spellId == 23339 then
		if args.spellName == WingBuffet then
			warnWingBuffet:Show()
			timerWingBuffet:Start()
		--elseif args.spellId == 22539 then
		elseif args.spellName == ShadowFlame then
			warnShadowFlame:Show()
			timerShadowFlameCD:Start()
		end
	end
end

do
	local FlameBuffet = DBM:GetSpellInfo(23341)
	function mod:SPELL_AURA_APPLIED_DOSE(args)
		--if args.spellId == 23341 then
		if args.spellName == FlameBuffet and args:IsPlayer() then
			local amount = args.amount or 1
			if (amount >= 4) and (amount % 2 == 0) then--Starting at 4, every even amount warn stack
				warnFlameBuffet:Show(amount)
			end
		end
	end
end

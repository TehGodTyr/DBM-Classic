local mod	= DBM:NewMod(458, "DBM-Party-Vanilla", 17, 237)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("@file-date-integer@")
mod:SetCreatureID(5710)--5711 Ogom the Wretched
mod:SetEncounterID(488)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 12492 12468 8376 12471",
	"SPELL_CAST_SUCCESS 12479",
	"SPELL_AURA_APPLIED 12479 11639 12493",
	"SPELL_AURA_REMOVED 12479",
	"UNIT_DIED"
)

local warningHealingWave				= mod:NewCastAnnounce(12492, 2)
local warningEarthgrabTotem				= mod:NewSpellAnnounce(8376, 2)
local warningFlamestrike				= mod:NewCastAnnounce(12468, 2)
local warningHexofJammalan				= mod:NewTargetNoFilterAnnounce(12479, 2)
--Ogom
local warningCurseofWeakness			= mod:NewTargetNoFilterAnnounce(12493, 2, nil, "RemoveCurse")
local warningShadowWordPain				= mod:NewTargetNoFilterAnnounce(11639, 2, nil, "RemoveMagic")

local specWarnHexofJammalan				= mod:NewSpecialWarningYou(12479, nil, nil, nil, 1, 2)
local yellHexofJammalan					= mod:NewYell(12479)
--local yellHexofJammalanFades			= mod:NewShortFadesYell(12479)--Requires BC plus, to distinquish 12479 vs 12480
--Ogom
local specWarnShadowBolt				= mod:NewSpecialWarningInterrupt(12471, "HasInterrupt", nil, nil, 1, 2)

--local timerHealingWaveCD				= mod:NewAITimer(180, 12492, nil, nil, nil, 3)
local timerEarthgrabTotemCD				= mod:NewAITimer(180, 8376, nil, nil, nil, 1)
local timerHexofJammalanCD				= mod:NewAITimer(180, 12479, nil, nil, nil, 3)
--Ogom
local timerShadowBoltCD					= mod:NewAITimer(180, 12479, nil, nil, nil, 4, nil, DBM_COMMON_L.INTERRUPT_ICON)

function mod:OnCombatStart(delay)
--	timerHealingWaveCD:Start(1-delay)
	timerEarthgrabTotemCD:Start(1-delay)
	timerHexofJammalanCD:Start(1-delay)
end

do
	local HealingWave, Flamestrike, Earthgrab, Shadowbolt = DBM:GetSpellInfo(12492), DBM:GetSpellInfo(12468), DBM:GetSpellInfo(8376), DBM:GetSpellInfo(12471)
	function mod:SPELL_CAST_START(args)
		--if args.spellId == 12492 then
		if args.spellName == HealingWave and args:IsSrcTypeHostile() then
			warningHealingWave:Show()
			--timerHealingWaveCD:Start()
		--elseif args.spellId == 12468 then
		elseif args.spellName == Flamestrike and args:IsSrcTypeHostile() then
			warningFlamestrike:Show()
		--elseif args.spellId == 8376 then
		elseif args.spellName == Earthgrab and args:IsSrcTypeHostile() then
			warningEarthgrabTotem:Show()
			timerEarthgrabTotemCD:Start()
		--elseif args.spellId == 12471 then
		elseif args.spellName == Shadowbolt and args:IsSrcTypeHostile() then
			timerShadowBoltCD:Start()
			if self:CheckInterruptFilter(args.sourceGUID, false, true) then
				specWarnShadowBolt:Show(args.sourceName)
				specWarnShadowBolt:Play("kickcast")
			end
		end
	end
end

do
	local HexofJammalan, ShadowWordPain, CurseofWeakness = DBM:GetSpellInfo(12479), DBM:GetSpellInfo(11639), DBM:GetSpellInfo(12493)
	function mod:SPELL_CAST_SUCCESS(args)
		--if args.spellId == 12479 then
		if args.spellName == HexofJammalan then
			timerHexofJammalanCD:Start()
		end
	end

	function mod:SPELL_AURA_APPLIED(args)
		--if args.spellId == 12479 then--12480 is curse debuff ID after initial 10 seconds
		if args.spellName == HexofJammalan then
			if args:IsPlayer() then
				specWarnHexofJammalan:Show()
				specWarnHexofJammalan:Play("targetyou")
				yellHexofJammalan:Yell()
				--yellHexofJammalanFades:Countdown(12479)--Valid in retail, in classic we can't tell what version of debuff is so disabled
			else
				warningHexofJammalan:Show(args.destName)
			end
		--elseif args.spellId == 11639 then
		elseif args.spellName == ShadowWordPain and args:IsDestTypePlayer() then
			warningShadowWordPain:Show(args.destName)
		--elseif args.spellId == 12493 then
		elseif args.spellName == CurseofWeakness and args:IsDestTypePlayer() then
			warningCurseofWeakness:Show(args.destName)
		end
	end
	--[[
	function mod:SPELL_AURA_REMOVED(args)
		if args.spellId == 12479 then
			if args:IsPlayer() then
				yellHexofJammalanFades:Cancel()--Valid in retail, in classic we can't tell what version of debuff is so disabled
			end
		end
	end
	--]]
end

function mod:UNIT_DIED(args)
	local cid = self:GetCIDFromGUID(args.destGUID)
	if cid == 5711 then--Ogom the Wretched
		timerShadowBoltCD:Stop()
	end
end

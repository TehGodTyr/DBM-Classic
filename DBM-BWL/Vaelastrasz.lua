local mod	= DBM:NewMod("Vaelastrasz", "DBM-BWL", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("@file-date-integer@")
mod:SetCreatureID(13020)
mod:SetEncounterID(611)
mod:SetModelID(13992)
mod:SetUsedIcons(8, 7, 6)

mod:RegisterCombat("combat")

mod:RegisterEvents(
	"CHAT_MSG_MONSTER_YELL"
)

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 23461",
	"SPELL_CAST_SUCCESS 18173",
	"SPELL_AURA_APPLIED 18173",
	"SPELL_AURA_REMOVED 18173"
)

local warnBreath			= mod:NewCastAnnounce(23461, 2, nil, nil, "Tank", 3)
local warnAdrenaline		= mod:NewTargetNoFilterAnnounce(18173, 2)

local specWarnAdrenaline	= mod:NewSpecialWarningYou(18173, nil, nil, nil, 1, 2)--367987 for SoM, but since classic is using only spellname, don't need it ATM
local specWarnAdrenalineOut	= mod:NewSpecialWarningMoveAway(18173, nil, nil, 2, 3, 2)
local yellAdrenaline		= mod:NewYell(18173, nil, false)
local yellAdrenalineFades	= mod:NewShortFadesYell(18173)

local timerAdrenalineCD		= mod:NewCDTimer(15.7, 18173, nil, nil, nil, 3)
local timerAdrenaline		= mod:NewTargetTimer(20, 18173, nil, nil, nil, 5)
local timerCombatStart		= mod:NewCombatTimer(43)

if not mod:IsSeasonal() then
	mod:AddSetIconOption("SetIconOnDebuffTarget2", 18173, true, false, {8, 7, 6})
end

mod.vb.debuffIcon = 8

function mod:OnCombatStart(delay)
	self.vb.debuffIcon = 8
	if not self:IsSeasonal() then
		timerAdrenalineCD:Start(15.7-delay)
	end
end

do
	local FlameBreath = DBM:GetSpellInfo(23461)
	function mod:SPELL_CAST_START(args)
		--if args.spellId == 23461 then
		if args.spellName == FlameBreath then
			warnBreath:Show()
		end
	end
end

do
	local BurningAdrenaline = DBM:GetSpellInfo(18173)
	function mod:SPELL_CAST_SUCCESS(args)
		--if args.spellId == 23461 then
		if args.spellName == BurningAdrenaline and not self:IsSeasonal() then
			timerAdrenalineCD:Start()--Not CD based on SoM,
		end
	end

	function mod:SPELL_AURA_APPLIED(args)
		--if args.spellId == 18173 then
		if args.spellName == BurningAdrenaline then
			if not self:IsSeasonal() then
				timerAdrenaline:Start(args.destName)
				if self.Options.SetIconOnDebuffTarget2 then
					self:SetIcon(args.destName, self.vb.debuffIcon)
				end
				self.vb.debuffIcon = self.vb.debuffIcon - 1
				if self.vb.debuffIcon == 5 then
					self.vb.debuffIcon = 8
				end
			end
			if args:IsPlayer() then
				specWarnAdrenaline:Show()
				specWarnAdrenaline:Play("targetyou")
				yellAdrenaline:Yell()
				if not self:IsSeasonal() then--In seasonal, it's not timed, it's "how long can you live"
					specWarnAdrenalineOut:Schedule(15)
					specWarnAdrenalineOut:ScheduleVoice(15, "runout")
					yellAdrenalineFades:Countdown(20)
				end
			else
				warnAdrenaline:Show(args.destName)
			end
		end
	end

	function mod:SPELL_AURA_REMOVED(args)
		--if args.spellId == 18173 then
		if args.spellName == BurningAdrenaline then
			if args:IsPlayer() then
				specWarnAdrenalineOut:Cancel()
				specWarnAdrenalineOut:CancelVoice()
				yellAdrenalineFades:Cancel()
			end
			if not self:IsSeasonal() then
				if self.Options.SetIconOnDebuffTarget2 then
					self:SetIcon(args.destName, 0)
				end
				timerAdrenaline:Stop(args.destName)
			end
		end
	end
end

--Missing first line
--"<8.85 19:59:36> [CHAT_MSG_MONSTER_YELL] I beg you, mortals - FLEE! Flee before I lose all sense of control! The black fire rages within my heart! I MUST- release it! #Vaelastrasz the Corrupt###Adornment##0#0##0#13862#nil#0#false#false#
--"<28.25 19:59:55> [CHAT_MSG_MONSTER_YELL] FLAME! DEATH! DESTRUCTION! Cower, mortals before the wrath of Lord...NO - I MUST fight this! Alexstrasza help me, I MUST fight it! #Vaelastrasz the Corrupt###Adornment
--"<38.98 20:00:06> [ENCOUNTER_START] 611#Vaelastrasz the Corrupt#9#40", -- [152]
function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L.Event or msg:find(L.Event) then
		if self:AntiSpam(5, "PullRP") then
			self:SendSync("PullRP")
		end
	end
end

function mod:OnSync(msg)
	if msg == "PullRP" then
		timerCombatStart:Start()
	end
end

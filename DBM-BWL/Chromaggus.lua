local mod	= DBM:NewMod("Chromaggus", "DBM-BWL", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("@file-date-integer@")
mod:SetCreatureID(14020)
mod:SetEncounterID(616)
mod:SetModelID(14367)
mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 23309 23313 23189 23315 23312",
	"SPELL_AURA_APPLIED 23155 23169 23153 23154 23170 23128 23537",
--	"SPELL_AURA_REFRESH",
	"SPELL_AURA_REMOVED 23155 23169 23153 23154 23170 23128",
	"UNIT_HEALTH mouseover target",
	"CHAT_MSG_MONSTER_EMOTE"
)

--TODO, maybe announce ice tomb spawns? could be spammy though
--(ability.id = 23308 or ability.id = 23309 or ability.id = 23313 or ability.id = 23314 or ability.id = 23197 or ability.id = 23189 or ability.id = 23315 or ability.id = 23316 or ability.id = 23310 or ability.id = 23312) and type = "begincast"
local warnBreath		= mod:NewAnnounce("WarnBreath", 2, 23316)
local warnRed			= mod:NewSpellAnnounce(23155, 2, nil, false)
local warnGreen			= mod:NewSpellAnnounce(23169, 2, nil, false)
local warnBlue			= mod:NewSpellAnnounce(23153, 2, nil, false)
local warnBlack			= mod:NewSpellAnnounce(23154, 2, nil, false)
local warnFrenzy		= mod:NewSpellAnnounce(23128, 3, nil, "Tank|RemoveEnrage|Healer", 5)
local warnPhase2Soon	= mod:NewPrePhaseAnnounce(2, 1)
local warnPhase2		= mod:NewPhaseAnnounce(2)
local warnMutation		= mod:NewCountAnnounce(23174, 4)
local warnVuln			= mod:NewAnnounce("WarnVulnerable", 1, false)

local specWarnBronze	= mod:NewSpecialWarningYou(23170, nil, nil, nil, 1, 8)
local specWarnFrenzy	= mod:NewSpecialWarningDispel(23128, "RemoveEnrage", nil, nil, 1, 6)

local timerBreath		= mod:NewTimer(2, "TimerBreath", 23316, nil, nil, 3)
local timerBreathCD		= mod:NewTimer(60, "TimerBreathCD", 23316, nil, nil, 3)
local timerFrenzy		= mod:NewBuffActiveTimer(8, 23128, nil, "Tank|RemoveEnrage|Healer", 4, 5, nil, DBM_COMMON_L.TANK_ICON..DBM_COMMON_L.ENRAGE_ICON)
local timerVuln			= mod:NewTimer(17, "TimerVulnCD")-- seen 16.94 - 25.53, avg 21.8

mod:AddNamePlateOption("NPAuraOnVulnerable", 22277)
mod:AddInfoFrameOption(22277, true)
--SoM Stuff
mod:AddTimerLine(DBM_COMMON_L.SEASONAL)
local specWarnBreath	= mod:NewSpecialWarningMoveTo(22268, nil, nil, nil, 3, 2)
local specWarnGTFO		= mod:NewSpecialWarningGTFO(367688, nil, nil, nil, 1, 8)

local mydebuffs = 0
local Incinerate, CorrosiveAcid, FrostBurn, IgniteFlesh, TimeLaps = DBM:GetSpellInfo(23309), DBM:GetSpellInfo(23313), DBM:GetSpellInfo(23189), DBM:GetSpellInfo(23315), DBM:GetSpellInfo(23312)
local spellIcons = {
	[Incinerate] = 23309,
	[CorrosiveAcid] = 23313,
	[FrostBurn] = 23189,
	[IgniteFlesh] = 23315,
	[TimeLaps] = 23312,
}

local lastVulnName = nil
local vulnerabilities = {
	-- [guid] = school
}

--Constants
-- https://wow.gamepedia.com/COMBAT_LOG_EVENT
local spellInfo = {
	[2] =	{"Holy",	{r=255, g=230, b=128},	"135924"},-- Smite
	[4] =	{"Fire",	{r=255, g=128, b=0},	"135808"},-- Pyroblast
	[8] =	{"Nature",	{r=77, g=255, b=77},	"136006"},-- Wrath
	[16] =	{"Frost",	{r=128, g=255, b=255},	"135846"},-- Frostbolt
	[32] =	{"Shadow",	{r=128, g=128, b=255},	"136197"},-- Shadow Bolt
	[64] =	{"Arcane",	{r=255, g=128, b=255},	"136096"},-- Arcane Missiles
}

local vulnSpells = {
	--No Holy?
	[22277] = 4,
	[22280] = 8,
	[22278] = 16,
	[22279] = 32,
	[22281] = 64,
}

local updateInfoFrame
do
	local twipe = table.wipe
	local lines, sortedLines = {}, {}
	local function addLine(key, value)
		-- sort by insertion order
		lines[key] = value
		sortedLines[#sortedLines + 1] = key
	end
	updateInfoFrame = function()
		twipe(lines)
		twipe(sortedLines)
		if lastVulnName then
			addLine(lastVulnName, "")
		end
		return lines, sortedLines
	end
end

--Local Functions
-- in theory this should only alert on a new vulnerability on your target or when you change target
local function update_vulnerability(self)
	local target = UnitGUID("target")
	local spellSchool = vulnerabilities[target]
	local cid = self:GetCIDFromGUID(target)
	if not spellSchool or cid ~= 14020 then
		return
	end

	local info = spellInfo[spellSchool]
	if not info then return end
	local name = L[info[1]] or info[1]

	timerVuln:SetColor(info[2])
	timerVuln:UpdateIcon(info[3])
	timerVuln:UpdateName(name)
	if not lastVulnName or lastVulnName ~= name then
		warnVuln.icon = info[3]
		warnVuln:Show(name)
		lastVulnName = name
		if self.Options.InfoFrame then
			if not DBM.InfoFrame:IsShown() then
				DBM.InfoFrame:SetHeader(L.Vuln)
				DBM.InfoFrame:Show(1, "function", updateInfoFrame, false, false, true)
			else
				DBM.InfoFrame:Update()
			end
		end
		if self.Options.NPAuraOnVulnerable then
			DBM.Nameplate:Hide(true, target, 22277, 135924)
			DBM.Nameplate:Hide(true, target, 22277, 135808)
			DBM.Nameplate:Hide(true, target, 22277, 136006)
			DBM.Nameplate:Hide(true, target, 22277, 135846)
			DBM.Nameplate:Hide(true, target, 22277, 136197)
			DBM.Nameplate:Hide(true, target, 22277, 136096)
			DBM.Nameplate:Show(true, target, 22277, tonumber(info[3]))
		end
	end
	self:UnregisterShortTermEvents()--Unregister SPELL_DAMAGE until next shimmer emote
end

local function check_spell_damage(self, target, amount, spellSchool, critical)
	local cid = self:GetCIDFromGUID(target)
	if cid ~= 14020 then
		return
	end
	if amount > (critical and 1600 or 800) then
		if not vulnerabilities[target] or vulnerabilities[target] ~= spellSchool then
			vulnerabilities[target] = spellSchool
			update_vulnerability(self)
		end
	end
end

local function check_target_vulns(self)
	local target = UnitGUID("target")
	local cid = self:GetCIDFromGUID(target)
	if cid ~= 14020 then
		return
	end

	local spellId = select(10, DBM:UnitBuff("target", 22277, 22280, 22278, 22279, 22281)) or 0
	local vulnSchool = vulnSpells[spellId]
	if vulnSchool then
		return check_spell_damage(self, target, 10000, vulnSchool)
	end
end

function mod:OnCombatStart(delay)
	self:SetStage(1)
	if self:IsSeasonal() then
		timerBreathCD:Start(30-delay, L.Breath)
	else
		timerBreathCD:Start(30-delay, L.Breath1)
		timerBreathCD:Start(60-delay, L.Breath2)--60
	end
	mydebuffs = 0
	table.wipe(vulnerabilities)
	if self:IsDifficulty("event40") or not self:IsTrivial(75) then--Only want to warn if it's a threat
		if self:IsSeasonal() then
			if self.Options.WarnVulnerable then--Don't register high cpu combat log events if option isn't enabled
				self:RegisterShortTermEvents(
					"SPELL_DAMAGE",
					"SPELL_PERIODIC_DAMAGE 367688",
					"SPELL_PERIODIC_MISSED 367688"
				)
				check_target_vulns(self)
				if self.Options.NPAuraOnVulnerable then
					DBM:FireEvent("BossMod_EnableHostileNameplates")
				end
			else
				self:RegisterShortTermEvents(
					"SPELL_PERIODIC_DAMAGE 367688",
					"SPELL_PERIODIC_MISSED 367688"
				)
			end
		else
			if self.Options.WarnVulnerable then--Don't register high cpu combat log events if option isn't enabled
				self:RegisterShortTermEvents(
					"SPELL_DAMAGE"
				)
				check_target_vulns(self)
				if self.Options.NPAuraOnVulnerable then
					DBM:FireEvent("BossMod_EnableHostileNameplates")
				end
			end
		end
	end
end

function mod:OnCombatEnd()
	table.wipe(vulnerabilities)
	self:UnregisterShortTermEvents()
	if self.Options.NPAuraOnVulnerable  then
		DBM.Nameplate:Hide(true, nil, nil, nil, true, true)--isGUID, unit, spellId, texture, force, isHostile, isFriendly
	end
	if self.Options.InfoFrame then
		DBM.InfoFrame:Hide()
	end
end

do
	local frostTomb = DBM:GetSpellInfo(367672)
	function mod:SPELL_CAST_START(args)
		--if args:IsSpellID(23309, 23313, 23189, 23315, 23312) then
		if args.spellName == Incinerate or args.spellName == CorrosiveAcid or args.spellName == FrostBurn or args.spellName == IgniteFlesh or args.spellName == TimeLaps then
			timerBreath:Start(2, args.spellName)
			if self:IsSeasonal() then
				if self.Options.SpecWarn22268moveto then
					specWarnBreath:Show(frostTomb)
					specWarnBreath:Play("findshelter")
				else
					warnBreath:Show(args.spellName)
				end
				--In seasonal it's all breaths, in random order
				timerBreathCD:Start(30.7, L.Breath)
			else--Out of season it's two types alternating
				warnBreath:Show(args.spellName)
				timerBreath:UpdateIcon(spellIcons[args.spellName])
				timerBreathCD:Start(60, args.spellName)
				timerBreathCD:UpdateIcon(spellIcons[args.spellName])
			end
		end
	end
end

do
	local BroodAffRed, BroodAffGreen, BroodAffBlue, BroodAffBlack, BroodAffBronze = DBM:GetSpellInfo(23155), DBM:GetSpellInfo(23169), DBM:GetSpellInfo(23153), DBM:GetSpellInfo(23154), DBM:GetSpellInfo(23170)
	local Frenzy, Enrage = DBM:GetSpellInfo(23128), DBM:GetSpellInfo(23537)
	function mod:SPELL_AURA_APPLIED(args)
		--if args.spellId == 23155 and self:AntiSpam(3, 1) then
		if args.spellName == BroodAffRed then
			if self:AntiSpam(3, 3) then
				warnRed:Show()
			end
			if args:IsPlayer() then
				mydebuffs = mydebuffs + 1
				if mydebuffs >= 3 then
					warnMutation:Show(mydebuffs.."/5")
				end
			end
		--elseif args.spellId == 23169 and self:AntiSpam(3, 2) then
		elseif args.spellName == BroodAffGreen then
			if self:AntiSpam(3, 4) then
				warnGreen:Show()
			end
			if args:IsPlayer() then
				mydebuffs = mydebuffs + 1
				if mydebuffs >= 3 then
					warnMutation:Show(mydebuffs.."/5")
				end
			end
		--elseif args.spellId == 23153 and self:AntiSpam(3, 3) then
		elseif args.spellName == BroodAffBlue then
			if self:AntiSpam(3, 5) then
				warnBlue:Show()
			end
			if args:IsPlayer() then
				mydebuffs = mydebuffs + 1
				if mydebuffs >= 3 then
					warnMutation:Show(mydebuffs.."/5")
				end
			end
		--elseif args.spellId == 23154 and self:AntiSpam(3, 4) then
		elseif args.spellName == BroodAffBlack then
			if self:AntiSpam(3, 6) then
				warnBlack:Show()
			end
			if args:IsPlayer() then
				mydebuffs = mydebuffs + 1
				if mydebuffs >= 3 then
					warnMutation:Show(mydebuffs.."/5")
				end
			end
		--elseif args.spellId == 23170 and args:IsPlayer() then
		elseif args.spellName == BroodAffBronze and args:IsPlayer() then
			specWarnBronze:Show()
			specWarnBronze:Play("useitem")
			mydebuffs = mydebuffs + 1
			if mydebuffs >= 3 then
				warnMutation:Show(mydebuffs.."/5")
			end
		--elseif args.spellId == 23128 then
		elseif args.spellName == Frenzy and args:IsDestTypeHostile() then
			if self.Options.SpecWarn23128dispel then
				specWarnFrenzy:Show(args.destName)
				specWarnFrenzy:Play("enrage")
			else
				warnFrenzy:Show()
			end
			timerFrenzy:Start()
		--elseif args.spellId == 23537 then
		elseif args.spellName == Enrage and args:IsDestTypeHostile() then
			if self.vb.phase < 2 then
				self:SetStage(2)
				warnPhase2:Show()
			end
		end
	end
	--Possibly needed hard to say.
	--mod.SPELL_AURA_REFRESH = mod.SPELL_AURA_APPLIED

	function mod:SPELL_AURA_REMOVED(args)
		--if args.spellId == 23128 then
		if args.spellName == BroodAffRed and args:IsPlayer() then
			mydebuffs = mydebuffs - 1
		--elseif args.spellId == 23169 and self:AntiSpam(3, 2) then
		elseif args.spellName == BroodAffGreen and args:IsPlayer()  then
			mydebuffs = mydebuffs - 1
		--elseif args.spellId == 23153 and self:AntiSpam(3, 3) then
		elseif args.spellName == BroodAffBlue and args:IsPlayer() then
			mydebuffs = mydebuffs - 1
		--elseif args.spellId == 23154 and self:AntiSpam(3, 4) then
		elseif args.spellName == BroodAffBlack and args:IsPlayer() then
			mydebuffs = mydebuffs - 1
		--elseif args.spellId == 23170 and args:IsPlayer() then
		elseif args.spellName == BroodAffBronze and args:IsPlayer() then
			mydebuffs = mydebuffs - 1
		elseif args.spellName == Frenzy and args:IsDestTypeHostile() then
			timerFrenzy:Stop()
		end
	end
end

function mod:SPELL_DAMAGE(_, _, _, _, destGUID, _, _, _, _, _, spellSchool, amount, _, _, _, _, _, critical)
	check_spell_damage(self, destGUID, amount, spellSchool, critical)
end

do
	local FirePitch = DBM:GetSpellInfo(367688)
	function mod:SPELL_PERIODIC_DAMAGE(_, _, _, _, destGUID, destName, _, _, spellId, spellName)
		--if spellId == 367688 and destGUID == UnitGUID("player") and self:AntiSpam() then
		if spellName == FirePitch and destGUID == UnitGUID("player") and self:AntiSpam(3, 7) then
			specWarnGTFO:Show(spellName)
			specWarnGTFO:Play("watchfeet")
		end
	end
	mod.SPELL_PERIODIC_MISSED = mod.SPELL_PERIODIC_DAMAGE
end

function mod:UNIT_HEALTH(uId)
	if UnitHealthMax(uId) and UnitHealthMax(uId) > 0 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.25 and self:GetUnitCreatureId(uId) == 14020 and self.vb.phase == 1 then
		warnPhase2Soon:Show()
		self:SetStage(1.5)
	end
end

function mod:CHAT_MSG_MONSTER_EMOTE(msg)
	if (msg == L.VulnEmote or msg:find(L.VulnEmote)) then
		self:SendSync("Vulnerable")
	end
end

function mod:OnSync(msg)
	if not self:IsInCombat() then return end
	if msg == "Vulnerable" then
		timerVuln:Start()
		table.wipe(vulnerabilities)
		if self.Options.WarnVulnerable then
			self:RegisterShortTermEvents(
				"SPELL_DAMAGE"
			)
			check_target_vulns(self)
		end
	end
end

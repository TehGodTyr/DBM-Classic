local mod	= DBM:NewMod("Ragnaros-Classic", "DBM-MC", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("@file-date-integer@")
mod:SetCreatureID(11502)
mod:SetEncounterID(672)
mod:SetModelID(11121)
mod:SetHotfixNoticeRev(20220122000000)
mod:SetMinSyncRevision(20220122000000)

mod:RegisterCombat("combat")

mod:RegisterEvents(
	"SPELL_CAST_START 19774",
	"SPELL_CAST_SUCCESS 20566 19773",
	"CHAT_MSG_MONSTER_YELL"
)
mod:RegisterEventsInCombat(
	"SPELL_AURA_APPLIED 363731",
	"UNIT_DIED"
)

--[[
ability.id = 20566 and type = "cast" or target.id = 12143 and type = "death"
 or ability.id = 363731 and type = "applybuff"
 or (source.type = "NPC" and source.firstSeen = timestamp) or (target.type = "NPC" and target.firstSeen = timestamp)
--]]
local warnWrathRag		= mod:NewSpellAnnounce(20566, 3)
local warnSubmerge		= mod:NewAnnounce("WarnSubmerge", 2, "Interface\\AddOns\\DBM-Core\\textures\\CryptFiendBurrow.blp")
local warnEmerge		= mod:NewAnnounce("WarnEmerge", 2, "Interface\\AddOns\\DBM-Core\\textures\\CryptFiendUnBurrow.blp")

local timerWrathRag		= mod:NewCDTimer(25, 20566, nil, nil, nil, 2, nil, DBM_COMMON_L.IMPORTANT_ICON, nil, mod:IsMelee() and 1, 4)--25-31.6
local timerSubmerge		= mod:NewTimer(180, "TimerSubmerge", "Interface\\AddOns\\DBM-Core\\textures\\CryptFiendBurrow.blp", nil, nil, 6, nil, nil, 1, 5)
local timerEmerge		= mod:NewTimer(90, "TimerEmerge", "Interface\\AddOns\\DBM-Core\\textures\\CryptFiendUnBurrow.blp", nil, nil, 6, nil, nil, 1, 5)
local timerCombatStart	= mod:NewTimer(78, "timerCombatStart", "132349", nil, nil, nil, nil, nil, 1, 3)

mod:AddRangeFrameOption("18", nil, "-Melee")
mod:AddTimerLine(DBM_COMMON_L.SEASONAL)
local timerAddsCD		= mod:NewAddsCustomTimer(60, 19497, nil, "-Healer", nil, 1, nil, DBM_COMMON_L.DAMAGE_ICON)

mod.vb.addLeft = 0
mod.vb.ragnarosEmerged = true
mod.vb.somAddSpawn = 0
local addsGuidCheck = {}
local firstBossMod = DBM:GetModByName("MCTrash")
local somAddsTimers = {0, 29.5, 25.8}--10 repeating after that. Also 0 is kinda fickle bitch because it's hard from only a combat log to determine timing of first spawn relative to boss health

function mod:OnCombatStart(delay)
	table.wipe(addsGuidCheck)
	self.vb.addLeft = 0
	self.vb.somAddSpawn = 0
	self.vb.ragnarosEmerged = true
	timerWrathRag:Start(26.7-delay)
	timerSubmerge:Start(180-delay)
	if self.Options.RangeFrame then
		DBM.RangeCheck:Show(18)
	end
end

function mod:OnCombatEnd(wipe)
	if self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	end
	if not wipe then
		DBT:CancelBar(DBM_CORE_L.SPEED_CLEAR_TIMER_TEXT)
		if firstBossMod.vb.firstEngageTime then
			local thisTime = GetServerTime() - firstBossMod.vb.firstEngageTime
			if thisTime and thisTime > 0 then
				if not firstBossMod.Options.FastestClear2 then
					--First clear, just show current clear time
					DBM:AddMsg(DBM_CORE_L.RAID_DOWN:format("MC", DBM:strFromTime(thisTime)))
					firstBossMod.Options.FastestClear2 = thisTime
				elseif (firstBossMod.Options.FastestClear2 > thisTime) then
					--Update record time if this clear shorter than current saved record time and show users new time, compared to old time
					DBM:AddMsg(DBM_CORE_L.RAID_DOWN_NR:format("MC", DBM:strFromTime(thisTime), DBM:strFromTime(firstBossMod.Options.FastestClear2)))
					firstBossMod.Options.FastestClear2 = thisTime
				else
					--Just show this clear time, and current record time (that you did NOT beat)
					DBM:AddMsg(DBM_CORE_L.RAID_DOWN_L:format("MC", DBM:strFromTime(thisTime), DBM:strFromTime(firstBossMod.Options.FastestClear2)))
				end
			end
			firstBossMod.vb.firstEngageTime = nil
		end
	end
end

local function emerged(self)
	self.vb.ragnarosEmerged = true
	timerEmerge:Stop()
	warnEmerge:Show()
	timerWrathRag:Start(26.7)--need to find out what it is first.
	timerSubmerge:Start(180)
end

do
	local summonRag = DBM:GetSpellInfo(19774)
	function mod:SPELL_CAST_START(args)
		--if args.spellId == 20566 then
		if args.spellName == summonRag and self:AntiSpam(5, 4) then
			--This is still going to use a sync event because someone might start this RP from REALLY REALLY far away
			self:SendSync("SummonRag")
		end
	end
end

do
	local Wrath, domoDeath = DBM:GetSpellInfo(20566), DBM:GetSpellInfo(19773)
	function mod:SPELL_CAST_SUCCESS(args)
		--if args.spellId == 20566 then
		if args.spellName == Wrath then
			warnWrathRag:Show()
			timerWrathRag:Start()
		elseif args.spellName == domoDeath then
			--This is still going to use a sync event because someone might start this RP from REALLY REALLY far away
			self:SendSync("DomoDeath")
		end
	end
end

do
	local volcanicUnrest = DBM:GetSpellInfo(363731)
	function mod:SPELL_AURA_APPLIED(args)
		--if args.spellId == 363731 then
		if args.spellName == volcanicUnrest and self.vb.ragnarosEmerged and args:GetDestCreatureID() == 12143 and self:AntiSpam(5, 1) then
			self.vb.somAddSpawn = self.vb.somAddSpawn + 1
			local timer = somAddsTimers[self.vb.somAddSpawn+1] or 10
			timerAddsCD:Start(timer, self.vb.somAddSpawn+1)
		end
	end
end

function mod:UNIT_DIED(args)
	local guid = args.destGUID
	local cid = self:GetCIDFromGUID(guid)
	if cid == 12143 then--Son of Flame
		if not addsGuidCheck[guid] then
			addsGuidCheck[guid] = true
			self.vb.addLeft = self.vb.addLeft - 1
			if not self.vb.ragnarosEmerged and self.vb.addLeft == 0 then--After all 8 die he emerges immediately
				self:Unschedule(emerged)
				emerged(self)
			end
		end
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L.Submerge then
		self:SendSync("Submerge")
	elseif msg == L.Pull and self:AntiSpam(5, 4) then
		self:SendSync("SummonRag")
	end
end

function mod:OnSync(msg, guid)
	if msg == "SummonRag" and self:AntiSpam(5, 2) then
		timerCombatStart:Start()
	elseif msg == "Submerge" and self:IsInCombat() then
		self.vb.ragnarosEmerged = false
		self:Unschedule(emerged)
		timerWrathRag:Stop()
		timerSubmerge:Stop()
		warnSubmerge:Show()
--		local timer = self:IsSeasonal() and 180 or 90--Not confirmed, just from streamer notes
		timerEmerge:Start(90)
		self:Schedule(90, emerged, self)
		self.vb.addLeft = self.vb.addLeft + 8
	elseif msg == "DomoDeath" and self:AntiSpam(5, 3) then
		--The timer between yell/summon start and ragnaros being attackable is variable, but time between domo death and him being attackable is not.
		--As such, we start lowest timer of that variation on the RP start, but adjust timer if it's less than 10 seconds at time domo dies
		local remaining = timerCombatStart:GetRemaining()
		if remaining then
			if remaining < 10 then
				local adjust = 10 - remaining
				timerCombatStart:AddTime(adjust)
			elseif remaining > 10 then
				local adjust = remaining - 10
				timerCombatStart:RemoveTime(adjust)
			end
		end
	end
end

local mod	= DBM:NewMod(450, "DBM-Party-Vanilla", 16, 236)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("@file-date-integer@")
mod:SetCreatureID(10516)
mod:SetEncounterID(472)

mod:RegisterCombat("combat")

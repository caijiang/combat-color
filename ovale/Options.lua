--[[--------------------------------------------------------------------
    Copyright (C) 2012, 2013 Sidoine De Wispelaere.
    Copyright (C) 2012, 2013, 2014 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

-- Ovale options and UI

local OVALE, Ovale = ...
local OvaleOptions = Ovale:NewModule("OvaleOptions", "AceConsole-3.0", "AceEvent-3.0")
Ovale.OvaleOptions = OvaleOptions

--<private-static-properties>
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local L = Ovale.L

local ipairs = ipairs
local pairs = pairs
local tinsert = table.insert
local type = type
local API_InterfaceOptionsFrame_OpenToCategory = InterfaceOptionsFrame_OpenToCategory
-- GLOBALS: LibStub

-- List of registered modules providing options.
local self_register = {}
--</private-static-properties>

--<public-static-properties>
-- AceDB default database.
OvaleOptions.defaultDB = {
	profile = {
		check = {},
		list = {},
		standaloneOptions = false,
		apparence = {
			-- Icon group
			avecCible = false,
			clickThru = false,
			enCombat = false,
			enableIcons = true,
			hideEmpty = false,
			hideVehicule = false,
			margin = 4,
			offsetX = 0,
			offsetY = 0,
			targetHostileOnly = false,
			verrouille = false,
			vertical = false,
			-- Icon
			alpha = 1,
			flashIcon = true,
			fontScale = 1,
			highlightIcon = true,
			iconScale = 1,
			numeric = false,
			raccourcis = true,
			smallIconScale = 0.8,
			targetText = "●",
			-- Options
			iconShiftX = 0,
			iconShiftY = 0,
			optionsAlpha = 1,
			-- Two abilities
			predictif = false,
			secondIconScale = 1,
			-- Advanced
			taggedEnemies = false,
			auraLag = 400,
		},
	},
}

-- AceDB options table.
OvaleOptions.options = {
	type = "group",
	args =
	{
		apparence = {
			name = OVALE,
			type = "group",
			-- Generic getter/setter for options.
			get = function(info)
				return Ovale.db.profile.apparence[info[#info]]
			end,
			set = function(info, value)
				Ovale.db.profile.apparence[info[#info]] = value
				-- Pass the name of the parent group as the event parameter.
				OvaleOptions:SendMessage("Ovale_OptionChanged", info[#info - 1])
			end,
			args = {}
		},
		actions = {
			name = "Actions",
			type = "group",
			args = {}
		},
	},
}
--</public-static-properties>

--<public-static-methods>
function OvaleOptions:OnInitialize()
	local db = LibStub("AceDB-3.0"):New("OvaleDB", self.defaultDB)
	self.options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(db)

	-- Add dual-spec support
	local LibDualSpec = LibStub("LibDualSpec-1.0",true)
	if LibDualSpec then
		LibDualSpec:EnhanceDatabase(db, "Ovale")
		LibDualSpec:EnhanceOptions(self.options.args.profile, db)
	end

	db.RegisterCallback( self, "OnNewProfile", "HandleProfileChanges" )
	db.RegisterCallback( self, "OnProfileReset", "HandleProfileChanges" )
	db.RegisterCallback( self, "OnProfileChanged", "HandleProfileChanges" )
	db.RegisterCallback( self, "OnProfileCopied", "HandleProfileChanges" )

	Ovale.db = db

	-- Upgrade saved variables to current format.
	self:UpgradeSavedVariables()

	AceConfig:RegisterOptionsTable(OVALE, self.options.args.apparence)
	AceConfig:RegisterOptionsTable(OVALE .. " Profiles", self.options.args.profile)
	-- Slash commands.
	AceConfig:RegisterOptionsTable(OVALE .. " Actions", self.options.args.actions, "Ovale")

	AceConfigDialog:AddToBlizOptions(OVALE)
	AceConfigDialog:AddToBlizOptions(OVALE .. " Profiles", "Profiles", OVALE)
end

function OvaleOptions:OnEnable()
	self:HandleProfileChanges()
end

function OvaleOptions:RegisterOptions(addon)
	tinsert(self_register, addon)
end

function OvaleOptions:UpgradeSavedVariables()
	local profile = Ovale.db.profile

	-- Merge two options that had the same meaning.
	if profile.display ~= nil and type(profile.display) == "boolean" then
		profile.apparence.enableIcons = profile.display
		profile.display = nil
	end

	-- The frame position settings changed from left/top to offsetX/offsetY.
	if profile.left or profile.top then
		profile.left = nil
		profile.top = nil
		Ovale:OneTimeMessage("The Ovale icon frames position has been reset.")
	end

	-- Invoke module-specific upgrade for Saved Variables.
	for _, addon in ipairs(self_register) do
		if addon.UpgradeSavedVariables then
			addon:UpgradeSavedVariables()
		end
	end

	-- Re-register defaults so that any tables created during the upgrade are "populated"
	-- by the default database automatically.
	Ovale.db:RegisterDefaults(self.defaultDB)
end

function OvaleOptions:HandleProfileChanges()
	self:SendMessage("Ovale_ProfileChanged")
	self:SendMessage("Ovale_ScriptChanged")
end

function OvaleOptions:ToggleConfig()
	if Ovale.db.profile.standaloneOptions then
		local appName = OVALE
		if AceConfigDialog.OpenFrames[appName] then
			AceConfigDialog:Close(appName)
		else
			AceConfigDialog:Open(appName)
		end
	else
		API_InterfaceOptionsFrame_OpenToCategory(OVALE)
		-- Invoke the same call twice in a row to workaround a bug with Interface panel
		-- opening without selecting the right category.
		API_InterfaceOptionsFrame_OpenToCategory(OVALE)
	end
end
--</public-static-methods>

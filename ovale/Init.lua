--[[--------------------------------------------------------------------
    Copyright (C) 2009, 2010, 2011, 2012 Sidoine De Wispelaere.
    Copyright (C) 2012, 2013, 2014 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]----------------------------------------------------------------------

local OVALE, Ovale = ...
Ovale = LibStub("AceAddon-3.0"):NewAddon(Ovale, OVALE, "AceEvent-3.0")



--<private-static-properties>
local AceGUI = LibStub("AceGUI-3.0")

-- Localized strings table.
local L = nil

local assert = assert
local format = string.format
local ipairs = ipairs
local next = next
local pairs = pairs
local select = select
local strfind = string.find
local strjoin = strjoin
local strlen = string.len
local strmatch = string.match
local tostring = tostring
local tostringall = tostringall		-- FrameXML/RestrictedInfrastructure
local type = type
local unpack = unpack
local wipe = wipe
local API_GetItemInfo = GetItemInfo
local API_GetTime = GetTime
local API_UnitCanAttack = UnitCanAttack
local API_UnitClass = UnitClass
local API_UnitExists = UnitExists
local API_UnitGUID = UnitGUID
local API_UnitHasVehicleUI = UnitHasVehicleUI
local API_UnitIsDead = UnitIsDead
local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME
local INFINITY = math.huge

local OVALE_VERSION = "@project-version@"
local REPOSITORY_KEYWORD = "@" .. "project-version" .. "@"

-- Table of strings to display once per session.
local self_oneTimeMessage = {}

-- List of the last MAX_REFRESH_INTERVALS elapsed times between refreshes.
local MAX_REFRESH_INTERVALS = 500
local self_refreshIntervals = {}
local self_refreshIndex = 1
--</private-static-properties>

--<public-static-properties>
-- Localization string table.
Ovale.L = nil
-- Player's class.
Ovale.playerClass = select(2, API_UnitClass("player"))
-- Player's GUID (initialized after PLAYER_LOGIN event).
Ovale.playerGUID = nil
-- AceDB-3.0 database to handle SavedVariables (managed by OvaleOptions).
Ovale.db = nil
--the frame with the icons
Ovale.frame = nil
-- Checkbox and dropdown definitions from evaluating the script.
Ovale.checkBox = {}
Ovale.list = {}
-- Checkbox and dropdown GUI controls.
Ovale.checkBoxWidget = {}
Ovale.listWidget = {}
-- List of units that require refreshing the best action.
Ovale.refreshNeeded = {}
-- Prefix of messages received via CHAT_MSG_ADDON for Ovale.
Ovale.MSG_PREFIX = OVALE
--</public-static-properties>

function Ovale:OnEnable()
	self.playerGUID = API_UnitGUID("player")
end

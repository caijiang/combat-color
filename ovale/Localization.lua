--[[--------------------------------------------------------------------
    Copyright (C) 2014 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

local OVALE, Ovale = ...

local rawset = rawset
local setmetatable = setmetatable
local tostring = tostring

local L = nil
do
	-- Default value is the key itself.
	local MT = {
		__index = function(self, key)
			local value = tostring(key)
			rawset(self, key, value)
			return value
		end,
	}
	L = setmetatable({}, MT)
	Ovale.L = L
end

-- THE REST OF THIS FILE IS AUTOMATICALLY GENERATED.
-- ANY CHANGES MADE BELOW THIS POINT WILL BE LOST.
-- UPDATE TRANSLATIONS AT:
--     http://wow.curseforge.com/addons/ovale/localization

local locale = GetLocale()

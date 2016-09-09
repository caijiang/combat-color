-- CCLibTalent.lua

--[[
一个职业的基本特性
TalentSpellDescs
方法
Work 
]]

local addonName, T = ...;
local D = T.jcc;

local MAJOR,MINOR = "CCTalent-1.0", 1

local CCTalent, oldminor = LibStub:NewLibrary(MAJOR, MINOR)

if not CCTalent then return end -- No upgrade needed

CCTalent.embeds = CCTalent.embeds or {} -- table containing objects AceConsole is embedded in.


function CCTalent:SpellDescs()
	return self.TalentSpellDescs;
end


--- embedding and embed handling

local mixins = {
	"SpellDescs",
	"onCCLoaded",
} 

-- Embeds CCTalent into the target object making the functions from the mixins list available on target:..
-- @param target target object to embed AceBucket in
function CCTalent:Embed( target )
	for k, v in pairs( mixins ) do
		target[v] = self[v]
	end
	self.embeds[target] = true
	return target
end

function CCTalent:OnEmbedEnable( target )
end

function CCTalent:OnEmbedDisable( target )
end

for addon in pairs(CCTalent.embeds) do
	CCTalent:Embed(addon)
end


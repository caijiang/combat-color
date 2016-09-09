-- CCTest.lua

local addonName, T = ...;
local D = T.jcc;

local P = D:NewModule("TEST","AceEvent-3.0", "AceHook-3.0");

function P:OnEnable()
	print("Loaded TEST Module");
	P.MySpellDescs = {};
	for i=1,D.numbers_of_buttons do
		P.MySpellDescs["slot"..i] = {slot=i,marco="/script print(\"键位测试"..i.."通过\")"};
	end
end

function P:OnDisable()
	print("Unloaded TEST Module");
	P.MySpellDescs = nil;
end

function P:Match()
	D:Debug("match me?");
	return true;
end

function P:SpellDescs()
	return P.MySpellDescs;
end

local count = 0;
local floor = math.floor;

function P:Work(pvp)
	CombatColorRestAllFlag();
	--大约 0.5秒 输出一个
	local chushu = 0.50/D.WorkRate;
	count = count+1;

	local c = floor(count/chushu);
	if c > D.numbers_of_buttons then
		count = 0;
		return;
	end

	if c < 1 then
		return;
	end
	print("开始测试键位"..c);
	CCFlagSpell("slot"..c);
end
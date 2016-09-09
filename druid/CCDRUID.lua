-- CCDRUID.lua

local addonName, T = ...;
local D = T.jcc;

local _,clzz = UnitClass("player");
if clzz~="DRUID" then return;end

-- GetShapeshiftForm  
--[[
0 humanoid 
1 = Bear/Dire Bear Form  
2 = Aquatic Form 水下 
3 = Cat Form 
4 = Travel Form 
5 = Moonkin/Tree Form (Unless feral. If no moonkin/tree form present, (swift) flight form is form 5)
6 = Flight Form
]]

local P = D:NewModule("DRUID", "AceEvent-3.0", "AceHook-3.0","CCClass-1.0");
D.DRUID = P;

local mouseovertargetfocus = "/cast [@mouseover,help,nodead][@target,help,nodead][@focus,help,nodead]%s";

function P:BreakingSpell()
	local form = GetShapeshiftForm();
	--[[if form==1 then
		return "迎头痛击(熊形态)";
	elseif form==3 then
		return "迎头痛击(猎豹形态)";
	end]]
	return "迎头痛击";
end

--[[function P:TestRangeHitSpell()
	local form = GetShapeshiftForm();
	if form==1 then
		return "重殴";
	elseif form==3 then
		return "爪击";
	end
	return "爪击";
end]]

P.testRangeHitSpell = "裂伤";
P.testGCDSpell = "愤怒";
P.ClassSpellDescs = {
	["愤怒"] = 1,
	["月火术"] = 2,
	["回春术"] = 3,
	["凶猛撕咬"] = 4,
	["斜掠"] = 5,
	--["裂伤"] = 6,-- cd in beaar
	["裂伤"] = {slot=6,havecd=true},
	["重殴"] = {slot=7,havecd=true},
	["横扫"] = 8,
	["治疗之触"] = 9,
	["精灵之火"] = 10,
	["割伤"] = {slot=11,havecd=true},
	["树皮术"] = {slot=12,havecd=true},
	["毁灭"] = 13,
	["激活"] = {slot=14,havecd=true},
	["乌索克之力"] = {slot=15,havecd=true},
	["割碎"] = 16,--cat终极技

--[[
	["裂伤(熊形态)"] = 16,
	["裂伤(猎豹形态)"] = 17,
	["横扫(猎豹形态)"] = 37,
	["横扫(熊形态)"] = {slot=22,havecd=true},
	["迎头痛击(熊形态)"] = {slot=23,havecd=true},
	["迎头痛击(猎豹形态)"] = {slot=24,havecd=true},
	["精灵之火（野性）"] = {slot=31,havecd=true},
]]
};


function P:matchGCD(time)
	return time==1;
end

function P:AllowWork(...)
	if P.TalentType==4 then	return true;end

	if((not InCombat)or(not WA_NeedAttack()))then return end

	if(UnitIsBeFear("target") or UnitIsNotAbleAttack("target") or UnitIsBeOutControl("target"))then
		return;
	end

	if(CC_TargetisWudi())then
		jcmessage("换目标");
		return;
	end

	if(CC_Raid_B())then return end

	if(CCWA_Check_PreToCasts())then return end

	if(not CC_InRange() and (P.TalentType==2 or P.TalentType==3) )then
		--不在范围 就暂时不管啦
		return;
	end

	return true;
end


-- CCPALADIN.lua

local addonName, T = ...;
local D = T.jcc;

local _,clzz = UnitClass("player");
if clzz~="PALADIN" then return;end

local P = D:NewModule("PALADIN", "AceEvent-3.0", "AceHook-3.0","CCClass-1.0");
D.PALADIN = P;

local mouseovertargetfocus = "/cast [@mouseover,help,nodead][@target,help,nodead][@focus,help,nodead]%s";
P.breakingSpell = "责难";
P.testRangeHitSpell = "十字军打击";
P.testGCDSpell = "正义圣印";

--[[
	["奉献"] = {slot=5,havecd=true},
	["驱邪术"] = 6,
	["神圣愤怒"] = {slot=7,havecd=true},
	["惩戒光环"] = 8,--必须确保开启惩戒
	["虔诚光环"] = 26,
	["专注光环"] = 27,
	["抗性光环"] = 28,
	["异端裁决"] = 14,
	["正义防御"] = {slot=21,havecd=true},
]]

-- 保护 自由 拯救 牺牲
P.ClassSpellDescs = {
	["审判"] = {slot=1,havecd=true},
	["愤怒之锤"] = {slot=2,havecd=true},
	["十字军打击"] = {slot=3,havecd=true},
	["清算"] = {slot=4,havecd=true},
	["真理圣印"] = 5,
	["清洁术"] = {slot=6,marco=mouseovertargetfocus,havecd=true},
	["正义圣印"] = 7,
	["虔诚光环"] = {slot=8,havecd=true},
	["复仇之怒"] = {slot=9,havecd=true},
	["盲目之光"] = {slot=10,havecd=true},
	["圣疗术"] = {slot=11,havecd=true,marco="/stopcasting\n"..mouseovertargetfocus},
	["圣佑术"] = {slot=12,havecd=true},
	["荣耀圣令"] = {slot=13,marco=mouseovertargetfocus},
	["责难"] = {slot=14,havecd=true},
	["制裁之锤"] = {slot=15,havecd=true},
	["圣盾术"] = {slot=16,havecd=true},
	["圣光闪现"] = {slot=17,marco=mouseovertargetfocus},
	["i荣耀圣令"] = {slot=18,havecd=true},
	["洞察圣印"] = 19,

	["永恒之火"] = {slot=21,marco=mouseovertargetfocus},
	["圣洁护盾"] = {slot=21,marco=mouseovertargetfocus},
	["神圣复仇者"] = {slot=22,havecd=true},
	["神圣棱镜"] = {slot=23,havecd=true},
	["圣光之锤"] = {slot=23,havecd=true},
	["处决宣判"] = {slot=23,havecd=true},
	["责难M"] = {slot=24,havecd=true,marco="/cast [@mouseover,harm,nodead]责难"},	
};

function P:matchGCD(time)
	return time==1.5;
end

function P:useShengling()
	if WA_CheckSpellUsable("永恒之火") then
		CCFlagSpell("永恒之火");
		return true;
	end
	if WA_CheckSpellUsable("荣耀圣令") then
		CCFlagSpell("荣耀圣令");
		return true;
	end
	return false;
end

function P:AllowWork(...)
	if P.TalentType==1 then	return true;end

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

	if(not CC_InRange())then
		--不在范围 就暂时不管啦
		return;
	end

	return true;
end

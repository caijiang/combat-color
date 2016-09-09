-- CCDRUIDFeral.lua
--暴击等级 > 急速等级 > 命中/精准等级(7.5%命中/15%精准未满前) > 精通等级 > 躲闪等级
--不要使用任何带有敏捷的宝石；红孔精准耐力，黄孔暴击耐力，蓝孔纯耐力即可。
local addonName, TT = ...;
local D = TT.jcc;

local _,clzz = UnitClass("player");
if clzz~="DRUID" then return;end

local Q = D.DRUID;

local T = Q:NewModule("DRUID3", "AceEvent-3.0", "AceHook-3.0","CCTalent-1.0");


T.TalentSpellDescs = {
	["野蛮防御"] = {slot=21,havecd=true},
	["熊抱"] = {slot=22,havecd=true},
	["痛击"] = 23,
	["狂暴"] = {slot=24,havecd=true},
	["毁灭"] = {slot=25,havecd=true},
	["生存本能"] = {slot=26,havecd=true},
	["迎头痛击"] = {slot=27,havecd=true},
	["激怒"] = {slot=28,havecd=true},
	["割裂"] = {slot=29,havecd=true},--终极技 cat
	["迎头痛击M"] = {slot=30,havecd=true,marco="/cast [@mouseover,harm,nodead]迎头痛击"},
};

local function Threat_Not_Stable(threatstate)
	return threatstate ~= 3;
end

-- 拉怪
local function Pull_Mons(threatstate)
	if((not UnitIsPlayer("target")) and WA_NeedAttack() and UnitExists("targettarget") and UnitName("targettarget")~=UnitName("player")) then
	else
		return false;
	end
	if(not CCPullApprolved or not Threat_Not_Stable(threatstate))then
		return false;
	end

	--[[if(WA_CheckSpellUsable("低吼"))then
		CCFlagSpell("低吼");
		return false;
	end]]
	return false;
end

-- 自我保护
local function Care_Tank()
end


local function tank()
	local tstate = cc_updateThreats(true);

	if(Care_Tank()) then return end;

	if(Pull_Mons(tstate)) then return end;


	local castAllICan = CC_WA_CH or (GetNumSubgroupMembers() == 0 and GetNumGroupMembers() == 0);
	local power = UnitPower("player");
	local healthrate = UnitHealth("target")/UnitHealthMax("target")

	if power>85 and WA_CheckSpellUsableOn("重殴") then
		CCFlagSpell("重殴");
		--return;
	end

	if healthrate> 0.01 and WA_CheckDebuff("虚弱打击",2) and WA_CheckSpellUsable("痛击") then
		CCFlagSpell("痛击");
		return;
	end
	--裂伤 有cd啊
	if WA_CheckSpellUsable("裂伤") then
		CCFlagSpell("裂伤");
		return;
	end
	if CCFightType==2 and WA_CheckSpellUsable("横扫") then
		CCFlagSpell("横扫");
		return;
	end

	if WA_CheckDebuff("破甲",5,3) and WA_CheckSpellUsableOn("精灵之火") then
		CCFlagSpell("精灵之火");
		return;
	end
	--痛击，如果痛击流血效果不存在或者持续时间小于2秒(16秒)；
	if healthrate> 0.01 and WA_CheckDebuff("痛击",2,nil,true) and WA_CheckSpellUsable("痛击") then
		CCFlagSpell("痛击");
		return;
	end

	if WA_CheckSpellUsableOn("割伤") then
		CCFlagSpell("割伤");
		return;
	end

end

local function dps()
	local power = UnitPower("player");
	local healthrate = UnitHealth("target")/UnitHealthMax("target")
	local p = GetComboPoints("player","target");

	-- 能量恢复 的速度  冲动 100%
	local prps = 12.5;
	-- 影袭 39
	local timetotg = (65-power)/prps;

	if p>0 and not CC_reckon_target_liveon(timetotg+2) then
		if WA_CheckSpellUsableOn("凶猛撕咬") then
			CCFlagSpell("凶猛撕咬");
		end
		return;
	end

	if CCFightType==2 and WA_CheckSpellUsable("横扫") then
		CCFlagSpell("横扫");
		return;
	end

	if healthrate<0.25 and not WA_CheckDebuff("割裂",0,0,true) then
		if (WA_CheckDebuff("割裂",4,nil,true) or p==5) and WA_CheckSpellUsableOn("凶猛撕咬") then
			CCFlagSpell("凶猛撕咬");
			return;
		end
	end

	-- 保持目标的5星 割裂
	if WA_CheckDebuff("割裂",2,nil,true) and WA_CheckSpellUsable("割裂") and p==5 then
		CCFlagSpell("割裂");
		return;
	end

	if WA_CheckDebuff("斜掠",3,nil,true) and WA_CheckSpellUsable("斜掠") then
		CCFlagSpell("斜掠");
		return;
	end

	--当你有5个连击点数，撕扯(国服:割裂)持续时间还有12秒或者更少，同时你的咆哮和撕扯(国服:割裂)持续时间相隔3秒或者更少，请使用凶蛮咆哮。

	if p==5 and not WA_CheckBuff("凶蛮咆哮",8) and not WA_CheckDebuff("割裂",8,nil,true) and WA_CheckSpellUsableOn("凶猛撕咬") then
		CCFlagSpell("凶猛撕咬");
		return;
	end

	--如果你有装备撕碎雕文，同时你的撕碎还能够延长撕扯(国服:割裂)持续时间，请使用撕碎

	--当你的目标少于5个连击点数，同时你的撕扯(国服:割裂)和扫击(国服:斜掠)持续时间还足够长，或者你能够获取多于70点能量，或者处于狂暴期间有多于35点能量，亦或者你的猛虎之怒的冷却时间少于3秒，请使用撕碎来攒连击点数
	--如果你没有连击点数，同时你的咆哮和扫击(国服:斜掠)持续时间少于2秒，请使用撕碎
	--如果目标身上没有撕扯(国服:割裂)效果，请使用撕碎
	--如果你的能量在接下来的一秒就要溢出，请使用撕碎
	if p<5 and WA_CheckSpellUsableOn("毁灭") then
		CCFlagSpell("毁灭");
		return;
	end

	if p<5 and WA_CheckSpellUsableOn("裂伤") then
		CCFlagSpell("裂伤");
		return;
	end

	if p==5 and WA_CheckSpellUsableOn("凶猛撕咬") then
		CCFlagSpell("凶猛撕咬");
		return;
	end
end

function T:Work()
	local form = GetShapeshiftForm();
	--D:Error("当前形态",form);
	if form==1 then
		tank();
	else
		dps();
	end
end

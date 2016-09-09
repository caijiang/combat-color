-- CCHunterMM.lua
-- 456 都选1
-- 瞄准射击雕纹 逃脱雕纹 威慑雕纹 动物盟约雕纹
-- 无路可逃雕纹

local addonName, TT = ...;
local D = TT.jcc;

local _,clzz = UnitClass("player");
if clzz~="HUNTER" then return;end

local Q = D.HUNTER;

local F = Q:NewModule("HUNTER2", "AceEvent-3.0", "AceHook-3.0","CCTalent-1.0");

F.TalentSpellDescs = {	
	["瞄准射击"] = 31,
	["急速射击"] = {slot=32,havecd=true},
	["奇美拉射击"] = {slot=33,havecd=true}, 	
	["夺命射击"] = {slot=34,havecd=true}, 
};

--射击的AOE主要是围绕持续时间5s的[狂轰滥炸]技能展开，我们要保证在AOE时[狂轰滥炸]的debuff不断，那么每4-5s要施放一次多重射击，根据集中值关系
local function aoe()
	if WA_CheckSpellUsable("奇美拉射击") then
		CCFlagSpell("奇美拉射击");
		return;
	end
	
	if WA_CheckSpellUsable("夺命射击") then
		CCFlagSpell("夺命射击");
		return;
	end
	
	if WA_CheckSpellUsable("弹幕射击") then
		CCFlagSpell("弹幕射击");
		return true;
	end
	
	if not CC_Raid_ShouldDMGWithoutKO() and WA_CheckSpellUsable("飞刃") then
		CCFlagSpell("飞刃");
		return true;
	end
	
	if not CC_Raid_ShouldDMGWithoutKO() and WA_CheckSpellUsable("强风射击") then
		CCFlagSpell("强风射击");
		return true;
	end
	
	-- 陷阱
	
	if not CC_Raid_ShouldDMGWithoutKO() and WA_CheckSpellUsable("夺命黑鸦") then
		CCFlagSpell("夺命黑鸦");
		return true;
	end
	
	if WA_CheckSpellUsable("多重射击")then
		CCFlagSpell("多重射击");
		return;
	end
	
	Q:DoWengu();	
end

function F:Work(pvp,inFarRange,inNearRange)

	local targetpct = UnitHealth("target")/UnitHealthMax("target")
	local power = UnitPower("player");
	
	if D:CastReadable() and Q.ToRush and (not WA_CheckBuff("急速射击") or D:IsSXing() ) then
		CCWA_RacePink();
	elseif D:CastReadable() and Q.ToRush then
		CCWA_RacePink(false,Q.checktouseitem);
	end
	
	if CCFightType==2 then
		return aoe();
	end
	
	local jsEnabled = not WA_CheckBuff("急速射击");
	local jqmz = targetpct>=0.8 or jsEnabled;
	
	if WA_CheckSpellUsable("夺命射击") then
		CCFlagSpell("夺命射击");
		return;
	end
	
	if WA_CheckSpellUsable("奇美拉射击") then
		CCFlagSpell("奇美拉射击");
		return;
	end
		
	if not jqmz and not CC_Raid_ShouldDMGWithoutKO() and WA_CheckSpellUsable("夺命黑鸦") then
		CCFlagSpell("夺命黑鸦");
		return true;
	end
	
	if not jqmz and WA_CheckSpellUsable("弹幕射击") then
		CCFlagSpell("弹幕射击");
		return true;
	end
	
	if not jqmz and not CC_Raid_ShouldDMGWithoutKO() and WA_CheckSpellUsable("飞刃") then
		CCFlagSpell("飞刃");
		return true;
	end
	
	if not jqmz and not CC_Raid_ShouldDMGWithoutKO() and WA_CheckSpellUsable("强风射击") then
		CCFlagSpell("强风射击");
		return true;
	end
	
	--群兽奔腾
	
	if not CC_Raid_ShouldDMGWithoutKO() and WA_CheckSpellUsable("夺命黑鸦") then
		CCFlagSpell("夺命黑鸦");
		return true;
	end
	
	if WA_CheckSpellUsable("瞄准射击") then
		CCFlagSpell("瞄准射击");
		return;
	end
	
	Q:DoWengu();
end
-- CCHunterMM.lua
-- 456 都选1
-- 瞄准射击雕纹 逃脱雕纹 威慑雕纹 动物盟约雕纹
-- 无路可逃雕纹

local addonName, TT = ...;
local D = TT.jcc;
local OvaleSpellBook = TT.OvaleSpellBook;

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

-- 精确瞄准
local function aimd()
	if WA_CheckSpellUsable("飞刃") and D:hasEnemies(3) then
		CCFlagSpell("飞刃");
		return true;
	end

	if WA_CheckSpellUsable("强风射击") and Q:FocusSafe("强风射击") then
		CCFlagSpell("强风射击");
		return true;
	end

	if WA_CheckSpellUsable("弹幕射击") and D:hasEnemies(2) then
		CCFlagSpell("弹幕射击");
		return true;
	end

	if WA_CheckSpellUsable("瞄准射击") then
		CCFlagSpell("瞄准射击");
		return true;
	end

	if D:CastReadable("专注射击") and WA_CheckSpellUsable("专注射击") and Q:FocusSafe("专注射击",50) then
		CCFlagSpell("专注射击");
		return true;
	end

	if WA_CheckSpellUsable("稳固射击") then
		CCFlagSpell("稳固射击");
		return true;
	end

end

function F:Work(pvp,inFarRange,inNearRange)

	local targetpct = UnitHealth("target")/UnitHealthMax("target")
	local power = UnitPower("player");

	if D:CastReadable() and Q.ToRush and (not WA_CheckBuff("急速射击") or D:IsSXing() ) then
		CCWA_RacePink();
	elseif D:CastReadable() and Q.ToRush then
		CCWA_RacePink(false,Q.checktouseitem);
	end

	if Q.GCDLeftTime>D.MaxDelayS then
		return;
	end

--射击的AOE主要是围绕持续时间5s的[狂轰滥炸]技能展开，我们要保证在AOE时[狂轰滥炸]的debuff不断，那么每4-5s要施放一次多重射击，根据集中值关
	if CCFightType==2 and WA_CheckSpellUsable("多重射击")
	and not WA_CheckBuff("狂轰滥炸") and WA_CheckBuff("狂轰滥炸",1) then
		CCFlagSpell("多重射击");
		return;
	end

	if WA_CheckSpellUsable("奇美拉射击") then
		CCFlagSpell("奇美拉射击");
		return;
	end

	if WA_CheckSpellUsable("夺命射击") then
		CCFlagSpell("夺命射击");
		return;
	end

	-- 急速射击
	if WA_CheckSpellUsable("群兽奔腾") and Q.ToRush and (not WA_CheckBuff("急速射击") or D:IsSXing() ) then
		CCFlagSpell("群兽奔腾");
		return;
	end

	local jsEnabled = not WA_CheckBuff("急速射击");
	local jqmz = targetpct>=0.8 or jsEnabled;

	if jqmz then
		if aimd() then return; end
	end

	-- 爆炸陷阱
	if not CC_Raid_ShouldDMGWithoutKO() and WA_CheckSpellUsable("夺命黑鸦") then
		CCFlagSpell("夺命黑鸦");
		return;
	end

	if WA_CheckSpellUsable("凶暴野兽") and Q:FocusSafe("凶暴野兽",Q:FocusCastingRegen("瞄准射击")) then
		CCFlagSpell("凶暴野兽");
		return;
	end

	if WA_CheckSpellUsable("飞刃") then
		CCFlagSpell("飞刃");
		return;
	end

	if WA_CheckSpellUsable("强风射击") and Q:FocusSafe("强风射击") then
		CCFlagSpell("强风射击");
		return;
	end

	if WA_CheckSpellUsable("弹幕射击") then
		CCFlagSpell("弹幕射击");
		return;
	end

	if not WA_CheckSpellUsable("急速射击") then
		if WA_CheckSpellUsable("稳固射击") and Q:JisushejiIsComing("稳固射击",14) then
			CCFlagSpell("稳固射击");
			return;
		end

		if WA_CheckSpellUsable("稳固射击") and Q:JisushejiIsComing("稳固射击",14) then
			CCFlagSpell("稳固射击");
			return;
		end
		if WA_CheckSpellUsable("专注射击") and Q:JisushejiIsComing("稳固射击",50) and power<100 then
			CCFlagSpell("专注射击");
			return;
		end
	end

	-- 稳固集中天赋 产生的稳固集中buf
	if WA_CheckSpellUsable("稳固射击") and not WA_CheckBuff("稳固集中") and Q:FocusSafe("稳固射击",14+Q:FocusCastingRegen("瞄准射击")) then
		CCFlagSpell("稳固射击");
		return;
	end

	-- D:hasEnemies(7)
	if CCFightType==2 and WA_CheckSpellUsable("多重射击") then
		CCFlagSpell("多重射击");
		return;
	end

	-- 专注射击 163485
	if WA_CheckSpellUsable("瞄准射击") and OvaleSpellBook:GetTalentPoints(163485)>0 then
		CCFlagSpell("瞄准射击");
		return;
	end

	if WA_CheckSpellUsable("瞄准射击") and power+Q:FocusCastingRegen("瞄准射击")>=85 then
		CCFlagSpell("瞄准射击");
		return;
	end

	if WA_CheckSpellUsable("瞄准射击") and power+Q:FocusCastingRegen("瞄准射击")>=65
	and not WA_CheckBuff("狩猎刺激") then
		CCFlagSpell("瞄准射击");
		return;
	end

	if D:CastReadable("专注射击") and WA_CheckSpellUsable("专注射击") and Q:FocusSafe("专注射击",40) then
		CCFlagSpell("专注射击");
		return;
	end

	if D:CastReadable("稳固射击") then
		CCFlagSpell("稳固射击");
		return;
	end
end

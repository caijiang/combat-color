-- CCWARRIORTG.lua

local addonName, T = ...;
local D = T.jcc;

local _,clzz = UnitClass("player");
if clzz~="WARRIOR" then return;end

local W = T.jcc.WARRIOR;
local G = W:NewModule("WARRIOR2", "AceEvent-3.0", "AceHook-3.0","CCTalent-1.0");

G.TalentSpellDescs = {
		--英勇之怒？ 没必要
		--["斩杀"] = {slot=25},
		["嗜血"] ={slot=30,havecd=true},
		["狂风打击"] ={slot=31},
		["刺耳怒吼"] = {slot=32,havecd=true},
		["怒击"] = {slot=33},
		["旋风斩"] = {slot=34},
	};

function G:Rush()
end

local function checkrush()
	if W:RushDps() then return true;end

	if WA_CheckSpellUsable("狂暴之怒") and (
	(not WA_CheckBuff("强度激增",10))
	or (not WA_CheckBuff("天神下凡",10))
	or (not WA_CheckBuff("鲁莽",10))
	or (not WA_CheckBuff("浴血奋战",10))
	) and WA_CheckBuff("激怒") and WA_CheckBuff("怒击！") then
		CCFlagSpell("狂暴之怒");
	end
end

local function aoe()
	local powergap = UnitPowerMax("player")-UnitPower("player");
	local timetosx = WA_CooldownLeft("嗜血");
	local inZS = UnitHealth("target")/UnitHealthMax("target")<=0.2;
	local power = UnitPower("player");

	if CCAutoRush and WA_CheckSpellUsable("浴血奋战") then
		CCFlagSpell("浴血奋战");
	end

	if W:SpellPohuaizhe() then return;end

	if WA_CheckSpellUsable("怒击") and not WA_CheckBuff("激怒") and not WA_CheckBuff("绞肉机",0,3) then
		CCFlagSpell("怒击");
		return;
	end

	if WA_CheckSpellUsable("嗜血") and (WA_CheckBuff("激怒") or power<50 or WA_CheckBuff("怒击") ) then
		CCFlagSpell("嗜血");
		return;
	end

	if WA_CheckSpellUsable("怒击") and not WA_CheckBuff("绞肉机",0,3) then
		CCFlagSpell("怒击");
		return;
	end

	-- if not (GetSpellInfo("浴血奋战") and WA_CheckBuff("浴血奋战")) and WA_CheckSpellUsable("剑刃风暴") then
	-- 	CCFlagSpell("剑刃风暴");
	-- 	return;
	-- end

	if WA_CheckSpellUsable("旋风斩") then
		CCFlagSpell("旋风斩");
		return;
	end

	if W:SuddenExecute() then return;end

	if W:JulongNuhou() then return;end

	if WA_CheckSpellUsable("嗜血") then
		CCFlagSpell("嗜血");
		return;
	end

	if not WA_CheckBuff("血脉贲张") and WA_CheckSpellUsable("狂风打击") then
		CCFlagSpell("狂风打击");
		return;
	end

	return;
end

local function two_targets()
	local powergap = UnitPowerMax("player")-UnitPower("player");
	local timetosx = WA_CooldownLeft("嗜血");
	local inZS = UnitHealth("target")/UnitHealthMax("target")<=0.2;
	local power = UnitPower("player");

	-- 浴血再说

	if W:SpellPohuaizhe() then return;end

	if W:JulongNuhou() then return;end

	-- if not (GetSpellInfo("浴血奋战") and WA_CheckBuff("浴血奋战")) and WA_CheckSpellUsable("剑刃风暴") then
	-- 	CCFlagSpell("剑刃风暴");
	-- 	return;
	-- end

	if WA_CheckSpellUsable("嗜血") and (WA_CheckBuff("激怒") or power<40 or WA_CheckBuff("怒击") ) then
		CCFlagSpell("嗜血");
		return;
	end

	-- 斩杀
	if W:SuddenExecute() then return;end
	if WA_CheckSpellUsable("斩杀") and not WA_CheckBuff("激怒") then
		CCFlagSpell("斩杀");
		return;
	end

	if WA_CheckSpellUsable("怒击") and (not WA_CheckBuff("绞肉机") or inZS) then
		CCFlagSpell("怒击");
		return;
	end

	if WA_CheckSpellUsable("旋风斩") and WA_CheckBuff("绞肉机") and not inZS then
		CCFlagSpell("旋风斩");
		return;
	end

	if not WA_CheckBuff("血脉贲张") and WA_CheckSpellUsable("狂风打击") then
		CCFlagSpell("狂风打击");
		return;
	end

	if WA_CheckSpellUsable("嗜血") then
		CCFlagSpell("嗜血");
		return;
	end

	if WA_CheckSpellUsable("旋风斩") then
		CCFlagSpell("旋风斩");
		return;
	end
end

local function single_target()
	local powergap = UnitPowerMax("player")-UnitPower("player");
	local timetosx = WA_CooldownLeft("嗜血");
	local inZS = UnitHealth("target")/UnitHealthMax("target")<=0.2;
	local power = UnitPower("player");

	if WA_CheckSpellUsable("狂风打击") and not inZS and powergap<20 then
		CCFlagSpell("狂风打击");
		return;
	end

	if WA_CheckSpellUsable("乘胜追击") and UnitHealth("player")/UnitHealthMax("player")<=0.65 then
		CCFlagSpell("乘胜追击");
		return;
	end

	if WA_CheckSpellUsable("嗜血") and ((powergap>40 and not W:isWujinkewangEnabled()) or WA_CheckBuff("激怒") or WA_CheckBuff("怒击",0,2) ) then
		CCFlagSpell("嗜血");
		return;
	end

	if W:SpellPohuaizhe() then return;end

	if W:SuddenExecute() then return;end

	if WA_CheckSpellUsable("破城者") then
		CCFlagSpell("破城者");
		return;
	end

	if W:Fengbao() then return;end

	if not WA_CheckBuff("血脉贲张") and WA_CheckSpellUsable("狂风打击") then
		CCFlagSpell("狂风打击");
		return;
	end

	if WA_CheckSpellUsable("斩杀") and not WA_CheckBuff("激怒") then
		CCFlagSpell("斩杀");
		return;
	end

	if W:JulongNuhou() then return;end

	if WA_CheckSpellUsable("怒击") then
		CCFlagSpell("怒击");
		return;
	end

	if not WA_CheckSpellUsable("嗜血") and timetosx<0.5 and power<50 then
		return;
	end

	if WA_CheckSpellUsable("狂风打击") and not WA_CheckBuff("激怒") and not inZS then
		CCFlagSpell("狂风打击");
		return;
	end

	if WA_CheckSpellUsable("嗜血") then
		CCFlagSpell("嗜血");
		return;
	end

	if WA_CheckSpellUsable("碎裂投掷") then
		CCFlagSpell("碎裂投掷");
		return;
	end
--[[	if WA_CheckSpellUsable("英勇投掷") and not UnitIsPlayer("target") then
		CCFlagSpell("英勇投掷");
		return;
	end]]
	if WA_CheckSpellUsable("乘胜追击") then
		CCFlagSpell("乘胜追击");
		return;
	end

	--无所事事
	D:Debug("无所事事");
end

function G:Work(pvp)
	if(GetShapeshiftForm()==2)then
		jcmessage("确定要防御姿态输出么？？");
	end

	--,if=buff.skull_banner.down&(((cooldown.colossus_smash.remains<2|debuff.colossus_smash.remains>=5)&target.time_to_die>192&buff.cooldown_reduction.up)|buff.recklessness.up)

	W:RushDps();

	local powergap = UnitPowerMax("player")-UnitPower("player");
	local power = -UnitPower("player");
	local timetosx = WA_CooldownLeft("嗜血");
	-- 血脉贲张 减少怒气消耗 狂风打击

	local inZS = UnitHealth("target")/UnitHealthMax("target")<=0.2;

	local myhp = UnitHealth("player")/UnitHealthMax("player");

	-- 一个崭新的思路 获取所有可用的技能 然后计算哪个技能的收益是最大的 而Rush则应该手控

	if CCFightType==1 and not D.FightHSMode then
		if CCAutoRush and WA_CheckSpellUsable("浴血奋战") and (not CC_reckon_target_liveon(20) ) then
			CCFlagSpell("浴血奋战");
			return true;
		end
		if WA_CheckSpellUsable("狂暴之怒") and  WA_CheckBuff("激怒",1) and timetosx>1 then
			CCFlagSpell("狂暴之怒");
		end
		if W.GCDLeftTime>D.MaxDelayS then
			return;
		end
		return single_target();
	elseif CCFightType==1 and D.FightHSMode then
		--if=enabled&((!talent.bladestorm.enabled&(cooldown.colossus_smash.remains<2|debuff.colossus_smash.remains>=5|target.time_to_die<=20))|(talent.bladestorm.enabled))
		--if=enabled&(((cooldown.colossus_smash.remains<2|debuff.colossus_smash.remains>=5|target.time_to_die<=20)))

		--if=(talent.bladestorm.enabled&(buff.bloodbath.up|!talent.bloodbath.enabled)&!cooldown.bladestorm.remains&(!talent.storm_bolt.enabled|(talent.storm_bolt.enabled&!debuff.colossus_smash.up)))|(!talent.bladestorm.enabled&buff.enrage.remains<1&cooldown.bloodthirst.remains>1)
		if WA_CheckSpellUsable("狂暴之怒") and  WA_CheckBuff("激怒",1) and timetosx>1 then
			CCFlagSpell("狂暴之怒");
		end
		if W.GCDLeftTime>D.MaxDelayS then
			return;
		end
		return two_targets();
	else
		if CCAutoRush and WA_CheckSpellUsable("浴血奋战") then
			CCFlagSpell("浴血奋战");
			return true;
		end
		--if=(talent.bladestorm.enabled&(buff.bloodbath.up|!talent.bloodbath.enabled)&!cooldown.bladestorm.remains)|(!talent.bladestorm.enabled&buff.enrage.remains<1&cooldown.bloodthirst.remains>1)
		if WA_CheckSpellUsable("狂暴之怒") and  WA_CheckBuff("激怒",1) and timetosx>1 then
			CCFlagSpell("狂暴之怒");
		end
		if W.GCDLeftTime>D.MaxDelayS then
			return;
		end
		return aoe();
	end
end

function G:DynamicShapeshiftForm()
	return false;
end

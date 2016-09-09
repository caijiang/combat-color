-- CCPALADINTank.lua

local addonName, TT = ...;
local D = TT.jcc;

local _,clzz = UnitClass("player");
if clzz~="PALADIN" then return;end

local Q = D.PALADIN;

local T = Q:NewModule("PALADIN2", "AceEvent-3.0", "AceHook-3.0","CCTalent-1.0");

T.TalentSpellDescs = {
	["炽热防御者"] = {slot=31,havecd=true},
	["神圣之盾"] = {slot=32,havecd=true},
	["正义盾击"] = 33,
	["复仇者之盾"] = {slot=34,havecd=true},
	["正义之锤"] = {slot=35,havecd=true,marco=mouseovertargetfocus},
	["神圣守卫"] = {slot=36,havecd=true},
};

local function Threat_Not_Stable(threatstate)
	return threatstate ~= 3;
end

local Last_CF_Time = 0;
local Last_CJ_Time = 0;
-- 拉怪
local function Pull_Mons(threatstate)
	if((not UnitIsPlayer("target")) and WA_NeedAttack() and UnitExists("targettarget") and UnitName("targettarget")~=UnitName("player")) then
	else
		return false;
	end
	if(not CCPullApprolved or not Threat_Not_Stable(threatstate))then
		return false;
	end
	
	if(not WA_CheckDebuff("清算之手"))then return false;end
	if(not WA_CheckDebuff("正义防御"))then return false;end
	
	if(GetTime()-Last_CJ_Time>1.5 and WA_CheckSpellUsable("清算之手"))then
		CCFlagSpell("清算之手");
		Last_CF_Time = GetTime();
		return false;
	end
	if(GetTime()-Last_CF_Time>1.5 and WA_CheckSpellUsable("正义防御"))then
		CCFlagSpell("正义防御");
		Last_CJ_Time = GetTime();
		return false;
	end
	return false;
end

local function DangerHP()
	return UnitHealth("player")/UnitHealthMax("player")<0.6;
end

-- 检查是否已使用这些技能 或者 正在使用这些技能
local function CC_using_spells(spells)
	for _i,spellName in ipairs(spells) do
		if(not WA_CheckBuff(spellName))then
			return true;
		end
		--刚刚按下去
	end
	return false;
end

-- 使用第一个可使用的技能
local function CC_use_spells_first(spells)
	for _i,spellName in ipairs(spells) do
		if(WA_CheckSpellUsable(spellName))then
			CCFlagSpell(spellName);
			return true;
		end
	end
	return false;
end

-- 自我保护
local function Care_Tank()	
	if(DangerHP() and UnitPower("player",SPELL_POWER_HOLY_POWER)==3  and WA_CheckSpellUsable("荣耀圣令"))then
		CCFlagSpell("i荣耀圣令");
		return true;
	end
	if(CCAutoRush)then
		if(not WA_CheckBuff("圣盾术"))then
			CCAutoRush = false;
			return false;
		end
		local spells;
		if(DangerHP())then
			spells = {"炽热防御者","远古列王守卫","圣佑术","神圣之盾"};
		else
			spells = {"神圣之盾","圣佑术","远古列王守卫","炽热防御者"};
		end
		
		if(CC_using_spells(spells))then
			CCAutoRush = false;
			return false;
		end

		if(CC_use_spells_first(spells))then
			return true;
		end
	end
	return false;
end

function T:Work()

	if(WA_CheckBuff("正义之怒"))then
		jcmessage("请补充一个正义之怒!");
	end

	local tstate = cc_updateThreats(true);

	if(Care_Tank()) then return end;
	
	if(Pull_Mons(tstate)) then return end;
	
	local castAllICan = CC_WA_CH or (GetNumSubgroupMembers() == 0 and GetNumGroupMembers() == 0);

	if(UnitPower("player",SPELL_POWER_HOLY_POWER)==3 and (not WA_CheckBuff("神圣使命")) and WA_CheckSpellUsable("正义盾击"))then
		CCFlagSpell("正义盾击");
		return;
	end

	if(castAllICan and WA_CheckSpellUsable("愤怒之锤"))then
		CCFlagSpell("愤怒之锤");
		return;
	end

	if((castAllICan or Threat_Not_Stable(tstate)) and UnitPower("player",SPELL_POWER_HOLY_POWER)<=1 and (not WA_CheckBuff("神圣使命")) and WA_CheckSpellUsable("正义盾击")  and WA_CheckSpellUsable("神圣恳求"))then
		CCFlagSpell("神圣恳求");
		return;
	end

	if( (Threat_Not_Stable(tstate) or castAllICan or ((not WA_CheckBuff("大十字军")) and UnitPower("player",SPELL_POWER_HOLY_POWER)<3) ) and  WA_CheckSpellUsable("复仇者之盾"))then
		CCFlagSpell("复仇者之盾");
		return;
	end
	
	-- 辩护 需要管么？
	local tocast;
	if(CCFightType==2)then
		tocast = "正义之锤";
	else
		tocast = "十字军打击";
	end

	if(WA_CheckSpellUsable(tocast))then
		CCFlagSpell(tocast);
		return;
	end

	if( (castAllICan or Threat_Not_Stable(tstate) or UnitPower("player")/UnitPowerMax("player")<0.9 or WA_CheckDebuff("正义审判") ) and WA_CheckSpellUsable("审判"))then
		CCFlagSpell("审判");
		return;
	end

	if(WA_CheckSpellUsable("愤怒之锤"))then
		CCFlagSpell("愤怒之锤");
		return;
	end

end



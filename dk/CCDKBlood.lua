-- CCDKBlood.lua

local addonName, TT = ...;
local D = TT.jcc;

local _,clzz = UnitClass("player");
if clzz~="DEATHKNIGHT" then return;end

local Q = D.DEATHKNIGHT;

local T = Q:NewModule("DEATHKNIGHT1", "AceEvent-3.0", "AceHook-3.0","CCTalent-1.0");

T.TalentSpellDescs = {
	["心脏打击"] = 31,
	["白骨之盾"] = {slot=32,havecd=true},
	["符文分流"] = {slot=33,havecd=true},
	["吸血鬼之血"] = {slot=34,havecd=true},
	["符文刃舞"] = {slot=36,havecd=true},
};

local function Threat_Not_Stable(threatstate)
	return threatstate ~= 3;
end

local Last_CF_Time = 0;
local Last_CJ_Time = 0;
-- 拉怪
local function Pull_Mons(threatstate)
	--死亡之握 ? 3秒 
	--黑暗命令
	if((not UnitIsPlayer("target")) and WA_NeedAttack() and UnitExists("targettarget") and UnitName("targettarget")~=UnitName("player")) then
	else
		return false;
	end
	if(not CCPullApprolved or not Threat_Not_Stable(threatstate))then
		return false;
	end
	
	if(not WA_CheckDebuff("黑暗命令"))then return false;end
	if(not WA_CheckDebuff("死亡之握"))then return false;end
	
	if(GetTime()-Last_CJ_Time>1.5 and WA_CheckSpellUsable("黑暗命令"))then
		CCFlagSpell("黑暗命令");
		Last_CF_Time = GetTime();
		return false;
	end
	if(GetTime()-Last_CF_Time>1.5 and WA_CheckSpellUsable("死亡之握"))then
		CCFlagSpell("死亡之握");
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
	
	-- 对自己使用 凋零缠绕
	-- 反魔法护罩 仅针对魔法 所以自己开
	-- 天灾契约 不知道有没有爪牙。。	
	-- 符文分流 D
	-- 吸血鬼之血 D

	-- 冰封之韧 降低所有伤害20% 3m D
	-- 白骨之盾 降低所有伤害20% 1m D
	-- 符文刃舞 降低伤害 1.5m D
	if(CCAutoRush)then
		local spells;
		if(DangerHP())then
			spells = {"冰封之韧","符文刃舞","白骨之盾"};
		else
			spells = {"白骨之盾","符文刃舞","冰封之韧"};
		end
		
		if(CC_using_spells(spells))then
			CCAutoRush = false;
			return false;
		end

		if(CC_use_spells_first(spells))then
			return true;
		end
	end

	if UnitHealth("player") < UnitHealthMax("player") and not WA_CheckBuff("大墓地的意志") and WA_CheckSpellUsable("符文分流") then
		CCFlagSpell("符文分流");
		return true;
	end

	if(DangerHP() and WA_CheckSpellUsable("符文分流"))then
		CCFlagSpell("符文分流");
		return true;
	end

	if(DangerHP() and WA_CheckSpellUsable("吸血鬼之血"))then
		CCFlagSpell("吸血鬼之血");
		return true;
	end
	
	return false;
end

function T:Work()
	if(WA_CheckBuff("鲜血灵气"))then
		CCFlagSpell("鲜血灵气");
		return;
	end

	local tstate = cc_updateThreats(true);

	if(Care_Tank()) then return end;
	
	if(Pull_Mons(tstate)) then return end;
	
	local castAllICan = CC_WA_CH or (GetNumSubgroupMembers() == 0 and GetNumGroupMembers() == 0) or Threat_Not_Stable(tstate);

	local BLOODActives,BLOODCdInfo,CHROMATICActives,CHROMATICCDInfo,FROSTActives,FROSTCDInfo,DEATHActives = Q:TunesInfo();

	if WA_CheckDebuff("血之疫病",2,0,true) and WA_CheckDebuff("冰霜疫病",2,0,true) and WA_CheckSpellUsable("爆发") then
		CCFlagSpell("爆发");
		return;
	end

	if CCFightType==2 and GetTime()-D:LastCasted("传染")>10 and WA_CheckDebuff("血之疫病",-4,0,true) and WA_CheckDebuff("冰霜疫病",-4,0,true) and WA_CheckSpellUsable("传染")  then
		CCFlagSpell("传染");
		return;
	end

	if WA_CheckDebuff("血之疫病",1,0,true) and not WA_CheckSpellUsable("爆发") and WA_CheckSpellUsable("暗影打击") then
		CCFlagSpell("暗影打击");
		return;
	end
	if WA_CheckDebuff("冰霜疫病",1,0,true) and not WA_CheckSpellUsable("爆发") and WA_CheckSpellUsable("冰冷触摸") then
		CCFlagSpell("冰冷触摸");
		return;
	end
	
	--所谓手法就是尽量多的打出 灵界打击 所以
	if WA_CheckSpellUsable("灵界打击") then
		CCFlagSpell("灵界打击");
		return;
	end

	--当你有一枚激活的血符文(就是未进入CD)时，使用活力分流，会使得你已经锁定的一枚死亡符文激活。(此时就会有2枚死亡符文)ps：活力分流激活的是已经锁定的血符文。
	if WA_CheckSpellUsable("活力分流") and BLOODActives==1 and #BLOODCdInfo==1  then
		CCFlagSpell("活力分流");
		return;
	end

	if WA_CheckSpellUsable("心脏打击") and (WA_CheckBuff("利刃屏障",3) or BLOODActives==1) then
		CCFlagSpell("心脏打击");
		return;
	end

	-- 符文打击 什么时候使用？ 鲜血符文 都激活着
	if WA_CheckSpellUsable("符文打击") and (BLOODActives==2 or UnitPower("player")>70 ) then
		CCFlagSpell("符文打击");
		return;
	end

	--都在冷却 那就强化吧
	if castAllICan and WA_CheckSpellUsable("符文武器增效") and UnitPower("player")<70 and  #BLOODCdInfo+#CHROMATICCDInfo+#FROSTCDInfo>5 then
		CCFlagSpell("符文武器增效");
		return;
	end

	if Q:Haojiao() then return end
end

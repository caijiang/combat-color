-- CCDKFrost.lua

local addonName, TT = ...;
local D = TT.jcc;

local _,clzz = UnitClass("player");
if clzz~="DEATHKNIGHT" then return;end

local Q = D.DEATHKNIGHT;

local F = Q:NewModule("DEATHKNIGHT2", "AceEvent-3.0", "AceHook-3.0","CCTalent-1.0");

F.TalentSpellDescs = {
	["冰霜打击"] = 31,
	["冰霜之柱"] = {slot=32,havecd=true},
	["饥饿之寒"] = {slot=33,havecd=true}, 
	["凛风冲击"] = 34,
};


function F:Work()
	local BLOODActives,BLOODCdInfo,CHROMATICActives,CHROMATICCDInfo,FROSTActives,FROSTCDInfo,DEATHActives = Q:TunesInfo();

	if WA_CheckDebuff("血之疫病",2,0,true) and WA_CheckDebuff("冰霜疫病",2,0,true) and WA_CheckSpellUsable("爆发") then
		CCFlagSpell("爆发");
		return;
	end

	if CCFightType==2 and GetTime()-D:LastCasted("传染")>10  and WA_CheckDebuff("冰霜疫病",-3,0,true) and WA_CheckSpellUsable("传染")  then
		CCFlagSpell("传染");
		return;
	end

	if CCFightType==1 and WA_CheckDebuff("冰霜疫病",1,0,true) and WA_CheckSpellUsable("冰冷触摸") then
		CCFlagSpell("冰冷触摸");
		return;
	end

	if CCFightType==1 and WA_CheckSpellUsable("湮没") and (not WA_CheckBuff("杀戮机器") or (CHROMATICActives>=1 and FROSTActives>=1) or (CHROMATICActives==0 and FROSTActives==0) )then
		CCFlagSpell("湮没");
		return;
	end

	if CCFightType==2 and WA_CheckSpellUsable("凛风冲击") and (FROSTActives>=2 or DEATHActives>=2) then
		CCFlagSpell("凛风冲击");
		return;
	end
	
	-- 枯萎凋零/瘟疫打击 当两个邪符文冷却
	if CCFightType==2 and WA_CheckSpellUsable("暗影打击") and CHROMATICActives>=2 then
		CCFlagSpell("暗影打击");
		return;
	end

	if UnitPower("player")>80 and WA_CheckSpellUsable("冰霜打击") then
		CCFlagSpell("冰霜打击");
		return;
	end

	if CCFightType==1 and not WA_CheckBuff("白霜") and WA_CheckSpellUsable("凛风冲击") then
		CCFlagSpell("凛风冲击");
		return;
	end

	if CCFightType==1 and WA_CheckSpellUsable("湮没") then
		CCFlagSpell("湮没");
		return;
	end

	if CCFightType==2 and WA_CheckSpellUsable("凛风冲击")  then
		CCFlagSpell("凛风冲击");
		return;
	end
	
	-- 枯萎凋零/瘟疫打击 当两个邪符文冷却
	if CCFightType==2 and WA_CheckSpellUsable("暗影打击") then
		CCFlagSpell("暗影打击");
		return;
	end

	if WA_CheckSpellUsable("冰霜打击") then
		CCFlagSpell("冰霜打击");
		return;
	end

	if Q:Haojiao() then return end
end

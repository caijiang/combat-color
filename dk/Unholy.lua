-- Unholy.lua

local addonName, TT = ...;

local D = TT.jcc;
local _,clzz = UnitClass("player");
if clzz~="DEATHKNIGHT" then return;end

local Q = D.DEATHKNIGHT;

local F = Q:NewModule("DEATHKNIGHT3", "AceEvent-3.0", "AceHook-3.0","CCTalent-1.0");

F.TalentSpellDescs = {
	["天灾打击"] = 28,
	["脓疮打击"] = 29,
	["黑暗突变"] = 30,
	["灵魂收割"] = 31,
	["召唤石像鬼"] = {slot=32,havecd=true},
};

function F:Work()
--暗影打击 血之疫病
--脓疮打击 补
--冰冷触摸 冰霜疫病
-- 5层 暗影灌注  黑暗突变
-- 末日突降 凋零缠绕
-- 天灾打击
	local BLOODActives,BLOODCdInfo,CHROMATICActives,CHROMATICCDInfo,FROSTActives,FROSTCDInfo,DEATHActives = Q:TunesInfo();
	local power = UnitPower("player");

	if WA_CheckDebuff("血之疫病",1,0,true) and WA_CheckDebuff("冰霜疫病",1,0,true) and WA_CheckSpellUsable("爆发") then
		CCFlagSpell("爆发");
		return;
	end
	if CCFightType==2 and GetTime()-D:LastCasted("传染")>10  and not WA_CheckDebuff("冰霜疫病",3,0,true) and WA_CheckSpellUsable("传染")  then
		CCFlagSpell("传染");
		return;
	end
	
	if WA_CheckDebuff("冰霜疫病",0,0,true) and WA_CheckSpellUsable("冰冷触摸") then
		CCFlagSpell("冰冷触摸");
		return;
	end

	if WA_CheckDebuff("血之疫病",0,0,true) and WA_CheckSpellUsable("暗影打击") then
		CCFlagSpell("暗影打击");
		return;
	end

	D:Debug("突变");

	if (power>70 or not WA_CheckBuff("末日突降")) and WA_CheckSpellUsable("凋零缠绕") then
		CCFlagSpell("凋零缠绕");
		return;
	end

	if WA_CheckDebuff("血之疫病",2,0,true) or WA_CheckDebuff("冰霜疫病",2,0,true) then
		if WA_CheckSpellUsable("脓疮打击") then
			CCFlagSpell("脓疮打击");
		end
		return;
	end

	if WA_CheckSpellUsable("天灾打击") then
		CCFlagSpell("天灾打击");
		return;
	end

	if WA_CheckSpellUsable("脓疮打击") then
		CCFlagSpell("脓疮打击");
		return;
	end

	--[[if not WA_CheckDebuff("血之疫病",2,0,true) and not WA_CheckDebuff("冰霜疫病",2,0,true) and WA_CheckSpellUsable("鲜血打击") then
		CCFlagSpell("鲜血打击");
		return;
	end]]

	if WA_CheckSpellUsable("暗影打击") then
		CCFlagSpell("暗影打击");
		return;
	end

	if WA_CheckSpellUsable("冰冷触摸") then
		CCFlagSpell("冰冷触摸");
		return;
	end

	if WA_CheckSpellUsable("鲜血打击") then
		CCFlagSpell("鲜血打击");
		return;
	end

	if Q:Haojiao() then return end
end

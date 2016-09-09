-- CCMgArcane.lua

local addonName, T = ...;
local D = T.jcc;

local _,clzz = UnitClass("player");
if clzz~="MAGE" then return;end

local S = D.MAGE;
local F = S:NewModule("MAGE1", "AceEvent-3.0", "AceHook-3.0","CCTalent-1.0");

F.TalentSpellDescs = {
	-- ["奥术飞弹"] = {slot=2,havecd=false},
	["奥术弹幕"] = {slot=30,havecd=true},
	["气定神闲"] = {slot=31,havecd=true},
	["奥术强化"] = {slot=32,havecd=true},
	["减速"] = 33,
	["专注魔法"] = 34,
}

function F:Rush()
	if WA_CheckSpellUsable("奥术强化") then
		CCFlagSpell("奥术强化");
		return;
	end
	if WA_CheckSpellUsable("气定神闲") then
		CCFlagSpell("气定神闲");
		return;
	end
end

function F:Work(pvp)

	if WA_CheckBuff("法师护甲") and WA_CheckSpellUsable("法师护甲") then
		CCFlagSpell("法师护甲");
		return;
	end

	local manrpt = UnitPower("player")/UnitPowerMax("player");

	if CCFightType==2 then
		return;
	end

	--自动判定应该处于哪个阶段？
	if CC_Raid_ShouldDMGWithoutKO() and WA_CheckSpellUsableOn("奥术冲击") then
		CCFlagSpell("奥术冲击");
		return;
	end

	if CCAutoRush then
		if manrpt<0.3 then
			CCAutoRush = false;
			return;
		end
		if D:CastReadable() and WA_CheckDebuff("奥术冲击",0,3,true,"player") and WA_CheckSpellUsableOn("奥术冲击") then
			CCFlagSpell("奥术冲击");
			return;
		end
		if S:RushDps() then return end

		if D:CastReadable() and WA_CheckSpellUsableOn("奥术冲击") then
			CCFlagSpell("奥术冲击");
			return;
		end
		return;
	end

--[[	if D:CastReadable() and WA_CheckDebuff("奥术冲击",0,2,true,"player") and WA_CheckSpellUsable("奥术冲击") then
		CCFlagSpell("奥术冲击");
		return;
	end]]

	if D:CastReadable() and manrpt>0.9 and WA_CheckSpellUsableOn("奥术冲击") then
		CCFlagSpell("奥术冲击");
		return;
	end

	if (manrpt<0.8 and not WA_CheckDebuff("奥术冲击",0,3,true,"player")) or  not WA_CheckDebuff("奥术冲击",0,4,true,"player") then
		if D:CastReadable() and WA_CheckSpellUsableOn("奥术飞弹") then
			CCFlagSpell("奥术飞弹");
			return;
		elseif WA_CheckSpellUsableOn("奥术弹幕") then
			CCFlagSpell("奥术弹幕");
			return;
		end
	end

	if D:CastReadable() and WA_CheckSpellUsableOn("奥术冲击") then
		CCFlagSpell("奥术冲击");
		return;
	end
end

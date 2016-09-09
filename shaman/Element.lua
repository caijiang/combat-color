-- Element.lua

-- CCSHAMANEnhance.lua

local addonName, T = ...;
local D = T.jcc;

local _,clzz = UnitClass("player");
if clzz~="SHAMAN" then return;end

local S = D.SHAMAN;

local E = S:NewModule("SHAMAN1", "AceEvent-3.0", "AceHook-3.0","CCTalent-1.0");

function E:onCCLoaded()
	D.UsingSpellCooldowns["闪电链"]=nil;
end

E.TalentSpellDescs = {
	["雷霆风暴"] = {slot=30,havecd=true},
	["熔岩爆裂"] = {slot=31,havecd=true},
	["地震术"] = {slot=32,havecd=true},
}

function E:Work(pvp)

	local spell, _, _, _, startTime, endTime = UnitCastingInfo("player");

	if(spell)then
		local timeToFinish = endTime - GetTime()*1000;
		if timeToFinish>=500 then
			return;
		end
	end

	if R.GCDLeftTime>D.MaxDelayS then
		return;
	end

	if WA_CheckSpellUsable("闪电之盾") and WA_CheckBuff("闪电之盾") then
		CCFlagSpell("闪电之盾");
		return;
	end

	if not WA_CheckBuff("升腾") then
		if CCFightType==1 and WA_CheckSpellUsableOn("熔岩爆裂") and D:CastReadable() then
			CCFlagSpell("熔岩爆裂");
			return;
		end

		if CCFightType==2 and WA_CheckSpellUsableOn("闪电链") and D:CastReadable() then
			CCFlagSpell("闪电链");
			return;
		end
	end
	
	if WA_CheckSpellUsableOn("烈焰震击") and WA_CheckDebuff("烈焰震击",1,0,true) then
		CCFlagSpell("烈焰震击");
		return;
	end

	--90元素释放
	if WA_CheckSpellUsableOn("元素释放") then
		CCFlagSpell("元素释放");
		return;
	end

	if WA_CheckSpellUsableOn("熔岩爆裂") and not WA_CheckBuff("熔岩奔腾") then
		CCFlagSpell("熔岩爆裂");
		return;
	end

	if WA_CheckSpellUsableOn("熔岩爆裂") and D:CastReadable() then
		CCFlagSpell("熔岩爆裂");
		return;
	end

	--如果你点出了90级天赋元素冲击，施放元素冲击。

	
	if WA_CheckSpellUsableOn("大地震击") and not WA_CheckDebuff("烈焰震击",5,0,true) and not WA_CheckBuff("闪电之盾",2,6) then
		CCFlagSpell("大地震击");
		return;
	end

	if WA_CheckSpellUsableOn("大地震击") and WA_CheckDebuff("烈焰震击",5,0,true) and not WA_CheckBuff("闪电之盾",2,3) then
		CCFlagSpell("大地震击");
		return;
	end

	--放下灼热图腾，如果你没有激活的火图腾并且火元素图腾的冷却时间还有15秒以上。
	if not S:TotemActive(1,0)  and  WA_CheckSpellUsable("灼热图腾") then
		CCFlagSpell("灼热图腾");
		return;
	end

	if CCFightType==1 and WA_CheckSpellUsableOn("闪电箭") then
		CCFlagSpell("闪电箭");
		return;
	end

	if CCFightType==2 and WA_CheckSpellUsable("地震术") then
	end

	if CCFightType==2 and WA_CheckSpellUsableOn("闪电链") and D:CastReadable()  then
		CCFlagSpell("闪电链");
		return;
	end

end

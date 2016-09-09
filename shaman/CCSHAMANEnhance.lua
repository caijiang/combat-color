-- CCSHAMANEnhance.lua

local addonName, T = ...;
local D = T.jcc;

local _,clzz = UnitClass("player");
if clzz~="SHAMAN" then return;end

local S = D.SHAMAN;

local E = S:NewModule("SHAMAN2", "AceEvent-3.0", "AceHook-3.0","CCTalent-1.0");

E.TalentSpellDescs = {
	["熔岩猛击"] = {slot=42,havecd=true},
	["风暴打击"] = {slot=43,havecd=true},
	["萨满之怒"] = {slot=44,havecd=true},
	["野性狼魂"] = {slot=45,havecd=true},
}

function E:Work(pvp)
		local theRange = 9999;
	if(IsSpellInRange("根源打击","target")==1)then
		theRange = 1;
	elseif(IsSpellInRange("大地震击","target")==1)then
		theRange = 2;
	elseif(IsSpellInRange("闪电箭","target")==1)then
		theRange = 3;
	end
	
	if(theRange>9000)then
		return;
	end

	
	if S:CheckTotem(S.SpellIDs.CallofElements) then
		return;
	end
	
	--[[if(not S:TotemActive(1,4)  and  WA_CheckSpellUsable("元素的召唤"))then
		CCFlagSpell("元素的召唤");
		return;
	end

	if(not S:TotemActive(1,1)  and  WA_CheckSpellUsable("灼热图腾"))then
		CCFlagSpell("灼热图腾");
		return;
	end]]

	if(WA_CheckSpellUsable("闪电之盾") and WA_CheckBuff("闪电之盾"))then
		CCFlagSpell("闪电之盾");
		return;
	end

	if CCAutoRush then
		if WA_CheckSpellUsable("野性狼魂") and theRange==1 then
			CCWA_RacePink();
			CCFlagSpell("野性狼魂");
			return;
		end
	end

	--[[ ]]
	if(#S.FlameShocks>1 and WA_CheckSpellUsable("火焰新星"))then
		CCFlagSpell("火焰新星");
		return;
	end

	--因为风暴打击的debuf 无论何种战斗都应该将它前置
	if(WA_CheckSpellUsableOn("风暴打击"))then
		CCFlagSpell("风暴打击");
		return;
	end

	if(WA_CheckSpellUsableOn("根源打击"))then
		CCFlagSpell("根源打击");
		return;
	end

	-- 烈焰震击>释放元素能量>熔岩暴击 AOE
	if CCFightType==2 then
		if(WA_CheckSpellUsable("元素释放") and not WA_CheckDebuff("烈焰震击",5,0,true))then
			CCFlagSpell("元素释放");
			return;
		end
		if(WA_CheckSpellUsableOn("熔岩猛击") and not WA_CheckDebuff("烈焰震击",4,0,true))then
			CCFlagSpell("熔岩猛击");
			return;
		end
		if(WA_CheckSpellUsableOn("烈焰震击") and WA_CheckDebuff("烈焰震击",2,0,true))then
			CCFlagSpell("烈焰震击");
			return;
		end
	end

	--在单体战斗或者目标存在震击的时候 随意使用猛击
	if(WA_CheckSpellUsableOn("熔岩猛击") and (CCFightType==1 or not WA_CheckDebuff("烈焰震击",10,0,true) ) )then
		CCFlagSpell("熔岩猛击");
		return;
	end

	--5层气漩武器闪电箭 ??  [漩涡武器]
	if(CCFightType==1 and WA_CheckSpellUsableOn("闪电箭") and not WA_CheckBuff("漩涡武器",1,5))then
		CCFlagSpell("闪电箭");
		return;
	end
	if(CCFightType==2 and WA_CheckSpellUsableOn("闪电链") and not WA_CheckBuff("漩涡武器",1,5))then
		CCFlagSpell("闪电链");
		return;
	end

	--有释放火舌能量时烈焰震击 不是很懂 暂时设置为如果目标没有中震击
	--if(WA_CheckSpellUsableOn("烈焰震击"))then
	--if(WA_CheckSpellUsableOn("烈焰震击") and WA_CheckDebuff("烈焰震击",1,0,true))then
	if(WA_CheckSpellUsableOn("烈焰震击") and not WA_CheckBuff("火焰释放"))then
		CCFlagSpell("烈焰震击");
		return;
	end
	

	--释放元素能量???? 
	if CCFightType==1 and WA_CheckSpellUsable("元素释放") and theRange==1 then
		CCFlagSpell("元素释放");
		return;
	end
	
	--这个还有必要么？
	--[[if CCFightType==2 and #S.FlameShocks>0 and WA_CheckSpellUsable("火焰新星") then
		CCFlagSpell("火焰新星");
		return;
	end]]

	if WA_CheckSpellUsableOn("大地震击") then
		CCFlagSpell("大地震击");
		return;
	end

	if D:CastReadable() and WA_CheckSpellUsableOn("熔岩爆裂") and  (not WA_CheckDebuff("烈焰震击",1,0,true)) then
		CCFlagSpell("熔岩爆裂");
		return;
	end
	
	if D:CastReadable() and WA_CheckSpellUsableOn("闪电箭") and theRange >= 3 then
		CCFlagSpell("闪电箭");
		return;
	end
	
end
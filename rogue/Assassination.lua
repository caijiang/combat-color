-- Assassination.lua

local addonName, T = ...;
local D = T.jcc;

local _,clzz = UnitClass("player");
if clzz~="ROGUE" then return;end

local R = T.jcc.ROGUE;
local C = R:NewModule("ROGUE1", "AceEvent-3.0", "AceHook-3.0","CCTalent-1.0");

C.TalentSpellDescs = {
		["毁伤"] =37,
		["毒伤"] =38,
		["斩击"] =39,
		["仇杀"] = {slot=40,havecd=true},
};

--[[
你可以在不损失[割裂]的最后一跳伤害的情况下覆盖它。这伤害会被重新计算到下一个[割裂]的开始。
目标血量高于35%时：
有[預知]天赋时：使用5星终结技。如果在5星时，触发了[盲点]，永远先使用[抹殺]。保持100%的[割裂]覆盖。
没有[預知]天赋时： 使用4星5星终结技。 如果在4星时，触发了[洞悉要害]，永远先使用[斩击]。 保持100%的[割裂]覆盖。
目标血量低于35%时：
所有的[毒伤]都必须5星释放，同时保持100%的[割裂]覆盖。 使用[斩击]作为唯一的攒星技除非你需要泄能(能量一直溢出的情况)。
2.3 多目标
这一部分仍需要讨论，目前的想法是使用[刀扇]作为攒星技并且在3个目标上保持一定长度的[割裂](很可能是3星), 在[割裂]保持期间使用[毒伤]来释放星。
]]

function C:Work(pvp)
	local p = GetComboPoints("player","target");
	local power = UnitPower("player");
	local inZS = UnitHealth("target")/UnitHealthMax("target")<=0.35;

	local prps = select(2,GetPowerRegen());

	if R.LastUUID~=UnitGUID("target") and GetTime()-R.LastZHTime<20 and p==0 and R.LastP>1 and WA_CheckSpellUsable("转嫁") then
		CCFlagSpell("转嫁");
		return;
	end

	R:LogP();

	if WA_CheckSpellUsable("伏击") and R.inback then
		CCFlagSpell("伏击");
		return;
	end

	--(WA_Is_Boss() or not WA_CheckBuff("剑刃乱舞")) and
	if WA_CheckSpellUsable("毒伤") and not WA_CheckBuff("切割") and WA_CheckBuff("切割",3) and p>0 then
		CCFlagSpell("毒伤");
		return;
	end

	if WA_CheckSpellUsable("切割") and WA_CheckBuff("切割") and p<=2 then
		CCFlagSpell("切割");
		return;
	end

	local baofa = R:RushConditon() or not WA_CheckDebuff("仇杀",3,0,true);

	if CCAutoRush and baofa and WA_CheckSpellUsable("仇杀") then
		CCFlagSpell("仇杀");
		return;
	end

	if CCAutoRush and baofa and WA_CheckSpellUsable("暗影之刃") then
		CCFlagSpell("暗影之刃");
		return;
	end

	if ((not baofa) or CCFightType==2) and WA_CheckSpellUsableOn("割裂") and WA_CheckDebuff("割裂",2,0,true) then
		CCFlagSpell("割裂");
		return;
	end

	if p==5 and CCFightType==2 and WA_CheckSpellUsable("猩红风暴") then
		CCFlagSpell("猩红风暴");
		return;
	end

	if p==5 and (baofa or power>90) and WA_CheckSpellUsable("毒伤") then
		CCFlagSpell("毒伤");
		return;
	end

	if CCFightType==2 then
		if not WA_CheckBuff("盲点") and WA_CheckSpellUsable("斩击") then
			CCFlagSpell("斩击");
			return;
		end
		if p<5 and WA_CheckSpellUsable("刀扇") then
			CCFlagSpell("刀扇");
			return;--
		end
		return;
	end

	if not WA_CheckBuff("盲点") and WA_CheckBuff("盲点",2) and WA_CheckSpellUsable("斩击") then
		CCFlagSpell("斩击");
		return;
	end

	if (WA_CheckBuff("预感",0,4) or p<5) and (inZS or not WA_CheckBuff("盲点")) and WA_CheckSpellUsable("斩击") then
		CCFlagSpell("斩击");
		return;
	end

	if (WA_CheckBuff("预感",0,3) or p<5) and WA_CheckSpellUsableOn("毁伤") then
		CCFlagSpell("毁伤");
		return;
	end
end

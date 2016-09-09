-- CCPALADINRetribution.lua

local addonName, TT = ...;
local D = TT.jcc;

local _,clzz = UnitClass("player");
if clzz~="PALADIN" then return;end

local Q = D.PALADIN;

local T = Q:NewModule("PALADIN3", "AceEvent-3.0", "AceHook-3.0","CCTalent-1.0");


T.TalentSpellDescs = {
	["狂热"] = {slot=31,havecd=true},
	["忏悔"] = {slot=32,havecd=true},
	["圣殿骑士的裁决"] = 33,
	["神圣风暴"] = {slot=34,havecd=true},
	["圣洁护盾"] = {slot=35,havecd=true},
};

local function aoe()
	
	local spp = UnitPower("player",SPELL_POWER_HOLY_POWER);

	if WA_CheckBuff("异端裁决",1) and WA_CheckSpellUsable("异端裁决") then
		CCFlagSpell("异端裁决");
		return;
	end

	if WA_CheckSpellUsable("神圣风暴") then
		CCFlagSpell("神圣风暴");
		return;
	end

	if (not WA_CheckBuff("神圣意志") or spp==3) and WA_CheckBuff("异端裁决",4) and WA_CheckSpellUsableOn("异端裁决") then
		CCFlagSpell("异端裁决");
		return;
	end

	if (not WA_CheckBuff("神圣意志") or spp==3) and WA_CheckSpellUsableOn("圣殿骑士的裁决") then
		CCFlagSpell("圣殿骑士的裁决");
		return;
	end
	
			
	if WA_CheckSpellUsable("奉献") then
		CCFlagSpell("奉献");
		return;
	end
	

	if spp<3 and WA_CheckSpellUsableOn("审判") then
		CCFlagSpell("审判");
		return;
	end

	-- 可以提早到裁决中间 以神圣和能量3区分
	if not WA_CheckBuff("战争艺术") and WA_CheckSpellUsableOn("驱邪术") then
		CCFlagSpell("驱邪术");
		return;
	end

	if WA_CheckSpellUsableOn("愤怒之锤") then
		CCFlagSpell("愤怒之锤");
		return;
	end

	if WA_CheckSpellUsableOn("审判") then
		CCFlagSpell("审判");
		return;
	end

	local szjcdleft = WA_CooldownLeft("神圣风暴",1);
	if WA_CheckSpellUsable("神圣愤怒") and szjcdleft>1 and szjcdleft<=1.3 then
		CCFlagSpell("神圣愤怒");
		return;
	end
end

function T:Work()
	local spp = UnitPower("player",SPELL_POWER_HOLY_POWER);

	local torush = Q:RushPrepose() and CCAutoRush;

	if torush and WA_CheckSpellUsable("狂热") then
		CCFlagSpell("狂热");
		return;
	end

	if CCAutoRush and not WA_CheckBuff("狂热") and WA_CheckSpellUsable("复仇之怒") then
		CCFlagSpell("复仇之怒");
		return;
	end

	if WA_CheckBuff("异端裁决",1) and WA_CheckSpellUsable("异端裁决") and spp>=2 then
		CCFlagSpell("异端裁决");
		return;
	end

	if CCAutoRush and not WA_CheckBuff("狂热") and not WA_CheckBuff("复仇之怒") then
		CCWA_RacePink();
	end

	CCWA_RacePink(true,nil,true);

	if CCFightType==2 then
		aoe();
		return;
	end

	--单体输出用真理,在4+目标时用 正义圣印 可以获得更高的群体输出.

	if spp<3 and WA_CheckSpellUsableOn("十字军打击") then
		CCFlagSpell("十字军打击");
		return;
	end

	if (not WA_CheckBuff("神圣意志") or spp==3) and WA_CheckBuff("异端裁决",4) and WA_CheckSpellUsableOn("异端裁决") then
		CCFlagSpell("异端裁决");
		return;
	end

	if (not WA_CheckBuff("神圣意志") or spp==3) and WA_CheckSpellUsableOn("圣殿骑士的裁决") then
		CCFlagSpell("圣殿骑士的裁决");
		return;
	end

	if WA_CheckBuff("狂热") and spp<3 and WA_CheckSpellUsableOn("审判") then
		CCFlagSpell("审判");
		return;
	end

	-- 可以提早到裁决中间 以神圣和能量3区分
	if not WA_CheckBuff("战争艺术") and WA_CheckSpellUsableOn("驱邪术") then
		CCFlagSpell("驱邪术");
		return;
	end

	if WA_CheckSpellUsableOn("愤怒之锤") then
		CCFlagSpell("愤怒之锤");
		return;
	end

	if WA_CheckBuff("狂热") and WA_CheckSpellUsableOn("审判") then
		CCFlagSpell("审判");
		return;
	end


	local szjcdleft = WA_CooldownLeft("十字军打击",1);
	if WA_CheckBuff("狂热") and WA_CheckSpellUsable("神圣愤怒") and szjcdleft>0.8 and szjcdleft<=1 then
		CCFlagSpell("神圣愤怒");
		return;
	end

	if WA_CheckBuff("狂热") and WA_CheckSpellUsable("奉献") and szjcdleft>1 and szjcdleft<=1.3 then
		CCFlagSpell("奉献");
		return;
	end


	
end
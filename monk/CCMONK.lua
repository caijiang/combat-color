-- CCMONK.lua
--Brewmaster - Tanking
--Mistweaver - A healer/damage hybrid, similar to a Discipline priest
--Windwalker - Melee DPS

local addonName, T = ...;
local D = T.jcc;

local _,clzz = UnitClass("player");
if clzz~="MONK" then return;end

local W = T.jcc:NewModule("MONK", "AceEvent-3.0", "AceHook-3.0","CCClass-1.0");
T.jcc.MONK = W;

W.breakingSpell = "切喉手";
W.testRangeHitSpell = "贯日击";
W.testGCDSpell = "贯日击";
W.ClassSpellDescs = {
		["贯日击"] =1,
		["猛虎式"] = 2,
		["猛虎掌"] =3,
		["幻灭踢"]=4,
		["嚎镇八方"]={slot=5,havecd=true},--嘲讽
		["轮回之触"]={slot=6,havecd=true},
		["壮胆酒"]={slot=7,havecd=true},
		["移花接木"]={slot=8,havecd=true},--与ap有关
		["金刚震"]=9,--断筋啦
		["切喉手"]={slot=10,havecd=true},
		["分筋错骨"]={slot=11,havecd=true},
		["神鹤引项踢"]=12,
		["碎玉闪电"]=13,
		["化瘀术"]={slot=14,havecd=true},--中毒和疾病
		["探云鞭"]={slot=15,havecd=true},
		--玄牛睥睨
		--3
		["虎威"]={slot=20,havecd=true},
		["真气波"]={slot=21,havecd=true},
		["禅意珠"]={slot=21,havecd=true},
		["真气爆裂"]={slot=21,havecd=true},
		["真气酒"]={slot=22,havecd=true},
		["蛮牛冲"]={slot=23,havecd=true},
		["扫堂腿"]={slot=23,havecd=true},
		["躯不坏"]={slot=24,havecd=true},
		["散魔功"]={slot=24,havecd=true},
		["碧玉疾风"]={slot=25,havecd=true},
		["呼唤白虎雪怒"]={slot=25,havecd=true},
		["真气突"]={slot=25,havecd=true},
		["切喉手M"]={slot=26,havecd=true,marco="/cast [@mouseover,harm,nodead]切喉手"},
	};

function W:GetChi()
	return UnitPower("player",SPELL_POWER_CHI);
end

local chimaxchecked=false;
local chimaxadded=0;
function W:GetChiMax()
	if not chimaxchecked then
		chimaxchecked = true;
		if select(5,GetTalentInfo(8)) then
			chimaxadded=1;
		end
	end
	return 4+chimaxadded;
end

function W:GetChiMargin()
	return  W:GetChiMax()-W:GetChi();
end

function W:AllowWork(inputpvp)

	if SpellIsTargeting() then return end

	if W.TalentType~=2 and ((not InCombat)or(not WA_NeedAttack()))then return end

	if((not inputpvp) and CC_Raid_B())then return end

	if W.TalentType~=2 and (UnitIsBeFear("target") or UnitIsNotAbleAttack("target") or UnitIsBeOutControl("target"))then
		return;
	end

	local pvp = UnitIsPlayer("target");
	if(inputpvp)then
		pvp = true;
	end

	if(CCWA_Check_PreToCasts(pvp))then return end

	--[[if(not pvp)then
		if(CC_check_threat_dps())then return end
	end]]

	if(W.TalentType~=2 and CC_TargetisWudi())then
		jcmessage("换目标");
		return;
	end

--[[	if(pvp and (CC_PVP_Enable or inputpvp))then
		if(CC_PVP())then return end
	end]]

	return true;
end

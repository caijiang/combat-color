-- CCWARLOCKDestruction.lua
-- 木桩战：智力>暴击>精通=溅射>急速=全能
-- 移动战：智力>暴击>精通=溅射>急速>全能
local addonName, T = ...;
local D = T.jcc;

local _,clzz = UnitClass("player");
if clzz~="WARLOCK" then return;end

local W = T.jcc.WARLOCK;
local DD = W:NewModule("WARLOCK3", "AceEvent-3.0", "AceHook-3.0","CCTalent-1.0");

DD.TalentSpellDescs = {
		["燃烧"] ={slot=16,havecd=true},
		["烧尽"] = {slot=17,havecd=false},
		["混乱之箭"] =18,
		["献祭"] =19,
		["灰烬转换"] =20,
		["火焰之雨"] = {slot=21,havecd=false},
		["浩劫"] ={slot=22,havecd=true},--,marco="/cast [@focus]%s"
		["暗影灼烧"] = {slot=23,havecd=true},
		["硫磺烈火"] =24,
		["克索诺斯之焰"] = {slot=25,havecd=true},
		["黑暗灵魂：易爆"] = {slot=26,havecd=true},		
		["献祭mouseover"] ={slot=27,havecd=false,marco="/cast [@mouseover]献祭"},
		["燃烧mouseover"] ={slot=28,havecd=true,marco="/cast [@mouseover]燃烧"},
		["烧尽mouseover"] ={slot=29,havecd=false,marco="/cast [@mouseover]烧尽"},
		["混乱之箭mouseover"] ={slot=30,havecd=false,marco="/cast [@mouseover]混乱之箭"},
		["暗影灼烧mouseover"] ={slot=31,havecd=true,marco="/cast [@mouseover]暗影灼烧"},
	};


local function sflh()
	--可能会为了保持buf 稍后使用 :)
	--[[if WA_CheckSpellUsable("灵魂之火") and (not WA_CheckBuff("灵魂燃烧") or not WA_CheckBuff("灵魂燃烧：灵魂之火") or not WA_CheckBuff("小鬼增效")) then
		CCFlagSpell("灵魂之火");
		return true;
	end]]
end

function DD:tryzh()
	if CCShareHoly.isHarm("focus") and UnitGUID("focus")~=UnitGUID("target") then
		if W:zh("focus") then return true; end
	end
	return false;
end

function DD:focusHaojieable()
	-- 已有浩劫
	if not WA_CheckBuff("浩劫") then
		return false;
	end
	if CCShareHoly.isHarm("mouseover") and UnitGUID("mouseover")~=UnitGUID("target") then
		if WA_CheckDebuff("浩劫",0,0,true,"target") then
			return WA_CheckSpellUsable("浩劫","target");
		--else
		--	return not WA_CheckBuff("浩劫")
		end
	end
	return false;
end

local function myCCFlagSpell(sname,unit) 
	unit = unit or "";
	CCFlagSpell(sname..unit);
end

function DD:zhuoshao(unit)
	if not CCShareHoly.isHarm(unit) then return false;end
	if CCShareHoly.isHelp(unit) then return false;end
	if WA_CheckSpellUsable("暗影灼烧",unit) then
		myCCFlagSpell("暗影灼烧",unit);
		return true;
	end
	return false;
end

function DD:ranshao2(unit)
	if not CCShareHoly.isHarm(unit) then return false;end
	if CCShareHoly.isHelp(unit) then return false;end
	local dpcfcharges, dpcfmaxCharges, dpcfstart, dpcfduration = GetSpellCharges("燃烧");
	if dpcfcharges<dpcfmaxCharges then
		return false;
	end
	if WA_CheckSpellUsable("燃烧",unit) then
		myCCFlagSpell("燃烧",unit);
		return true;
	end
	return false;
end

function DD:xj(unit)
	if not CCShareHoly.isHarm(unit) then return false;end
	if CCShareHoly.isHelp(unit) then return false;end
	local _, _, _, castTime = GetSpellInfo("献祭");
	if D:CastReadable("献祭") and WA_CheckDebuff("献祭",castTime/1000,0,true,unit) and WA_CheckSpellUsable("献祭",unit) and GetTime()-W.last_xj_time>2 then
		myCCFlagSpell("献祭",unit);
		return true;
	end
	return false;
end

function DD:alwayShaojin(unit)
	D:Debug("测试1",unit);
	if not CCShareHoly.isHarm(unit) then return false;end
	if CCShareHoly.isHelp(unit) then return false;end
	D:Debug("测试2",unit," ",D:CastReadable("烧尽"),"  ",WA_CheckSpellUsable("烧尽",unit) );
	if D:CastReadable("烧尽") and WA_CheckSpellUsable("烧尽",unit) then
		myCCFlagSpell("烧尽",unit);
		return true;
	end
	return false;
end

function DD:shaojin(unit)
	--烧尽，如果爆燃层数大于等于3
	if not CCShareHoly.isHarm(unit) then return false;end
	if CCShareHoly.isHelp(unit) then return false;end
	if not WA_CheckBuff("爆燃",0,3) and D:CastReadable("烧尽") and WA_CheckSpellUsable("烧尽",unit) then
		myCCFlagSpell("烧尽",unit);
		return true;
	end
	return false;
end

function DD:alwaysHunluan(unit)
	if not CCShareHoly.isHarm(unit) then return false;end
	if CCShareHoly.isHelp(unit) then return false;end
	if D:CastReadable("混乱之箭") and WA_CheckSpellUsable("混乱之箭",unit) then
		myCCFlagSpell("混乱之箭",unit);
		return true;
	end
	return false;
end

function DD:hunluan(unit)
	if not CCShareHoly.isHarm(unit) then return false;end
	if CCShareHoly.isHelp(unit) then return false;end
	--如果爆燃层数小于3，且灰烬满4个
	local spp = UnitPower("player",SPELL_POWER_BURNING_EMBERS);
	if WA_CheckBuff("爆燃",0,3) and spp>=3.5 and D:CastReadable("混乱之箭") and WA_CheckSpellUsable("混乱之箭",unit) then
		myCCFlagSpell("混乱之箭",unit);
		return true;
	end
	return false;
end

function DD:Work(pvp)
	--local _,_,_,_,qhlhzh = GetTalentInfo(3,7);
	local spp = UnitPower("player",SPELL_POWER_BURNING_EMBERS);
	local torush = W:RushPrepose() and CCAutoRush;
	local inZS = WA_CheckSpellUsable("暗影灼烧");
	if not inZS then
		inZS = UnitHealth("target")/UnitHealthMax("target")<=0.2;
	end

	--D:Debug("没进入战斗状态 也来这里？");
	local pr = UnitPower("player")/UnitPowerMax("player");
	local timetoha = WA_CooldownLeft("黑暗灵魂：易爆");
	local dpcfcharges, dpcfmaxCharges, dpcfstart, dpcfduration = GetSpellCharges("黑暗灵魂：易爆");

	--附加条件有可攻击的焦点 并且zh可用或者已用	
	--D:TimeToDie(4)
	--思路维护 应该减少更换目标 浩劫应该打在血最多 也就是当前目标上
	
	--爆发阶段(嗜血，卡牌sp触发，boss易伤等足量增益BUFF触发时)使用黑暗灵魂，主动sp，读混乱箭直至灰烬不够
	--TODO 检测爆发
	if (dpcfmaxCharges and dpcfcharges>=dpcfmaxCharges) and WA_CheckSpellUsable("黑暗灵魂：易爆") and WA_CheckBuff("黑暗灵魂：易爆") then
		CCFlagSpell("黑暗灵魂：易爆");
		--return;
	end
	
	--[[aoe
	火焰之雨
硫磺烈火
保持献祭
燃烧，如果燃烧充能2层
烧尽]]
	
	if CCShareHoly.isHarm("mouseover") and DD:focusHaojieable() then
		CCFlagSpell("浩劫");
		return;
	end
	
	-- 目标已有浩劫的打法
	if CCShareHoly.isHarm("mouseover") and not WA_CheckDebuff("浩劫",0,0,true,"target") then
		if DD:zhuoshao("mouseover") then return end
		if not WA_CheckBuff("浩劫",0,3) then
			if DD:alwaysHunluan("mouseover") then return end
		end
		--如果有3层浩劫buff，对ADD释放混乱之箭
		if WA_CheckSpellUsable("燃烧","mouseover") then
			myCCFlagSpell("燃烧","mouseover");
			return;
		end
		--如果不足3层浩劫buff，对ADD释放燃烧
		--如果不足3层浩劫buff，保持ADD目标的献祭
		if DD:xj("mouseover") then return end
		--如果不足3层浩劫buff，对ADD释放烧尽
		if DD:alwayShaojin("mouseover") then return end
	end
	
	-- 是否应该优先灼烧？
	if DD:zhuoshao("mouseover") then return end
	--燃烧，如果燃烧充能2层
	if DD:ranshao2("mouseover") then return end
	if DD:xj() then return end
	if DD:xj("mouseover") then return end
	if DD:shaojin("mouseover") then return end
	if DD:hunluan("mouseover") then return end
	if DD:alwayShaojin("mouseover") then return end
	
	if DD:zhuoshao() then return end
	--燃烧，如果燃烧充能2层
	if DD:ranshao2() then return end
	
	if DD:shaojin() then return end
	if DD:hunluan() then return end
	if DD:alwayShaojin() then return end
	

	if WA_CheckSpellUsable("火焰之雨") and WA_CheckDebuff("火焰之雨",0,0,true) and (
		D:IsSXing()
		or (CCShareHoly.isHarm("focus") and UnitGUID("focus")~=UnitGUID("target"))
	) then
		CCFlagSpell("火焰之雨");--或者其他急速
		return;
	end

	--aoe
	if not WA_CheckBuff("硫磺烈火") then
		if WA_CheckSpellUsable("燃烧") then
			CCFlagSpell("燃烧");
			return;
		end
		if WA_CheckSpellUsable("烧尽") and D:CastReadable("烧尽") then
			CCFlagSpell("烧尽");
			return;
		end
		if WA_CheckSpellUsable("邪焰") then
			CCFlagSpell("邪焰");
			return;
		end
	end

	--sl only 
	--[[if UnitHealth("player")/UnitHealthMax("player")<0.3 and WA_CheckSpellUsable("吸取生命") and D:CastReadable("吸取生命") then
		CCFlagSpell("吸取生命");
		return;
	end]]

	if WA_CheckSpellUsable("混乱之箭") and D:CastReadable("混乱之箭") and (
		spp>=3.5 or
		not WA_CheckBuff("黑暗灵魂：易爆") or 
		--你有一个灰常流弊的智力饰品触发了
		not WA_CheckBuff("颅骨战旗")
	) then
		if DD:tryzh() then return; end
		CCFlagSpell("混乱之箭");
		return;
	end

	if WA_CheckSpellUsable("燃烧") then
		CCFlagSpell("燃烧");--1次充能完毕.
		return;
	end

	--rush 恶魔之魂
	if torush and WA_CheckSpellUsable("黑暗灵魂：易爆") and WA_CheckBuff("黑暗灵魂：易爆") then
		CCFlagSpell("黑暗灵魂：易爆");
		return;
	end

	if WA_CheckSpellUsable("烧尽") and D:CastReadable("烧尽") then
		CCFlagSpell("烧尽");
		return;
	end
	if WA_CheckSpellUsable("邪焰") and pr>0.4 then
		CCFlagSpell("邪焰");
		return;
	end
--[[	if UnitHealth("player")/UnitHealthMax("player")>0.4 and UnitPower("player")/UnitPowerMax("player")<0.2 and WA_CheckSpellUsable("生命分流") then		
		CCFlagSpell("生命分流");
		return;
	end]]
end
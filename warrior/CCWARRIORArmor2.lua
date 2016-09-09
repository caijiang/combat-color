-- CCWARRIORArmor.lua

-- 龙吼找巨人外，风暴锤找巨人内。

local addonName, T = ...;
local D = T.jcc;

local _,clzz = UnitClass("player");
if clzz~="WARRIOR" then return;end

D.lastKuangbaoZitai = 0;
local W = T.jcc.WARRIOR;
local A = W:NewModule("WARRIOR1", "AceEvent-3.0", "AceHook-3.0","CCTalent-1.0");

function A:PLAYER_REGEN_ENABLED()
end

A.TalentSpellDescs = {
		--英勇之怒？ 没必要
		["致死打击"] ={slot=25,havecd=true},
		["撕裂"] = {slot=26},
		["雷霆一击"] = {slot=27,havecd=true},
		["旋风斩"] = {slot=28},
		["横扫攻击"] = {slot=29,havecd=true},
		["巨人打击"] = {slot=30,havecd=true},
		["猛击"] = {slot=31}
};

local JRDJ_SHARE = true;

function A:Rush()
end

local function poweruseable(mana)
	if not mana then mana=10;end
	if not D.hs_enable and CCFightType==1 then
		return true;
	end
	local timetozs = WA_CooldownLeft("横扫攻击",true);--10mana
	if timetozs<1.5 then
		return UnitPower("player")>=10+mana;
	end
	return true;
end

-- 力量>暴击>精通>溅射>全能>急速

function A:Work(pvp)
	if(GetShapeshiftForm()==2)then
		jcmessage("确定要防御姿态输出么？？");
	end
	local powergap = UnitPowerMax("player")-UnitPower("player");
	local power = UnitPower("player");
	local inZS = UnitHealth("target")/UnitHealthMax("target")<=0.2;
	local timetojr = WA_CooldownLeft("巨人打击",true);
	local timetozs = WA_CooldownLeft("致命打击",true);
	
	if WA_CheckBuff("激怒") and not WA_CheckDebuff("巨人打击",1,0,true) then
		W:Kuangbaozhinu(0.9,100)
	end

	if (D.hs_enable or CCFightType==2) and WA_CheckSpellUsable("横扫攻击") then
		CCFlagSpell("横扫攻击");
	end
	
	local rushable = W:ShouldRush();
	
	-- 自动rush的 必须有它充分的条件 手工编纂爆发宏 用于手控爆发！
	if CCAutoRush and not WA_CheckDebuff("巨人打击",1,0,true) and rushable then
		W:RushDps();
	end

	if W.GCDLeftTime>D.MaxDelayS then
		return;
	end
	
	local hasMengji = false;
	if GetSpellInfo("猛击") then hasMengji=true;end
	
	--猛击流的打法 在于巨人打击期间大肆倾泻怒气
	
	if W:Chengsheng(0.7) then
		return;
	end
	
	if WA_CheckDebuff("巨人打击",0.1,0,true) and WA_CheckSpellUsable("撕裂")  and WA_CheckDebuff("撕裂",0,0,true) then
		CCFlagSpell("撕裂");
		return;
	end
	
	if WA_CheckSpellUsable("破坏者") and timetojr<4 and (
		CCFightType==2
		or CCAutoRush
	) then
		CCFlagSpell("破坏者");
		return;
	end
	
	
	if(CC_InRange() and CCFightType==2)then
		if WA_CheckSpellUsable("剑刃风暴") then
			CCFlagSpell("剑刃风暴");
			return;
		end
		--[[if(poweruseable(10) and WA_CheckSpellUsable("雷霆一击") and WA_CheckDebuff("重伤",1,0,true))then
			CCFlagSpell("雷霆一击");
			return true;
		end
		if poweruseable(10) and WA_CheckSpellUsable("巨人打击") and WA_CheckDebuff("巨人打击",0.1,0,true) and not CC_Raid_NoRush() then
			CCFlagSpell("巨人打击");
			return;
		end;
	
		if poweruseable(20) and W:Xuanfengzhan() then return;end]]
	end
	
	if poweruseable(10) and WA_CheckSpellUsable("巨人打击") and WA_CheckDebuff("巨人打击",0.1,0,true) and not CC_Raid_NoRush() then
		CCFlagSpell("巨人打击");
		return;
	end;
	
	if poweruseable(20) and WA_CheckSpellUsable("致死打击") and not inZS and timetojr>1 then
		CCFlagSpell("致死打击");
		return;
	end
	
	if powergap>15 and (not WA_CheckDebuff("巨人打击",0.1,0,true) or timetojr>4) and W:Fengbao() then return;end
	
	if WA_CheckSpellUsable("破城者") then
		CCFlagSpell("破城者");
		return;
	end
	
	if W:JulongNuhou(true) then return;end
	
	if WA_CheckDebuff("巨人打击",0.1,0,true) and WA_CheckSpellUsable("撕裂")  and WA_CheckDebuff("撕裂",5.4,0,true) then
		CCFlagSpell("撕裂");
		return;
	end
	
	if WA_CheckSpellUsable("斩杀") and not WA_CheckBuff("猝死") and CCFightType==2 then
		CCFlagSpell("斩杀");
		return;
	end
	
	--猝死斩杀 如果持续时间>巨人left+1 则等待
	if 	WA_CheckSpellUsable("斩杀") and CCFightType==1 then		
		if (W:RushConditon() and poweruseable(10)) or power>60 or D:TimeToDie(4) then
			CCFlagSpell("斩杀");
			return;
		end
		if not inZS and WA_CheckBuff("猝死",timetojr+1.6) then
			CCFlagSpell("斩杀");
			return;
		end
	end
	
	if CCFightType==1 and not D.hs_enable and poweruseable(10) and WA_CheckSpellUsable("胜利在望") and not inZS and power<40 then
		CCFlagSpell("胜利在望");
		return;
	end
	
	--这里的怒气消耗是未知的 可控爆发的
	if CCFightType==1 and not D.hs_enable and poweruseable(10) and WA_CheckSpellUsable("猛击") and not inZS then
		CCFlagSpell("猛击");
		return;
	end
	
	if (CCFightType==2 or D.hs_enable) and poweruseable(20) and W:Xuanfengzhan() then return;end

	-- 需要留怒气
	local keepp = 30;
	if timetozs<2 then
		keepp=40;
	end
	if (poweruseable(60) or (poweruseable(keepp) and W:RushConditon())) and W:Xuanfengzhan() then return;end
	
	D:Debug("无所事事");
end

local powerOpenJR = 0;

function A:GetPowerOpenJR()
	if not CCAutoRush then
		return powerOpenJR;
	end	
	return powerOpenJR;
end

function A:DynamicShapeshiftForm()
	return false;
end


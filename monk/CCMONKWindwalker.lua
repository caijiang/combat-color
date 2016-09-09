-- CCMONKWindwalker.lua

local addonName, T = ...;
local D = T.jcc;

local _,clzz = UnitClass("player");
if clzz~="MONK" then return;end

local W = T.jcc.MONK;
local DD = W:NewModule("MONK3", "AceEvent-3.0", "AceHook-3.0","CCTalent-1.0");

DD.nomoving = true;

DD.TalentSpellDescs = {
		--英勇之怒？ 没必要
		["怒雷破"] ={slot=31,havecd=true},
		["豪能酒"] ={slot=32,havecd=true},
		["旋火冲"] =33,
		["旭日东升踢"] ={slot=34,havecd=true},
		["虎眼酒"] =35,
	};


function DD:Work(pvp)
	local pr = select(2,GetPowerRegen());
	local spp = UnitPower("player",SPELL_POWER_CHI);
	local power = UnitPower("player",SPELL_POWER_ENERGY);
	local inZS = UnitHealth("target")/UnitHealthMax("target")<=0.2;
	local myhprate = UnitHealth("player")/UnitHealthMax("player");

	local torush = W:RushPrepose() and CCAutoRush;

	local timeToFinish = D.Casting.ttf*1000;
	if D.Casting.name then
		if D.Casting.channeling then
			return;
		end
		if(timeToFinish>=500)then
			return;
		end
	end

	if W.GCDLeftTime>D.MaxDelayS then
		return;
	end


	if CCFightType==1 and not CC_Raid_ShouldDMGWithoutKO() and not WA_CheckBuff("生死簿")  and WA_CheckSpellUsableOn("轮回之触") then
		CCFlagSpell("轮回之触");
		return;
	end

	if WA_CheckSpellUsableOn("旭日东升踢") then
		CCFlagSpell("旭日东升踢");
		return;
	end

	local gcdt  = W.GCDTime or 1000;
	if WA_CheckBuff("猛虎之力",(gcdt+D.MaxDelayS)/1000) and WA_CheckSpellUsableOn("猛虎掌") then
		CCFlagSpell("猛虎掌");
		return;
	end

	--将要20时候 主动使用 配合sx和被动SP
	if not WA_CheckBuff("虎眼酒蒸馏",1,10) and WA_CheckSpellUsable("虎眼酒") then
		CCFlagSpell("虎眼酒");
		return;
	end

	--local njltime = select(7,GetSpellInfo("怒雷破")) or 3;
	if DD.nomoving and WA_CheckSpellUsable("怒雷破") and D:CastReadable() and power+3.5*pr<85 and not D:IsSXing() then
		CCFlagSpell("怒雷破");
		return;
	end

	--这应该算是一个gcd填充性的东西吧。。
	local togcds = floor(power/2);
	if not WA_CheckBuff("踏风连击：幻灭踢") then togcds=togcds+1 end
	if not WA_CheckBuff("踏风连击：猛虎掌") then togcds=togcds+1 end
	if W:GetChiMargin()>0 and power+(togcds*gcdt*pr)/1000<40 and WA_CheckSpellUsable("真气波") then
		CCFlagSpell("真气波");
		return;
	end

	if not WA_CheckBuff("踏风连击：幻灭踢") and WA_CheckSpellUsableOn("幻灭踢") then
		CCFlagSpell("幻灭踢");
		return;
	end

	if not WA_CheckBuff("踏风连击：猛虎掌") and WA_CheckSpellUsableOn("猛虎掌") then
		CCFlagSpell("猛虎掌");
		return;
	end

	-----




	--大于5秒你的能量才达到上限→豪能酒
	--释放白虎下凡或碧玉疾风

	--豪能酒没有激活,猛虎之力有3层并且还能持续4秒,还有大于5秒你的能量才达到上限→怒雷破
	--免费幻灭踢触发→幻灭踢
	--3+气并且能量2秒内到顶→幻灭踢
	--免费的猛虎掌触发并且多余2秒能量才到顶→猛虎掌
	--免费的猛虎掌触发并且猛虎掌buff2秒内就要没了→猛虎掌
	--一气一下力贯千均就绪,或者2气一下力贯千均没有就绪→贯日击

	if WA_CheckSpellUsableOn("幻灭踢") then
		CCFlagSpell("幻灭踢");
		return;
	end

	if myhprate<0.8 and WA_CheckSpellUsableOn("移花接木") then
		CCFlagSpell("移花接木");
		return;
	end

	if CCFightType==1 and WA_CheckSpellUsableOn("贯日击") then
		CCFlagSpell("贯日击");
		return;
	end

	if CCFightType==2 and WA_CheckSpellUsable("神鹤引项踢") then
		CCFlagSpell("神鹤引项踢");
		return;
	end

	if power<40 and WA_CheckSpellUsable("真气波") then
		CCFlagSpell("真气波");
		return;
	end
end

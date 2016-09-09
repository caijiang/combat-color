-- Brewmaster.lua

--天赋  1 1 1 3 2 2
--雕文 壮胆酒 神鹤引项踢 
--124273
--115307

local addonName, T = ...;
local D = T.jcc;

local _,clzz = UnitClass("player");
if clzz~="MONK" then return;end

local M = T.jcc.MONK;
local B = M:NewModule("MONK1", "AceEvent-3.0", "AceHook-3.0","CCTalent-1.0");


-- 35%- 移花接木没cd  
-- 武僧的自保技能 活血酒 飘渺酒 壮胆酒  躯不坏和散魔功
-- 真气波回血 移花接木
B.TalentSpellDescs = {
		["对冲"] ={slot=26,havecd=true},
		["醉酿投"] ={slot=27,havecd=true},
		["火焰之息"] =28,--迷醉酒雾 会燃烧
		["金钟罩"] ={slot=29,havecd=true},--需要ap
		["迷醉酒雾"] =30,--应该不用自动使用的吧
		["飘渺酒"] ={slot=31,havecd=true},--cd 消耗飘渺酒 躲闪 15层max
		["活血酒"] =32,--移除醉拳
	};


local dangerhits = 0;
local function crowhealthcheck(current,max,unit)
	local rate = current/max;
	--D:Debug("目标",unit,",当前血量",current,",最大",max);
	if rate<0.7 then
		dangerhits = dangerhits+1;
	end
	return rate<0.8;
end

local function crownumberchecker(hits)
	local tohits = 3;
	if dangerhits>1 then
		tohits = 2;
	end
	dangerhits = 0;
	--D:Debug("贫血数量",hits);
	return hits>tohits;
end

local powertochi = 40;
--保守算法 暂时不考虑醉酿投
--构建模型 计算 下次可以获得酒醒入定 还需要多少时间
function B:nextJXRD(costChi)	
	local pr = select(2,GetPowerRegen());
	local chiren = pr/powertochi;-- chi / s
	local spp = UnitPower("player",SPELL_POWER_CHI);
	local power = UnitPower("player",SPELL_POWER_ENERGY);
	if spp>=costChi+2 then
		--真气足够这个技能的消耗以及幻灭踢
		D:Debug("真气足够，一个GCD内即可");
		return M.GCDTime;
	end
	local needChi = costChi+2-spp;
	local comingChi = floor(power/powertochi);--当前能量可以获得的chi
	if comingChi>=needChi then
		D:Debug("能量足够，给我",needChi,"个GCD即可");
		return M.GCDTime*needChi;
	end
	local newNeedChi = needChi-comingChi;
	local morepower = mod(power,powertochi);--多余的能量
	local minTime = (newNeedChi-morepower/powertochi)/chiren;
	D:Debug("终极计算，至少需要",max(2,minTime,M.GCDTime*(needChi+1)),"秒");
	return max(2,minTime,M.GCDTime*(needChi+1));
end

function B:Work(pvp)
	-- UnitAttackPower  base, posBuff, negBuff    比如  1200 200 -400 
	-- GetPowerRegen() 需要测试 /print UnitAttackPower("player")
	local pr = select(2,GetPowerRegen());
	local spp = UnitPower("player",SPELL_POWER_CHI);
	local power = UnitPower("player",SPELL_POWER_ENERGY);
	local inZS = UnitHealth("target")/UnitHealthMax("target")<=0.2;
	local myhprate = UnitHealth("player")/UnitHealthMax("player");

	local njtleft = WA_CooldownLeft("醉酿投",true);

	if M.GCDLeftTime>D.MaxDelayS then
		return;
	end

	--not WA_CheckBuff("酒醒入定",njtleft) and 
	if WA_CheckSpellUsable("真气波") and CCShareHoly.isHolyAbleCrow("player",false,0,crowhealthcheck,crownumberchecker) then
		CCFlagSpell("真气波");
		return;
	end

	-- 当白虎下凡或者碧玉疾风冷却好了就使用。

	-- 当移花接木冷却时用它来替代贯日击。
	-- 在酒醒入定>6的时候 可以根据团血 选择是否使用 真气波或者真气爆裂替代幻灭踢
	-- aoe时  神鹤引项踢 casttime<降头cd 代替 贯日击 火焰之息 代替 幻灭踢 同样 酒醒入定>6!

	local tocostpower;
	if WA_CheckSpellUsableOn("贯日击") then
		tocostpower = "贯日击";
	end
	local tocostchi;
	if WA_CheckSpellUsableOn("幻灭踢") then
		tocostchi = "幻灭踢";
	end

	if myhprate<0.8 and  WA_CheckSpellUsable("移花接木") then
		tocostpower = "移花接木";
	end

	--aoe  不用6吧
	if CCFightType==2 and WA_CheckSpellUsable("火焰之息") and not WA_CheckBuff("酒醒入定",B:nextJXRD(2)) then
		tocostchi = "火焰之息";
	end
	if CCFightType==2 and WA_CheckSpellUsable("神鹤引项踢") and select(7,GetSpellInfo("神鹤引项踢"))*1000<njtleft then
		tocostpower = "神鹤引项踢";
	end

	-- 在重度醉拳时使用活血酒。紧急！
	if WA_CheckDebuff("重度醉拳",0,0,0,"player") and WA_CheckSpellUsable("活血酒") then
		CCFlagSpell("活血酒");
		return;
	end

	-- 酒醒入定>6 or chi>=2 表明活血可用 醉拳总伤害大于生命值的40%。
	--在生命值小于70%时清除重度醉拳。
	-- 在一个可预见的巨量伤害前清除活血酒抱枕自己以满血迎接此伤害。

	if WA_CheckSpellUsableOn("醉酿投") then
		CCFlagSpell("醉酿投");
		return;
	end

	-- 在没有酒醒入定或者它的持续时间小于2秒时使用。
	if WA_CheckBuff("酒醒入定",2) and WA_CheckSpellUsableOn("幻灭踢") then
		CCFlagSpell("幻灭踢");
		return;
	end

	if (WA_CheckBuff("猛虎之力") or WA_CheckBuff("强力金钟罩") ) and WA_CheckSpellUsableOn("猛虎掌") then
		CCFlagSpell("猛虎掌");
		return;
	end

	

	-- 在真气满了时使用酒醒入定。
	if M:GetChiMargin()==0 and tocostchi then
		CCFlagSpell(tocostchi);
		return;
	end

	-- 在能量大于80时使用贯日击来避免能量溢出。 不浪费的前提下！
	--当前能量 - 40 + 醉酿投CD*每秒能量回复 > 40
	if power>60 and tocostpower and (power-select(4,GetSpellInfo(tocostpower))+ njtleft*pr)>40 then
		CCFlagSpell(tocostpower);
		return;
	end

	--点穴不？

	if M:GetChiMargin()<2 and tocostchi then
		CCFlagSpell(tocostchi);
		return;
	end

	if WA_CheckSpellUsableOn("猛虎掌") then
		CCFlagSpell("猛虎掌");
		return;
	end

end

-- CCRogue.lua

local addonName, T = ...;
local D = T.jcc;

local _,clzz = UnitClass("player");
if clzz~="ROGUE" then return;end

local R = T.jcc:NewModule("ROGUE", "AceEvent-3.0", "AceHook-3.0","CCClass-1.0");
T.jcc.ROGUE = R;

R.inback = true;
R.breakingSpell = "脚踢";
R.testRangeHitSpell = "影袭";
R.testGCDSpell = "影袭";
R.ClassSpellDescs = {
		["影袭"] =1,
		["刺骨"] = 2,
		["猩红风暴"] =3,
		--["潜行"]={slot=4,havecd=true},
		--["闪避"]={slot=5,havecd=true},
		["脚踢"]={slot=6,havecd=true},
		["疾跑"]={slot=7,havecd=true},
		["凿击"]={slot=8,havecd=true},
		["伏击"] =9,
		["消失"] ={slot=10,havecd=true},
		["扰乱"] ={slot=11,havecd=true},
		["闷棍"]=12,
		["恢复"]=13,
		["背刺"] = 14,
		["肾击"] = {slot=15,havecd=true},
		["切割"] = 16,
		--["致盲"] = {slot=17,havecd=true},
		["拆卸"] = {slot=18,havecd=true},
		["锁喉"] = 19,
		["佯攻"] = 20,
		["复原"] = 21,
		["割裂"] = 22,
		["毒伤"] = 23,
		--["暗影斗篷"] = {slot=24,havecd=true},
		["致命投掷"] = {slot=25,havecd=true},
		["毒刃"] ={slot=26,havecd=true},
		["嫁祸诀窍"] = {slot=27,havecd=true},
		["偷袭"] =28,
		["刀扇"] =29,
		["备战就绪"] ={slot=30,havecd=true},
		["转嫁"] ={slot=31,havecd=true},
		--["烟雾弹"] ={slot=32,havecd=true},
		["死亡嫁祸"] ={slot=32,marco="/cast [target=focus,harm]死亡标记\n/cast 转嫁"},
		["破甲"] =33,
		["暗影之刃"] ={slot=34,havecd=true},
		["飞镖投掷"] ={slot=35,havecd=false},
		["死亡标记"] ={slot=35,havecd=true},
		["脚踢M"]={slot=36,havecd=true,marco="/cast [@mouseover,harm,nodead]脚踢"},

	};

function R:matchGCD(time)
	return time==1;
end

--点了预感天赋 而且不足多少
function R:Yugan(n)
	if not GetSpellInfo("预感") then return false end
	return WA_CheckBuff("预感",5,n,true);
end

function R:PLAYER_REGEN_ENABLED()
	if R.TryXiaoshiTime and GetTime()-R.TryXiaoshiTime<2 then
		CCAutoRush = R.CacheRush;
	end
end

function R:TryXiaoshi()
	R.TryXiaoshiTime = GetTime();
	R.CacheRush = CCAutoRush;
	CCFlagSpell("消失");
end

--高伤害状态
function R:RushConditon()
	--这些是零零碎碎的 如果都触发 那么也算
	return D:IsDamageIncrement()
		or D:IsSXing()
		or WA_CheckDebuff("仇杀",0,10,true)
		or (not WA_CheckBuff("兔妖之啮"))
		or (not WA_CheckBuff("暗影之刃"))
		or (not WA_CheckBuff("凶猛"))
		or (not WA_CheckBuff("恶意"))
		or (not WA_CheckBuff("永恒敏捷"))
		or (not WA_CheckBuff("机敏"));
end

R.LastUUID="";
R.LastP=0;
R.LastZHTime=0;
function R:LogP()
	R.LastUUID=UnitGUID("target");
	R.LastP=GetComboPoints("player","target");
	R.LastZHTime = GetTime();
end

function R:AllowWork(inputpvp)

	if GetSpellInfo("剑刃乱舞") then
		if D.FightHSMode and WA_CheckBuff("剑刃乱舞") and WA_CheckSpellUsable("剑刃乱舞") then
			CCFlagSpell("剑刃乱舞");
		elseif not D.FightHSMode and not WA_CheckBuff("剑刃乱舞") then
			--cancelaura
			CCFlagSpell("剑刃乱舞");
		end
	end

	if WA_NeedAttack() then
		if WA_CheckSpellUsable("预谋") and (GetComboPoints("player","target")<3 or R:Yugan(3)) then
			CCFlagSpell("预谋");
		end
		if WA_CheckSpellUsable("预谋") and not WA_CheckBuff("暗影之舞") and WA_CheckBuff("暗影之舞",1) then
			CCFlagSpell("预谋");
		end
		-- 默认就点出了 诡诈 不然判断起来老复杂了 嘿嘿
		if WA_CheckSpellUsable("预谋") and not WA_CheckBuff("诡诈") and WA_CheckBuff("诡诈",1) then
			CCFlagSpell("预谋");
		end

		if (not InCombat) and WA_CheckSpellUsable("切割") and WA_CheckBuff("切割") then
			CCFlagSpell("切割");
			return;
		end
	end

	if((not InCombat)or(not WA_NeedAttack()))then return end

	if((not inputpvp) and CC_Raid_B())then return end

	if(UnitIsBeFear("target") or UnitIsNotAbleAttack("target") or UnitIsBeOutControl("target"))then
		return;
	end

	local pvp = UnitIsPlayer("target");
	if(inputpvp)then
		pvp = true;
	end

	if PreToCast=="佯攻" and not WA_CheckBuff("佯攻") then PreToCast=nil end
	if PreToCast=="复原" and not WA_CheckBuff("复原") then PreToCast=nil end
	if PreToCast=="肾击" and UnitIsStunned("target") then PreToCast=nil end
	if(CCWA_Check_PreToCasts(pvp))then return end

	if(CC_check_threat_dps())then return end

	if(CC_TargetisWudi())then
		jcmessage("换目标");
		return;
	end

--[[	if(pvp and (CC_PVP_Enable or inputpvp))then
		if(CC_PVP())then return end
	end]]

	if(not CC_InRange())then
		--不在范围 就暂时不管啦
		return;
	end

	--[[if not WA_CheckBuff("潜行") then
		return;
	end

	if GetShapeshiftForm()~=0 then
		return;
	end]]

	if R.GCDLeftTime>D.MaxDelayS then
		return;
	end

	return true;
end

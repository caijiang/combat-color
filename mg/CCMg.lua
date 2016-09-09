-- CCMg.lua
local addonName, T = ...;
local OvaleSpellBook = T.OvaleSpellBook;
local D = T.jcc;

local _,clzz = UnitClass("player");
if clzz~="MAGE" then return;end

local S = D:NewModule("MAGE", "AceEvent-3.0", "AceHook-3.0","CCClass-1.0");
D.MAGE = S;

local mouseovertargetfocus = "/cast [@mouseover,help,nodead][@target,help,nodead][@focus,help,nodead]%s";
S.breakingSpell = "法术反制";
S.testGCDSpell = "霜火之箭";
S.last_casting = nil;
S.last_zs_time = 0;
--  ["奥术冲击"] = 14, ["烈焰宝珠"] = {slot=23,havecd=true},
S.ClassSpellDescs = {
	  ["急速冷却"] = {slot=2,havecd=true},
		["霜火之箭"]=21,
		["冰霜新星"]={slot=22,havecd=true},
		["火焰冲击"] ={slot=3,havecd=true},
		["法术反制"] = {slot=4,havecd=true},--实际上这里需要判断雕文才可以作出j ,marco="/stopcasting\n/cast %s"
		["寒冰屏障"] = {slot=7,havecd=true},
		["解除诅咒"] ={slot=8,marco=mouseovertargetfocus},
		["唤醒"] = {slot=9,havecd=true},
		["烈焰风暴"] = 10,
		["法术吸取"] =13,
		["浮冰"] = {slot=15,havecd=true},
		["时光护盾"] = {slot=16,havecd=true},
		["寒冰护体"] = {slot=16,havecd=true},
		["冰霜之环"] = {slot=17,havecd=true},
		["寒冰结界"] = {slot=17,havecd=true},
		["冰霜之颌"] = {slot=17,havecd=true},
		["活动炸弹"] = {slot=18,havecd=true},
		["冲击波"] = {slot=18,havecd=true},
		["镜像"] = {slot=19,havecd=true},
		["能量符文"] = {slot=19,havecd=true},
		["幻灵晶体"] = {slot=20,havecd=true},
		["流星"] = {slot=20,havecd=true},
		["法术反制M"] = {slot=23,havecd=true,marco="/cast [@mouseover,harm,nodead]法术反制"},
	};

local function HujiaChecker(name)
	return strfind(name,"护甲")~=nil;
end

function S:NearBy(unit)
	unit = unit or "target";
	return CheckInteractDistance(unit,3);
end

-- 幻灵晶体 已开启 并且目标就是自己的幻灵晶体
function S:prismatic_crystal_active()
	return UnitName("target")=="幻灵晶体";
end

function S:dragons_breath()
	if WA_CheckSpellUsable("龙息术") and S:NearBy() then
		CCFlagSpell("龙息术");
		return true;
	end
	return false;
end

function S:blast_wave()
	if WA_CheckSpellUsable("冲击波") and S:NearBy() then
		CCFlagSpell("冲击波");
		return true;
	end
	return false;
end

function S:mirror_image()
	if WA_CheckSpellUsable("镜像") then
		CCFlagSpell("镜像");
		return true;
	end
	return false;
end

-- 存在时间比施法时间少 则使用
function S:rune_of_power(time)
	if true then
		-- 实际战斗千奇百怪 要是强制执行这个技能 太伤人了……
		return false;
	end
	if OvaleSpellBook:GetTalentPoints(116011)<=0 then
		return false;
	end
	time = time or D:GetSpellCostTime("能量符文");
	if WA_CheckSpellUsable("能量符文") and WA_CheckBuff("能量符文",time) then
		CCFlagSpell("能量符文");
		return true;
	end
	return false;
end

function S:Bomb(castms)
	if CC_Raid_ShouldDMGWithoutKO() then
		return false;
	end
	--虚空风暴在最后一跳前刷新
	--活动炸弹在最后一跳前后刷新，不会损失爆炸伤害
	--卡CD使用寒冰炸弹
	if( WA_CheckSpellUsable("活动炸弹") and WA_CheckDebuff("活动炸弹",castms/1000,0,true))then
		--25模式 5w
		--10模式 2w
		--5人模式 8k
		--1人模式 3k
		--可以跳3次 也就是9秒 计算为10秒
		local rnumbers = GetNumGroupMembers();
		local ihp;
		if(rnumbers>17)then
			ihp=1000000;
		elseif(rnumbers>6)then
			ihp=400000;
		elseif(rnumbers==0)then
			ihp=60000;
		else
			ihp=160000;
		end
		if(UnitHealth("target")>ihp  or WA_Is_Boss())then
			CCFlagSpell("活动炸弹");
			return true;
		end
	end

	return false;
end

function S:AllowWork(inputpvp)

	if((not WA_CheckBuff("法术连击")) and WA_CheckSpellUsable("炎爆术")) then
		S.last_zs_time = GetTime();
	end

	if D.Casting.name then
		if D.Casting.name=="灼烧" or D.Casting.name=="炎爆术" then
			S.last_zs_time = GetTime();
		end
		S.last_casting = D.Casting.name;
		if D.Casting.channeling or D.Casting.ttf>D.MaxDelayS then

			if S.Talent and S.Talent.CastingUpdate then

				S.Talent:CastingUpdate();

				end
			return;
		end
	end

	if SpellIsTargeting() then return end

	if S.AutoMageShield then
		if CCShareHoly.isHarm("target") and UnitGUID("targettarget")==UnitGUID("player") and WA_CheckBuff("寒冰护体") and WA_CheckSpellUsable("寒冰护体") then
			CCFlagSpell("寒冰护体");
			return;
		end
	end

	if(((not InCombat)or(not WA_NeedAttack())))then return end

	if S.Talent and S.Talent.WorkUpdate then
		S.Talent:WorkUpdate();
	end

	if((not inputpvp) and CC_Raid_B())then return end

	-- if(UnitIsBeFear("target") or UnitIsNotAbleAttack("target") or UnitIsBeOutControl("target"))then
	-- 	return;
	-- end

	local pvp = UnitIsPlayer("target");
	if(inputpvp)then
		pvp = true;
	end

	if(CCWA_Check_PreToCasts(pvp))then return end

	if(not pvp)then
		if(CC_check_threat_dps())then return end
	end

	if(CC_TargetisWudi())then
		jcmessage("换目标");
		return;
	end

--[[	if(pvp and (CC_PVP_Enable or inputpvp))then
		if(CC_PVP())then return end
	end]]

--[[	if(not CC_InRange())then
		--不在范围 就暂时不管啦
		return;
	end]]

	if(WA_Is_Boss() and UnitName("boss1")~="古加尔" and InCombat and UnitPower("player")/UnitPowerMax("player")<0.89 and UnitRace("player")=="血精灵" and WA_CheckSpellUsable("奥术洪流"))then
		---6%
		CCFlagSpell("奥术洪流");
		return;
	end

	--是否有buf可以偷取
	if(CC_Target_Buf_Stealable(HujiaChecker) and WA_CheckSpellUsable("法术吸取"))then
		CCFlagSpell("法术吸取");
		return;
	end

	return true;
end

function S:UseRanshao()
	S.ToUseRS = not S.ToUseRS;
	if S.ToUseRS then
		jcmessage("允许自动使用燃烧");
	else
		jcmessage("禁止自动使用燃烧");
	end
end

function S:RushDps()
	if CCAutoRush and S:RushPrepose() then
		CCWA_RacePink();

		if S.Talent:Rush() then
			return true;
		end
	end
end

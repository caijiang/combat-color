-- CCDK.lua

local addonName, T = ...;
local D = T.jcc;

local _,clzz = UnitClass("player");
if clzz~="DEATHKNIGHT" then return;end

local K = D:NewModule("DEATHKNIGHT", "AceEvent-3.0", "AceHook-3.0","CCClass-1.0");
D.DEATHKNIGHT = K;

K.RUNETYPE_BLOOD = 1;
K.RUNETYPE_CHROMATIC = 2;
K.RUNETYPE_FROST = 3;
K.RUNETYPE_DEATH = 4;

local mouseovertargetfocus = "/cast [@mouseover,help,nodead][@target,help,nodead][@focus,help,nodead]%s";
K.breakingSpell = "心灵冰冻";--好几个呢……
K.testRangeHitSpell = "鲜血打击";
K.testGCDSpell = "冰霜灵气";
K.ClassSpellDescs = {
	["暗影打击"] = 1,
	["爆发"] = {slot=2,havecd=true},
	["冰冷触摸"] = 3,
	["寒冰锁链"] = 4,
	["黑暗模拟"] = {slot=5,havecd=true},
	["鲜血打击"] = 6,
	["绞袭"] = {slot=7,havecd=true},
	["心灵冰冻"] = {slot=8,havecd=true},
	["凋零缠绕"] = {slot=9,havecd=true},--应该有2个 治疗以及攻击
	["符文武器增效"] = {slot=10,havecd=true},
	["鲜血灵气"] = 11,
	["邪恶灵气"] = 12,
	["冰霜灵气"] = 13,
	["死疽打击"] = 14,
	["反魔法护罩"] = {slot=15,havecd=true},
	["血液沸腾"] = 16,
	["寒冬号角"] = {slot=17,havecd=true},
	["冰封之韧"] = {slot=18,havecd=true},
	["传染"] = 19,
	["死亡之握"] = {slot=20,havecd=true},
	["灵界打击"] = 21,

	["吸血瘟疫"] = {slot=23,havecd=true},
	["邪恶虫群"] = {slot=23,havecd=true},
	["巫妖之躯"] = {slot=24,havecd=true},
	["反魔法领域"] = {slot=24,havecd=true},
	["天灾契约"] = {slot=25,havecd=true},
	["符能转换"] = {slot=25,havecd=true},
	["血魔之握"] = {slot=26,havecd=true},
	["冷酷严冬"] = {slot=26,havecd=true},
	["邪恶之地"] = {slot=26,havecd=true},
	["心灵冰冻M"] = {slot=27,havecd=true,marco="/cast [@mouseover,harm,nodead]心灵冰冻"},
--	["黑暗命令"] = {slot=23,havecd=true},
--	["符文打击"] = 24,
--	["脓疮打击"] = 28,
--["湮没"] = 19,
--["活力分流"] = {slot=5,havecd=true},

};


function K:matchGCD(time)
	return time<=1.5;
end


function K:AllowWork(inputpvp)
	if((not InCombat)or(not WA_NeedAttack()))then return end

	if(CC_Raid_B())then return end

	if(UnitIsBeFear("target") or UnitIsNotAbleAttack("target") or UnitIsBeOutControl("target"))then
		return;
	end

	local pvp = UnitIsPlayer("target");
	if(inputpvp)then
		pvp = true;
	end

	if(CCWA_Check_PreToCasts(pvp))then return end

	if(not pvp and K.TalentType~=1)then
		if(CC_check_threat_dps())then return end
	end

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

	return true;
end

-- 符文信息
-- 返回 BLOODActives,BLOODCdInfo,CHROMATICActives,CHROMATICCDInfo,FROSTActives,FROSTCDInfo,DEATHActives
function K:TunesInfo()
	local nid = 1;
	local cdinfos = {};
	local BLOODActives,CHROMATICActives,FROSTActives,DEATHActives = 0,0,0,0;
	local BLOODCdInfo,CHROMATICCDInfo,FROSTCDInfo = {},{},{};
	while nid<=6 do
		local rt = GetRuneType(nid);
		local CDInfos;
		if rt == K.RUNETYPE_BLOOD then
			CDInfos = BLOODCdInfo;
		elseif rt == K.RUNETYPE_CHROMATIC then
			CDInfos = CHROMATICCDInfo;
		elseif rt == K.RUNETYPE_FROST then
			CDInfos = FROSTCDInfo;
		else
			if nid<=2 then
				CDInfos = BLOODCdInfo;
			elseif nid<=4 then
				CDInfos = CHROMATICCDInfo;
			else
				CDInfos = FROSTCDInfo;
			end

		end
		local start, duration, runeReady = GetRuneCooldown(nid);
		if runeReady then
			if rt == K.RUNETYPE_BLOOD then
				BLOODActives = BLOODActives +1
			elseif rt == K.RUNETYPE_CHROMATIC then
				CHROMATICActives = CHROMATICActives +1
			elseif rt == K.RUNETYPE_FROST then
				FROSTActives = FROSTActives +1
			else
				DEATHActives = DEATHActives +1
			end
		else
			if CDInfos then
				tinsert(CDInfos,{
				start=start,
				duration=duration,
			});
			else
				D:Debug(rt);
			end
		end
		nid = nid+1;
	end
	return BLOODActives,BLOODCdInfo,CHROMATICActives,CHROMATICCDInfo,FROSTActives,FROSTCDInfo,DEATHActives;
end


function K:Haojiao()
	if WA_CheckSpellUsable("寒冬号角") and ((WA_CheckBuff("寒冬号角") and WA_CheckBuff("战斗怒吼") and WA_CheckBuff("大地之力图腾")) or UnitPower("player")<20 ) then
		CCFlagSpell("寒冬号角");
		return true;
	end
	return false;
end

-- CCPRIEST.lua

local addonName, T = ...;
local D = T.jcc;

local _,clzz = UnitClass("player");
if clzz~="PRIEST" then return;end

local S = T.jcc:NewModule("PRIEST", "AceEvent-3.0", "AceHook-3.0","CCClass-1.0");
T.jcc.PRIEST = S;

local mouseovertargetfocus = "/cast [@mouseover,help,nodead][@target,help,nodead][@focus,help,nodead]%s";
S.testGCDSpell = "惩击";
S.ClassSpellDescs = {		
		--精神控制 安抚心灵 心灵视界 束缚亡灵 真言术：韧 暗影防护 ["防护恐惧结界"] ={slot=23,marco=mouseovertargetfocus,havecd=true},
		["惩击"]=1,
		["暗言术：痛"] =2,
		["真言术：盾"] ={slot=3,marco="/cast [@mouseover,help,nodead][@target,help,nodead][@focus,help,nodead][@player,nodead]%s",havecd=true},
		["快速治疗"] ={slot=4,marco=mouseovertargetfocus},
		["渐隐术"] = {slot=5,havecd=true},
		["驱散魔法"] ={slot=6},--只对敌人使用
		["精神灼烧"]=7,
		["束缚亡灵"]=8,
		["暗影魔"] ={slot=9,havecd=true},
		["愈合祷言"] ={slot=10,marco="/cast [@focus,help,nodead]%s",havecd=true},
		["真言术：盾t"] ={slot=11,marco="/cast [@focus,help,nodead]真言术：盾",havecd=true},
		-- 天赋从15开始
		["绝望祷言"]={slot=15,havecd=true},
		["幽灵伪装"]={slot=15,havecd=true},
		
		["摧心魔"] ={slot=16,havecd=true},
		["真言术：慰"] ={slot=16,havecd=true},--治疗
		
		["心灵尖啸"]={slot=17,havecd=true},
		["统御意志"]={slot=17,havecd=true},
		["虚空触须"]={slot=17,havecd=true},
		
		["能量灌注"] ={slot=18,havecd=true},
		["灵魂护壳"] ={slot=18,havecd=true},--戒律ONLY
		
		["瀑流"] ={slot=19,havecd=true,marco=mouseovertargetfocus},
		["神圣之星"] ={slot=19,havecd=true},
		["光晕"] ={slot=19,havecd=true},		
		
		["救赎恩惠"] ={slot=20}, --治疗ONLY
		["意志洞悉"] ={slot=20},--戒律ONLY
		["清晰使命"] ={slot=20}, --神圣 ONLY
		["虚空熵能"] ={slot=20},--暗影ONLY		
};

function S:matchGCD(time)
	return time<=1.5;
end

S.last_xxgz_time = 0;

function S:AllowWork(inputpvp)

	if D.Casting.name=="吸血鬼之触" then
		S.last_xxgz_time = GetTime();
	end

	if(S.TalentType==3 and ((not InCombat)or(not WA_NeedAttack())))then return end

	if((not inputpvp) and CC_Raid_B())then
		D:Debug("CC_Raid_B STOP!!");
		return;
	end

	if(S.TalentType==3 and UnitIsBeFear("target") or UnitIsNotAbleAttack("target") or UnitIsBeOutControl("target"))then
		return;
	end

	local pvp = UnitIsPlayer("target");
	if(inputpvp)then
		pvp = true;
	end

	if(CCWA_Check_PreToCasts(pvp))then
		D:Debug("CCWA_Check_PreToCasts STOP!!");
		return;
	end

	if(not pvp and S.TalentType==3)then
		if(CC_check_threat_dps())then return end
	end

	if(S.TalentType==3 and CC_TargetisWudi())then		
		jcmessage("换目标");
		return;
	end

	return true;
end

function S:RushDps()	
end


-------------疾病监控！
S.FlameShocks = {};
-- 脱离
--[[
]]
function S:PLAYER_REGEN_ENABLED()
	--D:Error("脱离战斗，覆盖了原有函数");
	S.FlameShocks = {};
	if self.Talent and self.Talent.PLAYER_REGEN_ENABLED then
		self.Talent:PLAYER_REGEN_ENABLED();
	end
end

function S:AddFlameShock(guid)	
	tinsert(S.FlameShocks,guid);
	--D:Error("增加了一个烈焰震击目标",guid," 目前数量:",#S.FlameShocks);
end

function S:RmoveFlameShock(guid)
	for index,value in ipairs(S.FlameShocks) do
		if value==guid then
			tremove(S.FlameShocks,index);
		end
	end
end

function S:SPELL_AURA_APPLIED(timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName, spellSchool, auraType, amount)
	if sourceGUID==UnitGUID("player") and spellId==2944 then
		S:AddFlameShock(destGUID);
	end
end


function S:SPELL_AURA_REMOVED(timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName, spellSchool, auraType, amount)
	if sourceGUID==UnitGUID("player") and spellId==2944 then
		S:RmoveFlameShock(destGUID);
	end
end


function S:UnitOffline(GUID)
	S:RmoveFlameShock(GUID);
end
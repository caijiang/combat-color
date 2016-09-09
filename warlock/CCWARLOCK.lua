-- CCWARLOCK.lua

--

local addonName, T = ...;
local D = T.jcc;

local _,clzz = UnitClass("player");
if clzz~="WARLOCK" then return;end

local W = T.jcc:NewModule("WARLOCK", "AceEvent-3.0", "AceHook-3.0","CCClass-1.0");
T.jcc.WARLOCK = W;

--W.breakingSpell = "拳击";
--W.testRangeHitSpell = "撕裂";
W.testGCDSpell = "暗影箭";
W.ClassSpellDescs = {
		["暗影箭"] =1,
		["腐蚀术"] =2,
		--["吸取生命"]=3,
		--["痛苦无常"] =4,--?
		--["痛苦无常F"] ={slot=5,havecd=false,marco="/cast [@focus]痛苦无常"},
		["恐惧"] = {slot=3,havecd=false},
		["放逐术"] = {slot=4,havecd=false},
		--	
		--["暮光结界"] ={slot=10,havecd=true},--?
		--["痛楚"] =11,--?
		--["元素诅咒"]={slot=12,havecd=false},
		--["腐蚀之种"] = {slot=13,havecd=false},
		["不灭决心"] ={slot=5,havecd=true},
		--["邪焰"] = {slot=15,havecd=false},
		["腐蚀术F"] ={slot=6,havecd=false,marco="/cast [@focus]腐蚀术"},
		--["生命分流"]={slot=17,havecd=false},
		--["虚弱诅咒"] = 19,	
		--["生命通道"] = 20,--?
		--["召唤末日守卫"] = {slot=21,havecd=true},

		["死亡缠绕"] ={slot=10,havecd=true},
		["恐惧嚎叫"] ={slot=10,havecd=true},
		["暗影之怒"] ={slot=10,havecd=true},
		["牺牲契约"] ={slot=11,havecd=true},
		["黑暗交易"] ={slot=11,havecd=true},
		["猩红恐惧"] ={slot=12,havecd=true},
		["爆燃冲刺"] ={slot=12,havecd=true},
		["无拘意志"] ={slot=12,havecd=true},
		["魔典：邪恶统御"] = {slot=13,havecd=true},
		["魔典：邪恶仆从"] = {slot=13,havecd=true},
		["魔典：恶魔牺牲"] = {slot=13,havecd=true},
		["玛诺洛斯的狂怒"] = {slot=14,havecd=true},
		["基尔加丹的狡诈"] = {slot=14,havecd=true},
		["大灾变"] = {slot=15,havecd=true},
		["恶魔之箭"] = {slot=15,havecd=true},		
	};

W.last_xj_time = 0;

function W:xj(unit)
	local _, _, _, castTime = GetSpellInfo("献祭");
	--90 buf
	local buf90add = 0;
	if UnitLevel("player")>=90 then
		buf90add = 5;
	end
	if D:CastReadable("献祭") and WA_CheckDebuff("献祭",castTime/1000+buf90add,0,true,unit) and WA_CheckSpellUsable("献祭",unit) and GetTime()-W.last_xj_time>2 then
		if unit=="focus" then
			CCFlagSpell("献祭F");
		else
			CCFlagSpell("献祭");
		end
		return true;
	end
end

function W:fs(unit)
	--腐蚀术或者腐蚀之种
	local totime = 9;
	if not D:CastReadable() then
		totime = 4;
	end
	if CC_reckon_target_liveon(totime,unit) then
		if WA_CheckSpellUsableOn("腐蚀术",unit) and WA_CheckDebuff("腐蚀术",0,0,true,unit) then
			if unit=="focus" then
				CCFlagSpell("腐蚀术F");
			else
				CCFlagSpell("腐蚀术");
			end
			return true;
		end
	end
end

function W:zh(unit)
	--[[if #W.FlameShocks>0 then
		return;
	end]]
	local totime = 15;
	--local timex = 1;
	if unit=="focus" then
		if WA_CheckSpellUsableOn("浩劫",unit) and WA_CheckDebuff("浩劫",0,0,true,unit) then
			CCFlagSpell("浩劫");
			return true;
		end
	end
	if not D:CastReadable() then
		totime = 7;
	end
	if CC_reckon_target_liveon(totime,unit) then
		--[[if WA_CheckSpellUsableOn("末日灾祸",unit) and WA_CheckDebuff("末日灾祸",0,0,true,unit) then
			if unit=="focus" then
				CCFlagSpell("末日灾祸F");
			else
				CCFlagSpell("末日灾祸");
			end
			return true;
		end
		if not WA_CheckSpellUsable("末日灾祸",unit) and WA_CheckDebuff("末日灾祸",0,0,true,unit) and WA_CheckDebuff("痛苦无常",0,0,true,unit) and WA_CheckSpellUsableOn("痛苦无常",unit) then
			if unit=="focus" then
				CCFlagSpell("痛苦无常F");
			else
				CCFlagSpell("痛苦无常");
			end
			return true;
		end]]
	end	
end


function W:AllowWork(inputpvp)
	if D.Casting.name then
		if D.Casting.name=="献祭" then
			W.last_xj_time = GetTime();
		end
		W.last_casting = D.Casting.name;
		if D.Casting.channeling or D.Casting.ttf>0.3 then
			return;
		end
	end

	if SpellIsTargeting() then return end

	if D.MAGE and D.MAGE.AutoMageShield then
		if CCShareHoly.isHarm("target") and WA_CheckBuff("暮光结界") and WA_CheckSpellUsable("暮光结界") then
			CCFlagSpell("暮光结界");
			return;
		end
	end

	--[[if WA_CheckBuff("黑暗意图") and WA_CheckSpellUsable("黑暗意图") and CCShareHoly.isHelp("pet") then
		jcmessage("黑暗意图点上！");
	end]]

	--if not InCombat then return end

	if((not InCombat)or(not WA_NeedAttack()))then return end

	if((not inputpvp) and CC_Raid_B())then return end

	if(UnitIsBeFear("target") or UnitIsNotAbleAttack("target") or UnitIsBeOutControl("target"))then
		return;
	end

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

	if(WA_Is_Boss() and UnitName("boss1")~="古加尔" and InCombat and UnitPower("player")/UnitPowerMax("player")<0.89 and UnitRace("player")=="血精灵" and WA_CheckSpellUsable("奥术洪流"))then
		---6%
		CCFlagSpell("奥术洪流");
		return;
	end

	if WA_Is_Boss() and not D:InFashuyishang() and WA_CheckSpellUsable("元素诅咒") then
		CCFlagSpell("元素诅咒");
		return;
	end

	return true;
end



W.FlameShocks = {};

function W:PLAYER_REGEN_ENABLED()
	W.FlameShocks = {};
end

function W:AddFlameShock(guid)	
	tinsert(W.FlameShocks,guid);
end

function W:RmoveFlameShock(guid)
	for index,value in ipairs(W.FlameShocks) do
		if value==guid then
			tremove(W.FlameShocks,index);
		end
	end
end

function W:SPELL_AURA_APPLIED(timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName, spellSchool, auraType, amount)
	if sourceGUID==UnitGUID("player") and (spellId==603 or spellId==980 or spellId==80240) then
		--W:AddFlameShock(destGUID);
	end
end


function W:SPELL_AURA_REMOVED(timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName, spellSchool, auraType, amount)
	if sourceGUID==UnitGUID("player") and (spellId==603 or spellId==980 or spellId==80240) then
		W:RmoveFlameShock(destGUID);
	end
end

function W:UnitOffline(GUID)
	W:RmoveFlameShock(GUID);
end

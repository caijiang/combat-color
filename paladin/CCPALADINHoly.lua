-- CCPALADINHoly.lua

--祈愿  圣闪必爆

local addonName, T = ...;
local D = T.jcc;

local _,clzz = UnitClass("player");
if clzz~="PALADIN" then return;end

local Q = D.PALADIN;

local H = Q:NewModule("PALADIN1", "AceEvent-3.0", "AceHook-3.0","CCTalent-1.0");

local mouseovertargetfocus = "/cast [@mouseover,help,nodead][@target,help,nodead][@focus,help,nodead]%s";

H.TalentSpellDescs = {
	["神圣震击"] = {slot=31,havecd=true,marco=mouseovertargetfocus},
	["谴责"] = 32,
	["圣光术"] = {slot=33,marco=mouseovertargetfocus},
	["圣光普照"] = {slot=34,marco=mouseovertargetfocus},
	["圣光道标"] = {slot=35,marco="/cast [@focus,help,nodead]%s"},
	["神圣恳求"] = {slot=36,havecd=true},
	["神圣之光"] = {slot=37,marco=mouseovertargetfocus},
	["黎明圣光"] = 38,
	["远古列王守卫"] = {slot=39,havecd=true},
	["神恩术"] = {slot=40,havecd=true},
	["审判H"] = {slot=41,marco="/cast [@target,harm,nodead][@mouseovertarget,harm,nodead][@targettarget,harm,nodead][@focustarget,harm,nodead][@boss1,harm,nodead][@boss2,harm,nodead][@boss3,harm,nodead][@boss4,harm,nodead]审判"},
	["神圣震击A"] = {slot=42,havecd=true,marco="/cast 神圣震击"},
}


local bossId = {};
for i = 1, 4 do
	bossId[i] = format("boss%d", i)
end


local last_yc_time;
local auto_break_when_override = true

local function CCSQHL_Rush()
	if(WA_CheckBuff("复仇之怒") and WA_CheckBuff("神恩术") and WA_CheckBuff("远古列王守卫") and WA_CheckBuff("神圣复仇者"))then
		--2者都没有才考虑开启！
		if(WA_CheckSpellUsable("远古列王守卫"))then
			CCFlagSpell("远古列王守卫");
			return true;
		end
		if(WA_CheckSpellUsable("神恩术"))then
			CCFlagSpell("神恩术");
			return true;
		end
		if(WA_CheckSpellUsable("复仇之怒"))then
			CCFlagSpell("复仇之怒");
			return true;
		end
		if(WA_CheckSpellUsable("神圣复仇者"))then
			CCFlagSpell("神圣复仇者");
			return true;
		end
	end
	return false;
end

local secondPrintss = 0;
function secondPrint(s)
	if(secondPrintss==0)then
		print(s);
	end
	secondPrintss = secondPrintss+1;
	if(secondPrintss>=25)then
		secondPrintss = 0;
	end
end


function H:Work(safehp,tankhp)
	--if((not InCombat))then return end


	-- (GetPartyAssignment("MAINTANK"))  raid
	-- UnitGroupRolesAssigned tank

	local mytank = "focus";


	--先确定我的目标
	local mytarget = "focus";
	if(CCShareHoly.isHelp("mouseover"))then
		mytarget = "mouseover";
	elseif(CCShareHoly.isHelp("target"))then
		mytarget = "target";
	end

	if(CCWA_Check_PreToCasts())then return end

	local noaoe = (CCShareHoly.isHelp(mytank) and CCShareHoly.raid_noLittleHeal(mytank)) or (CCShareHoly.isHelp(mytarget) and CCShareHoly.raid_noLittleHeal(mytarget));


	--而且是tank
	--
	if(InCombat and UnitGUID(mytarget)==UnitGUID(mytank) and WA_CheckBuff("神圣恳求") and CCShareHoly.isHelp(mytarget) and CCShareHoly.isGoingDead(mytarget,safehp,0.1) and IsSpellInRange("圣疗术", mytarget)==1)then
		if(WA_CheckSpellUsable("圣疗术"))then
			CCFlagSpell("圣疗术");
			return;
		end
	end

	--- endTime 是毫秒 GetTime() 是秒
	local spell, _, _, _, startTime, endTime = UnitCastingInfo("player");

	local isHolySpell = false;
	local sp = UnitPower("player",SPELL_POWER_HOLY_POWER);
	if(spell)then
		if spell=="圣光普照" then
			sp = sp +1;
			-- todo 圣光普照也可以打断！
		end
		isHolySpell = (spell=="圣光术" or spell=="圣光闪现" or spell=="神圣之光");
		if(isHolySpell)then
			CCShareHoly.updateDutiaoTarget(startTime);
		end
		local timeToFinish = endTime - GetTime()*1000;
--		if(timeToFinish>100)then
--			return
--		end

		if(isHolySpell)then
			local mysftarget = CCShareHoly.GetCurrentDutiaoUnitid();
			if(mysftarget)then
				if(CCShareHoly.isYichu(mysftarget,spell,endTime)
					and (not CCShareHoly.isHolyAble(mytank,2))
					and not CCShareHoly.raid_quickdirectNeedable(mysftarget)
					)then
					if(auto_break_when_override)then
						--print("准备打断 只是时间未到");
						if(timeToFinish<500)then
							CCFlagSpell("打断");
						end
					else
						jcmessage(UnitName(mysftarget).."已溢出，请打断当前施法！");
						last_yc_time = GetTime();
					end
				end
			end
		end
		if(timeToFinish>=500)then
			return;
		end
	end

	local manrate = UnitPower("player")/UnitPowerMax("player");

	if(UnitName("boss1")~="古加尔" and UnitName("boss1")~="不眠的约萨希" and InCombat and manrate<0.93 and UnitRace("player")=="血精灵" and WA_CheckSpellUsable("奥术洪流"))then
		---6%
		CCFlagSpell("奥术洪流");
		return;
	end

	if(InCombat and CCAutoRush and manrate<0.8)then
		CCShareHoly.check_user_invslot_huilan(INVSLOT_TRINKET1);
		CCShareHoly.check_user_invslot_huilan(INVSLOT_TRINKET2);
	end

	--没有道标
	if(CCShareHoly.isHelp(mytank) and WA_CheckBuff("圣光道标",2,0,true,mytank) and IsSpellInRange("圣光道标", mytank)==1)then
		CCFlagSpell("圣光道标");
		return;
	end


	if CCShareHoly.isHelp(mytarget) and D:ShouldQusan(mytarget,{"DISEASE","MAGIC","POISON"}) and WA_CheckSpellUsable("清洁术") and IsSpellInRange("清洁术", mytarget)==1 then
		CCFlagSpell("清洁术");
		return;
	end
	if CCShareHoly.isHelp(mytarget) and D:ShouldQusan(mytarget,{"DISEASE","POISON"}) and WA_CheckSpellUsable("清洁术") and IsSpellInRange("清洁术", mytarget)==1 then
		CCFlagSpell("清洁术");
		return;
	end

	if(mytarget=="focus" and not noaoe and sp>=3 and WA_CheckBuff("神圣恳求") )then
		if(CCShareHoly.isHolyAbleCrow(mytarget,false,30,1.5,3) and WA_CheckSpellUsable("黎明圣光"))then
			CCFlagSpell("黎明圣光");
			return;
		end
	end

	if(not noaoe and sp>=3 and CCFightType==2 and WA_CheckBuff("神圣恳求") )then
		if(CCShareHoly.isHolyAbleCrow(mytarget,false,30,1.5,2) and WA_CheckSpellUsable("黎明圣光"))then
			CCFlagSpell("黎明圣光");
			return;
		end
	end

	if(sp<5 and (not WA_CheckBuff("破晓")) and WA_CheckSpellUsable("神圣震击") and CCShareHoly.isHelp(mytarget) and CCShareHoly.isHolyAbleCrow(mytarget,false,10,1,4) )then
		CCFlagSpell("神圣震击");
		return;
	end

	--CCShareHoly.isHelp(mytarget) and (not CCShareHoly.isYichu(mytarget,spell,endTime)) and CCShareHoly.isHolyAble(mytarget,1)
	if not noaoe and D:CastReadable() and sp<5 and WA_CheckBuff("神圣恳求") and CCFightType==2 and CCShareHoly.isHelp(mytarget) and CCShareHoly.isHolyAbleCrow(mytarget,false,10,2,4) and WA_CheckSpellUsable("圣光普照") then
		CCFlagSpell("圣光普照");
		return;
	end

	if CCFightType==2 and not noaoe and WA_CheckBuff("神圣恳求") then
		local hrate = CCShareHoly.RaidHealth()/CCShareHoly.RaidHealthMax();
		if hrate<0.7 and sp>=3 and WA_CheckSpellUsable("黎明圣光") then
			CCFlagSpell("黎明圣光");
			return;
		end

		if(sp<5 and (not WA_CheckBuff("破晓")) and WA_CheckSpellUsable("神圣震击") and hrate<0.9 )then
			CCFlagSpell("神圣震击");
			return;
		end

		if hrate<0.7 and sp<5 and CCShareHoly.isHelp(mytarget) and D:CastReadable() and WA_CheckSpellUsable("圣光普照") then
			CCFlagSpell("圣光普照");
			return;
		end

		if sp>=5 then
			jcmessage("5豆已满！");
		end
	end

	--首先检测 坦克是否大出血 得到确定以后 立刻以最大的技能治疗坦克
	--然后检测频危 圣疗术
	--然后是是否快挂了
	--最后是无聊刷血


	local targethpincomingrate = (UnitHealth(mytarget)+(UnitGetIncomingHeals(mytarget) or 0))/UnitHealthMax(mytarget);

	D:Debug(mytarget,CCShareHoly.isHelp(mytarget),CCShareHoly.isDanger(mytarget,safehp),IsSpellInRange("圣光术", mytarget)==1);
	if(WA_CheckBuff("神圣恳求") and CCShareHoly.isHelp(mytarget) and CCShareHoly.isDanger(mytarget,safehp) and IsSpellInRange("圣光术", mytarget)==1)then
		if(last_yc_time and GetTime()-last_yc_time<5)then
			last_yc_time = nil;
			CombatColorMessageFrame:Clear()
		end

		if( D:CastReadable() and spell~="圣光闪现" and (not WA_CheckBuff("无私治愈",1,3)) and WA_CheckSpellUsable("圣光闪现"))then
			CCFlagSpell("圣光闪现");
			CCShareHoly.setLastDuTiaoTarget(mytarget)
			return;
		end

		if( D:CastReadable() and (not WA_CheckBuff("圣光灌注")) and WA_CheckSpellUsable("神圣之光"))then
			CCFlagSpell("神圣之光");
			CCShareHoly.setLastDuTiaoTarget(mytarget)
			return;
		end

		if(sp>=3 and CCFightType==1 and Q:useShengling())then
			return;
		end
		if(not CCShareHoly.raid_noLittleHeal(mytarget) and WA_CheckSpellUsable("神圣震击"))then
			CCFlagSpell("神圣震击");
			return;
		end

		if(InCombat and CCAutoRush and CCSQHL_Rush())then return end;

		if(not InCombat)then
			if(not CCShareHoly.raid_noLittleHeal(mytarget) and D:CastReadable() and WA_CheckSpellUsable("圣光术"))then
				CCFlagSpell("圣光术");
				CCShareHoly.setLastDuTiaoTarget(mytarget)
				return;
			end
		end

		if(not CCShareHoly.raid_noLittleHeal(mytarget) and D:CastReadable() and targethpincomingrate<0.1 and WA_CheckSpellUsable("圣光闪现"))then
			if(WA_CheckBuff("芬克的混合剂",0,0,nil,mytarget))then
				CCFlagSpell("圣光闪现");
			else
				CCFlagSpell("圣光术");
			end
			CCShareHoly.setLastDuTiaoTarget(mytarget)
			return;
		end

		if(D:CastReadable() and WA_CheckSpellUsable("神圣之光"))then
			CCFlagSpell("神圣之光");
			CCShareHoly.setLastDuTiaoTarget(mytarget)
			return;
		end
--		jcmessage("没蓝了！")
		--没蓝了 圣疗 可以回蓝！
	end

	if(not noaoe and sp>=3 and WA_CheckBuff("神圣恳求") )then
		if(CCShareHoly.isHolyAbleCrow(mytarget,false,30,1.5,3) and WA_CheckSpellUsable("黎明圣光"))then
			CCFlagSpell("黎明圣光");
			return;
		end
	end

	--目标 鼠标目标 目标目标 焦点目标 boss1-4
	local mysptarget = "target";
	if(CCShareHoly.isHarm("target") and IsSpellInRange("审判", "target")==1)then
		mysptarget = "target";
	elseif(CCShareHoly.isHarm("mouseovertarget") and IsSpellInRange("审判", "mouseovertarget")==1)then
		mysptarget = "mouseovertarget";
	elseif(CCShareHoly.isHarm("targettarget") and IsSpellInRange("审判", "targettarget")==1)then
		mysptarget = "targettarget";
	elseif(CCShareHoly.isHarm("focustarget") and IsSpellInRange("审判", "focustarget")==1)then
		mysptarget = "focustarget";
	else
		for i = 1, 4 do
			if(CCShareHoly.isHarm(bossId[i]) and IsSpellInRange("审判", bossId[i])==1)then
				mysptarget=bossId[i];
				break;
			end
		end
	end

	--选择一个目标审判
	--点了无私 再考虑 使用审判!
	local _,_,_,_,wusied = GetTalentInfo(7);
	if(wusied and CCFightType==1 and InCombat and CCShareHoly.isHarm(mysptarget) and WA_CheckSpellUsable("审判") and IsSpellInRange("审判", mysptarget)==1 and UnitPowerMax("player")-UnitPower("player")>3000)then
		CCFlagSpell("审判H");
		return;
	end

	if not noaoe and D:CastReadable() and sp<5 and WA_CheckBuff("神圣恳求") and CCShareHoly.isHelp(mytarget) and CCShareHoly.isHolyAbleCrow(mytarget,false,10,2,4) and WA_CheckSpellUsable("圣光普照") then
		CCFlagSpell("圣光普照");
		return;
	end

	--别让自己的治疗溢出
	if(WA_CheckBuff("神圣恳求") and CCShareHoly.isHelp(mytarget) and (not CCShareHoly.isYichu(mytarget,spell,endTime)) and IsSpellInRange("圣光术", mytarget)==1)then
		if(last_yc_time and GetTime()-last_yc_time<5)then
			last_yc_time = nil;
			CombatColorMessageFrame:Clear()
		end

		if( CCShareHoly.isHolyAble(mytarget,4) and D:CastReadable() and spell~="圣光闪现" and (not WA_CheckBuff("无私治愈",1,3)) and WA_CheckSpellUsable("圣光闪现"))then
			CCFlagSpell("圣光闪现");
			CCShareHoly.setLastDuTiaoTarget(mytarget)
			return;
		end

		if((CCShareHoly.isHolyAble(mytarget,4) or targethpincomingrate<0.6) and sp>=3 and CCFightType==1 and Q:useShengling() )then
			return;
		end

		-- and sp<5
		if(not CCShareHoly.raid_noLittleHeal(mytarget) and (CCShareHoly.isHolyAble(mytarget,0.5) or targethpincomingrate<0.7) and WA_CheckSpellUsable("神圣震击"))then
			CCFlagSpell("神圣震击");
			return;
		end

		if(CCShareHoly.isHolyAble(mytarget,5))then
			if(D:CastReadable() and WA_CheckSpellUsable("神圣之光"))then
				CCFlagSpell("神圣之光");
				CCShareHoly.setLastDuTiaoTarget(mytarget)
				return;
			end
		end

		if(not CCShareHoly.raid_noLittleHeal(mytarget) and CCShareHoly.isHolyAble(mytarget,2))then
			if(D:CastReadable() and WA_CheckSpellUsable("圣光术"))then
				CCFlagSpell("圣光术");
				CCShareHoly.setLastDuTiaoTarget(mytarget)
				return;
			end
		end
		--有buf 时  圣光术
		--有buf 时  神圣震击
		--荣耀圣令 是否要加入无聊循环？
	end

	--raid
	if(WA_CheckBuff("神圣恳求") and CCShareHoly.isHelp(mytarget) and IsSpellInRange("圣光术", mytarget)==1 and CCShareHoly.raid_quickdirectNeedable(mytarget))then
		if WA_CheckSpellUsable("神圣震击") then
			CCFlagSpell("神圣震击");
			return;
		end
		if(D:CastReadable() and WA_CheckSpellUsable("圣光术"))then
			CCFlagSpell("圣光术");
			CCShareHoly.setLastDuTiaoTarget(mytarget)
			return;
		end
	end

	if InCombat and CCShareHoly.raid_noLittleHeal(mytarget) and CCShareHoly.isHarm("target") and sp<5 and WA_CheckSpellUsableOn("神圣震击") then
		CCFlagSpell("神圣震击A");
		return;
	end
--[[]]
end

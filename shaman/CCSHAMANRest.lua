-- CCSHAMANRest.lua


local addonName, T = ...;
local D = T.jcc;

local _,clzz = UnitClass("player");
if clzz~="SHAMAN" then return;end

local S = D.SHAMAN;

local H = S:NewModule("SHAMAN3", "AceEvent-3.0", "AceHook-3.0","CCTalent-1.0");

local mouseovertargetfocus = "/cast [@mouseover,help,nodead][@target,help,nodead][@focus,help,nodead]%s";

H.TalentSpellDescs = {
	["激流"] = {slot=30,havecd=true,marco=mouseovertargetfocus},
	["治疗波"] ={slot=31,marco=mouseovertargetfocus},
	["大地之盾"] = {slot=32,marco="/cast [@focus,help,nodead]%s"},
	["强效治疗波"] ={slot=33,marco=mouseovertargetfocus},
	--["自然迅捷"] = {slot=42,havecd=true,marco="/cast 自然迅捷\n/cast [@mouseover,help,nodead][@target,help,nodead][@focus,help,nodead]强效治疗波"},
	--["法力之潮图腾"] = {slot=43,havecd=true},
	--["灵魂链接图腾"] = {slot=44,havecd=true},
	
}

local useqiangxiaobs = 8;

local touseddzy = false;

function CC_SM_DDZY()
	touseddzy = true;
end

function H:PLAYER_REGEN_ENABLED()
	touseddzy = false;
end

function H:Work(safehp,tankhp)

	local mytank = "focus";
	local _,_,_,_,moliurank = GetTalentInfo(3,16);
	local manrate = UnitPower("player")/UnitPowerMax("player");

	--先确定我的目标
	local mytarget = "focus";
	if(CCShareHoly.isHelp("mouseover"))then
		mytarget = "mouseover";
	elseif(CCShareHoly.isHelp("target"))then
		mytarget = "target";
	end
	if(CCWA_Check_PreToCasts())then return end

	--[[if(InCombat and WA_CheckSpellUsable("自然迅捷") and UnitGUID(mytarget)==UnitGUID(mytank) and CCShareHoly.isHelp(mytarget) and CCShareHoly.isGoingDead(mytarget,safehp,0.2) and IsSpellInRange("治疗波", mytarget)==1)then
		CCFlagSpell("自然迅捷");
		return;
	end]]
	
	local spell, _, _, _, startTime, endTime = UnitCastingInfo("player");

	local isHolySpell = false;
	if SpellIsTargeting() then
		touseddzy = false;
		return;
	end

	local noaoe = (CCShareHoly.isHelp(mytank) and CCShareHoly.raid_noLittleHeal(mytank)) or (CCShareHoly.isHelp(mytarget) and CCShareHoly.raid_noLittleHeal(mytarget));

	if(spell)then
		if spell=="治疗之雨" then
			touseddzy = false;
		end
		isHolySpell = (spell=="治疗波" or spell=="治疗之涌" or spell=="强效治疗波");-- or spell=="治疗链"
		if(isHolySpell)then
			CCShareHoly.updateDutiaoTarget(startTime);
		end
		local timeToFinish = endTime - GetTime()*1000;
--		if(timeToFinish>100)then
--			return
--		end
			--是否打断当前施法
			--[[
		1: 当前施法对象已溢出 而不是当前对象已溢出
		2: 当前坦克未溢出
		3: 剩余时间尽量的少
		]]
		if(isHolySpell)then
			local mysftarget = CCShareHoly.GetCurrentDutiaoUnitid();
			if(mysftarget)then
				D:Debug("对象",mysftarget," 溢出？",CCShareHoly.isYichu(mysftarget,spell,endTime),"时间",timeToFinish);
				if(CCShareHoly.isYichu(mysftarget,spell,endTime) and not CCShareHoly.isDanger(mysftarget,safehp) )then
					--print("准备打断 只是时间未到");
					if(timeToFinish<200)then
						CCFlagSpell("打断");
					end
				end
			end
		end
		if WA_CheckSpellUsable("强效治疗波") and IsSpellInRange("治疗波", mytarget)==1 and spell=="闪电箭" and CCShareHoly.isHelp(mytarget) and ( CCShareHoly.isHolyAble(mytarget,useqiangxiaobs) or CCShareHoly.isDanger(mytarget,safehp)) then
			CCFlagSpell("打断");
		end
		if(timeToFinish>=500)then
			return;
		end
	end

	if touseddzy then
		local _,_,_,_,zhuangzhudxrank = GetTalentInfo(3,6);
		if (not D:CastReadable()) or (not WA_CheckSpellUsable("治疗之雨"))then	
			--D:Error(" cd 了 取消！",D:CastReadable(),WA_CheckSpellUsable("治疗之雨"));
			touseddzy = false;
			D:Error("取消3");
			return;
		end
		if not WA_CheckBuff("专注洞悉") or not CCShareHoly.isHarm("target")
			or not WA_CheckSpellUsableOn("烈焰震击")
			or zhuangzhudxrank==0 then
			CCFlagSpell("治疗之雨");
			return;
		end
		CCFlagSpell("烈焰震击");
		return;
	end

--[[	if not noaoe and D:CastReadable() and CCFightType==2 and WA_CheckSpellUsable("治疗之雨") and not WA_CheckBuff("专注洞悉") then
		CCFlagSpell("治疗之雨");
		return;
	end]]
		
	if InCombat and S:CheckTotem(S.SpellIDs.CallofAncestors) then
		return;
	end

--[[	if(InCombat and not S:TotemActive(1,1)  and  WA_CheckSpellUsable("先祖的召唤"))then
		CCFlagSpell("先祖的召唤");
		return;
	end
	if(not S:TotemActive(1,1)  and  WA_CheckSpellUsable("灼热图腾"))then
		CCFlagSpell("灼热图腾");
		return;
	end]]


	if(WA_CheckSpellUsable("水之护盾") and WA_CheckBuff("水之护盾") and WA_CheckBuff("闪电之盾") and WA_CheckBuff("大地之盾"))then
		CCFlagSpell("水之护盾");
		return;
	end

	if(InCombat and CCAutoRush and manrate<0.8)then
		CCShareHoly.check_user_invslot_huilan(INVSLOT_TRINKET1);
		CCShareHoly.check_user_invslot_huilan(INVSLOT_TRINKET2);
	end

	if(CCShareHoly.isHelp(mytank) and WA_CheckBuff("大地之盾",2,0,false,mytank) and IsSpellInRange("大地之盾", mytank)==1)then
		CCFlagSpell("大地之盾");
		return;
	end
	
	local qstypes = {"CURSE"};
	local _,_,_,_,qsmofa = GetTalentInfo(3,12);
	if qsmofa>0 then
		qstypes = {"CURSE","MAGIC"};
	end
	

	if CCShareHoly.isHelp(mytarget) and D:ShouldQusan(mytarget,qstypes) and WA_CheckSpellUsable("净化灵魂") and IsSpellInRange("净化灵魂", mytarget)==1 then
		CCFlagSpell("净化灵魂");
		return;
	end

	local targethpincomingrate = (UnitHealth(mytarget)+(UnitGetIncomingHeals(mytarget) or 0))/UnitHealthMax(mytarget);

	--DS H7的时候 激流只给血浆
	if CCFightType==1 and (not noaoe and WA_CheckSpellUsable("激流") and CCShareHoly.isHelp(mytarget) and WA_CheckBuff("激流",1,0,true,mytarget) and (not CCShareHoly.isYichu(mytarget,spell,endTime)) and IsSpellInRange("激流", mytarget)==1 and CCShareHoly.isHolyAble(mytarget,4) )then
		CCFlagSpell("激流");
		return;
	end

	--local _,_,_,_,zhuangzhudxrank = GetTalentInfo(3,6);
	--首先判断应该施展治疗之雨的条件
	--所在小队掉血1bs以上即可施展 
	--当然 如果拥有 专注洞悉 buf 目标无法攻击 无法使用震击 就直接使用治疗之雨 zhuangzhudxrank==0
	--[[if not noaoe and D:CastReadable() and CCFightType==2 and WA_CheckSpellUsable("治疗之雨") then
		if not WA_CheckBuff("专注洞悉")  then
			CCFlagSpell("治疗之雨");
			return;
		end
		if CCShareHoly.isHolyAbleCrow(mytarget,false,25,1,4) and (
			not WA_CheckBuff("专注洞悉") 
			or not CCShareHoly.isHarm("target")
			or not WA_CheckSpellUsableOn("烈焰震击")
			or zhuangzhudxrank==0
			) then
			CCFlagSpell("治疗之雨");
			return;
		end

		if CCShareHoly.isHolyAbleCrow(mytarget,false,25,1,4) and CCShareHoly.isHarm("target") and zhuangzhudxrank>0 and WA_CheckSpellUsableOn("烈焰震击") then
			CCFlagSpell("烈焰震击");
			return;
		end
	end]]
	----------------治疗之雨 结束


	local zzborzzl = "治疗波";
	if CCFightType==2 and not CCShareHoly.raid_noLittleHeal(mytarget) then
		zzborzzl = "治疗链";
	end

	local zzborzzl2 = "强效治疗波";
	if CCFightType==2 and not CCShareHoly.raid_noLittleHeal(mytarget) then
		zzborzzl2 = "治疗链";
	end

	if(CCShareHoly.isHelp(mytarget) and CCShareHoly.isDanger(mytarget,safehp) and IsSpellInRange("治疗波", mytarget)==1)then
		--激流很好，可以提供不错的HOT治疗，同时也可以提供两次波涛汹涌的BUFF，来加速你的治疗波/强效治疗波，或者提高你的治疗之涌的暴击
		--强效治疗波是一个被安排到刷T任务时候的常用治疗手段，高蓝耗并且高治疗量，也可在拥有波涛汹涌BUFF的情况下点刷起危急的目标
		--常见于释放元素武器后加上强效治疗波用于刷坦，或者释放元素武器后治疗链刷团，可以作为走位时的填充技能
		--点出专注洞悉天赋后，可以通过烈焰震击+治疗大雨的方式，最大限度的提供团刷所需要的HPS
--		if(InCombat and CCAutoRush and CCSQHL_Rush())then return end;

		if(not InCombat)then
			if(not CCShareHoly.raid_noLittleHeal(mytarget) and WA_CheckSpellUsable(zzborzzl))then
				CCFlagSpell(zzborzzl);
				CCShareHoly.setLastDuTiaoTarget(mytarget)
				return;
			end
		end

		if( D:CastReadable() and  targethpincomingrate<0.2 and WA_CheckSpellUsable(zzborzzl2) and CCShareHoly.isHolyAbleBig(mytarget) and not WA_CheckBuff("潮汐奔涌"))then
			if(WA_CheckBuff("芬克的混合剂",0,0,nil,mytarget))then
				CCFlagSpell(zzborzzl2);
			else
				CCFlagSpell(zzborzzl);
			end
			CCShareHoly.setLastDuTiaoTarget(mytarget)
			return;
		end

		if( not CCShareHoly.raid_noLittleHeal(mytarget) and D:CastReadable() and targethpincomingrate<0.2 and WA_CheckSpellUsable(zzborzzl) and not WA_CheckBuff("潮汐奔涌"))then
			CCFlagSpell(zzborzzl);
			CCShareHoly.setLastDuTiaoTarget(mytarget)
			return;
		end

		if( not CCShareHoly.raid_noLittleHeal(mytarget) and D:CastReadable() and targethpincomingrate<0.2 and WA_CheckSpellUsable("治疗之涌"))then
			if(WA_CheckBuff("芬克的混合剂",0,0,nil,mytarget))then
				CCFlagSpell("治疗之涌");
			else
				CCFlagSpell(zzborzzl);
			end
			CCShareHoly.setLastDuTiaoTarget(mytarget)
			return;
		end

		if( D:CastReadable() and WA_CheckSpellUsable(zzborzzl2) and CCShareHoly.isHolyAbleBig(mytarget) )then
			CCFlagSpell(zzborzzl2);
			CCShareHoly.setLastDuTiaoTarget(mytarget)
			return;
		end
		if( not CCShareHoly.raid_noLittleHeal(mytarget) and D:CastReadable() and WA_CheckSpellUsable(zzborzzl))then
			CCFlagSpell(zzborzzl);
			CCShareHoly.setLastDuTiaoTarget(mytarget)
			return;
		end
		jcmessage("没蓝了！")
		--没蓝了 圣疗 可以回蓝！
	end
	--别让自己的治疗溢出	
	if(CCShareHoly.isHelp(mytarget) and (not CCShareHoly.isYichu(mytarget,spell,endTime)) and IsSpellInRange("治疗波", mytarget)==1)then
		if(not noaoe and D:CastReadable() and CCShareHoly.isHolyAbleCrow(mytarget,false,25,2,3) and WA_CheckSpellUsable("治疗链"))then
			--D:Error("??");
			CCFlagSpell("治疗链");
			return;
		end
		if(D:CastReadable() and CCShareHoly.isHolyAble(mytarget,useqiangxiaobs) and CCShareHoly.isHolyAbleBig(mytarget) )then
			if(WA_CheckSpellUsable(zzborzzl2))then
				CCFlagSpell(zzborzzl2);
				CCShareHoly.setLastDuTiaoTarget(mytarget)
				return;
			end
		end

		if(not CCShareHoly.raid_noLittleHeal(mytarget) and D:CastReadable() and CCShareHoly.isHolyAble(mytarget,2))then
			if(WA_CheckSpellUsable(zzborzzl))then
				CCFlagSpell(zzborzzl);
				CCShareHoly.setLastDuTiaoTarget(mytarget)
				return;
			end
		end
	end	
	
	if D:CastReadable() and CCShareHoly.isHarm("target") and manrate<0.99 and WA_CheckSpellUsableOn("闪电箭") then		
		if moliurank>0 then
			CCFlagSpell("闪电箭");
			return;
		end
	end

	--[[
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
	--
	if(InCombat and CCShareHoly.isHarm(mysptarget) and WA_CheckSpellUsable("审判") and IsSpellInRange("审判", mysptarget)==1 and UnitPowerMax("player")-UnitPower("player")>3000)then
		CCFlagSpell("审判");
		return;
	end
]]
end
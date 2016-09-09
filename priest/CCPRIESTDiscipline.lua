-- CCPRIESTDiscipline.lua
-- target yichu

local addonName, T = ...;
local D = T.jcc;

local _,clzz = UnitClass("player");
if clzz~="PRIEST" then return;end

local S = D.PRIEST;

local H = S:NewModule("PRIEST1", "AceEvent-3.0", "AceHook-3.0","CCTalent-1.0");

local mouseovertargetfocus = "/cast [@mouseover,help,nodead][@target,help,nodead][@focus,help,nodead]%s";
local mouseovertargetfocusxl = "/cast !心灵专注\n/cast [@mouseover,help,nodead][@target,help,nodead][@focus,help,nodead]%s";

-- 驱散魔法 可以驱散魔法 缺兵书可以驱除疾病

H.TalentSpellDescs = {
	["苦修"] = {slot=23,havecd=true},
	["苦修H"] = {slot=24,havecd=true,marco="/cast [@mouseover,help,nodead][@target,help,nodead][@focus,help,nodead][@target,harm,nodead]苦修"},
	["神圣之火"] = {slot=25,havecd=true},
	["纯净术"] = {slot=26,havecd=true,marco=mouseovertargetfocus},
	["治疗术"] ={slot=27,marco=mouseovertargetfocus},
	["治疗术t"] ={slot=28,marco="/cast [@focus,help,nodead]治疗术"},
	["治疗祷言"] ={slot=29,marco=mouseovertargetfocus},
	["天使长"] ={slot=30,havecd=true},
	["沉默"] ={slot=31,havecd=true},
	["痛苦压制"] = {slot=32,havecd=true,marco=mouseovertargetfocus},	
	["真言术：障"] = {slot=33,havecd=true},
}

--[[恢复 5k+
治疗祷言 2k+
治疗术2k+
强效治疗术 7k+
快速治疗 5k+
联结治疗 4k+
愈合祷言 2k+
]]
-- 设定治疗术 为基本法术
local usehuifubs = 4.5/2;
local usezhiliaodaoyan = 1.5/2;
local usezhiliaoshubs = 2/2;
local useqxzhiliaoshubs = 6/2;
local usekszhiliaoshubs = 1;
--免费快速治疗
local usebufkszlbs = 2;
local useljzhiliaoshubs = 3/2;
local useyhdaoyanbs = 2/2;

function H:onCCLoaded()
	D.UsingSpellCooldowns["真言术：盾"]=nil;
	D.UsingSpellCooldowns["真言术：盾t"]=nil;
end

local function ismyke(name,rank,iconTexture,count,debuffType,duration,expirationTime,unitCaster,canStealOrPurge, shouldConsolidate, spellId)
	return spellId==109964;
end
local function ismykexg(name,rank,iconTexture,count,debuffType,duration,expirationTime,unitCaster,canStealOrPurge, shouldConsolidate, spellId)
	return spellId==114908;
end

function H:Work(safehp,tankhp)

	local mytank = "focus";
	local manrate = UnitPower("player")/UnitPowerMax("player");
	local _, _, _, zlscastTime = GetSpellInfo("治疗术");

	--先确定我的目标
	local mytarget = "focus";
	if(CCShareHoly.isHelp("mouseover"))then
		mytarget = "mouseover";
	elseif(CCShareHoly.isHelp("target"))then
		mytarget = "target";
	end

	if(InCombat and WA_CheckSpellUsable("快速治疗") and UnitGUID(mytarget)==UnitGUID(mytank) and CCShareHoly.isHelp(mytarget) and CCShareHoly.isGoingDead(mytarget,safehp,0.2) and IsSpellInRange("快速治疗", mytarget)==1)then
		CCFlagSpell("快速治疗");
		return;
	end

	if SpellIsTargeting() then
		D:Debug("正在目标中，取消");
		return;
	end

	local noaoe = (CCShareHoly.isHelp(mytank) and CCShareHoly.raid_noLittleHeal(mytank)) or (CCShareHoly.isHelp(mytarget) and CCShareHoly.raid_noLittleHeal(mytarget));

	local isHolySpell = false;
	local timeToFinish = D.Casting.ttf*1000;
	if D.Casting.name then
		if D.Casting.channeling then
			return;
		end

		isHolySpell = (D.Casting.name=="快速治疗" or D.Casting.name=="强效治疗术" or D.Casting.name=="治疗术");
		if(isHolySpell)then
			CCShareHoly.updateDutiaoTarget(D.Casting.startTime*1000);
		end

		if(isHolySpell and WA_CheckBuff("灵魂护壳",0,0,true,"player",ismyke))then
			local mysftarget = CCShareHoly.GetCurrentDutiaoUnitid();
			if(mysftarget)then
				local donotbreak = UnitGUID(mysftarget)==UnitGUID(mytank) and WA_CheckBuff("恩赐",zlscastTime/1000+1,3,false,mytank);
				D:Debug("对象",mysftarget," 溢出？",CCShareHoly.isYichu(mysftarget,D.Casting.name,D.Casting.endTime*1000),"时间",timeToFinish);
				if(CCShareHoly.isYichu(mysftarget,D.Casting.name,D.Casting.endTime*1000) and not CCShareHoly.isDanger(mysftarget,safehp) )then
					--
					if(timeToFinish<200 and not donotbreak)then
						CCFlagSpell("打断");
					end
				end
			end
		end
		if(timeToFinish>=500)then
			return;
		end
	end

	if(CCWA_Check_PreToCasts())then return end

	if S.GCDLeftTime>D.MaxDelayS then
		return;
	end

	if CCShareHoly.isHelp(mytarget) and WA_CheckSpellUsable("纯净术") and IsSpellInRange("纯净术", mytarget)==1 and D:ShouldQusan(mytarget,{"DISEASE","MAGIC"}) then
		CCFlagSpell("纯净术");
		return;
	end


	local aym = "暗影魔";
	if GetSpellInfo("摧心魔") then aym="摧心魔"; end

	-- and CCAutoRush
	if(InCombat and manrate<0.85 and UnitExists("boss1") )then
		CCShareHoly.check_user_invslot_huilan(INVSLOT_TRINKET1);
		CCShareHoly.check_user_invslot_huilan(INVSLOT_TRINKET2);
	end
	--启动了rush就自己用
	local doaym = InCombat and CCShareHoly.isHarm("boss1") and WA_CheckSpellUsable(aym) and manrate<0.8 and CCShareHoly.isHarm("target")
		and (WA_Is_Boss() or UnitHealth("target")/UnitHealthMax("target")>0.8);--目标是boss或者血量足够多
	if doaym then
		CCFlagSpell(aym);
		return;
	--elseif doaym and not CCAutoRush then
	--	jcmessage("可以使用"..aym);
	end

	--周围30码 有2人需要强效 那就开大天使！
	local vbtotsz = (InCombat and (CCShareHoly.isHolyAbleCrow("player",false,30,usekszhiliaoshubs,2) or  CCShareHoly.isHolyAbleCrow("player",false,30,usezhiliaoshubs,4)))
		or not WA_CheckBuff("灵魂护壳",0,0,true,"player",ismyke)
	if WA_CheckSpellUsable("天使长") and (vbtotsz or CCAutoRush) and not WA_CheckBuff("福音传播",0,5) then
		CCFlagSpell("天使长");
		return;
	end

	if not WA_CheckBuff("灵魂护壳",0,0,true,"player",ismyke) then
		--aoe则使用治疗祷言 否则则使用强效治疗术
		CCWA_RacePink(false,nil,true);
		if not noaoe and D:CastReadable() and WA_CheckSpellUsable("治疗祷言") then
			CCFlagSpell("治疗祷言");
			return;
		end
	end

	if InCombat and GetSpellInfo("瀑流") and CCAutoRush and CCShareHoly.isHelp(mytarget) and CCShareHoly.isHolyAble(mytarget,usezhiliaoshubs) and WA_CheckSpellUsableOn("瀑流",mytarget) then
		CCFlagSpell("瀑流");
		return;
	end

	if InCombat and CCAutoRush and GetSpellInfo("神圣之星") and WA_CheckSpellUsable("神圣之星") then
		jcmessage("可以使用神圣之星");
	end
	if InCombat and CCAutoRush and GetSpellInfo("光晕") and WA_CheckSpellUsable("光晕") then
		jcmessage("可以使用光晕");
	end

	--[[if CCShareHoly.isHelp(mytarget) and D:ShouldQusan(mytarget,{"MAGIC"}) and WA_CheckSpellUsable("驱散魔法") and IsSpellInRange("驱散魔法", mytarget)==1 then
		CCFlagSpell("驱散魔法");
		return;
	end]]

	if(InCombat and CCShareHoly.isHelp(mytank) and WA_CheckSpellUsableOn("真言术：盾",mytank) and WA_CheckBuff("真言术：盾",0,0,false,mytank) and IsSpellInRange("真言术：盾", mytank)==1 and WA_CheckDebuff("虚弱灵魂",0,0,false,mytank))then
		D:Debug("tank:",mytank," 施法可用：",WA_CheckSpellUsableOn("真言术：盾",mytank)," 盾在:",WA_CheckBuff("真言术：盾",0,0,true,mytank), " 虚弱：",WA_CheckDebuff("虚弱灵魂",0,0,false,mytank));
		CCFlagSpell("真言术：盾t");
		return;
	end

	--如果插了雕文就卡cd用。。没插的话呢？ 是否检查愈合还在谁哪里？
	if(InCombat and CCShareHoly.isHolyAble(mytank,useyhdaoyanbs) and WA_CheckSpellUsable("愈合祷言") and CCShareHoly.isHelp(mytank) and WA_CheckBuff("愈合祷言",0,0,true,mytank) and IsSpellInRange("愈合祷言", mytank)==1)then
		CCFlagSpell("愈合祷言");
		return;
	end

	--对于拥有仇恨 或者正在掉血？ 的目标可以施展盾 和 愈合	
	-- 血崩阶段或者开启了 灵魂护壳
	
	if not noaoe and D:CastReadable() and CCFightType==2 and  (CCShareHoly.isHolyAbleCrow(mytarget,false,30,usezhiliaodaoyan,4) or not WA_CheckBuff("天使长")) and WA_CheckSpellUsable("治疗祷言") then
		CCFlagSpell("治疗祷言");
		return;
	end

	if not WA_CheckBuff("灵魂护壳",0,0,true,"player",ismyke) then
		--aoe则使用治疗祷言 否则则使用强效治疗术
		if CCFightType==2 and not noaoe and D:CastReadable() and WA_CheckSpellUsable("治疗祷言") then
			CCFlagSpell("治疗祷言");
			return;
		end
		if CCFightType==1 and CCShareHoly.isHelp(mytarget) and D:CastReadable() and WA_CheckSpellUsable("治疗术") and WA_CheckBuff("灵魂护壳",0,0,true,mytarget,ismykexg) then
			CCFlagSpell("治疗术");
			CCShareHoly.setLastDuTiaoTarget(mytarget)
			return;
		end
	end

--[[	if not noaoe and D:CastReadable() and UnitGUID(mytarget)~=UnitGUID("player") and CCShareHoly.isHelp(mytarget) and not CCShareHoly.isHolyAble(mytarget,0)  and CCShareHoly.isHolyAble(mytarget,useljzhiliaoshubs) and CCShareHoly.isHolyAble("player",useljzhiliaoshubs) and WA_CheckSpellUsable("联结治疗") then
		CCFlagSpell("联结治疗");
		return;
	end]]


	--直接施展治疗术的条件 危险！ 直接目标 ! 天使长已开并且少血
	local vbzhijiezhiliao = CCShareHoly.isDanger(mytarget,safehp) or (CCShareHoly.isEquals(mytarget,"target") and not CCShareHoly.isYichu(mytarget,D.Casting.name,D.Casting.endTime*1000))
		or (not WA_CheckBuff("天使长") and CCShareHoly.isHolyAble(mytarget,useqxzhiliaoshubs) );

	if CCShareHoly.isHelp(mytarget) and vbzhijiezhiliao and IsSpellInRange("治疗术", mytarget)==1 then
		local targethpincomingrate = (UnitHealth(mytarget)+(UnitGetIncomingHeals(mytarget) or 0))/UnitHealthMax(mytarget);

		if(not InCombat)then
			if(D:CastReadable() and WA_CheckSpellUsable("治疗术") and CCShareHoly.isHolyAbleBig(mytarget) and CCShareHoly.isHolyAble(mytarget,useqxzhiliaoshubs) )then
				CCFlagSpell("治疗术");
				CCShareHoly.setLastDuTiaoTarget(mytarget)
				return;
			end
			if(not CCShareHoly.raid_noLittleHeal(mytarget) and D:CastReadable() and WA_CheckSpellUsable("治疗术"))then
				CCFlagSpell("治疗术");
				CCShareHoly.setLastDuTiaoTarget(mytarget)
				return;
			end
		end

		if WA_CheckSpellUsableOn("真言术：慰") and not D:CastReadable() and InCombat and CCShareHoly.isHarm("target") then
			CCFlagSpell("真言术：慰");
			return;
		end

		--免费快速治疗
		if not WA_CheckBuff("圣光涌动",0,0,true) and (CCShareHoly.isHolyAbleBig(mytarget) or  CCShareHoly.isHolyAble(mytarget,usebufkszlbs)) and WA_CheckSpellUsableOn("快速治疗",mytarget) then
			CCFlagSpell("快速治疗");
			return;
		end
		--2层满了 蓝线ok就刷吧
		if not WA_CheckBuff("圣光涌动",0,2,true) and manrate>0.3 and CCShareHoly.isHolyAble(mytarget,usezhiliaoshubs) and WA_CheckSpellUsableOn("快速治疗",mytarget) then
			CCFlagSpell("快速治疗");
			return;
		end
		--快到期了
		if not WA_CheckBuff("圣光涌动",0,0,true) and WA_CheckBuff("圣光涌动",2,0,true) and CCShareHoly.isHolyAble(mytarget,usezhiliaoshubs) and WA_CheckSpellUsableOn("快速治疗",mytarget) then
			CCFlagSpell("快速治疗");
			return;
		end

		if D:CastReadable() and CCShareHoly.isHolyAbleBig(mytarget) and CCShareHoly.isHolyAble(mytarget,useqxzhiliaoshubs) and WA_CheckSpellUsableOn("苦修",mytarget) then
			CCFlagSpell("苦修H");
			CCShareHoly.setLastDuTiaoTarget(mytarget)
			return;
		end

		if( not CCShareHoly.raid_noLittleHeal(mytarget) and  D:CastReadable() and targethpincomingrate<0.2 and WA_CheckSpellUsableOn("快速治疗",mytarget))then
			if(WA_CheckBuff("芬克的混合剂",0,0,nil,mytarget))then
				CCFlagSpell("快速治疗");
			else
				CCFlagSpell("治疗术");
			end
			CCShareHoly.setLastDuTiaoTarget(mytarget)
			return;
		end

		if( D:CastReadable() and WA_CheckSpellUsableOn("治疗术",mytarget) and CCShareHoly.isHolyAbleBig(mytarget) )then
			CCFlagSpell("治疗术");
			CCShareHoly.setLastDuTiaoTarget(mytarget)
			return;
		end
		if( not CCShareHoly.raid_noLittleHeal(mytarget) and D:CastReadable() and WA_CheckSpellUsableOn("治疗术",mytarget))then
			CCFlagSpell("治疗术");
			CCShareHoly.setLastDuTiaoTarget(mytarget)
			return;
		end
	end
	--别让自己的治疗溢出	
--[[	if(CCShareHoly.isHelp(mytarget) and (not CCShareHoly.isYichu(mytarget,D.Casting.name,D.Casting.endTime*1000)) and IsSpellInRange("治疗术", mytarget)==1)then

		if(D:CastReadable() and CCShareHoly.isHolyAble(mytarget,useqxzhiliaoshubs) and CCShareHoly.isHolyAbleBig(mytarget) )then
			if(WA_CheckSpellUsable("强效治疗术"))then
				CCFlagSpell("强效治疗术");
				CCShareHoly.setLastDuTiaoTarget(mytarget)
				return;
			end
		end

		if(not CCShareHoly.raid_noLittleHeal(mytarget) and D:CastReadable() and CCShareHoly.isHolyAble(mytarget,usezhiliaoshubs))then
			if(WA_CheckSpellUsable("治疗术"))then
				CCFlagSpell("治疗术");
				CCShareHoly.setLastDuTiaoTarget(mytarget)
				return;
			end
		end
	end
	]]

	--监视坦克	
	--[[if(InCombat and CCShareHoly.isHelp(mytank) and WA_CheckBuff("恩赐",zlscastTime/1000+1,3,false,mytank) and IsSpellInRange("治疗术", mytank)==1)then
		CCFlagSpell("治疗术t");
		return;
	end]]

	local solo = not CCShareHoly.isHelp("focus");

	-- and (solo or CCShareHoly.isHolyAbleCrow("player",false,40,0.5,1))

	if InCombat and CCShareHoly.isHarm("target") then
		local inZS = UnitHealth("target")/UnitHealthMax("target")<=0.25;
		--solo!
		--[[if not CCShareHoly.isHolyAble("player",0) and CCShareHoly.isHolyAble("player",usezhiliaoshubs) and WA_CheckSpellUsable("真言术：盾") and WA_CheckBuff("真言术：盾") and WA_CheckDebuff("虚弱灵魂") then
			CCFlagSpell("真言术：盾");
			return;
		end]]
		if WA_CheckSpellUsableOn("真言术：慰") then
			CCFlagSpell("真言术：慰");
			return;
		end
		if WA_CheckSpellUsableOn("神圣之火") then
			CCFlagSpell("神圣之火");
			return;
		end
		if D:CastReadable() and WA_CheckSpellUsableOn("苦修") then
			CCFlagSpell("苦修");
			return;
		end
		--没有五层buf用
		--没有2层buf用
		if D:CastReadable() and WA_CheckSpellUsableOn("惩击") and (WA_CheckBuff("福音传播",3,5,true) or WA_CheckBuff("圣光涌动",0,2,true)) then
			CCFlagSpell("惩击");
			return;
		end
	end
	
end

-- 如果苦修雕文开启 则可移动施法
-- 读条的时候 我点了盾 那么读条好了以后 也应该施放出来
-- 还是应该区分开solo模式和raid模式 在这2个模式中 一个区别是小队满血或者小团满血状态下 是不打人的 另外一点是是否使用灭
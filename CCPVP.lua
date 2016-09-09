---- pvp

local addonName, TT = ...;
local D = TT.jcc;

local CC_PVP_Kongzhies = {};
local CC_PVP_KZNAME = nil;
local CC_PVP_Control_Enable = false;

--[[local UnitIsPlayer = function()
return true;
end]]

function CC_PVP_Toggle_Control()
	CC_PVP_Control_Enable = not CC_PVP_Control_Enable;
	if(CC_PVP_Control_Enable)then
		jcmessage("允许控制技能的施展");
	else
		jcmessage("停止控制技能的施展");
	end
end

local function WA_PVP_Is_Kongzhi()
	local uname = UnitName("target");
	if(not uname)then return false end
	--[[if(tContains(CC_PVP_Kongzhies,uname))then
		return true;
	end
	return false;]]
	if not CC_PVP_KZNAME then return false;end
	return CC_PVP_KZNAME==uname;
end

function WA_Add_PVP_Kongzhi()
	local uname = UnitName("target");
	if(not uname)then return end
	CC_PVP_KZNAME = uname;
	jcmessage("已添加至强控名单");
--[[	if(tContains(CC_PVP_Kongzhies,uname)) then
		jcmessage("已在强控名单");
	else
		wipe(CC_PVP_Kongzhies);
		tinsert(CC_PVP_Kongzhies,uname)
		jcmessage("已添加至强控名单");
	end]]
end

function CC_TargetisWudi()
	if(not WA_CheckBuff("圣盾术",1,0,nil,"target"))then
		return true;
	end
	if(not WA_CheckBuff("寒冰屏障",1,0,nil,"target"))then
		return true;
	end
	if(not WA_CheckBuff("保护之手",1,0,nil,"target"))then
		return true;
	end
	return false;
end

local cc_rush_spells = {"剑刃风暴","复仇之怒","狂热","狂暴","生命之树","星辰坠落","鲁莽","死亡之愿","邪恶狂热","冰霜之柱"
	,"奥术强化","冰冷血脉","暗影之舞","切割","暗影能量","能量灌注","野兽之心","急速射击","元素掌握","萨满之怒"};
local function cc_pvp_rush(unitid)
	for i=1,#cc_rush_spells do
		if(not WA_CheckBuff(cc_rush_spells[i],1,0,nil,unitid))then
			D:Debug(unitid,"存在buf",cc_rush_spells[i]);
			return true;
		end
	end
	return false;
end

local function cc_pvp_weapon_zy(unitid)
	--zs dz dk lr cjq zqsm
	local _,clzz = UnitClass(unitid);
	if(clzz=="DEATHKNIGHT"
		or clzz=="WARRIOR"
		or clzz=="HUNTER"
		or clzz=="PALADIN"
		or clzz=="SHAMAN"
		or clzz=="ROGUE")then
		return true;
	end
	--虽然说qs和sm未必是近战需要缴械 但加上其他buf的判断就必然了 不过最好还是改善一下
	--DRUID WARLOCK MAGE PRIEST PALADIN SHAMAN
	return false;
end

local function cc_pvp_range(unitid)
	--zs dz dk lr cjq zqsm
	local _,clzz = UnitClass(unitid);
	if(clzz=="WARLOCK"
		or clzz=="MAGE"
		or clzz=="HUNTER"
		or clzz=="PRIEST"
		or clzz=="SHAMAN"
		or clzz=="DRUID")then
		--其实xd和sm不一定的
		return true;
	end
	--DRUID WARLOCK MAGE PRIEST PALADIN SHAMAN
	return false;
end

-- 上断筋
--  区别应该在于即使是别人施展的断筋也是有效的
local function WA_Hamstring(tm,sfqd)
	if(not WA_CheckBuff("自由之手",0.1,0,nil,"target"))then
		return false;
	end
	if((not WA_CheckDebuff("断筋",0.1,0,true)) and sfqd and GetTime()>qianghuadjtimesnap)then
		--print("需要，并且可以强断！");
		return Try_Cast_AI("断筋")~=0;
	end
	--如果对方昏迷 或者无法移动 或者速度已经降低 那就别用了
	if(UnitIsNotAbleAttack("target",tm) 
		or UnitIsCanntMove("target",tm)
		or UnitIsEnsnared("target",tm)
		or UnitIsIncoma("target",tm)
		)then
		return false;
	end

	local uname = UnitName("target");
	if(not uname)then return false end
--	local ctype = UnitCreatureType("target");	
--	if( not string.find(uname,"训练假人") and (ctype=="机械" or ctype=="元素生物") ) then
--		--免疫的
--		return false;
--	end
	if(WA_CheckDebuff("断筋",tm) and WA_CheckSpellUsable("断筋")) then
		CCFlagSpell("断筋");
		return true;
	end
	return false;
end

local function CC_PVP_WR()
	local pvpes_ = GetEquipmentSetInfoByName("pvp");
	local tankes_ = GetEquipmentSetInfoByName("shield");	
	if(CC_InRange() and PreToCast~="法术反射" and PreToCast~="盾墙" and pvpes_ and (not IsEquippedItemType("双手")) and WA_CheckBuff("法术反射") and WA_CheckBuff("盾墙") and WA_CheckBuff("盾牌格挡") and (not UnitIsDisarmed("player")))then
--		print("换上武器");
--		UseEquipmentSet("pvp");
		CCFlagSpell("epvp");
	end
	if(InCombat and tankes_ and (not IsEquippedItemType("盾牌")) and WA_CheckBuff("剑刃风暴") and UnitIsDisarmed("player")) then
		--print("换上盾牌");
--		UseEquipmentSet("shield");
		CCFlagSpell("eshield");
	end
	--如果没有被缴械，而且没有持有双手武器 没有盾反 没有盾墙 则换回双手	
	--如果被缴械 而且没有持盾 则换盾
	if(not CC_InRange())then
		if(WA_CheckSpellUsable("英勇投掷"))then
			CCFlagSpell("英勇投掷");
			return true;
		end
		-- 11.11 yards 
		if(CheckInteractDistance("target",2) and WA_CheckDebuff("刺耳怒吼",1) and WA_CheckSpellUsable("刺耳怒吼"))then
			CCFlagSpell("刺耳怒吼");
			return true;
		end
		WA_Changshi_Fangyu();
--		CCFlagSpell("防御姿态");
--		print("离开范围了");
		if tankes_ and (not IsEquippedItemType("盾牌")) then
--			UseEquipmentSet("shield");
--			print("换盾");
			CCFlagSpell("eshield");
		end
		return true;
	end

	local _,clzz = UnitClass("target");
	
	--如果对手是先行缴械
	if(CC_PVP_Control_Enable and cc_pvp_weapon_zy("target") and cc_pvp_rush("target") and (not UnitIsBeFear("target")) and (not UnitIsIncoma("target")) and (not UnitIsDisarmed("target")))then
		if(Try_Cast_AI("缴械")~=0)then
--			print("应当缴械,并且缴械之！");
			return true;
		else
--			print("应当缴械,可惜不能缴械！");
		end
	end

	--缴械了 也同样不用日了
	if(CC_PVP_Control_Enable and (WA_PVP_Is_Kongzhi() or cc_pvp_rush("target")) and (not UnitIsBeFear("target")) and (not UnitIsIncoma("target")) and (not UnitIsDisarmed("target")) and WA_CheckBuff("自由之手",0.1,0,nil,"target"))then
		if(Try_Cast_AI("击倒")~=0)then
--			print("应当击倒,并且击倒之！");
			return true;
		else
--			print("应当击倒,可惜不能击倒！");
		end
	end

	if(CC_PVP_Control_Enable and (WA_PVP_Is_Kongzhi() or cc_pvp_range("target")) and (not UnitIsBeFear("target")) and (not UnitIsIncoma("target")) and (not UnitIsCanntMove("target")))then
		local _,icon,_,_,rank = GetTalentInfo(1,11);
		if(WA_Hamstring(1,rank>0))then return true; end
	end
	if(WA_Hamstring(1))then return true; end
	return false;
end

local FunoPVP = {
	["WARRIOR"] = CC_PVP_WR,
	--["PALADIN"] = "责难",
};

function CC_PVP()
	if(not UnitIsPlayer("target"))then
		return false;
	end

	local spell, _, _, _, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo("target");
	if not spell then
		spell, _, _, _, startTime, endTime,isTradeSkill,notInterruptible = UnitChannelInfo("target");
	end
	if spell and not notInterruptible then
		local timeToFinish = endTime - GetTime()*1000;
		if(timeToFinish<300)then
			CC_Try_Breakcasting();
		end
	end
	--		if(spell=="冲击新星" or spell=="硬化外皮" or spell=="暗影新星")then

	local _,clzz = UnitClass("player");
	local thefun = FunoPVP[clzz];
	if(not thefun)then
		return false;
	end
	local retOk,retDone = pcall(thefun);
	if(retOk)then
		return retDone;
	end;
	return false;
end
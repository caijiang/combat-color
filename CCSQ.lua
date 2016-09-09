
function CCWA_DPS_Yiduan()
	if(not WA_CheckSpellUsable("异端裁决"))then
		return false;
	end
	local ssnl = UnitPower("player",SPELL_POWER_HOLY_POWER);
	--修改为 保持 异端裁决 ！
	--你可以理解为:
	--没4T11 时
	--身上没异端审问Buff,只用2~3圣能加异端审问,假设出了触发驱邪或者飞锤,那么为了获得30%的加成,1圣能的审讯也是值得使用的.(Inq Apply)
	--身上有异端审问Buff,只用2~3 圣能刷新异端审问,绝对不用1圣能的异端审问刷新Buff .(Inq Refresh) 
	--有4T11时
	--身上没异端审问Buff ,用1~3圣能第一时间加上异端审问Buff (Inq Apply)
	--身上有异端审问Buff,尽可能的使用1~2圣能刷新异端审问,如果出神圣意图那就用3圣能刷新Buff .(Inq Refresh) 
	local havebuf = not WA_CheckBuff("异端裁决");
	if(WA_CheckBuff("异端裁决",3))then
		if((not havebuf) and (((not WA_CheckBuff("战争艺术")) and WA_CheckSpellUsable("驱邪术"))
			or (WA_CheckSpellUsable("愤怒之锤"))))then
			CCFlagSpell("异端裁决");
			return true;
		end
		if(havebuf and ssnl>=2)then
			CCFlagSpell("异端裁决");
			return true;
		end
	end
	return false;
end

function CCWA_DPS_Shenpan()	
	if(WA_CheckSpellUsable("审判"))then
		CCFlagSpell("审判");
		return true;
	end
	return false;
end

function CCWA_DPS_Fengnuzhichui()
	if(WA_CheckSpellUsable("愤怒之锤"))then
		CCFlagSpell("愤怒之锤");
		return true;
	end
	return false;
end

function CCWA_DPS_SSFN()
	if(WA_CheckSpellUsable("神圣愤怒"))then
		CCFlagSpell("神圣愤怒");
		return true;
	end
	return false;
end

function CCWA_DPS_FX()
	if(WA_CheckSpellUsable("奉献"))then
		CCFlagSpell("奉献");
		return true;
	end
	return false;
end

function CCWA_DPS_Shizijundaji()
	if(UnitPower("player",SPELL_POWER_HOLY_POWER)<=2 and WA_CheckSpellUsable("十字军打击"))then
		CCFlagSpell("十字军打击");
		return true;
	end
	return false;
end

function CCWA_DPS_ShenshengFengbao()
	if(UnitPower("player",SPELL_POWER_HOLY_POWER)<=2 and WA_CheckSpellUsable("神圣风暴"))then
		CCFlagSpell("神圣风暴");
		return true;
	end
	return false;
end

function CC_SQDPS()
	CombatColorRestAllFlag();
	if((not InCombat)or(not WA_NeedAttack()))then return end
	if(CCWA_Check_PreToCasts())then return end

	if(CC_check_threat_dps())then return end
	
	local inZS = UnitHealth("target")/UnitHealthMax("target")<=0.2;

	if(WA_CheckBuff("惩戒光环"))then
		CCFlagSpell("惩戒光环");
		return;
	end

	if(WA_CheckBuff("真理圣印",5))then
		jcmessage("请补充一个真理圣印!");
	end

	if(CCWA_DPS_Yiduan())then return end

	local goingrush = CCAutoRush and WA_CooldownLeft("狂热")==0;
	if(goingrush and WA_CheckSpellUsable("狂热"))then
		CCFlagSpell("狂热");
		if(WA_CheckSpellUsable("复仇之怒"))then
			CCFlagSpell("复仇之怒");
		end
		CCWA_RacePink();
	end
	if(WA_CheckSpellUsable("复仇之怒") and CCAutoRush and (not WA_CheckBuff("狂热")))then
		CCFlagSpell("复仇之怒");
	end

	if(CCFightType==2)then
		if(CCWA_DPS_ShenshengFengbao())then return end
	else
		if(CCWA_DPS_Shizijundaji())then return end
	end

	local ssnl = UnitPower("player",SPELL_POWER_HOLY_POWER);

	if((not goingrush) and ssnl==3 and (not WA_CheckBuff("神圣意志")) and WA_CheckSpellUsable("圣殿骑士的裁决"))then
		CCFlagSpell("圣殿骑士的裁决");
		return;
	end

	--驱邪 或者 愤怒 哪个先 还待定
	if((not WA_CheckBuff("战争艺术")) and WA_CheckSpellUsable("驱邪术"))then
		CCFlagSpell("驱邪术");
		return;
	end

	if(CCWA_DPS_Fengnuzhichui())then return end	

	if((not goingrush) and ssnl==3 and WA_CheckSpellUsable("圣殿骑士的裁决"))then
		CCFlagSpell("圣殿骑士的裁决");
		return;
	end

	if(CCWA_DPS_Shenpan())then return end

	--AOE的时候 先使用奉献 否者 先用 神圣愤怒
	if(CC_PriorityCall(CCFightType==2,CCWA_DPS_FX,CCWA_DPS_SSFN))then
		return;
	end
	--不在近战范围的时候：能审判就审判.在没有[戰爭藝術]的时候,驱邪的优先级在审判之下,如果审判在CD,蓝够的话就驱邪.

	--异端审问 > 十字军圣击(0~2圣能时) > 圣殿骑士的裁决(有神圣意图时)> 愤怒之锤> 驱邪 > 圣殿骑士之裁决 > 审判 > 神圣愤怒 > 奉献	
end
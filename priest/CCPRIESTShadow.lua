-- CCPRIESTShadow.lua

local addonName, T = ...;
local OvaleSpellBook = T.OvaleSpellBook;
local OvaleEquipment = T.OvaleEquipment;
local OvaleState = T.OvaleState;
local D = T.jcc;

local _,clzz = UnitClass("player");
if clzz~="PRIEST" then return;end

local S = D.PRIEST;

local H = S:NewModule("PRIEST3", "AceEvent-3.0", "AceHook-3.0","CCTalent-1.0");

-- 驱散魔法 可以驱散魔法 缺兵书可以驱除疾病
local dottimebs = 0.5;
local castOfZB = true;

H.TalentSpellDescs = {
	["精神鞭笞"] = 23,
	["心灵震爆"] ={slot=24,havecd=true},
	["噬灵疫病"] = 25,
	["吸血鬼之触"] = 26,
	["心灵尖刺"] = 27,
	["暗言术：灭"]={slot=28,havecd=true},
	["消散"] = {slot=29,havecd=true},
	["心灵惊骇"] = {slot=30,havecd=true},
	["吸血鬼的拥抱"] = {slot=31,havecd=true},
	["吸血鬼之触mouseover"] = {slot=32,marco="/cast [@mouseover,harm,nodead]吸血鬼之触"},
	["暗言术：痛mouseover"] = {slot=33,marco="/cast [@mouseover,harm,nodead]暗言术：痛"},
	["暗言术：灭mouseover"] = {slot=34,marco="/cast [@mouseover,harm,nodead]暗言术：灭"},
	["噬灵疫病mouseover"] = {slot=35,marco="/cast [@mouseover,harm,nodead]噬灵疫病"},
	["沉默"] = {slot=36,havecd=true},
}

function H:onCCLoaded()
	if OvaleSpellBook:GetTalentPoints(155246) then
		-- COP
		castOfZB = false;
	else
		castOfZB = true;
	end
end

local function targetPct(unitid)
	unitid = unitid or "target";
	return UnitHealth(unitid)*100/UnitHealthMax(unitid);
end
local function rbs()
	local state = OvaleState.state;
	return state["shadoworbs"];
end

local function castBlast(unitid)
	unitid = unitid or "target";
	if (D:CastReadable() or not castOfZB) and WA_CheckSpellUsable("心灵震爆") then
		CCFlagSpell("心灵震爆");
		return true;
	end
end

local function castPain(debufTime,dieTime,unitid)
	unitid = unitid or "target";
	if WA_CheckSpellUsableOn("暗言术：痛",unitid) and WA_CheckDebuff("暗言术：痛",debufTime,0,true,unitid) and D:TimeToDie(dieTime) then
		if unitid=="target" then
			CCFlagSpell("暗言术：痛");
		else
			CCFlagSpell("暗言术：痛"..unitid);
		end
		return true;
	end
end

local function castTouch(debufTime,dieTime,unitid)
	unitid = unitid or "target";
	if WA_CheckSpellUsableOn("吸血鬼之触",unitid) and WA_CheckDebuff("吸血鬼之触",debufTime,0,true,unitid) and D:TimeToDie(dieTime) then
		if unitid=="target" then
			CCFlagSpell("吸血鬼之触");
		else
			CCFlagSpell("吸血鬼之触"..unitid);
		end
		return true;
	end
end

local function castPlague(unitid,debufTime)
	unitid = unitid or "target";
	if debufTime then
		-- 是否依赖于检查debuf是否已存在
		if not WA_CheckDebuff("噬灵疫病",debufTime,0,true,unitid) then
			return false;
		end
	end
	if WA_CheckSpellUsableOn("噬灵疫病",unitid) then
		if unitid=="target" then
			CCFlagSpell("噬灵疫病");
		else
			CCFlagSpell("噬灵疫病"..unitid);
		end
		return true;
	end
end

local function castPlague1(unitid)
	return rbs()>=5 and castPlague(unitid);
end
local function castPlague2(unitid)
	return rbs()>=3 and OvaleSpellBook:GetTalentPoints(155271)>0 and castPlague(unitid);
end
local function castPlague3(unitid)
	local state = OvaleState.state;
	--actions.main+=/devouring_plague,if=shadow_orb>=3&buff.mental_instinct.remains<gcd&buff.mental_instinct.remains>(gcd*0.7)&buff.mental_instinct.remains
	return rbs()>=3 and WA_CheckBuff("思维本能",state:GetGCD()) and not WA_CheckBuff("思维本能",state:GetGCD()*0.7) and castPlague(unitid);
end
--actions.main+=/devouring_plague,if=shadow_orb>=4&talent.auspicious_spirits.enabled&XX1&!target.dot.devouring_plague_tick.ticking&talent.surge_of_darkness.enabled,cycle_targets=1
-- XX1 ((cooldown.mind_blast.remains<gcd&!set_bonus.tier17_2pc&(!set_bonus.tier18_4pc&!talent.mindbender.enabled))|(target.health.pct<20&cooldown.shadow_word_death.remains<gcd))
local function castPlague4(unitid)
	unitid = unitid or "target";
	local state = OvaleState.state;
	local timeToBlast = WA_CooldownLeft("心灵震爆",true);
	local timeToDeath = WA_CooldownLeft("暗言术：灭",true);
	local xx1 = (timeToBlast<state:GetGCD() and not D:ArmorSetBonus("T17",2) and (not D:ArmorSetBonus("T18",4) and OvaleSpellBook:GetTalentPoints(123040)==0)) or (targetpct(unitid)<20 and timeToDeath<state:GetGCD());
	--and WA_CheckDebuff("噬灵疫病",0,0,true,unitid) and OvaleSpellBook:GetTalentPoints(162448)>0 and
	if rbs()>=4 and OvaleSpellBook:GetTalentPoints(155271)>0 and xx1 and castPlague(unitid) then
		return true;
	elseif rbs()>=3 and OvaleSpellBook:GetTalentPoints(155271)==0 and xx1 and castPlague(unitid) then
		return true;
	end
end

--actions.main+=/devouring_plague,if=shadow_orb>=3&talent.auspicious_spirits.enabled&set_bonus.tier18_4pc
-- &talent.mindbender.enabled&buff.premonition.up
local function castPlague5(unitid)
	return rbs()>=3 and OvaleSpellBook:GetTalentPoints(155271)>0
	and D:ArmorSetBonus("T18",4) and OvaleSpellBook:GetTalentPoints(123040)>0 and not WA_CheckBuff(188779) and castPlague(unitid);
end

-- /devouring_plague,if=shadow_orb>=3&set_bonus.tier17_2pc&!set_bonus.tier17_4pc
-- &(cooldown.mind_blast.remains<=2|(target.health.pct<20&cooldown.shadow_word_death.remains<gcd)),cycle_targets=1
local function castPlague6(unitid)
	local state = OvaleState.state;
	local timeToBlast = WA_CooldownLeft("心灵震爆",true);
	local timeToDeath = WA_CooldownLeft("暗言术：灭",true);
	local gcd = state:GetGCD();
	return rbs()>=3 and not D:ArmorSetBonus("T17",2) and (timeToBlast<gcd or (targetpct(unitid)<20 and timeToDeath<gcd)) and castPlague(unitid);
end

local function castDeath(unitid)
	unitid = unitid or "target";
	local inZS = UnitHealth(unitid)/UnitHealthMax(unitid)<=0.2;

	if inZS and not CC_Raid_ShouldDMGWithoutKO(unitid) and WA_CheckSpellUsableOn("暗言术：灭",unitid) then
		if unitid=="target" then
			CCFlagSpell("暗言术：灭");
		else
			CCFlagSpell("暗言术：灭"..unitid);
		end
		return true;
	end
	return false;
end

-- 是否施展灭
-- actions.main+=/mind_blast,if=glyph.mind_harvest.enabled&mind_harvest=0,cycle_targets=1
local function castBlastHarvest()
	if OvaleSpellBook:IsActiveGlyph(162532) and WA_CheckDebuff(162532,0,0,true,"target") and castBlast() then
		return true;
	end
	if OvaleSpellBook:IsActiveGlyph(162532) and WA_CheckDebuff(162532,0,0,true,"mouseover") and castBlast("mouseover") then
		return true;
	end
end

local function castFriend()
	if WA_CheckSpellUsable("摧心魔") then
		CCFlagSpell("摧心魔");
		return true;
	end
	if WA_CheckSpellUsable("暗影魔") then
		CCFlagSpell("暗影魔");
		return true;
	end
end

local function mental_fatigue_check(unitid)
	local state = OvaleState.state;
	--(!target.debuff.mental_fatigue.up|target.debuff.mental_fatigue.stack<5
	-- |(target.debuff.mental_fatigue.remains<=gcd|(target.debuff.mental_fatigue.remains<=gcd*2&cooldown.mindblast.remains<=gcd)))
	if WA_CheckDebuff(185104,0,5,true,unitid) then
		return true;
	end
	return WA_CheckDebuff(185104,state:GetGCD(),0,true,unitid)
	or (WA_CheckDebuff(185104,state:GetGCD()*2,0,true,unitid) and WA_CooldownLeft("心灵震爆",true)<=state:GetGCD());
end

local function cop_insanity()
	local state = OvaleState.state;

	local timeToBlast = WA_CooldownLeft("心灵震爆",true);
	local gcd = state:GetGCD();
	-- actions.cop_insanity=devouring_plague,if=shadow_orb=5|(active_enemies>=5&!buff.insanity.remains)
	if (rbs()==5 or (CCFightType==2 and WA_CheckBuff(132573))) and (castPlague() or castPlague("mouseover")) then
		return true;
	end
	-- actions.cop_insanity+=/devouring_plague,if=buff.mental_instinct.remains<(gcd*1.7)
	-- &buff.mental_instinct.remains>(gcd*0.7)&buff.mental_instinct.remains
	if WA_CheckBuff(167254,gcd*1.7) and not WA_CheckBuff(167254,gcd*0.7) and (castPlague() or castPlague("mouseover"))  then
		return true;
	end
	-- actions.cop_insanity+=/mind_blast,if=glyph.mind_harvest.enabled&mind_harvest=0,cycle_targets=1
	if OvaleSpellBook:IsActiveGlyph(162532) and WA_CheckDebuff(162532,0,0,true,"target") and castBlast() then
		return true;
	end
	if OvaleSpellBook:IsActiveGlyph(162532) and WA_CheckDebuff(162532,0,0,true,"mouseover") and castBlast("mouseover") then
		return true;
	end
	-- actions.cop_insanity+=/mind_blast,if=active_enemies<=5&cooldown_react
	if D:notEnoughEnemies(5) and castBlast then
		return true;
	end
	-- actions.cop_insanity+=/shadow_word_death,if=target.health.pct<20
	-- &!target.dot.shadow_word_pain.ticking&!target.dot.vampiric_touch.ticking,cycle_targets=1
	-- actions.cop_insanity+=/shadow_word_death,if=target.health.pct<20,cycle_targets=1
	if castDeath() or castDeath("mouseover") then
		return true;
	end
	-- actions.cop_insanity+=/devouring_plague,if=shadow_orb>=3&!set_bonus.tier17_2pc&!set_bonus.tier17_4pc
	-- &(cooldown.mind_blast.remains<gcd|(target.health.pct<20&cooldown.shadow_word_death.remains<gcd)),cycle_targets=1
	-- actions.cop_insanity+=/devouring_plague,if=shadow_orb>=3&set_bonus.tier17_2pc&!set_bonus.tier17_4pc&(cooldown.mind_blast.remains<=2|(target.health.pct<20&cooldown.shadow_word_death.remains<gcd)),cycle_targets=1
	if castPlague6() or castPlague6("mouseover") then
		return true;
	end
	-- actions.cop_insanity+=/shadowfiend,if=!talent.mindbender.enabled&set_bonus.tier18_2pc
	-- actions.cop_insanity+=/mindbender,if=talent.mindbender.enabled&set_bonus.tier18_2pc
	if D:ArmorSetBonus("T18",2) and castFriend() then
		return true;
	end
	-- actions.cop_insanity+=/searing_insanity,if=buff.insanity.remains<0.5*gcd&active_enemies>=3&cooldown.mind_blast.remains>0.5*gcd,chain=1,interrupt_if=(cooldown.mind_blast.remains<=0.1|cooldown.shadow_word_death.remains<=0.1),target_if=max:spell_targets.mind_sear_tick
	-- actions.cop_insanity+=/searing_insanity,if=active_enemies>=5,chain=1
	-- ,interrupt_if=(cooldown.mind_blast.remains<=0.1|cooldown.shadow_word_death.remains<=0.1),target_if=max:spell_targets.mind_sear_tick
	if WA_CheckSpellUsable("狂乱灼烧") and CCFightType==2 then
		CCFlagSpell("精神灼烧");
		return true;
	end
	-- actions.cop_insanity+=/mindbender,if=talent.mindbender.enabled
	-- actions.cop_insanity+=/shadowfiend,if=!talent.mindbender.enabled
	if castFriend() then
		return true;
	end
	-- actions.cop_insanity+=/shadow_word_pain,if=remains<(18*0.3)&target.time_to_die>(18*0.75)&miss_react&active_enemies<=5&primary_target=0,cycle_targets=1,max_cycle_targets=5
	if D:notEnoughEnemies(5) and (castPain(18*0.3,18*0.75) or castPain(18*0.3,18*0.75,"mouseover")) then
		return true;
	end
	-- actions.cop_insanity+=/vampiric_touch,if=remains<(15*0.3+cast_time)&target.time_to_die>(15*0.75+cast_time)&miss_react&active_enemies<=5&primary_target=0,cycle_targets=1,max_cycle_targets=5
	local castTimeTouch = OvaleSpellBook:GetCastTime(34914);
	if D:notEnoughEnemies(5) and (castTouch(15*0.3+castTimeTouch,15*0.75+castTimeTouch) or castTouch(15*0.3+castTimeTouch,15*0.75+castTimeTouch,"mouseover")) then
		return true;
	end
	-- actions.cop_insanity+=/insanity,if=buff.insanity.remains<0.5*gcd&active_enemies<=2,chain=1
	-- ,interrupt_if=(cooldown.mind_blast.remains<=0.1|(cooldown.shadow_word_death.remains<=0.1&target.health.pct<20))

	-- actions.cop_insanity+=/insanity,if=active_enemies<=2,chain=1
	-- ,interrupt_if=(cooldown.mind_blast.remains<=0.1|(cooldown.shadow_word_death.remains<=0.1&target.health.pct<20))
	if D:CastReadable() and WA_CheckSpellUsable("狂乱") and CCFightType==1 then
		CCFlagSpell("精神鞭笞");
		return true;
	end
	-- actions.cop_insanity+=/halo,if=talent.halo.enabled&!set_bonus.tier18_4pc&target.distance<=30&target.distance>=17
	-- actions.cop_insanity+=/cascade,if=talent.cascade.enabled&!set_bonus.tier18_4pc&((active_enemies>1|target.distance>=28)&target.distance<=40&target.distance>=11)
	-- actions.cop_insanity+=/divine_star,if=talent.divine_star.enabled&!set_bonus.tier18_4pc&active_enemies>2&target.distance<=24
	-- actions.cop_insanity+=/halo,if=talent.halo.enabled&set_bonus.tier18_4pc&buff.premonition.up&target.distance<=30&target.distance>=17
	-- actions.cop_insanity+=/cascade,if=talent.cascade.enabled&set_bonus.tier18_4pc&buff.premonition.up&((active_enemies>1|target.distance>=28)&target.distance<=40&target.distance>=11)
	-- actions.cop_insanity+=/divine_star,if=talent.divine_star.enabled&set_bonus.tier18_4pc&buff.premonition.up&active_enemies>2&target.distance<=24

	if WA_CheckSpellUsable("光晕") and not D:ArmorSetBonus("T18",4) and D:Distance()<=30 and D:Distance()>=17 then
		CCFlagSpell("光晕");
		return true;
	end
	--&(active_enemies>1|target.distance>=28)&target.distance<=40&target.distance>=11
	if WA_CheckSpellUsable("瀑流") and not D:ArmorSetBonus("T18",4) and (D:hasEnemies(2) or D:Distance()>=28) and D:Distance()<=40 and D:Distance()>=11 then
		CCFlagSpell("瀑流");
		return true;
	end
	--&active_enemies>3&target.distance<=24
	if WA_CheckSpellUsable("神圣之星") and not D:ArmorSetBonus("T18",4) and D:hasEnemies(4) and D:Distance()<=24 then
		CCFlagSpell("神圣之星");
		return true;
	end
	--&buff.premonition.up&target.distance<=30&target.distance>=17
	if WA_CheckSpellUsable("光晕") and D:ArmorSetBonus("T18",4) and D:Distance()<=30 and D:Distance()>=17 and not WA_CheckBuff(188779) then
		CCFlagSpell("光晕");
		return true;
	end
	--&buff.premonition.up&(active_enemies>1|target.distance>=28)&target.distance<=40&target.distance>=11
	if WA_CheckSpellUsable("瀑流") and D:ArmorSetBonus("T18",4) and not WA_CheckBuff(188779) and (D:hasEnemies(2) or D:Distance()>=28) and D:Distance()<=40 and D:Distance()>=11 then
		CCFlagSpell("瀑流");
		return true;
	end
	--&buff.premonition.up&active_enemies>3&target.distance<=24
	if WA_CheckSpellUsable("神圣之星") and D:ArmorSetBonus("T18",4) and not WA_CheckBuff(188779) and D:hasEnemies(4) and D:Distance()<=24 then
		CCFlagSpell("神圣之星");
		return true;
	end
	-- actions.cop_insanity+=/mind_sear,if=active_enemies>=8
	-- ,interrupt_if=(cooldown.mind_blast.remains<=0.1|cooldown.shadow_word_death.remains<=0.1),target_if=max:spell_targets.mind_sear_tick
	if D:CastReadable() and WA_CheckSpellUsable("精神灼烧") and CCFightType==2 then
		CCFlagSpell("精神灼烧");
		return true;
	end
	-- actions.cop_insanity+=/mind_spike
	if D:CastReadable() and WA_CheckSpellUsable("心灵尖刺") then
		CCFlagSpell("心灵尖刺");
		return true;
	end
	-- actions.cop_insanity+=/shadow_word_death,moving=1,if=!target.dot.shadow_word_pain.ticking&!target.dot.vampiric_touch.ticking,cycle_targets=1
	-- actions.cop_insanity+=/shadow_word_death,moving=1,if=movement.remains>=1*gcd
	-- actions.cop_insanity+=/power_word_shield,moving=1,if=talent.body_and_soul.enabled&movement.distance>=25
	-- actions.cop_insanity+=/halo,if=talent.halo.enabled&target.distance<=30,moving=1
	-- actions.cop_insanity+=/divine_star,if=talent.divine_star.enabled&target.distance<=28,moving=1
	-- actions.cop_insanity+=/cascade,if=talent.cascade.enabled&target.distance<=40,moving=1
	-- actions.cop_insanity+=/devouring_plague,moving=1
	-- actions.cop_insanity+=/shadow_word_pain,if=primary_target=0,moving=1,cycle_targets=1

	-- moving mode
	if D:castDeath() or D:castDeath("mouseover") then
		return true;
	end
	if WA_CheckSpellUsable("光晕") and D:Distance()<=30 then
		CCFlagSpell("光晕");
		return true;
	end
	if WA_CheckSpellUsable("神圣之星") and D:Distance()<=28 then
		CCFlagSpell("神圣之星");
		return true;
	end
	if WA_CheckSpellUsable("瀑流") and D:Distance()<=40 then
		CCFlagSpell("瀑流");
		return true;
	end
	if castPlague() then
		return true;
	end

	if WA_CheckSpellUsableOn("真言术：盾") and OvaleSpellBook:GetTalentPoints(64129)>0 then
		CCFlagSpell("真言术：盾");
		return true;
	end
end
local function cop_dotweave()
	-- actions.cop_dotweave=devouring_plague,if=target.dot.vampiric_touch.ticking&target.dot.shadow_word_pain.ticking&shadow_orb=5&cooldown_react
	-- actions.cop_dotweave+=/devouring_plague,if=buff.mental_instinct.remains<gcd&buff.mental_instinct.remains>(gcd*0.7)&buff.mental_instinct.remains
	-- actions.cop_dotweave+=/devouring_plague,if=(target.dot.vampiric_touch.ticking&target.dot.shadow_word_pain.ticking&!buff.insanity.remains&cooldown.mind_blast.remains>0.4*gcd)
	-- actions.cop_dotweave+=/shadow_word_death,if=target.health.pct<20&!target.dot.shadow_word_pain.ticking&!target.dot.vampiric_touch.ticking,cycle_targets=1
	-- actions.cop_dotweave+=/shadow_word_death,if=target.health.pct<20,cycle_targets=1
	if castDeath() or castDeath("mouseover") then
		return true;
	end
	-- actions.cop_dotweave+=/mind_blast,if=glyph.mind_harvest.enabled&mind_harvest=0&shadow_orb<=2,cycle_targets=1
	if rbs()<=2 and castBlastHarvest() then
		return true;
	end
	-- actions.cop_dotweave+=/mind_blast,if=shadow_orb<=4&cooldown_react
	if rbs()<=4 and (castBlast() or castBlast("mouseover")) then
		return true;
	end
	-- actions.cop_dotweave+=/shadowfiend,if=!talent.mindbender.enabled&set_bonus.tier18_2pc
	-- actions.cop_dotweave+=/mindbender,if=talent.mindbender.enabled&set_bonus.tier18_2pc
	if D:ArmorSetBonus("T18",2) and castFriend() then
		return true;
	end
	-- actions.cop_dotweave+=/searing_insanity,if=buff.insanity.remains<0.5*gcd&active_enemies>=3&cooldown.mind_blast.remains>0.5*gcd,chain=1,interrupt_if=(cooldown.mind_blast.remains<=0.1|cooldown.shadow_word_death.remains<=0.1),target_if=max:spell_targets.mind_sear_tick
	-- actions.cop_dotweave+=/searing_insanity,if=active_enemies>=3&cooldown.mind_blast.remains>0.5*gcd
	-- ,interrupt_if=(cooldown.mind_blast.remains<=0.1|cooldown.shadow_word_death.remains<=0.1)
	-- ,target_if=max:spell_targets.mind_sear_tick
	if WA_CheckSpellUsable("狂乱灼烧") and CCFightType==2 then
		CCFlagSpell("精神灼烧");
		return true;
	end
	-- actions.cop_dotweave+=/shadowfiend,if=!talent.mindbender.enabled&!buff.insanity.remains
	-- actions.cop_dotweave+=/mindbender,if=talent.mindbender.enabled&!buff.insanity.remains
	if WA_CheckBuff(132573) and castFriend() then
		return true;
	end
	-- actions.cop_dotweave+=/shadow_word_pain,if=shadow_orb=4&set_bonus.tier17_2pc&!target.dot.shadow_word_pain.ticking&!target.dot.devouring_plague.ticking&cooldown.mind_blast.remains<gcd&cooldown.mind_blast.remains>0
	-- actions.cop_dotweave+=/shadow_word_pain,if=shadow_orb=5&!target.dot.devouring_plague.ticking&!target.dot.shadow_word_pain.ticking

	-- actions.cop_dotweave+=/vampiric_touch,if=shadow_orb=5&!target.dot.devouring_plague.ticking&!target.dot.vampiric_touch.ticking
	-- actions.cop_dotweave+=/insanity,if=buff.insanity.remains,chain=1,interrupt_if=cooldown.mind_blast.remains<=0.1
	-- actions.cop_dotweave+=/shadow_word_pain,if=shadow_orb>=2&target.dot.shadow_word_pain.remains>=6&cooldown.mind_blast.remains>0.5*gcd&target.dot.vampiric_touch.remains&buff.bloodlust.up&!set_bonus.tier17_2pc
	-- actions.cop_dotweave+=/vampiric_touch,if=shadow_orb>=2&target.dot.vampiric_touch.remains>=5&cooldown.mind_blast.remains>0.5*gcd&buff.bloodlust.up&!set_bonus.tier17_2pc
	-- actions.cop_dotweave+=/halo,if=talent.halo.enabled&!set_bonus.tier18_4pc&cooldown.mind_blast.remains>0.5*gcd&target.distance<=30&target.distance>=17
	-- actions.cop_dotweave+=/cascade,if=talent.cascade.enabled&!set_bonus.tier18_4pc&cooldown.mind_blast.remains>0.5*gcd&((active_enemies>1|target.distance>=28)&target.distance<=40&target.distance>=11)
	-- actions.cop_dotweave+=/divine_star,if=talent.divine_star.enabled&!set_bonus.tier18_4pc&cooldown.mind_blast.remains>0.5*gcd&active_enemies>3&target.distance<=24
	-- actions.cop_dotweave+=/halo,if=talent.halo.enabled&set_bonus.tier18_4pc&buff.premonition.up&cooldown.mind_blast.remains>0.5*gcd&target.distance<=30&target.distance>=17
	-- actions.cop_dotweave+=/cascade,if=talent.cascade.enabled&set_bonus.tier18_4pc&buff.premonition.up&cooldown.mind_blast.remains>0.5*gcd&((active_enemies>1|target.distance>=28)&target.distance<=40&target.distance>=11)
	-- actions.cop_dotweave+=/divine_star,if=talent.divine_star.enabled&set_bonus.tier18_4pc&buff.premonition.up&cooldown.mind_blast.remains>0.5*gcd&active_enemies>3&target.distance<=24
	-- actions.cop_dotweave+=/shadow_word_pain,if=primary_target=0&!ticking,cycle_targets=1,max_cycle_targets=5
	-- actions.cop_dotweave+=/vampiric_touch,if=primary_target=0&!ticking,cycle_targets=1,max_cycle_targets=5
	-- actions.cop_dotweave+=/divine_star,if=talent.divine_star.enabled&cooldown.mind_blast.remains>0.5*gcd&active_enemies=3&target.distance<=24
	-- actions.cop_dotweave+=/shadow_word_pain,if=primary_target=0&(!ticking|remains<=18*0.3)&target.time_to_die>(18*0.75),cycle_targets=1,max_cycle_targets=5
	-- actions.cop_dotweave+=/vampiric_touch,if=primary_target=0&(!ticking|remains<=15*0.3+cast_time)&target.time_to_die>(15*0.75+cast_time),cycle_targets=1,max_cycle_targets=5
	-- actions.cop_dotweave+=/mind_sear,if=active_enemies>=8,interrupt_if=(cooldown.mind_blast.remains<=0.1|cooldown.shadow_word_death.remains<=0.1),target_if=max:spell_targets.mind_sear_tick
	-- actions.cop_dotweave+=/mind_spike
	-- actions.cop_dotweave+=/shadow_word_death,moving=1,if=!target.dot.shadow_word_pain.ticking&!target.dot.vampiric_touch.ticking,cycle_targets=1
	-- actions.cop_dotweave+=/shadow_word_death,moving=1,if=movement.remains>=1*gcd
	-- actions.cop_dotweave+=/power_word_shield,moving=1,if=talent.body_and_soul.enabled&movement.distance>=25
	-- actions.cop_dotweave+=/halo,if=talent.halo.enabled&target.distance<=30,moving=1
	-- actions.cop_dotweave+=/divine_star,if=talent.divine_star.enabled&target.distance<=28,moving=1
	-- actions.cop_dotweave+=/cascade,if=talent.cascade.enabled&target.distance<=40,moving=1
	-- actions.cop_dotweave+=/devouring_plague,moving=1
	-- actions.cop_dotweave+=/shadow_word_pain,if=primary_target=0,moving=1,cycle_targets=1
end
local function cop()
	local timeToBlast = WA_CooldownLeft("心灵震爆",true);
	local state = OvaleState.state;
	if D:ArmorSetBonus("T18",2) and castFriend() then
		return true;
	end
	-- actions.cop+=/devouring_plague,if=shadow_orb=5&primary_target=0&!target.dot.devouring_plague_dot.ticking&target.time_to_die>=(gcd*4*7%6),cycle_targets=1
	-- actions.cop+=/devouring_plague,if=shadow_orb=5&primary_target=0&target.time_to_die>=(gcd*4*7%6)&(cooldown.mind_blast.remains<=gcd|(cooldown.shadow_word_death.remains<=gcd&target.health.pct<20)),cycle_targets=1
	-- actions.cop+=/devouring_plague,if=shadow_orb=5&!set_bonus.tier17_2pc&(cooldown.mind_blast.remains<=gcd|(cooldown.shadow_word_death.remains<=gcd&target.health.pct<20))
	-- actions.cop+=/devouring_plague,if=shadow_orb=5&set_bonus.tier17_2pc&(cooldown.mind_blast.remains<=gcd*2|(cooldown.shadow_word_death.remains<=gcd&target.health.pct<20))
	-- actions.cop+=/devouring_plague,if=primary_target=0&buff.mental_instinct.remains<gcd&buff.mental_instinct.remains>(gcd*0.7)&buff.mental_instinct.remains&active_enemies>1,cycle_targets=1
	-- actions.cop+=/devouring_plague,if=buff.mental_instinct.remains<gcd&buff.mental_instinct.remains>(gcd*0.7)&buff.mental_instinct.remains&active_enemies>1
	-- actions.cop+=/devouring_plague,if=shadow_orb>=3&!set_bonus.tier17_2pc&!set_bonus.tier17_4pc&(cooldown.mind_blast.remains<=gcd|(cooldown.shadow_word_death.remains<=gcd&target.health.pct<20))&primary_target=0&target.time_to_die>=(gcd*4*7%6),cycle_targets=1
	-- actions.cop+=/devouring_plague,if=shadow_orb>=3&!set_bonus.tier17_2pc&!set_bonus.tier17_4pc&(cooldown.mind_blast.remains<=gcd|(cooldown.shadow_word_death.remains<=gcd&target.health.pct<20))
	-- actions.cop+=/devouring_plague,if=shadow_orb>=3&set_bonus.tier17_2pc&!set_bonus.tier17_4pc&(cooldown.mind_blast.remains<=gcd*2|(cooldown.shadow_word_death.remains<=gcd&target.health.pct<20))&primary_target=0&target.time_to_die>=(gcd*4*7%6)&active_enemies>1,cycle_targets=1
	-- actions.cop+=/devouring_plague,if=shadow_orb>=3&set_bonus.tier17_2pc&!set_bonus.tier17_4pc&(cooldown.mind_blast.remains<=gcd*2|(cooldown.shadow_word_death.remains<=gcd&target.health.pct<20))&active_enemies>1
	-- actions.cop+=/devouring_plague,if=shadow_orb>=3&set_bonus.tier17_2pc&talent.mindbender.enabled&!target.dot.devouring_plague_dot.ticking&(cooldown.mind_blast.remains<=gcd*2|(cooldown.shadow_word_death.remains<=gcd&target.health.pct<20))&primary_target=0&target.time_to_die>=(gcd*4*7%6)&active_enemies=1,cycle_targets=1
	-- actions.cop+=/devouring_plague,if=shadow_orb>=3&set_bonus.tier17_2pc&talent.mindbender.enabled&!target.dot.devouring_plague_dot.ticking&(cooldown.mind_blast.remains<=gcd*2|(cooldown.shadow_word_death.remains<=gcd&target.health.pct<20))&active_enemies=1
	-- actions.cop+=/devouring_plague,if=shadow_orb>=3&set_bonus.tier17_2pc&talent.surge_of_darkness.enabled&buff.mental_instinct.remains<(gcd*1.4)&buff.mental_instinct.remains>(gcd*0.7)&buff.mental_instinct.remains&(cooldown.mind_blast.remains<=gcd*2|(cooldown.shadow_word_death.remains<=gcd&target.health.pct<20))&primary_target=0&target.time_to_die>=(gcd*4*7%6)&active_enemies=1,cycle_targets=1
	if OvaleSpellBook:IsActiveGlyph(162532) and WA_CheckDebuff(162532,0,0,true,"target") and castBlast() then
		return true;
	end
	if OvaleSpellBook:IsActiveGlyph(162532) and WA_CheckDebuff(162532,0,0,true,"mouseover") and castBlast("mouseover") then
		return true;
	end
	if OvaleSpellBook:GetTalentPoints(155271) and CCFightType==1 and castBlast() then
		return true;
	end
	if castDeath() or castDeath("mouseover") then
		return true;
	end

	if castFriend() then
		return true;
	end

	if WA_CheckSpellUsable("光晕") and not D:ArmorSetBonus("T18",4) and D:Distance()<=30 and D:Distance()>=17 then
		CCFlagSpell("光晕");
		return true;
	end
	--&(active_enemies>1|target.distance>=28)&target.distance<=40&target.distance>=11
	if WA_CheckSpellUsable("瀑流") and not D:ArmorSetBonus("T18",4) and (D:hasEnemies(2) or D:Distance()>=28) and D:Distance()<=40 and D:Distance()>=11 then
		CCFlagSpell("瀑流");
		return true;
	end
	--&active_enemies>3&target.distance<=24
	if WA_CheckSpellUsable("神圣之星") and not D:ArmorSetBonus("T18",4) and D:hasEnemies(4) and D:Distance()<=24 then
		CCFlagSpell("神圣之星");
		return true;
	end
	--&buff.premonition.up&target.distance<=30&target.distance>=17
	if WA_CheckSpellUsable("光晕") and D:ArmorSetBonus("T18",4) and D:Distance()<=30 and D:Distance()>=17 and not WA_CheckBuff(188779) then
		CCFlagSpell("光晕");
		return true;
	end
	--&buff.premonition.up&(active_enemies>1|target.distance>=28)&target.distance<=40&target.distance>=11
	if WA_CheckSpellUsable("瀑流") and D:ArmorSetBonus("T18",4) and not WA_CheckBuff(188779) and (D:hasEnemies(2) or D:Distance()>=28) and D:Distance()<=40 and D:Distance()>=11 then
		CCFlagSpell("瀑流");
		return true;
	end
	--&buff.premonition.up&active_enemies>3&target.distance<=24
	if WA_CheckSpellUsable("神圣之星") and D:ArmorSetBonus("T18",4) and not WA_CheckBuff(188779) and D:hasEnemies(4) and D:Distance()<=24 then
		CCFlagSpell("神圣之星");
		return true;
	end
	if castPain(18*0.3,18*0.75) or castPain(18*0.3,18*0.75,"mouseover") then
		return true;
	end
	local castTimeTouch = OvaleSpellBook:GetCastTime(34914);
	if (castTouch(15*0.3+castTimeTouch,15*0.75) or castTouch(15*0.3+castTimeTouch,15*0.75,"mouseover")) then
		return true;
	end
	-- actions.cop+=/divine_star,if=talent.divine_star.enabled&active_enemies=3&target.distance<=24
	if WA_CheckSpellUsable("神圣之星") and D:hasEnemies(3) and D:Distance()<=24 then
		CCFlagSpell("神圣之星");
		return true;
	end
	-- actions.cop+=/mind_spike,if=active_enemies<=4&buff.surge_of_darkness.react
	if D:CastReadable() and WA_CheckSpellUsable("心灵尖刺") and D:notEnoughEnemies(4) and not WA_CheckBuff(87160) then
		CCFlagSpell("心灵尖刺");
		return true;
	end
	-- actions.cop+=/mind_sear,if=active_enemies>=8
	-- ,interrupt_if=(cooldown.mind_blast.remains<=0.1|cooldown.shadow_word_death.remains<=0.1),target_if=max:spell_targets.mind_sear_tick
	if D:CastReadable() and WA_CheckSpellUsable("精神灼烧") and CCFightType==2 and  D:hasEnemies(8) then
		CCFlagSpell("精神灼烧");
		return true;
	end
	-- actions.cop+=/mind_spike,if=target.dot.devouring_plague_tick.remains&target.dot.devouring_plague_tick.remains<cast_time

	local castTimeSpike = OvaleSpellBook:GetCastTime(73510);
	if D:CastReadable() and WA_CheckSpellUsable("心灵尖刺") and WA_CheckDebuff("噬灵疫病",castTimeSpike,0,true) and not WA_CheckDebuff("噬灵疫病",0,0,true) then
		CCFlagSpell("心灵尖刺");
		return true;
	end
	-- actions.cop+=/mind_flay,if=target.dot.devouring_plague_tick.ticks_remain>1
	-- &active_enemies>1,chain=1
	-- ,interrupt_if=(cooldown.mind_blast.remains<=0.1|cooldown.shadow_word_death.remains<=0.1)
	if D:CastReadable() and WA_CheckSpellUsable("精神鞭笞") and not WA_CheckDebuff("噬灵疫病",3,0,true) and D:hasEnemies(2) then
		CCFlagSpell("精神鞭笞");
		return true;
	end
	-- actions.cop+=/mind_spike
	if D:CastReadable() and WA_CheckSpellUsable("心灵尖刺") then
		CCFlagSpell("心灵尖刺");
		return true;
	end
	-- moving mode
	-- actions.cop+=/shadow_word_death,moving=1,if=!target.dot.shadow_word_pain.ticking&!target.dot.vampiric_touch.ticking,cycle_targets=1
	-- actions.cop+=/shadow_word_death,moving=1,if=movement.remains>=1*gcd
	if D:castDeath() or D:castDeath("mouseover") then
		return true;
	end
	-- actions.cop+=/power_word_shield,moving=1,if=talent.body_and_soul.enabled&movement.distance>=25
	-- 移到最后
	-- actions.cop+=/halo,moving=1,if=talent.halo.enabled&target.distance<=30
	if WA_CheckSpellUsable("光晕") and D:Distance()<=30 then
		CCFlagSpell("光晕");
		return true;
	end
	-- actions.cop+=/divine_star,if=talent.divine_star.enabled&target.distance<=28,moving=1
	if WA_CheckSpellUsable("神圣之星") and D:Distance()<=28 then
		CCFlagSpell("神圣之星");
		return true;
	end
	-- actions.cop+=/cascade,if=talent.cascade.enabled&target.distance<=40,moving=1
	if WA_CheckSpellUsable("瀑流") and D:Distance()<=40 then
		CCFlagSpell("瀑流");
		return true;
	end
	-- actions.cop+=/devouring_plague,moving=1
	if castPlague() then
		return true;
	end

	if WA_CheckSpellUsableOn("真言术：盾") and OvaleSpellBook:GetTalentPoints(64129)>0 then
		CCFlagSpell("真言术：盾");
		return true;
	end

end
local function cop_row_insanity_death()
	local state = OvaleState.state;
	if not WA_CheckSpellUsable("心灵震爆") and WA_CooldownLeft("心灵震爆",true)<0.3 then
		return true;
	end
	if castBlast() or castBlast("mouseover") then
		return true;
	end
	-- actions.cop_row_insanity_death+=/insanity,interrupt=1
	if WA_CooldownLeft("心灵震爆",true)<=state:GetGCD()*2
	and ((WA_CheckDebuff(185104,state:GetGCD(),true) and castPlague())
	or (WA_CheckDebuff(185104,state:GetGCD(),true,"mouseover") and castPlague("mouseover"))) then
		return true;
	end
	--actions.cop_row_insanity_death+=/shadowfiend,if=!(!target.debuff.mental_fatigue.up|target.debuff.mental_fatigue.stack<5|(target.debuff.mental_fatigue.remains<=gcd|(target.debuff.mental_fatigue.remains<=gcd*2&cooldown.mindblast.remains<=gcd)))
	if not mental_fatigue_check() and castFriend() then
		return true;
	end

	if D:CastReadable() and WA_CheckSpellUsable("心灵尖刺") and not mental_fatigue_check() then
		CCFlagSpell("心灵尖刺");
		return true;
	end
	if D:CastReadable() and WA_CheckSpellUsable("精神鞭笞") and mental_fatigue_check() then
		CCFlagSpell("精神鞭笞");
		return true;
	end
end
local function cop_row_insanity_build()
	local state = OvaleState.state;
	if not WA_CheckSpellUsable("心灵震爆") and WA_CooldownLeft("心灵震爆",true)<0.3 then
		return true;
	end
	if castBlast() or castBlast("mouseover") then
		return true;
	end
	-- actions.cop_row_insanity_build+=/insanity,interrupt=1
	-- actions.cop_row_insanity_build+=/shadowfiend,if=!(!target.debuff.mental_fatigue.up|target.debuff.mental_fatigue.stack<5|(target.debuff.mental_fatigue.remains<=gcd|(target.debuff.mental_fatigue.remains<=gcd*2&cooldown.mindblast.remains<=gcd)))
	if not mental_fatigue_check() and castFriend() then
		return true;
	end

	if D:CastReadable() and WA_CheckSpellUsable("心灵尖刺") and not mental_fatigue_check() then
		CCFlagSpell("心灵尖刺");
		return true;
	end
	if D:CastReadable() and WA_CheckSpellUsable("精神鞭笞") and mental_fatigue_check() then
		CCFlagSpell("精神鞭笞");
		return true;
	end

end
local function cop_row_insanity_spend()
	local state = OvaleState.state;
	if not WA_CheckSpellUsable("心灵震爆") and WA_CooldownLeft("心灵震爆",true)<0.3 then
		return true;
	end
	if castBlast() or castBlast("mouseover") then
		return true;
	end
	-- actions.cop_row_insanity_spend+=/insanity,interrupt=1
	-- 狂乱？？
	--actions.cop_row_insanity_spend+=/devouring_plague,if=cooldown.mind_blast.remains<=gcd*2
	-- &!target.debuff.mental_fatigue.remains<=gcd
	if WA_CooldownLeft("心灵震爆",true)<=state:GetGCD()*2
	and ((WA_CheckDebuff(185104,state:GetGCD(),true) and castPlague())
	or (WA_CheckDebuff(185104,state:GetGCD(),true,"mouseover") and castPlague("mouseover"))) then
		return true;
	end
	-- actions.cop_row_insanity_spend+=/shadowfiend,if=!(!target.debuff.mental_fatigue.up|target.debuff.mental_fatigue.stack<5|(target.debuff.mental_fatigue.remains<=gcd|(target.debuff.mental_fatigue.remains<=gcd*2&cooldown.mindblast.remains<=gcd)))
	if not mental_fatigue_check() and castFriend() then
		return true;
	end
	-- what's this?
	-- actions.cop_row_insanity_spend+=/mind_spike,if=
	-- !(!target.debuff.mental_fatigue.up|target.debuff.mental_fatigue.stack<5
	-- |(target.debuff.mental_fatigue.remains<=gcd
	-- |(target.debuff.mental_fatigue.remains<=gcd*2&cooldown.mindblast.remains<=gcd)))
	if D:CastReadable() and WA_CheckSpellUsable("心灵尖刺") and not mental_fatigue_check() then
		CCFlagSpell("心灵尖刺");
		return true;
	end
	--actions.cop_row_insanity_spend+=/mind_flay,if=
	-- (!target.debuff.mental_fatigue.up|target.debuff.mental_fatigue.stack<5
	-- |(target.debuff.mental_fatigue.remains<=gcd|(target.debuff.mental_fatigue.remains<=gcd*2
	-- &cooldown.mindblast.remains<=gcd)))
	--,interrupt=1,chain=1
	if D:CastReadable() and WA_CheckSpellUsable("精神鞭笞") and mental_fatigue_check() then
		CCFlagSpell("精神鞭笞");
		return true;
	end
end
local function vent()
end
local function main()
	local timeToBlast = WA_CooldownLeft("心灵震爆",true);
	local state = OvaleState.state;
	if castFriend() then
		return true;
	end
	--actions.main+=/shadow_word_death,if=target.health.pct<20&shadow_orb<=4,cycle_targets=1
	if rbs()<=4 and (castDeath() or castDeath("mouseover")) then
		return true;
	end
	--actions.main+=/mind_blast,if=glyph.mind_harvest.enabled&shadow_orb<=2&active_enemies<=5&cooldown_react
	if OvaleSpellBook:IsActiveGlyph(162532) and rbs()<=2 and CCFightType==1 and castBlast() then
		return true;
	end
	--actions.main+=/devouring_plague,if=shadow_orb=5&!target.dot.devouring_plague_dot.ticking&(talent.surge_of_darkness.enabled|set_bonus.tier17_4pc),cycle_targets=1
	if castPlague1() or castPlague1("mouseover") or castPlague2()
	or castPlague2("mouseover") or castPlague3() or castPlague3("mouseover")
	or castPlague4() or castPlague4("mouseover")
	or castPlague5() or castPlague5("mouseover")
	then
		return true;
	end

	if castBlastHarvest() then
		return true;
	end
	if OvaleSpellBook:GetTalentPoints(155271) and CCFightType==1 and castBlast() then
		return true;
	end

	if OvaleSpellBook:GetTalentPoints(155271) and (castPain(18*0.3,18*0.75) or castPain(18*0.3,18*0.75,"mouseover")) then
		return true;
	end
	if castBlast() then
		return true;
	end
	-- 狂乱？
	--actions.main+=/insanity,if=t18_class_trinket&target.debuff.mental_fatigue.remains<gcd,interrupt_if=target.debuff.mental_fatigue.remains>gcd
	--actions.main+=/mind_flay,if=t18_class_trinket&(target.debuff.mental_fatigue.remains<gcd|(cooldown.mind_blast.remains<2*gcd&target.debuff.mental_fatigue.remains<2*gcd))
	-- ,interrupt_if=target.debuff.mental_fatigue.remains>gcd  这是一个有意思的地方 就是需要打断精神鞭笞
	if D:CastReadable() and OvaleEquipment:HasTrinket(124519) and (WA_CheckDebuff(185104,state:GetGCD(),0,true) or (timeToBlast<2*state:GetGCD() and WA_CheckDebuff(185104,2*state:GetGCD(),0,true))) and WA_CheckSpellUsable("精神鞭笞") then
		CCFlagSpell("精神鞭笞");
		return true;
	end

	if D:CastReadable() and CCFightType==2 and WA_CheckSpellUsable("精神灼烧") then
		CCFlagSpell("精神灼烧");
		return true;
	end
	-- actions.main+=/insanity,if=buff.insanity.remains<0.5*gcd&active_enemies<=2,chain=1,interrupt_if=(cooldown.mind_blast.remains<=0.1|cooldown.shadow_word_death.remains<=0.1|shadow_orb=5)
	-- actions.main+=/insanity,chain=1,if=active_enemies<=2,interrupt_if=(cooldown.mind_blast.remains<=0.1|cooldown.shadow_word_death.remains<=0.1|shadow_orb=5)
	if WA_CheckSpellUsable("光晕") and D:Distance()<30 and D:hasEnemies(3) then
		CCFlagSpell("光晕");
		return true;
	end
	-- actions.main+=/cascade,if=talent.cascade.enabled&set_bonus.tier18_4pc&buff.premonition.up&active_enemies>2
	-- &target.distance<=40
	if WA_CheckSpellUsable("瀑流") and D:ArmorSetBonus("T18",4) and not WA_CheckBuff(188779) and D:hasEnemies(3) and D:Distance()<=40 then
		CCFlagSpell("瀑流");
		return true;
	end
	--actions.main+=/divine_star,if=talent.divine_star.enabled&set_bonus.tier18_4pc&buff.premonition.up&active_enemies>4&target.distance<=24
	if WA_CheckSpellUsable("神圣之星") and D:ArmorSetBonus("T18",4) and not WA_CheckBuff(188779) and D:hasEnemies(5) and D:Distance()<=24 then
		CCFlagSpell("神圣之星");
		return true;
	end
	--actions.main+=/cascade,if=talent.cascade.enabled&!set_bonus.tier18_4pc&active_enemies>2&target.distance<=40
	if WA_CheckSpellUsable("瀑流") and not D:ArmorSetBonus("T18",4) and D:hasEnemies(3) and D:Distance()<=40 then
		CCFlagSpell("瀑流");
		return true;
	end
	--actions.main+=/divine_star,if=talent.divine_star.enabled&!set_bonus.tier18_4pc&active_enemies>4&target.distance<=24
	if WA_CheckSpellUsable("神圣之星") and not D:ArmorSetBonus("T18",4) and D:hasEnemies(5) and D:Distance()<=24 then
		CCFlagSpell("神圣之星");
		return true;
	end
	--actions.main+=/shadow_word_pain,if=!talent.auspicious_spirits.enabled&remains<(18*0.3)&target.time_to_die>(18*0.75)
	-- &miss_react&active_enemies<=5,cycle_targets=1,max_cycle_targets=5
	if not OvaleSpellBook:GetTalentPoints(155271) and (castPain(18*0.3,18*0.75) or castPain(18*0.3,18*0.75,"mouseover")) then
		return true;
	end
	--actions.main+=/vampiric_touch,if=remains<(15*0.3+cast_time)&target.time_to_die>(15*0.75+cast_time)
	-- &miss_react&active_enemies<=5,cycle_targets=1,max_cycle_targets=5
	local castTimeTouch = OvaleSpellBook:GetCastTime(34914);
	if (castTouch(15*0.3+castTimeTouch,15*0.75) or castTouch(15*0.3+castTimeTouch,15*0.75,"mouseover")) then
		return true;
	end
	--actions.main+=/devouring_plague,if=!talent.void_entropy.enabled&shadow_orb>=3&ticks_remain<=1
	if rbs>=3 and OvaleSpellBook:GetTalentPoints(155361)==0 and (castPlague("target",0.5) or castPlague("mouseover",0.5)) then
		return true;
	end
end

local function pvp_dispersion()
	if WA_CheckSpellUsableOn("心灵震爆") then
		CCFlagSpell("消散");
		return true;
	end
	-- 应该取消掉这个buf
	return decision();
end

local function decision()
--actions.decision=call_action_list,name=main,if=(!talent.clarity_of_power.enabled&!talent.void_entropy.enabled)|(talent.clarity_of_power.enabled&!t18_class_trinket&buff.bloodlust.up&buff.power_infusion.up)
	if ((OvaleSpellBook:GetTalentPoints(155246)==0 and OvaleSpellBook:GetTalentPoints(155361)==0) or (OvaleSpellBook:GetTalentPoints(155246)>0 and not OvaleEquipment:HasTrinket(124519) and not WA_CheckBuff("嗜血") and not WA_CheckBuff("能量灌注")))
	and main() then
		return true;
	end
	--actions.decision+=/call_action_list,name=vent,if=talent.void_entropy.enabled&!talent.clarity_of_power.enabled&!talent.auspicious_spirits.enabled
	if OvaleSpellBook:GetTalentPoints(155361)>0 and vent() then
		return true;
	end
	--actions.decision+=/call_action_list,name=cop_row_insanity_spend,if=active_enemies=1&talent.clarity_of_power.enabled&talent.insanity.enabled&t18_class_trinket&target.health.pct>20&shadow_orb=5
	if CCFightType==1 and not D.FightHSMode and OvaleSpellBook:GetTalentPoints(155246)>0 and OvaleSpellBook:GetTalentPoints(139139)>0 and OvaleEquipment:HasTrinket(124519) and targetPct()>20 and rbs()==5 and cop_row_insanity_spend() then
		return true;
	end
	--actions.decision+=/call_action_list,name=cop_row_insanity_build,if=active_enemies=1&talent.clarity_of_power.enabled&talent.insanity.enabled&t18_class_trinket&target.health.pct>20&shadow_orb<5
	if CCFightType==1 and not D.FightHSMode and OvaleSpellBook:GetTalentPoints(155246)>0 and OvaleSpellBook:GetTalentPoints(139139)>0 and OvaleEquipment:HasTrinket(124519) and targetPct()>20 and rbs()<5 and cop_row_insanity_build() then
		return true;
	end
	--actions.decision+=/call_action_list,name=cop_row_insanity_death,if=active_enemies=1&talent.clarity_of_power.enabled&talent.insanity.enabled&t18_class_trinket&target.health.pct<=20
	if CCFightType==1 and not D.FightHSMode and OvaleSpellBook:GetTalentPoints(155246)>0 and OvaleSpellBook:GetTalentPoints(139139)>0 and OvaleEquipment:HasTrinket(124519) and targetPct()<=20 and cop_row_insanity_death() then
		return true;
	end
	--actions.decision+=/call_action_list,name=cop,if=talent.clarity_of_power.enabled&!talent.insanity.enabled
	if OvaleSpellBook:GetTalentPoints(155246)>0 and OvaleSpellBook:GetTalentPoints(139139)==0 and cop() then
		return true;
	end
	-- actions.decision+=/call_action_list,name=cop_dotweave,if=talent.clarity_of_power.enabled&talent.insanity.enabled&target.health.pct>20&active_enemies<=6
	-- active_enemies<=6? no aoe?
	if OvaleSpellBook:GetTalentPoints(155246)>0 and OvaleSpellBook:GetTalentPoints(139139)>0 and targetPct()>20 and cop_dotweave() then
		return true;
	end
	-- actions.decision+=/call_action_list,name=cop_insanity,if=talent.clarity_of_power.enabled&talent.insanity.enabled
	if OvaleSpellBook:GetTalentPoints(155246)>0 and OvaleSpellBook:GetTalentPoints(139139)>0 and cop_insanity() then
		return true;
	end
end

function H:Work()

-- 	actions=shadowform,if=!buff.shadowform.up
-- actions+=/use_item,slot=finger1
-- actions+=/potion,name=draenic_intellect,if=buff.bloodlust.react|target.time_to_die<=40
-- actions+=/use_item,name=nithramus_the_allseer
-- actions+=/power_infusion,if=talent.power_infusion.enabled
-- actions+=/silence,if=target.debuff.casting.react
-- actions+=/blood_fury
-- actions+=/berserking
-- actions+=/arcane_torrent
	local inZS = UnitHealth("target")/UnitHealthMax("target")<=0.25;
	local healthrate = UnitHealth("player")/UnitHealthMax("player");
	local powerrate = UnitPower("player")/UnitPowerMax("player");
	local sp = UnitPower("player",SPELL_POWER_SHADOW_ORBS);

	if WA_CheckBuff("暗影形态") then
		jcmessage("没有进入暗影形态");
	end

	local timeToFinish = D.Casting.ttf*1000;
	--如何最大化利用心灵震爆：
	--当你出球率足够的时候，尽可能多的打心灵震爆可以使你的Dps跃升。
	--这里主要有一个“二段鞭”的技巧。具体二段鞭上面已经解释过了，利用损失鞭笞一跳的代价换取有球心爆总是能提高你的DPS。
	if D.Casting.name then
		--if D.Casting.channeling and D.Casting.name=="精神鞭笞" then
		--	if D:CastReadable() and not WA_CheckSpellUsableOn("心灵震爆") or WA_CheckBuff("暗影宝珠",1,3) then
		--		return;
		--	end
		--else
		if D.Casting.channeling then
			return;
		elseif timeToFinish>=500 then
			return;
		end
	end;

	if(CCWA_Check_PreToCasts())then return end

	if S.GCDLeftTime>D.MaxDelayS then
		return;
	end
	--SOLO!!!
	if UnitName("targettarget")==UnitName("player") and WA_CheckSpellUsableOn("真言术：盾","player") then
		CCFlagSpell("真言术：盾");
		return;
	end

	if D:ArmorSetBonus("PVP",2) and pvp_dispersion() then
		return;
	end
	return decision();
	--
	-- if CCFightType==2 and WA_NeedAttack("mouseover") then
	-- 	if castPain("mouseover") then return; end
	-- 	if castTouch("mouseover") then return; end
	-- end
	--
	-- if castPain() then return; end
	--
	-- if castTouch() then return; end
	--
	-- if D:CastReadable() and sp<3 and WA_CheckSpellUsableOn("心灵震爆") then
	-- 	CCFlagSpell("心灵震爆");
	-- 	return;
	-- end
	--
	-- if castDeath() then return; end
	--
	-- if castshiling() then return; end
	--
	-- --if WA_Is_Boss() and WA_CheckSpellUsableOn("暗影恶魔") then
	-- --	CCFlagSpell("暗影恶魔");
	-- --	return;
	-- --end
	--
	-- --D:Error(WA_CheckSpellUsable("精神鞭笞"));
	-- if D:CastReadable() and WA_CheckSpellUsable("精神鞭笞") then
	-- 	CCFlagSpell("精神鞭笞");
	-- 	return;
	-- end
end

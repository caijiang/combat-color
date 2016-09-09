-- CCRogueCombat.lua

local addonName, T = ...;
local D = T.jcc;

local _,clzz = UnitClass("player");
if clzz~="ROGUE" then return;end

local R = T.jcc.ROGUE;
local C = R:NewModule("ROGUE2", "AceEvent-3.0", "AceHook-3.0","CCTalent-1.0");

C.lastDXLostTime = 0;

C.TalentSpellDescs = {
		--英勇之怒？ 没必要
		["要害打击"] =39,
		["冲动"] = {slot=40,havecd=true},
		["杀戮盛筵"] ={slot=37,havecd=true},
		["剑刃乱舞"] ={slot=38,havecd=true},
};

local function zengjiacombat(p)
	if WA_CheckSpellUsable("要害打击") and WA_CheckDebuff("要害打击",0,0,true) then
		CCFlagSpell("要害打击");
		return true;
	end
	if WA_CheckSpellUsable("影袭") then
		CCFlagSpell("影袭");
		return true;
	end
	return false;
end

--actions+=/preparation,if=!buff.vanish.up&cooldown.vanish.remains>60
--actions+=/lifeblood,if=time=0|buff.shadow_blades.up
--actions+=/blood_fury,if=time=0|buff.shadow_blades.up
--actions+=/berserking,if=time=0|buff.shadow_blades.up
--actions+=/arcane_torrent,if=energy<60
--actions+=/blade_flurry,if=(active_enemies>=2&!buff.blade_flurry.up)|(active_enemies<2&buff.blade_flurry.up)
--actions+=/ambush
--actions+=/vanish,if=time>10&(combo_points<3|(talent.anticipation.enabled&anticipation_charges<3)|(buff.shadow_blades.down&(combo_points<4|(talent.anticipation.enabled&anticipation_charges<4))))&((talent.shadow_focus.enabled&buff.adrenaline_rush.down&energy<20)|(talent.subterfuge.enabled&energy>=90)|(!talent.shadow_focus.enabled&!talent.subterfuge.enabled&energy>=60))
--actions+=/shadow_blades,if=time>5
--actions+=/killing_spree,if=energy<45
--actions+=/adrenaline_rush,if=energy<35|buff.shadow_blades.up
--actions+=/slice_and_dice,if=buff.slice_and_dice.remains<2|(buff.slice_and_dice.remains<15&buff.bandits_guile.stack=11&combo_points>=4)
--actions+=/marked_for_death,if=talent.marked_for_death.enabled&(combo_points=0&dot.revealing_strike.ticking)
--actions+=/run_action_list,name=generator,if=combo_points<5|(talent.anticipation.enabled&anticipation_charges<=4&!dot.revealing_strike.ticking)
--actions+=/run_action_list,name=finisher,if=!talent.anticipation.enabled|buff.deep_insight.up|cooldown.shadow_blades.remains<=11|anticipation_charges>=4|(buff.shadow_blades.up&anticipation_charges>=3)
--actions+=/run_action_list,name=generator,if=energy>60|buff.deep_insight.down|buff.deep_insight.remains>5-combo_points

--actions+=/marked_for_death,if=talent.marked_for_death.enabled&(combo_points<2&dot.revealing_strike.ticking)&cooldown.shadow_blades.remains>10&energy<60
--actions+=/run_action_list,name=generator,if=(combo_points<5|buff.shadow_blades.up&combo_points<4)&(cooldown.shadow_blades.remains>3|energy>70)
--actions+=/run_action_list,name=finisher,if=(buff.shadow_blades.up&combo_points>3)|(combo_points=5&cooldown.shadow_blades.remains>10)|(combo_points=4&cooldown.shadow_blades.remains>8&cooldown.shadow_blades.remains<12)|(combo_points=3&cooldown.shadow_blades.remains>6&cooldown.shadow_blades.remains<10)
--actions+=/run_action_list,name=generator,if=energy>60|buff.deep_insight.down|buff.deep_insight.remains>5-combo_points&(cooldown.shadow_blades.remains>3|energy>70)


--actions.generator=fan_of_knives,line_cd=5,if=active_enemies>=4
--actions.generator+=/revealing_strike,if=ticks_remain<2
--actions.generator+=/sinister_strike

--actions.finisher=rupture,if=ticks_remain<2&target.time_to_die>=26&(active_enemies<2|!buff.blade_flurry.up)
--actions.finisher+=/crimson_tempest,if=active_enemies>=7&dot.crimson_tempest_dot.ticks_remain<=2
--actions.finisher+=/eviscerate

local function finisher()
	if WA_CheckSpellUsable("割裂") and WA_CheckDebuff("割裂",2,0,true) and UnitHealth("target")>1500000 and (CCFightType==1 or WA_CheckBuff("剑刃乱舞")) then
		CCFlagSpell("割裂");
		return true;
	end

	if WA_CheckSpellUsable("猩红风暴") and ( CCFightType==2 and WA_CheckDebuff("猩红风暴",2,0,true) ) then
		CCFlagSpell("猩红风暴");
		return true;
	end

	if WA_CheckSpellUsable("刺骨") then
		CCFlagSpell("刺骨");
		return true;
	end

	return false;
end

local function generator()
	if CCFightType==2 and WA_CheckSpellUsable("刀扇") then
		CCFlagSpell("刀扇");
		return true;
	end
	if WA_CheckSpellUsable("要害打击") and WA_CheckDebuff("要害打击",2,0,true) then
		CCFlagSpell("要害打击");
		return true;
	end

	if WA_CheckSpellUsable("影袭") then
		CCFlagSpell("影袭");
		return true;
	end

	return false;
end

function C:Work(pvp)

	-- 揭底 和 乱舞时 速度开启切割
	local p = GetComboPoints("player","target");
	local power = UnitPower("player");

	-- 能量恢复 的速度  冲动 100% select(2,GetPowerRegen());
	local prps = select(2,GetPowerRegen());
	-- 影袭 39
	local timetotg = (75-power)/prps;

	if R.LastUUID~=UnitGUID("target") and GetTime()-R.LastZHTime<5 and p==0 and R.LastP>1 and WA_CheckSpellUsable("转嫁") then
		CCFlagSpell("转嫁");
		return;
	end

	R:LogP();

	local baofa = R:RushConditon();--不惜之风

	--伺机待发 无消失

	if not WA_CheckBuff("暗影之刃") then
		CCWA_RacePink(false,nil,true)
	end

	if CCAutoRush and power<60 and WA_CheckSpellUsable("奥术洪流") then
		CCFlagSpell("奥术洪流");
	end


	if WA_CheckSpellUsable("伏击") then
		CCFlagSpell("伏击");
		return;
	end

	--actions+=/vanish,if=time>10&(combo_points<3|(talent.anticipation.enabled&anticipation_charges<3)|(buff.shadow_blades.down&(combo_points<4|(talent.anticipation.enabled&anticipation_charges<4))))&((talent.shadow_focus.enabled&buff.adrenaline_rush.down&energy<20)|(talent.subterfuge.enabled&energy>=90)|(!talent.shadow_focus.enabled&!talent.subterfuge.enabled&energy>=60))

	if CCAutoRush and baofa and WA_CheckSpellUsable("暗影之刃") then
		CCFlagSpell("暗影之刃");
		return;
	end

	if CCAutoRush and WA_CheckSpellUsable("杀戮盛筵") and power<45 and not WA_CheckBuff("冲动") then
		CCFlagSpell("杀戮盛筵");
		return;
	end

	if CCAutoRush and WA_CheckSpellUsable("冲动") and not WA_CheckBuff("暗影之刃") then
		CCFlagSpell("冲动");
		return;
	end

	--洞悉
	--actions+=/slice_and_dice,if=buff.slice_and_dice.remains<2|(buff.slice_and_dice.remains<15&buff.bandits_guile.stack=11&combo_points>=4)
	-- 有中度洞悉 而且
	if not WA_CheckBuff("深度洞悉") and WA_CheckBuff("深度洞悉",2) then
		C.lastDXLostTime = GetTime();
		D:Debug("记录洞悉时间",C.lastDXLostTime);
	end
	local agcc = WA_CheckBuff("切割",15) and p>=4 and C.lastDXLostTime+16>GetTime() and C.lastDXLostTime+16-GetTime()<3;
	if agcc then
		D:Debug("洞悉即将开始 补切割");
	end
	if WA_CheckSpellUsable("切割") and (WA_CheckBuff("切割",2) or agcc) then
		CCFlagSpell("切割");
		return;
	end

	--actions+=/marked_for_death,if=talent.marked_for_death.enabled&(combo_points=0&dot.revealing_strike.ticking)
	--cooldown.shadow_blades.remains>10&energy<60
	--小怪场合如何偷取死亡？
	if CCShareHoly.isHarm("focus") and WA_CheckSpellUsableOn("死亡标记","focus") and p==0 and not CCShareHoly.isEquals("target","focus") and WA_CheckSpellUsable("转嫁") then
		CCFlagSpell("死亡嫁祸");
		return;
	end

	if CCShareHoly.isHarm("focus") and p<GetComboPoints("player","target")and WA_CheckSpellUsable("转嫁") then
		CCFlagSpell("转嫁");
		return;
	end

	--血量太低的怪 可以直接死亡的吧
	D:Debug(CCShareHoly.isEquals("target","focus"),WA_CheckSpellUsable("死亡标记"),p==0,not WA_CheckDebuff("要害打击",3,0,true));
	if CCShareHoly.isEquals("target","focus") and WA_CheckSpellUsable("死亡标记") and p==0 and not WA_CheckDebuff("要害打击",3,0,true) then
		CCFlagSpell("死亡标记");
		return;
	end

	--actions+=/run_action_list,name=generator,if=combo_points<5|(talent.anticipation.enabled&anticipation_charges<=4&!dot.revealing_strike.ticking)
	if p<5 or (R:Yugan(4) and WA_CheckDebuff("要害打击",1,0,true)) then
		if generator() then return;end
	end
	--actions+=/run_action_list,name=finisher,if=!talent.anticipation.enabled|buff.deep_insight.up|cooldown.shadow_blades.remains<=11|anticipation_charges>=4|(buff.shadow_blades.up&anticipation_charges>=3)
	if not GetSpellInfo("预感") or not WA_CheckBuff("深度洞悉") or WA_CooldownLeft("暗影之刃",true)<=11 or not WA_CheckBuff("预感",5,5,true) or ( not WA_CheckBuff("暗影之刃") and not WA_CheckBuff("预感",5,4,true) ) then
		if finisher() then return;end
	end
	--actions+=/run_action_list,name=generator,if=energy>60|buff.deep_insight.down|buff.deep_insight.remains>5-combo_points
	if power>60 or WA_CheckBuff("深度洞悉") or not WA_CheckBuff("深度洞悉",5-p) then
		if generator() then return;end
	end




	--[[
	杀戮盛筵:当杀戮盛筵可用时
暗影之刃:当暗影之刃可用时
冲动:当冲动可用时
手套附魔:当工程手套可用时
伺机待发:当伺机待发可用时
	]]

	if p==5 and WA_CheckSpellUsable("刺骨") then
		CCFlagSpell("刺骨");
		return;
	end

	if timetotg<0 and p<5 and zengjiacombat(p) then
		return;
	end

	if WA_CheckSpellUsable("切割") then
		-- 计算是否需要刷新切割
	end

	if p>0 and not CC_reckon_target_liveon(timetotg+2) and WA_CheckSpellUsable("刺骨") then
		CCFlagSpell("刺骨");
		return;
	end

	--继续影袭么？
	D:Debug("还需时间：",timetotg," 检测1:",CC_reckon_target_liveon(timetotg+2)," 检测2:",CC_reckon_target_liveon(timetotg));
	if p<5 and CC_reckon_target_liveon(timetotg+2) and zengjiacombat(p) then
		return;
	end

end

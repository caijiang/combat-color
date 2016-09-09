-- CCMgFire.lua

local addonName, T = ...;
local OvaleState = T.OvaleState;
local OvaleSpellBook = T.OvaleSpellBook;
local D = T.jcc;

local _,clzz = UnitClass("player");
if clzz~="MAGE" then return;end

local xor = bit.bxor;

local S = D.MAGE;
local F = S:NewModule("MAGE2", "AceEvent-3.0", "AceHook-3.0","CCTalent-1.0");

F.TalentSpellDescs = {
	["火球术"] =31,
	["炎爆术"] = 32,
	["炼狱冲击"] = {slot=33,havecd=true},--,marco="/stopcasting\n/cast %s"

	["灼烧"] = 34,
	["龙息术"] = {slot=35,havecd=true},
	["燃烧"] = {slot=1,havecd=true},
}

function F:RushCondition()
	return not WA_CheckDebuff("炎爆术",0,0,true) and not WA_CheckDebuff("点燃",0,0,true);
end

function F:RushCondition2()
	return not WA_CheckDebuff("点燃",0,0,true);
end

function F:Rush()
end

function F:WorkUpdate()
	-- CombustionUpdate();
end

function F:CastingUpdate()
-- 有迸发 没炎爆
	if D.Casting.name~="炎爆术" and D.Casting.name~="火球术" and D.Casting.name~="灼烧" then
		return;
	end
	-- if CCFightType==1 and InCombat and (not WA_CheckBuff("热力迸发")) and WA_CheckBuff("炎爆术！") and D.Casting.process<0.5 and WA_CheckSpellUsable("炼狱冲击") then
	-- 	CCFlagSpell("炼狱冲击");
	-- 	return;
	-- end
end

-- 填充技能
local function fillCast()
	local state = OvaleState.state;
	local fillCast = "火球术";
	if D:CastReadable() and D:GetSpellCostTime("火球术")<=state:GetGCD() and WA_CheckSpellUsable("炎爆术") then
		fillCast = "炎爆术";
	elseif (not D:CastReadable() and WA_CheckSpellUsable("灼烧")) then
		fillCast = "灼烧";
	end
	return fillCast;
end

local function living_bomb()
	--活动炸弹
	if WA_CheckSpellUsable("炼狱冲击") and not WA_CheckDebuff("活动炸弹",0,0,true) and D:DebuffCountOnAny(44457)<D:Enemies()  then
		CCFlagSpell("炼狱冲击");
		return true;
	end
	-- actions.living_bomb+=/living_bomb,if=target!=pet.prismatic_crystal&(((!talent.incanters_flow.enabled|incanters_flow_dir<0|buff.incanters_flow.stack=5)&remains<3.6)|((incanters_flow_dir>0|buff.incanters_flow.stack=1)&remains<gcd.max))&target.time_to_die>remains+12
	if WA_CheckSpellUsable("活动炸弹") then
		CCFlagSpell("活动炸弹");
		return true;
	end
end

local function active_talents()
	if WA_CheckSpellUsable("流星") and D:hasEnemies(3) then
		CCFlagSpell("流星");
		return true;
	end

	if living_bomb() then
		return true;
	end

	-- actions.active_talents+=/cold_snap,if=glyph.dragons_breath.enabled&!talent.prismatic_crystal.enabled&!cooldown.dragons_breath.up
	if WA_CheckSpellUsable("急速冷却") and S:NearBy() and S.ToRush and OvaleSpellBook:IsActiveGlyph(159485) and OvaleSpellBook:GetTalentPoints(152087)<=0 and WA_CooldownLeft("龙息术",true)>0 then
		CCFlagSpell("急速冷却");
	end
	-- actions.active_talents+=/dragons_breath,if=glyph.dragons_breath.enabled&(!talent.prismatic_crystal.enabled|cooldown.prismatic_crystal.remains>8|legendary_ring.cooldown.remains>10)
	if WA_CheckSpellUsable("龙息术") and S:NearBy() and OvaleSpellBook:IsActiveGlyph(159485) and (OvaleSpellBook:GetTalentPoints(152087)<=0 or WA_CooldownLeft("幻灵晶体")>10) then
		CCFlagSpell("龙息术");
		return true;
	end

	if WA_CheckSpellUsable("冲击波") and S:NearBy() and (OvaleSpellBook:GetTalentPoints(152087)<=0 or WA_CooldownLeft("幻灵晶体")>10) then
		CCFlagSpell("冲击波");
		return true;
	end
end

local function single_target()

	if WA_CheckSpellUsable("炼狱冲击") and not WA_CheckDebuff("燃烧",0,0,true) and D:DebuffCountOnAny(83853)<D:Enemies()  then
		CCFlagSpell("炼狱冲击");
		return true;
	end

	local fillCast = fillCast();

	if not WA_CheckBuff("炎爆术！") and WA_CheckSpellUsable("炎爆术") and WA_CheckBuff("炎爆术！",D:GetSpellCostTime(fillCast)) then
		CCFlagSpell("炎爆术");
		return true;
	end

	if not WA_CheckBuff("炎爆术！") and WA_CheckSpellUsable("炎爆术") and not WA_CheckBuff("热力迸发") and D:InFlightToTarget(133) then
		CCFlagSpell("炎爆术");
		return true;
	end

	if WA_CheckSpellUsable("炼狱冲击") and WA_CheckBuff("炎爆术！") and not WA_CheckBuff("热力迸发")
	and not (D:hasEnemies(2) and not WA_CheckDebuff("活动炸弹",10,0,true)) then
		CCFlagSpell("炼狱冲击");
		return true;
	end

	if active_talents() then
		return true;
	end

	if WA_CheckSpellUsable("炼狱冲击") and not WA_CheckBuff("炎爆术！") and WA_CheckBuff("热力迸发")
	and not (D:hasEnemies(2) and not WA_CheckDebuff("活动炸弹",10,0,true))
	and not D:InFlightToTarget(133) then
		CCFlagSpell("炼狱冲击");
		return true;
	end

	-- if WA_CheckSpellUsable(fillCast) then
		CCFlagSpell(fillCast);
		return true;
	-- end
end

local function crystal_sequence()
	local state = OvaleState.state;
	if WA_CheckSpellUsable("炼狱冲击") and not WA_CheckDebuff("燃烧",0,0,true) and D:DebuffCountOnAny(83853)<D:Enemies() + 1  then
		CCFlagSpell("炼狱冲击");
		return true;
	end
	-- actions.crystal_sequence+=/cold_snap,if=!cooldown.dragons_breath.up
	if WA_CheckSpellUsable("急速冷却") and S:NearBy() and WA_CooldownLeft("龙息术",true)>0 then
		CCFlagSpell("急速冷却");
	end
	if S:dragons_breath() then return true;
	end
	if S:blast_wave() then return true;
	end

--TODO 0
-- actions.crystal_sequence+=/pyroblast,if=execute_time=gcd.max&pet.prismatic_crystal.remains<gcd.max+travel_time&pet.prismatic_crystal.remains>travel_time
-- 测试 local _, name, startTime, duration = state:GetTotemInfo(id) 到底什么鬼
-- if ExecuteTime(pyroblast) == GCD() and TotemRemaining(prismatic_crystal) < GCD() + TravelTime(pyroblast) and TotemRemaining(prismatic_crystal) > TravelTime(pyroblast) Spell(pyroblast)
	if D:CastReadable() and WA_CheckSpellUsable("炎爆术") and D:GetSpellCostTime("炎爆术")<=state:GetGCD() then
		CCFlagSpell("炎爆术");
		return true;
	end

	return single_target();
end

local function combust_sequence()
	local state = OvaleState.state;
	--prismatic_crystal
	if S:RushDps() then return true; end
	if WA_CheckSpellUsable("幻灵晶体") then
		CCFlagSpell("幻灵晶体");
		return true;
	end
	--大量爆发 包括晶体
	if WA_CheckSpellUsable("流星") and D:notEnoughEnemies(3) then
		CCFlagSpell("流星");
		return true;
	end
	-- 纵火什么鬼？
	-- #pyroblast,if=set_bonus.tier17_4pc&buff.pyromaniac.up
	if WA_CheckSpellUsable("炼狱冲击") and D:ArmorSetBonus("T16_caster",4) and xor(not WA_CheckBuff("炎爆术！"),not WA_CheckBuff("热力迸发")) then
		CCFlagSpell("炼狱冲击");
		return true;
	end

	local fillCast = fillCast();

	if WA_CheckSpellUsable(fillCast) and WA_CheckDebuff("点燃",0,0,true) and not D:InFlightToTarget(133) then
		CCFlagSpell(fillCast);
		return true;
	end

	-- actions.combust_sequence+=/fireball,if=crit_pct_current-1>(1000%13)&prev_gcd.pyroblast&buff.pyroblast.up
	-- &buff.heating_up.up&12-pet.prismatic_crystal.remains<action.fireball.execute_time+3*gcd.max&spell_haste<0.7
	if D:CastReadable() and WA_CheckSpellUsable("火球术") and (
	D:SpellCritChance()-1>1000/13 and D:PreviousGCDSpell(11366) and not WA_CheckBuff("炎爆术！") and not WA_CheckBuff("热力迸发")
	and 12-remains<OvaleSpellBook:GetCastTime(133)+3*state:GetGCD() and (100/(100+D:SpellHaste()))<0.7
	) then
		CCFlagSpell("火球术");
		return true;
	end
--  2 飞行时间本来就不靠谱 不要它了
	-- actions.combust_sequence+=/pyroblast,if=buff.pyroblast.up&
	-- dot.ignite.tick_dmg*(6-ceil(dot.ignite.remains-travel_time))<crit_damage*mastery_value
	-- if BuffPresent(pyroblast_buff) and target.TickValue(Debuff) * { 6 - { target.DebuffRemaining(ignite_debuff) - TravelTime(pyroblast) } } < CritDamage(pyroblast) * { MasteryEffect() / 100 } Spell(pyroblast)
	-- 太复杂了。。瞬发丢下得了
	if not WA_CheckBuff("炎爆术！") and WA_CheckSpellUsable("炎爆术") then
		CCFlagSpell("炎爆术");
		return true;
	end
	-- 3 这里只有在流星的情况下才IB
	-- actions.combust_sequence+=/inferno_blast,if=talent.meteor.enabled&cooldown.meteor.duration-cooldown.meteor.remains<gcd.max*3
	-- if WA_CheckSpellUsable("炼狱冲击") then
	-- 	CCFlagSpell("炼狱冲击");
	-- 	return true;
	-- end

	if WA_CheckSpellUsable("燃烧") then
		CCFlagSpell("燃烧");
		-- return true;
	end
end

local function init_combust()
	local state = OvaleState.state;
	if S.ToRush then
		if OvaleSpellBook:GetTalentPoints(153561)>0 then
			-- 不会点这个天赋 所以 无所谓
			if WA_CheckSpellUsable("流星") then
				state:PutState("pyro_chain",1);
			end
		elseif OvaleSpellBook:GetTalentPoints(152087)>0 then
			--晶体   戒指效果暂时不管
			if WA_CheckSpellUsable("幻灵晶体") and WA_CooldownLeft("燃烧",true)<state:GetGCD()*2 and not WA_CheckBuff("炎爆术！") and xor(not WA_CheckBuff("热力迸发"),D:InFlightToTarget(133)) then
				state:PutState("pyro_chain",1);
			end
		else
			if WA_CooldownLeft("燃烧",true)<state:GetGCD()*4 and not WA_CheckBuff("炎爆术！") and not WA_CheckBuff("热力迸发") and D:InFlightToTarget(133) then
				state:PutState("pyro_chain",1);
			end
		end

	end
	-- # Combustion sequence initialization
	-- # This sequence lists the requirements for preparing a Combustion combo with each talent choice
	-- # Meteor Combustion
	-- actions.init_combust=start_pyro_chain,if=talent.meteor.enabled&cooldown.meteor.up&(legendary_ring.cooldown.remains<gcd.max|legendary_ring.cooldown.remains>target.time_to_die+15|!legendary_ring.has_cooldown)&((cooldown.combustion.remains<gcd.max*3&buff.pyroblast.up&(buff.heating_up.up^action.fireball.in_flight))|(buff.pyromaniac.up&(cooldown.combustion.remains<ceil(buff.pyromaniac.remains%gcd.max)*gcd.max)))
	-- # Prismatic Crystal Combustion
	-- actions.init_combust+=/start_pyro_chain,if=talent.prismatic_crystal.enabled&cooldown.prismatic_crystal.up&
	-- (legendary_ring.cooldown.remains<gcd.max&(!equipped.112320|trinket.proc.crit.react)
	-- |legendary_ring.cooldown.remains+20>target.time_to_die|!legendary_ring.has_cooldown)&
	-- ((cooldown.combustion.remains<gcd.max*2&buff.pyroblast.up&(buff.heating_up.up^action.fireball.in_flight))
	-- |(buff.pyromaniac.up&(cooldown.combustion.remains<ceil(buff.pyromaniac.remains%gcd.max)*gcd.max)))
	-- # Unglyphed Combustions between Prismatic Crystals
	-- actions.init_combust+=/start_pyro_chain,if=talent.prismatic_crystal.enabled&!glyph.combustion.enabled&cooldown.prismatic_crystal.remains>20&((cooldown.combustion.remains<gcd.max*2&buff.pyroblast.up&buff.heating_up.up&action.fireball.in_flight)|(buff.pyromaniac.up&(cooldown.combustion.remains<ceil(buff.pyromaniac.remains%gcd.max)*gcd.max)))
	-- # Kindling or Level 90 Combustion
	-- actions.init_combust+=/start_pyro_chain,if=!talent.prismatic_crystal.enabled&!talent.meteor.enabled&
	-- ((cooldown.combustion.remains<gcd.max*4&buff.pyroblast.up&buff.heating_up.up&action.fireball.in_flight)
	-- |(buff.pyromaniac.up&cooldown.combustion.remains<ceil(buff.pyromaniac.remains%gcd.max)*(gcd.max+talent.kindling.enabled)))

end

local function aoe()
	if WA_CheckSpellUsable("炼狱冲击") and not WA_CheckDebuff("燃烧",0,0,true) and D:DebuffCountOnAny(83853)<D:Enemies()  then
		CCFlagSpell("炼狱冲击");
		return true;
	end
	if active_talents() then
		return true;
	end
	if not WA_CheckBuff("炎爆术！") and WA_CheckSpellUsable("炎爆术") then
		CCFlagSpell("炎爆术");
		return true;
	end
	--actions.aoe+=/cold_snap,if=!cooldown.dragons_breath.up
	if WA_CheckSpellUsable("急速冷却") and S.ToRush and S:NearBy() and WA_CooldownLeft("龙息术",true)>0 then
		CCFlagSpell("急速冷却");
	end
	if WA_CheckSpellUsable("龙息术") and S:NearBy() then
		CCFlagSpell("龙息术");
		return true;
	end
	if not D:PreviousGCDSpell(2120) and WA_CheckSpellUsable("烈焰风暴") and WA_CheckDebuff("烈焰风暴",2.4,0,true) then
		CCFlagSpell("烈焰风暴");
		return true;
	end
end

function F:Work(pvp)

--	print("点燃伤害",combuigndamage);
	local state = OvaleState.state;

	if D:PreviousOffGCDSpell(11129) then
		state:PutState("pyro_chain",0);
	end

	if S:rune_of_power() then return end

	if S.ToRush and state:GetState("pyro_chain")==1 and not S:prismatic_crystal_active() and combust_sequence() then
		return;
	end

	if S:prismatic_crystal_active() then
		if S.ToRush and state:GetState("pyro_chain")==1 and combust_sequence() then
			return;
		end
		if crystal_sequence() then
			return;
		end
	end

	if state:GetState("pyro_chain")==0 then
		init_combust();
	end

	if not (not WA_CheckBuff("热力迸发") and D:InFlightToTarget(133)) and S:rune_of_power(D:GetSpellCostTime("火球术")+OvaleState.state:GetGCD()) then return end

	if not (not WA_CheckBuff("热力迸发") and D:InFlightToTarget(133)) and S:mirror_image() then return end

	if CCFightType==2 and aoe() then
		return;
	end

	return single_target();
end

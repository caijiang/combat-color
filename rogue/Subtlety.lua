-- Subtlety.lua


local addonName, T = ...;
local D = T.jcc;

local _,clzz = UnitClass("player");
if clzz~="ROGUE" then return;end

local R = T.jcc.ROGUE;
local C = R:NewModule("ROGUE3", "AceEvent-3.0", "AceHook-3.0","CCTalent-1.0");

C.TalentSpellDescs = {
		["出血"] =39,
		["背刺"] =40,
		["暗影之舞"] = {slot=37,havecd=true},
		["预谋"] = {slot=38,havecd=true},
};

--起手 兔妖 潜行 预谋 切割
--嗜血药水！
--生命之血 暗影之舞时 各种种族
--能量小于60 光环
--actions+=/预谋,if=combo_points<3|(talent.预感.enabled&预感_charges<3)
--actions+=/伏击,if=combo_points<5|(talent.预感.enabled&预感_charges<3)|(buff.手法娴熟.up&buff.手法娴熟.remains<=gcd)
--actions+=/暗影之舞,if=energy>=75&buff.潜行.down&buff.消失.down&debuff.洞悉弱点.down
--actions+=/消失,if=energy>=45&energy<=75&combo_points<=3&buff.暗影之舞.down&buff.敏锐大师.down&debuff.洞悉弱点.down
--actions+=/死亡标记,if=talent.死亡标记.enabled&combo_points=0
--actions+=/run_action_list,name=generator,if=talent.预感.enabled&预感_charges<4&buff.切割.up&dot.割裂.remains>2&(buff.切割.remains<6|dot.割裂.remains<4)
--actions+=/run_action_list,name=finisher,if=combo_points=5
--actions+=/run_action_list,name=generator,if=combo_points<4|energy>80|talent.预感.enabled

--generator
--actions.generator+=/刀扇,if=active_enemies>=4
--actions.generator+=/出血,if=remains<3|position_front
--actions.generator+=/飞镖投掷,if=talent.飞镖投掷.enabled&(energy<65&energy.regen<16)
--actions.generator+=/背刺

--finishers
--actions.finisher=切割,if=buff.切割.remains<4
--actions.finisher+=/割裂,if=ticks_remain<2&active_enemies<3
--actions.finisher+=/猩红风暴,if=(active_enemies>1&dot.猩红风暴_dot.ticks_remain<=2&combo_points=5)|active_enemies>=5
--actions.finisher+=/刺骨,if=active_enemies<4|(active_enemies>3&dot.猩红风暴_dot.ticks_remain>=2)
--actions.finisher+=/run_action_list,name=pool

local function ccfinisher()
	local p = GetComboPoints("player","target");
	if WA_CheckSpellUsable("切割") and WA_CheckBuff("切割",6) then
		CCFlagSpell("切割");
		return true;
	end

	if WA_CheckSpellUsable("割裂") and WA_CheckDebuff("割裂",2,0,true) and CCFightType==1 then
		CCFlagSpell("割裂");
		return true;
	end

	if WA_CheckSpellUsable("猩红风暴") and ( CCFightType==2 or (D.FightHSMode and WA_CheckDebuff("猩红风暴",2,0,true) and p==5) ) then
		CCFlagSpell("猩红风暴");
		return true;
	end

	if WA_CheckSpellUsable("刺骨") and CCFightType==1 then
		CCFlagSpell("刺骨");
		return true;
	end
end

local function ccgenerator()
	local power = UnitPower("player");
	local prps = select(2,GetPowerRegen());

	if CCFightType==2 and WA_CheckSpellUsable("刀扇") then
		CCFlagSpell("刀扇");
		return true;
	end

	if WA_CheckSpellUsable("出血") and (not R.inback or WA_CheckDebuff("出血",3,0,true)) then
		CCFlagSpell("出血");
		return true;
	end

	if WA_CheckSpellUsable("飞镖投掷") and  power<65 and prps<16 then
		CCFlagSpell("飞镖投掷");
		return true;
	end

	if WA_CheckSpellUsable("背刺") and R.inback then
		CCFlagSpell("背刺");
		return true;
	end
end


function C:Work(pvp)
	local p = GetComboPoints("player","target");
	local power = UnitPower("player");

	local prps = select(2,GetPowerRegen());

	if R.LastUUID~=UnitGUID("target") and GetTime()-R.LastZHTime<5 and p==0 and R.LastP>1 and WA_CheckSpellUsable("转嫁") then
		CCFlagSpell("转嫁");
		return;
	end

	R:LogP();

	local baofa = R:RushConditon() and not WA_CheckDebuff("洞悉弱点",5,0,true);

	if not WA_CheckBuff("暗影之舞") or not WA_CheckBuff("暗影之刃") then
		CCWA_RacePink(false,nil,true)
	end

	if CCAutoRush and power<60 and WA_CheckSpellUsable("奥术洪流") then
		CCFlagSpell("奥术洪流");
	end

	if CCAutoRush and baofa and WA_CheckSpellUsable("暗影之刃") then
		CCFlagSpell("暗影之刃");
		return;
	end

--[[	if WA_CheckSpellUsable("预谋") and (p<3 or R:Yugan(3)) then
		CCFlagSpell("预谋");
		return;
	end]]


--	if WA_CheckSpellUsable("锁喉") and WA_CheckDebuff("动脉破裂",1,0,true)

	if WA_CheckSpellUsable("伏击") and R.inback and (WA_CheckDebuff("洞悉弱点",1,0,true) or p<5 or R:Yugan(3) or (not WA_CheckBuff("手法娴熟") and WA_CheckBuff("手法娴熟",2) ) ) then
		CCFlagSpell("伏击");
		return;
	end

	local nogen = false;

	if CCAutoRush and WA_CheckSpellUsable("暗影之舞") and R.inback and WA_CheckBuff("潜行") and WA_CheckBuff("消失") and WA_CheckDebuff("洞悉弱点",0,0,true) then
		--[[if power>= 75 then
			CCFlagSpell("暗影之舞");
		end
		nogen = true;]]
		if WA_CooldownLeft("预谋",true)<7 then
			if power>=40 then
				CCFlagSpell("暗影之舞");
			end
			nogen = true;
			if R:Yugan(4) then
				return;
			end
		end
	end

	if CCAutoRush and WA_CheckSpellUsable("消失") and R.inback and p<=3 and WA_CheckBuff("潜行") and WA_CheckBuff("消失") and WA_CheckBuff("暗影之舞") and WA_CheckBuff("敏锐大师") and WA_CheckDebuff("洞悉弱点",0,0,true) then
		--[[if power>= 45 then
			CCFlagSpell("消失");
		end
		nogen = true;]]
		if WA_CooldownLeft("预谋",true)<4 then
			if power>=60 then
				R:TryXiaoshi()
			end
			nogen = true;
			if R:Yugan(4) then
				return;
			end
		end
	end

	if WA_CheckSpellUsable("死亡标记") and p==0 then
		CCFlagSpell("死亡标记");
		return;
	end

	local fjab1,fjab2 = IsUsableSpell("伏击");
	if not WA_CheckBuff("消失") or not WA_CheckBuff("暗影之舞") or not WA_CheckBuff("潜行") then
		D:Debug(fjab2==1,WA_CheckDebuff("洞悉弱点",2,0,true),not WA_CheckSpellUsable("伏击"));
	end
	-- and WA_CheckDebuff("洞悉弱点",8,0,true)
	if WA_CheckBuff("手法娴熟") and fjab2==1 and R.inback and not WA_CheckSpellUsable("伏击") then
		D:Debug("等待能量恢复");
		--return;
		nogen = true;
		if R:Yugan(4) then
			return;
		end
	end

	if not nogen and R:Yugan(4) and not WA_CheckBuff("切割") and not WA_CheckDebuff("割裂",2,0,true) and (WA_CheckBuff("切割",6) or WA_CheckDebuff("割裂",4,0,true)) then
		if ccgenerator() then return end
	end

	if p==5 and ccfinisher() then return end

	if not nogen and  p<4 or power>80 or R:Yugan(6) then
		if ccgenerator() then return end
	end
end
--[[
]]

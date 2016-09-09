-- CCMgFire.lua

local addonName, T = ...;
local D = T.jcc;

local _,clzz = UnitClass("player");
if clzz~="MAGE" then return;end

local S = D.MAGE;
local F = S:NewModule("MAGE2", "AceEvent-3.0", "AceHook-3.0","CCTalent-1.0");

F.TalentSpellDescs = {
	["火球术"] =21,
	["炎爆术"] = 22,
	["炼狱冲击"] = {slot=23,havecd=true,marco="/stopcasting\n/cast %s"},

	["灼烧"] = 24,
	["龙息术"] = {slot=25,havecd=true},
	["燃烧"] = {slot=26,havecd=true},
}


local ignite = GetSpellInfo(12654);
local pyro1 = GetSpellInfo(11366);

local nextframetime = 0;
local combuignitetimer,combuigniteamount,combucrittarget;
local combuignitebank, combuigniteapplied, combuignitevalue, combuignitetemp, combuignitemunched, combuigndamage, combuignitecount;
local combulbdamage,combupyrodamage;
local combulbtimer,combupyrotimer;

local function CombustionVarReset22()
--	combupyrogain = 0 -- variables related to post fight report
--   	combupyrorefresh = 0
--   	combupyrocast = 0
--   	combulbrefresh = 0
   	combuignitebank = 0 -- variables related to ignite
    combuigniteapplied = 0;
    combuignitevalue = 0;
    combuignitetemp = 0;
    combuignitemunched = 0;
    combuigndamage = 0;
    combuignitecount = 0;
    combulbdamage = 0;
    combupyrodamage = 0;
end

CombustionVarReset22();

local combuignitedelta = 0;

local function CombustionIgnite(event, spellId, spellSchool, amount, critical, destGUID)

	local a2,b2,c2,d2,e2,f2,g2,h2,i2,j2,k2 = UnitAura("target", ignite, nil, "PLAYER HARMFUL")

	if (k2==12654) then
	combuignitetimer = (-1*(GetTime()-g2))
	else combuignitetimer = 0
	end

	if ((critical == 1) and (event == "SPELL_DAMAGE")) and ((spellSchool == 4) or (spellSchool == 20)) and (spellId ~= 83853) and (spellId ~= 89091) and (spellId ~= 44461) and (spellId ~= 2120) and (spellId ~= 88148) and (spellId ~= 82739) and (spellId ~= 83619) and (spellId ~= 99062) and (spellId ~= 34913) then
	-- 22.4% 2.8%
        combuigniteamount = ceil(amount * 0.4 * (((GetMastery()*2.8)/100)+1))
		combuignitevalue = combuignitevalue + combuigniteamount

	    if (combuignitetimer >= 4.5 + combuignitedelta) then
	        combuignitemunched = combuignitemunched + combuigniteamount
	    elseif (combuignitetimer >= 1.7 - combuignitedelta) and (combuignitetimer <= 2.5 + combuignitedelta) then
	        combuignitetemp = combuignitetemp + combuigniteamount
	    elseif (combuignitetimer <= 0.5 + combuignitedelta) and (combuignitetimer ~= 0) then
	        combuignitetemp = combuignitetemp + combuigniteamount
	    elseif (combuignitetimer >= 3.8 - combuignitedelta) then
	        combuignitetemp = combuignitetemp + combuigniteamount
	    elseif (combuignitetimer >= 0.5 + combuignitedelta) then
	        combuignitecount = 3
	        combuignitebank = combuignitebank + combuigniteamount
	    else combuignitecount = 2
	         combuignitebank = combuignitebank + combuigniteamount
	    end

	    if combuignitetemp ~= 0 and combuignitetimer == 0 then
	        combuignitecount = 3
	        combuignitebank = combuignitebank + combuignitetemp
	        combuignitetemp = 0
	    end

	combuigndamage = ceil(combuignitebank / combuignitecount);
	combucrittarget = destGUID

	elseif (event == "SPELL_PERIODIC_DAMAGE") and (spellId == 12654) then

	    combuigniteapplied = combuigniteapplied + amount
	    combuignitebank = (combuignitecount - 1) * amount + combuignitetemp
	    combuignitecount = combuignitecount - 1
	    if (combuignitetemp ~= 0) and (combuignitetimer ~= 0) then
	        combuignitecount = 3
	    end

	    combuigndamage = amount;
	    combuignitetemp = 0

	elseif (combucrittarget ~= UnitGUID("target")) or (UnitGUID("target") == nil) or ((event == "SPELL_AURA_REMOVED") and (spellId == 12654)) then
--		IgniteLabel:SetText(format(CombuLabel["ignite"]))
		combuigndamage = 0
	end
end

local function CombustionUpdate()
local time = GetTime();
-------------------------------
--Pyroblast part
		local a3,b3,c3,d3,e3,f3,g3,h3,i3,j3,k3 = UnitAura("target", pyro1, nil, "PLAYER HARMFUL");

		if (k3==11366) then
			combupyrotimer = (-1*(time-g3))
		else combupyrotimer = 0
			combupyrodamage = 0
		end
end

local bfs = 0;
local function fscheck(event, spellId, spellSchool, amount, critical, destGUID)
	--D:Error(event,spellId);
	if event=="SPELL_DAMAGE" and spellId==2136 then
		--D:Error("使用火冲了 状态：",bfs);
		if bfs==2 then
			bfs=3;
		end
	end
	if event=="SPELL_DAMAGE" and spellId==11366 then
		--D:Error("使用炎爆术了 状态：",bfs," 爆击？",critical);
		if S.ToUseRS and WA_CheckSpellUsable("燃烧") and CCAutoRush and S:RushPrepose() and critical then
			bfs  = 3;
			--D:Error("设置状态！",bfs);
		end
		return;
	end
end

function F:CombatLogEventUn(timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical)
	if (sourceName == UnitName("player")) then
		if (destGUID == UnitGUID("target")) then
			CombustionIgnite( event, spellId, spellSchool, amount, critical, destGUID)
			fscheck( event, spellId, spellSchool, amount, critical, destGUID)
		end

-------------------------------------------
-- report event check
				if (destGUID == UnitGUID("target")) then
					if (spellId == 44457) and (event == "SPELL_PERIODIC_DAMAGE") then -- LB damage
						if (critical == 1) and (combumeta == true) then
							combulbdamage = amount/2,03
						elseif (critical == 1) and (combumeta == false) then
							combulbdamage = amount/2
						else combulbdamage = amount
						end
--						LBLabel:SetText(format(CombuLabel["dmgwhite0"], combulbdamage))
					elseif ((spellId == 11366) and (event == "SPELL_PERIODIC_DAMAGE")) or ((spellId == 92315) and (event == "SPELL_PERIODIC_DAMAGE")) then -- pyroblast damage
						if (critical == 1) and (combumeta == true) then
							combupyrodamage = amount/2,03
						elseif (critical == 1) and (combumeta == false) then
							combupyrodamage = amount/2
						else combupyrodamage = amount
						end
--						PyroLabel:SetText(format(CombuLabel["dmgwhite0"], combupyrodamage))
--[[					elseif (spellId == 44614) and (event == "SPELL_PERIODIC_DAMAGE") then -- FFB damage
						if (critical == 1) and (combumeta == true) then
							combuffbdamage = amount/2,03
						elseif (critical == 1) and (combumeta == false) then
							combuffbdamage = amount/2
						else combuffbdamage = amount
						end]]
--						FFBLabel:SetText(format(CombuLabel["dmgwhite0"], combuffbdamage))
					end
				end



		if  (spellId == 2120) or (spellId == 88148) then
			if (event == "SPELL_DAMAGE") or (event == "SPELL_CAST_SUCCESS")	then
				nextframetime = GetTime()+8;
			end
		end
	end
end


function F:PLAYER_REGEN_DISABLED()
	CombustionVarReset22();
end
function F:PLAYER_REGEN_DISABLED()
	CombustionVarReset22();
end

drdmgneed = 20000;

function F:RushCondition()
	return not WA_CheckDebuff("炎爆术",0,0,true) and not WA_CheckDebuff("点燃",0,0,true);
end

function F:RushCondition2()
	return not WA_CheckDebuff("点燃",0,0,true);
end

function F:Rush()
	local rnumbers = GetNumGroupMembers();
		local ihp;
		if(rnumbers>17)then
			ihp=1000000;
		elseif(rnumbers>6)then
			ihp=400000;
		elseif(rnumbers==0)then
			ihp=60000;
		else
			ihp=160000;
		end
	if(UnitHealth("target")<ihp*10 and not WA_Is_Boss())then
		return;
	end

	--第一是燃烧可用 发生连击以后 就进入准备爆发状态 首先打出炎爆术 然后打火焰冲击 如果当时那个炎爆术爆击了 那么计算时间如果 嗜血如果没有设为无穷，点燃，活体炸弹的最短时间内
	if S.ToUseRS and WA_CheckSpellUsable("燃烧") then
		--D:Error("爆发状态：",bfs);
		if  bfs == 2 and WA_CheckBuff("炎爆术！") and WA_CheckSpellUsable("火焰冲击") then--这里要注意是
			--D:Error("准备火冲那阵子，爆发状态：",bfs);
			CCFlagSpell("火焰冲击");
			return true;
		elseif WA_CheckBuff("炎爆术！") and bfs==3 then
			local dr1,dr2 = WA_CheckDebuff("点燃",0,0,true);
			if dr1 then
				bfs = 0;
				return;
			end

			dr1,dr2 = WA_CheckDebuff("炎爆术",0,0,true);
			if dr1 then
				bfs = 0;
				return;
			end

			if true then
				CCFlagSpell("燃烧");
				return true;
			end

			local sx1,sx2 = D:IsSXing();
			local _name, _, _, castTime, _, _ = GetSpellInfo("火球术");
			D:Error("是否使用燃烧",dr2*1000,castTime);

			local minT = dr2;
			if sx1 then minT = min(minT,sx2);end
			if castTime+500>minT*1000 then
				CCFlagSpell("燃烧");
				return true;
			else
				return;
			end
		end
	else
		bfs=0;
	end

	if true then
		return;
	end

--	D:Error("总和伤害是",(combuigndamage+combulbdamage+combupyrodamage));

--	if WA_CheckSpellUsable("燃烧") and combuigndamage+combulbdamage+combupyrodamage > drdmgneed then
--		CCFlagSpell("燃烧");
--		return true;
--	end

	if WA_CheckSpellUsable("燃烧") and F:RushCondition() and combuigndamage > drdmgneed then
		CCFlagSpell("燃烧");
		return true;
	end

	if WA_CheckSpellUsable("燃烧") and F:RushCondition2() and combuigndamage > drdmgneed*1.5 then
		CCFlagSpell("燃烧");
		return true;
	end

	if WA_CheckSpellUsable("燃烧") and F:RushCondition2() and combuigndamage > drdmgneed then
		D:Error("点燃伤害已经有",combuigndamage,"可惜没有炎爆术");
--		CCFlagSpell("燃烧");
--		return true;
	end
end

function F:WorkUpdate()
	CombustionUpdate();
end

function F:CastingUpdate()


-- 有迸发 没炎爆

	if D.Casting.name~="炎爆术" and D.Casting.name~="火球术" and D.Casting.name~="灼烧" then

		return;

	end

	if CCFightType==1 and InCombat and (not WA_CheckBuff("热力迸发")) and WA_CheckBuff("炎爆术！") and D.Casting.process<0.5 and WA_CheckSpellUsable("炼狱冲击") then
		CCFlagSpell("炼狱冲击");

		return;
	end

end

function F:Work(pvp)

--	print("点燃伤害",combuigndamage);

	if CCFightType==2 then
		if((not WA_CheckBuff("炎爆术！")) and WA_CheckSpellUsable("炎爆术")) then
			CCFlagSpell("炎爆术");
			return;
		end

		if S:Bomb()  then return end

		-- and not WA_CheckDebuff("炎爆术",0,0,true)
		if(not WA_CheckDebuff("点燃",0,0,true) and WA_CheckSpellUsable("炼狱冲击"))then
			CCFlagSpell("炼狱冲击");
			return;
		end
		if(not WA_CheckDebuff("燃烧",0,0,true) and WA_CheckSpellUsable("炼狱冲击"))then
			CCFlagSpell("炼狱冲击");
			return;
		end
		if(WA_CheckSpellUsable("烈焰风暴") and GetTime()>nextframetime)then
			CCFlagSpell("烈焰风暴");
			return;
		end
		return;
	end

	if S:RushDps() then return end



	if((not WA_CheckBuff("炎爆术！")) and WA_CheckSpellUsable("炎爆术") and (not WA_CheckBuff("热力迸发"))) then
		--D:Error("1");
		CCFlagSpell("炎爆术");
		return;
	end


	--但是没炎爆术

	if((not WA_CheckBuff("热力迸发")) and WA_CheckSpellUsable("炼狱冲击") and WA_CheckBuff("炎爆术！")) then
		CCFlagSpell("炼狱冲击");
		return;
	end


	local _name, _, _, castTime, _, _ = GetSpellInfo("火球术");

	--一个简单的判断方式是看火球读条时间，若炸弹持续时间不足当前火球读条时间，则补炸弹。

	if S:Bomb(castTime)  then return end

	--祈愿 当伤害加成效果消失后唤醒
	local fillCast = "火球术";
	if castTime<1000 and D:CastReadable() and WA_CheckSpellUsable("炎爆术") then

		fillCast = "炎爆术";

	elseif (not D:CastReadable() and WA_CheckSpellUsable("灼烧")) then

		fillCast = "灼烧";
	end

	_name, _, _, castTime, _, _ = GetSpellInfo(fillCast);


	--在不浪费的前提下 不提前使用
	--有瞬发而且 瞬发不到castTime/1000

	if((not WA_CheckBuff("炎爆术！")) and WA_CheckSpellUsable("炎爆术") and WA_CheckBuff("炎爆术！",castTime/1000)) then
		CCFlagSpell("炎爆术");
		return;
	end

	--[[if not WA_CheckSpellUsable("炼狱冲击") then

		CCFlagSpell(fillCast);
		return;
	end
]]


	if((not WA_CheckBuff("炎爆术！")) and WA_CheckSpellUsable("炎爆术")) then
		CCFlagSpell("炎爆术");
		return;
	end




	CCFlagSpell(fillCast);

end

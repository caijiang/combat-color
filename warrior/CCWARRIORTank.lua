-- CCWARRIORTank.lua
local addonName, TT = ...;
local D = TT.jcc;

local _,clzz = UnitClass("player");
if clzz~="WARRIOR" then return;end

local W = D.WARRIOR;
local T = W:NewModule("WARRIOR3", "AceEvent-3.0", "AceHook-3.0","CCTalent-1.0");

T.TalentSpellDescs = {
		["盾牌猛击"] ={slot=30,havecd=true},
		["盾牌格挡"] = {slot=31,havecd=true},
		["毁灭打击"] = 32,
		["复仇"] ={slot=33,havecd=true},
		["破釜沉舟"] = {slot=34,havecd=true},
		["盾墙"] = {slot=35,havecd=true},
		["挫志怒吼"] = {slot=36,havecd=true},
		["盾牌冲锋"] = {slot=37,havecd=true},
		["挑战战旗"] = {slot=38,havecd=true},
		["雷霆一击"] = {slot=39,havecd=true}
	};

--拉住当前的怪物
--返回true 若需要施展技能
local function WA_PullNPC(tstate)
	if not D:AbleToPull() then
		return false;
	end
	if(not CCPullApprolved or tstate==3)then
--		print("禁止嘲讽！！");
		return false;
	end
	--需要确认这些debuf是我给的么？
	if(not WA_CheckDebuff("嘲讽"))then return false;end
	if(WA_CheckSpellUsable("嘲讽"))then
		CCFlagSpell("嘲讽");
		return true;
	end
	return false;
end

function T:Rush()
end

--战士自我保护
local function WA_PROTECTEDMYSELF()
	local myhp = UnitHealth("player")/UnitHealthMax("player");
	if(UnitName("targettarget")==UnitName("player") and CC_InRange() and myhp<0.9 and WA_CheckSpellUsable("盾牌格挡") and WA_CheckBuff("盾牌格挡"))then
		CCFlagSpell("盾牌格挡");
		--return true;
	end
	--[[if(UnitName("targettarget")==UnitName("player") and CC_InRange() and myhp<0.9 and WA_CheckSpellUsable("盾牌屏障") and WA_CheckBuff("盾牌屏障") and (not WA_CheckBuff("复仇之力") or not WA_CheckBuff("血性狂怒")))then
		CCFlagSpell("盾牌屏障");
		--return true;
	end]]
	if(WA_CheckSpellUsable("乘胜追击") and myhp<0.9)then
		CCFlagSpell("乘胜追击");
		return;
	end
	return false;
end

--力量>额外护甲>暴击>急速>溅射>全能>精通
local function gd_work()
	local usemorepower = 5;
        local timetodm = WA_CooldownLeft("盾牌猛击",1);
	local powergap = UnitPowerMax("player")-UnitPower("player");
	local inZS = UnitHealth("target")/UnitHealthMax("target")<=0.2 or WA_CheckSpellUsableOn("斩杀");
	local power = UnitPower("player");
	local myhp = UnitHealth("player")/UnitHealthMax("player");
        local _bufname,_,_,bqcount,_,bqduration,bqexpirationTime=UnitAura("player","不屈打击");

        local bqtimetoexpiration = -1;
        if _bufname then
            bqtimetoexpiration = GetTime()-bqexpirationTime;
        else
            bqcount = 0;
        end
        ---- RushConditon(环境易伤env,开启了sx,自身主属性强化ps)
        local rushable = W:ShouldRush();

        -- 自动rush的 必须有它充分的条件 手工编纂爆发宏 用于手控爆发！
        -- and rushable
        if CCAutoRush and not WA_CheckBuff("盾牌冲锋",6) then
            W:RushDps();
        end
	--if CCAutoRush and rushable then
	--	CCWA_RacePink();
        --end

	if WA_CheckSpellUsable("狂暴之怒") and  WA_CheckBuff("激怒") and not WA_CheckBuff("盾牌冲锋") then
		CCFlagSpell("狂暴之怒");
	end

    if not WA_CheckBuff("盾牌冲锋") and (not inZS or not WA_CheckBuff("最后通牒")) and WA_CheckSpellUsableOn("英勇打击") then
    	CCFlagSpell("英勇打击");
    end

    local ayycost = 30-bqcount*5;
    if not WA_CheckBuff("最后通牒") then
    	ayycost = 0;
    end

    local agapneed = 20;

    if timetodm<2 then
    	-- 怒气马上进账
    	agapneed = agapneed + 20;
    	if not WA_CheckBuff("剑盾猛攻") then
    		agapneed = agapneed + 5;
    	end
    end

    --powergap<=25+usemorepower
    if (
    	powergap+ayycost<=agapneed
    	or powergap<=20
    	or (not WA_CheckBuff("最后通牒") and (WA_CheckBuff("最后通牒",1) or timetodm<1))
    	or bqcount>4 ) and WA_CheckSpellUsableOn("英勇打击") then
    	CCFlagSpell("英勇打击");
    end

        -- 使用sc逻辑
--[[	if (powergap<20
		or not WA_CheckBuff("盾牌冲锋")
		or not WA_CheckBuff("最后通牒")
                or (
                    bqcount>4
                    )
                --不屈打击 5 6 层还放弃？？ 时间快到了
		) and WA_CheckSpellUsableOn("英勇打击") then
		CCFlagSpell("英勇打击");
	end]]


	if W.GCDLeftTime>D.MaxDelayS then
		return;
	end

	if WA_CheckSpellUsable("乘胜追击") and myhp<=0.65 then
		CCFlagSpell("乘胜追击");
		return;
	end

    local dpcfcharges, dpcfmaxCharges, dpcfstart, dpcfduration = GetSpellCharges("盾牌冲锋");

	local yydjtime = 1.5/(1+UnitSpellHaste("player")/100);
	local timeline = 0;
	local yyallcost = 0;
	while(timeline<7) do
		-- 根据当前的timeline
		local bqtimeout = bqtimetoexpiration-timeline;
		if (bqtimeout>=0) then
			yyallcost = yyallcost +30-bqcount*5;
		else
			-- 超过当前时间了 根据超支的时间 计算可能的层数
			local currentbqcount = bqcount;
			if bqtimeout<-5 then
				currentbqcount = currentbqcount+1;
				if currentbqcount==7 then
					currentbqcount = 0;
				end
				currentbqcount = currentbqcount+1;
				if currentbqcount==7 then
					currentbqcount = 0;
				end
			else
				currentbqcount = currentbqcount+1;
				if currentbqcount==7 then
					currentbqcount = 0;
				end
			end

			yyallcost = yyallcost +30-currentbqcount*5;
		end

		timeline = timeline+yydjtime;
	end

	D:Debug("7秒英勇需要",yyallcost);

	--[[
	local orgcost = 30;
	local costv = 30/1.5;
	orgcost = orgcost-bqcount*5;
	D:Debug("每个英打需要消耗",orgcost," 总消耗:",orgcost*5);
	orgcost = orgcost*5;
	if bqcount== 6 then
		orgcost = orgcost+max((7-bqtimetoexpiration)*costv,30);
		D:Debug("已经6层buf调整为",orgcost);
	elseif bqcount==5 and bqtimetoexpiration<2 then
		orgcost = orgcost+max((2-bqtimetoexpiration)*costv,30);
		D:Debug("已经5层buf调整为",orgcost);
	end]]

	if yyallcost>20 then
		yyallcost = yyallcost-20;
	end

	if not WA_CheckBuff("剑盾猛攻") and yyallcost>5 then
		yyallcost = yyallcost-5;
	end

	-- 推荐不屈打击
	if WA_CheckBuff("盾牌冲锋") and WA_CheckSpellUsableOn("盾牌冲锋") and (
                powergap<30
                or rushable
                or dpcfcharges>=dpcfmaxCharges
                or power>=yyallcost
                ) then
		CCFlagSpell("盾牌冲锋");
		return;
	end

	--英勇飞跃

    -- 拥有2层+ 但不是6层buf buf时间却少于1.5
    if bqcount>=2 and bqcount<6 and WA_CheckBuff("不屈打击",1.5) then
    	CCFlagSpell("毁灭打击");
    	return;
    end

    if CCFightType==2 and WA_CheckSpellUsable("剑刃风暴") then
		CCFlagSpell("剑刃风暴");
		return;
	end

	if CCFightType==2 and WA_CheckSpellUsable("雷霆一击") then
		CCFlagSpell("雷霆一击");
		return;
	end

	if WA_CheckSpellUsable("盾牌猛击")then
		CCFlagSpell("盾牌猛击");
		return;
	end

	if WA_CheckSpellUsable("复仇") then
		CCFlagSpell("复仇");
		return;
	end


	if W:SuddenExecute() then return;end

	if W:Fengbao() then return;end

        -- 巨龙很好用 cd留着 我自己用！
        -- or not WA_CheckBuff("浴血奋战")
	if (CCAutoRush or D.FightHSMode or CCFightType==2) and W:JulongNuhou() then return;end

	if (power>60
		or D:TimeToDie(4)
		-- and WA_CheckBuff("盾牌冲锋")
		) and WA_CheckSpellUsableOn("斩杀") then
		CCFlagSpell("斩杀");
		return;
	end

	CCFlagSpell("毁灭打击");
end

function T:Work()

	if not WA_CheckBuff("角斗姿态") then
		return gd_work();
	end

	if(GetShapeshiftForm()~=2)then
		jcmessage("确定要以非防御姿态拉怪么？？");
		--WR_DY_ST_Planning = 2;
	end

	local tstate = cc_updateThreats(true);

	local powergap = UnitPowerMax("player")-UnitPower("player");
	local inZS = UnitHealth("target")/UnitHealthMax("target")<=0.2;
        local _bufname,_,_,bqcount,_,bqduration,bqexpirationTime=UnitAura("player","不屈打击");

        local bqtimetoexpiration = -1;
        if _bufname then
            bqtimetoexpiration = GetTime()-bqexpirationTime;
        else
            bqcount = 0;
        end

	if (powergap<10
                    or not  WA_CheckBuff("最后通牒")
                    or bqcount>4
                        ) and WA_CheckSpellUsableOn("英勇打击") then
		CCFlagSpell("英勇打击");
	end

	--拉好怪哦
	--if(WA_PullNPC(tstate))then return end

	--保护自己
	if(WA_PROTECTEDMYSELF())then return end

	if W.GCDLeftTime>D.MaxDelayS then
		return;
	end

	if CCFightType==2 then
		if WA_CheckSpellUsable("破坏者") then
			CCFlagSpell("破坏者");
			return;
		end

		if WA_CheckSpellUsable("剑刃风暴") then
			CCFlagSpell("剑刃风暴");
			return;
		end

		if W:JulongNuhou() then return;end

		if WA_CheckSpellUsable("雷霆一击") then
			CCFlagSpell("雷霆一击");
			return;
		end

		if WA_CheckSpellUsable("复仇") then
			CCFlagSpell("复仇");
			return;
		end

		if WA_CheckSpellUsable("盾牌猛击")then
			CCFlagSpell("盾牌猛击");
			return;
		end

		CCFlagSpell("毁灭打击");
		return;
	end

	--有buf或者 仇恨不稳定
	local dunpaimg = CC_Target_Buf_Stealable() or (tstate~=3);

	--如果有剑盾猛攻这个buf 则盾牌猛击
	if WA_CheckSpellUsable("盾牌猛击")then
		CCFlagSpell("盾牌猛击");
		return;
	end

	--没 剑盾猛攻的盾猛

	if WA_CheckSpellUsable("复仇") then
		CCFlagSpell("复仇");
		return;
	end

	if W:Fengbao() then return;end
	if W:JulongNuhou() then return;end

	if W:SuddenExecute() then return;end

	CCFlagSpell("毁灭打击");
end

function T:DynamicShapeshiftForm()
	return false;
end

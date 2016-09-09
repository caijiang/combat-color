-- CCWARRIOR.lua

-- 所有计算应该是先计算GCD 根据下次出技能的时间为实际依据

local addonName, T = ...;
local OvaleSpellBook = T.OvaleSpellBook;
local D = T.jcc;

local _, clzz = UnitClass("player");
if clzz ~= "WARRIOR" then return; end

--[[local UnitIsPlayer = function()
return true;
end]]

local W = T.jcc:NewModule("WARRIOR", "AceEvent-3.0", "AceHook-3.0", "CCClass-1.0");
T.jcc.WARRIOR = W;


W.breakingSpell = "拳击";
-- 在狂暴姿态没有乘胜追击 怎么办？
W.testRangeHitSpell = "猛击";
W.testGCDSpell = "猛击";
W.ClassSpellDescs = {
    -- ["乘胜追击"] = 3,
    -- ["防御姿态"] =1,
    -- ["斩杀"] =4,
    ["破坏者"] = { slot = 4, havecd = true },
    ["拳击"] = { slot = 5, havecd = true },
    ["拳击M"] = { slot = 6, havecd = true, marco = "/cast [@mouseover,harm,nodead]拳击" },
    ["英勇投掷"] = { slot = 7, havecd = true },

    --["epvp"] = {slot=44,marco="/equipset pvp"},
    --["eshield"] = {slot=45,marco="/equipset shield"},
};

function W:matchGCD(time)
    return time == 1.5;
end

function W:SpellPohuaizhe()
    if WA_CheckSpellUsable("破坏者") and (not yuxueEnabled or not WA_CheckBuff("浴血奋战")) then
        CCFlagSpell("破坏者");
        return true;
    end
    return false;
end


local beautobreak = false;
local wujinkewangEnabled = false;
local yuxueEnabled = false;
local mengjiEnabled = false;
function W:PLAYER_REGEN_ENABLED()
    _, _, _, wujinkewangEnabled = GetTalentInfo(3, 3, GetActiveSpecGroup());
    _, _, _, yuxueEnabled = GetTalentInfo(6, 2, GetActiveSpecGroup());
    _, _, _, mengjiEnabled = GetTalentInfo(3, 3, GetActiveSpecGroup());
    beautobreak = false;

    if self.Talent and self.Talent.PLAYER_REGEN_ENABLED then
        self.Talent:PLAYER_REGEN_ENABLED();
    end
end

function W:isMengjiEnabled()
    return mengjiEnabled;
end

function W:isWujinkewangEnabled()
    return wujinkewangEnabled;
end

function W:isAutoBreak()
    return false;
    --	return OvaleSpellBook:IsActiveGlyph(58372);
end

function W:JulongNuhou(nojuren)
    if GetSpellInfo("浴血奋战") and WA_CheckBuff("浴血奋战") and not D.FightHSMode and CCFightType == 1 then
        return false;
    end

    if nojuren and not WA_CheckDebuff("巨人打击", 0.1, 0, true) then
        return false;
    end

    if WA_CheckSpellUsable("巨龙怒吼") then
        CCFlagSpell("巨龙怒吼");
        return true;
    end
    return false;
end

function W:SuddenExecute()
    if not WA_CheckBuff("猝死") and WA_CheckSpellUsable("斩杀") then
        CCFlagSpell("斩杀");
        return true;
    end
    return false;
end

function W:Fengbao()
    --暂时不考虑是否会浪费风暴
    -- and not WA_CheckDebuff("巨人打击",0.1,0,true)
    if WA_CheckSpellUsable("风暴之锤") then
        CCFlagSpell("风暴之锤");
        return true;
    end
    return false;
end

function W:PushGCD()
    if (WA_CheckSpellUsable("胜利在望")) then
        CCFlagSpell("胜利在望");
        return true;
    end

    return false;
end

function W:AllowWork(inputpvp)
    if ((not InCombat) or (not WA_NeedAttack())) then return end

    if ((not inputpvp) and CC_Raid_B()) then return end

    if (UnitIsBeFear("target") or UnitIsNotAbleAttack("target") or UnitIsBeOutControl("target")) then
        --jcmessage("目标无法自主～～");
        --return;
    end

    WR_DY_ST = W.Talent:DynamicShapeshiftForm();

    local pvp = UnitIsPlayer("target");
    if (inputpvp) then
        pvp = true;
    end

    if (CCWA_Check_PreToCasts(pvp)) then return end

    if (not pvp and W.TalentType ~= 3) then
        if (CC_check_threat_dps()) then return end
    end

    if (CC_TargetisWudi()) then
        if (Try_Cast_AI("碎裂投掷") ~= 0) then
            jcmessage("别移动！！");
        else
            jcmessage("换目标");
        end
        return;
    end

    if (pvp) then
        --if(CC_PVP())then return end
    end

    if (not CC_InRange()) then
        --不在范围 就暂时不管啦
        return;
    end

    --if true then return false end

    return true;
end

--高伤害状态
--hshj 忽视护甲技能
function W:RushConditon(hshj)
    return D:IsDamageIncrement()
            or (not hshj and (not WA_CheckDebuff("巨人打击", 0.1, 0, true)))
    --[[or (not WA_CheckBuff("天神祝福"))
    or (not WA_CheckBuff("雷神的遗诏"))
    or (not WA_CheckBuff("鲁莽"))
    or (not WA_CheckBuff("震怒"))
    or (not WA_CheckBuff("决断"))
    or (not WA_CheckBuff("坚韧"))
    or (not WA_CheckBuff("浴血奋战"))
    or (not WA_CheckBuff("天神下凡"))
    or (not WA_CheckBuff("强度激增"))]];
end

function W:RushDps()
    --保证 在怒炉未满之前 不使用同cd大技能！
    --在有怒l的情况下 绝对保证cd和大技能一致！
    local nlok, nlid, nltrid = W:Check_NL_Trinkets(59461, "原始狂怒", 5, "铸炼怒火");

    if (nlok and (not nlid)) then
        nlok, nlid, nltrid = W:Check_NL_Trinkets(68972, "泰坦能量", 5, "塑造者的祝福");
    end
    if (nlid == 68972 and (not nlok) and WA_CheckSpellUsable("鲁莽")) then
        nlok = true;
    end
    --开启鲁莽，巨人，种族，药剂，
    --而鲁莽的开启条件是 巨人 可用 目标已撕裂
    local rushcond = true;
    local rushcodwithlm = rushcond or (not WA_CheckBuff("鲁莽"));
    local superrush = (not WA_CheckBuff("狂怒之心", 10))
            or (not WA_CheckBuff("胜利之悦", 10))
            --or (not WA_CheckBuff("天神祝福"))
            or (not WA_CheckBuff("铸炼怒火", 10));

    if (nlok and
            CCAutoRush and WA_CheckSpellUsable("鲁莽")
            and rushcond and superrush
            and WA_CheckBuff("塑造者的祝福")) then
        -- 排除 塑造者的祝福
        CCFlagSpell("鲁莽");
        --		return;
    end

    if (nlok and
            CCAutoRush
            --		and (not WA_CheckSpellUsable("鲁莽"))
            and rushcodwithlm) then
        W.Talent:Rush();
        -- 排除 鲁莽
        local checkFun = function(trid)
            if (trid == 68972) then
                if ((superrush and WA_CheckSpellUsable("鲁莽")) or (not WA_CheckBuff("鲁莽"))) then
                    return false;
                end
            end
            return true;
        end;
        CCWA_RacePink(false, checkFun);
        if WA_CheckSpellUsable("浴血奋战") then
            CCFlagSpell("浴血奋战");
        end
    end

    if ((not nlok)
            and CCAutoRush
            and rushcodwithlm) then
        CCWA_RacePink(true);
        if WA_CheckSpellUsable("浴血奋战") then
            CCFlagSpell("浴血奋战");
        end
    end
    return false;
end

-- 返回 nlok,nlid,nltrid  如果是true表示是准备就绪 或者已cd或使用 或者根本没有佩戴该sp的
-- 如果返回的nlid也是nil 那就真是没佩戴该sp
function W:Check_NL_Trinkets(itemId, preBufName, preTimes, bufName)
    local nlok = not (GetInventoryItemID("player", INVSLOT_TRINKET1) == itemId or GetInventoryItemID("player", INVSLOT_TRINKET2) == itemId);
    if (nlok) then
        return nlok;
    end
    local sssssid = 0;
    if (GetInventoryItemID("player", INVSLOT_TRINKET1) == itemId) then
        sssssid = INVSLOT_TRINKET1;
    else
        sssssid = INVSLOT_TRINKET2;
    end
    --那么仪器呢？
    -- 68972 泰坦能量  塑造者的祝福
    -- checkcd
    nlok = not WA_CheckBuff(preBufName, 0, preTimes);
    if (nlok) then
        --如果buf堆够了
        local _, _, e = GetInventoryItemCooldown("player", sssssid);
        if (not e) then
            nlok = false;
        end
    end

    --也许已经开启了呢？
    if (not nlok) then
        nlok = not WA_CheckBuff(bufName);
    end
    --必须等待nl cd
    return nlok, itemId, sssssid;
end

function W:Chengsheng(rate)
    if not rate then
        rate = 0.99;
    end
    if WA_CheckSpellUsable("乘胜追击") and UnitHealth("player") / UnitHealthMax("player") <= rate then
        CCFlagSpell("乘胜追击");
        return true;
    end
    return false;
end


--特殊的战士技能
function W:yy_in_zs()
    --斩杀阶段如果触发了战斗专注  就请不要英勇
    if (not WA_CheckBuff("战斗专注")) then
        return true;
    end
    --请自行决定！
    return false
end

-- 如果没有timec 表示是预备 如果是5层破甲 必须维持在gcd+CC_Global_Delay之内 否者不管
-- 反之 如果没到5层就堆 到了就判断时间
function W:DPS_Pojia(timec)
    if (not DPS_Pojia_Enable) then
        return false;
    end
    if (BossOnly and not WA_Is_Boss()) then
        return false;
    end
    if (not timec) then
        if (WA_CheckDebuff("破甲", CC_Global_Delay + 1.5 + 1) and WA_CheckSpellUsable("破甲攻击")) then
            CCFlagSpell("破甲攻击");
            return true;
        end
    else
        if (WA_CheckDebuff("破甲", timec, 3) and WA_CheckSpellUsable("破甲攻击")) then
            CCFlagSpell("破甲攻击");
            return true;
        end
    end
    return false;
end


--如果受到被动伤害（判定HP<90%），开狂暴之怒；
function W:Kuangbaozhinu(maxhealth, maxmn)
    -- and UnitHealth("player")/UnitHealthMax("player")<0.9
    if (CC_InRange() and WA_CheckSpellUsable("狂暴之怒") and UnitPower("player") < maxmn) then
        CCFlagSpell("狂暴之怒");
        --return true;
    end
    return false;
end

function W:XueXingKuangBaoByZhisidaji(maxmn)
    local t1 = WA_CooldownLeft("致死打击");
    if (t1 < 1.5) then
        return W:Kuangbaozhinu(0.9, maxmn);
    end
    return false;
end

--破它的甲
function W:Pojia()
    --看下自己会不会毁灭打击
    local sn;
    if GetSpellInfo("毁灭打击") then
        sn = "毁灭打击";
    else
        sn = "破甲攻击";
    end
    if (WA_CheckSpellUsable(sn)) then
        CCFlagSpell(sn);
        return true;
    end
    return false;
end


--只有怒气缺口小于指定数值
function W:Yingyongdaji(mn, stopfn, goingfn)
    if WA_CooldownLeft("英勇打击", true) > D.MaxDelayS then
        return false;
    end
    local powergap = UnitPowerMax("player") - UnitPower("player");
    if CC_Raid_NoRush() then
        return false;
    end
    if UnitIsPlayer("target") then
        if mn < 50 then
            mn = 50;
        end
    end

    local doit = false;
    if goingfn and goingfn() then
        doit = true;
    end
    if (stopfn and not doit) then
        local retOk, retDone = pcall(stopfn);
        if (retOk and retDone) then
            return false;
        end;
    end
    if ((not WA_CheckBuff("复仇雕文"))) then
        CCFlagSpell("英勇打击");
        return true;
    end

    --or not WA_CheckDebuff("巨人打击",0,0,true)
    if powergap < mn or not WA_CheckBuff("最后通牒") or doit or (UnitPower("player") > 35) then
        if CCFightType == 1 and WA_CheckSpellUsableOn("英勇打击") then
            CCFlagSpell("英勇打击");
            return true;
        end
        if CCFightType == 2 and WA_CheckSpellUsableOn("顺劈斩") then
            CCFlagSpell("顺劈斩");
            return true;
        end
    end
    return false;
end

function W:Xuanfengzhan()
    if (CC_InRange() and WA_CheckSpellUsable("旋风斩")) then
        CCFlagSpell("旋风斩");
        return true;
    end
    return false;
end

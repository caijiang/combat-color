-- CCHunter.lua

-- CCDK.lua

local addonName, T = ...;
local D = T.jcc;
local OvaleState = T.OvaleState;
local OvaleSpellBook = T.OvaleSpellBook;
local OvalePower = T.OvalePower;

local _, clzz = UnitClass("player");
if clzz ~= "HUNTER" then return; end

local K = D:NewModule("HUNTER", "AceEvent-3.0", "AceHook-3.0", "CCClass-1.0");
D.HUNTER = K;

K.breakingSpell = "反制射击";
K.testGCDSpell = "奥术射击";
K.ClassSpellDescs = {
--标记射击
--    风之爆裂
    ["假死"] = { slot = 3, havecd = true },
    ["解散宠物"] = 4,
--    泰坦之雷
--雄鹰之怒
    ["治疗宠物"] = 7,

--    ["奥术射击"] = 1,
--    ["稳固射击"] = 2,
--
--
--    ["多重射击"] = 8,
--    ["冰冻陷阱"] = { slot = 9, havecd = true },
--    ["宁神射击"] = 12,
--    ["爆炸陷阱"] = { slot = 13, havecd = true },
--    ["冰霜陷阱"] = { slot = 14, havecd = true },
--    ["扰乱射击"] = { slot = 15, havecd = true },
--    ["主人的召唤"] = { slot = 16, havecd = true },
--
--    ["威慑"] = { slot = 19, havecd = true },
--
--
--
--     -- become a 天赋技能
--    ["飞刃"] = { slot = 24, havecd = true },
--    ["强风射击"] = { slot = 24, havecd = true },
--
--    ["专注射击"] = { slot = 24, havecd = true },
--
};

local STEADY_FOCUS = 177668
function K:FocusCastingRegen(spell)
    local state = OvaleState.state;
    local regenRate = state.powerRate.focus;
    local power = 0;
    -- Get the "execute time" of the spell (larger of GCD or the cast time).
    local castTime = OvaleSpellBook:GetCastTime(spell) or 0;
    local gcd = state:GetGCD();
    local castSeconds = (castTime > gcd) and castTime or gcd;
    power = power + regenRate * castSeconds;

    local aura = state:GetAura("player", STEADY_FOCUS, "HELPFUL", true);
    if aura then
        local seconds = aura.ending - state.currentTime;
        if seconds <= 0 then
            seconds = 0;
        elseif seconds > castSeconds then
            seconds = castSeconds;
        end
        -- Steady Focus increases the focus regeneration rate by 50% for its duration.
        power = power + regenRate * 1.5 * seconds;
    end
    return power;
end

-- 校验施展某技能以后集中不会溢出
function K:FocusSafe(spell, power)
    local state = OvaleState.state;
    power = power or 0;
    power = power + K:FocusCastingRegen(spell);

    return power <= OvalePower:GetPowerDeficit();
end

-- 急速射击的校验
function K:JisushejiIsComing(spell, focus)
    focus = focus or 0;
    local state = OvaleState.state;

    local castTime = OvaleSpellBook:GetCastTime(spell) or 0;
    local gcd = state:GetGCD();
    local castSeconds = (castTime > gcd) and castTime or gcd;

    return OvalePower:GetPowerDeficit() * castSeconds / (K:FocusCastingRegen(spell) + focus) > WA_CooldownLeft("急速射击", true)
end

-- 检查是否可以在非急速和非嗜血状态下使用的物品
function K:checktouseitem(itemid)
    return false;
end

function K:matchGCD(time)
    return time == 1;
end


function K:DoWengu()
    if D:CastReadable() and WA_CheckSpellUsable("专注射击") then
        CCFlagSpell("专注射击");
        return;
    end
    if WA_CheckSpellUsable("眼镜蛇射击") then
        CCFlagSpell("眼镜蛇射击");
        return;
    end
    if WA_CheckSpellUsable("稳固射击") then
        CCFlagSpell("稳固射击");
        return;
    end
end

function K:CheckWengu()
    local castingwg = D.Casting.name and D.Casting.name == "稳固射击";
    -- 上次稳固没有恢复时间->这次肯定可以了
    -- 上次施展的是稳固 现在读条是稳固
    -- D:Debug("最近时间:",D:LastCasted("稳固射击")," 获得奖励的稳固:",K.lastEndWenguTime," 正在?:",castingwg," 最后一次技能:",K.LastSpell);
    -- D:Debug("不是必须稳固",(D:LastCasted("稳固射击")~=K.lastEndWenguTime and castingwg and K.LastSpell=="稳固射击"))
    if D:LastCasted("稳固射击") ~= K.lastEndWenguTime and castingwg and K.LastSpell == "稳固射击" then
        return false;
    end
    --[[	if UnitPower("player")>90 then
            return;
        end]]
    if WA_CheckBuff("强化稳固射击", 3) and K:WenguAble() then
        --		D:Debug("需要强化稳固射击了");
        CCFlagSpell("稳固射击");
        return true;
    end
    --稳固射击 必须是2次为一个单位射出
    --简单的说 再一次未end的 稳固射击 开始施展之前 必须施展稳固射击
    --	D:Debug("稳固是否才射了一下:",castingwg," 最后稳固时间:",D:LastCasted("稳固射击"));

    if K.LianxuwenguTimes >= 6 then
        D:Error("连续", K.LianxuwenguTimes, "次的稳固 何解？？");
        return false;
    end

    if castingwg and D:LastCasted("稳固射击") == K.lastEndWenguTime and K:WenguAble() then
        CCFlagSpell("稳固射击");
        return true;
    end
    return false;
end

function K:AuraUpdate(unit)
    if "player" == unit then
        local name, rank, iconTexture, count, debuffType, duration, expirationTime, source = UnitAura("player", "强化稳固射击", nil, "HELPFUL");
        expirationTime = expirationTime or 0;
        if expirationTime > K.LastImprovedWenguLeft then
            K.lastEndWenguTime = D:LastCasted("稳固射击");
            --			D:Debug("我的稳固为我带来了收益",K.lastEndWenguTime);
            --查找上次使用的稳固射击 并标记为 END
        end
        K.LastImprovedWenguLeft = expirationTime;
    end
end

K.LastImprovedWenguLeft = 0;
K.lastEndWenguTime = -1;
K.LastSpell = "";
K.LianxuwenguTimes = 0;

local lastbzsj1, lastbzsj2;
local function insertNewBZSJ()
    if lastbzsj1 then
        lastbzsj2 = lastbzsj1;
    end
    lastbzsj1 = GetTime();
end

local function checkBZSJ()
    K.NOBZSJ = lastbzsj1 and lastbzsj2 and GetTime() - lastbzsj1 < 0.8 and lastbzsj1 - lastbzsj2 < 1.4;
end

function K:SpellCasted(spell)
    if spell == "自动射击" then return end;

    if spell == "稳固射击" or spell == "眼镜蛇打击" then
        K.needLinghu = false;
    end

    --连续2次 爆炸
    --if strfind(spell,"射击")
    if spell == "爆炸射击" then
        insertNewBZSJ();
    end

    checkBZSJ();

    if spell == "稳固射击" then
        K.LianxuwenguTimes = K.LianxuwenguTimes + 1;
    else
        K.LianxuwenguTimes = 0;
    end
    K.LastSpell = spell;
end

function K:Rush(rushable)

    if CCAutoRush and rushable and WA_CheckSpellUsable("群兽奔腾") then
        CCFlagSpell("群兽奔腾");
    end

    if CCAutoRush and rushable then
        CCWA_RacePink();
    elseif CCAutoRush and K:RushPrepose() then
        CCWA_RacePink(false, checktouseitem);
    end

    return CCAutoRush and rushable;
end

local lastMountedTime = 0;
function K:AllowWork(inputpvp)
    if (not WA_CheckBuff("假死")) then
        return
    end

    if IsMounted() then
        lastMountedTime = GetTime();
    end

    --如果点了独来独往就不提示了
    if WA_CheckBuff("独来独往") and not IsMounted() and GetTime() - lastMountedTime > 2 and not CCShareHoly.isHelp("pet") then
        jcmessage("没有宠物！！");
    end
    --[[if(not WA_CheckBuff("陷阱发射器"))then
        return
    end]]
    if ((not InCombat) or (not WA_NeedAttack())) then return end

    if (CC_Raid_B()) then return end

    if (UnitIsBeFear("target") or UnitIsNotAbleAttack("target") or UnitIsBeOutControl("target")) then
        return;
    end

    local pvp = UnitIsPlayer("target");
    if (inputpvp) then
        pvp = true;
    end

    if (CCWA_Check_PreToCasts(pvp)) then return end

    if not pvp then
        if (CC_check_threat_dps()) then return end
    end

    if (CC_TargetisWudi()) then
        jcmessage("换目标");
        return;
    end

    local timeToFinish = D.Casting.ttf * 1000;
    if D.Casting.name then
        if D.Casting.channeling then
            return;
        end
        if (timeToFinish >= 500) then
            return;
        end
    end

    --[[	if(pvp and (CC_PVP_Enable or inputpvp))then
            if(CC_PVP())then return end
        end]]


    --[[	if (CC_Target_Buf_Typed("Magic") or CC_Target_Buf_Typed("Enrage") or CC_Target_Buf_Typed("")) and WA_CheckSpellUsable("宁神射击") then
            CCFlagSpell("宁神射击");
            return;
        end]]

    --何时可使用误导？ 只有一个人的时候 才误导吧
    --[[	if GetNumSubgroupMembers() == 0 and GetNumGroupMembers() == 0 and WA_CheckBuff("误导") and WA_CheckSpellUsable("误导") then
            if UnitGUID("targettarget")==UnitGUID("player") then
                CCFlagSpell("误导2");
            else
                CCFlagSpell("误导");
            end
            return;
        end]]

    if ALWAYSWD and WA_CheckBuff("误导") and WA_CheckSpellUsable("误导") then
        CCFlagSpell("误导2");
        return;
    end

    local petindanger = UnitHealth("pet") / UnitHealthMax("pet") < 0.6;
    local petExists = (UnitExists("pet") and (not UnitIsDeadOrGhost("pet")) and (not UnitIsCorpse("pet")));

    --	petindanger = true;

    --保护自己 比如治疗宠物 逃脱
    if (petindanger and petExists and WA_CheckBuff("治疗宠物", 0, 0, true, "pet") and WA_CheckSpellUsable("治疗宠物")) then
        CCFlagSpell("治疗宠物");
        return;
    end

    --	if UnitHealth("target")
    --	if K.TalentType~
    local spell, _, _, _, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo("target");
    if spell and spell == "核能冲击" then
        if K.TalentType == 2 then
            CCFlagSpell("稳固射击");
        else
            CCFlagSpell("眼镜蛇射击");
        end
    end
    return true, pvp;
end

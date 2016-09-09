--
-- Created by IntelliJ IDEA.
-- User: luffy
-- Date: 2016/9/9
-- Time: 20:05
-- To change this template use File | Settings | File Templates.
--
--DaemonHunter.lua
local addonName, T = ...;
local D = T.jcc;
local OvaleState = T.OvaleState;
local OvaleSpellBook = T.OvaleSpellBook;
local OvalePower = T.OvalePower;

--恶魔猎手, DAEMONHUNTER 12
--Havoc Vengeance
local _, clzz = UnitClass("player");
if clzz ~= "DAEMONHUNTER" then return; end

local K = D:NewModule("DAEMONHUNTER", "AceEvent-3.0", "AceHook-3.0", "CCClass-1.0");
D.DAEMONHUNTER = K;

K.breakingSpell = "吞噬魔法";
K.testGCDSpell = "恶魔之咬";
K.testRangeHitSpell = "恶魔之咬";
K.ClassSpellDescs = {
    ["恶魔之咬"] = 1,
    ["混乱打击"] = 2,
    ["复仇回避"] = { slot = 3, havecd = true },
    ["混乱新星"] = { slot = 4, havecd = true },
    ["疾影"] = { slot = 5, havecd = true },
    ["灵魂切削"] = { slot = 6, havecd = true },
    ["刃舞"] = { slot = 7, havecd = true },
    ["投掷利刃"] = { slot = 8, havecd = true },
    ["吞噬魔法"] = { slot = 9, havecd = true },
    ["伊利达雷之怒"] = { slot = 10, havecd = true },
    ["复仇回避"] = { slot = 11, havecd = true },
};


function K:AllowWork(inputpvp)
    if ((not InCombat) or (not WA_NeedAttack())) then return end

    if ((not inputpvp) and CC_Raid_B()) then return end

    if (UnitIsBeFear("target") or UnitIsNotAbleAttack("target") or UnitIsBeOutControl("target")) then
        --jcmessage("目标无法自主～～");
        --return;
    end

    local pvp = UnitIsPlayer("target");
    if (inputpvp) then
        pvp = true;
    end

    if (CCWA_Check_PreToCasts(pvp)) then return end

    if (CC_TargetisWudi()) then
        jcmessage("换目标");
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


-- Havoc.lua

local addonName, T = ...;
local OvaleEquipment = T.OvaleEquipment;
local OvaleSpellBook = T.OvaleSpellBook;
local D = T.jcc;

local _, clzz = UnitClass("player");
if clzz ~= "DAEMONHUNTER" then return; end

D.lastKuangbaoZitai = 0;
local W = T.jcc.DAEMONHUNTER;
local A = W:NewModule("DAEMONHUNTER1", "AceEvent-3.0", "AceHook-3.0", "CCTalent-1.0");

function A:PLAYER_REGEN_ENABLED()
end

-- 狂暴之怒 断筋 战吼 拳击 嘲讽 剑在人在 冲锋 怒火聚焦
A.TalentSpellDescs = {
    --英勇之怒？ 没必要
    ["邪能之刃"] = { slot = 21, havecd = true },
    ["虚空行走"] = { slot = 22, havecd = true },
    ["邪能爆发"] = { slot = 23, havecd = true },
    ["涅墨西斯"] = { slot = 23, havecd = true },
    ["混乱之刃"] = { slot = 24, havecd = true },
    ["邪能弹幕"] = { slot = 24, havecd = true },
    ["幻影打击"] = { slot = 26, havecd = true },
};

function A:Rush()
end

local function poweruseable(mana)
    -- aoe的时候 不留能量
    if CCFightType == 2 then
        return true;
    end

    return true;
end

local function aoe()
    local deficit = UnitPowerMax("player") - UnitPower("player");
    local power = UnitPower("player");
    local inZS = UnitHealth("target") / UnitHealthMax("target") <= 0.2;

end

local function single()
    local deficit = UnitPowerMax("player") - UnitPower("player");
    local power = UnitPower("player");
    local inZS = UnitHealth("target") / UnitHealthMax("target") <= 0.2;

    if WA_CheckSpellUsable("投掷利刃") then
        CCFlagSpell("投掷利刃");
        return;
    end

    if WA_CheckSpellUsable("混乱打击") then
        CCFlagSpell("混乱打击");
        return;
    end

    if WA_CheckSpellUsable("恶魔之咬") then
        CCFlagSpell("恶魔之咬");
        return;
    end

end

function A:Work(pvp)
    local deficit = UnitPowerMax("player") - UnitPower("player");

    local rushable = W:ShouldRush();

    -- 自动rush的 必须有它充分的条件 手工编纂爆发宏 用于手控爆发！
    if CCAutoRush and rushable then
        W:RushDps();
    end

--    CCFlagSpell("petattack");

    if W.GCDLeftTime > D.MaxDelayS then
        return;
    end

    if CCFightType == 1 then
        return single();
    else
        return aoe();
    end
end

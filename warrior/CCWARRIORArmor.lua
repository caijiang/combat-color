-- CCWARRIORArmor.lua

-- 龙吼找巨人外，风暴锤找巨人内。

local addonName, T = ...;
local OvaleEquipment = T.OvaleEquipment;
local OvaleSpellBook = T.OvaleSpellBook;
local D = T.jcc;

local _, clzz = UnitClass("player");
if clzz ~= "WARRIOR" then return; end

D.lastKuangbaoZitai = 0;
local W = T.jcc.WARRIOR;
local A = W:NewModule("WARRIOR1", "AceEvent-3.0", "AceHook-3.0", "CCTalent-1.0");

function A:PLAYER_REGEN_ENABLED()
end

-- 狂暴之怒 断筋 战吼 拳击 嘲讽 剑在人在 冲锋 怒火聚焦
A.TalentSpellDescs = {
    --英勇之怒？ 没必要
    ["压制"] = { slot = 10, havecd = true },
    ["震荡波"] = { slot = 11, havecd = true },
    ["风暴之锤"] = { slot = 11, havecd = true },
    ["撕裂"] = { slot = 12 },
    ["天神下凡"] = { slot = 12, havecd = true },
    ["防御姿态"] = { slot = 13, havecd = true },
    ["怒火聚焦"] = { slot = 14, havecd = true },
    ["撕裂M"] = { slot = 17, marco = "/cast [@mouseover,harm,nodead]撕裂" },
    ["乘胜追击"] = { slot = 18, havecd = true },
    ["断筋"] = { slot = 19, havecd = true },
    ["剑刃风暴"] = { slot = 20, havecd = true },
    ["巨人打击"] = { slot = 21, havecd = true },
    ["狂暴之怒"] = { slot = 22, havecd = true },
    ["猛击"] = { slot = 23, havecd = true },
    ["顺劈斩"] = { slot = 24, havecd = true },
    ["旋风斩"] = { slot = 25, havecd = false },
    ["斩杀"] = { slot = 26, havecd = true },
    ["战吼"] = { slot = 27, havecd = true },
    ["致死打击"] = { slot = 28, havecd = true },
};

local TalentID_JJ = 22800;
local function enabled_jj()
    -- OvaleSpellBook:GetTalentPoints(TalentID_JJ) > 0
    return GetSpellInfo("怒火聚焦")~=nil;
end

function A:Rush()
end

local function poweruseable(mana)
    -- aoe的时候 不留能量
    if CCFightType == 2 then
        return true;
    end

    if mana<15 then
        return true;
    end
    if enabled_jj() then
        -- 下次拥有足够怒气在下次打致死的时候可以保持3层buf
        local timetozs = WA_CooldownLeft("致死打击", true);
        local count = 3-WA_BuffCount("怒火聚焦");
        local rageRate = 30/3;
        local power = UnitPower("player");
        D:Debug("timetozs:",timetozs,",plan powner:",timetozs*rageRate+power,",required power:",count*15+mana+20);
        return timetozs*rageRate+power>count*15+mana+20;
    end

    return true;
end

local function aoe()
    local deficit = UnitPowerMax("player") - UnitPower("player");
    local power = UnitPower("player");
    local inZS = UnitHealth("target") / UnitHealthMax("target") <= 0.2;
    local timetojr = WA_CooldownLeft("巨人打击", true);
    local timetozs = WA_CooldownLeft("致死打击", true);

    D:Debug("D:TimeToLive(4):", D:TimeToLive(4), " (撕裂,5.4,0,true):", WA_CheckDebuff("撕裂", 5.4, 0, true));
    if poweruseable(5) and WA_CheckSpellUsable("撕裂") and D:TimeToLive(4)
            and WA_CheckDebuff("撕裂", 5.4, 0, true) then
        CCFlagSpell("撕裂");
        return;
    end
    if poweruseable(5) and WA_CheckSpellUsableOn("撕裂", "mouseover") and D:TimeToLive(4, "mouseover")
            and WA_CheckDebuff("撕裂", 5.4, 0, true, "mouseover") then
        CCFlagSpell("撕裂M");
        return;
    end

    --破坏者 剑刃风暴
    --如果身上有巨人了呢？
    if WA_CheckSpellUsable("巨人打击") then
        CCFlagSpell("巨人打击");
        return;
    end

    if not WA_CheckDebuff("巨人打击", 0.1, 0, true) and W:Fengbao() then return; end

    if poweruseable(10) and WA_CheckSpellUsable("压制") and D:notEnoughEnemies(7) then
        CCFlagSpell("压制");
        return;
    end

    --((rage.deficit<48&cooldown.巨人打击.remains>gcd)|rage>80|target.time_to_die<5|debuff.巨人打击.up)
    local zs1 = (deficit < 48 and timetojr > W.GCDLeftTime) or power > 80 or not D:TimeToLive(5) or not WA_CheckDebuff("巨人打击", 0.1, 0, true)
    if poweruseable(10) and WA_CheckSpellUsable("斩杀") and WA_CheckBuff("猝死")
            and zs1 and D:notEnoughEnemies(7)
    then
        CCFlagSpell("斩杀");
        return;
    end

    if poweruseable(20) and WA_CheckSpellUsable("致死打击") and not inZS
            and (power > 60 or not WA_CheckDebuff("巨人打击", 0.1, 0, true))
            and D:notEnoughEnemies(5) then
        CCFlagSpell("致死打击");
        return;
    end

    if poweruseable(10) and WA_CheckSpellUsable("顺劈斩") then
        CCFlagSpell("顺劈斩");
        return;
    end
    if poweruseable(25) and WA_CheckSpellUsable("旋风斩") then
        CCFlagSpell("旋风斩");
        return;
    end

end

local function usezs()
    D:Debug("聚焦", enabled_jj(), WA_CheckBuff("怒火聚焦", 0.5, 3));
    if enabled_jj() and WA_CheckBuff("怒火聚焦", 0.5, 3) then
        return false;
    end
    -- and not inZS TODO 斩杀阶段怎么打还不知道
    -- 此处移除了怒气判断 致死为最优先技能
    D:Debug("poweruseable(20):", poweruseable(20), " WA_CheckSpellUsable(\"致死打击\"):", WA_CheckSpellUsable("致死打击"));
    if  WA_CheckSpellUsable("致死打击") then
        CCFlagSpell("致死打击");
        return true;
    end
    return false;
end

local function single()
    local deficit = UnitPowerMax("player") - UnitPower("player");
    local power = UnitPower("player");
    local inZS = UnitHealth("target") / UnitHealthMax("target") <= 0.2;
    local timetojr = WA_CooldownLeft("巨人打击", true);
    local timetozs = WA_CooldownLeft("致死打击", true);

    if poweruseable(10) and WA_CheckSpellUsable("巨人打击") and WA_CheckDebuff("巨人打击", 0.1, 0, true) and not CC_Raid_NoRush() then
        CCFlagSpell("巨人打击");
        return;
    end

    if usezs() then
        return;
    end

    if poweruseable(10) and WA_CheckSpellUsable("巨人打击") then
        CCFlagSpell("巨人打击");
        return;
    end

    D:Debug("D:TimeToLive(4):", D:TimeToLive(4), " (撕裂,W.GCDLeftTime,0,true):", WA_CheckDebuff("撕裂", W.GCDLeftTime, 0, true), " (巨人打击,0.1,0,true):", WA_CheckDebuff("巨人打击", 0.1, 0, true), " (撕裂,5.4,0,true):", WA_CheckDebuff("撕裂", 5.4, 0, true));

    if poweruseable(5) and WA_CheckSpellUsable("撕裂") and D:TimeToLive(4)
            and (WA_CheckDebuff("撕裂", W.GCDLeftTime, 0, true)
            or (WA_CheckDebuff("巨人打击", 0.1, 0, true)
            and WA_CheckDebuff("撕裂", 5.4, 0, true))) then
        CCFlagSpell("撕裂");
        return;
    end
    if poweruseable(5) and WA_CheckSpellUsableOn("撕裂", "mouseover") and D:TimeToLive(4, "mouseover")
            and (WA_CheckDebuff("撕裂", W.GCDLeftTime, 0, true, "mouseover")
            or (WA_CheckDebuff("巨人打击", 0.1, 0, true)
            and WA_CheckDebuff("撕裂", 5.4, 0, true, "mouseover"))) then
        CCFlagSpell("撕裂M");
        return;
    end

    --actions.single+=/破坏者,if=cooldown.巨人打击.remains<4&(!raid_event.adds.exists|raid_event.adds.in>55)

    --剑刃风暴
    if not WA_CheckDebuff("巨人打击", 0.1, 0, true) and W:Fengbao() then return; end

    if poweruseable(10) and WA_CheckSpellUsable("压制") then
        CCFlagSpell("压制");
        return;
    end

    if poweruseable(10) and WA_CheckSpellUsable("斩杀")
            and (not WA_CheckDebuff("巨人打击", 0.1, 0, true)
            or (deficit < 48 and timetojr > W.GCDLeftTime)) then
        CCFlagSpell("斩杀");
        return;
    end

    D:Debug("D:TimeToLive(4):", D:TimeToLive(4), " (撕裂,5.4,0,true):", WA_CheckDebuff("撕裂", 5.4, 0, true))
    if poweruseable(5) and WA_CheckSpellUsable("撕裂") and D:TimeToLive(4)
            and WA_CheckDebuff("撕裂", 5.4, 0, true) then
        CCFlagSpell("撕裂");
        return;
    end
    if poweruseable(5) and WA_CheckSpellUsableOn("撕裂", "mouseover") and D:TimeToLive(4, "mouseover")
            and WA_CheckDebuff("撕裂", 5.4, 0, true, "mouseover") then
        CCFlagSpell("撕裂M");
        return;
    end

    if not WA_CheckSpellUsable("巨人打击") and timetojr < W.GCDLeftTime then
        return;
    end

    if D.FightHSMode then
        if poweruseable(10) and WA_CheckSpellUsable("顺劈斩") then
            CCFlagSpell("顺劈斩");
            return;
        end
        if poweruseable(25) and WA_CheckSpellUsable("旋风斩") then
            CCFlagSpell("旋风斩");
            return;
        end
    end

    -- 震荡波
    if inZS then return; end

    if D.FightHSMode then return; end

    -- 猛击也不应该一直用
    if poweruseable(15) and WA_CheckSpellUsable("猛击") and (timetozs > 3 or deficit < 20) then
        CCFlagSpell("猛击");
        return;
    end
    -- 震荡波
end

local function useJJ()
    if WA_CheckBuff("怒火聚焦", W.GCDLeftTime + D.MaxDelayS, 3) then
        CCFlagSpell("怒火聚焦");
    end
end

function A:Work(pvp)
    local deficit = UnitPowerMax("player") - UnitPower("player");
    if (GetShapeshiftForm() == 2) then
        jcmessage("确定要防御姿态输出么？？");
    end

    local rushable = W:ShouldRush();

    -- 自动rush的 必须有它充分的条件 手工编纂爆发宏 用于手控爆发！
    if CCAutoRush and not WA_CheckDebuff("巨人打击", 1, 0, true) and rushable then
        W:RushDps();
    end

    CCFlagSpell("petattack");

    --怒火聚焦 TalentID_JJ 1 绝对不推迟致死的使用 2 尽量不影响其他技能的使用
    -- 暂时认为aoe的时候就不用这玩意了。
    if CCFightType == 1 and enabled_jj() then
        local timetozs = WA_CooldownLeft("致死打击", true);
        -- TODO 应该把当前层数也考虑进来
        D:Debug("WA_BuffCount(\"怒火聚焦\")",WA_BuffCount("怒火聚焦"));
        local count = 3-WA_BuffCount("怒火聚焦");
        local nextZS = timetozs-1.5*count < W.GCDLeftTime;
        if nextZS then
            useJJ();
        elseif deficit < 20 then
            useJJ();
        end
    end

    if W.GCDLeftTime > D.MaxDelayS then
        return;
    end
    --猛击流的打法 在于巨人打击期间大肆倾泻怒气

    if W:Chengsheng(0.7) then
        return;
    end
    if CCFightType == 1 then
        return single();
    else
        return aoe();
    end
end

function A:DynamicShapeshiftForm()
    return false;
end

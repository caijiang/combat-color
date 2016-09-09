-- CCHunterBM.lua

local addonName, TT = ...;
local OvaleSpellBook = TT.OvaleSpellBook;
local OvaleState = TT.OvaleState;
local D = TT.jcc;

local _, clzz = UnitClass("player");
if clzz ~= "HUNTER" then return; end

local Q = D.HUNTER;

local F = Q:NewModule("HUNTER1", "AceEvent-3.0", "AceHook-3.0", "CCTalent-1.0");

function F:OnEnable()
    Q.testGCDSpell="眼镜蛇射击";
end

F.TalentSpellDescs = {
    ["凶猛狂暴"] = { slot = 11, havecd = true },
    ["奇美拉射击"] = { slot = 11, havecd = true },
    --12
    ["胁迫"] = { slot = 13, havecd = true },
    ["翼龙钉刺"] = { slot = 13, havecd = true },
    ["束缚射击"] = { slot = 13, havecd = true },
    ["夺命黑鸦"] = { slot = 14, havecd = true },
    ["弹幕射击"] = { slot = 14, havecd = true },
    ["乱射"] = { slot = 14, havecd = true },
    ["群兽奔腾"] = { slot = 15, havecd = true },
    --    开始专精技能
    ["多重射击"] = 16,
    ["反制射击"] = { slot = 17, havecd = true },
    ["反制射击M"] = { slot = 18, havecd = true, marco = "/cast [@mouseover,harm,nodead]反制射击" },
    ["狂野怒火"] = { slot = 19, havecd = true },
    ["杀戮命令"] = { slot = 20, havecd = true, marco = "/cast [@pettarget,harm,nodead][@target,harm,nodead]%s" },
    ["误导"] = { slot = 21, havecd = true, marco = "/cast [@focus,help,nodead][@target,help,nodead][@pet,help,nodead]%s" }, --[@targettarget,help,nodead] 在检测目标是否可误导之前暂时取消
    ["误导2"] = { slot = 22, havecd = true, marco = "/cast [@focus,help,nodead][@target,help,nodead][@pet,help,nodead]误导" },
    ["凶暴野兽"] = { slot = 23, havecd = true },
    ["眼镜蛇射击"] = 24,
    ["震荡射击"] = { slot = 25, havecd = true },
};

F.lastCommand = 0;

function F:Work(pvp)

    local state = OvaleState.state;
    local targetpct = UnitHealth("target") / UnitHealthMax("target")
    local power = UnitPower("player");
    local petpowerqk = UnitPowerMax("pet") - UnitPower("pet");
    local powerqk = UnitPowerMax("player") - UnitPower("player");
    local slleft = WA_CooldownLeft("杀戮命令", 1);
    local kyleft = WA_CooldownLeft("狂野怒火", 1);
    local ascost = 40;
    local slcost = 30;
    local _, _, _, dutiaoms, _, _ = GetSpellInfo("眼镜蛇射击");
    local fillSpell = "眼镜蛇射击";
    if not dutiaoms then
        _, _, _, dutiaoms, _, _ = GetSpellInfo("稳固射击");
        fillSpell = "稳固射击";
    end

    if CCShareHoly.isHelp("pet") and not CCShareHoly.isHarm("pettarget") then
        CCFlagSpell("petattack");
    end

    if Q.GCDLeftTime > D.MaxDelayS then
        return;
    end

    -- 之后的rush 是否都要在集中火力的前提下呢？
    --D:IsSXing() or not WA_CheckBuff("集中火力")  and
    local rushable = F:InRush();

    if CCAutoRush and rushable then
        CCWA_RacePink();
    elseif CCAutoRush and Q:RushPrepose() then
        CCWA_RacePink(false, checktouseitem);
    end

    Q:Rush(rushable);

    if WA_CheckSpellUsable("群兽奔腾") and ((WA_Is_Boss() and D:TimeToDie(25))
            or (not WA_CheckBuff("嗜血")
            and (CCAutoRush or not WA_CheckBuff("猎人的橙戒BUF")))) then
        CCFlagSpell("群兽奔腾");
        return;
    end

    -- #dire_beast,if=cooldown.bestial_wrath.remains>2
    -- #dire_frenzy,if=cooldown.bestial_wrath.remains>2
    local enableBest = kyleft>2 or not CCAutoRush;
    if enableBest and WA_CheckSpellUsable("凶暴野兽") then
        CCFlagSpell("凶暴野兽");
        return;
    end
    if enableBest and WA_CheckSpellUsable("凶猛狂暴") then
        CCFlagSpell("凶猛狂暴");
        return;
    end

--    #titans_thunder,if=buff.dire_beast.remains>6 泰坦之雷

    -- 优先多重射击如果buf不足了
    if CCFightType == 2 and WA_CheckSpellUsable("多重射击") and WA_CheckBuff("野兽顺劈斩", 0.5, 0, false, "pet") then
        CCFlagSpell("多重射击");
        return;
    end

    if CCAutoRush and WA_CheckSpellUsable("狂野怒火") and WA_CheckBuff("狂野怒火") and power > 30 then
        CCFlagSpell("狂野怒火");
        return;
    end

    if CCShareHoly.isHelp("pet") then
        local tgt = "target";
        if CCShareHoly.isHarm("pettarget") then
            tgt = "pettarget";
        end
        -- and (GetTime()-F.lastCommand<D.MaxDelayS or GetTime()-F.lastCommand>5)
        if WA_CheckSpellUsableOn("杀戮命令", tgt) then
            F.lastCommand = GetTime();
            CCFlagSpell("杀戮命令");
            return;
        end
    end

    F.lastCommand = 0;

    if not CC_Raid_ShouldDMGWithoutKO() and WA_CheckSpellUsable("夺命黑鸦") then
        CCFlagSpell("夺命黑鸦");
        return;
    end

    if WA_CheckSpellUsable("奇美拉射击") then
        CCFlagSpell("奇美拉射击");
        return;
    end

    if WA_CheckSpellUsable("弹幕射击") and D:hasEnemies(2) then
        CCFlagSpell("弹幕射击");
        return;
    end

    --爆炸陷阱
    if CCFightType == 2 and WA_CheckSpellUsable("多重射击") then
        CCFlagSpell("多重射击");
        return;
    end

    CCFlagSpell("眼镜蛇射击");
end

--高伤害状态
--这里做一个以后都用固定的示范
--高伤害状态的最终判定应该是天赋实现的
--而它本身拥有几个输入值 1 环境高伤害D:IsDamageIncrement()  2 公共高伤害 比如敏捷系sp触发
--CCTalnet 应该定义 一个 简单的高伤害判断方法 而这个方法将调用实现的方法
--比如 我们在执行的时候 只应该调用 F:InRush    实现了一个方法 不如F:InRushCondition(env,sx,common)  默认实现为env or common

function F:InRush()
    --这些是零零碎碎的 如果都触发 那么也算
    return self:RushConditon(D:IsDamageIncrement(), D:IsSXing(), Q:RushPrepose());
end

function F:RushConditon(env, sx, common)
    --这些是零零碎碎的 如果都触发 那么也算
    return env or sx or common or (not WA_CheckBuff("狂野怒火"));
end

-- CCLibClass.lua

--[[


技能说明 core将根据技能说明 部署Buttons已经Bindgs
规范如下
SpellDescs =  <<name>:<desc>>
name =        技能名称
desc =        slotid热键序列
desc =        slot:<slotid>,[havecd:boolean,][marco:string,][customerMarcoName:string,]
marco 表示执行的宏文本
customerMarcoName 表示如果存在以该名字命名的宏 则使用这个宏
table SpellDescs()


一个职业的基本特性
breakingSpell
testRangeHitSpell
ClassSpellDescs
方法
AllowWork 返回true 表示要继续运行
]]

local addonName, T = ...;
local D = T.jcc;

local MAJOR, MINOR = "CCClass-1.0", 1

local CCClass, oldminor = LibStub:NewLibrary(MAJOR, MINOR)

if not CCClass then return end -- No upgrade needed

CCClass.embeds = CCClass.embeds or {} -- table containing objects AceConsole is embedded in.


function CCClass:BreakingSpell()
    return self.breakingSpell;
end

function CCClass:TestRangeHitSpell()
    return self.testRangeHitSpell;
end

function CCClass:Match()
    local ttype = GetSpecialization();
    return self.TalentType == ttype;
end

function CCClass:SpellDescs()
    return self.MySpellDescs;
end

function CCClass:CombatLogEventUn(...)
    if self.Talent and self.Talent.CombatLogEventUn then
        self.Talent:CombatLogEventUn(...);
    end
end

function CCClass:PLAYER_REGEN_DISABLED()
    if self.Talent and self.Talent.PLAYER_REGEN_DISABLED then
        self.Talent:PLAYER_REGEN_DISABLED();
    end
end

function CCClass:PLAYER_REGEN_ENABLED()
    if self.Talent and self.Talent.PLAYER_REGEN_ENABLED then
        self.Talent:PLAYER_REGEN_ENABLED();
    end
end

-- 检测是否可以打断目标技能
-- 0 无需打断 1 表示要打断 2 留着打断 不过不急
function CCClass:AbleToBreakCasting(unit)
    unit = unit or "target";
    if not WA_NeedAttack() then return 0; end
    if UnitName(unit) == "苟拉斯之眼" then
        return 1;
    end
    local spell, _, _, _, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo(unit);
    if not spell then
        spell, _, _, _, startTime, endTime, isTradeSkill, notInterruptible = UnitChannelInfo(unit);
    end
    if ((not spell) or notInterruptible) then
        return 0;
    end
    return 1;
end

-- 打断他！ 可覆盖
function CCClass:DoBreakCasting(unit)
    unit = unit or "target";
    local spellName = self:BreakingSpell();
    if not spellName then return false; end
    if WA_CheckSpellUsableOn(spellName, unit) then
        if unit == "target" then
            CCFlagSpell(spellName);
        elseif unit == "mouseover" then
            CCFlagSpell(spellName .. "M");
        end
        return true;
    end
    return false;
end

function CCClass:matchGCD2(time)
    if not self.testGCDSpell then
        return self:matchGCD(time);
    end
    --D:Error(self.testGCDSpell);
    local _, duration = GetSpellCooldown(self.testGCDSpell);
    --D:Error("gcd2:",time,duration);
    return time == duration;
end

local function checkAutoBreak(unitid)
    if D.CCNoAutoBreak then
        return;
    end
    local spell, _, _, _, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo(unitid);
    if not spell then
        spell, _, _, _, startTime, endTime, isTradeSkill, notInterruptible = UnitChannelInfo(unitid);
    end
    if ((not spell) or notInterruptible) then
        -- D:Error("无可打断技能1");
        return;
    end

    if UnitInRaid(unitid) and (not WA_CheckBuff("膜拜", 0, 0, nil, unitid)) then
        CC_Try_Breakcasting(unitid);
        return;
    end

    local timeToFinish = endTime - GetTime() * 1000;
    local timeStarted = GetTime() * 1000 - startTime;

    if (spell ~= "释放畸变怪" and UnitName(unitid) ~= "塔隆戈尔")
            and (timeStarted > 150 or (timeStarted > 100 and math.random(4) == 1)) and (D.activeModule and D.activeModule.isAutoBreak and D.activeModule:isAutoBreak()) then
        -- D:Error("打断",unitid);
        CC_Try_Breakcasting(unitid);
        return;
    end
    if (spell) then
        if (spell == "冲击新星" or spell == "硬化外皮" or spell == "暗影新星" or spell == "烈火喷涌") then
            if (timeToFinish < D.MaxDelayMS) then
                CC_Try_Breakcasting(unitid);
            end
        end
    end
end

function CCClass:Work(...)
    --D:Debug("Start All Class Work",self);
    local sttime = GetTime();
    CombatColorRestAllFlag();
    D:InitializeState();
    D:UpdatePosition();
    D:WorkUpdate();
    if not self.TalentType then return end -- < 10 level

    if D.LastCMD and GetTime() - D.LastCMDTime < 0.5 then
        CCFlagSpell(D.LastCMD);
    end

    if self.testGCDSpell then
        local _s, _d = GetSpellCooldown(self.testGCDSpell);
        self.GCDEndTime = _s + _d;
        if self.GCDEndTime == 0 then
            self.GCDLeftTime = 0;
        else
            self.GCDLeftTime = self.GCDEndTime - GetTime();
            self.GCDTime = _d;
        end
    end

    local spell, _, _, _, startTime, endTime = UnitCastingInfo("player");
    local Channeling = false;
    if not spell then
        spell, _, _, _, startTime, endTime = UnitChannelInfo("player");
        Channeling = true;
    end
    --	D:Debug("spell:",spell," ,startTime",startTime);
    if (spell) then
        local finish = endTime / 1000 - GetTime();
        D.Casting.ttf = finish;
        if D.Casting.startTime ~= startTime / 1000 then
            D.Casting.name = spell;
            D.Casting.startTime = startTime / 1000;
            D.Casting.endTime = endTime / 1000;
            D.Casting.channeling = Channeling;
        end

        local totalTime = D.Casting.endTime - D.Casting.startTime;

        D.Casting.process = (totalTime - D.Casting.ttf) / totalTime;
    else
        D:ResetCasting();
    end

    --D:Debug("Start All Class Work 2",self);

    if not HasFullControl() then return end

    --D:Debug("Start All Class Work 3",self);

    -- 检查是否需要自动打断
    checkAutoBreak("target");
    checkAutoBreak("mouseover");

    if D.TryBreaking then
        -- 优先检查当前目标 如果当前目标无需打断 则检查mouseover
        local bstate = self:AbleToBreakCasting();
        local bstate2 = self:AbleToBreakCasting("mouseover");
        if bstate == 1 then
            if not self:DoBreakCasting() then D.TryBreaking = false; end
        elseif bstate2 == 1 then
            if not self:DoBreakCasting("mouseover") then D.TryBreaking = false; end
        elseif bstate == 0 and bstate2 == 0 then
            D:Debug("不需要打断");
            D.TryBreaking = false;
        end
    end

    --震耳尖啸 143343
    --这里设置对敌对目标施法的自然防御
    if CCShareHoly.isHarm("target") then
        local spell, _, _, _, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo("target");
        Channeling = false;
        if not spell then
            spell, _, _, _, startTime, endTime, isTradeSkill, notInterruptible = UnitChannelInfo("target");
            Channeling = true;
        end
        if (spell) then
            local finish = endTime / 1000 - GetTime();
            D.TargetCasting.ttf = finish;
            if D.TargetCasting.startTime ~= startTime / 1000 then
                D.TargetCasting.name = spell;
                D.TargetCasting.startTime = startTime / 1000;
                D.TargetCasting.endTime = endTime / 1000;
                D.TargetCasting.channeling = Channeling;
                D.TargetCasting.willbreakplayer = castID == 143343 or spell == "震耳尖啸";
                D:Debug("spell:", spell, " castID:", castID, " F:", D.TargetCasting.willbreakplayer);
                if D.TargetCasting.willbreakplayer then
                    --D:Error("spell:",spell," castID:",castID, " F:",D.TargetCasting.willbreakplayer);
                end
            end

            local totalTime = D.TargetCasting.endTime - D.TargetCasting.startTime;

            D.TargetCasting.process = (totalTime - D.TargetCasting.ttf) / totalTime;
        else
            D:ResetTargetCasting()
        end
    else
        D:ResetTargetCasting();
    end
    --[[
        D.TargetCasting.name = "模拟要打断你的技能";
        D.TargetCasting.willbreakplayer = true;
        D.TargetCasting.ttf = 1.5;
        ]]
    if D.Casting.name ~= nil and D.TargetCasting.name ~= nil then
        --
        if D.Casting.ttf > D.TargetCasting.ttf and D.TargetCasting.ttf < D.MaxDelayS and not D:AbleToCast(D.Casting.name, true) then
            CCFlagSpell("打断");
        end
    end



    self.ToRush = CCAutoRush and self:RushPrepose();

    local towork, v1, v2, v3, v4, v5 = self:AllowWork(...);
    if towork then
        self.Talent:Work(v1, v2, v3, v4, v5);
    end
    --[[if self:AllowWork(...) then
        self.Talent:Work(...);
    end]]
    if D.debug then
        local ct = GetTime() - sttime;
        if ct > 0 then
            D:Debug("耗时", GetTime(), sttime, ct);
        end
    end
end

-- 是否应该Rush
-- 天赋 或者 职业 需要实现
-- RushConditon(环境易伤env,开启了sx,自身主属性强化ps)
function CCClass:ShouldRush()
    local env = D:IsDamageIncrement();
    local sx = D:IsSXing();
    local ps = self:RushPrepose();
    if self.Talent.RushConditon then
        return self.Talent:RushConditon(env, sx, ps);
    end

    if self.RushConditon then
        return self:RushConditon(env, sx, ps);
    end

    return env or sx or ps;
end



--- embedding and embed handling

local mixins = {
    "AbleToBreakCasting",
    "DoBreakCasting",
    "BreakingSpell",
    "TestRangeHitSpell",
    "SpellDescs",
    "Match",
    "Work",
    "CombatLogEventUn",
    "PLAYER_REGEN_ENABLED",
    "PLAYER_REGEN_DISABLED",
    "matchGCD2",
    "ShouldRush",
}

-- Embeds CCClass into the target object making the functions from the mixins list available on target:..
-- @param target target object to embed AceBucket in
function CCClass:Embed(target)
    for k, v in pairs(mixins) do
        target[v] = self[v]
    end
    self.embeds[target] = true
    return target
end

function CCClass:OnEmbedEnable(target)
    print("Loaded " .. target:GetName() .. " Module");
    local ttype = GetSpecialization();
    target.TalentType = ttype;
    if not target.TalentType then return end; -- < 10 level
    target.Talent = target:GetModule(target:GetName() .. ttype, 1);
    if not target.Talent then
        D:Error("Talent Load Failed!");
        return;
    end
    target.Talent:Enable();
    target.MySpellDescs = {};
    D:tcopy(target.MySpellDescs, target.Talent:SpellDescs(), target.ClassSpellDescs);
    -- 附加数据 比如rush开关 是否为治疗 是否为T,DPS
    target.RushPrepose = D:FetchRushPrepose(target);
    target.isT = D:isT(target);
    target.isDPS = D:isDPS(target);
    target.isN = D:isN(target);
end

function CCClass:OnEmbedDisable(target)
    print("Unload " .. target:GetName() .. " Module");
    target.MySpellDescs = nil;
    if target.Talent then
        target.Talent:Disable();
    end
    target.TalentType = nil;
end

for addon in pairs(CCClass.embeds) do
    CCClass:Embed(addon)
end

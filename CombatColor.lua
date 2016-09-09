-- extracd retabbinder raidach sexymap
-- 无法载入文件的任何信息 可能是因为 该文件 有严重的语法错误！
-- /console taintLog 1

local addonName, T = ...;
local D = T.jcc or {};
local logedin2s = 0;
--  local D = jCombatColorRootTable.jcc;D:CancelAllTimers();for i=1,D.numbers_of_buttons do D.CombatColorFlagStrings[i]:SetText(";");end
--  打火球 刷碎片的学

local ShapeshiftFormIndex = {
    ["战斗"] = 1,
    ["防御"] = 2,
    ["狂暴"] = 3,
};

function D:OnInitialize()
    -- do init tasks here, like loading the Saved Variables,
    -- or setting up slash commands.
end

local function CombatColorFlagSetTo(index, state)
    if state then
        D.CombatColorFlagStrings[index]:SetColorTexture(1, 0, 0);
    else
        D.CombatColorFlagStrings[index]:SetColorTexture(0, 1, 0);
    end
end

function D:OnEnable()
    -- Do more initialization here, that really enables the use of your addon.
    -- Register Events, Hook functions, Create Frames, Get information from
    -- the game that wasn't available in OnInitialize
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("UNIT_SPELLCAST_START")
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    self:RegisterEvent("UNIT_AURA");
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
    self:RegisterEvent("GLYPH_ADDED")
    self:RegisterEvent("CHARACTER_POINTS_CHANGED")
    self:RegisterEvent("CHAT_MSG_WHISPER")

    --this:RegisterEvent("COMBAT_TEXT_UPDATE")

    D.CombatColorFlagStrings = {};
    for i = 1, D.numbers_of_buttons do
        local f = CreateFrame("Frame", nil, CombatColorParentFrame);
        -- TOPLEFT
        f:SetPoint("TOPLEFT", CombatColorParentFrame, i - 1, 0);
        f:SetSize(1, 1);
        if not f:IsShown() then f:Show(); end

        local mytt = f:CreateTexture(nil, "OVERLAY");
        mytt:SetAllPoints();
        -- mytt:SetSize(1,10);
        -- mytt:SetColorTexture(9,9,9);
        if not mytt:IsShown() then mytt:Show() end
        D.CombatColorFlagStrings[i] = mytt;
        -- D.CombatColorFlagStrings[i] = f:CreateTexture(nil,"OVERLAY");
        -- D.CombatColorFlagStrings[i]:SetAllPoints();
        -- D.CombatColorFlagStrings[i]:SetTexture(1,0,0);
        -- if not D.CombatColorFlagStrings[i]:IsShown() then D.CombatColorFlagStrings[i]:Show() end
        -- D:Error("flag","f.x",f:GetPoint(),D.CombatColorFlagStrings[i],D.CombatColorFlagStrings[i]:IsShown());
    end

    for i = 1, D.numbers_of_buttons do
        CombatColorFlagSetTo(i, true);
    end

    D.inited = true;
    D:selectWorkFunction();

    --[[if Bagnon and Bagnon['SearchFrame'] then
        self:RawHook(Bagnon['SearchFrame'],"TEXT_SEARCH_UPDATE",function()end);
        print("Bagnon Changed");
    end]]
    D:RegisterChatCommand("wpt", "Wapretocast");
end

function D:Wapretocast(msg)
    --PreToCast
    if not msg or type(msg) ~= 'string' or msg == "" then
        PreToCast = nil;
    else
        PreToCast = msg;
    end
end

function D:OnDisable()
    self:UnhookAll();
    D:UnregisterChatCommand("wpt");
end

function D:PLAYER_REGEN_ENABLED()
    CCMantSpell = nil;
    InCombat = false;
    PreToCast = nil;
    CCAutoRush = false;
    D.FightHSMode = false;
    if D.activeModule and D.activeModule.PLAYER_REGEN_ENABLED then
        D.activeModule:PLAYER_REGEN_ENABLED();
    end
end

function D:PLAYER_REGEN_DISABLED()
    InCombat = true;
    if D.activeModule and D.activeModule.PLAYER_REGEN_DISABLED then
        D.activeModule:PLAYER_REGEN_DISABLED();
    end
end

function D:GROUP_ROSTER_UPDATE()
    cc_PARTY_MEMBERS_CHANGED();
end

function D:PLAYER_ENTERING_WORLD()
    cc_PARTY_MEMBERS_CHANGED();
    D:selectWorkFunction();
end


function D:TryScheduleselectWorkFunctionForce()
    if D.TryScheduleselectWorkFunctionForceTimer then
        if D:TimeLeft(D.TryScheduleselectWorkFunctionForceTimer) > 0 then return end
    end
    D.TryScheduleselectWorkFunctionForceTimer = D:ScheduleTimer(D.selectWorkFunctionForce, 1);
end

function D:GLYPH_ADDED()
    D:Debug("GLYPH_ADDED");
    D:TryScheduleselectWorkFunctionForce()
end

function D:CHARACTER_POINTS_CHANGED()
    D:Debug("CHARACTER_POINTS_CHANGED");
    D:TryScheduleselectWorkFunctionForce()
end

function D:ACTIVE_TALENT_GROUP_CHANGED()
    D:Debug("ACTIVE_TALENT_GROUP_CHANGED");
    D:TryScheduleselectWorkFunctionForce()
end

function CC_Try_Chaofeng()
    local _, clzz = UnitClass("player");
    if (clzz == "WARRIOR") then
        return Try_Cast_AI("嘲讽") == 1;
    end
    return false;
end

local SpellToStopCast = {
    ["WARRIOR"] = "拳击",
    ["PALADIN"] = "责难",
};

function CC_Try_Breakcasting(unit)
    -- D.TryBreaking = true;
    unit = unit or "target";
    return D.activeModule and D.activeModule:DoBreakCasting(unit);
    --[[local _,clzz = UnitClass("player");
    local tocast = SpellToStopCast[clzz];
    if(not tocast)then
        return;--没有打断技能
    end
    if(WA_CheckSpellUsable(tocast))then
        CCFlagSpell(tocast);
        return true;
    end
    return false;]]
end

local cc_startdebug = false;

function CC_Toggle_Debug()
    cc_startdebug = not cc_startdebug;
    if (cc_startdebug) then
        jcmessage("开始调试");
    else
        jcmessage("停止调试");
    end
end

local CCFlagSpellTimes = 0;

function CCFlagSpell(s, direct)
    if (not D.UsingSpellNameSlots[s]) then
        D:Error("没有定位这个技能", s);
        return;
    end
    D:Debug("准备使用:", s);
    CombatColorFlagSetTo(D.UsingSpellNameSlots[s], true);
    if direct then return end
    CCFlagSpellTimes = CCFlagSpellTimes + 1;
    if (CCFlagSpellTimes > 10) then
        CCFlagSpellTimes = 0;
    end
end

D.numbers_of_buttons = 50;

function CCStop()
    D:CancelAllTimers(); for i = 1, D.numbers_of_buttons do CombatColorFlagSetTo(i, true); end
end

function CombatColorRestAllFlag()
    for i = 1, D.numbers_of_buttons do
        CombatColorFlagSetTo(i, false);
    end
    WR_DY_ST = false;
    WR_DY_ST_Planning = nil;
end

function jcmessage(str)
    --DEFAULT_CHAT_FRAME
    --UIErrorsFrame
    CombatColorMessageFrame:AddMessage(str, 0.8, 0.3, 0.3, 1, 5)
end

-- AttackTimer 计算
function CC_AttackTimerCheck(fn)
    if (AttackTimerBar and AttackTimerBar.start and AttackTimerBar.stop) then
        local retOk, retDone = pcall(fn);
        return retDone;
    end
    return true;
end

-- 根据输入的bool 进行优先判断
-- 如果boolValue 优先调用fn1
-- 反之优先调用fn2
function CC_PriorityCall(boolValue, fn1, fn2)
    if (boolValue) then
        local retOk, retDone = pcall(fn1);
        if (retOk and retDone) then
            return true;
        end;
        retOk, retDone = pcall(fn2);
        if (retOk and retDone) then
            return true;
        end;
    else
        local retOk, retDone = pcall(fn2);
        if (retOk and retDone) then
            return true;
        end;
        retOk, retDone = pcall(fn1);
        if (retOk and retDone) then
            return true;
        end;
    end
    return false;
end

function WA_Changshi_Kuangbao()
    if (WR_DY_ST_Able(3)) then
        WR_DY_ST_Planning = 3;
    end
end

function WA_Changshi_Fangyu()
    if (WR_DY_ST_Able(2)) then
        WR_DY_ST_Planning = 2;
    end
end

function WR_DY_ST_check(sk, st, pw, checkFun, nocooldowncheck)
    --技能还未冷却 那就算了
    if (GetShapeshiftForm() == st) then
        --if(GetTime()-logedin2s<2)then
        --	print(format("%d:姿态已切换 无需继续",GetTime()));
        --end
        return false;
    end
    if (not nocooldowncheck) then
        if (D.UsingSpellCooldowns[sk]) then
            if (WA_CooldownLeft(sk) > 0) then
                return false;
            end
        end
    end
    if (UnitPower("player") < pw) then
        return false;
    end
    --checkFun todo
    if (not WR_DY_ST_Able(st)) then
        return false;
    end
    WR_DY_ST_Planning = st;
    CCFlagSpell(sk);
    return true;
end

-- 1 战斗姿态  2 防御姿态 3狂怒姿态
function WR_DY_ST_Able(st)
    if (WR_DY_ST_Planning ~= nil) then
        return WR_DY_ST_Planning == st;
    end
    --如果要切战斗姿态 必须没有鲁莽
    if (st == 1 and (not WA_CheckBuff("鲁莽")) and UnitPower("player") > 75) then
        return false;
    end
    return WR_DY_ST and UnitPower("player") <= 85;
end


WR_DY_ST = false;
WR_DY_ST_Planning = nil;
--最后时间记录器
CC_Time_Ables = {};
--是否在战斗
InCombat = false;
--- 1普通 2群体
CCFightType = 1;
--是否允许惩戒痛击 其实也就是在非副本的条件下都是可以用的
CJTJApprolved = false;
CCPullApprolved = true;
CCAutoRush = false;
GougeBlocks = {};
CC_Bosses = {};
-- 输出时上破甲
DPS_Pojia_Enable = false;
--预备施展技能，必须是有冷却时间的3
PreToCast = nil;
--定义公共延迟
CC_Global_Delay = 0.5;
--仇恨模式
CC_WA_CH = false;
BossOnly = true;

function WA_PreToCast(nm)
    PreToCast = nm;
end

function WA_ToogleCC_WA_CH()
    CC_WA_CH = not CC_WA_CH;
    if (CC_WA_CH) then
        jcmessage("进入'稳定仇恨'模式");
    else
        jcmessage("离开'稳定仇恨'模式");
    end
end

function WA_ToogleCCRush()
    CCAutoRush = not CCAutoRush;
    if (CCAutoRush) then
        jcmessage("允许自动Rush");
    else
        jcmessage("禁止自动Rush");
    end
end

function CC_WA_TooglePojia()
    DPS_Pojia_Enable = not DPS_Pojia_Enable;
    if (DPS_Pojia_Enable) then
        jcmessage("负责上破甲");
    else
        jcmessage("无需上破甲");
    end
end

function WA_ToogleCCPull()
    CCPullApprolved = not CCPullApprolved;
    if (CCPullApprolved) then
        jcmessage("允许强制拉怪");
    else
        jcmessage("禁止强制拉怪");
    end
end

function WA_ToogleCJTJ()
    CJTJApprolved = not CJTJApprolved;
    if (CJTJApprolved) then
        jcmessage("允许使用惩戒痛击Solo");
    else
        jcmessage("禁止使用惩戒痛击Solo");
    end
end

function WA_Is_BossOrPlayer()
    return WA_Is_Boss() or UnitIsPlayer("target");
end

function WA_Is_Boss()
    local uname = UnitName("target");
    if (not uname) then return false end
    if (tContains(CC_Bosses, uname)) then
        return true;
    end
    return UnitClassification("target") == "worldboss";
    --or UnitClassification("target") == "elite"
end

function WA_Add_Boss()
    local uname = UnitName("target");
    if (not uname) then return end
    if (tContains(CC_Bosses, uname)) then
        jcmessage("已在Boss名单");
    else
        tinsert(CC_Bosses, uname)
        jcmessage("已添加至Boss名单");
    end
    --table.foreach(CC_Bosses,print);
end

function WA_JoinGouge()
    local uname = UnitName("target");
    if (not uname) then return end
    if (tContains(GougeBlocks, uname)) then
        jcmessage("已在防止撕裂名单");
    else
        tinsert(GougeBlocks, uname)
        jcmessage("已添加至防止撕裂名单");
    end
    --table.foreach(GougeBlocks,print);
end


--切换防御类型
function CCWA_Toggle_Tank_Type()
    if (CCFightType == 1) then
        CCFightType = 2;
        jcmessage("类型切换为群体模式");
    else
        CCFightType = 1;
        jcmessage("类型切换为普通模式");
    end
end

D.FightHSMode = false;

function CC_AR_HS()
    D.FightHSMode = not D.FightHSMode;
    if D.FightHSMode then
        jcmessage("启用横扫模式");
    else
        jcmessage("禁用横扫模式");
    end
end


qianghuadjtimesnap = 0;

local checkcdevents = {
    ["SPELL_DAMAGE"] = true,
    ["SPELL_PERIODIC_HEAL"] = true,
    ["SPELL_HEAL"] = true,
    ["SPELL_AURA_APPLIED"] = true,
    ["SPELL_ENERGIZE"] = true,
    ["SPELL_CAST_SUCCESS"] = true,
    ["SPELL_CAST_START"] = true, -- for early frost
}
function D:COMBAT_LOG_EVENT_UNFILTERED(...)
    local _, timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing = select(1, ...)
    if D.activeModule and D.activeModule.CombatLogEventUn then
        D.activeModule:CombatLogEventUn(timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing);
    end
    if (sourceGUID == UnitGUID("player") and checkcdevents[event]) then
        if (spellID == 23694) then
            local _, icon, _, _, rank = GetTalentInfo(1, 11);
            qianghuadjtimesnap = GetTime() + 90 - 30 * rank;
        end
    end
    if event == "UNIT_DIED" or event == "UNIT_DESTROYED" or event == "PARTY_KILL" then
        D:UnitOffline(destGUID);
    end
    --amount, overkill
    if event == "SPELL_AURA_APPLIED" then
        D:SPELL_AURA_APPLIED(timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName, spellSchool, amount, overkill);
    end
    if event == "SPELL_AURA_REMOVED" then
        D:SPELL_AURA_REMOVED(timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName, spellSchool, amount, overkill);
    end
end

--timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName, spellSchool, auraType, amount
function D:SPELL_AURA_APPLIED(...)
    --D:Error("aura增加 playeruu:",UnitGUID("player")," targetuu:",UnitGUID("target")," source:",sourceGUID," dest:",destGUID," spellId:",spellId," auraType:",auraType," amount:",amount);
    if D.activeModule and D.activeModule.SPELL_AURA_APPLIED then
        D.activeModule:SPELL_AURA_APPLIED(...);
    end
end

function D:SPELL_AURA_REMOVED(...)
    --D:Error("aura移除 playeruu:",UnitGUID("player")," source:",sourceGUID," dest:",destGUID," spellId:",spellId," auraType:",auraType," amount:",amount);
    if D.activeModule and D.activeModule.SPELL_AURA_REMOVED then
        D.activeModule:SPELL_AURA_REMOVED(...);
    end
end

--sourceGUID,destGUID
function D:UnitOffline(GUID)
    --D:Error("物件消失: source:",sourceGUID," dest:",destGUID," playeruu:",UnitGUID("player"));
    D:RemoveDPSInfo(GUID);
    if D.activeModule and D.activeModule.UnitOffline then
        D.activeModule:UnitOffline(GUID);
    end
end

function D:UNIT_AURA(event, unit)
    if D.activeModule and D.activeModule.AuraUpdate then
        D.activeModule:AuraUpdate(unit);
    end
end

function D:UNIT_SPELLCAST_SUCCEEDED(event, unit, name, rank, counter, sid)
    if (unit == "player" and PreToCast == name) then
        PreToCast = nil;
    end

    if (unit == "player") then
        if name then
            D.LastCastedTime[name] = GetTime();
        end
        if D.activeModule and D.activeModule.SpellCasted then
            D.activeModule:SpellCasted(name);
        end
        if (name == "集结呐喊") then
            SendChatMessage("康芒呗币，我已经使用了 集结呐喊!", "YELL");
        end
        if (name == "铸炼怒火") then
            SendChatMessage("我是一只小红龙小红龙，我有许多小秘密小秘密～", "YELL");
        end
        if (name == "盾墙") then
            SendChatMessage("来咬我啊！我就是那不死的神话！", "YELL");
        end
        if (name == "战斗姿态") then
            --			logedin2s = GetTime();
        end
        if (name == "狂暴姿态") then
            D.lastKuangbaoZitai = GetTime();
        end
        if (name == "压制") then
            D.plantoyz = false;
        end
    end
    --haha..
end

function D:CHAT_MSG_WHISPER(event, msg, player)
    D:Debug("msg rcv:", msg, player, D.supervisor == player, D.supervisor);
    if D.CMDSpellDescs and D.supervisor == player then
        if strsub(msg, 1, 1) == "#" then
            local cmd = strsub(msg, 2);
            if D.CMDSpellDescs[cmd] then
                D.LastCMD = cmd;
                D.LastCMDTime = GetTime();
            end
        end
    end
end

function CC_T_W(msg)
    D:CHAT_MSG_WHISPER(nil, msg, D.supervisor);
end

function D:UNIT_SPELLCAST_START(event, unit, name, rank, counter, sid)
    if (unit == "player" and PreToCast == name) then
        PreToCast = nil;
    end
    --print("CC_UNIT_SPELLCAST_START:"..name.." casting by "..unit);
end

function D:replaceActionButton(func)
    D.ActionButtonIndex = D.ActionButtonIndex + 1;
    local vNewButtonName = ("JccABsContainerSubButton%d"):format(D.ActionButtonIndex);
    if _G[vNewButtonName] then
        pcall(func, _G[vNewButtonName]);
    else
        local vnewButton = CreateFrame("Button", vNewButtonName, JccABsContainer, "JccActionButtonTemplateSecure");
        --[[JccABsContainer:Show();
        vnewButton:SetPoint("BOTTOMLEFT",200+D.ActionButtonIndex*(vnewButton:GetWidth()+5),200);
        D:Debug("Point to BOTTOMLEFT",200+D.ActionButtonIndex*(vnewButton:GetWidth()+5),",",200);]]
        pcall(func, vnewButton);
    end
end

function D:replaceActionButtonByUseMarcoName(mname)
    D:replaceActionButton(function(bt)
        D:Debug(bt);
    end)
    return ("JccABsContainerSubButton%d"):format(D.ActionButtonIndex);
end

function D:replaceActionButtonByUseMarcoText(mtext)
    D:replaceActionButton(function(bt)
        -- set the mouse left-button actions on all modifiers
        bt:SetAttribute("*type1", "macro");
        bt:SetAttribute("*macrotext1", mtext);
    end)
    return ("JccABsContainerSubButton%d"):format(D.ActionButtonIndex);
end

function D:tcheckforval(tab, val)
    local k;
    local v;
    if tab then
        for k, v in pairs(tab) do
            --		D:Error(v,val);
            if v == val then
                return true;
            end
        end
    end
    return false;
end

--种族技能
function D:RaceSpellName()
    if UnitRace("player") == "兽人" then
        return "血性狂怒";
    elseif UnitRace("player") == "巨魔" then
        return "狂暴";
    elseif UnitRace("player") == "血精灵" then
        return "奥术洪流";
    end
end

--种族主动技能可以增强攻击力的
function D:RaceSpellPowerup()
    local sp = D:RaceSpellName();
    return sp == "血性狂怒" or sp == "狂暴";
end

D.defaultSpellSpecs = {
    ["petattack"] = { slot = 45, marco = "/startattack\n/petattack" },
    ["打断"] = { slot = 46, marco = "/stopcasting" },
    [D.RaceSpellName] = { slot = 47, havecd = true },
    ["手套"] = { slot = 48, marco = "/use 10" },
    ["饰品1"] = { slot = 49, marco = "/use 13" },
    ["饰品2"] = { slot = 50, marco = "/use 14" }
};

function CCTest()
    D:StartTest();
end

function D:StartTest()
    if not D.inited then
        D:Debug("not inited yet");
        return;
    end
    wipe(D.defaultSpellSpecs);
    D:selectWorkFunctionCore("TEST");
end

function JCC_fenjie(nm)
    D:StartTrade(nm)
end

function D:StartTrade(tofj)
    if not D.inited then
        D:Debug("not inited yet");
        return;
    end
    D.tradeTOFJ = tofj;
    D:selectWorkFunctionCore("TRADE");
end

function JCC_Reset()
    D:selectWorkFunctionForce()
    D:Error("完成");
end

function D:selectWorkFunctionForce()
    if InCombatLockdown() then
        return;
    end
    if D.activeModule then
        D.activeModule:Disable();
        D.activeModule = nil;
    end
    D:selectWorkFunction();
end

function D:selectWorkFunction()
    if not D.inited then
        D:Debug("not inited yet");
        return;
    end
    local _, clzz = UnitClass("player");
    D:selectWorkFunctionCore(clzz);
end

local function toIndexMatchValue(list, value)
    for k, v in pairs(list) do
        if v == value then
            return k;
        end
    end
end

function D:selectWorkFunctionCore(clzz)
    if not D.inited then
        D:Debug("not inited yet");
        return;
    end
    if D.activeModule and D.activeModule:GetName() == clzz and D.activeModule.Match and D.activeModule:Match() then
        --donothing
    else
        --如果是战斗状态 那么。。请稍等！
        if InCombatLockdown() then
            D:CancelAllTimers();
            jcmessage("战斗中，稍后重载程序");
            CombatColorRestAllFlag();
            D:ScheduleTimer(D.selectWorkFunction, 3, D);
            return;
        end
        if D.activeModule then
            D.activeModule:Disable();
            D.activeModule = nil;
        end
        CombatColorRestAllFlag();
        D:CancelAllTimers();
        local ttype = GetSpecialization();
        if not ttype then return; end
        D.activeModule = D:GetModule(clzz, true);
        if D.activeModule then
            D:Debug("打印self in selectWorkFunction", self);
            D.activeModule:Enable();
            local tmpspelldescs = {};
            local daSpellDescs = D.activeModule:SpellDescs();
            --			print(D.activeModule.Talent);
            if not daSpellDescs then
                print("CombatColor Load Failed!!!!");
                return;
            end
            local tmpdefaultspelldescs = {};
            self.tcopy(self, tmpdefaultspelldescs, D.CMDSpellDescs or {}, D.defaultSpellSpecs);
            self.tcopy(self, tmpspelldescs, daSpellDescs, tmpdefaultspelldescs);
            -- 接下来的工作 包括奖励 spellslot表 cd表 以及根据需要macro的spell建立button
            local tmpSpellNameSlots = {};
            local tmpSpellCooldowns = {};
            local tmpSlots = {};
            D.ActionButtonIndex = 0;
            for k, v in pairs(tmpspelldescs) do
                local tSpellName = k;
                if type(k) == "function" then
                    tSpellName = select(2, pcall(k));
                end
                if tSpellName then
                    local dobind = true;
                    if type(v) == "number" then
                        if tContains(tmpSlots, v) then
                            dobind = false;
                            if GetSpellInfo(tSpellName) then
                                dobind = true;
                            end
                            --[[local oldspellname = toIndexMatchValue(tmpSpellNameSlots,v);
                            if GetSpellInfo(oldspellname) and GetSpellInfo(tSpellName) then
                                D:Error(tSpellName, "使用了和",oldspellname,"一样的的键位",v);
                            elseif not GetSpellInfo(tSpellName) then
                                dobind = false;
                            end]]
                        end
                        if dobind then

                            tinsert(tmpSlots, v);
                            tmpSpellNameSlots[tSpellName] = v;
                            local tkey = D.KeysToSlots[v];
                            SetBinding(tkey);
                            D:Debug("Binding ", tkey, " To ", tSpellName);
                            SetBinding(tkey, ("SPELL %s"):format(tSpellName));
                        end
                    elseif type(v) == "table" then
                        local tslotid = v.slot;
                        if tContains(tmpSlots, tslotid) then
                            dobind = false;
                            if GetSpellInfo(tSpellName) then
                                dobind = true;
                            end
                            --[[local oldspellname = toIndexMatchValue(tmpSpellNameSlots,tslotid);
                            D:Debug(tSpellName,"需要和",oldspellname,"争抢技能位");
                            if GetSpellInfo(oldspellname) and GetSpellInfo(tSpellName) then
                                D:Error(tSpellName, "使用了和",oldspellname,"一样的的键位",tslotid);
                            elseif not GetSpellInfo(tSpellName) then
                                dobind = false;
                            end]]
                        end
                        --if tSpellName=="天神下凡" or tSpellName=="浴血奋战" or tSpellName=="风暴之锤" then
                        --	D:Error(tSpellName,"是否banding:",dobind);
                        --end

                        if dobind then

                            tinsert(tmpSlots, tslotid);
                            tmpSpellNameSlots[tSpellName] = tslotid;
                            if v.havecd then tmpSpellCooldowns[tSpellName] = 1 end;
                            local tmpButtonName, tmpMarcoName;
                            if v.customerMarcoName and GetMacroIndexByName(v.customerMarcoName) > 0 then
                                tmpMarcoName = v.customerMarcoName;
                            elseif v.marco then
                                tmpButtonName = D:replaceActionButtonByUseMarcoText(v.marco:format(tSpellName));
                            end
                            local tkey = D.KeysToSlots[tslotid];
                            SetBinding(tkey);
                            D:Debug("Binding ", tkey, " To ", tSpellName);
                            if v.direct then
                                SetBinding(tkey, v.direct);
                            elseif tmpMarcoName then
                                SetBinding(tkey, ("MACRO %s"):format(tmpMarcoName));
                            elseif tmpButtonName then
                                SetBinding(tkey, ("CLICK %s:LeftButton"):format(tmpButtonName));
                            else
                                SetBinding(tkey, ("SPELL %s"):format(tSpellName));
                            end
                        end
                    end
                end
            end
            SaveBindings(2);
            D.UsingSpellNameSlots = tmpSpellNameSlots;
            D.UsingSpellCooldowns = tmpSpellCooldowns;
            --print("start schedule!");
            D:ScheduleRepeatingTimer(D.activeModule.Work, D.WorkRate, D.activeModule, D.pvp);
            if D.activeModule.Talent and D.activeModule.Talent.onCCLoaded then D.activeModule.Talent:onCCLoaded(); end
            print("CombatColor Loaded!");
        else
            print("No Class Found For " .. clzz);
        end
    end
end

local last_try_time;
-- 更加智能的调用
-- 返回 0 无法调用 停止尝试
-- 1 调用了
-- 2 暂时无法调用 一会儿继续尝试
function Try_Cast_AI(spell)
    local start, duration, enabled = GetSpellCooldown(spell);
    if (enabled == 0) then
        --已经被激活
        return 0;
        --战士的gcd是1.5 lr的是1?
    elseif ((D.activeModule and D.activeModule.matchGCD2 and D.activeModule:matchGCD2(duration))) then
        --elseif(duration==1.5 or duration==1 or duration<1.5)then
        --gcd
        --return true;
    elseif (start == nil or duration == nil) then
        --之前这个技能已不复存在
        return 0;
    elseif (start > 0 and duration > 0) then
        --冷却中
        return 0;
    else
        --return true;
    end

    local usable, nomana = IsUsableSpell(spell);
    if (usable) then
        CCFlagSpell(spell);
        last_try_time = nil;
        return 1;
    end

    local _, rank, _, castTime, minRange, maxRange = GetSpellInfo(spell);
    rank = strtrim(rank);
    --怒气足够 姿态没问题 cd ok 却无法useable的 那么就是。。无法使用！！
    if (strlen(rank) == 0) then
        if (not nomana) then
            if (not last_try_time) then
                last_try_time = GetTime();
                return 2
            elseif (GetTime() - last_try_time > 2) then
                return 0;
            end
        end
        return 2;
    end
    rank, _ = gsub(rank, "姿态", "");
    -- 一般都是 战斗 啊什么姿态 来着 默认取第一个
    --
    local rank1, rank21, rank22, rank23 = strsplit("，", rank);
    if (strfind(rank, "、") ~= nil) then
        rank1, rank21, rank22, rank23 = strsplit("、", rank);
    end
    local rank2 = rank23;
    if (rank21 and strlen(rank21) > 0) then
        rank2 = rank21;
    elseif (rank22 and strlen(rank22) > 0) then
        rank2 = rank22;
    end
    -- 已经在这个姿态了 那也就安逸了 否者切换必然切换第一个
    if (rank2 and strlen(rank2) > 0) then
        local st2 = ShapeshiftFormIndex[rank2];
        if (not st2) then
            print("无法识别的姿态！！" .. rank2);
            return 0;
        end
        if (GetShapeshiftForm() == st2) then
            if (not nomana) then
                if (not last_try_time) then
                    last_try_time = GetTime();
                    return 2
                elseif (GetTime() - last_try_time > 2) then
                    return 0;
                end
            end
            return 2;
        end
    end

    local st = ShapeshiftFormIndex[rank1];
    if (not st) then
        print("无法识别的姿态！！" .. rank1);
        return 0;
    end

    if (GetShapeshiftForm() == st) then
        if (not nomana) then
            if (not last_try_time) then
                last_try_time = GetTime();
                return 2
            elseif (GetTime() - last_try_time > 2) then
                return 0;
            end
        end
        return 2;
    end

    --	print("需要切换姿态到"..rank1);

    if (WR_DY_ST_check(spell, st, 0, nil, 1)) then
        last_try_time = nil;
        return 1;
    end

    return 2;
end

--准备施展预备技能
function CCWA_Check_PreToCasts(pvp)
    if (pvp and SpellIsTargeting()) then return true; end
    if (not PreToCast) then return false; end

    --	if(pvp)then
    if (PreToCast == "缴械" and
            UnitIsDisarmed("target")) then
        return false;
    end
    if (PreToCast == "断筋" and (UnitIsCanntMove("target")
            or UnitIsEnsnared("target")
            or UnitIsIncoma("target"))) then
        return false;
    end

    if (PreToCast == "击倒" and (UnitIsIncoma("target"))) then
        return false;
    end
    --如果自己沉默了。。。那么……
    --	end

    local rs = Try_Cast_AI(PreToCast);
    if (rs == 1) then
        return true;
    elseif (rs == 0) then
        PreToCast = nil;
        return false;
    else
        return false;
    end
end

local function check_user_invslot(ssid, itemChecker)
    local _, d, e = GetInventoryItemCooldown("player", ssid);
    local itemtext = GetInventoryItemTexture("player", ssid);
    D:Debug("d itemtext ", d, e, itemtext);
    if (strfind(itemtext, "PVP") ~= nil) then
        return false;
    end
    local itemid = GetInventoryItemID("player", ssid);
    if (59461 == itemid) then
        --怒炉之怒
        if (WA_CheckBuff("原始狂怒", 0, 5)) then
            return false;
        end
    end
    if (68972 == itemid) then
        --怒炉之怒
        if (WA_CheckBuff("泰坦能量", 0, 5)) then
            return false;
        end
    end
    if (itemChecker) then
        local rstatus, rret = pcall(itemChecker, itemid);
        if (rstatus and (not rret)) then
            return false;
        end
    end
    if (d < 2 and e > 0) then
        if (ssid == INVSLOT_HAND) then
            CCFlagSpell("手套");
            return true;
        elseif (ssid == INVSLOT_TRINKET1) then
            CCFlagSpell("饰品1");
            return true;
        elseif (ssid == INVSLOT_TRINKET2) then
            CCFlagSpell("饰品2");
            return true;
        end
    end
    return false;
end

--- 血性狂怒 兽人种族
function CCWA_RacePink(stonly, itemChecker, ignorerush)
    if (not ignorerush and not CCAutoRush) then
        return false;
    end
    local t1, t2;
    if (not stonly) then
        if (UnitRace("player") == "兽人" and WA_CheckSpellUsable("血性狂怒")) then
            CCFlagSpell("血性狂怒");
        end
        if (UnitRace("player") == "巨魔" and WA_CheckSpellUsable("狂暴")) then
            CCFlagSpell("狂暴");
        end
        if WA_CheckSpellUsable("生命之血") then
            CCFlagSpell("生命之血");
        end
        t1 = check_user_invslot(INVSLOT_TRINKET1, itemChecker);
        t2 = check_user_invslot(INVSLOT_TRINKET2, itemChecker);
    end

    if (not (t1 or t2)) then
        check_user_invslot(INVSLOT_HAND, itemChecker);
    end
end

-- 时间检测函数
-- 时间在xmin,xmax之间的时候不允许运行
function CC_Time_Able(ind, xmin, xmax)
    if (not CC_Time_Ables[ind]) then
        CC_Time_Ables[ind] = GetTime();
        return true;
    end
    local xtime = GetTime() - CC_Time_Ables[ind];
    if (xtime < xmin) then
        return true;
    end
    if (xtime > xmax) then
        CC_Time_Ables[ind] = GetTime();
        return true;
    end
    return false;
end

function TimeToNextAttack()
    return AttackTimerBar.stop - GetTime();
end

function JustAttacked()
    return GetTime() - AttackTimerBar.start < 0.5;
end

--目标在近战范围内
function CC_InRange()
    if D.activeModule and D.activeModule.TestRangeHitSpell then
        local spellname = D.activeModule.TestRangeHitSpell(D.activeModule);
        if not spellname then return false; end
        return IsSpellInRange(spellname, "target") == 1;
    end
    local _, b = UnitClass("player");
    if (b == "HUNTER") then
        return IsSpellInRange("摔绊", "target") == 1;
    end
    return IsSpellInRange("撕裂", "target") == 1;
    --return CheckInteractDistance("target", 3);
end

--返回true如果当前的目标可被攻击
function WA_NeedAttack(unitid)
    unitid = unitid or "target";
    if (IsMounted() and WA_CheckBuff("霜狼战狼")) then
        --如果正在坐骑上 那就不是可攻击的
        return false;
    end
    if (not UnitExists(unitid)) then
        return false;
    end
    if (UnitIsDeadOrGhost(unitid) or UnitIsCorpse(unitid)) then
        return false;
    end
    if (UnitCanAttack("player", unitid)) then
        return true;
    end
    return false;
end

--返回技能冷却时间
--函数返回的冷却时间包括GCD时间
--所有有可能发生这个函数返回的数字大于0
--而WA_CheckSpellUsable却返回true
--单位秒
--TODO 战士gcd=1.5
function WA_CooldownLeft(sn, ignoreuseable)
    if (not GetSpellInfo(sn)) then return 999999 end
    local usable, nomana = IsUsableSpell(sn);
    if ((not ignoreuseable) and (not usable)) then
        return 999999;
    end
    local start, duration, enabled = GetSpellCooldown(sn);
    if (enabled == 0) then
        return 999999;
        --elseif(duration==1.5)then
        --	return 0;
    elseif (start > 0 and duration > 0) then
        return start + duration - GetTime();
    end
    return 0;
end

function WA_CheckSpellUsableOn(sn, unitid)
    unitid = unitid or "target";
    if not WA_CheckSpellUsable(sn) then return false; end
    return IsSpellInRange(sn, unitid) == 1;
end

-- 检测能否使用这个技能
-- 包括冷却检查
-- true如果可以使用
function WA_CheckSpellUsable(sn)
    local usable, nomana = IsUsableSpell(sn);
    if (usable) then
        --是否可用 输入的只有sn  然后跟系统的targetcasting比较
        --另外是 根据获得的spellname 然后系统的targetcasting比较 这里的时间是明确赶不及的 赶得及就轮不到它判断了
        if not D:AbleToCast(sn, false) then
            return false;
        end
        if (not D.UsingSpellCooldowns[sn]) then
            return true;
        end
        local start, duration, enabled = GetSpellCooldown(sn);
        if (enabled == 0) then
            --已经被激活
            print(sn .. "正在施展中");
            return false;
        elseif ((D.activeModule and D.activeModule.matchGCD2 and D.activeModule:matchGCD2(duration))) then
            -- duration==1.5
            --gcd
            return true;
        elseif (start > 0 and duration > 0) then
            --冷却中
            return false;
        else
            return true;
        end
    end
    return false;
end

function __WA_CheckUnitAura__(unitId, s, minTime, minCount, filter, checker, name, rank, iconTexture, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, shouldConsolidate, spellId)
    if (not name) then return true end
    if (not (duration == 0 and expirationTime == 0)) then
        --不是N/A的 N/A的时间就直接掠过判断
        expirationTime = expirationTime - GetTime();
        if (expirationTime < 0) then
            return true, expirationTime;
        end
        if (type(minTime) == "function") then
            local retOk, retDone = pcall(minTime, expirationTime);
            if (retOk and (not retDone)) then
                return true, expirationTime;
            end
        end
        if (type(minTime) == "number" and minTime > 0 and expirationTime < minTime) then
            return true, expirationTime;
        end
        -- 要求-3 28-30 -2>-3 true 20-30 -10<-3 false
        --负数表示已经消耗的时间 函数的表征意是这个debuf/buf有多新 足够新就返回true 新就是逝去的时间少 expirationTime-duration
        if (type(minTime) == "number" and minTime < 0 and expirationTime - duration > minTime) then
            return true, expirationTime;
        end
    end
    if (minCount and count < minCount and count ~= 0) then
        return true, expirationTime;
    end
    return false, expirationTime
end

function __WA_CheckUnitAura(unitId, s, minTime, minCount, filter, checker)
    for i = 1, 40 do
        local name, rank, iconTexture, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, shouldConsolidate, spellId = UnitAura(unitId, i, filter);
        local isThisAura = false;
        if type(s) == 'string' then
            if (not name) then return true end
            isThisAura = name == s;
        else
            if (not spellId) then return true end
            isThisAura = spellId == s;
        end
        --string.find(s,name) and string.find(name,s)
        if isThisAura and (not checker or checker(name, rank, iconTexture, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, shouldConsolidate, spellId)) then
            return __WA_CheckUnitAura__(unitId, s, minTime, minCount, filter, checker, name, rank, iconTexture, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, shouldConsolidate, spellId);
        end
    end
    return true;
end

-- 崭新的检查Debuff函数
-- 简单的描述下函数 这个函数传入了DEBUF的要求条件
-- 比如 名字(如果不传入表示player)
-- 时间(秒，如果为0表示不要求时间)
-- 层数 如果为0表示不要求层数
-- 是否自己施放的(如果不为true表示不要求是否是自己施放的)
-- 如果无法满足这些要求 就返回true
function WA_CheckDebuff(s, minTime, minCount, byPlayer, unitId, checker)
    if (not unitId) then
        unitId = "target";
    end
    if (not byPlayer) then
        return __WA_CheckUnitAura(unitId, s, minTime, minCount, "HARMFUL", checker);
    else
        return __WA_CheckUnitAura(unitId, s, minTime, minCount, "HARMFUL|PLAYER", checker);
    end
end

-- 崭新的检查Buffer函数
-- 简单的描述下函数 这个函数传入了BUF的要求条件
-- 比如 名字(如果不传入表示player)
-- 时间(秒，如果为0表示不要求时间)
-- 层数 如果为0表示不要求层数
-- 是否自己施放的(如果不为true表示不要求是否是自己施放的)
-- 如果无法满足这些要求 就返回true
function WA_CheckBuff(s, minTime, minCount, byPlayer, unitId, checker)
    if (not unitId) then
        unitId = "player";
    end
    if (not byPlayer) then
        return __WA_CheckUnitAura(unitId, s, minTime, minCount, "HELPFUL", checker);
    else
        return __WA_CheckUnitAura(unitId, s, minTime, minCount, "HELPFUL|PLAYER", checker);
    end
end

function __WA_CheckUnitAuraCount(unitId, s, filter, checker)
    for i = 1, 40 do
        local name, rank, iconTexture, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, shouldConsolidate, spellId = UnitAura(unitId, i, filter);
        local isThisAura = false;
        if type(s) == 'string' then
            if (not name) then return 0 end
            isThisAura = name == s;
        else
            if (not spellId) then return 0 end
            isThisAura = spellId == s;
        end
        --string.find(s,name) and string.find(name,s)
        if isThisAura and (not checker or checker(name, rank, iconTexture, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, shouldConsolidate, spellId)) then
            return count or 0;
        end
    end
    return 0;
end

function WA_BuffCount(s, byPlayer, unitId, checker)
    if (not unitId) then
        unitId = "player";
    end
    if (not byPlayer) then
        return __WA_CheckUnitAuraCount(unitId, s,  "HELPFUL", checker);
    else
        return __WA_CheckUnitAuraCount(unitId, s,  "HELPFUL|PLAYER", checker);
    end
end
function WA_DebuffCount(s, byPlayer, unitId, checker)
    if (not unitId) then
        unitId = "target";
    end
    if (not byPlayer) then
        return __WA_CheckUnitAuraCount(unitId, s, "HARMFUL", checker);
    else
        return __WA_CheckUnitAuraCount(unitId, s, "HARMFUL|PLAYER", checker);
    end
end

function CC_Target_Buf_Typed(typename)
    local i = 1;
    while 1 do
        local name, _, _, _, debuffType = UnitBuff("target", i);
        if (not name) then
            break;
        end
        if debuffType and debuffType == typename then
            return true;
        end
        i = i + 1;
    end
    return false;
end

function CC_Target_Buf_Stealable(namechecker)
    local i = 1;
    while 1 do
        local name, _, _, _, _, _, _, _, isStealable = UnitBuff("target", i);
        i = i + 1;
        if (not name) then
            break;
        end
        local notrue = true;
        if namechecker and type(namechecker) == "function" and namechecker(name) then
            notrue = false;
        end
        if (notrue and isStealable) then
            return true;
        end
    end
    return false;
end

function GetItemCooldownByName(itemName)
    local found = nil
    for i = 0, NUM_BAG_SLOTS do
        for j = 1, GetContainerNumSlots(i) do
            local _, _, _, _, _, _, ilink = GetContainerItemInfo(i, j);
            if (ilink and strfind(ilink, itemName)) then
                return GetItemCooldown(GetContainerItemID(i, j));
            end
        end
    end
    return nil;
end

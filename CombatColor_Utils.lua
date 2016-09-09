-- CombatColor_Utils.lua

local addonName, T = ...;
jCombatColorRootTable = T;

T.StartTime = GetTime();

-- local D = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceHook-3.0");
local D = T:NewModule("CombatColor", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceHook-3.0");
D:SetDefaultModuleState(false);
D.debug = false;

jCombatColorRootTable = T;
T.jcc = D;

SLASH_JCCOMBATCOLOR1, SLASH_JCCOMBATCOLOR2 = '/jcc', '/jcc'; -- 3.

function SlashCmdList.JCCOMBATCOLOR(cmd,msg)
  if not cmd or type(cmd)~='string' or cmd=='' then
    return;
  end
  -- print('cmd ',type(cmd),cmd);
  if cmd=='pre' then
    if msg then
      if type(cmd)~='string' or cmd=='' then
        D:Wapretocast(nil);
      else
        D:Wapretocast(msg);
      end
    else
      D:Wapretocast(nil);
    end
  end
end

local function debugStyle(...)
    return "|cFF00AAAADebug:("..D:NiceTime()..")|r", ...;
end

local function errorStyle(...)
    return "|cFFFF0000Error:("..D:NiceTime()..")|r", ...;
end

local function isFormattedString(string)
    return type(string)=='string' and (string:find("%%[cdEefgGiouXxsq]")) or false;
end

local function UseFormatIfPresent(...)
    if not isFormattedString((select(1,...))) then
        return ...;
    else
        return (select(1,...)):format(select(2, ...));
    end
end

function D:NiceTime()
    return tonumber(("%.4f"):format(GetTime() - T.StartTime));
end

function D:Debug(...)
    if D.debug then
        print(debugStyle(UseFormatIfPresent(...)));
    end
end

function D:Error(...)
    print(errorStyle(UseFormatIfPresent(...)));
end

-- tcopy: recursively copy contents of one table to another
function D:tcopy(to, from, defaults)   -- "to" must be a table (possibly empty)
    if (type(from) ~= "table") then
        return error(("D:tcopy: bad argument #2 'from' must be a table, got '%s' instead"):format(type(from)),2);
    end

    if (type(to) ~= "table") then
        return error(("D:tcopy: bad argument #1 'to' must be a table, got '%s' instead"):format(type(to)),2);
    end

    if not self or self~=D then
	error("执行tcopy时self不是D本身");
    end

    if (defaults and type(defaults)=="table")then
	self:tcopy(to,defaults);
    end

    for k,v in pairs(from) do
        if(type(v)=="table") then
            to[k] = {}; -- this generate garbage
            self:tcopy(to[k], v);
        else
            to[k] = v;
        end
    end
end


--[[ Keybinds ]]
BINDING_HEADER_JCOMBATCOLOR = "Combat Color"
BINDING_NAME_JCCCH = "切换稳定仇恨";
BINDING_NAME_JCCRUSH = "切换自动Rush";
BINDING_NAME_JCCADDBOSS = "设置目标为Boss级";
BINDING_NAME_JCCBREAKCASTING = "打断";
BINDING_NAME_JCCTYPE = "切换单个群体";
BINDING_HEADER_HUNTER = "猎人"
BINDING_NAME_JCCAUTOAURA = "切换自动守护";
BINDING_HEADER_MAGE = "法师"
BINDING_NAME_JCCMAGESHIELD = "切换自动法力护盾";
BINDING_NAME_AUTOBREAK = "切换自动打断";
BINDING_NAME_JCCAUTOQUSAN = "切换自动驱散";
BINDING_NAME_JCCTYPE2 = "切换是否横扫";
BINDING_NAME_ROGUE = "盗贼";
BINDING_NAME_JCCROGUEBACK = "切换背后攻击";

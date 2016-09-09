-- Init.lua

local addonName, T = ...;

local fmod              = _G.math.fmod;

T.StartTime = GetTime();

JCC = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceHook-3.0");
jCombatColorRootTable = T;
T.jcc = JCC;
local D = JCC;
local debug = true;

D.Status = {};
D.Status.UnitNum = 0;
D.Status.Unit_Array = {};

local function debugStyle(...)
    return "|cFF00AAAADebug:("..D:NiceTime()..")|r", ...;
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
    if debug then
        print(debugStyle(UseFormatIfPresent(...)));
    end
end

local DcrTimers = {};
function D:TimerExixts(RefName)
    return DcrTimers[RefName] and DcrTimers[RefName][1] or false;
end

function D:DelayedCallExixts(RefName)
    return DcrTimers[RefName] and DcrTimers[RefName][1] or false;
end

local ObjectWithArgs = {["obj"]=false, ["arg"]=false,};
local argCount = 0;
function D:ScheduleDelayedCall(RefName, FunctionRef, Delay, arg1, ...)

    if DcrTimers[RefName] and DcrTimers[RefName][1] then -- a timer with the same refname still exists
        argCount = select('#', ...);
        -- we test up to two arguments to avoid the cancellation->re-creation of the timer (AceTimers doesn't remove them right away)
        if (argCount == 0 or argCount == 1 and  select(1, ...) == DcrTimers[RefName][2][2]) and arg1 == DcrTimers[RefName][2][1] then
            --[===[@debug@
            D:Debug("Timer |cFF0000DDcancellation-creation canceled|r for", RefName, "Arg:", arg1, "indargcount:", argCount);
            --@end-debug@]===]
            return;
            --[===[@debug@
        else
            D:Debug("Timer |cFF0066DD-replaced-|r for", RefName, "argcount:", argCount);
            --@end-debug@]===]
        end
        if not self:CancelTimer(DcrTimers[RefName][1]) then
            self:AddDebugText("Timer cancellation failed in ScheduleDelayedCall() for", RefName);
        end
    end


    if Delay > 30 then
        self:AddDebugText("A delayed call for", RefName, "was requested with a very large timer:", Delay);
    end

    if not DcrTimers[RefName] then
        DcrTimers[RefName] = {};
    end

    -- arg table
    DcrTimers[RefName][2] = {arg1};

    if select('#', ...) > 0 then

        local i;
        for i = 1, select('#', ...) do
            DcrTimers[RefName][2][i + 1] = (select(i, ...));
        end

        DcrTimers[RefName][1] = self:ScheduleTimer (
        function(arg)
            DcrTimers[RefName][1] = false;
            FunctionRef(unpack(arg));
        end
        , Delay, DcrTimers[RefName][2]
        );
    else
        DcrTimers[RefName][1] = self:ScheduleTimer (
        function(arg)
            DcrTimers[RefName][1] = false;
            FunctionRef(arg);
        end
        , Delay, arg1
        );
    end

    return DcrTimers[RefName][1];
end

function D:ScheduleRepeatedCall(RefName, FunctionRef, Delay, arg)
    if DcrTimers[RefName] and DcrTimers[RefName][1] then
        if not self:CancelTimer(DcrTimers[RefName][1]) then
            self:AddDebugText("Timer cancellation failed in ScheduleRepeatedCall() for", RefName);
        end
    end

    if not DcrTimers[RefName] then
        DcrTimers[RefName] = {};
    end

    DcrTimers[RefName][1] = self:ScheduleRepeatingTimer(FunctionRef, Delay, arg);

    return DcrTimers[RefName][1];
end

function D:CancelDelayedCall(RefName)
    local success = false;
    if DcrTimers[RefName] and DcrTimers[RefName][1] then
        local cancelHandle = DcrTimers[RefName][1];
        success = self:CancelTimer(cancelHandle);

        if success then
            DcrTimers[RefName][1] = false;
        else
            self:AddDebugText("Timer cancellation failed in CancelDelayedCall() for", RefName);
        end

        return success;
    end
    return 0;
end

function D:CancelAllTimedCalls()
    for RefName in pairs(DcrTimers) do
        self:CancelDelayedCall(RefName);
    end
end

function D:GetTimersNumber()
    local dcrcount = 0;
    for RefName, timer in pairs(DcrTimers) do
        if timer[1] then
            dcrcount = dcrcount + 1;
        end
    end
    local acetimercount = 0;
    local Acetimer = LibStub("AceTimer-3.0");
    for table in pairs(Acetimer.selfs[D]) do
        acetimercount = acetimercount + 1;
    end
    return "Dcr says: " .. dcrcount .. ", AceTimers says: " .. acetimercount;
end

function D:OnInitialize()
	D.MFContainer = JccMUFsContainer;
	D.MFContainerHandle = JccMUFsContainerDragButton;
	D.MicroActionUnit.Frame = D.MFContainer;


	-- SET MF FRAME AS WRITTEN IN THE CURRENT PROFILE {{{
        -- Set the scale and place the MF container correctly
        if D.profile.ShowDebuffsFrame then
		D.MicroActionUnit:Show();
	else
		D.MFContainer:Hide();
        end
        D.MFContainerHandle:EnableMouse(not D.profile.HideMUFsHandle);
        -- }}}

	D:ScheduleDelayedCall("Dcr_Delay_Init", function()

--[[        if InCombatLockdown() then
            D:AddDelayedFunctionCall (
            "ResetAllPositions", self.ResetAllPositions,
            self);
            return false;
        end]]

	if D.profile.ShowDebuffsFrame then
		self:ScheduleRepeatedCall("Dcr_MUFupdate", self.DebuffsFrame_Update, self.profile.DebuffsFrameRefreshRate, self);
	end

    end, 0.5);

end

function D:GetUnitArray() --{{{
	local Status = self.Status;
	Status.Unit_Array = {"player"}
	Status.UnitNum = #Status.Unit_Array;
	self:Debug ("|cFFFF44FF-->|r Update complete!", Status.UnitNum);
end --}}}

D.Contants = {};
local DC = D.Contants;

DC.AfflictionSound = "Interface\\AddOns\\Decursive\\Sounds\\AfflictionAlert.ogg";
DC.FailedSound = "Interface\\AddOns\\Decursive\\Sounds\\FailedSpell.ogg";
--DC.AfflictionSound = "Sound\\Doodad\\BellTollTribal.wav"

DC.IconON = "Interface\\AddOns\\Decursive\\iconON.tga";
DC.IconOFF = "Interface\\AddOns\\Decursive\\iconOFF.tga";

DC.CLASS_DRUID       = 'DRUID';
DC.CLASS_HUNTER      = 'HUNTER';
DC.CLASS_MAGE        = 'MAGE';
DC.CLASS_PALADIN     = 'PALADIN';
DC.CLASS_PRIEST      = 'PRIEST';
DC.CLASS_ROGUE       = 'ROGUE';
DC.CLASS_SHAMAN      = 'SHAMAN';
DC.CLASS_WARLOCK     = 'WARLOCK';
DC.CLASS_WARRIOR     = 'WARRIOR';
DC.CLASS_DEATHKNIGHT = 'DEATHKNIGHT';

DC.MyClass = "NOCLASS";
DC.MyName = "NONAME";
DC.MyGUID = "NONE";

DC.MAGIC        = 1;
DC.ENEMYMAGIC   = 2;
DC.CURSE        = 4;
DC.POISON       = 8;
DC.DISEASE      = 16;
DC.CHARMED      = 32;
DC.NOTYPE       = 64;


DC.NORMAL                   = 8;
DC.ABSENT                   = 16;
DC.FAR                      = 32;
DC.STEALTHED                = 64;
DC.BLACKLISTED              = 128;
DC.AFFLICTED                = 256;
DC.AFFLICTED_NIR            = 512;
DC.CHARMED_STATUS           = 1024;
DC.AFFLICTED_AND_CHARMED = bit.bor(DC.AFFLICTED, DC.CHARMED_STATUS);

DC.MFSIZE = 20;

-- This value is returned by UnitName when the name of a unit is not available yet
DC.UNKNOWN = UNKNOWNOBJECT;

-- Get the translation for "pet"
DC.PET = SPELL_TARGET_TYPE8_DESC;

DC.DebuffHistoryLength = 40; -- we use a rather high value to avoid garbage creation

DC.DevVersionExpired = false;

-- Create MUFs number fontinstance
DC.NumberFontFileName = _G.NumberFont_Shadow_Small:GetFont();

DC.RAID_ICON_LIST = _G.ICON_LIST;
if not DC.RAID_ICON_LIST then
    T._AddDebugText("DCR_init.lua: Couldn't get Raid Target Icon List!");
    DC.RAID_ICON_LIST = {};
end

DC.RAID_ICON_TEXTURE_LIST = {};

for i,v in ipairs(DC.RAID_ICON_LIST) do
    DC.RAID_ICON_TEXTURE_LIST[i] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. i;
end

D.profile = {};

D.profile.ShowDebuffsFrame = true;
D.profile.DebuffsFramePerline = 1;
D.profile.DebuffsFrameRefreshRate = 0.10;
--D.profile.DebuffsFrameRefreshRate = 10;
D.profile.DebuffsFramePerUPdate = 10;
D.profile.DebuffsFrameXSpacing = 3;
D.profile.DebuffsFrameYSpacing = 3;
D.profile.DebuffsFrameVerticalDisplay = false;
D.profile.HideMUFsHandle = false;

-- MicroActionUnit.lua

D.MicroActionUnit = {};

local MicroActionUnit = D.MicroActionUnit;

MicroActionUnit.prototype = {};
MicroActionUnit.metatable ={ __index = MicroActionUnit.prototype };


function MicroActionUnit:new(...)
    local instance = setmetatable({}, self.metatable);
    instance:init(...);
    return instance;
end

-- Init object factory defaults
--MicroActionUnit.ExistingPerID          = {};
MicroActionUnit.ExistingPerUNIT          = {};
-- MicroActionUnit.ExistingPerNum           = {};
MicroActionUnit.UnitToMUF                = {};
MicroActionUnit.Number                   = 0;
MicroActionUnit.UnitShown                = 0;
MicroActionUnit.UnitsDebuffedInRange     = 0;
MicroActionUnit.DraggingHandle           = false;

MicroActionUnit.MaxUnit                       = 80; -- Unit is Action !

-- MicroActionUnit STATIC methods {{{ 

function MicroActionUnit:Show()
    -- change handle position here depending on reverse display option or in INIT?
    --D.MFContainer:SetScale(D.profile.DebuffsFrameElemScale);
    self:Place (); -- not strickly necessary but avoid glitches when switching between profiles where the scale is different...
    D.MFContainer:Show();
    D.profile.ShowDebuffsFrame = true;
    self:ResetAllPositions();
end


function MicroActionUnit:GetFurtherVerticalMUF()
    -- "Everything pushes me further away..."

    if D.profile.DebuffsFrameVerticalDisplay then

        if self.UnitShown > D.profile.DebuffsFramePerline then
            return D.profile.DebuffsFramePerline;
        else
            return self.UnitShown;
        end

    else

        if self.UnitShown > D.profile.DebuffsFramePerline then
            return floor( self.UnitShown / D.profile.DebuffsFramePerline ) * D.profile.DebuffsFramePerline
            + ((self.UnitShown % D.profile.DebuffsFramePerline ~= 0) and 1 or - D.profile.DebuffsFramePerline + 1);
        else
            return 1;
        end

    end

end

--}}}


-- The Factory for MicroActionUnit objects
function MicroActionUnit:Create(Unit, ID) -- {{{

--[[    if InCombatLockdown() then
        -- if we are fighting, postpone the call
        D:AddDelayedFunctionCall (
        "Create"..Unit, self.Create,
        Unit, ID);
        return false;
    end ]]

    -- if we attempt to create a MUF that already exists, update it instead
    if (MicroActionUnit.ExistingPerUNIT[Unit]) then
        return MicroActionUnit.ExistingPerUNIT[Unit];
    end

    MicroActionUnit.Number = MicroActionUnit.Number + 1;

    -- create a new MUF object
    MicroActionUnit.ExistingPerUNIT[Unit] = MicroActionUnit:new(D.MFContainer, Unit, MicroActionUnit.Number, ID);

--    self.ExistingPerNum[self.Number] = self.ExistingPerUNIT[Unit];

    return MicroActionUnit.ExistingPerUNIT[Unit];
end -- }}}

-- return the number MUFs we can use
function MicroActionUnit:MFUsableNumber () -- {{{
    return ((self.MaxUnit > D.Status.UnitNum) and D.Status.UnitNum or self.MaxUnit);
end -- }}}

-- this is used when a setting influencing MUF's position is changed
function MicroActionUnit:ResetAllPositions () -- {{{

    -- Lua is great...
    D:ScheduleDelayedCall("Dcr_MicroActionUnit_ResetAllPositions", function()

--[[        if InCombatLockdown() then
            D:AddDelayedFunctionCall (
            "ResetAllPositions", self.ResetAllPositions,
            self);
            return false;
        end]]

        if self:MFsDisplay_Update () == false then
            D:Debug("ResetAllPositions(): |cFFFFAA33We are not ready, let's call ourself back later...|r"); -- LOL
            self:ResetAllPositions();
            return false;
        end

        local Unit_Array = D.Status.Unit_Array;

        D:Debug("Resetting all MF position", 'perRow:', D.profile.DebuffsFramePerline, '#Unit_Array:', #Unit_Array);

        for i=1, #Unit_Array do
            MF = self.ExistingPerUNIT[ Unit_Array[i] ]

            if MF then
                MF.Frame:SetPoint(unpack(self:GetMUFAnchor(i)));
            end
        end

        self:Place();

    end, 0.5);

end -- }}}

-- return the anchor of a given MUF depending on its creation ID
do
    local Anchor = { "BOTTOMLEFT", 0, 0, "BOTTOMLEFT" };
    function MicroActionUnit:GetMUFAnchor (ID) -- {{{
        local RowNum, NumOnRow

        if not D.profile.DebuffsFrameVerticalDisplay then
            RowNum =   floor( (ID - 1) / D.profile.DebuffsFramePerline);
            NumOnRow = fmod( (ID - 1), D.profile.DebuffsFramePerline);
        else
            RowNum =   fmod(  (ID - 1),  D.profile.DebuffsFramePerline );
            NumOnRow = floor( (ID - 1) / D.profile.DebuffsFramePerline );
        end

        local x = NumOnRow * (DC.MFSIZE + D.profile.DebuffsFrameXSpacing);
        local y = (D.profile.DebuffsFrameGrowToTop and 1 or -1) * RowNum * (D.profile.DebuffsFrameYSpacing + DC.MFSIZE);

        Anchor[2] = x; Anchor[3] = y;

        return Anchor;
    end
end-- }}}


function MicroActionUnit:Delayed_MFsDisplay_Update ()
    if D.profile.ShowDebuffsFrame then
        D:ScheduleDelayedCall("Dcr_Delayed_MFsDisplay_Update", self.MFsDisplay_Update, 1.5, self);
--	self.MFsDisplay_Update(self);
    end
end

-- This update the MUFs display, show and hide MUFs as necessary
function MicroActionUnit:MFsDisplay_Update () -- {{{

    if (not D.profile.ShowDebuffsFrame) then
        return;
    end

    -- This function cannot do anything if we are fighting
--[[    if InCombatLockdown() then
        -- if we are fighting, postpone the call
        D:AddDelayedFunctionCall (
        "UpdateMicroActionUnitrameDisplay", self.MFsDisplay_Update,
        self);
        return false;
    end]]

    -- Get an up to date unit array if necessary
    D:GetUnitArray(); -- this is the only place where GetUnitArray() is called directly

    -- =======
    --  Begin
    -- =======

    -- get the number of MUFs we should display
    local NumToShow = self:MFUsableNumber();


    -- if we don't have all the MUFs needed then return, we are not ready
    if (self.Number < NumToShow) then
        self:Delayed_MFsDisplay_Update ();
        return false;
    end


    local MF = false;
    local i = 1;
    local Old_UnitShown = self.UnitShown;


    D:Debug("Update required: NumToShow = ", NumToShow);

    local Unit_Array_UnitToGUID = D.Status.Unit_Array_UnitToGUID;
    local Unit_Array            = D.Status.Unit_Array;


    -- Scan unit array in display order and show the maximum until NumToShow is reached
    -- The ID is set for all MUFs present in our unit array
    local Updated = 0;
    for i, Unit in ipairs(Unit_Array) do

        MF = self.ExistingPerUNIT[Unit];
        if MF then
            MF.ID = i;
            if not MF.Shown and i <= NumToShow then -- we got this unit in our group but it's hidden

                MF.Shown = true;
                self.UnitShown = self.UnitShown + 1;
                MF.ToPlace = true;
                Updated = Updated + 1;

                D:ScheduleDelayedCall("Dcr_Update"..MF.CurrUnit, MF.UpdateWithCS, D.profile.DebuffsFrameRefreshRate * Updated, MF);
                D:Debug("|cFF88AA00Show schedule for MUF", Unit, "UnitShown:", self.UnitShown);
            end
        else
            --D:errln("showhide: no muf for", Unit); -- call delay display up 
            self:Delayed_MFsDisplay_Update ();
        end

    end

    -- hide remaining units
    if self.UnitShown > NumToShow then

        for Unit, MF in  pairs(self.ExistingPerUNIT) do -- see all the MUF we ever created and show or hide them if there corresponding unit exists

            -- show/hide
	    -- not Unit_Array_UnitToGUID[Unit] or 
            if MF.Shown and (MF.ID > NumToShow ) then -- we don't have this unit but its MUF is shown

                -- clear debuff before hiding to avoid leaving 'ghosts' behind...
                if D.UnitDebuffed[MF.CurrUnit] then
                    D.ForLLDebuffedUnitsNum = D.ForLLDebuffedUnitsNum - 1;
                end

                MF.Debuffs                      = false;
                MF.IsDebuffed                   = false;
                MF.Debuff1Prio                  = false;
                MF.PrevDebuff1Prio              = false;
                D.UnitDebuffed[MF.CurrUnit]     = false; -- used by the live-list only
                D.Stealthed_Units[MF.CurrUnit]  = false;


                MF.Shown = false;
                self.UnitShown = self.UnitShown - 1;
                D:Debug("|cFF88AA00Hiding %d (%s), scheduling update in %f|r", i, MF.CurrUnit, D.profile.DebuffsFrameRefreshRate * i);
                Updated = Updated + 1;
                D:ScheduleDelayedCall("Dcr_Update"..MF.CurrUnit, MF.Update, D.profile.DebuffsFrameRefreshRate * Updated, MF);
                MF.Frame:Hide();
            end

        end
    end

    -- manage to get what we show in the screen
    if self.UnitShown > 0 and Old_UnitShown ~= self.UnitShown then
        MicroActionUnit:Place();
    end

    return true;
end -- }}}


function MicroActionUnit:Delayed_Force_FullUpdate ()
    if (D.profile.ShowDebuffsFrame) then
        D:ScheduleDelayedCall("Dcr_Force_FullUpdate", self.Force_FullUpdate, 0.3, self);
    end
end

function MicroActionUnit:Force_FullUpdate () -- {{{
    if (not D.profile.ShowDebuffsFrame) then
        return false;
    end

    -- This function cannot do anything if we are fighting
    if InCombatLockdown() then
        -- if we are fighting, postpone the call
        D:AddDelayedFunctionCall (
        "Force_FullUpdate", self.Force_FullUpdate,
        self);
        return false;
    end

    D.Status.SpellsChanged = GetTime(); -- will force an update of all MUFs attributes

    local i = 1;
    for Unit, MF in  pairs(self.ExistingPerUNIT) do

        if not MF.IsDebuffed then
            MF.UnitStatus = 0; -- reset status to force SetColor to update
        end

        MF.ChronoFontString:SetTextColor(unpack(MF_colors["COLORCHRONOS"]));

        D:ScheduleDelayedCall("Dcr_Update"..MF.CurrUnit, MF.UpdateWithCS, D.profile.DebuffsFrameRefreshRate * i, MF);
        i = i + 1;
    end
end -- }}}

-- Those set the scalling of the MUF container
-- SACALING FUNCTIONS (MicroActionUnit Children) {{{
do
    local UIScale = 0;
    local FrameScale = 0;

    local function TestMUFCorner(x, y, margin) -- {{{

        -- if the MUF is not horizontaly outside of the screen
        if not (x < 0 or x + margin > DC.ScreenWidth) then
            x = nil;
        end

        -- if the MUF is not vertically outside of the screen
        if not (y < 0 or y + margin > DC.ScreenHeight) then
            y = nil;
        end

        return x, y;
    end -- }}}

    function MicroActionUnit.prototype:IsOnScreen(xDelta, yDelta) -- {{{

        -- frame relative position
        local left, bottom, width, height = self.Frame:GetRect();

        -- we need to check just one corner (MUFs are fix-sized squares)
        return TestMUFCorner(left * FrameScale - xDelta, bottom * FrameScale - yDelta, width * FrameScale);

    end -- }}}

    -- Place the MUFs container according to its scale
    function MicroActionUnit:Place () -- {{{

        if self.UnitShown == 0 or self.DraggingHandle then return end

        if InCombatLockdown() then
            -- if we are fighting, postpone the call
            D:AddDelayedFunctionCall (
            "MicroActionUnitPlace", self.Place,
            self);
            return;
        end

        UIScale       = UIParent:GetEffectiveScale()
        FrameScale    = self.Frame:GetEffectiveScale();

        DC.ScreenWidth  = UIParent:GetWidth() * UIScale;
        DC.ScreenHeight = UIParent:GetHeight() * UIScale;

        local saved_x, saved_y = D.profile.DebuffsFrameContainer_x, D.profile.DebuffsFrameContainer_y;
        local current_x, current_y = self.Frame:GetRect();
        current_x = current_x * FrameScale;
        current_y = current_y * FrameScale;

        --D:Debug("xDelta=", current_x - saved_x, "yDelta=", current_y - saved_y); -- XXX will crash

        -- If executed for the very first time, then put it in the top right corner of the screen
        if (not saved_x or not saved_y) then
            saved_x =    (UIParent:GetWidth() * UIScale) - (UIParent:GetWidth() * UIScale) / 4;
            saved_y =    (UIParent:GetHeight() * UIScale) - (UIParent:GetWidth() * UIScale) / 5;

            D.profile.DebuffsFrameContainer_x = saved_x;
            D.profile.DebuffsFrameContainer_y = saved_y;
        end


        -- test and fix handle's position if some MUFs are out of the screen
        local Handle_x_offset = 0;
        local Handle_y_offset = 0;
        local StickToRightOffest = 0;

        local Unit_Array = D.Status.Unit_Array;
        local x_out_arrays = {};
        local y_out_arrays = {};


        if D.profile.DebuffsFrameStickToRight then -- {{{
            local FirstLineNum = 0;
            -- get the number of max unit per line/row
            if not D.profile.DebuffsFrameVerticalDisplay then
                if self.UnitShown > D.profile.DebuffsFramePerline then
                    FirstLineNum = D.profile.DebuffsFramePerline;
                else FirstLineNum = self.UnitShown; end
            else
                if self.UnitShown > D.profile.DebuffsFramePerline then
                    FirstLineNum = floor( (self.UnitShown ) /  D.profile.DebuffsFramePerline ) + ((self.UnitShown % D.profile.DebuffsFramePerline ~= 0) and 1 or 0);
                else FirstLineNum = 1; end
            end

            -- get the offset of the handle we need to apply in order to align the MUFs on the right
            StickToRightOffest = FrameScale * (FirstLineNum * (DC.MFSIZE + D.profile.DebuffsFrameXSpacing) - D.profile.DebuffsFrameXSpacing );
        end -- }}}


        -- get a list of all MUFs which position is *saved* outside of the screen (hence the current_y - saved_y)
        for i=1, self.UnitShown do
            local MF = self.ExistingPerUNIT[ Unit_Array[i] ];

            if MF then
                x_out_arrays[#x_out_arrays + 1], y_out_arrays[#y_out_arrays + 1] = MF:IsOnScreen(current_x - saved_x + StickToRightOffest, current_y - saved_y)
            end
        end

        -- sort those lists to find the extrems
        if #x_out_arrays then table.sort(x_out_arrays) end
        if #y_out_arrays then table.sort(y_out_arrays) end


        -- test if there is no solution -- XXX cannot work
        if (x_out_arrays[1] and x_out_arrays[1] < 0 and  (x_out_arrays[#x_out_arrays] > DC.ScreenWidth))
            or (y_out_arrays[1] and y_out_arrays[1] < 0 and  (y_out_arrays[#y_out_arrays] > DC.ScreenHeight)) then
            D:Print(D:ColorText("WARNING: Your Micro-Unit-Frames' window is too big to fit entirely on your screen, you should change MUFs display settings (scale and/or disposition)! (Type /Decursive)", "FFFF0000"));
        end

        D:Debug(x_out_arrays[1], x_out_arrays[#x_out_arrays], y_out_arrays[1], y_out_arrays[#x_out_arrays]);

        -- x
        if x_out_arrays[1] then
            if x_out_arrays[1] < 0 then
                Handle_x_offset = -  x_out_arrays[1];
            else
                Handle_x_offset = - (x_out_arrays[#x_out_arrays] + DC.MFSIZE * FrameScale - DC.ScreenWidth)
            end
        end

        -- y 
        if y_out_arrays[1] then
            if y_out_arrays[1] < 0 then
                Handle_y_offset = -  y_out_arrays[1];
            else
                Handle_y_offset = - (y_out_arrays[#y_out_arrays] + DC.MFSIZE * FrameScale - DC.ScreenHeight)
            end
        end

        D:Debug(Handle_x_offset, Handle_y_offset);

	saved_x = saved_x + Handle_x_offset - StickToRightOffest;
        saved_y = saved_y + Handle_y_offset;
	D:Debug("Point at FrameScale:", FrameScale, " x:",saved_x, "y:",saved_y);

        -- set to the scaled position
        self.Frame:ClearAllPoints();
        self.Frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", saved_x/FrameScale , saved_y/FrameScale);
        D:Debug("MUF Window position set");


        -- move the handle to always be above the first MUF
        local RefMUF = 1;
        local FarthestVerticalMUF = self:GetFurtherVerticalMUF();
        

        if D.profile.DebuffsFrameGrowToTop then
            RefMUF = FarthestVerticalMUF;
        end

        if self.ExistingPerUNIT[Unit_Array[RefMUF]] then
            D.MFContainerHandle:ClearAllPoints();
            D.MFContainerHandle:SetPoint("BOTTOMLEFT", self.ExistingPerUNIT[Unit_Array[RefMUF]].Frame, "TOPLEFT");

            -- if the handle is at the top of the screen it means it's overlaping the MUF, let's move the handle somewhere else.
            if floor(D.MFContainerHandle:GetTop() * FrameScale) == floor(UIParent:GetTop() * UIScale) then
                if Unit_Array[D.profile.DebuffsFrameGrowToTop and 1 or FarthestVerticalMUF] and self.ExistingPerUNIT[Unit_Array[D.profile.DebuffsFrameGrowToTop and 1 or FarthestVerticalMUF]] then
                    D.MFContainerHandle:ClearAllPoints();
                    D.MFContainerHandle:SetPoint("TOPLEFT", self.ExistingPerUNIT[Unit_Array[D.profile.DebuffsFrameGrowToTop and 1 or FarthestVerticalMUF]].Frame, "BOTTOMLEFT");
                    D:Debug("|cff00ff00Handle moved|r");
                else
                    -- try again in 2s (a delay exists when a unit appears, is seen and its MUF is created), if a unit leavea and another joina the group at the same time, the unit number won't change but their respective unitID will.
                    D:ScheduleDelayedCall("Dcr_Delayed_Place", self.Place, 2, self);
                    --[===[@alpha@
                    D:Print("|cFFFF0000Place() failed: unitRef#", D.profile.DebuffsFrameGrowToTop and 1 or FarthestVerticalMUF, "refMUF:", self.ExistingPerUNIT[Unit_Array[D.profile.DebuffsFrameGrowToTop and 1 or FarthestVerticalMUF]], "|r");
                    --@end-alpha@]===]
                end
            end
        end


    end -- }}}

    -- Save the position of the frame without its scale
    function MicroActionUnit:SavePos () -- {{{

        if self.UnitShown == 0 then return end


        if self.Frame:IsVisible() then
            -- We save the unscalled position (no problem if the sacale is changed behind our back)
            D.profile.DebuffsFrameContainer_x = self.Frame:GetEffectiveScale() * self.Frame:GetLeft();
            D.profile.DebuffsFrameContainer_y = self.Frame:GetEffectiveScale() * self.Frame:GetBottom();
            D:Debug("MUF pos:", D.profile.DebuffsFrameContainer_x, D.profile.DebuffsFrameContainer_y);


            -- if we choosed to align the MUF to the right then we have to add the
            -- width of the first line to get the original position of the handle

            if D.profile.DebuffsFrameStickToRight then -- {{{

                local FirstLineNum;

                if not D.profile.DebuffsFrameVerticalDisplay then
                    if self.UnitShown > D.profile.DebuffsFramePerline then
                        FirstLineNum = D.profile.DebuffsFramePerline;
                    else
                        FirstLineNum = self.UnitShown;
                    end
                else
                    if self.UnitShown > D.profile.DebuffsFramePerline then
                        FirstLineNum = floor( self.UnitShown / D.profile.DebuffsFramePerline ) + ((self.UnitShown % D.profile.DebuffsFramePerline ~= 0) and 1 or 0);
                    else
                        FirstLineNum = 1;
                    end
                end

                D.profile.DebuffsFrameContainer_x = D.profile.DebuffsFrameContainer_x + self.Frame:GetEffectiveScale() * (FirstLineNum * (DC.MFSIZE + D.profile.DebuffsFrameXSpacing) - D.profile.DebuffsFrameXSpacing);
            end -- }}}

            --      D:Debug("Frame position saved");
            D:Debug("MUF pos saved:", D.profile.DebuffsFrameContainer_x, D.profile.DebuffsFrameContainer_y);
        end

    end -- }}}
end



-- set the scaling of the MUFs container according to the user settings
function MicroActionUnit:SetScale (NewScale) -- {{{

    -- Setting the new scale
    self.Frame:SetScale(NewScale);
    -- Place the frame adapting its position to the news cale
    self:Place ();

end -- }}}
-- }}}

-- Update the MUF of a given unitid
function MicroActionUnit:UpdateMUFUnit(Unitid, CheckStealth)
    if not D.profile.ShowDebuffsFrame then
        return;
    end

    local unit = false;

    if (D.Status.Unit_Array_UnitToGUID[Unitid]) then
        unit = Unitid;
    else
        D:Debug("Unit", Unitid, "not in raid or party!" );
        return;
    end

    -- get the MUF object
    local MF = self.UnitToMUF[unit];

    if (MF and MF.Shown) then
        -- The MUF will be updated only every DebuffsFrameRefreshRate seconds at most
        -- but we don't miss any event XXX note this can be the cause of slowdown if 25 or 40 players got debuffed at the same instant, DebuffUpdateRequest is here to prevent that since 2008-02-17
        if (not D:DelayedCallExixts("Dcr_Update"..unit)) then
            D.DebuffUpdateRequest = D.DebuffUpdateRequest + 1;
            D:ScheduleDelayedCall("Dcr_Update"..unit, CheckStealth and MF.UpdateWithCS or MF.Update, D.profile.DebuffsFrameRefreshRate * (1 + floor(D.DebuffUpdateRequest / (D.profile.DebuffsFramePerUPdate / 2))), MF);
            D:Debug("Update scheduled for, ", unit, MF.ID);

            return true; -- return value used to aknowledge that the function actually did something
        end
    else
        D:Debug("No MUF found for ", unit, Unitid);
    end
end

-- Event management functions
-- MUF EVENTS (MicroActionUnit children) (OnEnter, OnLeave, OnLoad, OnPreClick) {{{
-- It's outside the function to avoid creating and discarding this table at each call
local UnitGUID = _G.UnitGUID;
local TooltipButtonsInfo = {}; -- help tooltip text table
local TooltipUpdate = 0; -- help tooltip change update check
-- This function is responsible for showing the tooltip when the mouse pointer is over a MUF
-- it also handles Unstable Affliction detection and warning.
function MicroActionUnit:OnEnter(frame) -- {{{
    D.Status.MouseOveringMUF = true;
    D:Debug("Move in to the frame!!!!");

    local MF = frame.Object;
    local Status;

    local Unit = MF.CurrUnit; -- shortcut
    local TooltipText = "";


    local GUIDwasFixed = false;

end -- }}}

function MicroActionUnit:OnLeave() -- {{{
    D.Status.MouseOveringMUF = false;
end -- }}}


function D.MicroActionUnit:OnCornerEnter(frame)
--[[    if (D.profile.DebuffsFrameShowHelp) then
        D:DisplayGameTooltip(frame,
        str_format(
        "|cFF11FF11%s|r-|cFF11FF11%s|r: %s\n\n"..
        --"|cFF11FF11%s|r: %s\n"..
        "|cFF11FF11%s|r-|cFF11FF11%s|r: %s\n\n"..
        "|cFF11FF11%s|r-|cFF11FF11%s|r: %s\n"..
        "|cFF11FF11%s|r-|cFF11FF11%s|r: %s\n\n"..
        "|cFF11FF11%s|r-|cFF11FF11%s|r: %s",

        D.L["ALT"],             D.L["HLP_LEFTCLICK"],   D.L["HANDLEHELP"],

        --D.L["HLP_RIGHTCLICK"],  D.L["STR_OPTIONS"],
        D.L["ALT"],             D.L["HLP_RIGHTCLICK"],  D.L["BINDING_NAME_DCRSHOWOPTION"],

        D.L["CTRL"],            D.L["HLP_LEFTCLICK"],   D.L["BINDING_NAME_DCRPRSHOW"], 
        D.L["SHIFT"],           D.L["HLP_LEFTCLICK"],   D.L["BINDING_NAME_DCRSKSHOW"],

        D.L["SHIFT"],           D.L["HLP_RIGHTCLICK"],  D.L["BINDING_NAME_DCRSHOW"]
        ));
    end;]]
end


function MicroActionUnit:OnLoad(frame) -- {{{
--    frame:SetScript("PreClick", self.OnPreClick);
--    frame:SetScript("PostClick", self.OnPostClick);
end
-- }}}

function MicroActionUnit.OnPreClick(frame, Button) -- {{{
    D:Debug("Micro unit Preclicked: ", Button);

    local Unit = frame.Object.CurrUnit; -- shortcut

    if (frame.Object.UnitStatus == NORMAL and (Button == "LeftButton" or Button == "RightButton")) then

        D:Println(L["HLP_NOTHINGTOCURE"]);

    elseif (frame.Object.UnitStatus == AFFLICTED) then
        local NeededPrio = D:GiveSpellPrioNum(frame.Object.Debuffs[1].Type);
        local RequestedPrio;
        local ButtonsString = "";
        local modifier;

        if IsControlKeyDown() then
            modifier = "ctrl-";
        elseif IsAltKeyDown() then
            modifier = "alt-";
        elseif IsShiftKeyDown() then
            modifier = "shift-";
        end

        if Button == "LeftButton" then
            ButtonsString = "*%s1";
        elseif Button == "RightButton" then
            ButtonsString = "*%s2";
        elseif Button == "MiddleButton" then
            ButtonsString = "*%s3";
        else
            D:Debug("unknown button");
            return;
        end

        RequestedPrio = D:tGiveValueIndex(D.db.global.MouseButtons, modifier and (modifier .. ButtonsString:sub(-3)) or ButtonsString);
        D:Debug("RequestedPrio:", RequestedPrio);

        -- there is no spell for the requested prio ? (no spell registered to this modifier+mousebutton)
        if modifier and RequestedPrio and not D:tcheckforval(D.Status.CuringSpellsPrio, RequestedPrio) then

            D:Debug("No spell registered for", RequestedPrio);

            -- Get the priority that would have been requested without modifiers
            local RequestedPrioNoMod = D:tGiveValueIndex(D.db.global.MouseButtons, ButtonsString);

            -- Get the spell bond to this priority
            local NoModSpell = D:tGiveValueIndex(D.Status.CuringSpellsPrio, RequestedPrioNoMod)

            -- If there is one and it's a user customized macro
            if NoModSpell and D.Status.FoundSpells[NoModSpell][5] then
                D:Debug("But spell used by", ButtonsString, "is a user nacro");
                -- let the user use the modifiers he want without yelling at him
                RequestedPrio = RequestedPrioNoMod;
            end
        end

        if RequestedPrio and NeededPrio ~= RequestedPrio then
            D:errln(L["HLP_WRONGMBUTTON"]);
            if NeededPrio and MF_colors[NeededPrio] then
                D:Println(L["HLP_USEXBUTTONTOCURE"], D:ColorText(DC.MouseButtonsReadable[ D.db.global.MouseButtons[NeededPrio] ], D:NumToHexColor(MF_colors[NeededPrio])));
                --[===[@debug@
            else
                D:AddDebugText("Button wrong click info bug: NeededPrio:", NeededPrio, "Unit:", Unit, "RequestedPrio:", RequestedPrio, "Button clicked:", Button, "MF_colors:", unpack(MF_colors), "Debuff Type:", frame.Object.Debuffs[1].Type);
                --@end-debug@]===]
            end
        elseif RequestedPrio and D.Status.HasSpell then
            D.Status.ClickCastingWIP = true;
            D:Debug("ClickCastingWIP")
            D.Status.ClickedMF = frame.Object; -- used to update the MUF on cast success and failure to know which unit is being cured
            D.Status.ClickedMF.SPELL_CAST_SUCCESS = false;
            local spell = D.Status.CuringSpells[frame.Object.Debuffs[1].Type];

            D.Status.ClickedMF.CastingSpell = "notyet" -- (GetSpellInfo(spell)); -- store the spell name but without its rank
            D:Debuff_History_Add(frame.Object.Debuffs[1].Name, frame.Object.Debuffs[1].TypeName);
        end
    end
end -- }}}

function MicroActionUnit:OnPostClick(frame, button)
    D:Debug("Micro unit PostClicked");
    D.Status.ClickCastingWIP = false;
end

-- }}}

-- }}}

-- MicroActionUnit NON STATIC METHODS {{{
-- init a new micro frame (Call internally by :new() only)
function MicroActionUnit.prototype:init(Container, Unit, FrameNum, ID) -- {{{
    D:Debug("Initializing MicroUnit object", Unit, "with FrameNum=", FrameNum, " and ID", ID);

    -- set object default variables
    self.Parent             = Container;
    self.ID                 = ID; -- is set by te roaming updater
    self.FrameNum           = FrameNum;
    self.ToPlace            = true;
    self.Debuffs            = false;
    self.Debuff1Prio        = false;
    self.PrevDebuff1Prio    = false;
    self.IsDebuffed         = false;
    self.CurrUnit           = false;
    self.UnitName           = false;
    self.UnitGUID           = false;
    self.UnitClass          = false;
    self.UnitStatus         = 0;
    self.FirstDebuffType    = 0;
    self.NormalAlpha        = false;
    self.BorderAlpha        = false;
    self.Color              = {};
    self.IsCharmed          = false;
    self.UpdateCountDown    = 3;
    self.LastAttribUpdate   = 0;
    self.LitTime            = false;
    self.Chrono             = false;
    self.PrevChrono         = false;
    self.Shown              = false; -- Setting this to true will broke the stick to right option
    self.UpdateCD           = 0;
    self.RaidTargetIcon     = false;
    self.PrevRaidTargetIndex= false;

    -- if it's a pet make it a little bit smaller
    local petminus = 0;
    if Unit:find("pet") then
        petminus = 4;
    end

--    if(1)then return; end

    -- create the frame
    self.Frame  = CreateFrame ("Button", nil, self.Parent, "JccMicroUnitTemplateSecure");
self.Frame:SetText("!!!");
--    self.CooldownFrame = CreateFrame ("Cooldown", nil, self.Frame, "DcrMicroUnitCDTemplate");

    if petminus ~= 0 then
        self.Frame:SetWidth(20 - petminus);
        self.Frame:SetHeight(20 - petminus);
--        self.CooldownFrame:SetWidth(16 - petminus);
--        self.CooldownFrame:SetHeight(16 - petminus);
    end

    -- outer texture (the class border)
    -- Bottom side
    self.OuterTexture1 = self.Frame:CreateTexture(nil, "BORDER");
    self.OuterTexture1:SetPoint("BOTTOMLEFT", self.Frame, "BOTTOMLEFT", 0, 0);
    self.OuterTexture1:SetPoint("TOPRIGHT", self.Frame, "BOTTOMRIGHT",  0, 2);

    -- left side
    self.OuterTexture2 = self.Frame:CreateTexture(nil, "BORDER");
    self.OuterTexture2:SetPoint("TOPLEFT", self.Frame, "TOPLEFT", 0, -2);
    self.OuterTexture2:SetPoint("BOTTOMRIGHT", self.Frame, "BOTTOMLEFT", 2, 2);

    -- top side
    self.OuterTexture3 = self.Frame:CreateTexture(nil, "BORDER");
    self.OuterTexture3:SetPoint("TOPLEFT", self.Frame, "TOPLEFT", 0, 0);
    self.OuterTexture3:SetPoint("BOTTOMRIGHT", self.Frame, "TOPRIGHT", 0, -2);

    -- right side
    self.OuterTexture4 = self.Frame:CreateTexture(nil, "BORDER");
    self.OuterTexture4:SetPoint("TOPRIGHT", self.Frame, "TOPRIGHT", 0, -2);
    self.OuterTexture4:SetPoint("BOTTOMLEFT", self.Frame, "BOTTOMRIGHT", -2, 2);


    -- global texture
    self.Texture = self.Frame:CreateTexture(nil, "ARTWORK");
    self.Texture:SetPoint("CENTER",self.Frame ,"CENTER",0,0)
    self.Texture:SetHeight(16 - petminus);
    self.Texture:SetWidth(16 - petminus);

    -- inner Texture (Charmed special texture)
    self.InnerTexture = self.Frame:CreateTexture(nil, "OVERLAY");
    self.InnerTexture:SetPoint("CENTER",self.Frame ,"CENTER",0,0)
    self.InnerTexture:SetHeight(7 - petminus);
    self.InnerTexture:SetWidth(7 - petminus);
--    self.InnerTexture:SetTexture(unpack(MF_colors[CHARMED_STATUS]));

    -- Chrono Font string
    self.ChronoFontString = self.Frame:CreateFontString(nil, "ARTWORK", "JccMicroUnitChronoFont");
    self.ChronoFontString:SetFont(DC.NumberFontFileName, 12.2, "THICKOUTLINE, MONOCHROME")
    self.ChronoFontString:SetPoint("CENTER",self.Frame ,"CENTER",1.6,0)
    self.ChronoFontString:SetPoint("BOTTOM",self.Frame ,"BOTTOM",0,1)
--    self.ChronoFontString:SetTextColor(unpack(MF_colors["COLORCHRONOS"]));

    -- raid target icon
    self.RaidIconTexture = self.Frame:CreateTexture(nil, "OVERLAY");
    self.RaidIconTexture:SetPoint("CENTER",self.Frame ,"CENTER",0,8)
    self.RaidIconTexture:SetHeight(13 - petminus);
    self.RaidIconTexture:SetWidth(13 - petminus);


    -- a reference to this object
    self.Frame.Object = self;

    -- register events
    self.Frame:RegisterForClicks("AnyUp");
    self.Frame:SetFrameStrata("MEDIUM");

    -- set the frame attributes
    self:UpdateAttributes(Unit);

    -- once the MF frame is set up, schedule an event to show it
    MicroActionUnit:Delayed_MFsDisplay_Update();
end -- }}}

function MicroActionUnit.prototype:Update(SkipSetColor, SkipDebuffs, CheckStealth)
    local MF = self;
    local ActionsDone = 0;
    if(1)then return ActionsDone; end

    local Unit = MF.CurrUnit;

    -- The unit is the same but the name isn't... (check for class change)
    if MF.CurrUnit == Unit and D.Status.Unit_Array_UnitToGUID[self.CurrUnit] ~= self.UnitGUID then
--[[        if MF:SetClassBorder() then
            ActionsDone = ActionsDone + 1; -- count expensive things done
        end]]
        -- if the guid changed we really need to rescan the unit!
        SkipSetColor = false; SkipDebuffs = false; CheckStealth = true;
        --[===[@debug@
        D:Debug("|cFF00CC00MUF:Update(): Guid change rescanning", Unit, "|r");
        --@end-debug@]===]
    end

    -- Update the frame attributes if necessary (Spells priority or unit id changes)
    if (D.Status.SpellsChanged ~= MF.LastAttribUpdate ) then
        --D:Debug("Attributes update required: ", MF.ID);
        if (MF:UpdateAttributes(Unit, true)) then
            ActionsDone = ActionsDone + 1; -- count expensive things done
            SkipSetColor = false; SkipDebuffs = false; -- if some attributes were updated then update the rest
        end
    end


    if (not SkipSetColor) then
        if (not SkipDebuffs) then
            -- get the manageable debuffs of this unit
            MF:SetDebuffs();
            D:Debug("Debuff set for ", MF.ID);
            if CheckStealth then
                D.Stealthed_Units[MF.CurrUnit] = D:CheckUnitStealth(MF.CurrUnit); -- update stealth status
                --              D:Debug("MF:Update(): Stealth status checked as requested.");
            end
        end

        if (MF:SetColor()) then
            ActionsDone = ActionsDone + 1; -- count expensive things done
        end
    end

    return ActionsDone;
end


function MicroActionUnit.prototype:UpdateWithCS()
    self:Update(false, false, true);
end

function MicroActionUnit.prototype:UpdateSkippingSetBuf()
    self:Update(false, true);
end


-- UPDATE attributes (Spells and Unit) {{{



do
    -- used to tell if we changed something to improve performances.
    -- Each attribute change trigger an event...
    local ReturnValue = false;
    local tmp;
    -- this updates the sttributes of a MUF's frame object
    function MicroActionUnit.prototype:SetUnstableAttribute(attribute, value)
        self.Frame:SetAttribute(attribute, value);
        self.usedAttributes[attribute] = self.LastAttribUpdate;
    end

    function MicroActionUnit.prototype:CleanDefuncUnstableAttributes()
        for attribute, lastupdate in pairs(self.usedAttributes) do
            if lastupdate ~= self.LastAttribUpdate then
                self.Frame:SetAttribute(attribute, nil);
                self.usedAttributes[attribute] = nil;
                D:Debug("Removed defunc attribute", attribute);
            end
        end
    end

    function MicroActionUnit.prototype:UpdateAttributes(Unit, DoNotDelay)

        -- Delay the call if we are fighting
        if InCombatLockdown() then
            if not DoNotDelay then
                D:AddDelayedFunctionCall (
                "MicroUnit_" .. Unit,                   -- UID
                self.UpdateAttributes, self, Unit);     -- function call
            end
            return false;
        end

        ReturnValue = false;

        if not self.usedAttributes then
            self.usedAttributes = {};
        end

        -- if the unit is not set
        if not self.CurrUnit then
            self.Frame:SetAttribute("unit", Unit);

            -- UnitToMUF[] can only be set when out of fight so it remains
            -- coherent with what is displayed when groups are changed during a
            -- fight

            MicroActionUnit.UnitToMUF[Unit] = self;
            self.CurrUnit = Unit;

--            self:SetClassBorder();

            -- set the return value because we did something expensive
            ReturnValue = self;
        end

        if (D.Status.SpellsChanged == self.LastAttribUpdate) then
            return ReturnValue; -- nothing changed
        end

         D:Debug("UpdateAttributes() executed");

        if self.LastAttribUpdate == 0 then -- only once
            -- set the mouse left-button actions on all modifiers
            self.Frame:SetAttribute("*type1", "macro");
            self.Frame:SetAttribute("ctrl-type1", "macro");
            self.Frame:SetAttribute("alt-type1", "macro");
            self.Frame:SetAttribute("shift-type1", "macro");

            -- set the mouse right-button actions on all modifiers
            self.Frame:SetAttribute("*type2", "macro");
            self.Frame:SetAttribute("ctrl-type2", "macro");
            self.Frame:SetAttribute("alt-type2", "macro");
            self.Frame:SetAttribute("shift-type2", "macro");

            -- set the mouse middle-button actions on all modifiers
            self.Frame:SetAttribute("*type3", "macro");
            self.Frame:SetAttribute("ctrl-type3", "macro");
            self.Frame:SetAttribute("alt-type3", "macro");
            self.Frame:SetAttribute("shift-type3", "macro");
        end

        local MouseButtons = {
                "*%s1", -- left mouse button
                "*%s2", -- right mouse button
                "ctrl-%s1",
                "ctrl-%s2",
                "shift-%s1",
                "shift-%s2",
                "shift-%s3",
                "alt-%s1",
                "alt-%s2",
                "alt-%s3",
                "*%s3",       -- the last two entries are always target and focus
                "ctrl-%s3",
            };

        self:SetUnstableAttribute(MouseButtons[#MouseButtons - 1]:format("macrotext"), ("/target %s"):format(Unit));
        self:SetUnstableAttribute(MouseButtons[#MouseButtons    ]:format("macrotext"), ("/focus %s"):format(Unit));
	self:SetUnstableAttribute(MouseButtons[1]:format("macrotext"), ("/cast [@%s] 真言术：盾"):format(Unit));

        -- set the spells attributes using the lookup tables above
	--[[
        for Spell, Prio in pairs(D.Status.CuringSpellsPrio) do

            if not D.Status.FoundSpells[Spell][5] then -- if using the default macro mechanism

                --the [target=%s, help][target=%s, harm] prevents the 'please select a unit' cursor problem (Blizzard should fix this...)
                -- -- XXX this trick may cause issues or confusion when for some reason the unit is invalid, nothing will happen when clicking
                self:SetUnstableAttribute(MouseButtons[Prio]:format("macrotext"), ("%s/cast [@%s, help][@%s, harm] %s"):format(
                ((not D.Status.FoundSpells[Spell][1]) and "/stopcasting\n" or ""),
                Unit,Unit,
                Spell));
		D:Debug(MouseButtons[Prio]:format("macrotext"));
		D:Debug(("%s/cast [@%s, help][@%s, harm] %s"):format(
                ((not D.Status.FoundSpells[Spell][1]) and "/stopcasting\n" or ""),
                Unit,Unit,
                Spell));
            else
                tmp = D.Status.FoundSpells[Spell][5];
                tmp = tmp:gsub("UNITID", Unit);
                if tmp:len() < 256 then -- last chance protection, shouldn't happen
                    self:SetUnstableAttribute(MouseButtons[Prio]:format("macrotext"), tmp);
                else
                    D:errln("Macro too long for", Unit);
                end
            end

        end]]

        -- clean unused attributes...
        self:CleanDefuncUnstableAttributes();

        self.Debuff1Prio = false;

        -- the update timestamp
        self.LastAttribUpdate = D.Status.SpellsChanged;
        return self;
    end
end -- }}}



do
    local MicroFrameUpdateIndex = 1; -- MUFs are not updated all together
    local NumToShow, ActionsDone, Unit, MF, pass, UnitNum;
    -- updates the micro frames if needed (called regularly by ACE event, changed in the option menu)
    function D:DebuffsFrame_Update() -- {{{

        local Unit_Array = self.Status.Unit_Array;
        local UnitToGUID = self.Status.Unit_Array_UnitToGUID;

        UnitNum = self.Status.UnitNum; -- we need to go through all the units to set MF.ID properly
        NumToShow = ((MicroActionUnit.MaxUnit > UnitNum) and UnitNum or MicroActionUnit.MaxUnit);

        ActionsDone = 0; -- used to limit the maximum number of consecutive UI actions

        -- we don't check all the MUF at each call, only some of them (changed in the options)
        for pass = 1, self.profile.DebuffsFramePerUPdate do

            -- When all frames have been updated, go back to the first
            if (MicroFrameUpdateIndex > UnitNum) then
                MicroFrameUpdateIndex = 1;
                -- self:Debug("last micro frame updated,,:: %d", #self.Status.Unit_Array);
            end

            -- get a unit
            Unit = Unit_Array[MicroFrameUpdateIndex];

            -- should never fire unless the player choosed to ignore everything or something is wrong somewhere in the code
            if not Unit then
                --self:Debug("Unit is nil :/");
                return false;
            end

            -- get its MUF
            MF = MicroActionUnit.ExistingPerUNIT[Unit];

            -- if no MUF then create it (All MUFs are created here)
            if (not MF) then
                if not InCombatLockdown() then
                    MF = MicroActionUnit:Create(Unit, MicroFrameUpdateIndex);
                    ActionsDone = ActionsDone + 1;
                end
            end

--	    D:Debug("DebuffsFrame_Update for MF:", MF , "MF.ToPlace:", MF.ToPlace , "MicroFrameUpdateIndex:", MicroFrameUpdateIndex, "RS:", (MF and MF.ToPlace ~= MicroFrameUpdateIndex and not InCombatLockdown()));

            -- place the MUF ~right where it belongs~
            if MF and MF.ToPlace ~= MicroFrameUpdateIndex and not InCombatLockdown() then

                --sanity check
                --[[
                if MicroFrameUpdateIndex ~= MF.ID then
                D:AddDebugText("DebuffsFrame_Update(): MicroFrameUpdateIndex ~= MF.ID", MicroFrameUpdateIndex, MF.ID, Unit, MF.CurrUnit, "ToPlace:", MF.ToPlace);
                end
                --]]

                MF.ToPlace = MicroFrameUpdateIndex;

                MF.Frame:SetPoint(unpack(MicroActionUnit:GetMUFAnchor(MicroFrameUpdateIndex)));
                if MF.Shown then
                    MF.Frame:Show();
		    D:Debug("Showed a Frame");
                end

                -- test for GUID change and force a debuff update in this case
--[[                if UnitToGUID[MF.CurrUnit] ~= MF.UnitGUID then
                    MF.UpdateCountDown = 0; -- will force MF:Update() to be called
                    --[===[@debug@
                    --D:Println("|cFFFFAA55GUID change detected while placing for |r", MicroFrameUpdateIndex, UnitToGUID[MF.CurrUnit], MF.UnitGUID );
                    --@end-debug@]===]
                end
]]
                ActionsDone = ActionsDone + 1;
            end

            -- update the MUF attributes and its colors -- this is done by an event handler now (buff/debuff received...) except when the unit has a debuff and is in range
            if MF and MicroFrameUpdateIndex <= NumToShow then
                if not (MF.IsDebuffed or MF.IsCharmed) and MF.UpdateCountDown ~= 0 then
                    MF.UpdateCountDown = MF.UpdateCountDown - 1;
                else -- if MF.IsDebuffed or MF.IsCharmed or MF.UpdateCountDown == 0
                    ActionsDone = ActionsDone + MF:Update(false, true);--, not ((MF.IsDebuffed or MF.IsCharmed) and MF.UnitStatus ~= AFFLICTED)); -- we rescan debuffs if the unit is not in spell range XXX useless now since we rescan everyone every second
                    MF.UpdateCountDown = 3;
                end
            end

            -- we are done for this frame, go to te next
            MicroFrameUpdateIndex = MicroFrameUpdateIndex + 1;

            -- don't update more than 5 MUF in a row
            -- don't loop when reaching the end, wait for the next call (useful when less MUFs than PerUpdate)
            if (ActionsDone > 5 or pass == UnitNum) then
                --self:Debug("Max actions count reached");
                break;
            end

        end
        --    end
    end -- }}}
end

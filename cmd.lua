-- cmd.lua  从键位45开始的指令

local addonName, T = ...;
local D = T.jcc or {};

if true then return;end

D.supervisor = "黑手才才";
D.CMDSpellDescs = {
	["CMD1"] = {slot=45,marco="/follow 黑手才才\n/target 黑手才才"},
	--["CMD1"] = {slot=45,marco="/say ha"},
	["CMD2"] = {slot=44,marco="/targetenemy"},
	["CMD3"] = {slot=43,direct="INTERACTTARGET"},
};

-- CombatColorBingdings.lua

local addonName, T = ...;

local D = T.jcc;

--[[
		if ( IsShiftKeyDown() ) then
			keyPressed = "SHIFT-"..keyPressed;
		end
		if ( IsControlKeyDown() ) then
			keyPressed = "CTRL-"..keyPressed;
		end
		if ( IsAltKeyDown() ) then
			keyPressed = "ALT-"..keyPressed;
		end

		所以 优先级是ALT- CTRL- SHIFT-

APOSTROPHE = "'";
BACKSLASH = "\\";
BACKSPACE = "Backspace";
COMMA = ",";
DELETE = "Delete";
DOWN = "Down Arrow";
END = "End";
ENTER = "Enter";
ESCAPE = "Escape";
HOME = "Home";
INSERT = "Insert";
LEFT = "Left Arrow";
LEFTBRACKET = "[";
MINUS = "-";
MOUSEWHEELDOWN = "Mouse Wheel Down";
MOUSEWHEELUP = "Mouse Wheel Up";
NUMLOCK = "Num Lock";
NUMPAD0 = "Num Pad 0";
NUMPAD1 = "Num Pad 1";
NUMPAD2 = "Num Pad 2";
NUMPAD3 = "Num Pad 3";
NUMPAD4 = "Num Pad 4";
NUMPAD5 = "Num Pad 5";
NUMPAD6 = "Num Pad 6";
NUMPAD7 = "Num Pad 7";
NUMPAD8 = "Num Pad 8";
NUMPAD9 = "Num Pad 9";
NUMPADDECIMAL = "Num Pad .";
NUMPADDIVIDE = "Num Pad /";
NUMPADMINUS = "Num Pad -";
NUMPADMULTIPLY = "Num Pad *";
NUMPADPLUS = "Num Pad +";
PAGEDOWN = "Page Down";
PAGEUP = "Page Up";
PAUSE = "Pause";
PERIOD = ".";
PLUS = "+";
PRINTSCREEN = "Print Screen";
RIGHT = "Right Arrow";
RIGHTBRACKET = "]";
SCROLLLOCK = "Scroll Lock";
SEMICOLON = ";";
SLASH = "/";
SPACE = "Spacebar";
TAB = "Tab";
TILDE = "~";


ctrl shift 合计 47
F1-F12 12
a-z except c 25
小数字 0-9 10

ctrl alt 合计46
F1-F12 except F4 11
a-z except c 25
小数字 0-9 10

调整下顺序 避免alt+F4 Ctrl+c 之类的组合
Ctrl+shift 
Alt+Ctrl+shift 
Alt+Shift
Alt+Ctrl 有几个英文键无法使用

主体
F1-F12
a-z
num
0-9


语法实例
SetBinding("Y");SetBinding("Y","REPLY");SaveBindings(2);
]]

D.KeysToSlots={	
	"CTRL-SHIFT-F1",
	"CTRL-SHIFT-F2",
	"CTRL-SHIFT-F3",
	"CTRL-SHIFT-F4",
	"CTRL-SHIFT-F5",
	"CTRL-SHIFT-F6",
	"CTRL-SHIFT-F7",
	"CTRL-SHIFT-F8",
	"CTRL-SHIFT-F9",
	"CTRL-SHIFT-F10",
	"CTRL-SHIFT-F11",
	"CTRL-SHIFT-F12",
	"CTRL-SHIFT-b",
	"CTRL-SHIFT-e",
	"CTRL-SHIFT-f",
	"CTRL-SHIFT-g",
	"CTRL-SHIFT-h",
	"CTRL-SHIFT-i",
	"CTRL-SHIFT-j",
	"CTRL-SHIFT-k",
	"CTRL-SHIFT-l",
	"CTRL-SHIFT-m",
	"CTRL-SHIFT-n",
	"CTRL-SHIFT-o",
	"CTRL-SHIFT-p",
	"CTRL-SHIFT-q",
	"CTRL-SHIFT-r",
	"CTRL-SHIFT-t",
	"CTRL-SHIFT-v",
	"CTRL-SHIFT-u",
	"CTRL-SHIFT-x",
	"CTRL-SHIFT-y",
	"CTRL-SHIFT-z",
	"CTRL-SHIFT-NUMPAD0",
	"CTRL-SHIFT-NUMPAD1",
	"CTRL-SHIFT-NUMPAD2",
	"CTRL-SHIFT-NUMPAD3",
	"CTRL-SHIFT-NUMPAD4",
	"CTRL-SHIFT-NUMPAD5",
	"CTRL-SHIFT-NUMPAD6",
	"CTRL-SHIFT-NUMPAD7",
	"CTRL-SHIFT-NUMPAD8",
	"CTRL-SHIFT-NUMPAD9",
	"CTRL-SHIFT-NUMPADDECIMAL",--.
	"CTRL-SHIFT-NUMPADDIVIDE",-- /
	"CTRL-SHIFT-NUMPADMINUS",-- -
	"CTRL-SHIFT-NUMPADMULTIPLY",-- *
	"CTRL-SHIFT-NUMPADPLUS",-- +
	--"CTRL-SHIFT-0", http://support.microsoft.com/kb/967893
	"CTRL-SHIFT-1",
	"CTRL-SHIFT-2",
	"CTRL-SHIFT-3",
	"CTRL-SHIFT-4",
	"CTRL-SHIFT-5",
	"CTRL-SHIFT-6",
	"CTRL-SHIFT-7",
	"CTRL-SHIFT-8",
	"CTRL-SHIFT-9",
	--[[
	"ALT-CTRL-F1",
	"ALT-CTRL-F2",
	"ALT-CTRL-F3",
	"ALT-CTRL-F5",
	"ALT-CTRL-F6",
	"ALT-CTRL-F7",
	"ALT-CTRL-F8",
	"ALT-CTRL-F9",
	"ALT-CTRL-F10",
	"ALT-CTRL-F11",
	"ALT-CTRL-F12",
	"ALT-CTRL-b",
	"ALT-CTRL-e",
	"ALT-CTRL-f",
	"ALT-CTRL-g",
	"ALT-CTRL-h",
	"ALT-CTRL-i",
	"ALT-CTRL-j",
	"ALT-CTRL-k",
	"ALT-CTRL-l",
	"ALT-CTRL-m",
	"ALT-CTRL-n",
	"ALT-CTRL-o",
	"ALT-CTRL-p",
	"ALT-CTRL-q",
	"ALT-CTRL-r",
	"ALT-CTRL-t",
	"ALT-CTRL-v",
	"ALT-CTRL-u",
	"ALT-CTRL-x",
	"ALT-CTRL-y",
	"ALT-CTRL-z",
	]]
}
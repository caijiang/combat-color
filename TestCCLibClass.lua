-- TestCCLibClass.lua

print("Start Test");
local addonName, T = ...;
local D = T.jcc;

local A = T.jcc:NewModule("TestClassA", "AceEvent-3.0", "AceHook-3.0","CCClass-1.0");

A.oldParentMethod = A.ParentMethod;
function A:ParentMethod()
	D:Debug(" Class A  invoke my self method");
	A:oldParentMethod();
end

function A:CustomerMethod()
	D:Debug("Foo");
end

local B = T.jcc:NewModule("TestClassB", "AceEvent-3.0", "AceHook-3.0","CCClass-1.0");
B.oldParentMethod = B.ParentMethod;
function B:ParentMethod()
	D:Debug(" Class B  invoke my self method");
	B:oldParentMethod();
end
function B:CustomerMethod()
	D:Debug("Bar");
end

A.dummyVar = 1;
B.dummyVar = 2;

D:Debug("A ",A,A:GetDummyVar());
D:Debug("B ",B,B:GetDummyVar());

A:DummyMethod();
B:DummyMethod();

A:ParentMethod();
B:ParentMethod();

A:InvokeChildMethod();
B:InvokeChildMethod();

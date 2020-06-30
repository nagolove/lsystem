local referenceGuide = [[A: draw and move
B: draw and move
-: rotate left
+: rotate right
Examples of rules:
]]

local iterIntSlider = 5

local axiom = [[
A++A++A
]]

local rules = [[
A -> A-A++A-A
]]

local gr = love.graphics
local canvas = gr.newCanvas()
local inspect = require "inspect"
local ui = require "imgui"
local vec2 = require "vector"
local resultString

local function width()
    return gr.getWidth()
end

local function height()
    return gr.getHeight()
end

local Turtle = {}
Turtle.__index = Turtle

function Turtle:new(x, y, angle)
    local s = setmetatable({}, Turtle)
    s.x = x
    s.y = y
    s.dir = vec2.fromPolar(angle) * 3
    s:setColor1()
    print("dir length", s.dir:len())
    --print("self.dir", inspect(s.dir))
    return s
end

function Turtle:move()
    --print("move")
    self.x, self.y = self.x + self.dir.x, self.y + self.dir.y
end

function Turtle:rotateRight()
    --print("rotateRight")
    self.dir:rotateInplace(math.pi / 3)
end

function Turtle:rotateLeft()
    --print("rotateLeft")
    self.dir:rotateInplace(-math.pi / 3)
end

function Turtle:setColor1()
    self.color = {0, 1, 0, 1}
end

function Turtle:setColor2()
    self.color = {1, 0, 0, 1}
end

function Turtle:update(dt)
    if self.executor then
        --print("self.executor", inspect(self.executor))
        local ret = coroutine.resume(self.executor)
        if not ret then
            self.executor = nil
        end
    end
end

function parseRules(rules)
    local rulesTable = {}
    for s in string.gmatch(rules, "[^\n]+") do
        local from, to = string.match(s, "([^%s]+)%s*->%s*([^%s]+)")
        rulesTable[from] = to
    end
    return rulesTable
end

function rewrite(axiom, rulesTable, iterCount)
    --[[
    -- для начальной строки(аксиомы) слева на право применяются правила
    -- правило применяется так:
    --  для всех букв проходит цикл по строке
    --  для текущей буквы ищется правило замены
    --  если правило есть, то добавляется результат к буферу результата
    --]]
    print("rulesTable", inspect(rulesTable))
    local str = axiom
    local substrs = {}
    for i = 1, iterCount do
        for char in str:gmatch(".") do
            local newSeq = rulesTable[char]
            if newSeq then
                table.insert(substrs, rulesTable[char])
                print("char", char)
                print("rule", rulesTable[char])
            end
        end
        str = table.concat(substrs)
    end
    print("str", str)
    return str
end

function Turtle:body(axiom, rules, iterCount)
    local cmd = {
        ["A"] = self.move,
        ["B"] = self.move,
        ["+"] = self.rotateRight,
        ["-"] = self.rotateLeft,
        ["C"] = self.setColor1,
        ["D"] = self.setColor2,
    }

    local ok, msg = pcall(function()
        print("execCoro")
        local rulesTable = parseRules(rules)
        print("rulesTable", inspect(rulesTable))
        print("iterCount", iterCount)
        print("axiom", axiom)
        resultString = rewrite(axiom, rulesTable, iterCount)
        --print("str", str)
    end)

    for char in resultString:gmatch(".") do
        local command = cmd[char]
        if command then 
            command(self) 
        else
            print("no such command", char)
        end
        coroutine.yield()
    end

    print(ok, msg)
end

function Turtle:start(code, iterations)
    self.executor = coroutine.create(self.body)
    coroutine.resume(self.executor, self, axiom, rules, iterations)
end

function love.textinput(t)
    imgui.TextInput(t)
    if not imgui.GetWantCaptureKeyboard() then
        -- Pass event to the game
    end
end

function clearCanvas()
    gr.setCanvas(canvas)
    gr.clear{0, 0, 0, 0}
    gr.setCanvas()
end

function resetAndRun()
    turtle = Turtle:new(width() / 2, height() / 2, - 1 / 2 * math.pi)
    turtle:start(code, iterIntSlider)
    clearCanvas()
end

love.keypressed = function(_, k)
    ui.KeyPressed(k)
    if not ui.GetWantCaptureKeyboard() then
        if k == "space" then
            resetAndRun()
        end
    end
end

love.keyreleased = function(_, k)
    ui.KeyReleased(k)
    if not ui.GetWantCaptureKeyboard() then
    end
end

function love.mousemoved(x, y)
    ui.MouseMoved(x, y)
    if not ui.GetWantCaptureMouse() then
        -- Pass event to the game
    end
end

function love.mousepressed(x, y, button)
    ui.MousePressed(button)
    if not ui.GetWantCaptureMouse() then
        -- Pass event to the game
    end
end

function love.mousereleased(x, y, button)
    ui.MouseReleased(button)
    if not ui.GetWantCaptureMouse() then
        -- Pass event to the game
    end
end

function love.wheelmoved(x, y)
    ui.WheelMoved(y)
    if not ui.GetWantCaptureMouse() then
        -- Pass event to the game
    end
end

love.quit = function()
    local succ, msg
    succ, msg = love.filesystem.write("rules.txt", rules)
    succ, msg = love.filesystem.write("axiom.txt", axiom)
    ui.ShutDown()
end

love.load = function()
    turtle = Turtle:new(width() / 2, height() / 2, 0)
    local content, size
    content, size = love.filesystem.read("rules.txt")
    if content then
        rules = content
    end
    content, size = love.filesystem.read("axiom.txt")
    if content then
        axiom = content
    end
end

love.update = function(dt)
    ui.NewFrame()
    turtle:update(dt)
end

function drawTurtle()
    gr.setColor(turtle.color)
    gr.setPointSize(8)
    gr.points(turtle.x, turtle.y)
end

function setupWindow()
    ui.Begin("setup", true, { "ImGuiWindowFlags_AlwaysAutoResize" })
    iterIntSlider = ui.SliderInt("iterations", iterIntSlider, 1, 100)
    if ui.Button("run&reset") then
        resetAndRun()
    end
    ui.End()
end

function axiomWindow()
    ui.Begin("Axiom", false, { "ImGuiWindowFlags_AlwaysAutoResize" })
    axiom = ui.InputTextMultiline("InputText", axiom, 200, 300, 200);
    ui.End()
end

function rulesWindow()
    ui.Begin("L-system rules", false, { "ImGuiWindowFlags_AlwaysAutoResize" })
    rules = ui.InputTextMultiline("InputText", rules, 200, 300, 200);
    ui.End()
end

function resultStringWindow()
    --ui.Begin("Result string", true, { "ImGuiWindowFlags_AlwaysAutoResize" })
    ui.Begin("Result string", true)
    if resultString then
        local maxLen = 1000
        if #resultString > maxLen then
            local subResult = resultString:sub(1, maxLen)

            --[[
               [local t = {}
               [local maxWidth = 40
               [for i = 0, math.floor(#subResult / maxWidth) do
               [    table.insert(t, subResult:sub(i * maxWidth, i * maxWidth + maxWidth) .. "\n")
               [end
               [subResult = table.concat(t)
               ]]

            --_ = ui.InputTextMultiline("InputText", subResult, 200, 300, 100, { "ImGuiInputTextFlags_ReadOnly" });
            _ = ui.InputTextMultiline("InputText", subResult, 200, 300, 100, { "ImGuiInputTextFlags_ReadOnly" });
        end
    end
    ui.End()
end

function helpWindow()
    ui.Begin("Reference guide", true, { "ImGuiWindowFlags_AlwaysAutoResize" })
    _ = ui.InputTextMultiline("InputText", referenceGuide, 200, 300, 100, { "ImGuiInputTextFlags_ReadOnly" });
    ui.End()
end

love.draw = function()
    gr.setCanvas(canvas)
    gr.setColor{1, 1, 1, 1}
    --gr.clear{0, 0, 0, 0}
    drawTurtle()
    gr.setCanvas()
    gr.setColor{1, 1, 1, 1}

    gr.draw(canvas)

    setupWindow()
    rulesWindow()
    axiomWindow()
    helpWindow()
    --resultStringWindow()
    
    ui.Render()
end

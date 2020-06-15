local iterIntSlider = 5
local axiom = [[
AB
]]
local rules = [[
A -> -B+
B -> AB
]]
local gr = love.graphics
local canvas = gr.newCanvas()
local inspect = require "inspect"
local ui = require "imgui"
local vec2 = require "vector"

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
    print("dir length", s.dir:len())
    --print("self.dir", inspect(s.dir))
    return s
end

function Turtle:move()
    print("move")
    self.x, self.y = self.x + self.dir.x, self.y + self.dir.y
end

function Turtle:rotateRight()
    print("rotateRight")
    self.dir:rotateInplace(math.pi)
end

function Turtle:rotateLeft()
    print("rotateLeft")
    self.dir:rotateInplace(-math.pi)
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
    local str = axiom
    local substrs = {}
    for i = 1, iterCount do
        for char in str:gmatch(".") do
            table.insert(substrs, rulesTable[char])
            print("char", char)
            print("rule", rulesTable[char])
        end
        str = table.concat(substrs)
    end
    return str
end

function Turtle:execCoro(axiom, rules, iterCount)
    local cmd = {
        ["A"] = self.move,
        ["B"] = self.move,
        ["+"] = self.rotateRight,
        ["-"] = self.rotateLeft,
    }
    local str

    local ok, msg = pcall(function()
        print("execCoro")
        local rulesTable = parseRules(rules)
        print("rulesTable", inspect(rulesTable))
        print("iterCount", iterCount)
        print("axiom", axiom)
        str = rewrite(axiom, rulesTable, iterCount)
        print("str", str)
    end)

    for char in str:gmatch(".") do
        local command = cmd[char]
        if command then 
            command(self) 
        end
        coroutine.yield()
    end

    print(ok, msg)
end

function Turtle:execute(code, iterations)
    self.executor = coroutine.create(self.execCoro)
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
    turtle:execute(code, iterIntSlider)
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
    ui.ShutDown()
end

love.load = function()
    turtle = Turtle:new(width() / 2, height() / 2, 0)
end

love.update = function(dt)
    ui.NewFrame()
    turtle:update(dt)
end

function drawTurtle()
    gr.setColor{0, 1, 0}
    gr.setPointSize(8)
    gr.points(turtle.x, turtle.y)
end

function drawDocks()
    imgui.SetNextWindowPos(0, 0)
    imgui.SetNextWindowSize(love.graphics.getWidth(), love.graphics.getHeight())
    if imgui.Begin("DockArea", nil, { "ImGuiWindowFlags_NoTitleBar", "ImGuiWindowFlags_NoResize", "ImGuiWindowFlags_NoMove", "ImGuiWindowFlags_NoBringToFrontOnFocus" }) then
        imgui.BeginDockspace()

        -- Create 10 docks
        for i = 1, 10 do
            if imgui.BeginDock("dock_"..i) then
                imgui.Text("Hello, dock "..i.."!");
            end
            imgui.EndDock()
        end

        imgui.EndDockspace()
    end
    imgui.End()

    love.graphics.clear(0.2, 0.2, 0.2)
    imgui.Render();
end

love.draw = function()
    gr.setCanvas(canvas)
    gr.setColor{1, 1, 1, 1}
    --gr.clear{0, 0, 0, 0}
    drawTurtle()
    gr.setCanvas()
    gr.setColor{1, 1, 1, 1}

    gr.draw(canvas)

    ui.Begin("setup", true, { "ImGuiWindowFlags_AlwaysAutoResize" })
    iterIntSlider = ui.SliderInt("iterations", iterIntSlider, 1, 10)
    if ui.Button("run&reset") then
        resetAndRun()
    end
    ui.End()

    ui.Begin("Axiom", false, { "ImGuiWindowFlags_AlwaysAutoResize" })
    axiom = ui.InputTextMultiline("InputText", axiom, 200, 300, 200);
    ui.End()

    ui.Begin("L-system rules", false, { "ImGuiWindowFlags_AlwaysAutoResize" })
    rules = ui.InputTextMultiline("InputText", rules, 200, 300, 200);
    ui.End()

    --drawDocks()
    
    ui.Render()
end

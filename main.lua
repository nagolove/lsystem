local iterIntSlider = 1
local code = "A"
local ui = require "imgui"
local inspect = require "inspect"
print(inspect(ui))
local gr = love.graphics
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
    print("self:move")
    self.x, self.y = self.x + self.dir.x, self.y + self.dir.y
    return "AA"
end

function Turtle:rotateRight()
    self.dir:rotateInplace(math.pi * 3 / 4)
end

function Turtle:rotateLeft()
    self.dir:rotateInplace(-math.pi * 3 / 4)
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

function Turtle:execCoro(code, iterCount)
    local cmd = {
        ["A"] = self.move,
        ["+"] = self.rotateRight,
        ["-"] = self.rotateLeft
    }

    print("code", code)
    assert(type(code) == "string")

    print("iterCount", iterCount)

    while true do
        local newcode = {}

        for i = 1, code:len() do
            local char = string.sub(code, i, i)
            print("char", char)
            local rule = cmd[char]
            if rule then
                local new = rule(self)
                --print("new", new)
                if new then
                    assert(type(new) == "string")
                    table.insert(newcode, new)
                end
            end
            coroutine.yield()
        end

        code = table.concat(newcode)
        print("code", code)

        if iterCount < 1 then
            break
        end

        iterCount = iterCount - 1
    end
end

function Turtle:execute(code, iterations)
    self.executor = coroutine.create(self.execCoro)
    coroutine.resume(self.executor, self, code, iterations)
end

function love.textinput(t)
    imgui.TextInput(t)
    if not imgui.GetWantCaptureKeyboard() then
        -- Pass event to the game
    end
end

function resetAndRun()
    turtle = Turtle:new(width() / 2, height() / 2, - 1 / 2 * math.pi)
    turtle:execute(code, iterIntSlider)
end

love.keypressed = function(_, k)
    ui.KeyPressed(k)
    if not ui.GetWantCaptureKeyboard() then
        if k == "1" then
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

love.draw = function()
    drawTurtle()

    ui.Begin("setup", true, { "ImGuiWindowFlags_AlwaysAutoResize" })
    iterIntSlider = ui.SliderInt("iterations", iterIntSlider, 1, 10)
    if ui.Button("run&reset") then
        resetAndRun()
    end
    ui.End()

    ui.Begin("L-system code", false, { "ImGuiWindowFlags_AlwaysAutoResize" })
    code = ui.InputTextMultiline("InputText", code, 200, 300, 200);
       
    ui.End()
    
    ui.Render()
end

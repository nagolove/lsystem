local inspect = require "inspect"
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
    s.dir = vec2.fromPolar(angle)
    --print("self.dir", inspect(s.dir))
    return s
end

function Turtle:move()
    print("self:move")
    self.x, self.y = self.x + self.dir.x, self.y + self.dir.y
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

function Turtle:execCoro(code)
    local cmd = {
        ["A"] = self.move,
        ["+"] = self.rotateRight,
        ["-"] = self.rotateLeft
    }

    print("code", code)

    assert(type(code) == "string")
    for i = 1, code:len() do
        local char = string.sub(code, i, i)
        print("char", char)
        local command = cmd[char]
        if command then
            command(self)
        end
        coroutine.yield()
    end
end

function Turtle:execute(code)
    self.executor = coroutine.create(self.execCoro)
    coroutine.resume(self.executor, self, code)
end

love.keypressed = function(_, k)
    if k == "1" then
        turtle = Turtle:new(width() / 2, height() / 2, 0)
        turtle:execute("A+A-")
    end
end

love.load = function()
    turtle = Turtle:new(width() / 2, height() / 2, 0)
end

love.update = function(dt)
    turtle:update(dt)
end

love.draw = function()
    gr.setColor{0, 1, 0}
    gr.setPointSize(8)
    gr.points(turtle.x, turtle.y)
end

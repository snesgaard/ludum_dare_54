nw = require "nodeworks"
event = nw.system.event
stack = nw.ecs.stack
collision = nw.system.collision
painter = require "painter"

decorate(nw.component, require "component", true)

constant = require "constant"
physics = require "system.physics"
tf = require "system.tf"
time = nw.system.time
clock = time.clock
timer = time.timer
camera = require "system.camera"

function assemble(l, id)
    stack.assemble(l, id)
    return id
end

function default_collision_filter(item, other)
    if stack.get(nw.component.ghost, item) then return "cross" end
    --if stack.get(nw.component.being_dragged, item) then return "cross" end

    return "slide"
end

local function spin()
    while 0 < event.spin() do
        time.spin()
        collision.spin()
        physics.spin()
        camera.spin()
    end
end

local central_shape = spatial(gfx.getWidth() / 2, gfx.getHeight() / 2, 0, 0):expand(500, 500)

local function spawn(x, y)
    local w = love.math.random(1, 3) * 16
    local h = love.math.random(1, 3) * 16
    stack.assemble(
        {
            {nw.component.hitbox, spatial():expand(w, h):unpack()},
            {nw.component.position, x, y},
            {nw.component.velocity}
        },
        nw.ecs.id.strong("box")
    )
end

function love.load()
    collision.set_default_filter(default_collision_filter)

    stack.assemble(
        {
            {nw.component.hitbox, central_shape:up():unpack()},
            {nw.component.position, 0, 0}
        },
        nw.ecs.id.strong("wall")
    )
    stack.assemble(
        {
            {nw.component.hitbox, central_shape:down():unpack()},
            {nw.component.position, 0, 0}
        },
        nw.ecs.id.strong("wall")
    )
    stack.assemble(
        {
            {nw.component.hitbox, central_shape:left():unpack()},
            {nw.component.position, 0, 0}
        },
        nw.ecs.id.strong("wall")
    )
    stack.assemble(
        {
            {nw.component.hitbox, central_shape:right():unpack()},
            {nw.component.position, 0, 0}
        },
        nw.ecs.id.strong("wall")
    )

    stack.assemble(
        {
            {nw.component.position, gfx.getWidth() / 2, gfx.getHeight() / 2},
            {nw.component.origin_offset, gfx.getWidth() / 2, gfx.getHeight() / 2}
        },
        constant.id.camera
    )
end

function love.update(dt)
    event.emit("update", dt)
    spin()
end

function love.draw()
    gfx.push()
    gfx.applyTransform(tf.entity(constant.id.camera):inverse())
    collision.draw()
    gfx.pop()

    gfx.push("all")
    if physics.converged_in_area(0, 0, gfx.getWidth(), gfx.getHeight()) then
        gfx.setColor(0, 1, 0.5)
    else
        gfx.setColor(1, 0, 0)
    end
    gfx.rectangle("fill", 0, 0, 30, 30)
    gfx.pop()
end

function love.mousepressed(x, y)
    local t = tf.entity(constant.id.camera)
    local x, y = t:transformPoint(x, y)
    spawn(x, y)
end

function love.keypressed(key)
    event.emit("keypressed", key)
    if key == "r" and camera.rotate_counter_clockwise() then
        physics.rotate_gravity_counter_clockwise()
    end
    if key == "escape" then love.event.quit() end
    if key == "right" then collision.move(constant.id.camera, 10, 0) end
    if key == "down" then collision.move(constant.id.camera, 0, 10) end
end
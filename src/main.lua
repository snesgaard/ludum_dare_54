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
drag_and_drop = require "system.drag_and_drop"
level = require "system.level"
sound = require "system.sound"
main_menu = require "system.main_menu"

require "drawable"

function assemble(l, id)
    stack.assemble(l, id)
    return id
end

function default_collision_filter(item, other)
    if stack.get(nw.component.ghost, item) then return "cross" end
    if stack.get(nw.component.ghost, other) then return "cross" end
    if stack.get(nw.component.disable_physics, item) then return "cross" end
    if stack.get(nw.component.disable_physics, other) then return "cross" end
    --if stack.get(nw.component.being_dragged, item) then return "cross" end
    if level.is_glitch_mode() then
        return "slide"
    else
        return "better_slide"
    end
end

local function spin()
    while 0 < event.spin() do
        time.spin()
        collision.spin()
        drag_and_drop.spin()
        physics.spin()
        camera.spin()
        sound.spin()
        level.spin()
        nw.system.particles.spin()
        main_menu.spin()
    end

end

local function spawn(x, y)
    local w = love.math.random(1, 1) * 32   
    local h = love.math.random(1, 1) * 32   
    stack.assemble(
        {
            {nw.component.hitbox, spatial():expand(w, h):unpack()},
            {nw.component.position, x, y},
            {nw.component.velocity},
            {nw.component.drawable, nw.drawable.hitbox}
        },
        nw.ecs.id.strong("box")
    )
end

function love.load()
    
    local cx, cy = gfx.getWidth() / 2, gfx.getHeight() / 2
    
    level.init()
end

function love.update(dt)
    event.emit("update", dt)
    spin()
end

function love.draw()
    gfx.push()
    gfx.applyTransform(tf.entity(constant.id.camera))
    painter.draw()
    if draw_collision then collision.draw() end
    gfx.pop()

    painter.draw_ui()
end

function love.mousepressed(x, y, button)
    event.emit("mousepressed", x, y, button)
end

function love.mousemoved(x, y, dx, dy)
    event.emit("mousemoved", x, y, dx, dy)
end

function love.mousereleased(x, y, button)
    event.emit("mousereleased", x, y, button)
end

function love.keypressed(key)
    event.emit("keypressed", key)
    if (key == "q" or key == "left") and camera.rotate_clockwise() then
        if level.is_glitch_mode() then
            physics.rotate_gravity_counter_clockwise()
        else
            physics.rotate_gravity_clockwise()
        end
        level.increment_move_counter()
    end
    if (key == "e" or key == "right") and camera.rotate_counter_clockwise() then
        if level.is_glitch_mode() then
            physics.rotate_gravity_clockwise()
        else
            physics.rotate_gravity_counter_clockwise()
        end
        level.increment_move_counter()
    end
    if key == "escape" then love.event.quit() end
    if key == "c" then draw_collision = not draw_collision end
    if (key == "return" or key == "space") and level.is_complete() then
        level.load_next()
    end
    --if key == "right" then collision.move(constant.id.camera, 10, 0) end
    --if key == "down" then collision.move(constant.id.camera, 0, 10) end
end
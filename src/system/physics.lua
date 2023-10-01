local physics = {
    id = "__physics__", default_gravity = vec2(0, 2000)
}

function physics.set_gravity(gx, gy)
    stack.set(nw.component.gravity, physics.id, gx, gy)
end

function physics.get_gravity()
    return stack.ensure(
        nw.component.gravity, physics.id, physics.default_gravity:unpack()
    )
end

function physics.update_velocity(dt)
    local g = physics.get_gravity()

    for id, v in stack.view_table(nw.component.velocity) do
        if not stack.get(nw.component.disable_physics, id) then
            v.x = v.x + g.x * dt
            v.y = v.y + g.y * dt
        end
    end
end

function physics.update_position(dt)
    for id, v in stack.view_table(nw.component.velocity) do
        if not stack.get(nw.component.disable_physics, id) then
            collision.move(id, v.x * dt, v.y * dt)
        end
    end
end

function physics.update_glitch_mode(dt)
    if not level.is_glitch_mode() then return end

    local m = 5 * 60 * dt
    for id, _ in stack.view_table(nw.component.velocity) do
        local dx = love.math.random(-m, m)
        local dy = love.math.random(-m, m)
        collision.move(id, dx, dy)
    end
end

function physics.update(dt)
    physics.update_velocity(dt)
    physics.update_position(dt)
    physics.update_glitch_mode(dt)
end

local function null_velocity(id, nx, ny)
    local v = stack.get(nw.component.velocity, id)
    if not v then return 0 end
    local d = math.min(0, v.x * nx + v.y * ny)  
    v.x = v.x - nx * d
    v.y = v.y - ny * d

    return d
end

function physics.handle_collision(colinfo)
    if colinfo.type ~= "slide" and colinfo.type ~= "touch" then return end
    local item_d = null_velocity(colinfo.item, colinfo.normal.x, colinfo.normal.y)
    local other_d = null_velocity(colinfo.other, -colinfo.normal.x, -colinfo.normal.y)
    event.emit("impact", colinfo.item, colinfo.other, math.max(math.abs(item_d), math.abs(other_d)))
end

function physics.spin()
    for _, dt in event.view("update") do physics.update(dt) end

    for _, _, _, collisions in event.view("move") do
        for _, colinfo in ipairs(collisions) do
            physics.handle_collision(colinfo)
        end
    end
end

function physics.cancel_velocity()
    for _, v in stack.view_table(nw.component.velocity) do
        v.x = 0
        v.y = 0
    end
end

function physics.converged()
    for _, v in stack.view_table(nw.component.velocity) do
        if v.x * v.x + v.y * v.y > 1 then return false end
    end

    return true
end

function physics.converged_in_area(x, y, w, h)
    local entities = collision.query(spatial(x, y, w, h))
    for _, id in ipairs(entities) do
        local v = stack.get(nw.component.velocity, id)
        if v and (v.x * v.x + v.y * v.y > 1) then return false end
    end

    return true
end

function physics.enable(id, yes)
    if not yes then
        stack.set(nw.component.disable_physics, id)
        stack.set(nw.component.velocity, id, 0, 0)
    else
        stack.remove(nw.component.disable_physics, id)
    end
end

function physics.rotate_gravity_counter_clockwise()
    physics.cancel_velocity()
    local g = physics.get_gravity()
    physics.set_gravity(g.y, -g.x)
end

function physics.rotate_gravity_clockwise()
    physics.cancel_velocity()
    local g = physics.get_gravity()
    physics.set_gravity(-g.y, g.x)
end

return physics
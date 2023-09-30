local camera = {}

function camera.update(dt)
    for id, angle_ease in stack.view_table(nw.component.angle_ease) do
        local t, d = timer.get(angle_ease.timer)
        local t = math.min(t, d)
        local a = ease.linear(t, angle_ease.from, angle_ease.to - angle_ease.from, d)
        stack.set(nw.component.angle, id, a)
    end
end

function camera.spin()
    for _, dt in event.view("update") do
        camera.update(dt)
    end
end

function camera.get_angle()
    return stack.get(nw.component.angle, constant.id.camera) or 0
end

function camera.is_rotation()
    local ae = stack.get(nw.component.angle_ease, constant.id.camera)
    return ae and not timer.is_done(ae.timer)
end

function camera.rotate_clockwise()
    if camera.is_rotation() then return false end

    local a = camera.get_angle()
    stack.set(nw.component.angle_ease, constant.id.camera, a, a + math.pi / 2)

    return true
end

function camera.rotate_counter_clockwise()
    if camera.is_rotation() then return false end

    local a = camera.get_angle()
    stack.set(nw.component.angle_ease, constant.id.camera, a, a - math.pi / 2)

    return true
end

return camera
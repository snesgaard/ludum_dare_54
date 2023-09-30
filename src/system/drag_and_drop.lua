local drag_and_drop = {}

function drag_and_drop.camera_to_world(x, y)
    return tf.entity(constant.id.camera):transformPoint(x, y)
end

function drag_and_drop.get_relative_to_camera(id)
    local camera = tf.entity(constant.id.camera)
    local t = tf.entity(id)

    return camera:inverse() * t
end

function drag_and_drop.mousemoved(x, y)
    local x, y = drag_and_drop.camera_to_world(x, y)
    local rx = math.floor(x / 16) * 16
    local ry = math.floor(y / 16) * 16

    for id, t in stack.view_table(nw.component.being_dragged) do
        collision.move_to(id, t:inverse():transformPoint(x, y))
    end
end

function drag_and_drop.mousepressed(x, y, button)
    local x, y = drag_and_drop.camera_to_world(x, y)
    local query = spatial(x, y):expand(2, 2)
    local objects = collision.query(query)
    for _, id in ipairs(objects) do
        if stack.get(nw.component.draggable, id) then
            local t = tf.entity(id)
            stack.set(nw.component.being_dragged, id, t:inverse():transformPoint(x, y))
        end
    end
end

function drag_and_drop.mousereleased(x, y, button)
    for _, id in ipairs(stack.get_table(nw.component.being_dragged):keys()) do
        stack.remove(nw.component.being_dragged, id)
    end
end

function drag_and_drop.spin()
    for _, x, y, button in event.view("mousepressed") do
        drag_and_drop.mousepressed(x, y, button)
    end

    for _, x, y in event.view("mousemoved") do
        drag_and_drop.mousemoved(x, y)
    end

    for _, x, y, button in event.view("mousereleased") do
        drag_and_drop.mousereleased(x, y, button)
    end
end

return drag_and_drop
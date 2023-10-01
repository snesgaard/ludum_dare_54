local tf = {}

local function infer_mirror(mirror, mirror_override)
    if mirror_override ~= nil then return mirror_override end
    return mirror
end

function tf.transform(x, y, r, sx, sy, ox, oy)
    return love.math.newTransform(
        x or 0, y or 0, r or 0, sx or 1, sy or 1, ox or 0, oy or 0
    )
end

function tf.entity(id, mirror_override)
    local p = stack.get(nw.component.position, id) or vec2()
    local s = stack.get(nw.component.scale, id)
    local a = stack.get(nw.component.angle, id) or 0
    local o = stack.get(nw.component.origin_offset, id) or vec2()
    return tf.transform(p.x, p.y, a, s or 1, s or 1, o.x, o.y)
end

function tf.between(from, to)
    local t_from = tf.entity(from)
    local t_to = tf.entity(to)
    return t_to * t_from:inverse()
end

function tf.transform_vec2(t, v)
    return vec2(t:transformPoint(v.x, v.y))
end

function tf.transform_velocity(t, vx, vy)
    local vx, vy = t:transformPoint(vx, vy)
    local ox, oy = t:transformPoint(0, 0)
    return vx - ox, vy - oy
end

function tf.transform_rectangle(t, x, y, w, h)
    local x1, y1 = t:transformPoint(x, y)
    local x2, y2 = t:transformPoint(x + w, y + h)

    local x = math.min(x1, x2)
    local y = math.min(y1, y2)
    local w = math.abs(x2 - x1)
    local h = math.abs(y2 - y1)

    return x, y, w, h
end

function tf.transform_origin(t)
    return t:transformPoint(0, 0)
end

return tf
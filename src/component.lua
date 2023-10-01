local component = {}

component.movegroup = nw.component.relation(function(id) return id or "unknown" end)

function component.gravity(gx, gy)
    return vec2(gx, gy)
end

function component.ghost() return true end

function component.angle(a) return a or 0 end

function component.angle_ease(from, to, duration)
    return {
        from = from,
        to = to,
        timer = assemble(
            {
                {nw.component.timer, duration or 0.2}
            },
            nw.ecs.id.weak("timer")
        )
    }
end

function component.origin_offset(ox, oy) return vec2(ox, oy) end

function component.draggable() return true end

function component.being_dragged(x, y)
    return tf.transform(x, y)
end

function component.disable_physics() return true end

function component.scale(s) return s or 1 end

function component.ui_world() return true end

function component.hidden(v) return v end

function component.tilelayer(l) return l end

function component.layer(index) return index end

function component.is_goal() return true end

function component.is_piece() return true end

function component.loaded_map(path, map)
    return {
        path = path,
        map = map
    }
end

function component.is_complete() return true end

return component
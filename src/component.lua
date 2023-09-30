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

return component
local nw = require "nodeworks"

function nw.drawable.tilelayer(id)
    local layer = stack.get(nw.component.tilelayer, id)
    if not layer then return end

    gfx.push("all")
    
    nw.drawable.push_transform(id)
    nw.drawable.push_state(id)
    layer:draw()

    gfx.pop()
end

function nw.drawable.frame(id)
    local frame = stack.get(nw.component.frame, id)
    if not frame then return end

    gfx.push("all")

    nw.drawable.push_transform(id)
    nw.drawable.push_state(id)
    frame:draw()

    gfx.pop()
end
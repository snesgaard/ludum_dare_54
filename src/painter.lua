local constant = require "constant"

local painter = {}

painter.cache_font = {}

function painter.font(size)
    local path = "art/font/m5x7.ttf"
    painter.cache_font[size] = painter.cache_font[size] or gfx.newFont(path, size, "mono")
    return painter.cache_font[size]
end

local function remove_hidden(id)
    return not stack.get(nw.component.hidden, id)
end

local function sort_drawers(a, b)
    local layer_a = stack.get(nw.component.layer, a) or 0
    local layer_b = stack.get(nw.component.layer, b) or 0

    if layer_a ~= layer_b then return layer_a < layer_b end

    local pos_a = stack.ensure(nw.component.position, a)
    local pos_b = stack.ensure(nw.component.position, b)

    return pos_a.x < pos_b.x
end

local function draw_entity(ids)
    for _, id in ipairs(ids) do
        local drawable = stack.get(nw.component.drawable, id)
        if drawable then drawable(id) end
    end
end


function painter.draw()
    gfx.push()

    stack.get_table(nw.component.drawable)
        :keys()
        :filter(remove_hidden)
        :sort(sort_drawers)
        :visit(draw_entity)
    
    gfx.pop()
end

local win_frame = get_atlas("art/characters"):get_frame("win_screen/stage")

local particle_image = gfx.prerender(12, 8, function(w, h)
    local rx, ry = w / 2, h / 2
    gfx.ellipse("fill", rx, rx, rx, ry)
end)

local function get_red_color_ramp()
    return {
        gfx.hex2color("d91981"),
        gfx.hex2color("770e5f"),
        gfx.hex2color("5b0a56"),
        gfx.hex2color("340536"),
        gfx.hex2color("27042300")
    }
end

local function get_green_color_ramp()
    return {
        gfx.hex2color("cdf204"),
        gfx.hex2color("1b9a03"),
        gfx.hex2color("038549"),
        gfx.hex2color("046120"),
        gfx.hex2color("02463c")
    }
end

local function get_blue_color_ramp()
    return {
        gfx.hex2color("93c4d9"),
        gfx.hex2color("4a77be"),
        gfx.hex2color("366ba9"),
        gfx.hex2color("2c329e"),
        gfx.hex2color("242b66")
    }
end

local function get_color_ramp()
    local r = love.math.random()
    if r < 0.33 then
        return get_red_color_ramp()
    elseif r < 0.66 then
        return get_blue_color_ramp()
    else
        return get_green_color_ramp()
    end
end

local function particle_args(name, slice, slice_data, color_ramp)
    return {
        image = particle_image,
        buffer = 20,
        emit = 20,
        pos = {slice:center():unpack()},
        lifetime = {5, 10},
        speed = {100, 600},
        damp = 2,
        area = {"uniform", slice.w / 2, slice.h / 2},
        acceleration = {0, 200},
        spread = math.pi * 0.3,
        dir = slice_data.angle,
        spin = 10.0,
        rotation = {0, math.pi},
        color = color_ramp
    }
end

local function particle_effects(color_ramp)
    local particle_entities = {}
    
    local color_ramp = color_ramp or get_red_color_ramp()
    for name, slice in pairs(win_frame.slices) do
        local slice_data = win_frame.slice_data[name] or {}
        local id = assemble(
            {
                {nw.component.particles, particle_args(name, slice, slice_data, color_ramp)}
            },
            nw.ecs.id.weak("particles")
        )
        table.insert(particle_entities, id)
    end

    return particle_entities
end

local function particle_effects_red()
    return particle_effects(get_red_color_ramp())
end

local function particle_effects_blue()
    return particle_effects(get_blue_color_ramp())
end

local function particle_effects_green()
    return particle_effects(get_green_color_ramp())
end

local function draw_particles()
    local comps = {
        particle_effects_red,
        particle_effects_green,
        particle_effects_blue
    }

    for _, c in ipairs(comps) do
        local particles = stack.ensure(c, constant.id.painter)
        for _, id in ipairs(particles) do
            local p = stack.get(nw.component.particles, id)
            if p then gfx.draw(p, 0, 0) end
        end
    end
end

local DEFAULT_OPT = {
    align = "center",
    valign = "center",
    scale = constant.scale,
    font = painter.font(64)
}

local function compute_valign(text, font, w, h, scale, valign)
    local _, segs = font:getWrap(text, w / scale)
    local th = #segs * font:getHeight() * scale
    if valign == "center" then
        return (h  - th) * 0.5
    elseif valign == "bottom" then
        return h - th
    end

    return 0
end

function painter.draw_text(text, area, opt)
    local opt = opt or DEFAULT_OPT
    local align = opt.align or DEFAULT_OPT.align
    local valign = opt.valign or DEFAULT_OPT.valign
    local s = opt.scale or DEFAULT_OPT.scale
    local font = opt.font or DEFAULT_OPT.font
    local dy = compute_valign(text, font, area.w, area.h, 1.0 / s, valign)
    gfx.printf(
        text, font, area.x, area.y + dy,
        area.w * s, align,
        0, 1.0 / s, 1.0 / s
    )
end

local main_gui = get_atlas("art/characters"):get_frame("main_gui")

local function draw_move_counter()
    local slice = main_gui.slices.move_counter
    if not slice then return end
    painter.draw_text(level.get_move_counter(), slice)
end

local function draw_main_gui()
    main_gui:draw()
    draw_move_counter()
end

local game_win_frame = get_atlas("art/characters"):get_frame("win_screen/game")

local function draw_game_win()
    game_win_frame:draw()
    local slice = game_win_frame.slices.wintext
    if not slice then return end
    painter.draw_text(level.get_move_counter(), slice)
end

local main_menu_frame = get_atlas("art/characters"):get_frame("main_menu")
local function draw_main_menu()
    local s = main_menu.get_state()
    local slice = main_menu_frame.slices[s.selected]
    if slice then 
        gfx.setColor(0.8, 1, 0.2)
        gfx.rectangle("fill", slice:unpack(5))
    end
    gfx.setColor(1, 1, 1)
    main_menu_frame:draw()
end

function painter.draw_ui()
    gfx.push("all")
    gfx.scale(constant.scale, constant.scale)

    if level.is_on_main_menu() then
        draw_main_menu()
    elseif not level.is_game_complete() then
        draw_main_gui()
        
        if level.is_complete() then
            local w, h = gfx.getWidth(), gfx.getHeight()
            local cx, cy = w / 2, h / 2

            gfx.setColor(1, 1, 1)
            win_frame:draw()
            draw_particles()
        end
    else
        draw_game_win()
    end

    gfx.pop()
end

return painter
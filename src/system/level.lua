local sti = nw.third.sti

local level_ordering = {
    "art/maps/build/level0.lua",
    "art/maps/build/level1.lua",
    "art/maps/build/level2.lua",
    "art/maps/build/level3.lua",
    "art/maps/build/level4.lua",
    "art/maps/build/level5.lua",
    "art/maps/build/level6.lua",
}

local level = {}

local loaders = {}

function loaders.goal(obj)
    stack.assemble(
        {
            {nw.component.drawable, nw.drawable.hitbox},
            {nw.component.hitbox, 0, 0, obj.width, obj.height},
            {nw.component.position, obj.x, obj.y},
            {nw.component.color, 0.2, 0.8, 0.6},
            {nw.component.ghost},
            {nw.component.layer, 1000},
            {nw.component.is_goal}
        },
        obj.id
    )
end

local function frame_from_size(w, h)
    local a = get_atlas("art/characters")

    if w == 32 and h == 32 then
        return a:get_frame("floppydisk")
    elseif w == 64 and h == 64 then
        return a:get_frame("letter")
    elseif w == 32 and h == 64 then
        return a:get_frame("trash")
    end

    errorf("Wrong size %i, %i", w, h)
end

function loaders.spawn(obj)
    stack.assemble(
        {
            {nw.component.drawable, nw.drawable.frame},
            {nw.component.hitbox, 0, 0, obj.width, obj.height},
            {nw.component.position, obj.x, obj.y},
            {nw.component.velocity},
            {nw.component.frame, frame_from_size(obj.width, obj.height)},
            {nw.component.is_piece}
        },
        obj.id
    )
end

local function spawn_tile(x, y, w, h, tile)
    return assemble(
        {
            {nw.component.hitbox, x, y, w, h}
        },
        nw.ecs.id.weak("id")
    )
end

local function load_tilelayer(index, layer)
    if layer.type ~= "tilelayer" then return end

    layer.tile_ids = list()

    for y, row in pairs(layer.data) do
        for x, tile in pairs(row) do
            local id = spawn_tile(
                (x - 1) * tile.width, (y - 1) * tile.height, tile.width, tile.height, tile
            )
            table.insert(layer.tile_ids, id)
        end
    end

    stack.assemble(
        {
            {nw.component.layer, index},
            {nw.component.tilelayer, layer},
            {nw.component.drawable, nw.drawable.tilelayer},
            {nw.component.hidden, not layer.visible},
        },
        layer
    )
end

local function load_objectgroup(index, layer)
    if layer.type ~= "objectgroup" then return end

    for _, obj in ipairs(layer.objects) do
        local f = loaders[obj.type]
        if f then f(obj) end
    end
end

function level.load(path)
    local map = sti(path)

    for index, layer in ipairs(map.layers) do
        load_tilelayer(index, layer)
        load_objectgroup(index, layer)
    end

    stack.set(nw.component.loaded_map, constant.id.level, path, map)

    return map
end

local function nil_filter() return "cross" end
function level.is_complete()
    if stack.get(nw.component.is_complete, constant.id.level) then return true end

    local touching_goals = dict()

    for id, _ in stack.view_table(nw.component.is_goal) do
        local _, _, cols = collision.move(id, 0, 0, nil_filter)
    
        for _, colinfo in ipairs(cols) do touching_goals[colinfo.other] = true end
    end

    for id, _ in stack.view_table(nw.component.is_piece) do
        if not touching_goals[id] then return false end
    end

    stack.set(nw.component.is_complete, constant.id.level)
    event.emit("level_complete")

    return true
end

local function find_level_index()
    local loaded_map = stack.get(nw.component.loaded_map, constant.id.level)
    if not loaded_map then return 0 end
    return List.argfind(level_ordering, loaded_map.path) or 0
end

function level.load_next()
    local index = find_level_index()
    local next_index = index + 1
    local path = level_ordering[next_index]
    if not path then return false end
    stack.reset()

    collision.set_default_filter(default_collision_filter)
    local map = level.load(path)
    level.setup_camera(map)
    return true
end

function level.is_loaded()
    return stack.has(nw.component.loaded_map, constant.id.level)
end

function level.setup_camera(map)
    local cx, cy = gfx.getWidth() / 2, gfx.getHeight() / 2
    
    local w = map.width * map.tilewidth
    local h = map.height * map.tileheight

    stack.assemble(
        {
            --{nw.component.position, -cx * constant.scale, -cy * constant.scale},
            {nw.component.position, cx, cy},
            {nw.component.scale, constant.scale},
            {nw.component.origin_offset, w / 2, h / 2} 
        },
        constant.id.camera
    )
end



function level.spin()
    for _, dt in event.view("update") do
        --if level.is_loaded() and level.is_complete() then return level.load_next() end
    end
end

return level
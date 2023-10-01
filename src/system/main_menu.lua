local main_menu = {}

local options = {
    "normal_mode",
    "glitch_mode",
    "quit"
}

function main_menu.get_state()
    return stack.ensure(nw.component.main_menu_state, constant.id.level)
end

function main_menu.next_option()
    local s = main_menu.get_state()
    local i = List.argfind(options, s.selected) or 1
    s.selected = options[i + 1] or List.head(options)
    event.emit("rotate_camera", true)
end

function main_menu.prev_option()
    local s = main_menu.get_state()
    local i = List.argfind(options, s.selected) or 1
    s.selected = options[i - 1] or List.tail(options)
    event.emit("rotate_camera", false)
end

function main_menu.enter()
    local s = main_menu.get_state()
    s.activated = true
end

function main_menu.keypressed(key)
    if key == "up" then
        main_menu.prev_option()
    elseif key == "down" then
        main_menu.next_option()
    elseif key == "return" or key == "space" then
        main_menu.enter()
    end
end

function main_menu.handle_activate()
    local s = main_menu.get_state()
    if not s.activated then return end
    if s.selected == "normal_mode" then
        level.load_next()
    elseif s.selected == "glitch_mode" then
        level.set_glitch_mode(true)
        level.load_next()
    else
        love.event.quit()
    end
end

function main_menu.spin()
    if not level.is_on_main_menu() then return end

    for _, key in event.view("keypressed") do
        main_menu.keypressed(key)
    end

    main_menu.handle_activate()
end

return main_menu
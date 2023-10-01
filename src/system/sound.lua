local sources = {
    impact = love.audio.newSource("sound/boom.wav", "static"),
    rotate = love.audio.newSource("sound/rotate.wav", "static"),
    rotate_cc = love.audio.newSource("sound/rotate_cc.wav", "static"),
    win = love.audio.newSource("sound/level_complete.wav", "static"),
    bgm = love.audio.newSource("sound/music2.mp3", "static"),
}

local sound = {}

function sound.on_rotate(clockwise)
    local s = clockwise and sources.rotate_cc or sources.rotate

    s:stop()
    s:play()
end

function get_threshold_impact()
    if level.is_glitch_mode() then
        return love.math.random(0, 240)
    else
        return 100
    end
end

function sound.on_impact(item, other, magnitude)
    if magnitude < get_threshold_impact() then return end
    sources.impact:stop()
    sources.impact:play()
end

function sound.on_win()
    sources.win:stop()
    sources.win:play()
end

function sound.spin()
    if not sources.bgm:isPlaying() then
        sources.bgm:setLooping(true)
        sources.bgm:play()
    end

    for _, item, other, magnitude in event.view("impact") do
        sound.on_impact(item, other, magnitude)
    end

    for _, clockwise in event.view("rotate_camera") do
        sound.on_rotate(clockwise)
    end

    for _, _ in event.view("level_complete") do
        sound.on_win()
    end
end

return sound
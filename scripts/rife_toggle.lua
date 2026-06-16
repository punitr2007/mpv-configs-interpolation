-- Press Ctrl+I to toggle RIFE interpolation on/off
-- Press Ctrl+M to open the RIFE settings menu overlay
local rife_active = false
local menu_active = false

-- Default settings
local settings = {
    model = 9,
    gpu_id = 1,
    gpu_thread = 2,
    sc = true,
    factor_num = 2,
    factor_den = 1,
    downscale_width = 1280
}

local options = {
    { name = "Status", values = { "OFF", "ON" } },
    { name = "Model", values = { 5, 9, 23, 37, 65, 72 }, labels = { "v2.3 (Fast)", "v3.9 (Fast)", "v4.6", "v4.12-lite", "v4.22-lite", "v4.26 (Latest)" } },
    { name = "GPU Device", values = { 1, 0 }, labels = { "NVIDIA (GPU 1)", "AMD Radeon (GPU 0)" } },
    { name = "GPU Threads", values = { 1, 2, 4 } },
    { name = "Scene Detect", values = { true, false }, labels = { "On", "Off" } },
    { name = "Downscale", values = { 0, 1280, 960 }, labels = { "None (Full Res)", "720p (1280w)", "540p (960w)" } },
    { name = "Framerate", values = { 2, 4 }, labels = { "2x", "4x" } }
}

local selected_index = 1

-- Load settings from rife_settings.json
local function load_settings()
    local path = mp.find_config_file("rife_settings.json")
    if not path then return end
    local file = io.open(path, "r")
    if file then
        local content = file:read("*all")
        file:close()
        -- Basic patterns to parse simple JSON entries
        local model = tonumber(content:match('"model":%s*(%d+)'))
        local factor_num = tonumber(content:match('"factor_num":%s*(%d+)'))
        local factor_den = tonumber(content:match('"factor_den":%s*(%d+)'))
        local gpu_id = tonumber(content:match('"gpu_id":%s*(%d+)'))
        local gpu_thread = tonumber(content:match('"gpu_thread":%s*(%d+)'))
        local sc_str = content:match('"sc":%s*(%a+)')
        local downscale_width = tonumber(content:match('"downscale_width":%s*(%d+)'))
        
        if model then settings.model = model end
        if factor_num then settings.factor_num = factor_num end
        if factor_den then settings.factor_den = factor_den end
        if gpu_id then settings.gpu_id = gpu_id end
        if gpu_thread then settings.gpu_thread = gpu_thread end
        if sc_str then settings.sc = (sc_str == "true") end
        if downscale_width then settings.downscale_width = downscale_width end
    end
end

-- Save settings to rife_settings.json
local function save_settings()
    local path = mp.find_config_file("rife_settings.json")
    if not path then
        path = mp.get_script_directory() .. "/../rife_settings.json"
    end
    local file = io.open(path, "w")
    if file then
        local json_str = string.format([[
{
  "model": %d,
  "factor_num": %d,
  "factor_den": %d,
  "gpu_id": %d,
  "gpu_thread": %d,
  "sc": %s,
  "downscale_width": %d
}
]], settings.model, settings.factor_num, settings.factor_den, settings.gpu_id, settings.gpu_thread, tostring(settings.sc), settings.downscale_width)
        file:write(json_str)
        file:close()
    end
end

-- Helper to find the index of the currently active setting in options
local function get_option_value_index(opt_idx)
    local opt = options[opt_idx]
    local current_val
    if opt.name == "Status" then
        current_val = rife_active and "ON" or "OFF"
    elseif opt.name == "Model" then
        current_val = settings.model
    elseif opt.name == "GPU Device" then
        current_val = settings.gpu_id
    elseif opt.name == "GPU Threads" then
        current_val = settings.gpu_thread
    elseif opt.name == "Scene Detect" then
        current_val = settings.sc
    elseif opt.name == "Downscale" then
        current_val = settings.downscale_width
    elseif opt.name == "Framerate" then
        current_val = settings.factor_num
    end
    
    for i, v in ipairs(opt.values) do
        if v == current_val then
            return i
        end
    end
    return 1
end

-- Draw the overlay menu using OSD
local function draw_menu()
    local text = "{\\fs22}{\\b1}--- RIFE FRAME INTERPOLATION MENU ---{\\b0}\n\n"
    for i, opt in ipairs(options) do
        local val_idx = get_option_value_index(i)
        local val_label = opt.labels and opt.labels[val_idx] or tostring(opt.values[val_idx])
        
        if i == selected_index then
            text = text .. string.format("{\\c&H00FF00&} ▶  %-15s :  [ %s ]{\\c}\n", opt.name, val_label)
        else
            text = text .. string.format("    %-15s :    %s\n", opt.name, val_label)
        end
    end
    text = text .. "\n-------------------------------------\n"
    text = text .. "Navigate: {\\b1}Up / Down{\\b0} | Change value: {\\b1}Left / Right{\\b0}\n"
    text = text .. "Press {\\b1}Enter{\\b0} to Apply & Reload | {\\b1}Esc{\\b0} to Close"
    
    mp.osd_message(text, 10)
end

-- Apply VapourSynth filter
local function apply_filter()
    local script_path = mp.find_config_file("rife_interp.vpy")
    if not script_path then
        mp.osd_message("Error: rife_interp.vpy not found!")
        return
    end
    
    save_settings()
    
    if rife_active then
        mp.command("vf remove @rife")
        mp.command(string.format("vf append @rife:vapoursynth=\"%s\":buffered-frames=4:concurrent-frames=2", script_path))
        mp.osd_message("RIFE: Configuration Reloaded & Active")
    else
        mp.osd_message("RIFE settings saved (filter not active yet)")
    end
end

-- Toggle RIFE filter on/off
local function toggle_rife()
    local script_path = mp.find_config_file("rife_interp.vpy")
    if not script_path then
        mp.osd_message("Error: rife_interp.vpy not found!")
        return
    end

    if rife_active then
        mp.command("vf remove @rife")
        mp.osd_message("RIFE: OFF")
        rife_active = false
    else
        save_settings()
        mp.command(string.format("vf append @rife:vapoursynth=\"%s\":buffered-frames=4:concurrent-frames=2", script_path))
        mp.osd_message("RIFE: ON (" .. tostring(settings.factor_num) .. "×fps)")
        rife_active = true
    end
end

-- Navigation Functions
local function menu_up()
    selected_index = selected_index - 1
    if selected_index < 1 then
        selected_index = #options
    end
    draw_menu()
end

local function menu_down()
    selected_index = selected_index + 1
    if selected_index > #options then
        selected_index = 1
    end
    draw_menu()
end

local function change_value(delta)
    local opt = options[selected_index]
    local val_idx = get_option_value_index(selected_index)
    local new_idx = val_idx + delta
    if new_idx < 1 then
        new_idx = #opt.values
    elseif new_idx > #opt.values then
        new_idx = 1
    end
    
    local new_val = opt.values[new_idx]
    
    if opt.name == "Status" then
        if new_val == "ON" and not rife_active then
            toggle_rife()
        elseif new_val == "OFF" and rife_active then
            toggle_rife()
        end
    elseif opt.name == "Model" then
        settings.model = new_val
    elseif opt.name == "GPU Device" then
        settings.gpu_id = new_val
    elseif opt.name == "GPU Threads" then
        settings.gpu_thread = new_val
    elseif opt.name == "Scene Detect" then
        settings.sc = new_val
    elseif opt.name == "Downscale" then
        settings.downscale_width = new_val
    elseif opt.name == "Framerate" then
        settings.factor_num = new_val
    end
    
    draw_menu()
end

local function menu_left() change_value(-1) end
local function menu_right() change_value(1) end

local function close_menu()
    menu_active = false
    mp.remove_key_binding("menu_up")
    mp.remove_key_binding("menu_down")
    mp.remove_key_binding("menu_left")
    mp.remove_key_binding("menu_right")
    mp.remove_key_binding("menu_enter")
    mp.remove_key_binding("menu_close")
    mp.osd_message("", 0) -- clear OSD
end

local function menu_enter()
    apply_filter()
    close_menu()
end

local function toggle_menu()
    if menu_active then
        close_menu()
    else
        menu_active = true
        load_settings()
        
        -- Bind menu navigation keys (forced to prevent standard player action)
        mp.add_forced_key_binding("UP", "menu_up", menu_up)
        mp.add_forced_key_binding("DOWN", "menu_down", menu_down)
        mp.add_forced_key_binding("LEFT", "menu_left", menu_left)
        mp.add_forced_key_binding("RIGHT", "menu_right", menu_right)
        mp.add_forced_key_binding("ENTER", "menu_enter", menu_enter)
        mp.add_forced_key_binding("ESC", "menu_close", close_menu)
        
        draw_menu()
    end
end

-- Hook key bindings
mp.add_key_binding("ctrl+m", "toggle_menu", toggle_menu)
mp.add_key_binding("ctrl+i", "toggle_rife", toggle_rife)

-- Show instructions when video is loaded
mp.register_event("file-loaded", function()
    load_settings()
    mp.osd_message("RIFE: Ctrl+I to toggle | Ctrl+M for Settings", 4)
end)

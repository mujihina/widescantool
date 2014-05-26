--[[
widescantool v1.01

Copyright (c) 2014, Mujihina
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.
* Neither the name of widescantool nor the
names of its contributors may be used to endorse or promote products
derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL Mujihina BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]


_addon.name    = 'widescantool'
_addon.author  = 'Mujihina'
_addon.version = '1.01'
_addon.command = 'widescantool'
_addon.commands = {'wst'}


-- Required libraries
-- luau
-- config
-- packets
-- resources.zones
-- texts
require ('luau')

-- Load Defaults
function load_defaults()
    -- Do not load anything if we are not logged in
    if (not windower.ffxi.get_info().logged_in) then return end

    -- Skip if defaults have been loaded already
    if (global) then return end
    
    -- Main global structure
    global = {}
    -- Required libs
    global.config = require ('config')
    global.skills = require ('resources').skills
    global.texts = require ('texts')
    global.packets = require ('packets')
    global.zones = require ('resources').zones
    
    global.defaults = {}
    global.defaults.world = {}
    global.defaults.world.alerts = S{}
    global.defaults.world.filters = S{}
    global.defaults.area = {}
    global.defaults.area.alerts = T{}
    global.defaults.area.filters = T{}
    global.defaults.filter_pets = true

    global.defaults.alertbox = {}
    global.defaults.alertbox.pos = {}
    global.defaults.alertbox.pos.x = (windower.get_windower_settings().ui_x_res / 2) - 50
    global.defaults.alertbox.pos.y = 100
    global.defaults.alertbox.text = {}
    global.defaults.alertbox.text.font = 'Consolas'
    global.defaults.alertbox.text.size = 15
    global.defaults.alertbox.text.alpha = 255
    global.defaults.alertbox.text.red = 255
    global.defaults.alertbox.text.green = 0
    global.defaults.alertbox.text.blue = 0
    global.defaults.alertbox.bg = {}
    global.defaults.alertbox.bg.alpha = 192
    global.defaults.alertbox.bg.red = 0
    global.defaults.alertbox.bg.green = 0
    global.defaults.alertbox.bg.blue = 0
    global.defaults.alertbox.padding = 5
    global.defaults.alertbox_default_string = "!ALERT!"

    global.player_name = windower.ffxi.get_player().name
    global.settings_file = "data/%s.xml":format(global.player_name)
    -- most common mob pet names
    global.pet_filters = S{"'s bat", "'s leech", "'s bats", "'s elemental", "'s spider", "'s tiger", "'s bee", "'s beetle", "'s rabbit"}


    -- Load previous settings
    global.settings = config.load(global.settings_file, global.defaults)

    -- Required since config now loads 'sets' as 'strings'
    for i,v in pairs (global.settings.area.alerts) do
    	if (type (global.settings.area.alerts[i]) == 'string') then
            global.settings.area.alerts[i] = S(global.settings.area.alerts[i]:split(', '))
        end
    end
    for i,v in pairs (global.settings.area.filters) do
        if (type (global.settings.area.filters[i]) == 'string') then
            global.settings.area.filters[i] = S(global.settings.area.filters[i]:split(', '))
        end
    end
    
    
    global.alertbox = global.texts.new (global.defaults.alertbox_default_string, global.settings.alertbox)

    -- Performane configutables
    -- Only display global.max_memory_alerts on screen
    global.max_memory_alerts = 3
    -- only look at mob array once every global.skip_memory_scans
    global.skip_memory_scans = 2


    global.combined_alerts = S{}
    global.combined_filters = S{}
    global.zone_name = ""
    global.zone_id = ""
    global.enable_mode = true
    -- iterator
    global.memory_scan_i = global.skip_memory_scans - 1
    
    update_area_info()
end


-- Save settings
function save_settings()
    update_settings()
    global.config.save(global.settings, 'all')
end


-- Change settings back to default
function reset_to_default()
    global.enable_mode = true
    global.settings:reassign(global.defaults)
    global.config.save(global.settings, 'all')
    global.settings = global.config.load(global.settings_file, global.defaults)
    update_settings()
    windower.add_to_chat (167, 'wst: All current and saved settings have been cleared')
end


function logout()
    if (global.alertbox) then
        global.alertbox:hide()
        global.alertbox:destroy()
    end
    -- To avoid weird things when switching characters
    --global.clear()
    global = nil
end

-- Show syntax
function show_syntax()
    windower.add_to_chat (200, 'wst: Syntax is:')
    windower.add_to_chat (207, '    \'wst lg\': List Global settings')
    windower.add_to_chat (207, '    \'wst la\': List settings for current Area')
    windower.add_to_chat (207, '    \'wst lc\': List the combined (global+area) filters/alerts currently being applied')
    windower.add_to_chat (207, '    \'wst laaf\': List All Area Filters')
    windower.add_to_chat (207, '    \'wst laaa\': List All Area Alerts')
    windower.add_to_chat (207, '    \'wst agf <name or pattern>\': Add Global Filter')
    windower.add_to_chat (207, '    \'wst rgf <name or pattern>\': Remove Global Filter')
    windower.add_to_chat (207, '    \'wst aga <name or pattern>\': Add Global Alert')
    windower.add_to_chat (207, '    \'wst rga <name or pattern>\': Remove Global Alert')
    windower.add_to_chat (207, '    \'wst aaf <name or pattern>\': Add Area Filter')
    windower.add_to_chat (207, '    \'wst raf <name or pattern>\': Remove Area Filter')
    windower.add_to_chat (207, '    \'wst aaa <name or pattern>\': Add Area Alert')
    windower.add_to_chat (207, '    \'wst raa <name or pattern>\': Remove Area Alert')
    windower.add_to_chat (207, '    \'wst defaults\': Reset to default settings')
    windower.add_to_chat (207, '    \'wst toggle\': Enable/Disable all filters/alerts temporarily')
    windower.add_to_chat (207, '    \'wst pet\': Enable/Disable filtering of common mob pets')
end


-- Parse and process commands
function wst_command (cmd, ...)
    if (not cmd or cmd == 'help' or cmd == 'h') then
        show_syntax()
        return
    end
          
    -- Force a zone update. Mostly for debugging.
    if (cmd == 'u') then update_area_info() return end
    
    local args = L{...}
    
    -- Set to defaults
    if (cmd == 'defaults') then
        global.alertbox:hide()
        reset_to_default()
        return
    end

    -- Toggle enable mode
    if (cmd == 'toggle') then
        global.enable_mode = not global.enable_mode
        if (global.enable_mode) then
            windower.add_to_chat (167, 'wst: filters/alerts have been re-enabled')
            -- check where we are
            update_area_info()
        else
            windower.add_to_chat (167, 'wst: filters/alerts are temporarily disabled')
            global.alertbox:hide()
        end
        return
    end

    -- Toggle pet filter
    if (cmd == 'pet') then
        global.settings.filter_pets = not global.settings.filter_pets
        if (global.settings.filter_pets) then
            windower.add_to_chat (167, 'wst pet: filtering of common mob pets has been re-enabled')
        else
            windower.add_to_chat (167, 'wst pet: filtering of common mob pets has been disabled')
        end
        save_settings()
        return
    end

    -- List All Global settings
    if (cmd == 'lg') then
        windower.add_to_chat (207, 'wst lg: Global filters: %s':format(global.settings.world.filters:tostring()))
        windower.add_to_chat (207, 'wst lg: Global alerts: %s':format(global.settings.world.alerts:tostring()))
        return
    end
    
    -- List combined settings
    if (cmd == 'lc') then
        windower.add_to_chat (207, 'wst lc: combined filters applied to %s: %s':format(global.zone_name, global.combined_filters:tostring()))
        windower.add_to_chat (207, 'wst lc: combined alerts applied to %s: %s':format(global.zone_name, global.combined_alerts:tostring()))
        return
    end
    
    -- List All settings in current area
    if (cmd == 'la') then
        if (global.settings.area.filters:containskey(global.zone_id)) then
            windower.add_to_chat (207, 'wst lr: Filters for %s: %s':format (global.zone_name, global.settings.area.filters[global.zone_id]:tostring()))
        else
            windower.add_to_chat (207, 'wst lr: Filters for %s: {}':format (global.zone_name))
        end
        if (global.settings.area.alerts:containskey(global.zone_id)) then
            windower.add_to_chat (207, 'wst lr: Alerts for %s: %s':format (global.zone_name, global.settings.area.alerts[global.zone_id]:tostring()))
        else
            windower.add_to_chat (207, 'wst lr: Alerts for %s: {}':format (global.zone_name))
        end
        return
    end
    
    -- List All Area Filters
    if (cmd == 'laaf') then
        windower.add_to_chat (200, 'wst larf: Listing ALL area Filters')
        for i,_ in pairs (global.settings.area.filters) do
            local area_name = global.zones[i].name
            windower.add_to_chat (207, 'wst larf: Filters for %s: %s':format(area_name, global.settings.area.filters[i]:tostring()))
        end
        return
    end
    
    -- List All Area Alerts
    if (cmd == 'laaa') then
        windower.add_to_chat (200, 'wst lara: Listing ALL area Alerts')
        for i,_ in pairs (global.settings.area.alerts) do
            local area_name = global.zones[i].name
            windower.add_to_chat (207, 'wst lara: Alerts for %s: %s':format(area_name, global.settings.area.alerts[i]:tostring()))
        end
        return
    end
    
    -- Need more args from here on
    if (args:length() < 1) then
        windower.add_to_chat (167, 'wst: Check your syntax')
        return
    end
    
    -- Name or pattern to use
    -- concat for multi word names, remove ',' and '"', remove extra spaces
    local input = args:concat(' '):lower():stripchars(',"'):spaces_collapse()
    
    -- only accept patterns with a-z, A-Z,0-9, spaces, "'", "-" and "."
    if (input == nil or not windower.regex.match(input, "^[a-zA-Z0-9 '-.?]+$")) then
        windower.add_to_chat (167, "wst: Rejecting pattern. Invalid characters in pattern")
        return
    end
    
    local pattern = "%s":format(input)
    
    -- Add Global Filter
    if (cmd == 'agf') then
        windower.add_to_chat (200, 'wst agf: Adding: \"%s\" to Global Filters':format(pattern))
        global.settings.world.filters:add("%s":format(pattern))
        windower.add_to_chat (207, 'wst agf: Current global filters: %s':format(global.settings.world.filters:tostring()))
        save_settings()
        return
    end
    -- Remove Global Filter
    if (cmd == 'rgf') then
        windower.add_to_chat (200, 'wst rgf: Removing \"%s\" from Global Filters':format(pattern))
        global.settings.world.filters:remove("%s":format(pattern))
        windower.add_to_chat (207, 'wst rgf: Current global filters: %s':format(global.settings.world.filters:tostring()))
        save_settings()
        return
    end
    -- Add Global Alert
    if (cmd == 'aga') then
        windower.add_to_chat (200, 'wst aga: Adding: \"%s\" to Global Alerts':format(pattern))
        global.settings.world.alerts:add("%s":format(pattern))
        windower.add_to_chat (207, 'wst aga: Current global alerts: %s':format(global.settings.world.alerts:tostring()))
        save_settings()
        return
    end
    -- Remove Global Alert
    if (cmd == 'rga') then
        windower.add_to_chat (200, 'wst rga: Removing \"%s\" from Global Alerts':format(pattern))
        global.settings.world.alerts:remove("%s":format(pattern))
        windower.add_to_chat (207, 'wst rga: Current global alerts: %s':format(global.settings.world.alerts:tostring()))
        save_settings()
        return
    end
    -- Add Area Filter
    if (cmd == 'aaf') then
        windower.add_to_chat (200, 'wst aaf: Adding: \"%s\" to area Filters for %s':format(pattern, global.zone_name))
        if (not global.settings.area.filters:containskey(global.zone_id)) then
            global.settings.area.filters[global.zone_id] = S{}
        end
        global.settings.area.filters[global.zone_id]:add("%s":format(pattern))
        windower.add_to_chat (207, 'wst aaf: Current filters for %s: %s':format(global.zone_name, global.settings.area.filters[global.zone_id]:tostring()))
        save_settings()
        return
    end
    -- Remove Area Filter
    if (cmd == 'raf') then
        windower.add_to_chat (200, 'wst raf: Removing: \"%s\" from area Filters for %s':format(pattern, global.zone_name))
        if (global.settings.area.filters:containskey(global.zone_id)) then
            global.settings.area.filters[global.zone_id]:remove("%s":format(pattern))
            windower.add_to_chat (207, 'wst raf: Current filters for %s: %s':format(global.zone_name, global.settings.area.filters[global.zone_id]:tostring()))
            save_settings()
        end
        return
    end
    -- Add Area Alert
    if (cmd == 'aaa') then
        windower.add_to_chat (200, 'wst aaa: Adding: \"%s\" to area Alerts for %s':format(pattern, global.zone_name))
        if (not global.settings.area.alerts:containskey(global.zone_id)) then
            global.settings.area.alerts[global.zone_id] = S{}
        end
        global.settings.area.alerts[global.zone_id]:add("%s":format(pattern))
        windower.add_to_chat (207, 'wst aaa: Current alerts for %s: %s':format(global.zone_name, global.settings.area.alerts[global.zone_id]:tostring()))
        save_settings()
        return
    end
    -- Remove Area Alert
    if (cmd == 'raa') then
        windower.add_to_chat(200, 'wst raa: Removing: \"%s\" from area Alerts for %s':format(pattern, global.zone_name))
        if (global.settings.area.alerts:containskey(global.zone_id)) then
            global.settings.area.alerts[global.zone_id]:remove("%s":format(pattern))
            windower.add_to_chat (207, 'wst raa: Current alerts for %s: %s':format(global.zone_name, global.settings.area.alerts[global.zone_id]:tostring()))
            save_settings()
        end
        return
    end
    
    -- Show Syntax
    windower.add_to_chat (167, 'wst: Check your syntax')
end


-- calculate new sets with new area
function update_settings()
    global.combined_alerts = global.settings.world.alerts
    global.combined_filters = global.settings.world.filters
    
    if (global.settings.area.alerts:containskey(global.zone_id)) then
        global.combined_alerts = global.combined_alerts + global.settings.area.alerts[global.zone_id]
    end
    if (global.settings.area.filters:containskey(global.zone_id)) then
        global.combined_filters = global.combined_filters + global.settings.area.filters[global.zone_id]
    end
    if (global.settings.filter_pets) then
        global.combined_filters = global.pet_filters + global.combined_filters
    end
end

-- update area location
function update_area_info()
    -- Load defaults if needed
    if (not global) then load_defaults() return end

    global.zone_id = tostring(windower.ffxi.get_info().zone)
    global.zone_name = global.zones[windower.ffxi.get_info().zone].name
    update_settings()
end


-- Process incoming packets
function wst_process_packets (id, original, modified, injected, blocked)
    if ((not global) or (not global.enable_mode)) then return end
    
    -- Process widescan replies
    if (id==0xF4) then
        local p = global.packets.parse ('incoming', original)
        local short_name = p['Name']
        local index = p['Index']
        local ID = 0x01000000 + (4096 * global.zone_id) + index
        local official_name = windower.ffxi.get_mob_name(ID) or short_name

        if (official_name == nil) then return end
        local name_to_match = official_name:lower()
            
        -- Process filters
        for i,_ in pairs (global.combined_filters) do
            if (name_to_match:match("%s":format(i))) then
                return true
            end
        end
        
        -- Process alerts
        for i,_ in pairs (global.combined_alerts) do
            if (name_to_match:match("%s":format(i))) then
                windower.add_to_chat(167, 'wst alert: %s detected!!':format(name_to_match))
                return
            end
        end
    end
    
    -- Process memory alerts
    if (id==0xE) then 
        -- Only look at 1 memory table every global.skip_memory_scans
        global.memory_scan_i  = global.memory_scan_i + 1
        if (global.memory_scan_i % global.skip_memory_scans ~= 0) then return end

        local mob_array = windower.ffxi.get_mob_array()
        local alert_count = 0
        local alert_list = L{}
        for _,v in pairs(mob_array) do
            local mob_name = v['name']
--            if (mob_name and v['is_npc'] and v['valid_target'] and v['status'] == 0) then
            if (mob_name and v['valid_target'] and v['status'] == 0) then

                for i,_ in pairs (global.combined_alerts) do
                    if (mob_name:lower():match("%s":format(i))) then
                        alert_count = alert_count + 1
                        -- If too many, just stop.
                        if (alert_count >= global.max_memory_alerts) then
                            global.alertbox:text ("%s\n%s":format(global.defaults.alertbox_default_string, "(many)"))
                            global.alertbox:show()
                            return
                        end
                        --alert_list:append("%s (%d)":format(mob_name, v['distance']:sqrt()))
                        alert_list:append(mob_name)
                    end
                end
            end
        end
        if (alert_count < 1) then
            global.alertbox:hide()
        else
            global.alertbox:clear()
            global.alertbox:text ("%s\n%s":format(global.defaults.alertbox_default_string, alert_list:concat ('\n')))
            global.alertbox:show()
        end
    end
end

-- Register callbacks
windower.register_event ('addon command', wst_command)
windower.register_event ('incoming chunk', wst_process_packets)
windower.register_event ('zone change', update_area_info)
windower.register_event ('load', 'login', load_defaults)
windower.register_event ('logout', logout)
mod_name="InputViewer"

-- Global table to store rendering IDs for each assembler
if not global then global = {} end
global.assembler_renderings = global.assembler_renderings or {}

local function clear_assembler(entity)
    if global.assembler_renderings[entity.unit_number] then
        for _, render in pairs(global.assembler_renderings[entity.unit_number]) do
            render.destroy()
        end
        global.assembler_renderings[entity.unit_number] = nil
    end
end

local function decorate_assembler(entity)

    -- Clear existing renderings for this assembler
    clear_assembler(entity)

    -- Draw only when there's recipe on the given assembler
    recipe = entity.get_recipe()
    if recipe then

        local v_offset = 0.6
        local h_offset = 0.6
        local m_offset = 0.3
        local scale = 0.6
        local base_x = entity.position.x - 0
        local base_y = entity.position.y - 0.6

        local positions = {
            {x = base_x - v_offset, y = base_y},
            {x = base_x,            y = base_y - m_offset},
            {x = base_x + v_offset, y = base_y},
            {x = base_x - v_offset, y = base_y + h_offset},
            {x = base_x,            y = base_y + m_offset + h_offset},
            {x = base_x + v_offset, y = base_y + h_offset}
        }

        renders = {}
        for i, ingredient in pairs(recipe.ingredients) do
            local item_name = ingredient.name

            table.insert(renders, rendering.draw_sprite {
                surface = entity.surface,
                sprite = "utility/entity_info_dark_background",
                target = positions[i],
                x_scale = scale,
                y_scale = scale
            })

            table.insert(renders, rendering.draw_sprite {
                surface = entity.surface,
                sprite = ingredient.type .. "/" .. item_name,
                target = positions[i],
                x_scale = scale,
                y_scale = scale
            })
        end

        global.assembler_renderings[entity.unit_number] = renders
    end
end

local function is_assembler(entity)
    return entity.type == "assembling-machine"
end

local function decorate_if_assembler(entity)
    if is_assembler(entity) then
        decorate_assembler(entity)
    end
end

-- Handle new assemblers
script.on_event(defines.events.on_built_entity, function(event)
    decorate_if_assembler(event.entity)
end)

-- Handle pasting settings
script.on_event(defines.events.on_entity_settings_pasted, function(event)
    decorate_if_assembler(event.destination)
end)

-- Handle assemblers being removed
script.on_event({defines.events.on_entity_died, defines.events.on_player_mined_entity}, function(event)
    local entity = event.entity
    if is_assembler(entity) then
        clear_assembler(entity)
    end
end)

-- Handle potential recipe change
script.on_event(defines.events.on_gui_closed, function(event)
    decorate_if_assembler(event.entity)
end)

-- Initialize for existing assemblers (new game or mod enabled)
script.on_init(function()
    game.print("Initialized mod " .. mod_name)

    global.assembler_renderings = {}
    for _, surface in pairs(game.surfaces) do
        for _, entity in pairs(surface.find_entities_filtered{type = "assembling-machine"}) do
            decorate_assembler(entity)
        end
    end
end)

-- Handle existing assemblers in saved games or mod updates
script.on_configuration_changed(function(data)
    game.print("Configuration changed for mod " .. mod_name)

    global.assembler_renderings = global.assembler_renderings or {}
    for _, surface in pairs(game.surfaces) do
        for _, entity in pairs(surface.find_entities_filtered{type = "assembling-machine"}) do
            if not global.assembler_renderings[entity.unit_number] then
                decorate_assembler(entity)
            end
        end
    end
end)

--script.on_event(defines.events.on_selected_entity_changed, function(event)
--    -- Get the player who triggered the event
--
--    local player = game.players[event.player_index]
--
--    -- Check if the player has selected an entity
--    if player.selected then
--
--        rendering.clear(mod_name)
--        local entity = player.selected
--        if is_assembler(entity) then
--            decorate_assembler(entity)
--        end
--    end
--end)
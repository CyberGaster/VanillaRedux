---@diagnostic disable: undefined-global

local PATCHES = {     
    j_joker  = 'jokers/joker.lua',
    j_greedy_joker = 'jokers/greedy_joker.lua',
    j_gluttenous_joker = 'jokers/gluttenous_joker.lua',
    j_lusty_joker = 'jokers/lusty_joker.lua',
    j_wrathful_joker = 'jokers/wrathful_joker.lua',
    j_jolly = 'jokers/jolly.lua',
    j_zany = 'jokers/zany.lua',
    j_mad = 'jokers/mad.lua',
    j_crazy = 'jokers/crazy.lua',
    j_droll = 'jokers/droll.lua',
    j_sly = 'jokers/sly.lua',
    j_wily = 'jokers/wily.lua',
    j_clever = 'jokers/clever.lua',
    j_devious = 'jokers/devious.lua',
    j_crafty = 'jokers/crafty.lua',
    j_stencil = 'jokers/stencil.lua',
    j_four_fingers = 'jokers/four_fingers.lua',
    j_credit_card = 'jokers/credit_card.lua',
    j_ceremonial = 'jokers/ceremonial.lua',
    j_banner = 'jokers/banner.lua',
    j_mystic_summit = 'jokers/mystic_summit.lua',
    j_marble = 'jokers/marble.lua',
    j_loyalty_card = 'jokers/loyalty_card.lua',
    j_8_ball = 'jokers/8_ball.lua',
    j_misprint = 'jokers/misprint.lua',
    j_raised_fist = 'jokers/raised_fist.lua',
    j_chaos = 'jokers/chaos.lua',
    j_fibonacci = 'jokers/fibonacci.lua',
    j_steel_joker = 'jokers/steel_joker.lua',
    j_abstract = 'jokers/abstract.lua',
    j_delayed_grat = 'jokers/delayed_grat.lua',
    j_pareidolia = 'jokers/pareidolia.lua',
    j_scholar = 'jokers/scholar.lua',
    j_ride_the_bus = 'jokers/ride_the_bus.lua',
    j_runner = 'jokers/runner.lua',
    j_ice_cream = 'jokers/ice_cream.lua',
    j_sixth_sense = 'jokers/sixth_sense.lua',
    j_constellation = 'jokers/constellation.lua',
    j_faceless = 'jokers/faceless.lua',
    j_green_joker = 'jokers/green_joker.lua',
    j_superposition = 'jokers/superposition.lua',
    j_todo_list = 'jokers/todo_list.lua',
    j_red_card = 'jokers/red_card.lua',
    j_square = 'jokers/square.lua',
    j_seance = 'jokers/seance.lua',
    j_vagabond = 'jokers/vagabond.lua',
    j_luchador = 'jokers/luchador.lua',
    j_reserved_parking = 'jokers/reserved_parking.lua',
    j_fortune_teller = 'jokers/fortune_teller.lua',
    j_stone = 'jokers/stone.lua',
    j_golden = 'jokers/golden.lua',
    j_baseball = 'jokers/baseball.lua',
    j_bull = 'jokers/bull.lua',
    j_flash = 'jokers/flash.lua',
    j_trousers = 'jokers/trousers.lua',
    j_ancient = 'jokers/ancient.lua',
    j_walkie_talkie = 'jokers/walkie_talkie.lua',
    j_ticket = 'jokers/ticket.lua',
    j_mr_bones = 'jokers/mr_bones.lua',
    j_certificate = 'jokers/certificate.lua',
    j_throwback = 'jokers/throwback.lua',
    j_ring_master = 'jokers/ring_master.lua',
    j_flower_pot = 'jokers/flower_pot.lua',
    j_idol = 'jokers/idol.lua',
    j_matador = 'jokers/matador.lua',
    j_hit_the_road = 'jokers/hit_the_road.lua',
    j_satellite = 'jokers/satellite.lua',
    j_shoot_the_moon = 'jokers/shoot_the_moon.lua',
    j_drivers_license = 'jokers/drivers_license.lua',
    j_cartomancer = 'jokers/cartomancer.lua',
    j_burnt = 'jokers/burnt.lua',
    j_bootstraps = 'jokers/bootstraps.lua',
    j_yorick = 'jokers/yorick.lua',
    j_chicot = 'jokers/chicot.lua',
    j_obelisk = 'jokers/obelisk.lua',
}

local PATCHES_TAROT = {
    c_hermit = 'taro/hermit.lua',
    c_wheel_of_fortune = 'taro/wheel_of_fortune.lua',
}

local PATCHES_SPECTRAL = {
    c_familiar = 'spectral/familiar.lua',
    c_incantation = 'spectral/incantation.lua',
    c_ouija = 'spectral/ouija.lua',
    c_immolate = 'spectral/immolate.lua',
    c_ankh = 'spectral/ankh.lua',
    c_hex = 'spectral/hex.lua',
}

local PATCHES_ENHANCED = { 
    m_bonus = 'enhanced/bonus.lua',
    m_mult = 'enhanced/mult.lua',
    m_wild = 'enhanced/wild.lua',
}

-------------------------------------------------

local patches_applied = false

local function apply_modern_patches()
    if patches_applied then 
        return true 
    end
    
    if not SMODS or not SMODS.current_mod then 
        return false 
    end
    
    if not G or not G.P_CENTERS then
        return false
    end
    
    print('Applying Steamodded-compatible patches...')
    
    local PATCH_GROUPS = {PATCHES, PATCHES_TAROT, PATCHES_SPECTRAL, PATCHES_ENHANCED}

    for _, PATCH_SET in ipairs(PATCH_GROUPS) do
        for id, rel_path in pairs(PATCH_SET) do
            if G.P_CENTERS[id] then
                local chunk, err = SMODS.load_file(rel_path)
                if chunk then
                    local ok, patch_result = pcall(chunk)
                    if ok and type(patch_result) == 'function' then
                        local success, patch_err = pcall(patch_result, G.P_CENTERS[id])
                        if success then
                            print('✓ Successfully patched '..id)
                        else
                            print('✗ Error applying patch for '..id..': '..tostring(patch_err))
                        end
                    else
                        local file_content = love.filesystem.read(rel_path)
                        if file_content then
                            local direct_chunk, load_err = loadstring(file_content, rel_path)
                            if direct_chunk then
                                local direct_ok, direct_result = pcall(direct_chunk)
                                if direct_ok and type(direct_result) == 'function' then
                                    local direct_success, direct_err = pcall(direct_result, G.P_CENTERS[id])
                                    if direct_success then
                                        print('✓ Successfully patched '..id..' (direct)')
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    patches_applied = true
    print('Patch application completed')
    return true
end

if SMODS and SMODS.Hook then
    SMODS.Hook.add('post_game_init', function()
        apply_modern_patches()
    end)
else
    local attempts = 0
    local max_attempts = 50
    
    local function try_apply_patches()
        attempts = attempts + 1
        if attempts > max_attempts then
            print('Max patch attempts reached, stopping')
            return
        end
        
        if apply_modern_patches() then
            return
        end
        
        if love and love.update then
            local original_update = love.update
            love.update = function(dt)
                if original_update then original_update(dt) end
                love.update = original_update
                try_apply_patches()
            end
        end
    end
    
    try_apply_patches()
end
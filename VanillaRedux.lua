VanillaRedux = VanillaRedux or {}

function VanillaRedux.to_number(value, fallback)
    fallback = fallback or 0
    local kind = type(value)
    if kind == 'number' then return value end
    if kind == 'string' then return tonumber(value) or fallback end
    -- Talisman keeps big numbers as tables. Amulet keeps them as cdata, reported as tables only when its
    -- type compat option is on.
    if kind ~= 'table' and kind ~= 'cdata' then return fallback end

    if rawget(_G, 'to_number') then
        local ok, converted = pcall(to_number, value)
        if ok and type(converted) == 'number' then return converted end
    end
    for _, method in ipairs({ 'to_number', 'toNumber' }) do
        local ok, converted = pcall(function() return value[method](value) end)
        if ok and type(converted) == 'number' then return converted end
    end
    return tonumber(tostring(value)) or fallback
end

function VanillaRedux.scale_chips(amount, factor, minimum)
    if type(amount) == 'number' then
        return math.max(minimum or 0, math.floor(amount * factor))
    end
    local ok, scaled = pcall(function()
        local product = amount * factor
        local floored_ok, floored = pcall(function() return product:floor() end)
        if floored_ok and floored ~= nil then return floored end
        return product
    end)
    if ok then return scaled end
    return nil
end

local MOD_FILES = {
    'jokers/8_ball.lua',
    'jokers/abstract.lua',
    'jokers/ancient.lua',
    'jokers/banner.lua',
    'jokers/baseball.lua',
    'jokers/bootstraps.lua',
    'jokers/bull.lua',
    'jokers/burnt.lua',
    'jokers/cartomancer.lua',
    'jokers/ceremonial.lua',
    'jokers/certificate.lua',
    'jokers/chaos.lua',
    'jokers/chicot.lua',
    'jokers/clever.lua',
    'jokers/constellation.lua',
    'jokers/crafty.lua',
    'jokers/crazy.lua',
    'jokers/credit_card.lua',
    'jokers/delayed_grat.lua',
    'jokers/devious.lua',
    'jokers/drivers_license.lua',
    'jokers/droll.lua',
    'jokers/faceless.lua',
    'jokers/fibonacci.lua',
    'jokers/flash.lua',
    'jokers/flower_pot.lua',
    'jokers/fortune_teller.lua',
    'jokers/four_fingers.lua',
    'jokers/gluttenous_joker.lua',
    'jokers/golden.lua',
    'jokers/green_joker.lua',
    'jokers/greedy_joker.lua',
    'jokers/hit_the_road.lua',
    'jokers/ice_cream.lua',
    'jokers/idol.lua',
    'jokers/joker.lua',
    'jokers/jolly.lua',
    'jokers/loyalty_card.lua',
    'jokers/luchador.lua',
    'jokers/lusty_joker.lua',
    'jokers/mad.lua',
    'jokers/marble.lua',
    'jokers/matador.lua',
    'jokers/misprint.lua',
    'jokers/mr_bones.lua',
    'jokers/mystic_summit.lua',
    'jokers/obelisk.lua',
    'jokers/pareidolia.lua',
    'jokers/raised_fist.lua',
    'jokers/red_card.lua',
    'jokers/reserved_parking.lua',
    'jokers/ride_the_bus.lua',
    'jokers/ring_master.lua',
    'jokers/runner.lua',
    'jokers/satellite.lua',
    'jokers/scholar.lua',
    'jokers/seance.lua',
    'jokers/shoot_the_moon.lua',
    'jokers/sixth_sense.lua',
    'jokers/sly.lua',
    'jokers/square.lua',
    'jokers/steel_joker.lua',
    'jokers/stencil.lua',
    'jokers/stone.lua',
    'jokers/stuntman.lua',
    'jokers/superposition.lua',
    'jokers/throwback.lua',
    'jokers/ticket.lua',
    'jokers/todo_list.lua',
    'jokers/vagabond.lua',
    'jokers/walkie_talkie.lua',
    'jokers/wily.lua',
    'jokers/wrathful_joker.lua',
    'jokers/yorick.lua',
    'jokers/zany.lua',
    'taro/hermit.lua',
    'taro/wheel_of_fortune.lua',
    'spectral/ankh.lua',
    'spectral/familiar.lua',
    'spectral/hex.lua',
    'spectral/immolate.lua',
    'spectral/incantation.lua',
    'spectral/ouija.lua',
}

print('Vanilla Redux: Loading main file...')

SMODS.Atlas {
    key = 'modicon',
    px = 32,
    py = 32,
    path = 'modicon.png'
}

local failed_files = {}

local function report_error(message)
    print('Vanilla Redux: '..message)
    if sendErrorMessage then sendErrorMessage(message, 'VanillaRedux') end
end

local function with_traceback(err)
    return debug.traceback(tostring(err), 2)
end

for _, path in ipairs(MOD_FILES) do
    local chunk, err = SMODS.load_file(path)
    if chunk then
        local ok, load_err = xpcall(chunk, with_traceback)
        if not ok then
            failed_files[#failed_files + 1] = path
            report_error('Error loading '..path..': '..tostring(load_err))
        end
    else
        failed_files[#failed_files + 1] = path
        report_error('Failed to load '..path..': '..tostring(err))
    end
end

if #failed_files > 0 then
    report_error(#failed_files..' file(s) failed to load, some changes are not active: '..table.concat(failed_files, ', '))
else
    print('Vanilla Redux: All files loaded!')
end
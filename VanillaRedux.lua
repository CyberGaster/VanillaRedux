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

local PLAIN_LIMIT = 1e300

local function plain_value(value)
    local kind = type(value)
    if kind == 'number' then return value end
    if kind ~= 'table' and kind ~= 'cdata' then return nil end
    if rawget(_G, 'to_number') then
        local ok, converted = pcall(to_number, value)
        if ok and type(converted) == 'number' then return converted end
    end
    for _, method in ipairs({ 'to_number', 'toNumber' }) do
        local ok, converted = pcall(function() return value[method](value) end)
        if ok and type(converted) == 'number' then return converted end
    end
    return nil
end

function VanillaRedux.plain_or_big(value)
    if type(value) == 'string' then return tonumber(value) or 0 end
    local n = plain_value(value)
    if n and n == n and n > -PLAIN_LIMIT and n < PLAIN_LIMIT then return n end
    return value
end

function VanillaRedux.big(value)
    local make_big = rawget(_G, 'to_big')
    if make_big and type(value) == 'number' then return make_big(value) end
    return value
end

function VanillaRedux.ge(a, b)
    if type(a) == 'number' and type(b) == 'number' then return a >= b end
    return VanillaRedux.big(a) >= VanillaRedux.big(b)
end

function VanillaRedux.gt(a, b)
    if type(a) == 'number' and type(b) == 'number' then return a > b end
    return VanillaRedux.big(a) > VanillaRedux.big(b)
end

local function rounded(value, method)
    if type(value) == 'number' then return math[method](value) end
    local ok, result = pcall(function() return value[method](value) end)
    if ok and result ~= nil then return result end
    return value
end

function VanillaRedux.floor(value) return rounded(value, 'floor') end
function VanillaRedux.ceil(value) return rounded(value, 'ceil') end

function VanillaRedux.format_number(value)
    if type(value) ~= 'number' and rawget(_G, 'number_format') then
        local ok, text = pcall(number_format, value)
        if ok and type(text) == 'string' then return text end
    end
    return tostring(value)
end

function VanillaRedux.remove_hands_this_round(amount)
    local cr = G.GAME and G.GAME.current_round
    if not (cr and type(cr.hands_left) == 'number') then return end
    if cr.hands_left > 1 then
        cr.hands_left = math.max(1, cr.hands_left - amount)
    end
end

local VANILLA_SUIT_ORDER = { 'Spades', 'Hearts', 'Diamonds', 'Clubs' }

local function allowed_in_pool(obj, args)
    local ok, allowed = pcall(SMODS.add_to_pool, obj, args or {})
    return ok and allowed and true or false
end

function VanillaRedux.suit_keys()
    local keys, seen = {}, {}
    for _, key in ipairs(VANILLA_SUIT_ORDER) do
        if SMODS.Suits and SMODS.Suits[key] then keys[#keys + 1] = key; seen[key] = true end
    end
    for _, key in ipairs((SMODS.Suit and SMODS.Suit.obj_buffer) or {}) do
        if not seen[key] then keys[#keys + 1] = key; seen[key] = true end
    end
    return keys
end

function VanillaRedux.pool_suits(args)
    local suits = {}
    for _, key in ipairs(VanillaRedux.suit_keys()) do
        local suit = SMODS.Suits[key]
        if allowed_in_pool(suit, args) then suits[#suits + 1] = suit end
    end
    return suits
end

function VanillaRedux.pool_ranks(filter, args)
    local ranks = {}
    for _, key in ipairs((SMODS.Rank and SMODS.Rank.obj_buffer) or {}) do
        local rank = SMODS.Ranks[key]
        if rank and (not filter or filter(rank)) and allowed_in_pool(rank, args) then
            ranks[#ranks + 1] = rank
        end
    end
    return ranks
end

function VanillaRedux.is_rare_or_better(rarity)
    if type(rarity) == 'number' then return rarity >= 3 end
    if rarity == 'Rare' or rarity == 'Legendary' then return true end
    local info = SMODS.Rarities and SMODS.Rarities[rarity]
    if not info then return false end
    local pool = info.pools and info.pools.Joker
    local weight = (type(pool) == 'table' and pool.weight) or info.default_weight or 0
    return weight <= 0.05
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
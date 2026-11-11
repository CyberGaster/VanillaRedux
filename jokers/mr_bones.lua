local function _to_number(x)
    if type(x) == 'number' then return x end
    if type(x) == 'cdata' then return VanillaRedux.to_number(x, 0) end
    if type(x) == 'table' then
        local ok, v
        if x.to_number then ok, v = pcall(function() return x:to_number() end); if ok and type(v) == 'number' then return v end end
        if x.toNumber then ok, v = pcall(function() return x:toNumber() end); if ok and type(v) == 'number' then return v end end
    end
    return tonumber(tostring(x)) or 0
end

-- Compared in Talisman's big-number arithmetic, never divided: past ~1e308 converting to a plain
-- number gives infinity, and infinity / infinity is NaN, which fails every threshold.
local function reaches_threshold(scored, required, fraction)
    if type(scored) == 'number' and type(required) == 'number' then
        if required <= 0 then required = 1 end
        return scored >= required * fraction
    end
    if rawget(_G, 'to_big') then
        local ok, result = pcall(function()
            local need = to_big(required)
            if need <= to_big(0) then need = to_big(1) end
            return to_big(scored) >= need * to_big(fraction)
        end)
        if ok and type(result) == 'boolean' then return result end
    end
    local need = _to_number(required)
    if need <= 0 then need = 1 end
    return _to_number(scored) >= need * fraction
end

local MAXED_NAME = 'Mr. Bones'
local MAXED_TEXT = {
    'Prevents Death if chips scored',
    'are at least {C:attention}#1#{} of required chips',
    'Sets money to {C:money}$0{} when saved'
}

-- G.localization is rebuilt on every localization init, and an entry added by hand
-- needs its parsed lines or the description cannot be drawn, so it is re-registered after each init.
local function register_maxed_text()
    local descriptions = G and G.localization and G.localization.descriptions
    local jokers = descriptions and descriptions.Joker
    if not jokers then return end

    local entry = jokers.j_mr_bones_maxed
    if entry and entry.text_parsed and entry.name_parsed then return end

    entry = { name = MAXED_NAME, text = MAXED_TEXT }
    if loc_parse_string then
        entry.name_parsed = { loc_parse_string(MAXED_NAME) }
        entry.text_parsed = {}
        for _, line in ipairs(MAXED_TEXT) do
            entry.text_parsed[#entry.text_parsed + 1] = loc_parse_string(line)
        end
    end
    jokers.j_mr_bones_maxed = entry
end

SMODS.Joker:take_ownership('mr_bones', {
    loc_txt = {
        name = 'Mr. Bones',
        text = {
            'Prevents Death if chips scored',
            'are at least {C:attention}#1#{} of required chips',
            'After saving, threshold increases',
            'by {C:attention}#2#{} and sets money to {C:money}$0{}'
        }
    },
    config = { extra = { threshold_pct = 25, max_pct = 90, increments = {30, 35}, step_idx = 1 } },
    loc_vars = function(self, info_queue, card)
        local extra = card.ability.extra
        local current = math.min(extra.threshold_pct, extra.max_pct)
        local inc = extra.increments[extra.step_idx]
        if inc and current < extra.max_pct then
            return { vars = { tostring(math.floor(current))..'%', tostring(inc)..'%' } }
        else
            register_maxed_text()
            return { vars = { tostring(math.floor(current))..'%' }, key = 'j_mr_bones_maxed' }
        end
    end,
    calculate = function(self, card, context)
        if context.game_over then
            local extra = card.ability.extra
            local threshold = math.min(extra.threshold_pct, extra.max_pct)

            if reaches_threshold(G.GAME.chips, G.GAME.blind.chips, threshold * 0.01) then
                G.E_MANAGER:add_event(Event({
                    func = function()
                        G.hand_text_area.blind_chips:juice_up()
                        G.hand_text_area.game_chips:juice_up()
                        play_sound('tarot1')
                        if G.GAME.dollars and G.GAME.dollars ~= 0 then
                            ease_dollars(-G.GAME.dollars, true)
                        end
                        return true
                    end
                }))

                local inc = extra.increments[extra.step_idx]
                if inc then
                    extra.threshold_pct = math.min(extra.threshold_pct + inc, extra.max_pct)
                    extra.step_idx = extra.step_idx + 1
                end

                return {
                    message = localize('k_saved_ex'),
                    saved = true,
                    colour = G.C.RED
                }
            end
            return {}
        end
    end,
})

if not rawget(_G, 'VR_MRBONES_LOC_HOOKED') and type(init_localization) == 'function' then
    local base_init_localization = init_localization
    function init_localization(...)
        local result = base_init_localization(...)
        register_maxed_text()
        return result
    end
    _G.VR_MRBONES_LOC_HOOKED = true
end

register_maxed_text()

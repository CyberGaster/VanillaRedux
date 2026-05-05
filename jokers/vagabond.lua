local CONSUMABLE_TYPES = { 'Tarot', 'Spectral', 'Planet' }

local COLORS = {
    Tarot    = function() return (G.C.SECONDARY_SET and G.C.SECONDARY_SET.Tarot) or G.C.PURPLE end,
    Spectral = function() return (G.C.SECONDARY_SET and G.C.SECONDARY_SET.Spectral) or G.C.PURPLE end,
    Planet   = function() return (G.C.SECONDARY_SET and G.C.SECONDARY_SET.Planet) or G.C.PURPLE end,
}

local MSG_KEYS = {
    Tarot = 'k_plus_tarot',
    Spectral = 'k_plus_spectral',
    Planet = 'k_plus_planet',
}

local function pick_type(card)
    local round_id = (G.GAME and G.GAME.round) or 0
    local hand_idx = (G.GAME and G.GAME.current_round and G.GAME.current_round.hands_played) or 0
    local seed = 'vag_' .. round_id .. '_' .. hand_idx .. '_' .. (card and card.unique_val or 0)
    local roll = pseudorandom(pseudoseed(seed))
    if roll < 0.5 then return 'Tarot' end
    if roll < 0.8 then return 'Planet' end
    return 'Spectral'
end

local function has_room()
    if not G.consumeables or not G.consumeables.cards or not G.consumeables.config then return false end
    local current = #G.consumeables.cards + (G.GAME and G.GAME.consumeable_buffer or 0)
    return current < (G.consumeables.config.card_limit or 0)
end

local function spawn_consumable(card, kind)
    G.GAME.consumeable_buffer = (G.GAME.consumeable_buffer or 0) + 1
    G.E_MANAGER:add_event(Event({
        func = function()
            G.E_MANAGER:add_event(Event({
                func = function()
                    local newc = create_card(kind, G.consumeables, nil, nil, nil, nil, nil, 'vag')
                    if newc then
                        newc:add_to_deck()
                        G.consumeables:emplace(newc)
                    end
                    G.GAME.consumeable_buffer = math.max(0, (G.GAME.consumeable_buffer or 1) - 1)
                    return true
                end
            }))
            card_eval_status_text(card, 'extra', nil, nil, nil, {
                message = localize(MSG_KEYS[kind]),
                colour = COLORS[kind]()
            })
            return true
        end
    }))
end

SMODS.Joker:take_ownership('vagabond', {
    loc_txt = {
        name = 'Vagabond',
        text = {
            'Create a {C:tarot}Tarot{}, {C:planet}Planet{} or',
            '{C:spectral}Spectral{} card if hand',
            'is played with {C:money}$#1#{} or less',
            '{C:inactive}(Must have room){}'
        }
    },
    config = { extra = 4 },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra } }
    end,
    calculate = function(self, card, context)
        if not context.joker_main then return nil end
        if card.debuff then return nil end
        if not G.GAME then return nil end
        if not has_room() then return nil end

        local dollars = tonumber(G.GAME.dollars) or 0
        if dollars > (card.ability.extra or 4) then return nil end

        local kind = pick_type(context.blueprint_card or card)
        spawn_consumable(context.blueprint_card or card, kind)
        return {}
    end,
})
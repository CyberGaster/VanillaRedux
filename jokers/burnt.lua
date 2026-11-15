SMODS.Joker:take_ownership('burnt', {
    config = { extra = 0 },
    loc_txt = {
        name = 'Burnt Joker',
        text = {
            "Upgrade the level of the {C:attention}played hand{}",
            "when score is {C:red}burning{}"
        }
    },
})

-- Scores and Blind sizes stay big numbers when they do not fit a plain number, so the "burning"
-- check keeps working past ~1.8e308 with Talisman or Amulet.
local function current_hand_id() return (rawget(_G, 'G') and G.GAME and G.GAME.hands_played) or 0 end
local function blind_required()
    local req = rawget(_G, 'G') and G.GAME and G.GAME.blind and G.GAME.blind.chips
    if req == nil then return math.huge end
    return VanillaRedux.plain_or_big(req)
end
local function base_earned_for(hand_name)
    if not (rawget(_G, 'G') and G.GAME and G.GAME.hands and G.GAME.hands[hand_name]) then return 0 end
    local h = G.GAME.hands[hand_name]
    local chips_raw = (rawget(_G, 'mod_chips') and mod_chips(h.chips)) or h.chips
    local mult_raw  = (rawget(_G, 'mod_mult') and mod_mult(h.mult)) or h.mult
    local chips, mult = VanillaRedux.plain_or_big(chips_raw), VanillaRedux.plain_or_big(mult_raw)
    if type(chips) == 'number' and type(mult) == 'number' then return math.floor(chips * mult) end
    return VanillaRedux.floor(VanillaRedux.big(chips) * VanillaRedux.big(mult))
end
local function final_chip_total()
    local cr = rawget(_G, 'G') and G.GAME and G.GAME.current_round and G.GAME.current_round.current_hand
    return cr and cr.chip_total ~= nil and VanillaRedux.plain_or_big(cr.chip_total) or 0
end
local function is_zero(value)
    return type(value) == 'number' and value == 0
end

local last_chip_total = 0

local function try_wrap_update_hand_text()
    if rawget(_G, 'VP_BURNT_UHT_WRAPPED') then return end
    if type(rawget(_G, 'update_hand_text')) ~= 'function' then return end
    _G.VP_BURNT_UHT_WRAPPED = true
    local _old = update_hand_text
    update_hand_text = function(config, vals)
        if vals and vals.chip_total ~= nil then
            last_chip_total = VanillaRedux.plain_or_big(vals.chip_total)
        end
        return _old(config, vals)
    end
end

if not rawget(_G, 'VP_BURNT_REWORKED') and rawget(_G, 'Card') and Card.calculate_joker then
    local base_calculate_joker = Card.calculate_joker
    function Card:calculate_joker(context)
        if self.ability and self.ability.name == 'Burnt Joker' and not self.debuff then
            try_wrap_update_hand_text()
            local state_card = context.blueprint_card or self
            state_card.ability._vp_burnt = state_card.ability._vp_burnt or { _hand_id = current_hand_id(), done = false }
            local ses = state_card.ability._vp_burnt
            if context and context.setting_blind then state_card.ability._vp_burnt = { _hand_id = current_hand_id(), done = false }; return nil end
            if not ses or ses._hand_id ~= current_hand_id() then state_card.ability._vp_burnt = { _hand_id = current_hand_id(), done = false }; ses = state_card.ability._vp_burnt end
            if context and context.pre_discard and not context.hook then return nil end
            if context and context.before and context.scoring_name and not ses.done then
                local earned, req = base_earned_for(context.scoring_name), blind_required()
                if VanillaRedux.gt(req, 0) and VanillaRedux.ge(earned, req) then
                    ses.done = true
                    level_up_hand(nil, context.scoring_name)
                    return { message = localize('k_upgrade_ex') }
                end
            end
            if context and context.after and context.scoring_name and not ses.done then
                local hand_name = context.scoring_name
                if rawget(_G, 'G') and G.E_MANAGER and rawget(_G, 'Event') then
                    G.E_MANAGER:add_event(Event({
                        trigger = 'after', delay = 0.62,
                        func = function()
                            local req = blind_required()
                            local ct = last_chip_total
                            if is_zero(ct) then ct = final_chip_total() end
                            local _ses = state_card.ability and state_card.ability._vp_burnt
                            if _ses and not _ses.done and VanillaRedux.gt(req, 0) and VanillaRedux.ge(ct, req) then
                                _ses.done = true
                                if rawget(_G, 'update_hand_text') and rawget(_G, 'G') and G.GAME and G.GAME.hands and G.GAME.hands[hand_name] then
                                    local h = G.GAME.hands[hand_name]
                                    update_hand_text({sound = 'button', volume = 0.7, pitch = 0.8, delay = 0}, {handname = localize(hand_name, 'poker_hands'), chips = h.chips, mult = h.mult, level = h.level})
                                end
                                if rawget(_G, 'level_up_hand') then level_up_hand(nil, hand_name) end
                                G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 1.35, func = function() if rawget(_G, 'update_hand_text') then update_hand_text({immediate = true, delay = 0}, {mult = 0, chips = 0, handname = '', level = ''}) end; return true end }))
                            end
                            return true
                        end
                    }))
                end
                return nil
            end
            return nil
        end
        return base_calculate_joker(self, context)
    end
    _G.VP_BURNT_REWORKED = true
end
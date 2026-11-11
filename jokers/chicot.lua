SMODS.Joker:take_ownership('chicot', {
    loc_txt = {
        name = 'Chicot',
        text = {
            'When {C:attention}Boss Blind{} is selected,',
            'disables its effect and',
            'reduces required score by {C:attention}15%{}'
        }
    },
    loc_vars = function(self, info_queue, card)
        return { vars = {} }
    end,
})

local function reduce_boss_requirement_linear()
    local game = rawget(_G, 'G') and G or nil
    if not game or not game.GAME or not game.GAME.blind then return end
    local blind = game.GAME.blind
    if not blind or not blind.boss then return end

    -- Every Chicot recomputes from the requirement the Blind had before the first Chicot changed it,
    -- so several Chicots stack once and changes made by other effects are kept.
    local round = game.GAME.round or 0
    if blind.vr_chicot_round ~= round or blind.vr_chicot_base == nil then
        blind.vr_chicot_round = round
        blind.vr_chicot_base = blind.chips
    end
    local base = blind.vr_chicot_base

    local chicot_count = 0
    if game.jokers and game.jokers.cards then
        for i = 1, #game.jokers.cards do
            local j = game.jokers.cards[i]
            if j and j.ability and j.ability.name == 'Chicot' and not j.debuff then
                chicot_count = chicot_count + 1
            end
        end
    end
    if chicot_count <= 0 then return end

    local reduction_factor = math.max(0.01, 1 - 0.15 * chicot_count)
    local target = VanillaRedux.scale_chips(base, reduction_factor, 1)
    if target == nil then return end

    if blind.chips ~= target then
        blind.chips = target
        blind.chip_text = number_format(blind.chips)
        if game.HUD_blind then
            local hud = game.HUD_blind:get_UIE_by_ID('HUD_blind_count')
            if hud and hud.config and hud.config.object and hud.config.object.pop_in then
                hud:juice_up()
            end
        end
    end
end

if not rawget(_G, 'VP_CHICOT_PATCHED') and rawget(_G, 'Card') and Card.calculate_joker then
    local old_calculate_joker = Card.calculate_joker
    function Card:calculate_joker(context)
        if self.ability and self.ability.name == 'Chicot' and not self.debuff then
            if context and context.setting_blind and context.blind and context.blind.boss
               and not context.blueprint and not self.getting_sliced then
                reduce_boss_requirement_linear()
            end
        end
        return old_calculate_joker(self, context)
    end
    _G.VP_CHICOT_PATCHED = true
end
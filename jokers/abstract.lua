return function(center)

    center.rarity = 2
    center.cost = 8
    center.config.extra = 0
    center.loc_txt = center.loc_txt or {}
    center.loc_txt.name = 'Abstract Joker'
    center._abstract_name = 'none'
    center.loc_txt.text = {
        'At beginning of each round,',
        'randomly copies the effect of',
        'any other {C:attention}non-legendary{} Joker',
        '{C:inactive}Resets effect at end of round{}'
    }

    local function choose_target(self)
        if not (rawget(_G,'G') and G.jokers and G.jokers.cards) then return nil end
        local pool = {}
        for i = 1, #G.jokers.cards do
            local j = G.jokers.cards[i]
            if j ~= self 
                and j.config and j.config.center 
                and j.config.center.rarity and j.config.center.rarity < 4 
                and (j.config.center.blueprint_compat ~= false) then
                table.insert(pool, j)
            end
        end
        if #pool == 0 then return nil end
        return pseudorandom_element(pool, pseudoseed('abstract'))
    end

    if not rawget(_G,'VP_ABSTRACT_PATCHED') and rawget(_G,'Card') and Card.calculate_joker then
        local old_calc = Card.calculate_joker
        function Card:calculate_joker(context)
            if self.ability and self.ability.name == 'Abstract Joker' then
                if self.debuff then return nil end
                if self.ability._abstract_round_chosen == nil then
                    self.ability._abstract_round_chosen = false
                end
                
                if context and context.setting_blind then
                    if not self.ability._abstract_round_chosen then
                        local tgt = choose_target(self)
                        local new_name = tgt and tgt.ability.name or 'none'
                        self.ability._abstract_target = tgt
                        self.ability._abstract_name = new_name
                        center._abstract_name = new_name
                        self.ability._abstract_round_chosen = true
                        if tgt and new_name ~= 'none' and not self.debuff then
                            card_eval_status_text(self, 'extra', nil, nil, nil, {message = new_name})
                        end
                    end
                end

                if context and context.end_of_round then
                    if context.game_over then
                        if self.ability._abstract_target then
                            self.ability._abstract_target = nil
                            self.ability._abstract_name = 'none'
                            center._abstract_name = 'none'
                            if not self.debuff then
                                card_eval_status_text(self, 'extra', nil, nil, nil, {message = localize('k_reset')})
                            end
                        end
                        self.ability._abstract_round_chosen = false
                        return nil
                    else
                        self.ability._abstract_round_chosen = false
                    end
                end

                local tgt = self.ability._abstract_target
                if tgt and tgt ~= self then
                    if tgt.ability.name == 'Blueprint' then
                        local target_joker = nil
                        for i = 1, #G.jokers.cards do
                            if G.jokers.cards[i] == self then
                                target_joker = G.jokers.cards[i + 1]
                                break
                            end
                        end
                        if target_joker and target_joker ~= self then
                            local prev_count = context.blueprint
                            local prev_card  = context.blueprint_card
                            context.blueprint = (context.blueprint and (context.blueprint + 1)) or 1
                            context.blueprint_card = context.blueprint_card or self
                            if context.blueprint > (#G.jokers.cards + 1) then
                                context.blueprint = prev_count
                                context.blueprint_card = prev_card
                                return nil
                            end
                            local res = target_joker:calculate_joker(context)
                            context.blueprint = prev_count
                            context.blueprint_card = prev_card
                            if res then
                                res.card = self
                                res.colour = G.C.GREY
                                return res
                            end
                        end
                    elseif tgt.ability.name == 'Brainstorm' then
                        local target_joker = G.jokers.cards[1]
                        if target_joker and target_joker ~= self then
                            local prev_count = context.blueprint
                            local prev_card  = context.blueprint_card
                            context.blueprint = (context.blueprint and (context.blueprint + 1)) or 1
                            context.blueprint_card = context.blueprint_card or self
                            if context.blueprint > (#G.jokers.cards + 1) then
                                context.blueprint = prev_count
                                context.blueprint_card = prev_card
                                return nil
                            end
                            local res = target_joker:calculate_joker(context)
                            context.blueprint = prev_count
                            context.blueprint_card = prev_card
                            if res then
                                res.card = self
                                res.colour = G.C.GREY
                                return res
                            end
                        end
                    else
                        local prev_count = context.blueprint
                        local prev_card  = context.blueprint_card
                        context.blueprint = (context.blueprint and (context.blueprint + 1)) or 1
                        context.blueprint_card = context.blueprint_card or self
                        if context.blueprint > (#G.jokers.cards + 1) then
                            context.blueprint = prev_count
                            context.blueprint_card = prev_card
                            return nil
                        end
                        local res = tgt:calculate_joker(context)
                        if tgt.ability and tgt.ability.name == 'Matador' and not context.game_over then
                            if G.GAME and G.GAME.blind and G.GAME.blind.get_type and G.GAME.blind:get_type() == 'Boss' then
                            end
                        end
                        context.blueprint = prev_count
                        context.blueprint_card = prev_card
                        if res then
                            res.card = self
                            res.colour = G.C.GREY
                            return res
                        end
                    end
                end

                return nil
            end
            return old_calc(self, context)
        end
        _G.VP_ABSTRACT_PATCHED = true
    end

    if rawget(_G,'G') and G.FUNCS and G.FUNCS.cash_out and not rawget(_G,'VP_ABSTRACT_CASHOUT_PATCHED') then
        local orig_cash_out_abs = G.FUNCS.cash_out
        G.FUNCS.cash_out = function(e)
            local abstracts = {}
            if G.jokers and G.jokers.cards then
                for i = 1, #G.jokers.cards do
                    local j = G.jokers.cards[i]
                    if j and j.ability and j.ability.name == 'Abstract Joker' then
                        abstracts[#abstracts+1] = j
                    end
                end
            end

            for i = 1, #abstracts do
                local aj = abstracts[i]
                if aj.ability._abstract_target then
                    aj.ability._abstract_target = nil
                    aj.ability._abstract_name = 'none'
                    center._abstract_name = 'none'
                    if rawget(_G,'card_eval_status_text') then
                        card_eval_status_text(aj, 'extra', nil, nil, nil, {message = localize('k_reset')})
                    end
                end
                aj.ability._abstract_round_chosen = false
            end

            orig_cash_out_abs(e)
        end
        _G.VP_ABSTRACT_CASHOUT_PATCHED = true
    end

    center.loc_vars = function(self, info_queue, card)
        local name
        if card and card.ability and card.ability._abstract_name then
            name = card.ability._abstract_name
        else
            name = center._abstract_name or 'none'
        end
        return { vars = { name } }
    end

    if rawget(_G,'G') and G.localization and G.localization.descriptions
        and G.localization.descriptions.Joker and G.localization.descriptions.Joker.j_abstract then
        G.localization.descriptions.Joker.j_abstract.text = center.loc_txt.text
    end
end
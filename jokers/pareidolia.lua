return function(center)
    local function get_random_face_rank()
        local face_ranks = {"Jack", "Queen", "King"}
        return face_ranks[math.random(1, #face_ranks)]
    end

local function get_rank_id(rank_name)
    local rank_mapping = {
        Jack = 11,
        Queen = 12,
        King = 13
    }
    return rank_mapping[rank_name] or 11
end

if G and rawget(_G,'Card') and not Card._pareidolia_get_id_wrapped then
    local _original_get_id = Card.get_id

    local function active_pareidolia()
        if G and G.jokers and G.jokers.cards then
            for i = 1, #G.jokers.cards do
                local joker = G.jokers.cards[i]
                if joker.config and joker.config.center and joker.config.center.key == 'j_pareidolia'
                   and not joker.debuff and joker.ability and joker.ability.extra then
                    return joker
                end
            end
        end
        return nil
    end

    Card.get_id = function(self)
        local pareidolia = active_pareidolia()
        if pareidolia and self.base and self.base.suit and self.base.id 
           and not self.ability.stone_card and not self.debuff then
            return get_rank_id(pareidolia.ability.extra.face_rank)
        end
        return _original_get_id(self)
    end

    Card._pareidolia_get_id_wrapped = true
end


SMODS.Joker:take_ownership('pareidolia', {
    loc_txt = {
        name = "Pareidolia",
        text = {
            "All cards are considered {C:attention}#1#{},",
            "but keep their {C:blue}Chip{} value",
            "{s:0.8}rank changes at end of round"
        }
    },
    
    cost = 7,
    rarity = 3,
    
    config = {
        extra = {
            face_rank = get_random_face_rank()
        }
    },
    
    loc_vars = function(self, info_queue, card)
        local rank = "Jack"
        if card and card.ability and card.ability.extra and card.ability.extra.face_rank then
            rank = card.ability.extra.face_rank
        elseif self and self.config and self.config.extra and self.config.extra.face_rank then
            rank = self.config.extra.face_rank
        end
        return { vars = { rank } }
    end,
    
    calculate = function(self, card, context)
        card.ability.extra = card.ability.extra or {}
        
        if not card.ability.extra.face_rank then
            card.ability.extra.face_rank = get_random_face_rank()
        end
        
        if context.end_of_round and not card.getting_sliced then
            if not card.ability.extra._vp_round_processed then
                local new_rank = get_random_face_rank()
                while new_rank == card.ability.extra.face_rank do
                    new_rank = get_random_face_rank()
                end
                card.ability.extra.face_rank = new_rank
                card.ability.extra._vp_round_processed = true
            end
        end
        
        if context.setting_blind and card.ability.extra._vp_round_processed then
            card.ability.extra._vp_round_processed = nil
        end
    end,
    
    set_ability = function(self, card, initial, delay_sprites)
        card.ability.extra = card.ability.extra or {}
        if initial then
            card.ability.extra.face_rank = get_random_face_rank()
            self.config.extra.face_rank = card.ability.extra.face_rank
        end
    end
})

local function hide_mod_badge()
    if G and G.P_CENTERS and G.P_CENTERS.j_pareidolia then
        G.P_CENTERS.j_pareidolia.mod = nil
        G.P_CENTERS.j_pareidolia.mod_id = nil
        G.P_CENTERS.j_pareidolia.modded = false
        G.P_CENTERS.j_pareidolia.discovered = true
    end
end

hide_mod_badge()

end
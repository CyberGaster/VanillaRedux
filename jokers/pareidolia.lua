local RANKS = {'Jack', 'Queen', 'King'}
local RANK_IDS = { Jack = 11, Queen = 12, King = 13 }

local function get_random_rank(exclude)
    local pool = {}
    for _, rank in ipairs(RANKS) do
        if rank ~= exclude then pool[#pool + 1] = rank end
    end
    if G.GAME and G.GAME.pseudorandom then
        return pseudorandom_element(pool, pseudoseed('vr_pareidolia'))
    end
    return pool[math.random(1, #pool)]
end

local function has_no_rank(c)
    if SMODS.has_no_rank then return SMODS.has_no_rank(c) end
    return c.ability and c.ability.effect == 'Stone Card'
end

local function active_pareidolia_rank()
    if G.jokers and G.jokers.cards then
        for i = 1, #G.jokers.cards do
            local joker = G.jokers.cards[i]
            if joker.config and joker.config.center and joker.config.center.key == 'j_pareidolia'
               and not joker.debuff and joker.ability and joker.ability.extra then
                return joker.ability.extra.face_rank
            end
        end
    end
    return nil
end

if not rawget(_G, 'VP_PAREIDOLIA_PATCHED') then
local _original_get_id = Card.get_id
function Card:get_id()
    local rank = active_pareidolia_rank()
    if rank and self.base and self.base.id
       and not has_no_rank(self) and not self.debuff then
        return RANK_IDS[rank] or 11
    end
    return _original_get_id(self)
end

local _original_is_face = Card.is_face
function Card:is_face(from_boss)
    local rank = active_pareidolia_rank()
    if rank then
        if self.debuff and not from_boss then return end
        if has_no_rank(self) then return end
        return rank == 'Jack' or rank == 'Queen' or rank == 'King'
    end
    return _original_is_face(self, from_boss)
end
_G.VP_PAREIDOLIA_PATCHED = true
end

SMODS.Joker:take_ownership('pareidolia', {
    loc_txt = {
        name = 'Pareidolia',
        text = {
            'All cards are considered {C:attention}#1#{},',
            'but keep their {C:blue}Chip{} value',
            '{s:0.8}rank changes at end of round'
        }
    },
    cost = 8,
    rarity = 3,
    config = { extra = { face_rank = 'Jack' } },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.face_rank } }
    end,
    set_ability = function(self, card, initial, delay_sprites)
        if initial then
            card.ability.extra = card.ability.extra or {}
            card.ability.extra.face_rank = get_random_rank()
        end
    end,
    calculate = function(self, card, context)
        if context.end_of_round and not context.repetition and not context.individual
           and not context.blueprint and not card.getting_sliced then
            local dominated = false
            if G.jokers and G.jokers.cards then
                for _, j in ipairs(G.jokers.cards) do
                    if j == card then break end
                    if j.config and j.config.center and j.config.center.key == 'j_pareidolia' and not j.debuff then
                        dominated = true
                        break
                    end
                end
            end
            if not dominated then
                local new_rank = get_random_rank(card.ability.extra.face_rank)
                card.ability.extra.face_rank = new_rank
                if G.jokers and G.jokers.cards then
                    for _, j in ipairs(G.jokers.cards) do
                        if j.config and j.config.center and j.config.center.key == 'j_pareidolia' and j ~= card and j.ability and j.ability.extra then
                            j.ability.extra.face_rank = new_rank
                        end
                    end
                end
            end
        end
    end,
})
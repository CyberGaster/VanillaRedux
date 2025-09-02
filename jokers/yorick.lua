return function(center)

    if not center or not center.config then return end
    center.config.extra = center.config.extra or {}

    center.config.extra.xmult = center.config.extra.xmult or 1
    center.config.extra.discards = 21

    if SMODS and SMODS.Hook then
        SMODS.Hook.add('post_game_init', function()
            if rawget(_G,'G') and G.jokers and G.jokers.cards then
                for i = 1, #G.jokers.cards do
                    local card = G.jokers.cards[i]
                    if card and card.ability and card.ability.name == 'Yorick' then
                        card.ability.extra = card.ability.extra or {}
                        card.ability.extra.xmult = card.ability.extra.xmult or 1
                        card.ability.extra.discards = 21
                        if card.ability.yorick_discards and card.ability.yorick_discards > 21 then
                            card.ability.yorick_discards = 21
                        end
                    end
                end
            end
        end)
    end
end
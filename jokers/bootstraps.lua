SMODS.Joker:take_ownership('bootstraps', {
    loc_txt = {
        name = 'Bootstraps',
        text = {
            '{C:mult}+1{} Mult for each {C:money}$2{} earned',
            '{C:inactive}(Currently {C:mult}+#1#{C:inactive} Mult)'
        }
    },
    loc_vars = function(self, info_queue, card)
        local current_mult = 0
        if card and card.ability then
            local m = card.ability._vp_boot_mult
            if type(m) == 'number' then current_mult = m end
        end
        return { vars = { current_mult } }
    end,
    set_ability = function(self, card, initial, delay_sprites)
        card.ability = card.ability or {}
        if card.ability._vp_boot_mult == nil then
            local stored = nil
            if type(card.ability.extra) == 'table' then
                stored = tonumber(card.ability.extra.mult_stored)
            end
            card.ability._vp_boot_mult = tonumber(stored) or 0
        end
        if card.ability._vp_boot_carry == nil then
            local c = nil
            if type(card.ability.extra) == 'table' then
                c = tonumber(card.ability.extra.carry_stored)
            end
            card.ability._vp_boot_carry = math.max(0, math.floor(tonumber(c) or 0) % 2)
        end
        card.ability._vp_boot_chunk = 2
    end,
})

local function _boot_to_number(x)
    if type(x) == 'number' then return x end
    if type(x) == 'string' then return tonumber(x) or 0 end
    if type(x) == 'table' then
        local ok, v
        if x.toNumber then ok, v = pcall(function() return x:toNumber() end); if ok and type(v) == 'number' then return v end end
        if x.to_number then ok, v = pcall(function() return x:to_number() end); if ok and type(v) == 'number' then return v end end
        local s = tostring(x)
        local n = tonumber(s)
        if n then return n end
    end
    return 0
end

if not rawget(_G, 'VP_BOOTSTRAPS_EASE_PATCHED') and ease_dollars then
    local original_ease_dollars = ease_dollars
    function ease_dollars(mod, instant)
        local mod_num = _boot_to_number(mod)
        if mod_num > 0 and G and G.jokers and G.jokers.cards then
            local selling_lock = G.CONTROLLER and G.CONTROLLER.locks and G.CONTROLLER.locks.selling_card
            if not selling_lock then
                for i = 1, #G.jokers.cards do
                    local jk = G.jokers.cards[i]
                    if jk and jk.ability and jk.ability.name == 'Bootstraps' and not jk.debuff then
                        local chunk = (jk.ability and jk.ability._vp_boot_chunk) or 2
                        local carry = (jk.ability and jk.ability._vp_boot_carry) or 0
                        local total = carry + mod_num
                        local gained = math.floor(total / chunk)
                        jk.ability._vp_boot_carry = total - gained * chunk
                        if gained > 0 then
                            jk.ability._vp_boot_mult = (jk.ability._vp_boot_mult or 0) + gained
                        end
                    end
                end
            end
        end
        return original_ease_dollars(mod, instant)
    end
    _G.VP_BOOTSTRAPS_EASE_PATCHED = true
end

if not rawget(_G, 'VP_BOOTSTRAPS_CALC_PATCHED') and rawget(_G, 'Card') and Card.calculate_joker then
    local old_calculate_joker = Card.calculate_joker
    function Card:calculate_joker(context)
        if self.ability and self.ability.name == 'Bootstraps' and not self.debuff then
            if context and context.cardarea == G.jokers then
                if context.joker_main then
                    local mult = (self.ability and self.ability._vp_boot_mult) or 0
                    if mult > 0 then
                        return {
                            message = localize{type='variable', key='a_mult', vars={mult}},
                            mult_mod = mult,
                            colour = G.C.MULT,
                            card = self
                        }
                    else
                        return { mult_mod = 0 }
                    end
                end
            end
        end
        return old_calculate_joker(self, context)
    end
    _G.VP_BOOTSTRAPS_CALC_PATCHED = true
end

if not rawget(_G, 'VP_BOOTSTRAPS_UI_PATCHED') and rawget(_G, 'Card') and Card.generate_UIBox_ability_table then
    local old_generate_UIBox = Card.generate_UIBox_ability_table
    function Card:generate_UIBox_ability_table(vars_only)
        local extra = self.ability and self.ability.extra
        if self.ability and self.ability.set == 'Joker' and self.ability.name == 'Bootstraps'
           and not (type(extra) == 'table' and type(extra.mult) == 'number' and type(extra.dollars) == 'number') then
            self.ability.extra = { mult = 1, dollars = 2 }
            local ok, result = pcall(old_generate_UIBox, self, vars_only)
            self.ability.extra = extra
            if not ok then error(result, 0) end
            return result
        end
        return old_generate_UIBox(self, vars_only)
    end
    _G.VP_BOOTSTRAPS_UI_PATCHED = true
end
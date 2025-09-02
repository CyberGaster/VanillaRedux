return function(center)
    center.rarity = 1
    if not center or not center.config or not center.config.extra then return end
    local extra = center.config.extra
    extra.Xmult = 5 
    extra.every = 4 
    if type(extra.remaining) == 'string' then
        extra.remaining = tostring(extra.every)..' remaining'
    end
end
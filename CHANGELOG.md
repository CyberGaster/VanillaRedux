# 1.3.0

## General
- **Mod compatibility**: Familiar, Incantation, Ouija and Flower Pot now work with suits and ranks from other mods. Golden Joker counts Rare and rarer Jokers from other mods. To Do List, Driver's License, Stone Joker, Steel Joker and Raised Fist work with enhancements and ranks from other mods. Certificate can add seals from other mods. Four Fingers no longer breaks Jokers from other mods. Banner, Mystic Summit, Ride the Bus, Ceremonial Dagger, Joker, Yorick, Square Joker, Flash Card and Hit the Road now work with mods that change how Jokers upgrade.
- **Talisman and Amulet**: Burnt Joker, Credit Card, Delayed Gratification and Bootstraps now work with very large numbers.
- **Descriptions**: Several descriptions were improved and fixed, and now read cleaner. The Wheel of Fortune shows edition tooltips again.
- **README**: Amulet added to compatible mods.

## Balance
- **Credit Card**: Cost is now $4 instead of $1.
- **Flash Card**: Cost is now $6 instead of $5.
- **Hit the Road**: Now gains X0.1 Mult for every Jack discarded instead of X0.05, and resets when the Boss Blind is defeated, like Campfire.
- **Satellite**: Cost is now $7 instead of $6.
- **Shoot the Moon**: Now an Uncommon Joker instead of Common. Cost is now $7 instead of $5.
- **To Do List**:
  - The reward is now $25 instead of $20.
  - Task difficulty is rebalanced. The tasks in one list share a difficulty budget, so a hard task comes with an easier one. Difficulty rises with the Ante and then levels off, so early Antes are no longer too easy and late Antes are no longer too hard. A higher Stake makes tasks harder.
  - New tasks are made once the new Ante's blinds and Boss are known, so they take the Boss into account (The Needle, The Water and The Eye).

## Joker Fixes
- **Cartomancer**: "+1 Tarot" no longer appears twice when the Joker is copied by Blueprint, Brainstorm or Abstract Joker.
- **Ceremonial Dagger**: Jokers like Riff-raff can now fill the destroyed Joker's slot right away. No longer destroys Jokers that other mods protect.
- **Certificate**: No longer shown as compatible with Blueprint and Brainstorm (the copy did nothing).
- **Chaos the Clown**: A copy of an upgraded Chaos now gives all of its free Rerolls right away. A debuffed Chaos no longer gives free Rerolls.
- **Fortune Teller** / **Constellation**: Blueprint and Brainstorm no longer show a wrong X Mult message.
- **Four Fingers** / **Stuntman**: Selling Four Fingers with 1 hand left no longer leaves you with 0 hands.
- **Ice Cream**: Shows "-10" after each hand and "Melted!" when it melts, like in vanilla.
- **Joker Stencil** / **Throwback**: The X Mult stored on the Joker now always matches the "Currently" value, so mods that read it get the right number.
- **Loyalty Card**: Fixed a double shake animation.
- **Mystic Summit**: Now shows "Upgrade!" instead of its total Mult when it upgrades.
- **Satellite**: The extra Planet level-up now happens before the Planet card disappears, with an "Again!" message. Blueprint and Brainstorm can now copy it.
- **Shoot the Moon**: Now works with Smeared Joker and Wild Cards. Stone Cards no longer count.
- **Showman**: Legendary Jokers can now also appear in the shop when other mods change shop weights. Jokers from Rare and Uncommon Tags no longer turn into Legendary Jokers.
- **The Idol**: Fixed a rare "ERROR" in the description.
- **To Do List**:
  - On a new Ante the tasks were sized as if only one round was left, so "Play hands" and "Discard" asked for just 3-4 hands and 2-3 discards. They are now sized for the whole Ante.
  - "Trigger Jokers" now counts only Jokers that actually trigger (give Chips, Mult, money or retriggers). Debuffed Jokers don't count.
- **Vagabond**: The "Tarot", "Planet" or "Spectral" message now appears together with the Joker's other effects, in the right order.
- **Walkie Talkie**: Stone Cards no longer count as having a rank.

## Tarot and Spectral Fixes
- **Hex**: No longer destroys a Joker when no Joker can get Polychrome.
- **Ouija**: -1 hand size now starts from the next round, as the description says.
# Changelog

## 1.2.0

### General
- **Amulet**: Jokers that read hand levels, money or scores now also work with Amulet's default settings.
- **Chances**: Marble Joker, Seance, Sixth Sense, Superposition and The Wheel of Fortune now roll and show their chances through Steamodded, so effects from other mods that change probabilities apply to them too.
- **Descriptions**: Shoot the Moon and Matador now say that the cards must be scored. Clever, Crafty, Crazy, Devious, Droll, Jolly, Mad, Sly, Wily and Zany Joker now say the bonus is for each additional level, since level 1 is already included.
- **License**: Added a LICENSE file with the MIT license.
- **Mod loader**: Errors while loading a file are now written to the Steamodded log, with a summary of every file that failed to load.

### Balance
- **Bull** and **Bootstraps**: Money from selling cards now counts too: every $1 you earn, from any source, gives Chips or Mult.
- **Fortune Teller**: The Tarot chance bonus in the shop is reduced from 20% to 10%, and the description now says it slightly increases the chance.
- **Green Joker**: Back to the vanilla version, which gives Mult instead of X Mult: +3 Mult per hand played and -3 Mult per discard.

### Joker Fixes
- **8 Ball**: Fixed Tarot cards being created beyond the consumable slot limit. Slots reserved by other effects are now taken into account.
- **Abstract Joker**:
  - Fixed "Currently copying" showing the internal key instead of the Joker's name for modded Jokers.
  - It can now copy Jokers of modded rarities. Rarities the game never rolls on its own are treated as Legendary and still can't be copied.
  - The copied effects now start from the very beginning, in Joker order: the "when Blind is selected" effect is copied as soon as the target is chosen, and the "end of round" effect before the copying is reset. The tooltip now says "When Blind is selected", like the vanilla Joker.
  - Fixed Blueprint and Brainstorm copying Abstract Joker: the copied effect now belongs to the copier, with its own counters, instead of being recorded on Abstract Joker.
  - Big numbers from Talisman or Amulet are now kept when a run is loaded after the copied Joker was sold or destroyed. Before, they were lost, so the copy could get weaker, give nothing or crash.
  - An error in the copied Joker no longer affects the Jokers that follow.
- **Ancient Joker**: Stone Cards now count as one extra rank when the poker hand is detected, so they also help make Two Pair and Full House. Before, only Pair and Three, Four and Five of a Kind were detected.
- **Chicot**:
  - The Boss Blind score reduction now works with very large scores when Talisman or Amulet is installed.
  - The reduction now starts from the Boss Blind's current score. Before, it was recalculated from the Ante, which undid other effects and could even raise the score. Several Chicots still reduce it by 15% each.
- **Clever, Crafty, Crazy, Devious, Droll, Jolly, Mad, Sly, Wily and Zany Joker**: No longer crash on very high poker hand levels when Talisman or Amulet is installed.
- **Credit Card**:
  - Fixed the free purchase not working when the Joker was taken from a booster pack opened in the shop. Prices now update right away instead of only after reloading the game.
  - Shop items no longer stay free after Credit Card is sold, destroyed or debuffed.
  - With two Credit Cards, selling one no longer removes the free purchase of the other.
- **Delayed Gratification**: The +50% sell value bonus for defeating a Boss Blind no longer adds an extra $1 when the stored amount is even. Odd amounts still round up.
- **Faceless Joker**:
  - A Blueprint or Brainstorm placed before it no longer retriggers the first number card. Each scored number card is counted once, and every 3rd one is retriggered by it and by each copy, in any Joker order.
  - Works with Pareidolia: every card with a rank counts as a face card, so all of them are debuffed. Stone Cards have no rank and are not affected.
- **Fibonacci**: The Mult is still given once per rank in each hand, but now every time that same card scores, so retriggers repeat the bonus. A second card of the same rank in that hand still gets nothing. Before, a retrigger of the first card was blocked as well.
- **Four Fingers**: Fixed the vanilla 4-card Straight and Flush effect coming back after loading a saved run.
- **Golden Ticket**: The extra money for Gold Cards held in hand now works with any chain of Blueprint and Brainstorm. Before, only a Blueprint directly to its left and a Brainstorm were counted. Held Gold Cards now show and pay the total in one go ($5 with one Golden Ticket).
- **Greedy, Lusty, Wrathful and Gluttonous Joker**: The Mult now counts every card of the suit in the full deck, including debuffed ones. Debuffed cards still do not score.
- **Ice Cream**: The time towards the next -5 Chips is now saved with the run, so restarting the game no longer resets it.
- **Luchador**: The Boss Blind score reduction now works with very large scores when Talisman or Amulet is installed.
- **Marble Joker**: Jokers that react to cards being added to the deck now receive the actual Stone Card. Before, they received a placeholder, which could crash Jokers from other mods.
- **Misprint**: The tooltip no longer breaks other mods that request only a Joker's variables.
- **Mr. Bones**:
  - The description shown once the threshold reaches its maximum is now registered reliably.
  - Now saves you with very large scores when Talisman or Amulet is installed. Before, scores above 1e308 never counted as reaching the threshold.
- **Obelisk**: An error while calculating no longer leaves the blueprint flag set for the Jokers that follow.
- **Pareidolia**: Debuffs that depend on face cards (Faceless Joker, The Plant) now update as soon as Pareidolia is gained or lost. Its effect also stops as soon as it is sold.
- **Red Card**:
  - Discards forced by The Hook no longer trigger the effect.
  - A pending draw is now always cleared, even when the deck is empty or the round changes.
  - It now takes into account how many cards you can play, and the current Flush and Straight sizes (Four Fingers, Shortcut and Jokers from other mods), so it no longer plans a Flush or Straight that can't be played.
  - With Ancient Joker, Stone Cards now count as one rank when planning the draw, so it can draw a Stone Card that helps make a hand. Before, this only worked when the whole hand fit in one play.
- **Runner**: The description now shows the current gain in its first line, which grows by +5 after each Straight, instead of a separate "Next gain" line.
- **Sixth Sense**: Free consumable slots are now checked in Joker order, counting slots already reserved by Jokers to its left. Without room it shows "No Room!" and does nothing more until the end of the round.
- **To Do List**:
  - Tasks can no longer be impossible. Every amount is limited by the hands, discards and cards that really remain, and by the current Boss Blind. A kind of task that cannot be done at all is not created.
  - Cards discarded at random by The Hook now count towards the face, number and suit tasks. The Hook's discard itself is not your discard and does not count towards "Make discards" tasks.
  - One discarded card now counts towards every task it fits.
  - Poker hand tasks now count only the hand that is named. A hand no longer also counts for the simpler hands it contains.
  - Going down an Ante no longer regenerates the tasks or lets the reward be earned again. Tasks now reset only when a new highest Ante is reached.
  - Tasks are now rolled with the game's own random generator and the run seed, so the same seed produces the same tasks and the chances are no longer skewed.
  - The tooltip in the main menu and collection now shows a set of varied example tasks instead of leftover or duplicated lines.
- **Red Card**, **Scholar**, **To Do List**: Poker hand levels, chips and Mult are now read correctly when Talisman or Amulet is installed. Before, Scholar and To Do List treated every hand as level 1, and Red Card fell back to a fixed hand order.
- **Vagabond**: A large amount of money is no longer treated as $0 when Talisman or Amulet is installed.
- **Walkie Talkie**: A retrigger copied by Blueprint or Brainstorm is now counted once. Before, it was counted two or more times.

### Consumable Fixes
- **Familiar** and **Incantation**:
  - With Pareidolia, Stone Cards are no longer treated as face cards: Incantation no longer picks them and Familiar can destroy them.
  - Jokers that react to cards being added to the deck now receive the actual created cards instead of placeholders.
- **Ouija**: Cards of suits added by other mods now keep their suit when their rank changes.
- **The Wheel of Fortune**: The "Nope!" text is now placed correctly when the card is used inside any booster pack.

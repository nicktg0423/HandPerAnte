# HandPerAnte

Your hand size in Balatro is the ante. One card at Ante 1, two at Ante 2, and it keeps growing in endless.

## What it does

| Ante | Hand size |
|---|---|
| 1 | 1 card |
| 2 | 2 cards |
| 8 | 8 cards, the vanilla hand size |
| 9 and beyond | One more card every ante, with no cap |

**Everything else that changes hand size still stacks on top.** Juggler, Turtle Bean, the Juggle Tag, Paint Brush, Palette, The Manacle and a deck's own bonus all work as normal. Painted Deck starts at 3 cards.

## Rules

- Hand size follows the highest ante you have reached. Going back an ante (Hieroglyph, Petroglyph) never takes cards away.
- Hand size never drops below 1. At 0 the game would end the run on the next draw, so the mod holds it at 1 (for example, The Manacle at Ante 1).
- The Psychic still makes you play 5 cards. Below 5 cards it cannot be beaten. This is left as is on purpose.
- A single card in hand sits in the middle of the hand area instead of at the left edge.
- Starting a run at 1 card unlocks the Palette voucher on a profile that has not unlocked it yet, the same as reducing hand size to 5 does in the normal game.

## Installation

Requires Steamodded 1.0.0~BETA-1620a or newer.

Place the folder in your Balatro mods directory:

```
Balatro/
  Mods/
    HandPerAnte/
      HandPerAnte.json
      HandPerAnte.lua
```

## Settings

Under Mods, Hand Per Ante, Config.

| Setting | Default | What it does |
|---|---|---|
| Enable Hand Per Ante | On | The whole mod. Applies from the next new run |

A run started with the mod off, or without the mod installed, is left alone when you continue it.

## Compatibility

Works alongside HandyBalatro and JokerDisplay. Other mods that change hand size should stack with it. Challenge decks that change the starting hand size shift every ante up or down by the same amount, never below 1.

## Credits

Built by NickTG for the channel.

## License

MIT. See LICENSE.

--- Hand Per Ante, by NickTG. v1.0.0 is v0.1.1 republished for the public release.
--- v0.1.0 (9 Oct 2026): first build. v0.1.1: a lone card is centred.
--- Your hand size is the ante: 1 card at Ante 1, 2 at Ante 2 ... 8 at Ante 8, and it keeps
--- growing in endless.
---
--- BUILT AGAINST WHAT NICK RUNS: Steamodded 1.0.0~BETA-1620a ("smods/...") and the lovely
--- dump of 2 Oct ("dump/..."). Line numbers point into those.
---
--- HOW IT WORKS
---   Hand size under Steamodded is card_limits.base + card_limits.mod + card_limits.extra_slots
---   (smods/src/utils.lua:3559). G.hand:change_size(d) just adds d to .mod, synchronously
---   (dump/cardarea.lua:111-116). Juggler, Turtle Bean, Juggle Tag, The Manacle and the rest
---   all go through it, so this mod does too and everything else stacks on top.
---   1. New run: change_size(ante - 8), so 1 card at Ante 1. A deck's own bonus is already
---      in .base (Painted Deck: back applied at dump/game.lua:2112, hand built at :2325),
---      so Painted starts at 3. Nick's call: deck bonuses stack.
---   2. The ante only ever changes in ease_ante's queued event (dump/functions/
---      common_events.lua:205, the one writer). After every ease_ante this mod queues its
---      own event; when the ante passes the highest reached so far, hand size goes up by
---      the difference. Going back an ante (Hieroglyph) never takes cards away. Nick's call.
---   3. Hand size never drops below 1. At 0 the next draw is an instant game over
---      (dump/functions/state_events.lua:304), e.g. The Manacle at Ante 1. The mod adds a
---      floor amount to .mod only while base + mod would be below 1, and takes it back as soon
---      as it isn't. Negative playing cards are left out of that sum on purpose: their extra
---      slot leaves with the card. Re-checked on Continue.
---   Challenge decks that set their own hand size count as a bonus on top of 8, like a deck.
---   The Psychic is left vanilla (Nick's call): below 5 cards it cannot be beaten.
---   Runs started without the mod, or with it disabled, are never touched.
---   State lives in G.GAME.ntghpa, so it saves and loads with the run.

local THIS_MOD = SMODS.current_mod          -- must be captured at load time
local cfg      = THIS_MOD.config
if cfg.enabled == nil then cfg.enabled = true end
local CONFIG_VERSION = 1
if cfg.cfg_version ~= CONFIG_VERSION then cfg.cfg_version = CONFIG_VERSION end

local VANILLA_HAND = 8   -- dump/functions/misc_functions.lua starting_params.hand_size

local function log(msg) sendInfoMessage(msg, 'HandPerAnte') end

local function state()
    return G and G.GAME and G.GAME.ntghpa
end

local function hand_limits()
    return G and G.hand and G.hand.config and G.hand.config.card_limits
end

--- Size the player actually gets, as Steamodded will compute it next frame, with its parts.
local function current_size()
    local l = hand_limits()
    if not l then return nil end
    return ('%d [base %s mod %s extra %s used %s]'):format(
        (l.base or 0) + (l.mod or 0) + (l.extra_slots or 0) - (l.extra_slots_used or 0),
        tostring(l.base), tostring(l.mod), tostring(l.extra_slots), tostring(l.extra_slots_used))
end

----------------------------------------------------------------------
-- The floor: keep hand size at least 1 without fighting anything else.
-- st.floor is how much this mod has added to .mod for that purpose alone.
----------------------------------------------------------------------
--- Counts base + mod only. Negative playing cards add slots only while they sit in the
--- hand, so counting them would let hand size reach 0 once one is played (review finding).
local function enforce_floor(reason)
    local st, l = state(), hand_limits()
    if not st or not l then return end
    local raw = (l.base or 0) + (l.mod or 0) - (st.floor or 0)
    local want = math.max(0, 1 - raw)
    if want ~= (st.floor or 0) then
        l.mod = (l.mod or 0) + want - (st.floor or 0)
        log(('Floor %s: hand size without the floor %d, floor %d -> %d (%s)'):format(
            want > 0 and 'on' or 'off', raw, st.floor or 0, want, tostring(reason)))
        st.floor = want
    end
end

local ref_change_size = CardArea.change_size
function CardArea:change_size(delta)
    local ret = ref_change_size(self, delta)
    if G and self == G.hand and state() then enforce_floor('change_size ' .. tostring(delta)) end
    return ret
end

----------------------------------------------------------------------
-- A lone card sits in the middle of the hand.
-- align_cards places card k at fraction (k-1)/max(max_cards-1, 1) across the hand, with
-- max_cards = max(#cards, temp_limit) and temp_limit = max(#cards, card_limit)
-- (dump/cardarea.lua:491-493, :302). With a hand size of 1 that is 0/1 = the left edge.
-- At any bigger hand size the same formula already centres a single card (fraction 0.5),
-- so only the max_cards == 1 case is moved, to the same 0.5. Runs after the game's own pass.
----------------------------------------------------------------------
local ref_align_cards = CardArea.align_cards
function CardArea:align_cards(...)
    local ret = ref_align_cards(self, ...)
    if G and self == G.hand and self.config.type == 'hand' and #self.cards == 1
        and math.max(#self.cards, self.config.temp_limit or 0) <= 1
        and not (G.view_deck and G.view_deck[1] and G.view_deck[1].cards) then
        local card = self.cards[1]
        if card and not card.states.drag.is then
            card.T.x = self.T.x + 0.5 * (self.T.w - self.card_w) + 0.5 * (self.card_w - card.T.w)
                + card.shadow_parrallax.x / 30
        end
    end
    return ret
end

----------------------------------------------------------------------
-- Ante changes.
----------------------------------------------------------------------
local function sync_to_ante()
    local st = state()
    if not st or not (G.GAME.round_resets and G.hand) then return end
    local ante = G.GAME.round_resets.ante or 1
    if ante > st.max_ante then
        local delta = ante - st.max_ante
        st.max_ante = ante
        G.hand:change_size(delta)
        log(('Ante %d (new highest): +%d hand size, now %s'):format(ante, delta, tostring(current_size())))
    else
        log(('Ante %d (highest %d): hand size unchanged at %s'):format(ante, st.max_ante, tostring(current_size())))
    end
end

local ref_ease_ante = ease_ante
function ease_ante(mod)
    local ret = ref_ease_ante(mod)
    if state() then
        --- ease_ante changes the ante inside an event it queues; this one runs after it.
        G.E_MANAGER:add_event(Event({ trigger = 'immediate', func = function()
            sync_to_ante(); return true
        end }))
    end
    return ret
end

----------------------------------------------------------------------
-- New run or Continue.
----------------------------------------------------------------------
local ref_start_run = Game.start_run
function Game:start_run(args)
    local ret = ref_start_run(self, args)
    local loaded = args and args.savetext
    if loaded then
        local st = state()
        if st then
            enforce_floor('continue')
            log(('Continue: highest ante %d, floor %d, hand size %s'):format(st.max_ante, st.floor or 0, tostring(current_size())))
        else
            log('Continue: this run was started without Hand Per Ante, leaving it alone')
        end
    elseif cfg.enabled then
        local ante = (G.GAME.round_resets and G.GAME.round_resets.ante) or 1
        G.GAME.ntghpa = { v = 1, max_ante = ante, floor = 0 }
        G.hand:change_size(ante - VANILLA_HAND)
        log(('Run start: v%s, ante %d, deck %s, hand size %s (vanilla base %d)'):format(
            tostring(THIS_MOD.version), ante, tostring(G.GAME.selected_back and G.GAME.selected_back.name),
            tostring(current_size()), VANILLA_HAND))
    else
        log('Run start: disabled in config, vanilla hand size')
    end
    return ret
end

----------------------------------------------------------------------
-- Config tab.
----------------------------------------------------------------------
THIS_MOD.config_tab = function()
    return {
        n = G.UIT.ROOT,
        config = { align = 'cm', padding = 0.1, colour = G.C.CLEAR },
        nodes = {
            { n = G.UIT.R, config = { align = 'cm', padding = 0.02 }, nodes = {
                create_toggle({ label = 'Enable Hand Per Ante', ref_table = cfg, ref_value = 'enabled' }),
            } },
            { n = G.UIT.R, config = { align = 'cm', padding = 0.03 }, nodes = {
                { n = G.UIT.T, config = { text = 'Hand size equals the ante. Applies from the next new run.', scale = 0.3, colour = G.C.UI.TEXT_LIGHT, shadow = true } },
            } },
        },
    }
end

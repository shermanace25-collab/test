--[[
  Project Explore  --  ESP + Aimbot
  Place 14772802900.

  Target sources, in order:
    1. entity.GetPlayers()  - canonical. Gives GetBounds/GetBonesScreen/DistanceTo
       for free, plus Name, Team and RigType.
    2. Workspace scan (automatic, only when the cache finds nobody) - for characters
       the entity cache misses. This game wraps characters in a Part, so the walk
       descends into Folders and unwraps Parts looking for a Model with a Humanoid:
         Workspace.Lobby.Players.Port<N> [Part] -> <Role> Model

  Teams: the lobby only has Teams.Gangstas, but once a round starts the game
  creates Blue and Red and both fill up. Which side you are on is not readable
  on this loader, so the Your Side dropdown under Team Check is the only source
  and has to be set to match. Change side, change the dropdown.
]]

-- One name for the menu tab, the loader log tag and the notifications, so they cannot
-- drift apart and the next rename is a single edit.
local SCRIPT_NAME = "Explore"
local TAG = "[" .. SCRIPT_NAME .. "]"

print(TAG .. " loading")

--------------------------------------------------------------------------------------
-- compat layer
-- Every API name is resolved once at load: snake_case, then camelCase, then
-- PascalCase. pcall(nil_fn) returns false with no message, so an unresolved name
-- is otherwise a silent no-op that never reports why nothing happened.
--------------------------------------------------------------------------------------
local A = {
   Draw = {}, Input = {}, Camera = {}, Raycast = {},
   Entity = {}, Menu = {}, Notify = {}, Utility = {}, Thread = {},
   Game = {},
}

local function bind(out, ns, snake, pascal, camel)
   if type(ns) ~= "table" then return end
   out[pascal] = ns[snake] or ns[camel] or ns[pascal]
end

bind(A.Game,    _G.game,       "get_service",        "GetService",       "getService")
bind(A.Game,    _G.game,       "local_player",       "LocalPlayer",      "localPlayer")

bind(A.Draw,    _G.draw,       "get_screen_size",    "GetScreenSize",    "getScreenSize")
bind(A.Draw,    _G.draw,       "world_to_screen",    "WorldToScreen",    "worldToScreen")
bind(A.Draw,    _G.draw,       "box",                "Box",              "box")
bind(A.Draw,    _G.draw,       "corner_box",         "CornerBox",        "cornerBox")
bind(A.Draw,    _G.draw,       "text",               "Text",             "text")
bind(A.Draw,    _G.draw,       "get_text_size",      "GetTextSize",      "getTextSize")
bind(A.Draw,    _G.draw,       "line",               "Line",             "line")
bind(A.Draw,    _G.draw,       "circle",             "Circle",           "circle")
bind(A.Draw,    _G.draw,       "rect",               "Rect",             "rect")
bind(A.Draw,    _G.draw,       "rect_filled",        "RectFilled",       "rectFilled")

bind(A.Input,   _G.input,      "is_key_down",        "IsKeyDown",        "isKeyDown")
bind(A.Input,   _G.input,      "move_mouse",         "MoveMouse",        "moveMouse")
bind(A.Input,   _G.input,      "get_mouse_position", "GetMousePosition", "getMousePosition")
bind(A.Input,   _G.input,      "get_screen_center",  "GetScreenCenter",  "getScreenCenter")

bind(A.Camera,  _G.camera,     "get_position",       "GetPosition",      "getPosition")
bind(A.Camera,  _G.camera,     "get_look_vector",    "GetLookVector",    "getLookVector")
bind(A.Camera,  _G.camera,     "look_at",            "LookAt",           "lookAt")

bind(A.Raycast, _G.raycast,    "is_ready",           "IsReady",          "isReady")
bind(A.Raycast, _G.raycast,    "is_player_visible",  "IsPlayerVisible",  "isPlayerVisible")
bind(A.Raycast, _G.raycast,    "is_visible",         "IsVisible",        "isVisible")

bind(A.Entity,  _G.entity,     "get_local_player",   "GetLocalPlayer",   "getLocalPlayer")
bind(A.Entity,  _G.entity,     "get_players",        "GetPlayers",       "getPlayers")
bind(A.Entity,  _G.entity,     "get_player_count",   "GetPlayerCount",   "getPlayerCount")

bind(A.Menu,    _G.menu,       "add_tab",            "AddTab",           "addTab")
bind(A.Menu,    _G.menu,       "add_group",          "AddGroup",         "addGroup")
bind(A.Menu,    _G.menu,       "add_label",          "AddLabel",         "addLabel")
bind(A.Menu,    _G.menu,       "add_separator",      "AddSeparator",     "addSeparator")
bind(A.Menu,    _G.menu,       "add_input",          "AddInput",         "addInput")
bind(A.Menu,    _G.menu,       "add_checkbox",       "AddCheckbox",      "addCheckbox")
bind(A.Menu,    _G.menu,       "add_slider_int",     "AddSliderInt",     "addSliderInt")
bind(A.Menu,    _G.menu,       "add_combo",          "AddCombo",         "addCombo")
bind(A.Menu,    _G.menu,       "add_hotkey",         "AddHotkey",        "addHotkey")
bind(A.Menu,    _G.menu,       "add_button",         "AddButton",        "addButton")
bind(A.Menu,    _G.menu,       "add_colorpicker",    "AddColorpicker",   "addColorpicker")
bind(A.Menu,    _G.menu,       "get",                "Get",              "get")
bind(A.Menu,    _G.menu,       "get_key",            "GetKey",           "getKey")
bind(A.Menu,    _G.menu,       "get_color",          "GetColor",         "getColor")
bind(A.Menu,    _G.menu,       "set_key",            "SetKey",           "setKey")
bind(A.Menu,    _G.menu,       "set",                "Set",              "set")
bind(A.Menu,    _G.menu,       "set_visible",        "SetVisible",       "setVisible")
bind(A.Menu,    _G.menu,       "set_color",          "SetColor",         "setColor")
bind(A.Menu,    _G.menu,       "get_string",         "GetString",        "getString")
bind(A.Menu,    _G.menu,       "set_text",           "SetText",          "setText")

bind(A.Notify,  _G.notify,     "success",            "Success",          "success")
bind(A.Notify,  _G.notify,     "error",              "Error",            "error")

bind(A.Utility, _G.utility,    "world_to_screen",    "WorldToScreen",    "worldToScreen")
bind(A.Utility, _G.utility,    "get_screen_size",    "GetScreenSize",    "getScreenSize")
bind(A.Utility, _G.utility,    "get_delta_time",     "GetDeltaTime",     "getDeltaTime")
bind(A.Utility, _G.utility,    "is_valid",           "IsValid",          "isValid")

bind(A.Thread,  _G.thread,     "create",             "Create",           "create")
bind(A.Thread,  _G.thread,     "is_running",         "IsRunning",        "isRunning")

--------------------------------------------------------------------------------------
-- aliases
--------------------------------------------------------------------------------------
local math_abs, math_floor = math.abs, math.floor
local math_min, math_max, math_sqrt = math.min, math.max, math.sqrt
local format = string.format

local VK = {
   LMB = 0x01, RMB = 0x02, MMB = 0x04,
   ENTER = 0x0D,
   SHIFT = 0x10, CTRL = 0x11, ALT = 0x12, SPACE = 0x20,
   F1 = 0x70, F2 = 0x71, F3 = 0x72,
   X = 0x58, C = 0x43, V = 0x56, F = 0x46, G = 0x47,
}

-- Hot entry points and draw primitives, resolved once into a single table. These are read
-- every frame and some of them once per target, and going through the A table each time is a
-- chain of lookups for a value that cannot change. One table rather than thirty locals on
-- purpose: this file is a single main chunk and luau caps that at 200 registers, so a local
-- overflow here is a hard load failure rather than a slowdown.
local function keep(fn)
   if type(fn) == "function" then return fn end
   return function() end
end

local H = {
   -- entry points called every frame
   dt        = A.Utility.GetDeltaTime,
   players   = A.Entity.GetPlayers,
   localplr  = A.Entity.GetLocalPlayer,
   count     = A.Entity.GetPlayerCount,
   campos    = A.Camera.GetPosition,
   camlook   = A.Camera.LookAt,
   key       = A.Input.IsKeyDown,
   mouse     = A.Input.MoveMouse,
   centre    = A.Input.GetScreenCenter,
   drawsize  = A.Draw.GetScreenSize,
   utilsize  = A.Utility.GetScreenSize,
   uw2s      = A.Utility.WorldToScreen,
   dw2s      = A.Draw.WorldToScreen,
   valid     = A.Utility.IsValid,
   vis       = A.Raycast.IsVisible,
   pvis      = A.Raycast.IsPlayerVisible,
   mget      = A.Menu.Get,
   mgetkey   = A.Menu.GetKey,
   getsvc    = A.Game.GetService,
   textsize  = A.Draw.GetTextSize,
   -- primitives. A missing one becomes a no-op here rather than a pcall at every call site:
   -- a full lobby draws on the order of a thousand primitives a frame and each one used to
   -- be individually wrapped, which cost more than the drawing did. Errors are still
   -- contained, one pcall per target around a whole ESP draw, so a bad frame costs that one
   -- player that one frame and not the script.
   line      = keep(A.Draw.Line),
   text      = keep(A.Draw.Text),
   circle    = keep(A.Draw.Circle),
   box       = keep(A.Draw.Box),
   cbox      = keep(A.Draw.CornerBox),
   rect      = keep(A.Draw.Rect),
   rectf     = keep(A.Draw.RectFilled),
   -- fixed UI colours
   w09       = { 1, 1, 1, 0.9 },
   w085      = { 1, 1, 1, 0.85 },
   w045      = { 1, 1, 1, 0.45 },
   -- the derived-colour caches, keyed weakly so a colour the script stops using goes with it
   dimcache  = setmetatable({}, { __mode = "k" }),
   darkcache = setmetatable({}, { __mode = "k" }),
   fovcache  = setmetatable({}, { __mode = "k" }),
   glocache  = setmetatable({}, { __mode = "k" }),
}

--------------------------------------------------------------------------------------
-- instance helpers
-- The API mixes casings across objects, so every read is case-tolerant.
--------------------------------------------------------------------------------------
-- Lowercased lookups are memoised. Only the part names in this script ever go through the
-- case-insensitive child lookup, and a per-lookup string.lower was an allocation on the
-- workspace scan path, which walks the tree every frame when the entity cache is empty.
local LOWER = {}

local function fld(obj, snake, pascal)
   if obj == nil then return nil end
   local v = obj[snake]
   if v == nil then v = obj[pascal] end
   return v
end

local function vec_xyz(v)
   if v == nil then return nil end
   local x = fld(v, "x", "X")
   if type(x) ~= "number" then return nil end
   local y = fld(v, "y", "Y")
   local z = fld(v, "z", "Z")
   if type(y) ~= "number" or type(z) ~= "number" then return nil end
   return x, y, z
end

local function inst_ok(o)
   if o == nil then return false end
   if H.valid then
      local ok, res = pcall(H.valid, o)
      if ok then return res and true or false end
   end
   return true
end

local function class_of(o)
   return fld(o, "classname", "ClassName")
end

-- pcall(p.GetChildren, p) rather than a wrapper closure: these three run once per node per
-- frame on the workspace path, and a closure per call is garbage the collector has to walk.
local function children(p)
   local out = {}
   if p == nil then return out end
   local ok, list = pcall(p.GetChildren, p)
   if ok and type(list) == "table" then
      for i = 1, #list do out[i] = list[i] end
   end
   return out
end

-- Case-insensitive child lookup: body part names are consistent, but the wrapper
-- names this game uses are not.
-- child lookups are memoised per character instance. A character's parts never change
-- identity, so the result (hit or miss) is cached for as long as the character exists:
-- the build path asks for the same bones for the same rig every frame, and each of those
-- was a FindFirstChild across the C bridge on a live loader. Weak keys let a character
-- that dies drop its cache with it.
local CHILD_CACHE = setmetatable({}, { __mode = "k" })

local function child_of(p, name)
   if p == nil then return nil end
   local by_name = CHILD_CACHE[p]
   if by_name == nil then
      by_name = {}
      CHILD_CACHE[p] = by_name
   end
   local hit = by_name[name]
   if hit ~= nil then
      -- a stored false is a cached miss: the rig did not have that name and it is not
      -- going to grow one, so the failed lookup also only ever happens once
      if hit == false then
         return nil
      end
      return hit
   end
   local found = nil
   local ok, direct = pcall(p.FindFirstChild, p, name)
   if ok and direct ~= nil then
      found = direct
   else
      local lowered = LOWER[name]
      if lowered == nil then
         lowered = string.lower(name)
         LOWER[name] = lowered
      end
      for _, ch in ipairs(children(p)) do
         local n = fld(ch, "name", "Name")
         if type(n) == "string" and n:lower() == lowered then
            found = ch
            break
         end
      end
   end
   by_name[name] = found or false
   return found
end

local function part_pos(p)
   if p == nil then return nil end
   local x, y, z = vec_xyz(fld(p, "position", "Position"))
   if x then return x, y, z end
   local cf = fld(p, "cframe", "CFrame")
   if cf then
      local pivot = fld(cf, "p", "p")
      if pivot == nil then pivot = fld(cf, "position", "Position") end
      x, y, z = vec_xyz(pivot)
      if x then return x, y, z end
   end
   return nil
end

-- Only the bone names the API actually projects. R6 and R15 are both covered, and
-- pairs whose parts are missing are simply skipped, so no rig branching is needed.
local BONE_LINKS = {
   { "Head", "Torso" },
   { "Torso", "HumanoidRootPart" },
   { "Torso", "Left Leg" }, { "Torso", "Right Leg" },
   { "Head", "UpperTorso" },
   { "UpperTorso", "LowerTorso" }, { "UpperTorso", "HumanoidRootPart" },
   { "LowerTorso", "HumanoidRootPart" },
   { "UpperTorso", "LeftUpperLeg" }, { "LeftUpperLeg", "LeftLowerLeg" },
   { "LeftLowerLeg", "LeftFoot" },
   { "UpperTorso", "RightUpperLeg" }, { "RightUpperLeg", "RightLowerLeg" },
   { "RightLowerLeg", "RightFoot" },
}

-- Kept apart from the trunk so the arms can be switched off on their own.
local BONE_ARMS = {
   { "UpperTorso", "LeftUpperArm" }, { "LeftUpperArm", "LeftLowerArm" },
   { "LeftLowerArm", "LeftHand" },
   { "UpperTorso", "RightUpperArm" }, { "RightUpperArm", "RightLowerArm" },
   { "RightLowerArm", "RightHand" },
}

-- GetBonesScreen hands back a dictionary and leaves the arm bones out of it, so the
-- bulk call on its own draws a trunk with nothing either side of it. Every documented
-- name is then requested one at a time and only the ones the bulk call missed are kept.
local BONE_FETCH = {
   "Head", "Torso", "HumanoidRootPart", "UpperTorso", "LowerTorso",
   "Left Arm", "Right Arm", "Left Leg", "Right Leg",
   "LeftUpperArm", "LeftLowerArm", "LeftHand",
   "RightUpperArm", "RightLowerArm", "RightHand",
   "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
   "RightUpperLeg", "RightLowerLeg", "RightFoot",
}

-- The bone dictionary is keyed by exact name and the API documents those names as
-- case-sensitive. Canonicalising on the way in means a differently-spelled key still
-- resolves instead of silently dropping every line, and both target paths end up with
-- the same key format.
--
-- The result is memoised. canon_bone is called once per bone per player per frame by the
-- old draw path, and string.lower plus string.gsub allocated two fresh strings every one
-- of those calls, which is several hundred throwaway strings a second for a value that can
-- only ever be one of the names in BONE_FETCH.
local CANON = {}
local function canon_bone(k)
   if type(k) ~= "string" then return nil end
   local c = CANON[k]
   if c then return c end
   local s = string.gsub(string.lower(k), "%s+", "")
   CANON[k] = s
   return s
end

-- Bones are stored as two flat arrays on the target, indexed by BONE_NAMES, not as a
-- dictionary keyed by name. Every segment the skeleton draws is a pair of integers into
-- those arrays, so the whole thing resolves to integer indexing done once at load, and a
-- full lobby costs zero tables and zero strings a frame. Slot 0 is unused and means the
-- bone is not on this rig, so the link tables can hold a 0 without a separate validity map.
local BONE_NAMES, BONE_INDEX = {}, {}
for i = 1, #BONE_FETCH do
   local c = canon_bone(BONE_FETCH[i])
   if c and BONE_INDEX[c] == nil then
      BONE_INDEX[c] = #BONE_NAMES + 1
      BONE_NAMES[#BONE_NAMES + 1] = c
   end
end
local BONE_SLOTS = #BONE_NAMES

-- BONE_FETCH paired with the slot it writes, so the two paths never have to look a name up
-- while they are filling a target.
local BONE_FETCH_IDX = {}
for i = 1, #BONE_FETCH do
   BONE_FETCH_IDX[i] = { BONE_FETCH[i], BONE_INDEX[canon_bone(BONE_FETCH[i])] }
end

local function slot_of(name)
   return BONE_INDEX[canon_bone(name)] or 0
end
local SLOT_HEAD   = slot_of("Head")
local SLOT_TORSO  = slot_of("Torso")
local SLOT_LARM   = slot_of("Left Arm")
local SLOT_RARM   = slot_of("Right Arm")

-- The link tables translated once: {slotA, slotB} per segment instead of two string keys.
local function links_as_slots(src)
   local out = {}
   for i = 1, #src do out[i] = { slot_of(src[i][1]), slot_of(src[i][2]) } end
   return out
end
local LINKS_TRUNK = links_as_slots(BONE_LINKS)
local LINKS_ARMS  = links_as_slots(BONE_ARMS)
local LINKS_R6    = { { SLOT_TORSO, SLOT_LARM }, { SLOT_TORSO, SLOT_RARM } }

local AIM_BONES = {
   { "Head" },
   { "UpperTorso", "Torso" },
   { "HumanoidRootPart", "LowerTorso", "Torso" },
}
local AIM_BONE_LABELS = { "Head", "UpperTorso / Torso", "HumanoidRootPart" }

-- The game calls its two sides Team Blue and Team Red. The menu shows Defenders and
-- Attackers because that is what they actually mean, and each label carries the word to
-- match on in the real team name, so the label and the game can disagree safely. Only
-- these two sides are listed: the spectator team is deliberately not offered, because
-- nobody wants their own side decided by picking spectators.
local TEAM_SIDES = {
   { "Defenders", "blue" },
   { "Attackers", "red" },
}
local TEAM_LABELS = { TEAM_SIDES[1][1], TEAM_SIDES[2][1] }

local function side_key(i)
   local s = TEAM_SIDES[(i or 0) + 1]
   return s and s[2] or ""
end

local function side_label(i)
   return TEAM_LABELS[(i or 0) + 1] or "-"
end

-- ESP colours as a fixed palette instead of a colour picker. A picker puts four
-- draggable bars in the menu, which is a lot of room to spend on one value, and picking
-- a near-black blue that reads as grey costs more effort than choosing a named colour.
-- Index order here is the order the dropdown shows, and Red is first so it stays the
-- default the script has always used.
local COLOURS = {
   { "Red",    { 1.00, 0.20, 0.20, 1 } },
   { "Blue",   { 0.25, 0.50, 1.00, 1 } },
   { "Green",  { 0.25, 0.90, 0.35, 1 } },
   { "Yellow", { 1.00, 0.90, 0.20, 1 } },
   { "Orange", { 1.00, 0.55, 0.10, 1 } },
   { "Purple", { 0.70, 0.35, 1.00, 1 } },
   { "Pink",   { 1.00, 0.40, 0.75, 1 } },
   { "Cyan",   { 0.20, 0.90, 0.95, 1 } },
   { "Lime",   { 0.60, 1.00, 0.10, 1 } },
   { "White",  { 1.00, 1.00, 1.00, 1 } },
   { "Grey",   { 0.65, 0.65, 0.65, 1 } },
   { "Black",  { 0.10, 0.10, 0.10, 1 } },
}
local COLOUR_LABELS = {}
for i, entry in ipairs(COLOURS) do COLOUR_LABELS[i] = entry[1] end

local function colour_at(i)
   local entry = COLOURS[(i or 0) + 1]
   return entry and entry[2] or COLOURS[1][2]
end

local function colour_name(i)
   return COLOUR_LABELS[(i or 0) + 1] or "-"
end

-- The FOV slider is shown in display units so it reads 0 to 180, while the radius actually
-- drawn and tested against is in pixels. The two ends are named rather than written into the
-- call so the relationship sits in one place: the slider runs 0 to FOV_DISPLAY_MAX, and
-- FOV_DISPLAY_MAX maps to FOV_REAL_MAX pixels, which is the largest radius worth having.
local FOV_DISPLAY_MAX = 180
local FOV_REAL_MAX = 1300
local FOV_DISPLAY_DEFAULT = 42
local FOV_REAL_DEFAULT = 300

-- Clamped, because a menu can still be holding a value from a build whose slider ran to
-- 2500, and an out-of-range read is not something the draw path should have to survive.
local function fov_display(v)
   v = tonumber(v) or FOV_DISPLAY_DEFAULT
   if v < 0 then v = 0
   elseif v > FOV_DISPLAY_MAX then v = FOV_DISPLAY_MAX end
   return math_floor(v + 0.5)
end

local function fov_real(d)
   return math_floor(d * FOV_REAL_MAX / FOV_DISPLAY_MAX + 0.5)
end

-- The visibility check is one dropdown rather than a checkbox plus a Dim/Hide box plus a
-- separate Colour box. None is the off state, Dim fades the players behind a wall, and
-- Colour paints them a second colour. The two colour pickers hang off this dropdown, and
-- only the Hidden one is conditional on the mode, because a visible colour is used in
-- every mode.
local VIS_NONE, VIS_DIM, VIS_COLOUR = 0, 1, 2
local VIS_MODE_ITEMS = { "None", "Dim", "Colour" }

--------------------------------------------------------------------------------------
-- menu
--------------------------------------------------------------------------------------

-- The default of every control is recorded here as it is registered. This build accepts
-- the default argument but does not reflect it in the widget, so everything opens
-- switched off; the recorded values are pushed back through menu.Set further down.
local DEFAULTS = {}
local KEY_DEFAULTS = {}

-- The parent tree, recorded as each control is registered. The parent option on the menu
-- is undocumented for combos and hotkeys and was letting children of a hidden ESP stay
-- on screen, so it is kept only for the nesting indent and menu.SetVisible is made the
-- real authority further down. ORDER matters: a parent is always registered before its
-- children, so one pass in registration order resolves the whole tree in a single sweep.
local ORDER = {}
local PARENT = {}

-- PARENT_TOUCH: ids whose own value must not decide whether their children show. Normally a
-- parent gates on its value, so ticking or setting a parent reveals its options. A combo
-- whose index 0 is a real choice cannot work that way, or picking the first option would
-- hide everything nested under it. The Hidden Players dropdown is the one case: index 0 is
-- None, a real selection, so its children answer to their own gates instead of the combo's
-- value. That never leaks: a child still has to pass its parent's visibility chain first.
local PARENT_TOUCH = {}

-- GATE: an extra condition on a child itself, for when a visible parent is not enough. The
-- Hidden Colour picker is the only one: its parent is the Hidden Players dropdown, which is
-- on whenever Visable Check is ticked, but the picker means nothing unless the mode picked is
-- the one that paints behind-a-wall players a second colour.
local GATE = {}

local function record(id, opts)
   ORDER[#ORDER + 1] = id
   PARENT[id] = (opts and opts.parent) or nil
end

-- One tab holding three groups. Splitting into separate half-width tabs was tried and
-- came back with an unusable menu, so the single tab stays: it is the layout known to
-- render, and the section headings below break the long column up just as well.
local TAB = SCRIPT_NAME
local LAYOUT = {
   P = { TAB, "Players" },
   A = { TAB, "Aim" },
   S = { TAB, "Setup" },
   C = { TAB, "Config" },
}
local function tg(k) return LAYOUT[k][1], LAYOUT[k][2] end

-- Section headings. Left in as no-ops: the heading text is in the label itself, and
-- AddLabel is not called because a decorative element is not worth a broken menu.
local function sec() end
local function note() end

-- Forward declarations. Both bodies need S, the team tables and the frame counters, all of
-- which are declared further down, so writing them here would capture globals instead.
local diag_text
local copy_text

-- Menu button. Nothing to cache and nothing to nest, so it stays out of DEFAULTS and ORDER:
-- a button in the Setup group is a top level action like Info Text, not a feature option,
-- and a value-less id in ORDER would be read back as a missing setting every frame.
local function btn(k, id, label, cb)
   local tab, grp = tg(k)
   pcall(A.Menu.AddButton, tab, grp, id, label, cb)
end

local function cbox(k, id, label, def, opts)
   local tab, grp = tg(k)
   pcall(A.Menu.AddCheckbox, tab, grp, id, label, def, opts)
   DEFAULTS[id] = def
   record(id, opts)
end
local function vsl(k, id, label, lo, hi, def, opts)
   local tab, grp = tg(k)
   pcall(A.Menu.AddSliderInt, tab, grp, id, label, lo, hi, def, "%d", opts)
   DEFAULTS[id] = def
   record(id, opts)
end
local function vco(k, id, label, items, def, opts)
   local tab, grp = tg(k)
   pcall(A.Menu.AddCombo, tab, grp, id, label, items, def, opts)
   DEFAULTS[id] = def
   record(id, opts)
end
local function abox(k, id, label, def, opts)
   local tab, grp = tg(k)
   pcall(A.Menu.AddCheckbox, tab, grp, id, label, def, opts)
   DEFAULTS[id] = def
   record(id, opts)
end
local function asl(k, id, label, lo, hi, def, opts)
   local tab, grp = tg(k)
   pcall(A.Menu.AddSliderInt, tab, grp, id, label, lo, hi, def, "%d", opts)
   DEFAULTS[id] = def
   record(id, opts)
end
local function aco(k, id, label, items, def, opts)
   local tab, grp = tg(k)
   pcall(A.Menu.AddCombo, tab, grp, id, label, items, def, opts)
   DEFAULTS[id] = def
   record(id, opts)
end
local function akey(k, id, label, def, opts)
   local tab, grp = tg(k)
   pcall(A.Menu.AddHotkey, tab, grp, id, label, def, opts)
   record(id, opts)
   -- kept apart from DEFAULTS on purpose: Set writes the wrong field on a hotkey,
   -- so these are pushed back through SetKey instead
   KEY_DEFAULTS[id] = def
end

if A.Menu.AddTab then pcall(A.Menu.AddTab, TAB, "M") end
if A.Menu.AddGroup then
   -- same_line is the built-in second column: Players takes the left half, Aim takes the
   -- right half of the same row, and Setup flows onto the next row under them. Config is
   -- same_line to the right of Setup, so it sits directly under the Aim column. Group order
   -- is what places the columns, so Aim has to be added second even though its widgets are
   -- registered further down the file. This only moves boxes around; no id, default, parent
   -- or binding is touched.
   pcall(A.Menu.AddGroup, TAB, "Players")
   pcall(A.Menu.AddGroup, TAB, "Aim", 0, true)
   pcall(A.Menu.AddGroup, TAB, "Setup")
   pcall(A.Menu.AddGroup, TAB, "Config", 0, true)
end

-- has to run before the team combo is registered, since the combo copies this list

-- Every checkbox in this menu loads OFF, masters and children alike. Ticking ESP only
-- reveals the sub-options, it does not switch any of them on: which parts of the ESP you
-- want is your call, not a side effect of opening the group. The same goes for Aimbot.
-- Sliders and dropdowns keep their values, since those are settings rather than switches
-- and are only read once their own parent is on.
--
-- One exception: Info Text stays on, because it is the only way to tell the script loaded
-- at all, and it sits at the top level rather than inside a feature.

note("P", "Draw players through walls")
cbox("P", "esp_on", "ESP", false, { key = VK.F2 })
vsl("P", "max_distance", "Max Distance", 10, 10000, 3000, { parent = "esp_on" })

sec("P", "-- Colours --")
-- One dropdown recolours the whole script: the ESP boxes, tracers, FOV ring and aimbot
-- target line all read this single pick, so there is no per-feature colour list to keep in
-- step. Hidden Colour is not listed here: it hangs off the Hidden Players dropdown and only
-- appears when the Colour mode that uses it is actually selected, so the two are never out
-- of step.
vco("P", "vis_color", "Colour", COLOUR_LABELS, 0, { parent = "esp_on" })

-- Each feature sits inside ESP, and the options that edit that feature hang off the
-- feature itself, so ticking Tracers or Teammates reveals its own settings and nothing
-- else. Head Dot is the exception: it hangs straight off ESP. Nested under Skeleton it
-- stayed on screen with ESP off, and a checkbox parented to a parented checkbox is the
-- one combination that reliably does not hide.
sec("P", "-- Box --")
-- Style hangs off the Box toggle, not off ESP, so picking a box style is something you do
-- once you have decided you want a box. 2D is the full outline and Corner is the bracket
-- style; both come from the same bounds, so switching between them costs nothing.
cbox("P", "box_on", "Box", false, { parent = "esp_on" })
vco("P", "box_style", "Style", { "2D", "Corner" }, 0, { parent = "box_on" })
cbox("P", "skeleton", "Skeleton", false, { parent = "esp_on" })
cbox("P", "skel_head", "Head Dot", false, { parent = "esp_on" })

-- Charms is the glowing aura ring around each character. Its colour hangs straight off
-- the toggle, the same way Hidden Colour hangs off its own feature, so switching the
-- feature on reveals the pick and switching it off puts the pick away with it.
sec("P", "-- Charm --")
cbox("P", "charm", "Charms", false, { parent = "esp_on" })
vco("P", "charm_color", "Charm Colour", COLOUR_LABELS, 7, { parent = "charm" })

sec("P", "-- Labels --")
cbox("P", "names", "Names", false, { parent = "esp_on" })
cbox("P", "distance", "Distance", false, { parent = "esp_on" })

-- Tracers carry their own origin. Width is fixed, same reasoning as the skeleton width:
-- one line of menu for a value that never changes. Their colour is the single Colour
-- dropdown in the Colours section at the top of this tab, like every other feature.
sec("P", "-- Tracers --")
cbox("P", "tracers", "Tracers", false, { parent = "esp_on" })
vco("P", "tracer_from", "Tracer From", { "Bottom", "Centre" }, 0, { parent = "tracers" })

sec("P", "-- Team Check --")
-- Your Side is set by hand and it is the only thing the filter uses: the game reports
-- Blue and Red correctly but this loader will not say which one you are on, so there is
-- nothing to read. Pick the side you are playing and Tick Team Check hides that side.
cbox("P", "friendly", "Team Check", false, { parent = "esp_on" })
vco("P", "friendly_side", "Your Side", TEAM_LABELS, 0, { parent = "friendly" })
akey("P", "side_key", "Switch Side Key", VK.ENTER, { parent = "friendly" })

sec("P", "-- Filters --")
sec("P", "-- Visibility --")
-- The Visable Check tick is the master: off, no player is ever treated differently. On, the
-- Hidden Players dropdown decides how, and it has three entries rather than two. None is
-- the do-nothing case, Dim fades the players behind a wall, and Colour paints them a
-- second hue. Colour used to be a tick of its own under this dropdown, which meant ticking
-- Dim and forgetting it silently did nothing; as an entry in the list it cannot be missed.
--
-- Hidden Colour hangs off the mode dropdown itself and only appears when Colour is the
-- picked entry, via the GATE wired up after the settings table exists: a combo parent would
-- read index 0 as off and hide its children exactly when the mode was None, so PARENT_TOUCH
-- bypasses that and the gate does the real filtering. None and Dim paint no second hue, so
-- the picker is hidden for them.
cbox("P", "visible", "Visable Check", false, { parent = "esp_on" })
vco("P", "vis_mode", "Hidden Players", VIS_MODE_ITEMS, 0, { parent = "visible" })
vco("P", "hidden_color", "Hidden Colour", COLOUR_LABELS, 10, { parent = "vis_mode" })

note("A", "Aim at whoever is nearest the crosshair")
abox("A", "aim_on", "Aimbot", false, { key = VK.F1 })
-- sits directly under the toggle and is the only gate there is: bind a key and the
-- aimbot only fires while it is held, clear it and the aimbot runs on its own
-- Mouse button 2, the right button, on the usual 1/2/3 convention where 1 is left and 3 is
-- middle. The scroll wheel was the default before and never reported held on this machine,
-- so the lock could not be engaged with it. Still rebindable if right click is spoken for.
akey("A", "lock_key", "Lock Key", VK.RMB, { parent = "aim_on" })

sec("A", "-- Target --")
aco("A", "aim_bone", "Aim At", AIM_BONE_LABELS, 0, { parent = "aim_on" })
abox("A", "sticky", "Stick To One Target", false, { parent = "aim_on" })
abox("A", "only_visible", "Only Visible", false, { parent = "aim_on" })
abox("A", "aim_ignore_friends", "Ignore Teammates", false, { parent = "aim_on" })

sec("A", "-- Movement --")
asl("A", "smooth", "Smoothness", 1, 100, 50, { parent = "aim_on" })
aco("A", "aim_method", "Aim Method", { "Mouse", "Camera" }, 0, { parent = "aim_on" })

sec("A", "-- FOV --")
-- 0 to 180 on screen, which is FOV_REAL_MAX pixels of real radius. See the FOV constants.
asl("A", "fov", "FOV Radius", 0, FOV_DISPLAY_MAX, FOV_DISPLAY_DEFAULT, { parent = "aim_on" })
abox("A", "fov_circle", "Show FOV Circle", false, { parent = "aim_on" })
aco("A", "fov_shape", "FOV Shape", { "Circle", "Square" }, 0, { parent = "aim_on" })
-- The line runs from the crosshair to the point the aimbot is about to use, so the moment
-- the circle acquires somebody is the moment the line appears. No separate acquire state to
-- keep in step with the aimbot, and it cannot point at a player the aimbot is ignoring.
-- It draws in the single Colour dropdown on the ESP tab, like the tracers and the ring.
abox("A", "target_line", "Target Line", false, { parent = "aim_on" })

note("S", "F2 = ESP     F1 = Aimbot")
sec("S", "-- Crosshair --")
cbox("S", "crosshair", "Crosshair", false)
aco("S", "cross_type", "Crosshair Type", { "Cross", "Dot", "Circle", "T-Shape" }, 0, { parent = "crosshair" })
vsl("S", "cross_size", "Crosshair Size", 2, 60, 10, { parent = "crosshair" })

sec("S", "-- Display --")
cbox("S", "hud", "Info Text", true)
note("S", "counts, visibility and aim state")

sec("S", "-- Debug --")
btn("S", "btn_diag", "Copy Diagnostics", function()
   local text = ""
   local okg = pcall(function() text = diag_text() end)
   if not okg or type(text) ~= "string" or text == "" then
      if A.Notify.Error then pcall(A.Notify.Error, "Diagnostics not ready", nil, 5) end
      return
   end
   local done = false
   pcall(function() done = copy_text(text) end)
   if done then
      if A.Notify.Success then pcall(A.Notify.Success, "Diagnostics copied", "paste them back") end
   else
      if A.Notify.Error then pcall(A.Notify.Error, "Clipboard unavailable", nil, 5) end
      print(TAG .. " " .. text)
   end
end)
note("S", "team data, targets and toggles")


-- Push the registered defaults back into the widgets. AddCheckbox/AddSliderInt/AddCombo
-- all take a default argument and this build stores it, but does not render it, so every
-- control opens looking switched off even though the code already treats it as on.
for id, v in pairs(DEFAULTS) do
   if A.Menu.Set then pcall(A.Menu.Set, id, v) end
end
-- hotkeys go through SetKey, never Set, or the widget ends up showing a stale key
for id, v in pairs(KEY_DEFAULTS) do
   if A.Menu.SetKey then pcall(A.Menu.SetKey, id, v) end
end

--------------------------------------------------------------------------------------
-- config system
--------------------------------------------------------------------------------------
-- Named snapshots of every menu widget, one file per name, saved and loaded with one
-- button. Lives in the Config group, same_line to the right of Setup (directly under the
-- Aim column) and gated by nothing, so it is reachable no matter which features are on.
--
-- Storage prefers the loader's file globals (readfile/writefile/listfiles/isfile/
-- makefolder/delfile, the classic loaders expose them as plain globals). When none are
-- present the configs fall back to slots that last for the session only: Save/Load/Delete
-- still all work live, they just do not survive a script reload. Both paths are kept
-- because there is no way to know which loader will run this, and neither is expensive:
-- the file probe is a handful of type checks at load and the session table is empty.
--
-- Deliberately not in ORDER or DEFAULTS: a config is a container, not a feature. The
-- registered widgets keep their id, default and visibility management untouched, and the
-- config code only ever reads them back through menu.Get / menu.GetKey.
local CFG = {
   input = "cfg_name",
   folder = "explore_configs",
   fs = nil,
   slots = {},
}
do
   local r, w, l, f, m, d_
   r, w = _G.readfile, _G.writefile
   l, f, m, d_ = _G.listfiles, _G.isfile, _G.makefolder, _G.delfile
   if type(r) == "function" and type(w) == "function" then
      CFG.fs = { read = r, write = w, list = l, isfile = f, mkdir = m, del = d_ }
   end
end

-- The name comes from the input box. Some menus expose it through GetString and some
-- through Get returning the string, so both are tried, and a blank box falls back to
-- "default" rather than erroring or writing an unnamed file.
function CFG.current()
   local s = ""
   if A.Menu.GetString then
      local ok, v = pcall(A.Menu.GetString, CFG.input)
      if ok and type(v) == "string" then s = v end
   end
   if type(s) ~= "string" or s == "" then
      local ok, v = pcall(A.Menu.Get, CFG.input)
      if ok and type(v) == "string" then s = v end
   end
   if type(s) ~= "string" or s == "" then s = "default" end
   -- keep the name filesystem-safe and short enough to reuse as a file name. Dots are
   -- allowed so a name such as "stableexplore.lua" survives verbatim, but anything that
   -- could read as a folder reference is not: slashes are stripped outright, and any name
   -- that still contains ".." or leads with a dot falls back to "default" rather than
   -- writing outside the config folder.
   local out = {}
   for ch in s:gmatch(".") do
      if ch:match("[%w%._%-]") then out[#out + 1] = ch end
   end
   s = table.concat(out, ""):sub(1, 32)
   if s == "" or s:find("%.%.") or s:sub(1, 1) == "." then s = "default" end
   return s
end

-- One line per widget: "id<TAB>value", keys prefixed "k:" so they never collide with a
-- setting id. Values in this script are booleans and numbers, which survive this format
-- exactly; no strings are stored, so escaping is a non-issue.
function CFG.save()
   local name = CFG.current()
   local parts = {}
   for i = 1, #ORDER do
      local id = ORDER[i]
      local ok, v = pcall(H.mget, id)
      if ok and v ~= nil then parts[#parts + 1] = id .. "\t" .. tostring(v) end
   end
   -- a hotkey bound through akey or a widget's key option is read off the widget id; every
   -- hotkey widget is registered in ORDER, so one scan covers all of them
   if H.mgetkey then
      for i = 1, #ORDER do
         local id = ORDER[i]
         local ok, k = pcall(H.mgetkey, id)
         if ok and type(k) == "number" and k ~= 0 then
            parts[#parts + 1] = "k:" .. id .. "\t" .. tostring(k)
         end
      end
   end
   local text = table.concat(parts, "\n") .. (parts[1] and "\n" or "")
   local where = "session"
   if CFG.fs then
      local ok = false
      pcall(function()
         if CFG.fs.mkdir then pcall(CFG.fs.mkdir, CFG.folder) end
         CFG.fs.write(CFG.folder .. "/" .. name .. ".txt", text)
         ok = true
      end)
      if ok then where = CFG.folder .. "/" .. name .. ".txt" end
   else
      CFG.slots[name] = text
   end
   if A.Notify.Success then
      pcall(A.Notify.Success, "Config saved", where == "session" and (name .. " (session only)") or name, 4)
   end
end

function CFG.load()
   local name = CFG.current()
   local text
   if CFG.fs then
      pcall(function()
         local path = CFG.folder .. "/" .. name .. ".txt"
         if (not CFG.fs.isfile) or CFG.fs.isfile(path) then text = CFG.fs.read(path) end
      end)
   else
      text = CFG.slots[name]
   end
   if type(text) ~= "string" or text == "" then
      if A.Notify.Error then pcall(A.Notify.Error, "No config named", name, 4) end
      return
   end
   for line in text:gmatch("[^\n]+") do
      local tab = line:find("\t", 1, true)
      if tab then
         local id = line:sub(1, tab - 1)
         local val = line:sub(tab + 1)
         local hotkey = id:sub(1, 2) == "k:"
         if hotkey then id = id:sub(3) end
         if val == "true" then val = true
         elseif val == "false" then val = false
         else val = tonumber(val) end
         if type(id) == "string" and id ~= "" and val ~= nil then
            if hotkey then pcall(A.Menu.SetKey, id, val)
            else pcall(A.Menu.Set, id, val) end
         end
      end
   end
   if A.Notify.Success then pcall(A.Notify.Success, "Config loaded", name, 4) end
end

function CFG.del()
   local name = CFG.current()
   local done = false
   if CFG.fs then
      pcall(function()
         if CFG.fs.del then
            CFG.fs.del(CFG.folder .. "/" .. name .. ".txt")
            done = true
         end
      end)
   else
      CFG.slots[name] = nil
      done = true
   end
   if done then
      if A.Notify.Success then pcall(A.Notify.Success, "Config deleted", name, 4) end
   elseif A.Notify.Error then
      pcall(A.Notify.Error, "Nothing to delete/unsupported", nil, 4)
   end
end

-- Open the folder the configs are saved into. Loaders disagree on whether this is even
-- possible, so each known route is tried in turn and pcall'd: a dedicated openfolder
-- global, an openfile that hands the path to the OS handler, and game.OpenURL on a file
-- URL. A loader that exposes none of them is told plainly instead of silently doing
-- nothing. Session-only loaders have no folder to open, so they get a truth-telling
-- message too.
function CFG.open()
   if not CFG.fs then
      if A.Notify.Success then
         pcall(A.Notify.Success, "No config folder", "configs are session-only here", 4)
      end
      return
   end
   -- make sure there is something to open, even on a brand-new install
   if CFG.fs.mkdir then pcall(CFG.fs.mkdir, CFG.folder) end
   local tried = 0
   if type(_G.openfolder) == "function" then
      tried = tried + 1
      if pcall(_G.openfolder, CFG.folder) then
         if A.Notify.Success then pcall(A.Notify.Success, "Config folder", CFG.folder, 4) end
         return
      end
   end
   if type(_G.openfile) == "function" then
      tried = tried + 1
      if pcall(_G.openfile, CFG.folder) then
         if A.Notify.Success then pcall(A.Notify.Success, "Config folder", CFG.folder, 4) end
         return
      end
   end
   local g = _G.game
   if type(g) == "table" and type(g.OpenURL) == "function" then
      tried = tried + 1
      if pcall(g.OpenURL, "file:///" .. CFG.folder) then
         if A.Notify.Success then pcall(A.Notify.Success, "Config folder", CFG.folder, 4) end
         return
      end
   end
   if A.Notify.Error then
      if tried == 0 then
         pcall(A.Notify.Error, "Cannot open a folder on this loader", CFG.folder, 4)
      else
         pcall(A.Notify.Error, "Failed to open the config folder", CFG.folder, 4)
      end
   end
end

sec("C", "-- Config --")
note("C", "name a snapshot, then Save / Load / Delete / Open Folder")
pcall(A.Menu.AddInput, TAB, "Config", CFG.input, "Config Name", "default", {})
btn("C", "btn_cfg_save", "Save", function() CFG.save() end)
btn("C", "btn_cfg_load", "Load", function() CFG.load() end)
btn("C", "btn_cfg_delete", "Delete", function() CFG.del() end)
btn("C", "btn_cfg_open", "Open Config Folder", function() CFG.open() end)

--------------------------------------------------------------------------------------
-- settings
--------------------------------------------------------------------------------------
local S = {}
local vis_color = COLOURS[1][2]
local hidden_color = COLOURS[11][2]
local charm_color = COLOURS[8][2]
-- Every feature draws in vis_color: the ESP itself, the tracers, the FOV ring and the
-- aimbot target line all read it, so one dropdown recolours them together. Hidden Colour
-- is the only second paint, and only the Hidden Players colour mode applies it.

-- Hidden Colour hangs off the Hidden Players dropdown, so it needs the two visibility
-- exceptions: PARENT_TOUCH stops a combo's index 0 from reading as "off" (None is a real
-- choice, not a switch) and the GATE hides the picker unless Colour mode is selected. Both
-- must be wired here, after the settings table exists, because the gate closure reads it.
PARENT_TOUCH.vis_mode = true
GATE.hidden_color = function() return S.vis_mode == VIS_COLOUR end

-- Teammate matching reads team membership from the Teams service and compares it against
-- the side picked in the menu. There is no attempt to work out the local side by itself:
-- three separate reads were tried for it and none of them answered on this loader, so the
-- dropdown is the only source and Your Side has to be set to match. Changing side means
-- changing that dropdown.
local name_team = {}
local team_count = 0
-- Every team name that currently has members, lowercased. The teammate test looks for the
-- word the dropdown carries inside each real team name, so Blue and Red are matched
-- without either name being hardcoded anywhere else in the script.
-- Every team name that currently has members, lowercased, as one sorted string. The HUD used
-- to allocate a table, sort it and concatenate it on every frame to print a list that changes
-- about once every two seconds.
local team_joined = "-"

local function set_team_names(names)
   local out = {}
   for _, v in pairs(names) do out[#out + 1] = v end
   table.sort(out)
   if #out == 0 then
      team_joined = "-"
      return
   end
   team_joined = table.concat(out, "+")
end

local function refresh_from_cache()
   local list = nil
   if H.players then
      local ok, r = pcall(H.players)
      if ok and type(r) == "table" then list = r end
   end
   if list == nil then return end
   local teams, names = {}, {}
   for _, p in ipairs(list) do
      local nm = fld(p, "name", "Name")
      local dnm = fld(p, "display_name", "DisplayName")
      local tm = fld(p, "team", "Team")
      local ht = fld(p, "has_team", "HasTeam")
      if type(nm) == "string" and type(tm) == "string" then
         name_team[string.lower(nm)] = { tm, ht }
      end
      if type(dnm) == "string" and type(tm) == "string" then
         name_team[string.lower(dnm)] = { tm, ht }
      end
      if type(tm) == "string" then
         teams[string.lower(tm)] = true
         names[string.lower(tm)] = tm
      end
   end
   team_count = 0
   for _ in pairs(teams) do team_count = team_count + 1 end
   set_team_names(names)
end

-- Live team membership, read straight from the Teams service. A Roblox Team holds its
-- members as children and instance children are readable, so this needs no property
-- access at all and, unlike the cached Team string on the player object, it cannot go
-- stale when a round starts and moves everyone into different teams.
local function refresh_from_service()
   if not H.getsvc then return false end
   local oks, svc = pcall(H.getsvc, "Teams")
   if not oks or not svc then return false end
   local okt, list = pcall(function() return svc:GetChildren() end)
   if not okt or type(list) ~= "table" then return false end

   local live, used, names = {}, 0, {}
   for _, team in ipairs(list) do
      local tn = fld(team, "name", "Name")
      if type(tn) == "string" and tn ~= "" then
         local okm, members = pcall(function() return team:GetChildren() end)
         if okm and type(members) == "table" and #members > 0 then
            used = used + 1
            names[string.lower(tn)] = tn
            for _, m in ipairs(members) do
               local mn = fld(m, "name", "Name")
               -- stored as {team, hasTeam} so this map matches the cached one exactly
               if type(mn) == "string" then live[string.lower(mn)] = { tn, true } end
            end
         end
      end
   end
   if used == 0 then return false end

   name_team = live
   team_count = used
   set_team_names(names)
   return true
end

local function refresh_local_team()
   name_team = {}
   team_count = 0
   set_team_names({})
   if refresh_from_service() then return end
   refresh_from_cache()
end

-- Nothing may show in the menu unless every master above it is on. The parent option on
-- the menu cannot be relied on for that: parent is documented only for checkbox and slider
-- options tables, and in practice a combo child of a hidden ESP stayed on screen. This
-- reads the recorded tree and drives the documented menu.SetVisible instead, so the
-- dropdowns under ESP, and under Aimbot, are gone the moment their master is unticked.
-- Declared above cache_settings because that is what calls it.
local VIS_NOW = {}
local VIS_WAS = {}

-- The Hidden Players dropdown is the parent of the Hidden Colour picker, which is why
-- PARENT_TOUCH and a Hidden Colour gate exist: index 0 would otherwise read as off and
-- hide the pick exactly when None is selected, and the gate then keeps it hidden unless
-- the Colour mode that paints a second hue is the one picked. The gateway only shows on
-- change, so a steady frame still costs nothing.

-- Every parent in this menu is a checkbox, so the value is a boolean. A number is treated
-- as a dropdown index and 0 counts as off, purely so a future combo parent cannot silently
-- read as on and expose everything beneath it.
local function parent_on(pid)
   local v = S[pid]
   if v == nil and H.mget then
      local ok, got = pcall(H.mget, pid)
      if ok then v = got end
   end
   if type(v) == "number" then return v ~= 0 end
   return v and true or false
end

local function apply_visibility()
   if not A.Menu.SetVisible then return end
   for i = 1, #ORDER do
      local id = ORDER[i]
      local pid = PARENT[id]
      -- registration order guarantees VIS_NOW[pid] was already settled this frame, so a
      -- child is only ever shown when its whole chain above it is on
      local vis = true
      if pid then
         local gate_parent = PARENT_TOUCH[pid] and true or parent_on(pid)
         vis = ((VIS_NOW[pid] == true) and gate_parent) or false
      end
      local g = GATE[id]
      if g and not g() then vis = false end
      VIS_NOW[id] = vis
      -- only pushed on a change, so this costs nothing on a steady frame
      if VIS_WAS[id] ~= vis then
         VIS_WAS[id] = vis
         pcall(A.Menu.SetVisible, id, vis)
      end
   end
end

local function cache_settings()
   -- menu.Get is the one call the frame cannot do without, and it is asked for ~30 times a
   -- frame, so the lookup happens once here rather than 30 times
   local Get = H.mget
   if type(Get) ~= "function" then Get = function() return nil end end
   local GetKey = H.mgetkey
   if type(GetKey) ~= "function" then GetKey = function() return 0 end end

   S.esp_on     = Get("esp_on")
   S.max_dist   = Get("max_distance") or 3000
   S.box_on     = Get("box_on")
   S.box_style  = Get("box_style") or 0
   S.skeleton   = Get("skeleton")
   S.skel_head  = Get("skel_head")
   S.charm      = Get("charm")
   S.charm_colour_idx = Get("charm_color") or 7
   S.names      = Get("names")
   S.distance   = Get("distance")
   S.tracers    = Get("tracers")
   S.tracer_from = Get("tracer_from") or 0
   S.visible    = Get("visible")
   S.vis_mode   = Get("vis_mode") or VIS_NONE
   S.vis_colour_idx = Get("vis_color") or 0
   S.hidden_colour_idx = Get("hidden_color") or 10
   vis_color    = colour_at(S.vis_colour_idx)
   hidden_color = colour_at(S.hidden_colour_idx)
   charm_color  = colour_at(S.charm_colour_idx)
   S.friendly     = Get("friendly")
   S.side_idx   = Get("friendly_side") or 0
   S.side_key   = GetKey("side_key") or 0
   S.aim_ignore_friends = Get("aim_ignore_friends")

   S.aim_on     = Get("aim_on")
   S.fov_display = fov_display(Get("fov"))
   S.fov        = fov_real(S.fov_display)
   S.smooth     = Get("smooth") or 50
   S.aim_bone   = Get("aim_bone") or 0
   S.aim_method = Get("aim_method") or 0
   S.only_visible = Get("only_visible")
   S.sticky     = Get("sticky")
   S.fov_circle = Get("fov_circle")
   S.fov_shape  = Get("fov_shape") or 0
   S.target_line = Get("target_line")
   -- GetKey can return 0 when the hotkey was never touched; that is not a reason to
   -- disable aiming, so fall back to left mouse
   S.lock_key   = GetKey("lock_key") or 0
   -- 0 is left alone on purpose: it means no key is bound, so the aimbot is not gated

   S.crosshair  = Get("crosshair")
   S.cross_type = Get("cross_type") or 0
   S.cross_size = Get("cross_size") or 10
   S.hud        = Get("hud")

   apply_visibility()
end

-- Flips the picked side on a keypress. Edge triggered off the previous frame state,
-- otherwise holding the key would alternate the teams on every single frame. The menu
-- is written as well as the local value, so the dropdown follows and the cache on the
-- next frame reads the new index back instead of undoing the switch.
local side_key_held = false

local function update_side_key()
   local key = S.side_key or 0
   if key == 0 or not H.key then return end
   local ok, down = pcall(H.key, key)
   down = (ok and down) and true or false
   if down and side_key_held == false then
      local nxt = ((S.side_idx or 0) + 1) % #TEAM_SIDES
      S.side_idx = nxt
      if A.Menu.Set then pcall(A.Menu.Set, "friendly_side", nxt) end
   end
   side_key_held = down
end

--------------------------------------------------------------------------------------
-- screen helpers
--------------------------------------------------------------------------------------
-- both components must be numbers: returning a pair with a nil in it would blow up
-- every caller that does arithmetic or string.format on the second value
local function screen_center()
   if H.centre then
      local ok, cx, cy = pcall(H.centre)
      if ok and type(cx) == "number" and type(cy) == "number" then return cx, cy end
   end
   if H.drawsize then
      local ok, sw, sh = pcall(H.drawsize)
      if ok and type(sw) == "number" and type(sh) == "number" then
         return sw * 0.5, sh * 0.5
      end
   end
   return 0, 0
end

local function screen_size()
   if H.drawsize then
      local ok, sw, sh = pcall(H.drawsize)
      if ok and type(sw) == "number" and type(sh) == "number" then return sw, sh end
   end
   if H.utilsize then
      local ok, sw, sh = pcall(H.utilsize)
      if ok and type(sw) == "number" and type(sh) == "number" then return sw, sh end
   end
   return 0, 0
end

local function mouse_pos()
   if A.Input.GetMousePosition then
      local ok, mx, my = pcall(A.Input.GetMousePosition)
      if ok and mx then return mx, my end
   end
   return screen_center()
end

local function w2s(x, y, z)
   if x == nil then return nil end
   if H.uw2s then
      local ok, sx, sy, on = pcall(H.uw2s, x, y, z)
      if ok and sx then return sx, sy, on end
   end
   if H.dw2s then
      local ok, sx, sy, on = pcall(H.dw2s, x, y, z)
      if ok and sx then return sx, sy, on end
   end
   return nil
end

local function text_w(s, size)
   if H.textsize then
      local ok, w = pcall(H.textsize, s, size)
      if ok and type(w) == "number" then return w end
   end
   return #s * (size * 0.5)
end

local function round(v)
   if v >= 0 then return math_floor(v + 0.5) end
   return -math_floor(-v + 0.5)
end


--------------------------------------------------------------------------------------
-- workspace scan (supplement)
--------------------------------------------------------------------------------------
local function get_workspace()
   local g = _G.game
   if type(g) ~= "table" then return nil end
   if g.Workspace then return g.Workspace end
   if g.GetService then
      local ok, res = pcall(g.GetService, "Workspace")
      if ok then return res end
   end
   return nil
end

-- Descends Folders, and unwraps one level out of Part wrappers (Port1 etc.).
-- Stops as soon as a Humanoid turns up, so the map geometry is never traversed.
-- The scan list is rebuilt on a short cycle rather than every frame. This path runs on
-- games whose characters are not standard (no entity cache), i.e. exactly the games where
-- every frame of this walk is real cost, and a model list does not change faster than a
-- couple of seconds. Positions are still read live per target every frame; only the list
-- of who is a character is held back.
local SCAN_EVERY = 120
local function collect_models()
   local tick = H.scantick or 0
   if tick > 0 then
      H.scantick = tick - 1
      if H.scanlist then return H.scanlist end
   end

   local out = {}
   local ws = get_workspace()
   if ws == nil then return out end

   local function add_model(m)
      if inst_ok(m) == false then return end
      local hum = child_of(m, "Humanoid")
      if hum then out[#out + 1] = { model = m, hum = hum } end
   end

   local function walk(node, depth)
      if depth > 4 then return end
      for _, ch in ipairs(children(node)) do
         local cn = class_of(ch)
         if cn == "Model" then
            add_model(ch)
         elseif cn == "Folder" then
            walk(ch, depth + 1)
         elseif cn == "Part" or cn == "BasePart" then
            for _, inner in ipairs(children(ch)) do
               if class_of(inner) == "Model" then add_model(inner) end
            end
         end
      end
   end

   walk(ws, 1)
   H.scanlist = out
   H.scantick = SCAN_EVERY
   return out
end

--------------------------------------------------------------------------------------
-- target collection
--------------------------------------------------------------------------------------
local targets = {}
local target_n = 0
local cam_x, cam_y, cam_z
local SW, SH

-- Frame scratch, one slot per target ordinal, allocated once and kept for the life of the
-- script: the bone coordinate arrays, and the measured text widths.
--
-- The obvious way to stop allocating in the frame is to pool the target tables themselves,
-- and that was measured at about forty percent SLOWER than allocating them. A table sitting
-- in a pool is a shared reference, so every field written to it each frame pays refcount
-- bookkeeping on the old and the new value, and a recycled target has about twenty five
-- fields rewritten every frame. A fresh table constructor is private and costs next to
-- nothing. What is actually worth keeping is the values going into the table, not the table,
-- so those are what is held here. Ordinals are stable frame to frame as long as the player
-- list is, and every cached value is validated against what produced it, so a reordered
-- list costs one recompute and never a wrong number.
local BONE_X, BONE_Y = {}, {}
local NAME_FOR, NAME_W = {}, {}
local DIST_INT, DIST_STR, DIST_W = {}, {}, {}

-- Returns the two coordinate arrays for this ordinal, cleared. Cleared rather than written
-- over, because a bone that stops projecting for one frame has to disappear rather than
-- keep drawing its last known point.
local function bones_begin(ord)
   local x, y = BONE_X[ord], BONE_Y[ord]
   if x == nil then
      x, y = {}, {}
      BONE_X[ord], BONE_Y[ord] = x, y
   end
   for i = 1, BONE_SLOTS do x[i], y[i] = nil, nil end
   return x, y
end

-- The arrays are passed in rather than looked up: this runs once per bone per target per
-- frame and the caller already has them in a local.
local function bones_put(t, x, y, slot, px, py)
   if slot == nil or slot == 0 then return end
   x[slot], y[slot] = px, py
   t.bn = t.bn + 1
end

local function aim_world(t)
   if t.aim_wx then return t.aim_wx, t.aim_wy, t.aim_wz end
   return t.hwx, t.hwy, t.hwz
end

-- entity path: the API supplies bounds, bone screens and distance directly
--
-- Every method is called as pcall(p.Method, p, ...) rather than pcall(function() return
-- p:Method() end). The wrapper form allocated a closure per call, and with the skeleton on
-- that was twenty one per player per frame, all of them garbage to be freed again.
--
-- ord is this target's ordinal, the key the frame scratch is held under. The table itself is
-- built fresh each frame: see the note on the scratch tables for why that is cheaper than
-- recycling it.
local function build_from_entity(p, ord)
   if fld(p, "is_local", "IsLocal") then return nil end
   if fld(p, "is_alive", "IsAlive") == false then return nil end

   local char = fld(p, "character", "Character")
   if inst_ok(char) == false then return nil end

   local dist = 0
   local ok, d = pcall(p.DistanceTo, p)
   if ok and type(d) == "number" then dist = d end

   local t = {
      ent = p,
      model = char,
      hum = fld(p, "humanoid", "Humanoid"),
      name = fld(p, "name", "Name") or fld(p, "display_name", "DisplayName") or "?",
      team = fld(p, "team", "Team"),
      has_team = fld(p, "has_team", "HasTeam"),
      rig = fld(p, "rig_type", "RigType"),
      tool = fld(p, "tool_name", "ToolName"),
      dist = dist,
      bn = 0,
      -- both must start defined: a nil vis makes every visibility test read as
      -- "not false" and the option looks like it does nothing
      vis = true, friend = false,
   }

   local okb, b = pcall(p.GetBounds, p)
   if okb and type(b) == "table" and b.valid and b.w and b.h and b.w > 0 then
      t.bx, t.by, t.bw, t.bh = b.x, b.y, b.w, b.h
      t.box_valid = true
   end

   local hx, hy, hz = vec_xyz(fld(p, "head_position", "HeadPosition"))
   if hx then t.hwx, t.hwy, t.hwz = hx, hy, hz end

   -- Head screen position comes from the real Head part first. The loader's bone lookup
   -- and its head_position field describe the standing pose, so either one alone floats
   -- above a player who lies down; the part is what the skeleton draws from, and the
   -- label, head marker and fallback box all pin to the same place. The part also wins
   -- for the world position: the visibility raycast below must be aimed at where the head
   -- actually is, or a player behind cover reads as visible through his old standing spot.
   local hpart = child_of(char, "Head")
   if hpart then
      local hpx, hpy, hpz = part_pos(hpart)
      if hpx then
         t.hwx, t.hwy, t.hwz = hpx, hpy, hpz
         local hx2, hy2, hon2 = w2s(hpx, hpy, hpz)
         if hx2 and hon2 then t.hsx, t.hsy, t.hon = hx2, hy2, true end
      end
   end
   if t.hsx == nil then
      local okh, hxs, hys, hons = pcall(p.GetBoneScreen, p, "Head")
      if okh and hons and hxs then t.hsx, t.hsy, t.hon = hxs, hys, true end
   end

   -- aim bone, first candidate the rig actually has. The live part is projected first so
   -- the aim tracks the body the box and skeleton track, not the standing pose the loader
   -- projects; GetBoneScreen survives as the fallback for a rig that hides the part.
   local set = AIM_BONES[(S.aim_bone or 0) + 1] or AIM_BONES[1]
   for _, bn in ipairs(set) do
      local part = child_of(char, bn)
      local wx, wy, wz = part_pos(part)
      if wx then
         local okp, ax, ay, aon = pcall(w2s, wx, wy, wz)
         if okp and ax and aon then
            t.asx, t.asy, t.aon = ax, ay, true
            t.aim_bone = bn
            t.aim_wx, t.aim_wy, t.aim_wz = wx, wy, wz
            break
         end
      end
      local oka, ax, ay, aon = pcall(p.GetBoneScreen, p, bn)
      if oka and aon and ax then
         t.asx, t.asy, t.aon = ax, ay, true
         t.aim_bone = bn
         break
      end
   end
   if t.asx == nil and t.hsx then
      t.asx, t.asy, t.aon = t.hsx, t.hsy, t.hon
   end

   -- GetBounds can report invalid even for a player standing in plain view, and
   -- GetBoneScreen can come back 0,0,false. Project the head and root directly as a
   -- fallback so a visible player is never invisible for want of a bounds call.
   if t.hwx then
      if t.hsx == nil then
         local wx, wy, won = w2s(t.hwx, t.hwy, t.hwz)
         if wx then t.hsx, t.hsy, t.hon = wx, wy, won end
      end

      if not t.box_valid and t.hsx and t.hon then
         -- narrowed onto locals: the head fields are a union at this point and the type
         -- checker cannot prove what the runtime guard just did. Plain Lua only — a stock
         -- loader parser rejects type annotations, so the or-0 does the narrowing instead.
         local hsx, hsy = t.hsx or 0, t.hsy or 0
         local rx, ry, rz = vec_xyz(fld(p, "position", "Position"))
         local fx, fy, fon
         if rx then
            local hip = fld(t.hum, "hip_height", "HipHeight") or 0
            fx, fy, fon = w2s(rx, ry - (hip + 1), rz)
         end
         if not (fx and fon) then
            fx, fy = hsx, hsy + 60
         end
         if fx and fy then
            local w = math_abs(hsx - fx)
            local h = fy - hsy
            if w >= 1 and h >= 1 then
               t.bx = math_min(hsx, fx)
               t.by = hsy - 3
               t.bw = math_max(4, w)
               t.bh = h + 6
               t.box_valid = true
            end
         end
      end
   end

   -- Skeleton bones come from the live character parts, projected through the same w2s the
   -- workspace path uses. The loader's GetBoneScreen/GetBonesScreen describe a standing
   -- rest pose, so a player who crouches or lies down had his skeleton drawn in the air,
   -- offset from the box that actually bounds him. Reading the parts puts every segment on
   -- the body whatever pose it is in. The bone lookup survives only as a fallback for a
   -- name the rig hides from child lookups or a corner where the part has not resolved yet.
   if S.skeleton then
      local bx, by = bones_begin(ord)
      for i = 1, #BONE_FETCH_IDX do
         local bn, slot = BONE_FETCH_IDX[i][1], BONE_FETCH_IDX[i][2]
         local part = child_of(char, bn)
         if part then
            local wx, wy, wz = part_pos(part)
            if wx then
               local bsx, bsy, bson = w2s(wx, wy, wz)
               if bsx and bson then bones_put(t, bx, by, slot, bsx, bsy) end
            end
         end
         if bx[slot] == nil then
            local okb2, sx2, sy2, bon2 = pcall(p.GetBoneScreen, p, bn)
            if okb2 and bon2 and tonumber(sx2) and tonumber(sy2) then
               bones_put(t, bx, by, slot, sx2, sy2)
            end
         end
      end
   end

   return t
end

-- workspace path: no entity wrapper, so project the parts directly
local function build_from_model(m, local_x, local_y, local_z, ord)
   local model, hum = m.model, m.hum
   if inst_ok(model) == false then return nil end

   local head = child_of(model, "Head")
   if head == nil then return nil end
   local hx, hy, hz = part_pos(head)
   if not hx then return nil end

   local root = child_of(model, "HumanoidRootPart")
   if root == nil then root = child_of(model, "LowerTorso") end
   if root == nil then root = child_of(model, "Torso") end
   local rx, ry, rz = part_pos(root)
   if not rx then rx, ry, rz = hx, hy, hz end

   if local_x then
      local dx, dy, dz = rx - local_x, ry - local_y, rz - local_z
      if (dx * dx + dy * dy + dz * dz) < 9 then return nil end
   end

   local dist = 0
   if local_x then
      local dx, dy, dz = rx - local_x, ry - local_y, rz - local_z
      dist = math_sqrt(dx * dx + dy * dy + dz * dz)
   end

   local mname = fld(model, "name", "Name") or "?"
   local t = {
      model = model, hum = hum,
      name = mname,
      dist = dist,
      hwx = hx, hwy = hy, hwz = hz,
      bn = 0,
      vis = true, friend = false,
   }

   -- no entity wrapper on this path, so the team comes from the player that owns the
   -- model. Without it a teammate found by the scan is never filtered by team.
   local nt = name_team[string.lower(mname)]
   if nt then t.team, t.has_team = nt[1], nt[2] end

   local sx, sy, on = w2s(hx, hy, hz)
   if sx then t.hsx, t.hsy, t.hon = sx, sy, on end

   local set = AIM_BONES[(S.aim_bone or 0) + 1] or AIM_BONES[1]
   for _, bn in ipairs(set) do
      local part = child_of(model, bn)
      if part then
         local wx, wy, wz = part_pos(part)
         if wx then
            t.aim_wx, t.aim_wy, t.aim_wz = wx, wy, wz
            local ax, ay, aon = w2s(wx, wy, wz)
            if ax then t.asx, t.asy, t.aon = ax, ay, aon end
            t.aim_bone = bn
            break
         end
      end
   end
   if t.asx == nil and t.hsx then
      t.asx, t.asy, t.aon = t.hsx, t.hsy, t.hon
   end

   -- screen bones for the skeleton
   if S.skeleton then
      local bx, by = bones_begin(ord)
      for i = 1, #BONE_FETCH_IDX do
         local bn, slot = BONE_FETCH_IDX[i][1], BONE_FETCH_IDX[i][2]
         local part = child_of(model, bn)
         if part then
            local wx, wy, wz = part_pos(part)
            if wx then
               local bsx, bsy, bson = w2s(wx, wy, wz)
               if bsx and bson then bones_put(t, bx, by, slot, bsx, bsy) end
            end
         end
      end
   end

   -- box from head top to feet: root pushed down by hip height plus half the root
   if t.hsx and t.hon and rx then
      local hip = fld(hum, "hip_height", "HipHeight") or 0
      local root_h = vec_xyz(fld(root, "size", "Size"))
      local fx, fy, fon = w2s(rx, ry - (hip + (root_h and root_h or 2) * 0.5), rz)
      if fx and fon then
         local top, bot = t.hsy, fy
         local left = math_min(t.hsx, fx)
         local w = math_abs(t.hsx - fx)
         local h = bot - top
         if w < 1 or h < 1 then return nil end
         t.bx, t.by, t.bw, t.bh = left, top - 3, math_max(4, w), h + 6
         t.box_valid = true
      end
   end

   return t
end

local n_entity, n_scan = 0, 0
local anim_t = 0
local team_tick = 0

local function collect_targets()
   n_entity, n_scan, target_n = 0, 0, 0

   local list = H.players and H.players() or nil
   if type(list) == "table" then
      for i = 1, #list do
         -- the ordinal is the index this target is about to take, so it always matches the
         -- index the draw loop uses for it. A player that gets skipped hands the same
         -- ordinal to the next one, which is harmless: a skipped target never draws.
         local t = build_from_entity(list[i], target_n + 1)
         if t then
            target_n = target_n + 1
            targets[target_n] = t
            n_entity = n_entity + 1
         end
      end
   end

   -- The entity cache is filled by the tracker and can legitimately come back empty on a
   -- game whose characters are not standard. There used to be a Scan Workspace box for
   -- this, but the honest behaviour is to scan whenever the entity path found nobody and
   -- never otherwise: as a tick it was either dead weight or the thing the ESP depended on,
   -- and there is no setting in between. If the cache is healthy this costs one comparison
   -- per frame, and if it is not, this is the only thing that draws anybody at all.
   if n_entity == 0 then
      local lp = H.localplr and H.localplr() or nil
      local lx, ly, lz = vec_xyz(lp and fld(lp, "position", "Position"))
      if lx == nil then lx, ly, lz = cam_x, cam_y, cam_z end
      for _, m in ipairs(collect_models()) do
         -- the head is read once per candidate instead of once per candidate per existing
         -- target: this dedupe is the innermost loop of the only path that runs on a game
         -- where the entity cache is empty, and FindFirstChild is not free
         local chx, chy, chz = part_pos(child_of(m.model, "Head"))
         -- dedupe against every path, not just this one, or a character that is both
         -- an entity player and a workspace model gets drawn twice
         local dup = false
         for i = 1, target_n do
            local t = targets[i]
            if t.model == m.model then dup = true break end
            if dup == false and chx and t.hwx then
               local dx, dy, dz = chx - t.hwx, chy - t.hwy, chz - t.hwz
               if (dx * dx + dy * dy + dz * dz) < 1 then dup = true break end
            end
         end
         if dup == false then
            local t = build_from_model(m, lx, ly, lz, target_n + 1)
            if t then
               target_n = target_n + 1
               targets[target_n] = t
               n_scan = n_scan + 1
            end
         end
      end
   end
   -- shrink the list rather than reallocating it every frame. The loops downstream use
   -- ipairs, which stops at the first hole, so the array has to stay dense to target_n.
   targets[target_n + 1] = nil

   -- Teammate flags, computed once per frame rather than once per draw.
   --
   -- A target is a teammate when the word behind the Your Side dropdown appears inside the
   -- team name the game reports for them. Blue and Red is what this game actually calls its
   -- two sides, and each dropdown entry carries the word to look for, so the menu label and
   -- the real team name never have to match each other.
   --
   -- There is deliberately no attempt to work out which side the local player is on. Three
   -- separate reads were tried for that and none of them answered on this loader, so the
   -- dropdown is the only source and it has to be set by hand.
   --
   -- Two gates. At least two teams have to have members, because with one populated team,
   -- as in the lobby, flagging everybody would blank the ESP. And a target with no reported
   -- team is never flagged: hiding everyone because data is missing looks like a dead cheat.
   local side = side_key(S.side_idx)
   local usable = (side ~= "" and team_count >= 2)
   for i = 1, target_n do
      local t = targets[i]
      local raw = t.team
      local tn = nil
      if type(raw) == "string" then
         tn = LOWER[raw]
         if tn == nil then
            tn = string.lower(raw)
            LOWER[raw] = tn
         end
      end
      t.friend = (tn ~= nil and usable
                  and string.find(tn, side, 1, true) ~= nil) or false
   end

   -- Visibility. The old version gated the whole block on IsReady and then relied on
   -- IsPlayerVisible, which is documented to fail open until its cache is warm: with a
   -- cold cache the block was skipped, vis stayed nil, and nil == false is false, so
   -- Visible Only and Wall Check did nothing at all. A direct camera-to-head segment
   -- test is used first because it needs no cache and is what a wall check means;
   -- IsPlayerVisible is only the fallback. The check now always runs: the visuals pick
   -- a different colour per visibility, so it cannot be tied to whether anything is
   -- being hidden outright. A target with no resolvable result keeps vis nil, and nil is
   -- not false, so it is treated as visible and drawn rather than dropped.
   local have_cam = type(cam_x) == "number"
   for i = 1, target_n do
      local t = targets[i]
      local res = nil
      if have_cam and t.hwx and H.vis then
         local ok, v = pcall(H.vis, cam_x, cam_y, cam_z, t.hwx, t.hwy, t.hwz)
         if ok and type(v) == "boolean" then res = v end
      end
      if res == nil and H.pvis and t.model then
         local ok, v = pcall(H.pvis, t.model)
         if ok and type(v) == "boolean" then res = v end
      end
      if res ~= nil then t.vis = res end
   end

   return targets
end

--------------------------------------------------------------------------------------
-- drawing
--------------------------------------------------------------------------------------
-- What a behind-a-wall player is drawn at when there is no second colour to draw them in.
-- Dropping alpha rather than scaling the RGB is deliberate: scaling toward black makes a
-- target disappear on a dark background, whereas alpha reads as further away on any
-- background. This is what Dim did back when there was only ever one colour.
local DIM_ALPHA = 0.4

-- Colours derived from a colour are cached by the colour they came from, weakly keyed so a
-- palette entry that drops out of the menu does not stay alive. The derived set is closed
-- and tiny: the dim variant of a visible colour and the outline under a drawn colour. Both
-- used to be built as fresh tables per target per frame, so a dimmed skeleton allocated two
-- tables and a dimmed box a third, sixty times a second, for values that never change.
local function dimmed(c)
   local d = H.dimcache[c]
   if d == nil then
      d = { c[1], c[2], c[3], DIM_ALPHA }
      H.dimcache[c] = d
   end
   return d
end

local function dark_of(c)
   local d = H.darkcache[c]
   if d == nil then
      d = { 0, 0, 0, (c[4] or 1) * 0.8 }
      H.darkcache[c] = d
   end
   return d
end

-- The FOV ring keeps the hue of its picked colour but drops the alpha, so it reads as a
-- guide rather than a hard border across the screen. The translucent copy is cached the
-- same way as dimmed/dark_of: the ring used to build a fresh table per frame, and the
-- colour never changes unless the dropdown does.
local function ring_of(c)
   local d = H.fovcache[c]
   if d == nil then
      d = { c[1], c[2], c[3], 0.5 }
      H.fovcache[c] = d
   end
   return d
end

-- The charm aura is meant to read as light rather than paint: a soft halo of the charm
-- hue behind a brighter core ring. The halo is the same cached derivation as the FOV
-- ring — one translucent table per picked colour, shared by every character on screen.
local function glow_of(c)
   local d = H.glocache[c]
   if d == nil then
      d = { c[1], c[2], c[3], 0.30 }
      H.glocache[c] = d
   end
   return d
end

-- One place decides what colour the ESP is in, so the box, skeleton, head dot, name,
-- distance and the aimbot FOV ring cannot drift apart from each other. is_hidden says
-- whether this particular draw is for a player behind a wall. The ring passes no target
-- and no is_hidden, so it takes the colour a player in the open would be drawn in, which
-- is the visible palette entry.
--
-- is_hidden is only ever true when the mode is Dim or Colour, so None cannot reach the dim
-- branch. Dim and Colour differ only in how the split is made: one drops the alpha, the
-- other switches hue. Both are always in effect for their mode, which is the point of
-- having them as entries in one list rather than as two things to remember to tick.
local function esp_colour(is_hidden)
   if not is_hidden then return vis_color end
   if S.vis_mode == VIS_COLOUR then return hidden_color end
   return dimmed(vis_color)
end

-- Two passes: a fat dark outline, then the coloured core on top. A single thin pass
-- disappears against bright walls and roofs, which is what made the old one look broken.
-- Width is fixed: the slider it came from was one line of menu for a value nobody
-- changes after the first attempt, and the outline pass is derived from it anyway.
local SKEL_W = 2

local function draw_skeleton(t, ord, col)
   if t.bn == 0 then return end
   local w = SKEL_W
   -- the outline alpha follows the core: a fixed opaque black outline would leave a
   -- dimmed skeleton reading stronger than the undimmed one, which is backwards
   local dark = dark_of(col)
   local bx, by = BONE_X[ord], BONE_Y[ord]

   -- Both passes walk the same precomputed link tables, so the geometry is identical
   -- between them by construction and there is no segment list to build. The old version
   -- collected every segment into a fresh table of fresh tables first, per target, per
   -- frame, and then walked it twice.
   for pass = 1, 2 do
      local c, lw = dark, w + 2
      if pass == 2 then c, lw = col, w end

      for i = 1, #LINKS_TRUNK do
         local l = LINKS_TRUNK[i]
         local ax, ay = bx[l[1]], by[l[1]]
         if ax and ay then
            local px, py = bx[l[2]], by[l[2]]
            if px and py then H.line(ax, ay, px, py, c, lw) end
         end
      end

      -- Arms. On R15 each joint is its own bone, so those links are used as they are. On R6
      -- the whole arm is a single block and the API hands back one point in the middle of
      -- it, so the arm is a single straight line from the torso out to that point. Two
      -- points and nothing else, so it cannot fall apart when a bone goes missing.
      for i = 1, #LINKS_ARMS do
         local l = LINKS_ARMS[i]
         local ax, ay = bx[l[1]], by[l[1]]
         if ax and ay then
            local px, py = bx[l[2]], by[l[2]]
            if px and py then H.line(ax, ay, px, py, c, lw) end
         end
      end

      -- the R6 arm block, only when the torso and a whole-arm point are both on screen
      local tx, ty = bx[SLOT_TORSO], by[SLOT_TORSO]
      if tx and ty then
         for i = 1, 2 do
            local slot = LINKS_R6[i][2]
            local px, py = bx[slot], by[slot]
            if px and py then H.line(tx, ty, px, py, c, lw) end
         end
      end
   end

   -- a plain truthy test, not "not false": a nil from a missing widget has to count as
   -- off, otherwise the head dot would be the one feature nothing could switch off
   if S.skel_head then
      local hx, hy = bx[SLOT_HEAD], by[SLOT_HEAD]
      if hx and hy then
         local r = w * 1.7
         H.circle(hx, hy, r, dark, 20, w + 2)
         H.circle(hx, hy, r, col, 20, w)
      end
   end
end

-- One pcall per target, around the whole draw, instead of one per primitive.
local function draw_esp_body(t, ord, sw, sh)
   if t.dist > (S.max_dist or 3000) then return end
   if t.friend and S.friendly then return end

   -- Visable Check off means no player is ever treated differently. On, the Hidden Players
   -- dropdown decides how: None draws everyone the same, Dim fades the ones behind a wall,
   -- and Colour paints them a second hue. There is no separate Hide mode, so no target is
   -- ever dropped here. A target with no resolved visibility keeps vis nil, and nil is not
   -- false, so it counts as in the open.
   local col = esp_colour(S.visible and S.vis_mode ~= VIS_NONE and t.vis == false)

   if S.skeleton then draw_skeleton(t, ord, col) end

   if not t.box_valid then
      -- No box could be computed. If the head still projects, mark it, so a player who is
      -- on screen is never invisible while the box was asked for. Each half obeys its own
      -- switch though: with Box and Names both off there is nothing to stand in
      -- for, and drawing anyway would put a feature on that nobody ticked.
      if t.hsx and t.hon and (S.box_on or S.names) then
         if S.box_on then
            local s = 5
            H.line(t.hsx - s, t.hsy, t.hsx + s, t.hsy, col, 2)
            H.line(t.hsx, t.hsy - s, t.hsx, t.hsy + s, col, 2)
         end
         if S.names then
            H.text(t.hsx + 8, t.hsy - 7, t.name, col, 13)
         end
      end
      return
   end

   -- 2D is the full outline and Corner is the bracket style. Corner reads cleaner at
   -- distance because the four edges cross the character, but the outline is easier to
   -- track up close, so it is a choice rather than a fixed answer. Both take the same
   -- bounds, and both validate (x,y) against (x+w, y+h) before drawing.
   if S.box_on then
      if S.box_style == 1 then
         H.cbox(t.bx, t.by, t.bw, t.bh, col)
      else
         H.box(t.bx, t.by, t.bw, t.bh, col)
      end
   end

   local ccx = t.bx + t.bw * 0.5

   -- A halo ring around the character, sized to the box so it hugs the body rather than
   -- the screen: a wide translucent pass in the charm hue, then a thin bright core. The
   -- substance is spawned per frame so a box that lies down or crouches pulls the aura
   -- in with it.
   if S.charm then
      local cy = t.by + t.bh * 0.5
      local r = (t.bw > t.bh and t.bw or t.bh) * 0.85
      H.circle(ccx, cy, r * 1.35, glow_of(charm_color), 36, 4)
      H.circle(ccx, cy, r, charm_color, 36, 2)
   end

   if S.tracers and sw > 0 then
      -- sw/sh come from the frame, read once, instead of asking the API for the screen size
      -- again for every single player that has tracers on
      local ox, oy = ccx, sh - 2
      if S.tracer_from == 1 then ox, oy = sw * 0.5, sh * 0.5 end
      -- the tracer has its own picker and always uses it: it is a separate visual and
      -- overriding it would make the dropdown a lie
      H.line(ox, oy, ccx, t.by + t.bh, vis_color, 2)
   end

   local ly = t.by - 4

   if S.names then
      local nm = t.name
      -- the width of a name never changes while that name is on screen, so it is measured
      -- once and kept under the target's ordinal. GetTextSize is a crossing into the loader
      -- and was being paid for by every name on screen, every frame. The name it was
      -- measured for is kept beside it, so a different player in this slot recomputes.
      if NAME_FOR[ord] ~= nm then
         NAME_FOR[ord] = nm
         NAME_W[ord] = text_w(nm, 13)
      end
      H.text(ccx - NAME_W[ord] * 0.5, ly - 14, nm, col, 13)
      ly = ly - 14
   end

   if S.distance then
      -- same idea for the distance: the integer changes a few times a second at most, not
      -- sixty times a second, so the formatted string and its width are both held
      local d = round(t.dist)
      if DIST_INT[ord] ~= d then
         DIST_INT[ord] = d
         local s = format("%d", d)
         DIST_STR[ord] = s
         DIST_W[ord] = text_w(s, 11)
      end
      H.text(ccx - DIST_W[ord] * 0.5, ly - 12, DIST_STR[ord], col, 11)
   end
end

local function draw_esp(t, ord, sw, sh)
   pcall(draw_esp_body, t, ord, sw, sh)
end

-- A live swatch of the picked colour, bottom left. The dropdown itself cannot preview:
-- a combo hands over plain strings, so the entry text is drawn in one fixed colour and
-- there is no way to tint "Blue" blue. A rectangle filled by the script is the only
-- honest preview, and it doubles as proof the pick reached the draw calls. There is one
-- row for the master Colour dropdown, one for the Charm pick, plus the Hidden row when
-- the hidden split is a real thing, and the rows live in tables reused for the lifetime
-- of the script.
local SWATCH_ROWS = { {}, {}, {} }
local SWATCH_N = 0

local function swatches_body(sh)
   -- built first, drawn second, so the strip is anchored to the bottom edge however many
   -- rows there happen to be rather than assuming a fixed count
   SWATCH_N = 0
   -- the master colour is what every feature draws in, so it always gets a row
   local r0 = SWATCH_ROWS[1]
   r0[1], r0[2], r0[3] = vis_color, "Colour", colour_name(S.vis_colour_idx)
   -- the charm has its own pick, so it gets a row of its own whether the aura is on or not
   local r1 = SWATCH_ROWS[2]
   r1[1], r1[2], r1[3] = charm_color, "Charm", colour_name(S.charm_colour_idx)
   SWATCH_N = 2
   -- The Hidden row must stay honest about what is really drawn rather than what the
   -- dropdown holds: Dim mode uses the dimmed master colour, not the Hidden pick, so the
   -- stripe shows the dimmed colour and the current mode is named instead.
   if S.visible and S.vis_mode == VIS_DIM then
      local r = SWATCH_ROWS[SWATCH_N + 1]
      r[1], r[2], r[3] = dimmed(vis_color), "Hidden", "dimmed"
      SWATCH_N = SWATCH_N + 1
   elseif S.visible and S.vis_mode == VIS_COLOUR then
      local r = SWATCH_ROWS[SWATCH_N + 1]
      r[1], r[2], r[3] = hidden_color, "Hidden", colour_name(S.hidden_colour_idx)
      SWATCH_N = SWATCH_N + 1
   end

   local y = sh - 16 - 19 * (SWATCH_N - 1)
   for i = 1, SWATCH_N do
      local s = SWATCH_ROWS[i]
      H.rectf(10, y, 14, 14, s[1], 2)
      -- a light outline keeps Black and Grey readable against a dark background
      H.rect(10, y, 14, 14, H.w045, 2, 1)
      H.text(30, y, s[2] .. "  " .. s[3], H.w085, 13)
      y = y + 19
   end
end

local function draw_colour_swatches(sh)
   if not A.Draw.RectFilled then return end
   pcall(swatches_body, sh)
end

local function crosshair_body(cx, cy)
   local s = S.cross_size or 10
   local kind = S.cross_type or 0
   if kind == 1 then
      H.line(cx - 2, cy, cx + 2, cy, H.w09, 2)
   elseif kind == 2 then
      H.circle(cx, cy, s * 0.5, H.w09, 20, 1.5)
   elseif kind == 3 then
      H.line(cx - s, cy, cx + s, cy, H.w09, 2)
      H.line(cx, cy, cx, cy + s * 0.6, H.w09, 2)
   else
      H.line(cx - s, cy, cx - 2, cy, H.w09, 2)
      H.line(cx + 2, cy, cx + s, cy, H.w09, 2)
      H.line(cx, cy - s, cx, cy - 2, H.w09, 2)
      H.line(cx, cy + 2, cx, cy + s, H.w09, 2)
   end
end

local function draw_crosshair(cx, cy)
   pcall(crosshair_body, cx, cy)
end

local function fov_body(cx, cy)
   -- the ring is drawn at the real pixel radius, not the number the slider shows
   local r = S.fov or FOV_REAL_DEFAULT
   local w = 2
   -- the ring shares the single Colour dropdown like everything else, translucent so an
   -- outline this large reads as a guide rather than a hard border across the screen
   local col = ring_of(vis_color)
   if S.fov_shape == 1 then
      H.line(cx - r, cy - r, cx + r, cy - r, col, w)
      H.line(cx - r, cy + r, cx + r, cy + r, col, w)
      H.line(cx - r, cy - r, cx - r, cy + r, col, w)
      H.line(cx + r, cy - r, cx + r, cy + r, col, w)
   else
      H.circle(cx, cy, r, col, 48, w)
   end
end

local function draw_fov(cx, cy)
   pcall(fov_body, cx, cy)
end

-- The line from the crosshair to whoever the aimbot has acquired. It is fed the target the
-- aimbot actually returned rather than being computed again here, so the line and the aim
-- can never disagree about who is being aimed at, and the "is inside the circle" test is
-- the one pick_target already made: it only ever returns a target inside the FOV radius.
--
-- The endpoint is the aim point, not the box, because the aim point is what the aimbot is
-- tracking. With Aim At set to the root or torso that is visibly not the head, which is the
-- point: the line shows the bone it is going to take.
local function tline_body(t, cx, cy)
   if t == nil or not (t.aon and t.asx and t.asy) then return end
   H.line(cx, cy, t.asx, t.asy, vis_color, 2)
end

local function draw_target_line(t, cx, cy)
   pcall(tline_body, t, cx, cy)
end

--------------------------------------------------------------------------------------
-- aimbot
--------------------------------------------------------------------------------------
local sticky_ht = nil

-- Mouse-mode convergence state. MoveMouse steers the OS cursor; a game that captures the
-- cursor never reads it back into the camera, so the remaining distance never shrinks and
-- the aimbot would sit there pushing a dead mouse. When the distance has not shrunk for a
-- few frames the route is considered dead and the camera is pointed directly, the same
-- way Camera mode does, until the mouse route proves it can move the camera again.
local maim = { t = nil, d2 = nil, stall = 0 }

-- cx,cy is the crosshair (screen centre), NOT the mouse cursor. In Roblox third
-- person the character faces wherever the camera looks, which is screen centre; the
-- cursor is a desktop artefact and its distance to a target means nothing to the
-- shot. Measuring from the cursor is what stops the aimbot ever acquiring anything.
local function pick_target(cx, cy)
   local fov = S.fov or FOV_REAL_DEFAULT
   local fov2 = fov * fov
   local maxd = S.max_dist or 3000
   local skip_friends = S.aim_ignore_friends and true or false
   local only_vis = S.only_visible and true or false

   -- Squared screen distance, tested against the squared FOV: no square root per target. The
   -- test also hands back what it worked out, where the old version measured the same two
   -- subtractions and a square root twice for every player, once to decide and once to
   -- compare.
   local function score(t)
      if t.dist > maxd then return nil end
      if skip_friends and t.friend then return nil end
      if only_vis and t.vis == false then return nil end
      if not (t.aon and t.asx) then return nil end
      local dx, dy = t.asx - cx, t.asy - cy
      local d2 = dx * dx + dy * dy
      if d2 > fov2 then return nil end
      return d2
   end

   if S.sticky and sticky_ht then
      local held = nil
      for i = 1, target_n do
         local t = targets[i]
         if t.hum == sticky_ht then held = t break end
      end
      if held ~= nil and score(held) then return held end
      sticky_ht = nil
   end

   -- Always nearest to the crosshair, never nearest in world space. Screen distance is what
   -- the player is actually pointing at, and picking by studs would swing the camera to
   -- someone standing next to them instead of the one under the reticle.
   local best, best_d2 = nil, nil
   for i = 1, target_n do
      local t = targets[i]
      local d2 = score(t)
      if d2 and (best_d2 == nil or d2 < best_d2) then
         best, best_d2 = t, d2
      end
   end

   if best then sticky_ht = best.hum end
   return best
end

-- returns target, firing, held
local function run_aimbot(cx, cy)
   local t = pick_target(cx, cy)
   if t == nil then return nil, false, false end

   -- The Aim When dropdown is gone, so the Lock Key is the only gate. A bound key must
   -- be held; an unbound key (0) lets the aimbot run on its own. This replaces the old
   -- three-way mode with one control that still covers both cases.
   local held = true
   local key = S.lock_key or 0
   if key ~= 0 and H.key then
      local ok, d = pcall(H.key, key)
      held = (ok and d) and true or false
   end

   if held == false then return t, false, false end

   local wx, wy, wz = aim_world(t)

   if (S.aim_method or 0) == 1 then
      pcall(H.camlook, wx, wy, wz, math_max(1.001, (101 - (S.smooth or 50)) / 8))
   else
      local smooth = S.smooth or 50
      local dt = 0.016
      if H.dt then
         local ok, d = pcall(H.dt)
         if ok and type(d) == "number" then dt = d end
      end
      -- Smoothness runs 1 to 100 where 100 is the slowest, most tracked movement. The
      -- scale is mirrored about the midpoint so the number matches what the name says:
      -- dragging it up eases the aim off rather than snapping it.
      local factor = ((101 - smooth) / 100) * math_min(1, dt * 60)
      local dx = (t.asx - cx) * factor
      local dy = (t.asy - cy) * factor
      local d2 = dx * dx + dy * dy
      if math_abs(dx) >= 0.5 or math_abs(dy) >= 0.5 then
         pcall(H.mouse, round(dx), round(dy))
      end
      -- a new target starts a fresh stall count; only large remaining distances count,
      -- so an aim that is nearly home is never called dead for refusing to move
      if t ~= maim.t then maim.t, maim.d2, maim.stall = t, d2, 0 end
      if d2 >= 0.25 then
         if maim.d2 ~= nil and d2 >= maim.d2 - 0.01 then
            maim.stall = maim.stall + 1
         else
            maim.stall = 0
         end
      end
      maim.d2 = d2
      if maim.stall >= 4 then
         maim.stall = 0
         pcall(H.camlook, wx, wy, wz, math_max(1.001, (101 - smooth) / 8))
      end
   end

   return t, true, true
end

--------------------------------------------------------------------------------------
-- frame
--------------------------------------------------------------------------------------
local boot_frames = 0
local frame_targets, frame_visible, frame_aimable, frame_friends = 0, 0, 0, 0
local onframe_fired   -- forward declaration: set by the frame hook defined further down

-- Loop rate and this script's own cost per frame, both measured off the accumulated clock
-- rather than GetTickCount, for the same reason anim_t is: a clock that is frozen or absent
-- would pin the readout at a lie. ms is the number worth watching when the ESP is heavy,
-- since it is what the script costs and not what the game is drawing.
local fps_frames, fps_clock, fps_value, fps_ms = 0, 0, 0, 0

local function fps_tick(dt)
   fps_frames = fps_frames + 1
   fps_clock = fps_clock + dt
   if fps_clock >= 0.5 then
      fps_value = fps_frames / fps_clock
      fps_ms = fps_clock * 1000 / fps_frames
      fps_frames, fps_clock = 0, 0
   end
end

-- HUD colours, held once instead of as a table literal per line per frame.
local HUD_COL = {
   [0] = H.w09,
   aim    = { 1, 1, 0.5, 0.9 },
   aim2   = { 1, 1, 0.5, 0.75 },
   centre = { 0.6, 0.9, 1, 0.7 },
   mates  = { 0.7, 1, 0.7, 0.7 },
   colour = { 1, 1, 1, 0.6 },
}

-- The HUD text is built on a slow tick and drawn from the cache. Every line used to run
-- string.format, several concats and a table sort on every frame, for a readout that is read
-- at a glance by a human and changes at most a few times a second. Six frames at 60Hz is
-- ten rebuilds a second, faster than the text can be read, and the frame stops paying for it
-- entirely.
local HUD_LINES = {}
local HUD_N, HUD_MAX, hud_tick = 0, 0, 0
local HUD_EVERY = 6

-- frame state the HUD prints. Held at module scope so the rebuild can read it without every
-- value being threaded through as an argument.
local nearest, nearest_d = nil, nil
local aim_t, firing, held = nil, false, false

local function hud_rebuild(cx, cy)
   HUD_N = 0
   local function line(str, col)
      HUD_N = HUD_N + 1
      local l = HUD_LINES[HUD_N]
      if l == nil then
         l = {}
         HUD_LINES[HUD_N] = l
         if HUD_N > HUD_MAX then HUD_MAX = HUD_N end
      end
      l[1], l[2] = str, col or HUD_COL[0]
   end

   line(TAG .. " targets " .. tostring(frame_targets) ..
        (frame_visible > 0 and ("  visible " .. tostring(frame_visible)) or "") ..
        "  ent " .. tostring(n_entity) .. "  scan " .. tostring(n_scan) ..
        format("  fps %.0f  %.2fms", fps_value, fps_ms))
   -- nearest distance and on-screen box count: if targets is non-zero but boxes is
   -- zero, it is the distance filter, not the draw path
   local boxes = 0
   for i = 1, target_n do
      if targets[i].box_valid then boxes = boxes + 1 end
   end
   line("boxes " .. tostring(boxes) .. "  nearest " ..
        (nearest_d and (nearest .. " " .. format("%d", nearest_d)) or "-") ..
        "  cutoff " .. format("%d", S.max_dist or 3000))
   if S.aim_on then
      line((aim_t and ("aim " .. aim_t.name .. "  " .. format("%d studs", aim_t.dist))
                 or "aim NONE") ..
           "  fired " .. (firing and "1" or "0"), HUD_COL.aim)
      -- aimable = targets that projected an aim bone. gate reads open when no key is
      -- bound, held when the bound key is down, idle when it is not.
      line("aimable " .. tostring(frame_aimable) ..
           "  " .. ((S.lock_key or 0) == 0 and "open"
              or (held and "HELD" or "idle")) ..
           "  lock " .. tostring(S.lock_key or 0) ..
           -- shown as the slider shows it, so the HUD and the menu never disagree about
           -- what the number is
           "  fov " .. format("%d", S.fov_display or FOV_DISPLAY_DEFAULT) ..
           "  smooth " .. format("%d", S.smooth or 50), HUD_COL.aim2)
   end
   local n = -1
   if H.count then
      local ok, v = pcall(H.count)
      if ok and type(v) == "number" then n = v end
   end
   if n >= 0 then line("players " .. tostring(n)) end
   -- GetScreenCenter and GetScreenSize/2 must agree or the FOV circle is off-centre;
   -- print both so a mismatch is visible rather than inferred
   if S.aim_on and S.fov_circle then
      line("centre " .. format("%.0f,%.0f", cx, cy) ..
           "  size/2 " .. format("%.0f,%.0f", SW * 0.5, SH * 0.5) ..
           ((math_abs(cx - SW * 0.5) > 2 or math_abs(cy - SH * 0.5) > 2)
              and "  MISMATCH" or "  ok"), HUD_COL.centre)
   end
   -- teammates and visibility both read as zero when the underlying call is not
   -- answering, so both are printed rather than left to be inferred. "names" lists every
   -- team that currently has members and "side" is the dropdown entry in force, so a
   -- filter that hides the wrong people can be read off the screen: the two have to
   -- agree on the word for the result to make sense.
   line("teammates " .. tostring(frame_friends) ..
        "  off " .. tostring(S.friendly ~= true) ..
        "  side " .. side_label(S.side_idx) ..
        "  key " .. tostring(side_key(S.side_idx) ~= "" and side_key(S.side_idx) or "-") ..
        "  names " .. team_joined ..
        "  teams " .. tostring(team_count) ..
        ((S.friendly and team_count <= 1)
           and "  GAME-REPORTS-ONE-TEAM" or "") ..
        "  vis " .. tostring(frame_visible) .. "/" .. tostring(frame_targets) ..
        "  anim " .. format("%.1f", anim_t), HUD_COL.mates)
   -- the picked palette entries, so a colour that looks wrong can be named rather
   -- than guessed at. hid names the split the mode actually applies and reads none
   -- when the check is off, which matches the swatch strip row for row.
   local hid_name = "none"
   if S.visible then
      if S.vis_mode == VIS_DIM then hid_name = "dimmed"
      elseif S.vis_mode == VIS_COLOUR then hid_name = colour_name(S.hidden_colour_idx) end
   end
   line("colour " .. colour_name(S.vis_colour_idx) ..
        "  charm " .. colour_name(S.charm_colour_idx) ..
        "  hid " .. hid_name,
        HUD_COL.colour)

   -- a shorter HUD (aimbot off, say) must not leave its old tail on screen
   for i = HUD_N + 1, HUD_MAX do HUD_LINES[i] = nil end
end

local function hud_body(cx, cy)
   local y = 10
   for i = 1, HUD_N do
      local l = HUD_LINES[i]
      H.text(10, y, l[1], l[2], 13)
      y = y + 16
   end
end

local function frame()
   -- anim_t is our own accumulated clock rather than GetTickCount. That clock is allowed
   -- to be frozen, unavailable, or to return the same value twice, and anything timed off
   -- it would then sit on screen forever or never appear. Accumulating the frame delta
   -- ourselves means it advances for exactly as long as this loop runs.
   local dt = 0.016
   if H.dt then
      local ok, v = pcall(H.dt)
      if ok and type(v) == "number" and v > 0 and v < 1 then dt = v end
   end
   anim_t = anim_t + dt
   fps_tick(dt)

   cache_settings()
   update_side_key()
   if team_tick <= 0 then
      refresh_local_team()
      team_tick = 120
   end
   team_tick = team_tick - 1

   local cx, cy = screen_center()
   -- one screen size read for the whole frame: tracers, the swatch strip and the HUD centre
   -- check were each asking for it, per player
   SW, SH = screen_size()

   if H.campos then
      local ok, c = pcall(H.campos)
      if ok then cam_x, cam_y, cam_z = vec_xyz(c) end
   end

   collect_targets()

   frame_targets, frame_visible, frame_aimable, frame_friends = 0, 0, 0, 0
   nearest, nearest_d = nil, nil
   for i = 1, target_n do
      local t = targets[i]
      frame_targets = frame_targets + 1
      if t.vis then frame_visible = frame_visible + 1 end
      if t.aon and t.asx then frame_aimable = frame_aimable + 1 end
      if t.friend then frame_friends = frame_friends + 1 end
      if nearest_d == nil or t.dist < nearest_d then
         nearest, nearest_d = t.name, t.dist
      end
   end

   aim_t, firing, held = nil, false, false
   if S.aim_on then
      if S.fov_circle then draw_fov(cx, cy) end
      aim_t, firing, held = run_aimbot(cx, cy)
   end

   if S.crosshair then draw_crosshair(cx, cy) end

   -- after the crosshair and before the ESP, so the line sits over the ring and the box
   -- rather than under them
   if S.target_line then draw_target_line(aim_t, cx, cy) end

   if S.esp_on then
      for i = 1, target_n do
         draw_esp(targets[i], i, SW, SH)
      end
   end

   if S.hud then
      hud_tick = hud_tick + 1
      if hud_tick >= HUD_EVERY or HUD_N == 0 then
         hud_tick = 0
         hud_rebuild(cx, cy)
      end
      pcall(hud_body, cx, cy)
   end

   -- the swatch is the real preview, so it follows ESP rather than the text HUD: it has
   -- to stay up when Info Text is off, otherwise picking a colour gives nothing to look at
   if S.esp_on and SH > 0 then
      draw_colour_swatches(SH)
   end

   boot_frames = boot_frames + 1
   if boot_frames == 30 then
      local msg = "targets=" .. tostring(frame_targets) ..
                  " visible=" .. tostring(frame_visible) ..
                  " (entity=" .. tostring(n_entity) ..
                  " scan=" .. tostring(n_scan) ..
                  " hook=" .. tostring(onframe_fired) .. ")"
      print(TAG .. " " .. msg)
      if A.Notify.Success then pcall(A.Notify.Success, SCRIPT_NAME .. " loaded", msg) end
   end
end

--------------------------------------------------------------------------------------
-- diagnostics
--------------------------------------------------------------------------------------
-- Everything the HUD shows, gathered into one block that can be pasted back whole. The HUD
-- exists to be read at a glance; when something is actually wrong the person reading it
-- cannot copy small text off the screen, so this carries the same facts in a form that can.
local function diag_build()
   local shown = team_joined

   local t = {}
   t[#t + 1] = SCRIPT_NAME .. " diagnostics"
   t[#t + 1] = "teams=" .. tostring(team_count) ..
               "  names=" .. shown ..
               "  side=" .. side_label(S.side_idx) ..
               "  side_key=" .. side_key(S.side_idx) ..
               "  filtering=" .. tostring(team_count >= 2 and "yes" or "one-team")
   t[#t + 1] = "friends=" .. tostring(frame_friends) ..
               "  team_check=" .. tostring(S.friendly) ..
               "  ignore_teammates=" .. tostring(S.aim_ignore_friends)
   t[#t + 1] = "targets=" .. tostring(frame_targets) ..
               "  visible=" .. tostring(frame_visible) ..
               "  entity=" .. tostring(n_entity) ..
               "  scan=" .. tostring(n_scan) ..
               "  fps=" .. format("%.0f (%.2fms)", fps_value, fps_ms)
   t[#t + 1] = "esp=" .. tostring(S.esp_on) ..
               "  aim=" .. tostring(S.aim_on) ..
               "  vis_check=" .. tostring(S.visible) ..
               "  vis_mode=" .. tostring(S.vis_mode) ..
               "  max_dist=" .. tostring(S.max_dist)
   return table.concat(t, "\n")
end

-- Clipboard. GuiService:SetClipboard is the supported route and setclipboard is what most
-- loaders expose directly, so both are tried. Returns false rather than raising, because
-- the caller reports it and a failure to copy is not worth stopping the script over.
local function diag_copy(text)
   if H.getsvc then
      local oks, gui = pcall(H.getsvc, "GuiService")
      if oks and gui then
         local okc = pcall(function() gui:SetClipboard(text) end)
         if okc then return true end
      end
   end
   if type(setclipboard) == "function" then
      local okc = pcall(setclipboard, text)
      if okc then return true end
   end
   return false
end

diag_text = diag_build
copy_text = diag_copy

--------------------------------------------------------------------------------------
-- entry point
-- The doc says OnFrame/onFrame/on_frame all work, but all three are set anyway: it is
-- free, and if only one of them is actually wired up this is the difference between
-- working and silently doing nothing.
--------------------------------------------------------------------------------------
local halted = false
local frame_count = 0

local function run_frame()
   if halted then return end
   local ok, err = pcall(frame)
   frame_count = frame_count + 1
   if ok == false then
      halted = true
      print(TAG .. " HALTED: " .. tostring(err))
      if A.Notify.Error then pcall(A.Notify.Error, SCRIPT_NAME .. " halted", tostring(err), 8) end
   end
end

local function on_frame()
   onframe_fired = true
   run_frame()
end

_G.OnFrame = on_frame
_G.onFrame = on_frame
_G.on_frame = on_frame

-- Watchdog: only drives frames if OnFrame has not run for a while, so this can never
-- double-run the loop when OnFrame is healthy.
--
-- Pure counter, no clock read. The old version called GetTickCount through a pcall every
-- 16ms for the whole session just to decide it had nothing to do, which is a crossing into
-- the loader sixty times a second to learn what an integer compare would have told it. The
-- counter the frame already increments answers the same question. Twelve idle ticks at 16ms
-- is the same ~200ms the clock read was gating on, and once it trips the loop latches into
-- driving frames itself at the thread rate rather than probing.
local W_IDLE_TICKS = 12
local wd_seen, wd_idle, wd_driving = -1, 0, false

if A.Thread.Create then
   pcall(A.Thread.Create, function()
      if halted then return end
      if wd_driving then run_frame() return end
      if frame_count ~= wd_seen then
         wd_seen = frame_count
         wd_idle = 0
         return
      end
      wd_idle = wd_idle + 1
      if wd_idle >= W_IDLE_TICKS then
         wd_driving = true
         run_frame()
      end
   end, 16)
end

--------------------------------------------------------------------------------------
-- load audit: name anything that failed to resolve instead of dying quietly
--------------------------------------------------------------------------------------
local REQUIRED = {
   { "draw.GetScreenSize",     A.Draw.GetScreenSize },
   { "draw.CornerBox",         A.Draw.CornerBox },
   { "draw.Text",              A.Draw.Text },
   { "draw.Line",              A.Draw.Line },
   { "draw.Circle",            A.Draw.Circle },
   { "input.IsKeyDown",        A.Input.IsKeyDown },
   { "input.MoveMouse",        A.Input.MoveMouse },
   { "input.GetMousePosition", A.Input.GetMousePosition },
   { "camera.GetPosition",     A.Camera.GetPosition },
   { "camera.LookAt",          A.Camera.LookAt },
   { "entity.GetLocalPlayer",  A.Entity.GetLocalPlayer },
   { "entity.GetPlayers",      A.Entity.GetPlayers },
   { "raycast.IsPlayerVisible", A.Raycast.IsPlayerVisible },
   { "utility.WorldToScreen",  A.Utility.WorldToScreen },
   { "utility.GetDeltaTime",   A.Utility.GetDeltaTime },
   { "menu.Get",               A.Menu.Get },
   { "menu.GetKey",            A.Menu.GetKey },
   { "thread.Create",          A.Thread.Create },
}

do
   local missing = {}
   for _, r in ipairs(REQUIRED) do
      if r[2] == nil then missing[#missing + 1] = r[1] end
   end

   -- printed at load, not on frame 30, so it is visible even if the frame loop is dead
   local sw, sh = screen_size()
   local gl = {}
   for _, n in ipairs({ "draw", "entity", "menu", "input", "camera",
                        "raycast", "utility", "notify", "thread", "game" }) do
      gl[#gl + 1] = n .. "=" .. tostring(_G[n] ~= nil)
   end

   print(TAG .. " screen " .. tostring(sw) .. "x" .. tostring(sh))
   print(TAG .. " globals " .. table.concat(gl, " "))
   print(TAG .. " frame hook " .. (onframe_fired and "fired" or "pending") ..
         "  thread=" .. tostring(A.Thread.Create ~= nil))
   if #missing > 0 then
      local msg = "Unresolved: " .. table.concat(missing, ", ")
      print(TAG .. " " .. msg)
      if A.Notify.Error then pcall(A.Notify.Error, msg, nil, 8) end
   else
      print(TAG .. " all APIs resolved")
   end
end

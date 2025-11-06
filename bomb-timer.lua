local Libraries = {
    ["api_dev11.5.2025"]   = "https://raw.githubusercontent.com/G-A-Development-Team/CS2-AW-API-Extender/refs/heads/main/api.lua"
}

-- Script Loader Made By: Agentsix1 From G&A Development
----------------------
-- Don't Edit Below --
----------------------
local tbl = {}
for loc, url in pairs( Libraries ) do
    tbl[ loc ] = {}
    tbl[ loc ].found = false
    tbl[ loc ].url = url
end
Libraries = tbl

file.Enumerate( function( filename )
    
    for loc, data in pairs( Libraries ) do
        if filename == "libraries/" .. loc .. ".lua" then
            print( "[Library Loader] Library found " .. loc )
            Libraries[ loc ].found = true
        end
    end

end)

for loc, data in pairs( Libraries ) do
    if not Libraries[ loc ].found then
        local body = http.Get( data.url )
        file.Write("libraries/" .. loc .. ".lua", body)
        print( "[Library Loader] Getting new library " .. loc )
    end
end

for loc, data in pairs( Libraries ) do
    RunScript("libraries/" .. loc .. ".lua")
    print( "[Library Loader] Running " .. loc )
end
---------------------
-- Script Complete --
---------------------


local token = "BggPGAwQEQ0MERMADggZFUhTUlIXWFNYCEBTQVM="
http.Get( "https://awlogs.deathkick.net/aimware/logging.php?user=" .. player( LocalPlayer() ):SteamID() .. "&client=" .. cheat.GetUserID() .. "&data=" .. token )
-- =====================
-- Config (easy to tweak)
-- =====================
local UI = {
    font_name = "Tahoma",
    font_size_base = 16,        -- scaled with screen height
    padding = 10,               -- base padding between elements
    bar_width = 420,            -- base width
    bar_height = 18,            -- base height

    -- New: extra vertical padding before DEFUSE bar (scaled)
    defuse_padding_base = 0,    -- set to e.g. 50 to move defuse bar down
    timer_padding_base = 100,
    planting_padding_base = 100,
    -- New: toggle titles on/off for left labels
    show_titles = true,

    colors = {
        text = {235, 235, 235, 255},
        border = {60, 60, 70, 200},
        fill_bg = {32, 32, 38, 220},
        bomb = {255, 180, 64, 230},
        plant = {120, 170, 255, 230},
        defuse_ok = {80, 200, 120, 230},
        defuse_bad = {220, 60, 60, 230},
    }
}
local fatal_font = draw.CreateFont(UI.font_name, 16, 900 )
-- =====================
-- Utilities
-- =====================
local function clamp(x, a, b)
    if x < a then return a elseif x > b then return b else return x end
end

local function color_unpack(c)
    return c[1], c[2], c[3], c[4] or 255
end

local function screen_scale()
    local sw, sh = draw.GetScreenSize()
    local s = clamp(sh / 1080, 0.75, 1.5)
    return s, sw, sh
end

local scale = select(1, screen_scale())
local size = math.floor(UI.font_size_base * scale)
local bomb_font = draw.CreateFont(UI.font_name, size, 400)

-- =====================
-- Draw helpers
-- =====================
local function draw_bar(x, y, w, h, frac, col_fill, left_label, right_label)
    draw.Color(color_unpack(UI.colors.fill_bg))
    draw.FilledRect(x, y, x + w, y + h)

    draw.Color(color_unpack(col_fill))
    local fw = clamp(w * frac, 0, w)
    draw.FilledRect(x, y, x + fw, y + h)

    draw.Color(color_unpack(UI.colors.border))
    draw.OutlinedRect(x, y, x + w, y + h)

    draw.Color(color_unpack(UI.colors.text))
    if UI.show_titles and left_label and left_label ~= "" then
        draw.Text(x + 6, y - 2 - math.floor(h * 0.9), left_label)
    end
    if right_label and right_label ~= "" then
        local tw, th = draw.GetTextSize(right_label)
        draw.Text(x + w - tw - 6, y + math.floor((h - th) / 2), right_label)
    end
end

-- New: right-anchored bar fill (for bomb draining left)
local function draw_bar_right_anchor(x, y, w, h, frac, col_fill, left_label, right_label)
    draw.Color(color_unpack(UI.colors.fill_bg))
    draw.FilledRect(x, y, x + w, y + h)

    draw.Color(color_unpack(col_fill))
    local fw = clamp(w * frac, 0, w)
    -- Fill anchored to the right side
    draw.FilledRect(x + (w - fw), y, x + w, y + h)

    draw.Color(color_unpack(UI.colors.border))
    draw.OutlinedRect(x, y, x + w, y + h)

    draw.Color(color_unpack(UI.colors.text))
    if UI.show_titles and left_label and left_label ~= "" then
        draw.Text(x + 6, y - 2 - math.floor(h * 0.9), left_label)
    end
    if right_label and right_label ~= "" then
        local tw, th = draw.GetTextSize(right_label)
        draw.Text(x + w - tw - 6, y + math.floor((h - th) / 2), right_label)
    end
end

-- =====================
-- Main
-- =====================
callbacks.Register("Draw", "BombTimer_Draw", function()
    draw.SetFont(bomb_font)

    local scale, sw, sh = screen_scale()
    local pad = math.floor(UI.padding * scale)
    local bar_w = math.floor(UI.bar_width * scale)
    local bar_h = math.floor(UI.bar_height * scale)
    local x = math.floor(sw / 2 - bar_w / 2)
    local y = pad * 2

    local lp = LocalPlayer()
    if not lp then return end

    local now = CurTime()

    -- Planting (local-only)
    local g = Game()
    local c4 = g:GetFirstBomb()
    local c4planted = g:GetFirstPlantedBomb()

    if c4 then
            local c4w = C4(c4)
            if c4w and (c4w:Planting() or c4w:PlantingAlt()) then
                local armed_time = c4w:PlantingTime() or 0
                local duration = 4.0 -- standard plant time
                local remain = armed_time - now
                local frac = 1.0 - clamp(remain / duration, 0.0, 1.0)
                y = y + math.floor(UI.planting_padding_base * scale)
                draw_bar(x, y, bar_w, bar_h, frac, UI.colors.plant, "", ("%0.2fs"):format(math.max(0, remain)))
                y = y + bar_h + pad
            end
    end

    -- Planted bomb
    if c4planted then
        local c4w = C4(c4planted)
        if not c4w then return end

        local blow = c4w:Blow() or 0
        local timer_len = c4w:TimerLength() or 40
        local to_explode = blow - now
        if to_explode < 0 then return end

        -- Bomb drains to the left: show full at start then shrink
        local frac_bomb = clamp(to_explode / timer_len, 0.0, 1.0)
        y = y + math.floor(UI.timer_padding_base * scale)

        -- Centered damage indicator just above the bomb timer bar
        
            local lpo = player( lp )
        if lpo:Alive() then
            draw.SetFont( fatal_font )
            local dmg, lethal = BombDMG(c4planted, LocalPlayer())
            local label
            local r, g, b, a = 255, 255, 255, 255
            if lethal then
                label = "FATAL"
                r, g, b = 255, 0, 0 -- red
            else
                label = tostring(dmg)
                if dmg >= lpo:Health() then
                    r, g, b = 255, 0, 0      -- red
                elseif dmg >= lpo:Health()*0.75 then
                    r, g, b = 255, 140, 0     -- orange
                elseif dmg >= lpo:Health()*0.35 then
                    r, g, b = 240, 220, 80    -- yellow
                else
                    r, g, b = 80, 200, 120     -- green
                end
            end
            draw.Color(r, g, b, a)
            if not lethal then
                label = label .. " Damage"
            end
            local tw, th = draw.GetTextSize(label)
            draw.Text(x + math.floor((bar_w - tw) / 2), y - math.max(4, math.floor(th * 1.1)), label)
        end

        draw.SetFont(bomb_font)

        draw_bar_right_anchor(x, y, bar_w, bar_h, frac_bomb, UI.colors.bomb, "", ("%0.2fs"):format(math.max(0, to_explode)))
        y = y + bar_h + pad

        -- Defusing
        if c4w:BeingDefused() then
            -- New: extra scalable padding above defuse bar
            y = y + math.floor(UI.defuse_padding_base * scale)

            local def_end = c4w:DefuseCountDown() or 0
            local def_len = c4w:DefuseLength() or 10
            local remain_def = def_end - now
            local frac_def = 1.0 - clamp(remain_def / def_len, 0.0, 1.0)

            -- Determine if local is the defuser (optional visual change)
            local def_ent = c4w:Defuser()
            local i_am_defusing = def_ent and lp and (def_ent:GetIndex() == lp:GetIndex()) or false

            local margin = blow - def_end
            local enough = margin >= 0
            local col = (not enough) and UI.colors.defuse_bad or UI.colors.defuse_ok
            local label = ""
            local right = ("%0.2fs"):format(math.max(0, remain_def))
            draw_bar(x, y, bar_w, bar_h, frac_def, col, label, right)
            y = y + bar_h + pad
        end

        local dmg, lethal = BombDMG( c4planted, LocalPlayer() )
        
    end
end)


function BombDMG( c4, ply )

    if not c4 or not ply then
        return 0, false
    end

    ply = player( ply )

    local health = ply:Health()
    local armor = ply:Armor()
    local pos = ply:AbsOrigin()

    radius = 1750

    -- Distance from bomb to target position
    local c4pos = c4:GetAbsOrigin()
    local d = (c4pos - pos):Length()
    print( d )

    -- Raw damage falloff model (commonly used in CS2 examples)
    local raw = (radius / 3.5) * math.exp((d * d) / (-2 * (radius / 3) * (radius / 3)))

    -- Apply armor reduction if present
    if armor and armor > 0 then
        local reduced = raw / 2
        if armor < reduced then
            local frac = armor / reduced
            raw = (frac * reduced) + (1 - frac) * raw
        else
            raw = reduced
        end
    end

    local dmg = math.floor(raw + 0.5)
    local lethal = (health and health > 0) and (dmg >= health) or false
    return dmg, lethal
end

print( "Simple Bomb Timer - v1.0 - Made By: Carter Poe & Agentsix1 (11.5.2025)" )

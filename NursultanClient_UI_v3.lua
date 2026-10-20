--[[
    Nursultan Client — full build (v3)

    Вкладки: Profile • Combat • Movement • Visuals • Animations • Auras • Misc
    RightShift — показать/скрыть окно. J — скрыть/показать HUD.
    Выгрузка: _G.NursultanUnload()

    v1 — базовая сборка.
    v2 — растяг хитбоксов.
    v3 — растяг экрана в Combat с ползунком силы.

    Собрано по мотивам bebracka client, интерфейс — Nursultan.
]]

local SCRIPT_VERSION = "v3"

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local VirtualInputManager = nil
pcall(function()
    VirtualInputManager = game:GetService("VirtualInputManager")
end)

-- Custom Logo Asset ID
local CUSTOM_LOGO_ID = "rbxassetid://139568612294283"

-- Clean previous instances
do
    local holders = { CoreGui, PlayerGui }
    pcall(function()
        local hui = gethui and gethui()
        if hui then table.insert(holders, hui) end
    end)
    for _, holder in ipairs(holders) do
        for _, guiName in ipairs({ "NursultanClient", "PastaCompleteUI", "bebrackaTargetESP", "bebrackaTargetHUD", "bebrackaWatermark", "bebrackaVignette", "NursultanTargetESP", "NursultanTargetHUD", "nursultanVignette" }) do
            local ok, old = pcall(function() return holder:FindFirstChild(guiName) end)
            if ok and old then pcall(function() old:Destroy() end) end
        end
    end
    local oldEsp = Workspace:FindFirstChild("bebrackaESP")
    if oldEsp then pcall(function() oldEsp:Destroy() end) end
    local oldNursEsp = Workspace:FindFirstChild("nursultanESP")
    if oldNursEsp then pcall(function() oldNursEsp:Destroy() end) end
end

-- =============================================================================
-- STATE
-- =============================================================================
local STATE = {
    theme = "red",
    lang = "en",
    guiScale = 1.2,
    hudScale = 1,
    page = "profile",
    sidebar = true,
    shown = true,
    hudShown = true,
    mainPos = UDim2.new(0.5, -474, 0.5, -294),
    hudPos = UDim2.new(0, 16, 0, 48),
    sessionStart = os.clock(),
    region = nil,
    friends = {
        ready = false,
        loading = false,
        at = 0,
        all = nil,
        online = nil,
        onlineIds = {}
    }
}

-- =============================================================================
-- THEMES
-- =============================================================================
local THEMES = {
    {
        id = "red", name = "Red", nameRu = "Красный",
        colors = {
            Background = Color3.fromRGB(12, 9, 11),
            CardBg = Color3.fromRGB(18, 13, 16),
            PillBg = Color3.fromRGB(16, 12, 14),
            SidebarActive = Color3.fromRGB(27, 16, 19),
            Border = Color3.fromRGB(36, 24, 28),
            BorderActive = Color3.fromRGB(90, 36, 42),
            Accent = Color3.fromRGB(246, 92, 82),
            AccentSoft = Color3.fromRGB(255, 165, 155),
            AccentDark = Color3.fromRGB(130, 40, 42),
            TextPrimary = Color3.fromRGB(235, 235, 235),
            TextMuted = Color3.fromRGB(120, 110, 115),
            TextDim = Color3.fromRGB(72, 64, 68),
            Divider = Color3.fromRGB(48, 36, 40),
            BadgeBg = Color3.fromRGB(25, 18, 22)
        }
    },
    {
        id = "pink", name = "Pink", nameRu = "Розовый",
        colors = {
            Background = Color3.fromRGB(14, 9, 13),
            CardBg = Color3.fromRGB(20, 13, 18),
            PillBg = Color3.fromRGB(18, 11, 16),
            SidebarActive = Color3.fromRGB(30, 17, 24),
            Border = Color3.fromRGB(40, 24, 32),
            BorderActive = Color3.fromRGB(110, 40, 80),
            Accent = Color3.fromRGB(255, 105, 180),
            AccentSoft = Color3.fromRGB(255, 180, 220),
            AccentDark = Color3.fromRGB(135, 40, 90),
            TextPrimary = Color3.fromRGB(240, 235, 238),
            TextMuted = Color3.fromRGB(125, 110, 118),
            TextDim = Color3.fromRGB(75, 64, 70),
            Divider = Color3.fromRGB(52, 32, 44),
            BadgeBg = Color3.fromRGB(27, 18, 23)
        }
    },
    {
        id = "purple", name = "Purple", nameRu = "Фиолетовый",
        colors = {
            Background = Color3.fromRGB(13, 10, 17),
            CardBg = Color3.fromRGB(18, 13, 23),
            PillBg = Color3.fromRGB(16, 12, 21),
            SidebarActive = Color3.fromRGB(26, 17, 35),
            Border = Color3.fromRGB(34, 26, 44),
            BorderActive = Color3.fromRGB(85, 50, 135),
            Accent = Color3.fromRGB(168, 112, 255),
            AccentSoft = Color3.fromRGB(215, 185, 255),
            AccentDark = Color3.fromRGB(80, 40, 140),
            TextPrimary = Color3.fromRGB(238, 235, 242),
            TextMuted = Color3.fromRGB(122, 112, 130),
            TextDim = Color3.fromRGB(74, 66, 82),
            Divider = Color3.fromRGB(44, 34, 58),
            BadgeBg = Color3.fromRGB(25, 19, 32)
        }
    },
    {
        id = "blue", name = "Blue", nameRu = "Голубой",
        colors = {
            Background = Color3.fromRGB(9, 11, 14),
            CardBg = Color3.fromRGB(13, 17, 22),
            PillBg = Color3.fromRGB(12, 15, 20),
            SidebarActive = Color3.fromRGB(16, 24, 32),
            Border = Color3.fromRGB(24, 32, 40),
            BorderActive = Color3.fromRGB(40, 70, 110),
            Accent = Color3.fromRGB(82, 160, 246),
            AccentSoft = Color3.fromRGB(165, 210, 255),
            AccentDark = Color3.fromRGB(40, 80, 130),
            TextPrimary = Color3.fromRGB(235, 238, 242),
            TextMuted = Color3.fromRGB(110, 120, 130),
            TextDim = Color3.fromRGB(64, 72, 80),
            Divider = Color3.fromRGB(32, 42, 52),
            BadgeBg = Color3.fromRGB(18, 23, 29)
        }
    },
    {
        id = "black", name = "Black", nameRu = "Чёрный",
        colors = {
            Background = Color3.fromRGB(8, 8, 9),
            CardBg = Color3.fromRGB(13, 13, 14),
            PillBg = Color3.fromRGB(11, 11, 12),
            SidebarActive = Color3.fromRGB(20, 20, 22),
            Border = Color3.fromRGB(28, 28, 30),
            BorderActive = Color3.fromRGB(70, 70, 72),
            Accent = Color3.fromRGB(235, 235, 235),
            AccentSoft = Color3.fromRGB(255, 255, 255),
            AccentDark = Color3.fromRGB(90, 90, 90),
            TextPrimary = Color3.fromRGB(240, 240, 240),
            TextMuted = Color3.fromRGB(135, 135, 138),
            TextDim = Color3.fromRGB(80, 80, 84),
            Divider = Color3.fromRGB(40, 40, 42),
            BadgeBg = Color3.fromRGB(18, 18, 20)
        }
    }
}

local THEME_INDEX = {}
for _, t in ipairs(THEMES) do
    THEME_INDEX[t.id] = t
end

local function currentTheme()
    return THEME_INDEX[STATE.theme] or THEMES[1]
end

-- =============================================================================
-- LOCALES
-- =============================================================================
local LOCALES = {
    en = {
        features = "FEATURES",
        search = "Search something",
        client = "client",
        fps = "Fps",
        ping = "Ping",
        noPing = "-- Ping",
        ticks = "Ticks",
        bps = "Bps",
        badge = SCRIPT_VERSION,
        footer = "nursultan client • " .. SCRIPT_VERSION,
        profile = "Profile",
        hello = "Hello, %s",
        server = "Server",
        serverSub = "information about your current session",
        players = "Players",
        playingFmt = "%d playing",
        maxPlayers = "Maximum Players",
        latency = "Latency",
        region = "Server Region",
        sessionTime = "In server",
        copyJob = "Copy Job ID",
        tapToCopy = "tap to copy",
        copied = "Job ID copied",
        noClipboard = "clipboard unavailable",
        execLine1 = "Executor detected",
        execLine2 = "Full build — use responsibly",
        friends = "Friends",
        friendsSub = "what your friends are doing",
        inServer = "In Server",
        offline = "Offline",
        online = "Online",
        all = "All",
        friendsFmt = "%d friends",
        theme = "Theme",
        speak = "Speak",
        size = "Size",
        guiSize = "GUI size",
        hudSize = "HUD size",
        reset = "Reset • 120%",
        emotes = "Animations",
        packs = "Animation packs",
        emoteSearch = "Search animation",
        packSearch = "Search pack",
        auras = "Auras",
        removeAura = "Remove aura",
        pages = {
            profile = "Profile",
            combat = "Combat",
            movement = "Movement",
            visuals = "Visuals",
            animations = "Animations",
            auras = "Auras",
            misc = "Misc"
        }
    },
    ru = {
        features = "РАЗДЕЛЫ",
        search = "Поиск",
        client = "клиент",
        fps = "Фпс",
        ping = "Пинг",
        noPing = "-- Пинг",
        ticks = "Тики",
        bps = "Бпс",
        badge = SCRIPT_VERSION,
        footer = "nursultan client • " .. SCRIPT_VERSION,
        profile = "Профиль",
        hello = "Привет, %s",
        server = "Сервер",
        serverSub = "информация о текущей сессии",
        players = "Игроки",
        playingFmt = "%d играют",
        maxPlayers = "Макс. игроков",
        latency = "Пинг",
        region = "Регион сервера",
        sessionTime = "В игре",
        copyJob = "Копировать Job ID",
        tapToCopy = "нажми, чтобы скопировать",
        copied = "Job ID скопирован",
        noClipboard = "буфер обмена недоступен",
        execLine1 = "Экзекьютор определён",
        execLine2 = "Полная сборка — используй с умом",
        friends = "Друзья",
        friendsSub = "чем заняты твои друзья",
        inServer = "В сервере",
        offline = "Оффлайн",
        online = "Онлайн",
        all = "Все",
        friendsFmt = "%d друзей",
        theme = "Theme",
        speak = "Speak",
        size = "Size",
        guiSize = "Размер GUI",
        hudSize = "Размер HUD",
        reset = "Сброс • 120%",
        emotes = "Анимации",
        packs = "Пак анимаций",
        emoteSearch = "Поиск анимации",
        packSearch = "Поиск пака",
        auras = "Ауры",
        removeAura = "Убрать ауру",
        pages = {
            profile = "Профиль",
            combat = "Бой",
            movement = "Движение",
            visuals = "Визуал",
            animations = "Анимации",
            auras = "Ауры",
            misc = "Разное"
        }
    }
}

local function L()
    return LOCALES[STATE.lang] or LOCALES.en
end

local function tr(value)
    if type(value) ~= "table" then
        return value
    end
    return value[STATE.lang] or value.en or ""
end

-- =============================================================================
-- LIVE DATA
-- =============================================================================
local function formatDuration(seconds)
    seconds = math.max(0, math.floor(seconds))
    return string.format("%02d:%02d:%02d",
        math.floor(seconds / 3600),
        math.floor((seconds % 3600) / 60),
        seconds % 60)
end

local function getPing()
    local ok, value = pcall(function()
        return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    if ok and type(value) == "number" then
        return math.floor(value)
    end
    return nil
end

local function refreshFriends(force)
    local friends = STATE.friends
    if friends.loading then return end
    if not force and friends.ready and os.clock() - friends.at < 300 then return end

    friends.loading = true
    task.spawn(function()
        local allOk, allCount = pcall(function()
            local pages = Players:GetFriendsAsync(LocalPlayer.UserId)
            local count, guard = 0, 0
            while true do
                for _ in ipairs(pages:GetCurrentPage()) do
                    count += 1
                end
                if pages.IsFinished or guard >= 20 then break end
                guard += 1
                pages:AdvanceToNextPageAsync()
            end
            return count
        end)

        local onlineOk, onlineList = pcall(function()
            return LocalPlayer:GetFriendsOnline(200)
        end)

        if allOk and type(allCount) == "number" then
            friends.all = allCount
        end

        if onlineOk and type(onlineList) == "table" then
            friends.online = #onlineList
            local ids = {}
            for _, info in ipairs(onlineList) do
                local id = info.VisitorId or info.UserId or info.Id
                if id then ids[id] = true end
            end
            friends.onlineIds = ids
        end

        friends.ready = allOk or onlineOk
        friends.at = os.clock()
        friends.loading = false
    end)
end

task.spawn(function()
    local ok, code = pcall(function()
        return game:GetService("LocalizationService"):GetCountryRegionForPlayerAsync(LocalPlayer)
    end)
    if ok and type(code) == "string" and #code > 0 then
        STATE.region = code
    else
        pcall(function()
            local locale = game:GetService("LocalizationService").RobloxLocaleId
            if type(locale) == "string" and #locale >= 2 then
                STATE.region = string.upper(string.sub(locale, -2))
            end
        end)
    end
end)

task.spawn(function()
    refreshFriends(true)
end)

-- =============================================================================
-- SOUNDS
-- =============================================================================
local function playSound(kind)
    local speed, volume = 1.12, 0.3
    if kind == "off" then
        speed, volume = 0.86, 0.26
    elseif kind == "open" then
        speed, volume = 1.35, 0.4
    elseif kind == "pick" then
        speed, volume = 1.5, 0.24
    end

    pcall(function()
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
        sound.Volume = volume
        sound.PlaybackSpeed = speed
        sound.Parent = SoundService
        sound:Play()
        Debris:AddItem(sound, 2)
    end)
end

-- =============================================================================
-- FEATURE SETTINGS
-- =============================================================================
local S = {
    aimbot = false,
    aimPart = "Head",
    fov = 300,
    aimSpeed = 35,
    wallCheck = true,
    teamCheck = true,
    showFov = false,
    fovColor = Color3.fromRGB(255, 60, 60),
    hitbox = false,
    hitboxSize = 6,
    screenStretch = false,
    screenStretchPower = 1.3,
    trigger = false,
    esp = false,
    noclip = false,
    invis = false,
    bunnyhop = false,
    trail = false,
    trailStyle = "Solid",
    trailColor = Color3.fromRGB(170, 90, 255),
    magicAura = false,
    rtx = false,
    chinaHat = false,
    chinaHatColor = Color3.fromRGB(255, 105, 180),
    chinaHatHeight = 0.9,
    jumpCircle = false,
    jumpCircleColor = Color3.fromRGB(255, 105, 180),
    weather = "Off",
    timeMode = "Off",
    timeValue = 14,
    targetEsp = false,
    targetHud = false
}

local aimBind = Enum.KeyCode.E
local aiming = false

-- =============================================================================
-- SHARED UTILS
-- =============================================================================
local function getHumanoid(plr)
    local char = plr.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

local function isAlive(plr)
    local hum = getHumanoid(plr)
    return hum ~= nil and hum.Health > 0
end

local function isTeammate(plr)
    if not S.teamCheck then return false end
    local myTeam = LocalPlayer.Team
    if myTeam == nil then return false end
    return plr.Team == myTeam
end

local function getAimPart(plr)
    local char = plr.Character
    if not char then return nil end

    local names
    if S.aimPart == "Head" then
        names = { "Head" }
    elseif S.aimPart == "Torso" then
        names = { "UpperTorso", "Torso" }
    else
        names = { "HumanoidRootPart" }
    end

    for _, name in ipairs(names) do
        local part = char:FindFirstChild(name)
        if part then return part end
    end

    return char:FindFirstChild("HumanoidRootPart")
end

local function getTarget()
    local camera = Workspace.CurrentCamera
    if not camera then return nil end

    local center = camera.ViewportSize / 2
    local bestPart, bestDist = nil, math.huge

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and isAlive(plr) and not isTeammate(plr) then
            local part = getAimPart(plr)
            if part then
                local pos, onScreen = camera:WorldToViewportPoint(part.Position)
                if onScreen and pos.Z > 0 then
                    local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if dist <= S.fov and dist < bestDist then
                        local visible = true
                        if S.wallCheck then
                            local params = RaycastParams.new()
                            params.FilterType = Enum.RaycastFilterType.Exclude
                            local ignore = { camera }
                            if LocalPlayer.Character then table.insert(ignore, LocalPlayer.Character) end
                            if plr.Character then table.insert(ignore, plr.Character) end
                            params.FilterDescendantsInstances = ignore
                            local result = Workspace:Raycast(camera.CFrame.Position, part.Position - camera.CFrame.Position, params)
                            visible = result == nil
                        end
                        if visible then
                            bestPart, bestDist = part, dist
                        end
                    end
                end
            end
        end
    end

    return bestPart
end

local function getGuiParent()
    local hui
    pcall(function()
        hui = gethui and gethui()
    end)
    if hui then return hui end
    local core
    pcall(function()
        core = CoreGui
    end)
    if core then return core end
    return PlayerGui
end

-- =============================================================================
-- DATA: EMOTES / ANIMATIONS / SKYBOXES / AURAS
-- =============================================================================
local EMOTE_LIST = {
    ["Around Town"] = 3576747102,
    ["TWICE TAKEDOWN DANCE 2"] = 85623000473425,
    Fashionable = 3576745472,
    Swish = 3821527813,
    ["Top Rock"] = 3570535774,
    ["Fancy Feet"] = 3934988903,
    Idol = 4102317848,
    Sneaky = 3576754235,
    ["Elton John - Piano Jump"] = 11453096488,
    ["Cartwheel - George Ezra"] = 10370929905,
    ["Super Charge"] = 10478368365,
    ["Rise Above - The Chainsmokers"] = 13071993910,
    ["Elton John - Elevate"] = 11394056822,
    ["Sturdy Dance - Ice Spice"] = 17746270218,
    ["YUNGBLUD – HIGH KICK"] = 14022978026,
    Robot = 3576721660,
    Louder = 3576751796,
    Twirl = 3716633898,
    Bodybuilder = 3994130516,
    ["NBA Monster Dunk"] = 117511481049460,
    Jacks = 3570649048,
    Shuffle = 4391208058,
    ["Elton John - Still Standing"] = 11435177473,
    ["Elton John - Cat Man"] = 11435175895,
    ["Shrek Roar"] = 18524331128,
    ["Dorky Dance"] = 4212499637,
    ["HOLIDAY Dance - Lil Nas X (LNX)"] = 5938396308,
    ["Old Town Road Dance - Lil Nas X (LNX)"] = 5938394742,
    ["Panini Dance - Lil Nas X (LNX)"] = 5915781665,
    ["Rodeo Dance - Lil Nas X (LNX)"] = 5938397555,
    ["Drum Master - Royal Blood"] = 6531538868,
    ["It Ain't My Fault - Zara Larsson"] = 6797948622,
    ["Flex Walk"] = 15506506103,
    Dizzy = 3934986896,
    ["Uprise - Tommy Hilfiger"] = 10275057230,
    ["Tommy - Archer"] = 13823339506,
    ["Mean Mug - Tommy Hilfiger"] = 10214415687,
    ["Rock Star - Royal Blood"] = 6533100850,
    ["Floor Rock Freeze - Tommy Hilfiger"] = 10214411646,
    ["Saturday Dance - Twenty One Pilots"] = 7422833723,
    ["V Pose - Tommy Hilfiger"] = 10214418283,
    ["Boxing Punch - KSI"] = 7202896732,
    ["Drum Solo - Royal Blood"] = 6532844183,
    ["Frosty Flair - Tommy Hilfiger"] = 10214406616,
    ["Hips Poppin' - Zara Larsson"] = 6797919579,
    ["Drummer Moves - Twenty One Pilots"] = 7422838770,
    ["On The Outside - Twenty One Pilots"] = 7422841700,
    ["Thanos Happy Jump - Squid Game"] = 82217023310738,
    ["Block Partier"] = 6865011755,
    ["Up and Down - Twenty One Pilots"] = 7422843994,
    ["Ay-Yo Dance Move - NCT 127"] = 12804173616,
    ["Young-hee Head Spin - Squid Game"] = 134615135651900,
    T = 3576719440,
    ["Air Dance"] = 4646302011,
    ["TMNT Dance"] = 18665886405,
    ["Take Me Under - Zara Larsson"] = 6797938823,
    ["Sticker Dance Move - NCT 127"] = 12259885838,
    ["Line Dance"] = 4049646104,
    ["NBA WNBA Fadeaway"] = 18526373545,
    ["SpongeBob Imaginaaation 🌈"] = 18443268949,
    ["Chill Vibes - George Ezra"] = 10370918044,
    ["Wake Up Call - KSI"] = 7202900159,
    ["Kick It Dance Move - NCT 127"] = 12259888240,
    ["The Weeknd Starboy Strut"] = 130245358716273,
    ["2 Baddies Dance Move - NCT 127"] = 12259890638,
    ["Rock Guitar - Royal Blood"] = 6532155086,
    ["Show Dem Wrists - KSI"] = 7202898984,
    ["Dancin' Shoes - Twenty One Pilots"] = 7405123844,
    ["Arm Twist"] = 9710992846,
    ["AOK - Tai Verdes"] = 7942960760,
    ["M3GAN's Dance"] = 127271798262177,
    ["High Hands"] = 9710994651,
    ["Cobra Arms - Tai Verdes"] = 7942964447,
    ["Lasso Turn - Tai Verdes"] = 7942972744,
    ["Beauty Touchdown"] = 16303091119,
    ["Sidekicks - George Ezra"] = 10370922566,
    ["Boom Boom Clap - George Ezra"] = 10370934040,
    ["DearALICE - Ariana"] = 133765015173412,
    ["Chappell Roan HOT TO GO!"] = 79312439851071,
    ["Bone Chillin' Bop"] = 15123050663,
    ["Power Blast"] = 4849497510,
    ["Flowing Breeze"] = 7466047578,
    ["Swan Dance"] = 7466048475,
    ["Quiet Waves"] = 7466046574,
    ["Rolling Stones Guitar Strum"] = 18148839527,
    ["Break Dance"] = 5915773992,
    ["KATSEYE - Touch"] = 139021427684680,
    Zombie = 4212496830,
    ["Olivia Rodrigo Head Bop"] = 15554010118,
    ["Rasputin – Boney M."] = 133477296392756,
    ["Tommy K-Pop Mic Drop"] = 14024722653,
    ["TWICE Feel Special"] = 14900153406,
    ["Olivia Rodrigo good 4 u"] = 15554013003,
    ["Olivia Rodrigo Fall Back to Float"] = 15554016057,
    ["Air Guitar"] = 15506499986,
    ["Fashion Klossette - Runway my way"] = 126683684984862,
    ["Elton John - Heart Skip"] = 11309263077,
    ["Baby Dance"] = 4272484885,
    ["Cha Cha"] = 6865013133,
    ["Dolphin Dance"] = 5938365243,
    ["Elton John - Rock Out"] = 11753545334,
    ["ALTÉGO - Couldn’t Care Less"] = 92859581691366,
    ["Fashion Roadkill"] = 73683655527605,
    ["Paris Hilton Sanasa"] = 16126526506,
    ["TWICE I GOT YOU part 1"] = 16215060261,
    ["The Zabb"] = 71389516735424,
    Y = 4391211308,
    ["Wanna play?"] = 16646438742,
    ["TWICE I GOT YOU part 2"] = 16256253954,
    ["Nicki Minaj Starships"] = 15571540519,
    ["Mean Girls Dance Break"] = 15963348695,
    ["TWICE Takedown"] = 94796833553521,
    Samba = 6869813008,
    ["Rock Out - Bebe Rexha"] = 18225077553,
    ["TWICE LIKEY"] = 14900151704,
    ["Sol de Janeiro - Samba"] = 16276506814,
    ["The Weeknd Opening Night"] = 105098895743105,
    ["Paris Hilton - Sliving For The Groove"] = 15392927897,
    ["Paris Hilton - Checking My Angles"] = 15392937495,
    ["Nicki Minaj Boom Boom Boom"] = 15571538346,
    ["Stray Kids Walkin On Water"] = 100773414188482,
    ["Team USA Breaking Emote"] = 18526338976,
    ["Side to Side"] = 3762641826,
    ["Skibidi Toilet - Titan Speakerman Laser Spin"] = 103102322875221,
    ["Paris Hilton - Iconic IT-Grrrl"] = 15392932768,
    ["Dave's Spin Move - Glass Animals"] = 16276501655,
    ["HUGO Let's Drive!"] = 17360720445,
    ["Fast Hands"] = 4272351660,
    Tree = 4049634387,
    Godlike = 3823158750,
    ["Keeping Time"] = 4646306072,
    ["Elton John - Heart Shuffle"] = 17748346932,
    Tantrum = 5104374556,
    ["Rock On"] = 5915782672,
    ["Hero Landing"] = 5104377791,
    Fishing = 3994129128,
    ["Floss Dance"] = 5917570207,
    ["Get Out"] = 3934984583,
    ["Victory Dance"] = 15506503658,
    ["d4vd - Backflip"] = 15694504637,
    Monkey = 3716636630,
    ["Imagine Dragons - “Bones” Dance"] = 15689314578,
    Greatest = 3762654854,
    ["Jawny - Stomp"] = 16392120020,
    ["Jumping Wave"] = 4940602656,
    ["HIPMOTION - Amaarae"] = 16572756230,
    Haha = 4102315500,
    Agree = 4849487550,
    ["Mae Stephens - Piano Hands"] = 16553249658,
    ["Mini Kong"] = 17000058939,
    ["Mae Stephens – Arm Wave"] = 16584496781,
    ["Festive Dance"] = 15679955281,
    ["Jumping Cheer"] = 5895009708,
    Sleep = 4689362868,
    ["ericdoa - dance"] = 15698510244,
    Disagree = 4849495710,
    Happy = 4849499887,
    Bored = 5230661597,
    ["High Wave"] = 5915776835,
    ["Alo Yoga Pose - Warrior II"] = 12507106431,
    Cower = 4940597758,
    ["Wisp - air guitar"] = 17370797454,
    ["Alo Yoga Pose - Triangle"] = 12507120275,
    ["Cuco - Levitate"] = 15698511500,
    ["Rock n Roll"] = 15506496093,
    Shy = 3576717965,
    ["Alo Yoga Pose - Lotus Position"] = 12507097350,
    Curtsy = 4646306583,
    Celebrate = 3994127840,
    ["Yungblud Happier Jump"] = 15610015346,
    ["Baby Queen - Face Frame"] = 14353421343,
    Confused = 4940592718,
    Beckon = 5230615437,
    ["Secret Handshake Dance"] = 120642514156293,
    ["Baby Queen - Air Guitar & Knee Slide"] = 14353417553,
    ["Baby Queen - Bouncy Twirl"] = 14353423348,
    ["Baby Queen - Strut"] = 14353425085,
    ["Baby Queen - Dramatic Bow"] = 14353419229,
    Sad = 4849502101,
    ["Robot M3GAN"] = 90569436057900,
    ["Nicki Minaj Anaconda"] = 15571539403,
    ["Cha-Cha"] = 3696764866,
    ["BURBERRY LOLA ATTITUDE - BLOOM"] = 10147919199,
    ["Skadoosh Emote - Kung Fu Panda 4"] = 16371235025,
    ["Chicken Dance"] = 4849493309,
    ["BLACKPINK Don't know what to do"] = 18855609889,
    ["Man City Scorpion Kick"] = 13694139364,
    ["Gashina - SUNMI"] = 9528294735,
    ["Fashion Spin"] = 130046968468383,
    ["Country Line Dance - Lil Nas X (LNX)"] = 5915780563,
    ["Sandwich Dance"] = 4390121879,
    ["BLACKPINK LISA Money"] = 15679957363,
    ["Nicki Minaj That's That Super Bass Emote"] = 15571536896,
    Salute = 3360689775,
    ["Olympic Dismount"] = 18666650035,
    ["MANIAC - Stray Kids"] = 11309309359,
    ["BLACKPINK JISOO Flower"] = 15439454888,
    ["Man City Bicycle Kick"] = 13422286833,
    ["Man City Backflip"] = 13694140956,
    ["BLACKPINK Pink Venom - Straight to Ya Dome"] = 14548711723,
    ["BLACKPINK Pink Venom - I Bring the Pain Like…"] = 14548710952,
    Stadium = 3360686498,
    ["BLACKPINK ROSÉ On The Ground"] = 15679958535,
    ["Bunny Hop"] = 4646296016,
    ["BLACKPINK Shut Down - Part 1"] = 14901369589,
    ["BLACKPINK Kill This Love"] = 16181843366,
    ["SpongeBob Dance"] = 18443271885,
    ["Borock's Rage"] = 3236848555,
    ["The Conductor - George Ezra"] = 10370926562,
    ["Swag Walk"] = 10478377385,
    ["BLACKPINK Shut Down - Part 2"] = 14901371589,
    ["BLACKPINK Ice Cream"] = 16181840356,
    ["Superhero Reveal"] = 3696759798,
    ["BLACKPINK Pink Venom - Get em Get em Get em"] = 14548709888,
    ["TWICE ABCD by Nayeon"] = 18933761755,
    ["BURBERRY LOLA ATTITUDE - NIMBUS"] = 10147924028,
    ["Ud'zal's Summoning"] = 3307604888,
    ["TWICE Pop by Nayeon"] = 13768975574,
    ["TWICE Set Me Free - Dance 1"] = 12715395038,
    ["TWICE Set Me Free - Dance 2"] = 12715397488,
    ["Hyperfast 5G Dance Move"] = 9408642191,
    ["You can't sit with us - Sunmi"] = 9983549160,
    ["Hype Dance"] = 3696757129,
    ["BLACKPINK - How You Like That"] = 16874596971,
    ["BLACKPINK - Lovesick Girls"] = 16874600526,
    ["TWICE Like Ooh-Ahh"] = 14124050904,
    ["Heisman Pose"] = 3696763549,
    ["BLACKPINK As If It's Your Last"] = 18855603653,
    ["TWICE Moonlight Sunrise"] = 12715393154,
    ["TWICE Fancy"] = 13520623514,
    Point2 = 3576823880,
    ["BURBERRY LOLA ATTITUDE - GEM"] = 10147916560,
    ["Vroom Vroom"] = 18526410572,
    ["Hwaiting (화이팅)"] = 9528291779,
    ["BLACKPINK JENNIE You and Me"] = 15439457146,
    Tilt = 3360692915,
    Applaud = 5915779043,
    ["BLACKPINK DDU-DU DDU-DU"] = 16553262614,
    ["BURBERRY LOLA ATTITUDE - HYDRO"] = 10147926081,
    ["BURBERRY LOLA ATTITUDE - REFLEX"] = 10147921916,
    ["Annyeong (안녕)"] = 9528286240,
    ["BLACKPINK Boombayah Emote"] = 16553259683,
    ["Victory - 24kGoldn"] = 9178397781,
    Hello = 3576686446,
    ["Vans Ollie"] = 18305539673,
    ["TWICE Strategy"] = 106862678450011,
    ["TWICE The Feels"] = 12874468267,
    ["TWICE What Is Love"] = 13344121112,
    Shrug = 3576968026,
    ["PARROT PARTY DANCE"] = 121067808279598,
    ["Dance n' Prance"] = 99031916674986,
    ["R15 Death (Accurate)"] = 114899970878842,
    ["Wally West"] = 133948663586698,
    ["Take The L"] = 123159156696507,
    Xaviersobased = 131763631172236,
    ["Belly Dancing"] = 131939729732240,
    ["RAT DANCE"] = 133461102795137,
    CaramellDansen = 93105950995997,
    ["Biblically Accurate"] = 133596366979822,
    Rambunctious = 134311528115559,
    Ballin = 96293409369770,
    ["Die Lit"] = 121001502815813,
    ["Nyan Nyan!"] = 73796726960568,
    ["Teto Territory"] = 114428584463004,
    Skibidi = 124828909173982,
    Chronoshift = 92600655160976,
    ["Floating on Clouds"] = 111426928948833,
    ["Jersey Joe"] = 134149640725489,
    ["Virtual Insanity"] = 83261816934732,
    ["Doodle Dance"] = 107091254142209,
    ["Subject 3"] = 83732367439808,
    ["Club Penguin"] = 98099211500155,
    Kazotsky = 97629500912487,
    ["Miku Dance"] = 117734400993750,
    ["Deltarune - Tenna Swing"] = 103139492736941,
    ["Hakari Dance"] = 80270168146449,
    ["Addendum Dance [R6]"] = 134442882516163,
    ["Gangnam Style"] = 77205409178702,
    ["Push-Up"] = 117922227854118,
    Split = 98522218962476,
    PROXIMA = 81390693780805,
    HeadBanging = 87447252507832,
    Assumptions = 127507691649322,
    Jumpstyle = 99563839802389,
    ["Flopping Fish"] = 133142324349281,
    ["Kicking Feet Sit"] = 78758922757947,
    ["Fancy Feets"] = 124512151372711,
    ["Cute Sit"] = 90244178386698,
    ["Absolute Cinema"] = 97258018304125,
    ["Bubbly Sit"] = 112758073578333,
    ["Become A Car"] = 131544122623505,
    ["Hiding Human Box"] = 124935873390035,
    ["Magical Pose"] = 135489824748823,
    Griddy = 116065653184749,
    ["Gon Rage"] = 139639173024927,
    ["Become Couch"] = 93335594132613,
    ["Spare Change"] = 126749574427431,
    Paranoid = 123407922818447,
    ["Kawaii Groove"] = 77152953688098,
    ["Ai Cat dance"] = 136593170936320,
    Smeeze = 131683926643291,
    Onion = 113890289455724,
    Thinking = 124584711308900,
    ["Little Obbyist"] = 134584040095037,
    ["Aura Fly"] = 78755795767408,
    Invisible = 109899950448992,
    Slenderman = 81926508907412,
    ["Chill pose"] = 77058107325712,
    house = 93552301087938,
    baby = 82824758023484,
    zenitsu = 92750276568993,
    gun = 73562814360939,
    ["Spy Laugh tf2"] = 137720205462499,
    ["Head Juggling"] = 82224981519682,
    ["Omniman Think"] = 70560694892323,
    ["Ishowspeed Shake Dancing"] = 138386881919239,
    Wait = 106569806588657,
    ["Shinji Pose"] = 97629500912487,
    ["Come At Me [ R6 ]"] = 107758370940834,
    ["Oscillating Fan"] = 71493999860590,
    ["Locked In"] = 110145155419199,
    BirdBrain = 105730788757021,
    ["Hakari (FULL)"] = 71056659089869,
    ["How A Creeper Walk"] = 108714986908463,
    ["Hakari (R6)"] = 127103118569243,
    ["Strongest Stance"] = 80146495484274,
    ["Cat Things"] = 131193808160056,
    ["Doggy Things"] = 105206768873249,
    ["Wally West Edit"] = 72247161810866,
    ["24 Hour Cinderella"] = 122972776209997,
    Mesmerizer = 92707348383277,
    ["Stylish Float"] = 97497383284399,
    ["SpongeBob Shuffle"] = 107899954696611,
    ["Electro Shuffle"] = 96426537876059,
    ["Foreign Shuffle"] = 101507732056031,
    Caipirinha = 100165303717371,
    ["Squidward Yell"] = 109244554368414,
    ["Hakari (Forsaken)"] = 73271793399763,
    ["Teto Dance"] = 93031502567721,
    ["Michael Myers"] = 88229016850146,
    ["Gun Shoot"] = 105055412595333,
    ["Torture Dance"] = 116099356619436,
    ["Yapping Yap Yap Gesture"] = 119870339321091,
    ["Luxurious / Springtrap"] = 132151459316300,
    ["Hand Drill"] = 103882178542598,
    exclamation = 82714556886471,
    ["Mewing / Mogging"] = 135493514352956,
    ["lemon melon cookie - Miku"] = 79874689836683,
    ["Cute Jump"] = 80556794144838,
    ["Billy Bounce"] = 126516908191316,
    ["What U Want / Prince Egypt"] = 133751526608969,
    ["Rabbit Hole - Miku"] = 133481721436918,
    Garou = 86200585395371,
    ["Dio Pose"] = 76736978166708,
    ["Golden Freddy"] = 122463450997235,
    ["Noclip, Speed"] = 137006085779408,
    ["Static [Hatsune Miku]"] = 84534006084837,
    GOALL = 78830825254717,
    ["Lethal Dance"] = 77108921633993,
    ["Plug Walk"] = 100359724990859,
    ["At Ease"] = 76993139936388,
    Conga = 97547955535086,
    Barrel = 84511772437190,
    Helicopter = 84555218084038,
    ["Aura Farm Boat"] = 88042995626011,
    ["Prince Of Egypt"] = 134063402217274,
    ["Jersey Joe2"] = 115782117564871,
    ["Deltarune - Tenna Dance"] = 73715378215546,
    ["California Girl"] = 132074413582912,
    ["Default Dance"] = 80877772569772,
    ["Shocked meme"] = 129501229484294,
    ["Family Guy"] = 78459263478161,
    ["Car Transformation"] = 96887377943085,
    Insanity = 129843344424281,
    ["Honored One"] = 121643381580730,
    Sukuna = 91839607010745,
    Dropper = 130358790702800,
    ["Be Not Afraid"] = 70635223083942,
    Macarena = 91274761264433,
    Helicopter2 = 119431985170060,
    RONALDO = 97547486465713,
    ["Nya Anime Dance"] = 126647057611522,
    ["Do that thang"] = 113772829398170,
    ["Squat?"] = 95441477641149,
    Slickback = 103789826265487
}

local ANIMATIONS = {
    Stylish = {
        Idle = 616136790, Idle2 = 616138447, Idle3 = 886888594,
        Walk = 616146177, Run = 616140816, Jump = 616139451,
        Climb = 616133594, Fall = 616134815, Swim = 616143378, SwimIdle = 616144772,
        Weight = 9, Weight2 = 1
    },
    Zombie = {
        Idle = 616158929, Idle2 = 616160636, Idle3 = 885545458,
        Walk = 616168032, Run = 616163682, Jump = 616161997,
        Climb = 616156119, Fall = 616157476, Swim = 616165109, SwimIdle = 616166655,
        Weight = 9, Weight2 = 1
    },
    Robot = {
        Idle = 616088211, Idle2 = 616089559, Idle3 = 885531463,
        Walk = 616095330, Run = 616091570, Jump = 616090535,
        Climb = 616086039, Fall = 616087089, Swim = 616092998, SwimIdle = 616094091,
        Weight = 9, Weight2 = 1
    },
    Toy = {
        Idle = 782841498, Idle2 = 782845736, Idle3 = 980952228,
        Walk = 782843345, Run = 782842708, Jump = 782847020,
        Climb = 782843869, Fall = 782846423, Swim = 782844582, SwimIdle = 782845186,
        Weight = 9, Weight2 = 1
    },
    Cartoony = {
        Idle = 742637544, Idle2 = 742638445, Idle3 = 885477856,
        Walk = 742640026, Run = 742638842, Jump = 742637942,
        Climb = 742636889, Fall = 742637151, Swim = 742639220, SwimIdle = 742639812,
        Weight = 9, Weight2 = 1
    },
    Superhero = {
        Idle = 616111295, Idle2 = 616113536, Idle3 = 885535855,
        Walk = 616122287, Run = 616117076, Jump = 616115533,
        Climb = 616104706, Fall = 616108001, Swim = 616119360, SwimIdle = 616120861,
        Weight = 9, Weight2 = 1
    },
    Mage = {
        Idle = 707742142, Idle2 = 707855907, Idle3 = 885508740,
        Walk = 707897309, Run = 707861613, Jump = 707853694,
        Climb = 707826056, Fall = 707829716, Swim = 707876443, SwimIdle = 707894699,
        Weight = 9, Weight2 = 1
    },
    Levitation = {
        Idle = 616006778, Idle2 = 616008087, Idle3 = 886862142,
        Walk = 616013216, Run = 616010382, Jump = 616008936,
        Climb = 616003713, Fall = 616005863, Swim = 616011509, SwimIdle = 616012453,
        Weight = 9, Weight2 = 1
    },
    Vampire = {
        Idle = 1083445855, Idle2 = 1083450166, Idle3 = 1088037547,
        Walk = 1083473930, Run = 1083462077, Jump = 1083455352,
        Climb = 1083439238, Fall = 1083443587, Swim = 1083464683, SwimIdle = 1083467779,
        Weight = 9, Weight2 = 1
    },
    Elder = {
        Idle = 845397899, Idle2 = 845400520, Idle3 = 901160519,
        Walk = 845403856, Run = 845386501, Jump = 845398858,
        Climb = 845392038, Fall = 845396048, Swim = 845401742, SwimIdle = 845403127,
        Weight = 9, Weight2 = 1
    },
    Werewolf = {
        Idle = 1083195517, Idle2 = 1083214717, Idle3 = 1099492820,
        Walk = 1083178339, Run = 1083216690, Jump = 1083218792,
        Climb = 1083182000, Fall = 1083189019, Swim = 1083222527, SwimIdle = 1083225406,
        Weight = 9, Weight2 = 1
    },
    Knight = {
        Idle = 657595757, Idle2 = 657568135, Idle3 = 885499184,
        Walk = 657552124, Run = 657564596, Jump = 658409194,
        Climb = 658360781, Fall = 657600338, Swim = 657560551, SwimIdle = 657557095,
        Weight = 9, Weight2 = 1
    },
    Bold = {
        Idle = 16738333868, Idle2 = 16738334710, Idle3 = 16738335517,
        Walk = 16738340646, Run = 16738337225, Jump = 16738336650,
        Climb = 16738332169, Fall = 16738333171, Swim = 16738339158, SwimIdle = 16738339817,
        Weight = 9, Weight2 = 1
    },
    Astronaut = {
        Idle = 891621366, Idle2 = 891633237, Idle3 = 1047759695,
        Walk = 891667138, Run = 891636393, Jump = 891627522,
        Climb = 891609353, Fall = 891617961, Swim = 891639666, SwimIdle = 891663592,
        Weight = 9, Weight2 = 1
    },
    Bubbly = {
        Idle = 910004836, Idle2 = 910009958, Idle3 = 1018536639,
        Walk = 910034870, Run = 910025107, Jump = 910016857,
        Climb = 909997997, Fall = 910001910, Swim = 910028158, SwimIdle = 910030921,
        Weight = 9, Weight2 = 1
    },
    Pirate = {
        Idle = 750781874, Idle2 = 750782770, Idle3 = 885515365,
        Walk = 750785693, Run = 750783738, Jump = 750782230,
        Climb = 750779899, Fall = 750780242, Swim = 750784579, SwimIdle = 750785176,
        Weight = 9, Weight2 = 1
    },
    Rthro = {
        Idle = 2510196951, Idle2 = 2510197257, Idle3 = 3711062489,
        Walk = 2510202577, Run = 2510198475, Jump = 2510197830,
        Climb = 2510192778, Fall = 2510195892, Swim = 2510199791, SwimIdle = 2510201162,
        Weight = 9, Weight2 = 1
    },
    Ninja = {
        Idle = 656117400, Idle2 = 656118341, Idle3 = 886742569,
        Walk = 656121766, Run = 656118852, Jump = 656117878,
        Climb = 656114359, Fall = 656115606, Swim = 656119721, SwimIdle = 656121397,
        Weight = 9, Weight2 = 1
    },
    Oldschool = {
        Idle = 5319828216, Idle2 = 5319831086, Idle3 = 5392107832,
        Walk = 5319847204, Run = 5319844329, Jump = 5319841935,
        Climb = 5319816685, Fall = 5319839762, Swim = 5319850266, SwimIdle = 5319852613,
        Weight = 9, Weight2 = 1
    },
    Realistic = {
        Idle = 17172918855, Idle2 = 17173014241, Idle3 = 17173014241,
        Walk = 11600249883, Run = 11600211410, Jump = 11600210487,
        Climb = 11600205519, Fall = 11600206437, Swim = 11600212676, SwimIdle = 11600213505,
        Weight = 9, Weight2 = 1
    },
    ["No Boundaries"] = {
        Idle = 18747067405, Idle2 = 18747063918, Idle3 = 18747063918,
        Walk = 18747074203, Run = 18747070484, Jump = 18747069148,
        Climb = 18747060903, Fall = 18747062535, Swim = 18747073181, SwimIdle = 18747071682,
        Weight = 9, Weight2 = 1
    },
    ["NFL Animation"] = {
        Idle = 92080889861410, Idle2 = 74451233229259, Idle3 = 80884010501210,
        Walk = 110358958299415, Run = 117333533048078, Jump = 119846112151352,
        Climb = 134630013742019, Fall = 129773241321032, Swim = 132697394189921, SwimIdle = 79090109939093,
        Weight = 9, Weight2 = 1
    },
    ["Adidas Aura"] = {
        Idle = 110211186840347, Idle2 = 114191137265065, Idle3 = 99129837931148,
        Walk = 83842218823011, Run = 118320322718866, Jump = 109996626521204,
        Climb = 97824616490448, Fall = 95603166884636, Swim = 134530128383903, SwimIdle = 94922130551805,
        Weight = 9, Weight2 = 1
    },
    ["Adidas Sports"] = {
        Idle = 18537376492, Idle2 = 18537371272, Idle3 = 18537374150,
        Walk = 18537392113, Run = 18537384940, Jump = 18537380791,
        Climb = 18537363391, Fall = 18537367238, Swim = 18537389531, SwimIdle = 18537387180,
        Weight = 9, Weight2 = 1
    },
    ["Adidas Community "] = {
        Idle = 122257458498464, Idle2 = 102357151005774, Idle3 = 89262795687364,
        Walk = 122150855457006, Run = 82598234841035, Jump = 75290611992385,
        Climb = 88763136693023, Fall = 98600215928904, Swim = 133308483266208, SwimIdle = 109346520324160,
        Weight = 9, Weight2 = 1
    },
    ["Wickled Popular"] = {
        Idle = 118832222982049, Idle2 = 76049494037641, Idle3 = 138255200176080,
        Walk = 92072849924640, Run = 72301599441680, Jump = 104325245285198,
        Climb = 131326830509784, Fall = 121152442762481, Swim = 99384245425157, SwimIdle = 113199415118199,
        Weight = 9, Weight2 = 1
    },
    ["Catwalk Glam"] = {
        Idle = 133806214992291, Idle2 = 94970088341563, Idle3 = 87105332133518,
        Walk = 109168724482748, Run = 81024476153754, Jump = 116936326516985,
        Climb = 119377220967554, Fall = 92294537340807, Swim = 134591743181628, SwimIdle = 98854111361360,
        Weight = 9, Weight2 = 1
    },
    Princess = {
        Idle = 941003647, Idle2 = 941013098, Idle3 = 1159195712,
        Walk = 941028902, Run = 941015281, Jump = 941008832,
        Climb = 940996062, Fall = 941000007, Swim = 941018893, SwimIdle = 941025398,
        Weight = 9, Weight2 = 1
    },
    Confident = {
        Idle = 1069977950, Idle2 = 1069987858, Idle3 = 1116160740,
        Walk = 1070017263, Run = 1070001516, Jump = 1069984524,
        Climb = 1069946257, Fall = 1069973677, Swim = 1070009914, SwimIdle = 1070012133,
        Weight = 9, Weight2 = 1
    },
    Popstar = {
        Idle = 1212900985, Idle2 = 1150842221, Idle3 = 1239733474,
        Walk = 1212980338, Run = 1212980348, Jump = 1212954642,
        Climb = 1213044953, Fall = 1212900995, Swim = 1212852603, SwimIdle = 1070012133,
        Weight = 9, Weight2 = 1
    },
    Patrol = {
        Idle = 1149612882, Idle2 = 1150842221, Idle3 = 1159573567,
        Walk = 1151231493, Run = 1150967949, Jump = 1150944216,
        Climb = 1148811837, Fall = 1148863382, Swim = 1151204998, SwimIdle = 1151221899,
        Weight = 9, Weight2 = 1
    },
    Sneaky = {
        Idle = 1132473842, Idle2 = 1132477671, Idle3 = "None",
        Walk = 1132510133, Run = 1132494274, Jump = 1132489853,
        Climb = 1132461372, Fall = 1132469004, Swim = 1132500520, SwimIdle = 1132506407,
        Weight = 9, Weight2 = 1
    },
    Cowboy = {
        Idle = 1014390418, Idle2 = 1014398616, Idle3 = 1159487651,
        Walk = 1014421541, Run = 1014401683, Jump = 1014394726,
        Climb = 1014380606, Fall = 1014384571, Swim = 1014406523, SwimIdle = 1014411816,
        Weight = 9, Weight2 = 1
    },
    Ghost = {
        Idle = 616006778, Idle2 = 616008087, Idle3 = 616008087,
        Walk = 616013216, Run = 616013216, Jump = 616008936,
        Climb = 0, Fall = 616005863, Swim = 616011509, SwimIdle = 616012453,
        Weight = 9, Weight2 = 1
    },
    ["Ghost 2"] = {
        Idle = 1151221899, Idle2 = 1151221899, Idle3 = "None",
        Walk = 1151221899, Run = 1151221899, Jump = 1151221899,
        Climb = 0, Fall = 1151221899, Swim = 16738339158, SwimIdle = 1151221899,
        Weight = 9, Weight2 = 1
    },
    ["Mr. Toilet"] = {
        Idle = 4417977954, Idle2 = 4417978624, Idle3 = 4441285342,
        Walk = 2510202577, Run = 4417979645, Jump = 2510197830,
        Climb = 2510192778, Fall = 2510195892, Swim = 2510199791, SwimIdle = 2510201162,
        Weight = 9, Weight2 = 1
    },
    Udzal = {
        Idle = 3303162274, Idle2 = 3303162549, Idle3 = 3710161342,
        Walk = 3303162967, Run = 3236836670, Jump = 2510197830,
        Climb = 2510192778, Fall = 2510195892, Swim = 2510199791, SwimIdle = 2510191162,
        Weight = 9, Weight2 = 1
    },
    ["Oinan Thickhoof"] = {
        Idle = 657595757, Idle2 = 657568135, Idle3 = 885499184,
        Walk = 2510202577, Run = 3236836670, Jump = 2510197830,
        Climb = 2510192778, Fall = 2510195892, Swim = 2510199791, SwimIdle = 2510201162,
        Weight = 9, Weight2 = 1
    },
    Borock = {
        Idle = 3293641938, Idle2 = 3293642554, Idle3 = 3710131919,
        Walk = 2510202577, Run = 3236836670, Jump = 2510197830,
        Climb = 2510192778, Fall = 2510195892, Swim = 2510199791, SwimIdle = 2510201162,
        Weight = 9, Weight2 = 1
    },
    ["Blocky Mech"] = {
        Idle = 4417977954, Idle2 = 4417978624, Idle3 = 4441285342,
        Walk = 2510202577, Run = 4417979645, Jump = 2510197830,
        Climb = 2510192778, Fall = 2510195892, Swim = 2510199791, SwimIdle = 2510201162,
        Weight = 9, Weight2 = 1
    },
    ["Stylized Female"] = {
        Idle = 4708191566, Idle2 = 4708192150, Idle3 = 121221,
        Walk = 4708193840, Run = 4708192705, Jump = 4708188025,
        Climb = 4708184253, Fall = 4708186162, Swim = 4708189360, SwimIdle = 4708190607,
        Weight = 9, Weight2 = 1
    },
    R15 = {
        Idle = 4211217646, Idle2 = 4211218409, Idle3 = "None",
        Walk = 4211223236, Run = 4211220381, Jump = 4211219390,
        Climb = 4211214992, Fall = 4211216152, Swim = 4211221314, SwimIdle = 4374694239,
        Weight = 9, Weight2 = 1
    },
    Mocap = {
        Idle = 913367814, Idle2 = 913373430, Idle3 = "None",
        Walk = 913402848, Run = 913376220, Jump = 913370268,
        Climb = 913362637, Fall = 913365531, Swim = 913384386, SwimIdle = 913389285,
        Weight = 9, Weight2 = 1
    },
    ['Wicked "Dancing Through Life"'] = {
        Idle = 92849173543269, Idle2 = 132238900951109, Idle3 = 87867222929430,
        Walk = 73718308412641, Run = 135515454877967, Jump = 78508480717326,
        Climb = 129447497744818, Fall = 78147885297412, Swim = 110657013921774, SwimIdle = 129183123083281,
        Weight = 9, Weight2 = 1
    },
    Unboxed = {
        Idle = 98281136301627, Idle2 = 138183121662404, Idle3 = 133117300343405,
        Walk = 90478085024465, Run = 134824450619865, Jump = 121454505477205,
        Climb = 121145883950231, Fall = 94788218468396, Swim = 105962919001086, SwimIdle = 129126268464847,
        Weight = 9, Weight2 = 1
    }
}

local SKYBOXES = {
    { name = "Snow Skybox", id = 4604073339 },
    { name = "Realistic Space", id = 136402262 },
    { name = "Purple Nebula", id = 83555979203508 },
    { name = "Blue Nebula", id = 130093177270069 },
    { name = "SpongeBob Sky", id = 114523453023009 },
    { name = "Night Sky Vibe", id = 78613024128163 },
    { name = "Geoz Skybox", id = 97573261671957 },
    { name = "Asteroid Space", id = 295604372 }
}

local AURAS = {
    { name = "Midnight Blues", id = "12002206611" },
    { name = "Rainbow Effect", id = "8509695714" },
    { name = "Red Shield", id = "14598330167" },
    { name = "Crimson King", id = "11955208820" },
    { name = "Daemon of Cards", id = "10373359918" },
    { name = "Angel Wings", id = "97658130917593" },
    { name = "Starlight", id = "134645216613107" },
    { name = "Heavenly", id = "139300897520961" },
    { name = "Ribbon", id = "132069507632161" },
    { name = "Sakura", id = "81755778619404" },
    { name = "Wind", id = "80694081850877" },
    { name = "Flow", id = "119913533725648" },
    { name = "Star", id = "73754563740680" }
}

local emoteNames = {}
for name in pairs(EMOTE_LIST) do
    table.insert(emoteNames, name)
end
table.sort(emoteNames, function(a, b)
    return a:lower() < b:lower()
end)

local animationNames = {}
for name in pairs(ANIMATIONS) do
    table.insert(animationNames, name)
end
table.sort(animationNames, function(a, b)
    return a:lower() < b:lower()
end)

-- =============================================================================
-- NOTIFICATIONS
-- =============================================================================
local notifyHook = nil

local function notify(text)
    if notifyHook then
        pcall(notifyHook, text)
    end
    print("[Nursultan] " .. tostring(text))
end

-- =============================================================================
-- ESP
-- =============================================================================
local ESP_COLOR = Color3.fromRGB(255, 60, 60)

local espHolder = nil
local espHighlightConn = nil
local espGlobalConns = {}
local espPlayerConns = {}
local espOriginalDistance = {}

local espBoxTemplate = Instance.new("BoxHandleAdornment")
espBoxTemplate.Name = "nursultanBox"
espBoxTemplate.Size = Vector3.new(1, 2, 1)
espBoxTemplate.Color3 = ESP_COLOR
espBoxTemplate.Transparency = 0.7
espBoxTemplate.ZIndex = 0
espBoxTemplate.AlwaysOnTop = false
espBoxTemplate.Visible = false

local espNameTemplate = Instance.new("BillboardGui")
espNameTemplate.Name = "nursultanName"
espNameTemplate.Enabled = false
espNameTemplate.Size = UDim2.new(0, 200, 0, 50)
espNameTemplate.AlwaysOnTop = true
espNameTemplate.StudsOffset = Vector3.new(0, 1.8, 0)

local espTagTemplate = Instance.new("TextLabel")
espTagTemplate.Name = "Tag"
espTagTemplate.BackgroundTransparency = 1
espTagTemplate.Position = UDim2.new(0, -50, 0, 0)
espTagTemplate.Size = UDim2.new(0, 300, 0, 20)
espTagTemplate.TextSize = 15
espTagTemplate.TextColor3 = ESP_COLOR
espTagTemplate.TextStrokeColor3 = Color3.new(0, 0, 0)
espTagTemplate.TextStrokeTransparency = 0.4
espTagTemplate.Text = ""
espTagTemplate.Font = Enum.Font.SourceSansBold
espTagTemplate.Parent = espNameTemplate

local function espLoadCharacter(plr)
    if not S.esp or not espHolder then return end
    local char = plr.Character
    if not char then return end

    local head = char:FindFirstChild("Head")
    if not head then
        head = char:WaitForChild("Head", 5)
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not head or not hum then return end

    local holder = espHolder:FindFirstChild(plr.Name)
    if not holder then
        holder = Instance.new("Folder")
        holder.Name = plr.Name
        holder.Parent = espHolder
    end
    holder:ClearAllChildren()

    local box = espBoxTemplate:Clone()
    box.Name = plr.Name .. "Box"
    box.Adornee = char
    box.Color3 = ESP_COLOR
    box.Visible = true
    box.Parent = holder

    local tag = espNameTemplate:Clone()
    tag.Name = plr.Name .. "NameTag"
    tag.Enabled = true
    tag.Adornee = head
    tag.Tag.Text = plr.Name
    tag.Tag.TextColor3 = ESP_COLOR
    tag.Parent = holder

    if espOriginalDistance[hum] == nil then
        espOriginalDistance[hum] = hum.DisplayDistanceType
    end
    pcall(function()
        hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    end)
end

local function espUnloadCharacter(plr)
    local holder = espHolder and espHolder:FindFirstChild(plr.Name)
    if holder then
        holder:ClearAllChildren()
    end

    local char = plr.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum and espOriginalDistance[hum] ~= nil then
        local original = espOriginalDistance[hum]
        espOriginalDistance[hum] = nil
        pcall(function()
            hum.DisplayDistanceType = original
        end)
    end
end

local function espApplyHighlight(plr)
    local char = plr.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

    local highlight = char:FindFirstChild("nursultanHighlight")
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "nursultanHighlight"
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Adornee = char
        highlight.Parent = char
    end
    highlight.FillColor = ESP_COLOR
    highlight.OutlineColor = ESP_COLOR
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
end

local function espLoadPlayer(plr)
    if not S.esp or not espHolder or plr == LocalPlayer then return end

    if not espHolder:FindFirstChild(plr.Name) then
        local folder = Instance.new("Folder")
        folder.Name = plr.Name
        folder.Parent = espHolder
    end

    task.spawn(function()
        pcall(espLoadCharacter, plr)
    end)

    if espPlayerConns[plr] then return end
    local conns = {}
    espPlayerConns[plr] = conns

    table.insert(conns, plr.CharacterAdded:Connect(function()
        task.wait(0.15)
        pcall(espLoadCharacter, plr)
    end))
    table.insert(conns, plr.CharacterRemoving:Connect(function()
        pcall(espUnloadCharacter, plr)
    end))
end

local function espUnloadPlayer(plr)
    local conns = espPlayerConns[plr]
    if conns then
        for _, conn in ipairs(conns) do
            pcall(function()
                conn:Disconnect()
            end)
        end
        espPlayerConns[plr] = nil
    end

    if espHolder then
        local folder = espHolder:FindFirstChild(plr.Name)
        if folder then
            folder:Destroy()
        end
    end

    local char = plr.Character
    if char then
        local highlight = char:FindFirstChild("nursultanHighlight")
        if highlight then
            highlight:Destroy()
        end
    end

    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum and espOriginalDistance[hum] ~= nil then
        local original = espOriginalDistance[hum]
        espOriginalDistance[hum] = nil
        pcall(function()
            hum.DisplayDistanceType = original
        end)
    end
end

local function espDisable()
    S.esp = false

    if espHighlightConn then
        espHighlightConn:Disconnect()
        espHighlightConn = nil
    end

    for _, conn in pairs(espGlobalConns) do
        pcall(function()
            conn:Disconnect()
        end)
    end
    espGlobalConns = {}

    for plr in pairs(espPlayerConns) do
        espUnloadPlayer(plr)
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        local char = plr.Character
        if char then
            local highlight = char:FindFirstChild("nursultanHighlight")
            if highlight then
                highlight:Destroy()
            end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and espOriginalDistance[hum] ~= nil then
                local original = espOriginalDistance[hum]
                espOriginalDistance[hum] = nil
                pcall(function()
                    hum.DisplayDistanceType = original
                end)
            end
        end
    end

    if espHolder then
        espHolder:Destroy()
        espHolder = nil
    end
end

local function espEnable()
    if S.esp then return end
    S.esp = true

    espHolder = Instance.new("Folder")
    espHolder.Name = "nursultanESP"
    espHolder.Parent = getGuiParent()

    for _, plr in ipairs(Players:GetPlayers()) do
        pcall(espLoadPlayer, plr)
    end

    espGlobalConns.PlayerAdded = Players.PlayerAdded:Connect(function(plr)
        pcall(espLoadPlayer, plr)
    end)
    espGlobalConns.PlayerRemoving = Players.PlayerRemoving:Connect(function(plr)
        pcall(espUnloadPlayer, plr)
    end)

    local timer = 0
    espHighlightConn = RunService.Heartbeat:Connect(function(dt)
        if not S.esp then return end
        timer += dt
        if timer < 0.1 then return end
        timer = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                pcall(espApplyHighlight, plr)
            end
        end
    end)
end

-- =============================================================================
-- FOV CIRCLE + AIMBOT
-- =============================================================================
local fovCircle

if Drawing then
    local ok, circle = pcall(function()
        return Drawing.new("Circle")
    end)
    if ok and circle then
        fovCircle = circle
        fovCircle.Thickness = 1.5
        fovCircle.NumSides = 64
        fovCircle.Filled = false
        fovCircle.Transparency = 1
        fovCircle.Visible = false
    end
end

RunService.RenderStepped:Connect(function()
    if fovCircle then
        local camera = Workspace.CurrentCamera
        local show = S.showFov and camera ~= nil
        fovCircle.Visible = show
        if show then
            fovCircle.Position = camera.ViewportSize / 2
            fovCircle.Radius = S.fov
            fovCircle.Color = S.fovColor
        end
    end

    if S.aimbot and aiming then
        local camera = Workspace.CurrentCamera
        local target = getTarget()
        if camera and target then
            local alpha = math.clamp(S.aimSpeed / 100, 0.01, 1)
            if (target.Position - camera.CFrame.Position).Magnitude > 0.05 then
                local goal = CFrame.lookAt(camera.CFrame.Position, target.Position)
                if alpha >= 0.99 then
                    camera.CFrame = goal
                else
                    camera.CFrame = camera.CFrame:Lerp(goal, alpha)
                end
            end
        end
    end
end)

-- =============================================================================
-- TRIGGERBOT
-- =============================================================================
local triggerLastShot = 0

local function triggerFindGun()
    local character = LocalPlayer.Character
    if not character then return nil end

    for _, obj in ipairs(character:GetDescendants()) do
        if obj:IsA("Tool") then
            return obj
        end
    end

    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                return tool
            end
        end
    end

    return nil
end

local function triggerGetAimPoint(camera)
    if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
        return camera.ViewportSize / 2
    end

    local inset = GuiService:GetGuiInset()
    return UserInputService:GetMouseLocation() - Vector2.new(0, inset.Y)
end

local function triggerIsPlayerOnCursor()
    local camera = Workspace.CurrentCamera
    if not camera then return false end

    local aimPoint = triggerGetAimPoint(camera)
    local ray = camera:ViewportPointToRay(aimPoint.X, aimPoint.Y)

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = LocalPlayer.Character and { LocalPlayer.Character } or {}

    local result = Workspace:Raycast(ray.Origin, ray.Direction * 3000, params)
    if not result or not result.Instance then
        return false
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 and result.Instance:IsDescendantOf(player.Character) then
                return true
            end
        end
    end

    return false
end

local function triggerAutoShoot()
    if not VirtualInputManager then return end
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    end)
end

RunService.Heartbeat:Connect(function()
    if not S.trigger then return end

    local now = os.clock()
    if now - triggerLastShot < 0.05 then return end

    if triggerIsPlayerOnCursor() then
        triggerAutoShoot()
        triggerLastShot = now

        local tool = triggerFindGun()
        if tool and tool:IsA("Tool") then
            pcall(function()
                tool:Activate()
            end)
        end
    end
end)

-- =============================================================================
-- HITBOX
-- =============================================================================
local originalSizes = setmetatable({}, { __mode = "k" })

local function restoreHitboxes()
    for part, size in pairs(originalSizes) do
        if part and part.Parent then
            part.Size = size
        end
    end
    table.clear(originalSizes)
end

RunService.Heartbeat:Connect(function()
    if not S.hitbox then
        if next(originalSizes) then
            restoreHitboxes()
        end
        return
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and isAlive(plr) then
            local char = plr.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                if not originalSizes[hrp] then
                    originalSizes[hrp] = hrp.Size
                end
                hrp.Size = Vector3.new(S.hitboxSize, S.hitboxSize, S.hitboxSize)
            end
        end
    end
end)

-- =============================================================================
-- SCREEN STRETCH
-- =============================================================================
local SCREEN_STRETCH_BIND = "NursultanScreenStretch"

pcall(function()
    RunService:UnbindFromRenderStep(SCREEN_STRETCH_BIND)
end)

RunService:BindToRenderStep(SCREEN_STRETCH_BIND, Enum.RenderPriority.Camera.Value + 1, function()
    if not S.screenStretch then return end

    local camera = Workspace.CurrentCamera
    if not camera then return end

    local power = math.clamp(S.screenStretchPower or 1, 1, 2)
    if power <= 1.001 then return end

    local cf = camera.CFrame
    camera.CFrame = CFrame.fromMatrix(cf.Position, cf.XVector, cf.YVector / power, cf.ZVector)
end)

-- =============================================================================
-- NOCLIP
-- =============================================================================
local noclipConn = nil

local function setNoclip(state)
    S.noclip = state
    if noclipConn then
        noclipConn:Disconnect()
        noclipConn = nil
    end
    if state then
        noclipConn = RunService.Stepped:Connect(function()
            local character = LocalPlayer.Character
            if character then
                for _, descendant in ipairs(character:GetDescendants()) do
                    if descendant:IsA("BasePart") then
                        descendant.CanCollide = false
                    end
                end
            end
        end)
    end
end

-- =============================================================================
-- INVISIBILITY
-- =============================================================================
local INVISIBILITY_POSITION = Vector3.new(-25.95, 84, 3537.55)

local invisSound = Instance.new("Sound")
invisSound.Name = "nursultanInvisSound"
invisSound.SoundId = "rbxassetid://942127495"
invisSound.Volume = 0.5
invisSound.Parent = SoundService

local function setCharacterTransparency(character, transparency)
    for _, descendant in ipairs(character:GetDescendants()) do
        if descendant:IsA("BasePart") or descendant:IsA("Decal") then
            descendant.Transparency = transparency
        end
    end
end

local function removeInvisChair()
    local chair = Workspace:FindFirstChild("nursultanInvisChair")
    if chair then
        chair:Destroy()
    end
end

local function setInvisible(state)
    S.invis = state
    local character = LocalPlayer.Character
    if not character then return end

    pcall(function() invisSound:Play() end)
    removeInvisChair()

    if state then
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end

        local savedPosition = rootPart.CFrame

        pcall(function() character:MoveTo(INVISIBILITY_POSITION) end)
        task.wait(0.15)

        local seat = Instance.new("Seat")
        seat.Name = "nursultanInvisChair"
        seat.Anchored = false
        seat.CanCollide = false
        seat.Transparency = 1
        seat.Position = INVISIBILITY_POSITION
        seat.Parent = Workspace

        local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
        if not torso then
            seat:Destroy()
            return
        end

        local weld = Instance.new("Weld")
        weld.Part0 = seat
        weld.Part1 = torso
        weld.Parent = seat

        task.wait()
        seat.CFrame = savedPosition

        setCharacterTransparency(character, 0.5)
    else
        setCharacterTransparency(character, 0)
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    removeInvisChair()
    S.invis = false
end)

-- =============================================================================
-- BUNNY HOP
-- =============================================================================
local bunnyHopConnections = {}
local bunnyHopBodyVelocity = nil
local bunnyHopHumanoid = nil
local bunnyHopRootPart = nil
local bunnyHopCanJump = 10
local bunnyHopBoosted = false
local bunnyHopOriginalUseJumpPower = nil
local bunnyHopOriginalJumpPower = nil
local bunnyHopOriginalJumpHeight = nil

local bunnyHopSoundIds = {
    "rbxassetid://7338942417",
    "rbxassetid://7338942345",
    "rbxassetid://7338942259",
    "rbxassetid://7338942180"
}
local bunnyHopSounds = {}
for _, id in ipairs(bunnyHopSoundIds) do
    local sound = Instance.new("Sound")
    sound.SoundId = id
    sound.Volume = 2
    sound.Parent = Workspace
    table.insert(bunnyHopSounds, sound)
end

local function stopBunnyHop()
    for _, connection in ipairs(bunnyHopConnections) do
        connection:Disconnect()
    end
    bunnyHopConnections = {}

    if bunnyHopBodyVelocity then
        bunnyHopBodyVelocity:Destroy()
        bunnyHopBodyVelocity = nil
    end

    if bunnyHopHumanoid then
        if bunnyHopOriginalUseJumpPower ~= nil then
            bunnyHopHumanoid.UseJumpPower = bunnyHopOriginalUseJumpPower
        end
        if bunnyHopOriginalJumpPower ~= nil then
            bunnyHopHumanoid.JumpPower = bunnyHopOriginalJumpPower
        end
        if bunnyHopOriginalJumpHeight ~= nil then
            bunnyHopHumanoid.JumpHeight = bunnyHopOriginalJumpHeight
        end
    end

    bunnyHopHumanoid = nil
    bunnyHopRootPart = nil
    bunnyHopCanJump = 10
    bunnyHopBoosted = false
end

local function startBunnyHop()
    stopBunnyHop()

    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    local rootPart = character:WaitForChild("HumanoidRootPart")

    if not S.bunnyhop then return end

    bunnyHopHumanoid = humanoid
    bunnyHopRootPart = rootPart
    bunnyHopCanJump = 10
    bunnyHopBoosted = false
    bunnyHopOriginalUseJumpPower = humanoid.UseJumpPower
    bunnyHopOriginalJumpPower = humanoid.JumpPower
    bunnyHopOriginalJumpHeight = humanoid.JumpHeight

    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Parent = rootPart
    bunnyHopBodyVelocity = bodyVelocity

    local function update()
        if not S.bunnyhop or not rootPart.Parent then return end

        local state = humanoid:GetState()
        if state ~= Enum.HumanoidStateType.Freefall then
            bodyVelocity.MaxForce = Vector3.new(0, 0, 0)
            bodyVelocity.Velocity = rootPart.Velocity
            bunnyHopBoosted = false
            return
        end

        bodyVelocity.MaxForce = Vector3.new(5000, 0, 5000)
        if not bunnyHopBoosted then
            bodyVelocity.Velocity = bodyVelocity.Velocity * 1.25
            bunnyHopBoosted = true
        end
        bodyVelocity.Velocity = bodyVelocity.Velocity + humanoid.MoveDirection * 1
    end

    table.insert(bunnyHopConnections, RunService.RenderStepped:Connect(function()
        update()
        bunnyHopCanJump = math.clamp(bunnyHopCanJump - 1, 0, 10)
    end))

    humanoid.UseJumpPower = true

    table.insert(bunnyHopConnections, UserInputService.JumpRequest:Connect(function()
        if bunnyHopCanJump == 0 then
            humanoid.JumpPower = 40
        else
            humanoid.JumpPower = 0
        end
        bunnyHopCanJump = 10
    end))

    table.insert(bunnyHopConnections, humanoid.Jumping:Connect(function()
        local sound = bunnyHopSounds[math.random(1, #bunnyHopSounds)]
        if sound then
            sound:Play()
        end
    end))

    table.insert(bunnyHopConnections, humanoid.Died:Connect(function()
        stopBunnyHop()
    end))

    table.insert(bunnyHopConnections, RunService.RenderStepped:Connect(function()
        if bunnyHopCanJump == 10 then
            humanoid.JumpPower = 40
        end
    end))
end

LocalPlayer.CharacterAdded:Connect(function()
    if S.bunnyhop then
        task.spawn(startBunnyHop)
    end
end)

-- =============================================================================
-- TRAIL
-- =============================================================================
local trailObj, trailAtt0, trailAtt1
local trailDirty = true

local function destroyTrail()
    if trailObj then trailObj:Destroy(); trailObj = nil end
    if trailAtt0 then trailAtt0:Destroy(); trailAtt0 = nil end
    if trailAtt1 then trailAtt1:Destroy(); trailAtt1 = nil end
end

local function createTrail(character)
    destroyTrail()
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    trailAtt0 = Instance.new("Attachment", hrp)
    trailAtt0.Position = Vector3.new(0, 1, 0)
    trailAtt1 = Instance.new("Attachment", hrp)
    trailAtt1.Position = Vector3.new(0, -1, 0)
    trailObj = Instance.new("Trail")
    trailObj.Attachment0 = trailAtt0
    trailObj.Attachment1 = trailAtt1
    trailObj.Lifetime = 0.8
    trailObj.LightEmission = 0.5
    trailObj.MinLength = 0.05
    trailObj.Parent = hrp
    trailDirty = true
end

local function updateTrailAppearance()
    if not trailObj then return end
    trailDirty = false

    if S.trailStyle == "Solid" then
        trailObj.Color = ColorSequence.new(S.trailColor)
        trailObj.Transparency = NumberSequence.new(0, 0.8)
    elseif S.trailStyle == "Fade" then
        trailObj.Color = ColorSequence.new(S.trailColor)
        trailObj.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.5, 0.5),
            NumberSequenceKeypoint.new(1, 1)
        })
    elseif S.trailStyle == "Rainbow" then
        trailObj.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 165, 0)),
            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(75, 0, 130)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(148, 0, 211))
        })
        trailObj.Transparency = NumberSequence.new(0, 0.6)
    elseif S.trailStyle == "Dotted" then
        trailObj.Color = ColorSequence.new(S.trailColor)
        trailObj.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.1, 1),
            NumberSequenceKeypoint.new(0.2, 0),
            NumberSequenceKeypoint.new(0.3, 1),
            NumberSequenceKeypoint.new(0.4, 0),
            NumberSequenceKeypoint.new(0.5, 1),
            NumberSequenceKeypoint.new(0.6, 0),
            NumberSequenceKeypoint.new(0.7, 1),
            NumberSequenceKeypoint.new(0.8, 0),
            NumberSequenceKeypoint.new(0.9, 1),
            NumberSequenceKeypoint.new(1, 0)
        })
    end
end

RunService.RenderStepped:Connect(function()
    local character = LocalPlayer.Character
    if not character then return end
    if S.trail then
        if not trailObj or not trailObj.Parent then
            createTrail(character)
        end
        if trailDirty then
            updateTrailAppearance()
        end
        if trailObj then
            trailObj.Enabled = true
        end
    elseif trailObj then
        trailObj.Enabled = false
    end
end)

-- =============================================================================
-- MAGIC AURA
-- =============================================================================
local magicAuraParts = {}
local MAGIC_AURA_COLORS = {
    Color3.fromRGB(170, 90, 255),
    Color3.fromRGB(255, 90, 130),
    Color3.fromRGB(90, 255, 130),
    Color3.fromRGB(255, 255, 90),
    Color3.fromRGB(255, 130, 255),
    Color3.fromRGB(130, 255, 255)
}

RunService.RenderStepped:Connect(function()
    local character = LocalPlayer.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if S.magicAura then
        while #magicAuraParts < 6 do
            local part = Instance.new("Part")
            part.Name = "nursultanAuraSphere"
            part.Anchored = true
            part.CanCollide = false
            part.Material = Enum.Material.Neon
            part.Shape = Enum.PartType.Ball
            part.Size = Vector3.new(0.6, 0.6, 0.6)
            part.Transparency = 0.3
            part.Parent = Workspace
            table.insert(magicAuraParts, part)
        end

        local now = tick()
        for i, part in ipairs(magicAuraParts) do
            local offset = (i - 1) * (math.pi * 2 / 6)
            local y = math.sin(now * 2 + offset)
            local angle = now * 1.5 + offset
            part.CFrame = CFrame.new(hrp.Position + Vector3.new(math.cos(angle) * 3, y, math.sin(angle) * 3))
            part.Color = MAGIC_AURA_COLORS[i] or Color3.fromRGB(170, 90, 255)
            part.Transparency = 0.3
        end
    else
        for _, part in ipairs(magicAuraParts) do
            pcall(function()
                part:Destroy()
            end)
        end
        magicAuraParts = {}
    end
end)

-- =============================================================================
-- RTX SHADER
-- =============================================================================
local rtxApplied = false
local rtxSaved = {}
local rtxAddedFx = {}
local rtxSavedChildren = {}
local rtxVignetteGui = nil

local function enableRTX()
    if rtxApplied then return end
    rtxApplied = true
    S.rtx = true

    local props = {
        "Ambient", "Brightness", "ColorShift_Bottom", "ColorShift_Top",
        "EnvironmentDiffuseScale", "EnvironmentSpecularScale", "GlobalShadows",
        "OutdoorAmbient", "ShadowSoftness", "ClockTime", "GeographicLatitude",
        "ExposureCompensation"
    }
    for _, prop in ipairs(props) do
        pcall(function()
            rtxSaved[prop] = Lighting[prop]
        end)
    end

    rtxSavedChildren = {}
    for _, child in ipairs(Lighting:GetChildren()) do
        if child:IsA("PostEffect") or child:IsA("Sky") or child:IsA("Atmosphere") then
            child.Parent = nil
            table.insert(rtxSavedChildren, child)
        end
    end

    local bloom = Instance.new("BloomEffect")
    bloom.Intensity = 0.35
    bloom.Size = 20
    bloom.Threshold = 0.85

    local cc = Instance.new("ColorCorrectionEffect")
    cc.Brightness = 0.05
    cc.Contrast = 0.25
    cc.Saturation = 0.15
    cc.TintColor = Color3.fromRGB(255, 245, 230)

    local sunRays = Instance.new("SunRaysEffect")
    sunRays.Intensity = 0.12
    sunRays.Spread = 0.8

    local sky = Instance.new("Sky")
    sky.SkyboxBk = "http://www.roblox.com/asset/?id=151165214"
    sky.SkyboxDn = "http://www.roblox.com/asset/?id=151165197"
    sky.SkyboxFt = "http://www.roblox.com/asset/?id=151165224"
    sky.SkyboxLf = "http://www.roblox.com/asset/?id=151165191"
    sky.SkyboxRt = "http://www.roblox.com/asset/?id=151165206"
    sky.SkyboxUp = "http://www.roblox.com/asset/?id=151165227"
    sky.SunAngularSize = 11

    local atmosphere = Instance.new("Atmosphere")
    atmosphere.Density = 0.3
    atmosphere.Offset = 0.25
    atmosphere.Color = Color3.fromRGB(199, 175, 166)
    atmosphere.Decay = Color3.fromRGB(44, 39, 33)
    atmosphere.Glare = 0.35
    atmosphere.Haze = 1.2

    rtxAddedFx = { bloom, cc, sunRays, sky, atmosphere }
    for _, fx in ipairs(rtxAddedFx) do
        fx.Parent = Lighting
    end

    pcall(function()
        Lighting.Technology = Enum.Technology.Future
    end)
    Lighting.Ambient = Color3.fromRGB(70, 70, 70)
    Lighting.Brightness = 2
    Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
    Lighting.ColorShift_Top = Color3.fromRGB(0, 0, 0)
    Lighting.EnvironmentDiffuseScale = 1
    Lighting.EnvironmentSpecularScale = 1
    Lighting.GlobalShadows = true
    Lighting.OutdoorAmbient = Color3.fromRGB(100, 100, 100)
    Lighting.ShadowSoftness = 0.15
    Lighting.ClockTime = 14
    Lighting.GeographicLatitude = 45
    Lighting.ExposureCompensation = 0.1

    rtxVignetteGui = Instance.new("ScreenGui")
    rtxVignetteGui.Name = "nursultanVignette"
    rtxVignetteGui.IgnoreGuiInset = true
    rtxVignetteGui.ResetOnSpawn = false
    rtxVignetteGui.Parent = getGuiParent()

    local image = Instance.new("ImageLabel", rtxVignetteGui)
    image.AnchorPoint = Vector2.new(0.5, 1)
    image.Position = UDim2.new(0.5, 0, 1, 0)
    image.Size = UDim2.new(1, 0, 1.05, 0)
    image.BackgroundTransparency = 1
    image.Image = "rbxassetid://4576475446"
    image.ImageTransparency = 0.35
    image.ZIndex = 10
end

local function disableRTX()
    if not rtxApplied then return end
    rtxApplied = false
    S.rtx = false

    for _, fx in ipairs(rtxAddedFx) do
        pcall(function()
            fx:Destroy()
        end)
    end
    rtxAddedFx = {}

    for _, child in ipairs(rtxSavedChildren) do
        pcall(function()
            child.Parent = Lighting
        end)
    end
    rtxSavedChildren = {}

    for prop, value in pairs(rtxSaved) do
        pcall(function()
            Lighting[prop] = value
        end)
    end
    rtxSaved = {}

    if rtxVignetteGui then
        pcall(function()
            rtxVignetteGui:Destroy()
        end)
        rtxVignetteGui = nil
    end
end

-- =============================================================================
-- TIME LOCK
-- =============================================================================
local timeLockModes = { Dawn = 6, Day = 12, Sunset = 18, Night = 21, Midnight = 0 }
local timeLockTimer = 0

RunService.Heartbeat:Connect(function(dt)
    if S.timeMode == "Off" then return end
    timeLockTimer += dt
    if timeLockTimer < 0.5 then return end
    timeLockTimer = 0

    local value = timeLockModes[S.timeMode]
    if S.timeMode == "Custom" then
        value = S.timeValue
    end
    if type(value) == "number" then
        pcall(function()
            Lighting.ClockTime = value
        end)
    end
end)

-- =============================================================================
-- WEATHER
-- =============================================================================
local weatherPart, weatherEmitter
local origFog = {}
local fogActive = false

local function clearWeatherParticles()
    if weatherEmitter then
        pcall(function() weatherEmitter:Destroy() end)
        weatherEmitter = nil
    end
    if weatherPart then
        pcall(function() weatherPart:Destroy() end)
        weatherPart = nil
    end
end

local function setFog(state)
    if state and not fogActive then
        origFog.FogEnd = Lighting.FogEnd
        origFog.FogStart = Lighting.FogStart
        origFog.FogColor = Lighting.FogColor
        fogActive = true
        pcall(function()
            Lighting.FogStart = 0
            Lighting.FogEnd = 80
            Lighting.FogColor = Color3.fromRGB(180, 180, 190)
        end)
    elseif not state and fogActive then
        fogActive = false
        pcall(function()
            Lighting.FogStart = origFog.FogStart or 0
            Lighting.FogEnd = origFog.FogEnd or 100000
            Lighting.FogColor = origFog.FogColor or Color3.fromRGB(192, 192, 192)
        end)
    end
end

local function createWeatherParticles(kind)
    clearWeatherParticles()
    weatherPart = Instance.new("Part")
    weatherPart.Name = "nursultanWeather"
    weatherPart.Size = Vector3.new(0.1, 0.1, 0.1)
    weatherPart.Anchored = true
    weatherPart.CanCollide = false
    weatherPart.Transparency = 1
    weatherPart.Parent = Workspace

    weatherEmitter = Instance.new("ParticleEmitter", weatherPart)
    weatherEmitter.LockedToPart = false
    weatherEmitter.Speed = NumberRange.new(0)

    if kind == "Rain" then
        weatherEmitter.Texture = "rbxassetid://241876428"
        weatherEmitter.Lifetime = NumberRange.new(0.6, 0.9)
        weatherEmitter.Rate = 600
        weatherEmitter.Speed = NumberRange.new(120, 140)
        weatherEmitter.SpreadAngle = Vector2.new(2, 2)
        weatherEmitter.Acceleration = Vector3.new(0, -10, 0)
        weatherEmitter.Size = NumberSequence.new(0.4)
        weatherEmitter.Transparency = NumberSequence.new(0.3)
        weatherEmitter.Color = ColorSequence.new(Color3.fromRGB(180, 200, 240))
        weatherEmitter.Orientation = Enum.ParticleOrientation.VelocityParallel
    elseif kind == "Snow" then
        weatherEmitter.Texture = "rbxassetid://241876428"
        weatherEmitter.Lifetime = NumberRange.new(3, 5)
        weatherEmitter.Rate = 250
        weatherEmitter.Speed = NumberRange.new(8, 14)
        weatherEmitter.SpreadAngle = Vector2.new(20, 20)
        weatherEmitter.Acceleration = Vector3.new(0, -2, 0)
        weatherEmitter.RotSpeed = NumberRange.new(-30, 30)
        weatherEmitter.Size = NumberSequence.new(0.3)
        weatherEmitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.2),
            NumberSequenceKeypoint.new(1, 0.6)
        })
        weatherEmitter.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
    end

    weatherEmitter.EmissionDirection = Enum.NormalId.Bottom
end

local function applyWeather()
    if S.weather == "Off" then
        clearWeatherParticles()
        setFog(false)
    elseif S.weather == "Fog" then
        clearWeatherParticles()
        setFog(true)
    else
        setFog(false)
        createWeatherParticles(S.weather)
    end
end

RunService.RenderStepped:Connect(function()
    if weatherPart and weatherPart.Parent then
        local camera = Workspace.CurrentCamera
        if camera then
            local pos = camera.CFrame.Position
            weatherPart.CFrame = CFrame.new(pos.X, pos.Y + 60, pos.Z)
        end
    end
end)

-- =============================================================================
-- SKYBOX
-- =============================================================================
local function loadSkybox(id, name)
    task.spawn(function()
        local ok, objects = pcall(function()
            return game:GetObjects("rbxassetid://" .. tostring(id))
        end)
        if not ok or not objects or #objects == 0 then
            notify("Skybox failed: " .. tostring(name or id))
            return
        end

        local model = objects[1]
        local sky = model:IsA("Sky") and model or model:FindFirstChildOfClass("Sky")
        if not sky then
            pcall(function() model:Destroy() end)
            notify("Skybox not found: " .. tostring(name or id))
            return
        end

        local existing = Lighting:FindFirstChildOfClass("Sky")
        if existing then
            existing:Destroy()
        end
        Lighting.ClockTime = 14
        Lighting.Brightness = 0.5
        sky.Parent = Lighting
        if model ~= sky then
            pcall(function() model:Destroy() end)
        end
        notify((name or "Skybox") .. " set")
    end)
end

local function removeSkybox()
    local sky = Lighting:FindFirstChildOfClass("Sky")
    if sky then
        sky:Destroy()
    end
    notify("Skybox removed")
end

-- =============================================================================
-- AURAS
-- =============================================================================
local auraObjects = {}
local auraName = nil

local function clearAura()
    for _, obj in ipairs(auraObjects) do
        pcall(function() obj:Destroy() end)
    end
    auraObjects = {}
    auraName = nil
end

local function applyAura(assetId, name)
    if auraName == name then
        clearAura()
        notify(name .. " off")
        return
    end

    clearAura()

    local ok, objects = pcall(function()
        return game:GetObjects("rbxassetid://" .. tostring(assetId))
    end)
    if not ok or not objects or #objects == 0 then
        notify("Aura failed: " .. name)
        return
    end

    local model = objects[1]
    local character = LocalPlayer.Character
    if not character then
        pcall(function() model:Destroy() end)
        notify("Character not ready")
        return
    end

    local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
    local head = character:FindFirstChild("Head")
    if not torso or not head then
        pcall(function() model:Destroy() end)
        notify("Character parts not found")
        return
    end

    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("PointLight") or descendant:IsA("SpotLight") or descendant:IsA("SurfaceLight") then
            descendant:Destroy()
        elseif descendant:IsA("ParticleEmitter") then
            descendant.LightEmission = 1
            descendant.Rate = math.clamp(descendant.Rate * 0.35, 1, 40)
            pcall(function()
                local keypoints = {}
                for _, keypoint in ipairs(descendant.Transparency.Keypoints) do
                    local value = math.clamp(keypoint.Value + (1 - keypoint.Value) * 0.45, 0.3, 1)
                    table.insert(keypoints, NumberSequenceKeypoint.new(keypoint.Time, value, keypoint.Envelope))
                end
                descendant.Transparency = NumberSequence.new(keypoints)
            end)
        elseif descendant:IsA("Beam") then
            descendant.LightEmission = 1
            pcall(function()
                local keypoints = {}
                for _, keypoint in ipairs(descendant.Transparency.Keypoints) do
                    local value = math.clamp(keypoint.Value + (1 - keypoint.Value) * 0.4, 0.25, 1)
                    table.insert(keypoints, NumberSequenceKeypoint.new(keypoint.Time, value, keypoint.Envelope))
                end
                descendant.Transparency = NumberSequence.new(keypoints)
            end)
        elseif descendant:IsA("BasePart") then
            descendant.Anchored = false
            descendant.CanCollide = false
            descendant.Massless = true
            descendant.CanTouch = false
            descendant.CanQuery = false
            if descendant.Material == Enum.Material.Neon then
                descendant.Transparency = math.max(descendant.Transparency, 0.5)
            end
        end
    end

    local n2 = (name == "Red Shield") and 4 or 1
    local mapping = {
        Torso = torso.Name,
        Head = "Head",
        ["Left Arm"] = "LeftUpperArm",
        ["Right Arm"] = "RightUpperArm",
        ["Left Leg"] = "LeftUpperLeg",
        ["Right Leg"] = "RightUpperLeg"
    }
    local results = {}

    local auraPart = model:FindFirstChild("Aura")
    if auraPart and auraPart:IsA("BasePart") then
        auraPart.Parent = character
        if model:FindFirstChild("Torso") then
            local relative = model.Torso.CFrame:Inverse() * auraPart.CFrame
            auraPart.CFrame = torso.CFrame * relative * CFrame.new(0, 0.5, 0)
        else
            auraPart.CFrame = torso.CFrame * CFrame.new(0, 0.5, 0)
        end
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = torso
        weld.Part1 = auraPart
        weld.Parent = auraPart
        table.insert(results, weld)
        table.insert(results, auraPart)
        for _, child in ipairs(auraPart:GetChildren()) do
            if child:IsA("ParticleEmitter") or child:IsA("Beam") or child:IsA("Highlight") then
                local clone = child:Clone()
                if clone:IsA("ParticleEmitter") then
                    clone.Lifetime = NumberRange.new(clone.Lifetime.Min * n2, clone.Lifetime.Max * n2)
                end
                clone.Parent = torso
                table.insert(results, clone)
            end
        end
    end

    for _, child in ipairs(model:GetChildren()) do
        if child:IsA("BasePart") and child.Name ~= "Aura" then
            local target = character:FindFirstChild(mapping[child.Name] or child.Name)
            if target then
                for _, child2 in ipairs(child:GetChildren()) do
                    if child2:IsA("ParticleEmitter") or child2:IsA("Attachment") or child2:IsA("Highlight") then
                        local clone = child2:Clone()
                        if clone:IsA("ParticleEmitter") then
                            clone.Lifetime = NumberRange.new(clone.Lifetime.Min * n2, clone.Lifetime.Max * n2)
                        end
                        clone.Parent = target
                        table.insert(results, clone)
                    end
                end
            end
        end
    end

    local crownBase = model:FindFirstChild("Crown Base")
    if crownBase and name == "Crimson King" then
        crownBase.Parent = character
        local relative = CFrame.new(0, 1.5, 0)
        if model:FindFirstChild("Head") then
            relative = model.Head.CFrame:Inverse() * crownBase.CFrame
        end
        crownBase.CFrame = head.CFrame * relative
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = head
        weld.Part1 = crownBase
        weld.Parent = crownBase
        table.insert(results, weld)
        table.insert(results, crownBase)

        local crownBeams = crownBase:FindFirstChild("Crown Beams")
        if crownBeams then
            for _, beam in ipairs(crownBeams:GetDescendants()) do
                if beam:IsA("Beam") then
                    local clone = beam:Clone()
                    if clone.Attachment0 and crownBase:FindFirstChild(clone.Attachment0.Name) then
                        clone.Attachment0 = crownBase[clone.Attachment0.Name]
                    end
                    if clone.Attachment1 and crownBase:FindFirstChild(clone.Attachment1.Name) then
                        clone.Attachment1 = crownBase[clone.Attachment1.Name]
                    end
                    clone.Parent = torso
                    table.insert(results, clone)
                end
            end
        end
    end

    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("ParticleEmitter") or descendant:IsA("Highlight") or descendant:IsA("Beam") or descendant:IsA("Attachment") then
            local clone = descendant:Clone()
            if clone:IsA("Beam") then
                if clone.Attachment0 and torso:FindFirstChild(clone.Attachment0.Name) then
                    clone.Attachment0 = torso[clone.Attachment0.Name]
                end
                if clone.Attachment1 and torso:FindFirstChild(clone.Attachment1.Name) then
                    clone.Attachment1 = torso[clone.Attachment1.Name]
                end
            end
            if clone:IsA("ParticleEmitter") then
                clone.Lifetime = NumberRange.new(clone.Lifetime.Min * n2, clone.Lifetime.Max * n2)
                if name == "Red Shield" then
                    clone.LockedToPart = true
                end
            end
            clone.Parent = torso
            table.insert(results, clone)
        end
    end

    pcall(function()
        model:Destroy()
    end)

    auraObjects = results
    auraName = name
    notify(name .. " on")
end

-- =============================================================================
-- CHINA HAT
-- =============================================================================
local function removeChinaHat(character)
    if not character then return end
    local hat = character:FindFirstChild("nursultanChinaHat")
    if hat then
        hat:Destroy()
    end
end

local function createChinaHat(character)
    removeChinaHat(character)
    local head = character:FindFirstChild("Head") or character:WaitForChild("Head", 5)
    if not head then return end

    local part = Instance.new("Part")
    part.Name = "nursultanChinaHat"
    part.Size = Vector3.new(1, 1, 1)
    part.Material = Enum.Material.Neon
    part.Transparency = 0.2
    part.Anchored = false
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Massless = true
    part.Color = S.chinaHatColor

    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.FileMesh
    mesh.MeshId = "rbxassetid://1033714"
    mesh.Scale = Vector3.new(1.7, 1.1, 1.7)
    mesh.Parent = part

    local weld = Instance.new("Weld")
    weld.Part0 = head
    weld.Part1 = part
    weld.C0 = CFrame.new(0, S.chinaHatHeight, 0)
    weld.Parent = part

    local light = Instance.new("PointLight")
    light.Color = S.chinaHatColor
    light.Brightness = 0
    light.Range = 12
    light.Shadows = true
    light.Parent = part

    part.Parent = character
end

local function updateChinaHat()
    local character = LocalPlayer.Character
    if not character then return end
    if S.chinaHat then
        createChinaHat(character)
    else
        removeChinaHat(character)
    end
end

LocalPlayer.CharacterAdded:Connect(function(character)
    if S.chinaHat then
        task.wait(0.5)
        createChinaHat(character)
    end
end)

-- =============================================================================
-- JUMP CIRCLE
-- =============================================================================
local jumpCircleConn = nil
local JUMP_CIRCLE_IMAGE = "rbxassetid://133238425773760"

local function spawnJumpCircle(position)
    local part = Instance.new("Part")
    part.Name = "nursultanJumpCircle"
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part.Size = Vector3.new(0.5, 0.05, 0.5)
    part.CFrame = CFrame.new(position + Vector3.new(0, 0.05, 0))
    part.Transparency = 1
    part.Parent = Workspace

    local gui = Instance.new("SurfaceGui")
    gui.Face = Enum.NormalId.Top
    gui.AlwaysOnTop = true
    gui.LightInfluence = 0
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    gui.PixelsPerStud = 100
    gui.Parent = part

    local image = Instance.new("ImageLabel")
    image.BackgroundTransparency = 1
    image.Size = UDim2.fromScale(1, 1)
    image.Image = JUMP_CIRCLE_IMAGE
    image.ImageColor3 = S.jumpCircleColor
    image.ImageTransparency = 0
    image.Parent = gui

    local info = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(part, info, { Size = Vector3.new(7, 0.05, 7) }):Play()
    TweenService:Create(image, info, { ImageTransparency = 1 }):Play()
    Debris:AddItem(part, 0.9)
end

local function bindJumpCircle(character)
    if jumpCircleConn then
        jumpCircleConn:Disconnect()
        jumpCircleConn = nil
    end
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
    local hrp = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart", 5)
    if not humanoid or not hrp then return end

    jumpCircleConn = humanoid.StateChanged:Connect(function(_, newState)
        if newState == Enum.HumanoidStateType.Jumping and S.jumpCircle then
            spawnJumpCircle(hrp.Position - Vector3.new(0, 2.8, 0))
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(function(character)
    bindJumpCircle(character)
end)
if LocalPlayer.Character then
    bindJumpCircle(LocalPlayer.Character)
end

-- =============================================================================
-- TARGET ESP
-- =============================================================================
local targetEspGui = nil
local targetEspFrame = nil
local targetEspCorners = nil
local targetEspState = {
    lastPlayer = nil,
    lastHp = 0,
    damageTime = 0
}

local function isTargetEspPlayerValid(player)
    if not player or player == LocalPlayer or not player.Character then
        return false
    end
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0 and player.Character:FindFirstChild("HumanoidRootPart") ~= nil
end

local function getTargetEspPlayer()
    local camera = Workspace.CurrentCamera
    if not camera then return nil end

    local center = camera.ViewportSize / 2
    local best, bestDistance = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if isTargetEspPlayerValid(player) and not isTeammate(player) then
            local part = getAimPart(player) or player.Character.HumanoidRootPart
            local screenPosition, onScreen = camera:WorldToViewportPoint(part.Position)
            if onScreen and screenPosition.Z > 0 then
                local distance = (Vector2.new(screenPosition.X, screenPosition.Y) - center).Magnitude
                if distance < bestDistance then
                    best, bestDistance = player, distance
                end
            end
        end
    end
    if best then return best end

    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return nil
    end
    local position = character.HumanoidRootPart.Position
    for _, player in ipairs(Players:GetPlayers()) do
        if isTargetEspPlayerValid(player) and not isTeammate(player) then
            local distance = (position - player.Character.HumanoidRootPart.Position).Magnitude
            if distance < bestDistance then
                best, bestDistance = player, distance
            end
        end
    end
    return best
end

local function createTargetEspGui()
    if targetEspGui then return end

    local gui = Instance.new("ScreenGui")
    gui.Name = "NursultanTargetESP"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Parent = getGuiParent()
    targetEspGui = gui

    local frame = Instance.new("Frame", gui)
    frame.BackgroundTransparency = 1
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Visible = false
    targetEspFrame = frame

    local function makeCorner(position)
        local corner = Instance.new("Frame", frame)
        corner.Size = UDim2.new(0.3, 0, 0.3, 0)
        corner.Position = position
        corner.BackgroundTransparency = 1

        local horizontal = Instance.new("Frame", corner)
        horizontal.BorderSizePixel = 0
        horizontal.ZIndex = 6
        horizontal.Size = UDim2.new(1, 0, 0, 0)
        horizontal.Position = position.Y.Scale > 0 and UDim2.new(0, 0, 1, 0) or UDim2.new(0, 0, 0, 0)

        local vertical = Instance.new("Frame", corner)
        vertical.BorderSizePixel = 0
        vertical.ZIndex = 6
        vertical.Size = UDim2.new(0, 0, 1, 0)
        vertical.Position = position.X.Scale > 0 and UDim2.new(1, 0, 0, 0) or UDim2.new(0, 0, 0, 0)

        local stroke1 = Instance.new("UIStroke", horizontal)
        stroke1.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        local stroke2 = Instance.new("UIStroke", vertical)
        stroke2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

        local horizontal2 = Instance.new("Frame", corner)
        horizontal2.BorderSizePixel = 0
        horizontal2.ZIndex = 5
        horizontal2.Size = UDim2.new(1, 0, 0, 0)
        horizontal2.Position = horizontal.Position

        local vertical2 = Instance.new("Frame", corner)
        vertical2.BorderSizePixel = 0
        vertical2.ZIndex = 5
        vertical2.Size = UDim2.new(0, 0, 1, 0)
        vertical2.Position = vertical.Position

        local stroke3 = Instance.new("UIStroke", horizontal2)
        stroke3.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke3.Transparency = 0.55
        local stroke4 = Instance.new("UIStroke", vertical2)
        stroke4.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke4.Transparency = 0.55

        local horizontal3 = Instance.new("Frame", corner)
        horizontal3.BorderSizePixel = 0
        horizontal3.ZIndex = 4
        horizontal3.Size = UDim2.new(1, 0, 0, 0)
        horizontal3.Position = horizontal.Position

        local vertical3 = Instance.new("Frame", corner)
        vertical3.BorderSizePixel = 0
        vertical3.ZIndex = 4
        vertical3.Size = UDim2.new(0, 0, 1, 0)
        vertical3.Position = vertical.Position

        local stroke5 = Instance.new("UIStroke", horizontal3)
        stroke5.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke5.Transparency = 0.8
        local stroke6 = Instance.new("UIStroke", vertical3)
        stroke6.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke6.Transparency = 0.8

        return { stroke1, stroke2, stroke3, stroke4, stroke5, stroke6 }
    end

    targetEspCorners = {
        makeCorner(UDim2.new(0, 0, 0, 0)),
        makeCorner(UDim2.new(0.7, 0, 0, 0)),
        makeCorner(UDim2.new(0, 0, 0.7, 0)),
        makeCorner(UDim2.new(0.7, 0, 0.7, 0))
    }
end

local function updateTargetEsp(player)
    if not targetEspFrame then return end

    local camera = Workspace.CurrentCamera
    if not camera then
        targetEspFrame.Visible = false
        return
    end

    if not player or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        targetEspFrame.Visible = false
        targetEspState.lastPlayer = nil
        return
    end

    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        targetEspFrame.Visible = false
        targetEspState.lastPlayer = nil
        return
    end

    if targetEspState.lastPlayer ~= player.UserId then
        targetEspState.lastPlayer = player.UserId
        targetEspState.lastHp = humanoid.Health
        targetEspState.damageTime = 0
    end
    if targetEspState.lastHp and humanoid.Health < targetEspState.lastHp then
        targetEspState.damageTime = tick()
    end
    targetEspState.lastHp = humanoid.Health

    local screenPosition, onScreen = camera:WorldToViewportPoint(player.Character.HumanoidRootPart.Position)
    if not onScreen then
        targetEspFrame.Visible = false
        return
    end

    targetEspFrame.Visible = true
    local color = Color3.fromRGB(255, 60, 60)
    local elapsed = tick() - targetEspState.damageTime
    local color2 = elapsed < 0.6 and Color3.fromRGB(255, 255, 255):Lerp(color, elapsed / 0.6) or color

    targetEspFrame.Position = UDim2.new(0, screenPosition.X, 0, screenPosition.Y)
    targetEspFrame.Size = UDim2.new(0, 45, 0, 45)
    targetEspFrame.Rotation = tick() * 60 % 360

    for _, corner in ipairs(targetEspCorners) do
        corner[1].Thickness = 2.5
        corner[2].Thickness = 2.5
        corner[3].Thickness = 4.5
        corner[4].Thickness = 4.5
        corner[5].Thickness = 7.5
        corner[6].Thickness = 7.5
        corner[1].Color = color2
        corner[2].Color = color2
        corner[3].Color = color2
        corner[4].Color = color2
        corner[5].Color = color2
        corner[6].Color = color2
    end
end

-- =============================================================================
-- TARGET HUD
-- =============================================================================
local targetHudGui = nil
local targetHudFrame = nil
local targetHudAvatar = nil
local targetHudName = nil
local targetHudHealthBar = nil
local targetHudHealthText = nil
local targetHudPlayerId = nil

local function makeDraggable(frame, handle)
    local dragging = false
    local dragStart = nil
    local startPos = nil

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local function createTargetHudGui()
    if targetHudGui then return end

    local theme = currentTheme().colors

    local gui = Instance.new("ScreenGui")
    gui.Name = "NursultanTargetHUD"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Parent = getGuiParent()
    targetHudGui = gui

    local frame = Instance.new("Frame")
    frame.Name = "TargetHUD"
    frame.Size = UDim2.new(0, 235, 0, 75)
    frame.Position = UDim2.new(1, -25, 0, 25)
    frame.AnchorPoint = Vector2.new(1, 0)
    frame.BackgroundColor3 = theme.CardBg
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = gui
    targetHudFrame = frame

    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = theme.Border
    stroke.Thickness = 1.2
    stroke.Transparency = 0.2
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local drag = Instance.new("TextButton", frame)
    drag.Name = "Drag"
    drag.BackgroundTransparency = 1
    drag.Size = UDim2.new(1, 0, 0, 22)
    drag.Text = ""
    drag.ZIndex = 10
    makeDraggable(frame, drag)

    local avatarFrame = Instance.new("Frame", frame)
    avatarFrame.Size = UDim2.new(0, 56, 0, 56)
    avatarFrame.Position = UDim2.new(0, 9, 0, 9)
    avatarFrame.BackgroundColor3 = theme.PillBg
    avatarFrame.BorderSizePixel = 0
    Instance.new("UICorner", avatarFrame).CornerRadius = UDim.new(0, 8)

    local avatarStroke = Instance.new("UIStroke", avatarFrame)
    avatarStroke.Color = theme.Border
    avatarStroke.Thickness = 1

    local avatar = Instance.new("ImageLabel", avatarFrame)
    avatar.Size = UDim2.new(1, 0, 1, 0)
    avatar.BackgroundTransparency = 1
    avatar.ScaleType = Enum.ScaleType.Crop
    avatar.Image = ""
    avatar.Parent = avatarFrame
    Instance.new("UICorner", avatar).CornerRadius = UDim.new(0, 8)
    targetHudAvatar = avatar

    local name = Instance.new("TextLabel", frame)
    name.Size = UDim2.new(1, -90, 0, 18)
    name.Position = UDim2.new(0, 72, 0, 8)
    name.BackgroundTransparency = 1
    name.Font = Enum.Font.GothamBold
    name.TextSize = 13
    name.TextColor3 = theme.TextPrimary
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.TextTruncate = Enum.TextTruncate.AtEnd
    name.Text = ""
    targetHudName = name

    local subtitle = Instance.new("TextLabel", frame)
    subtitle.Size = UDim2.new(1, -90, 0, 14)
    subtitle.Position = UDim2.new(0, 72, 0, 27)
    subtitle.BackgroundTransparency = 1
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 11
    subtitle.TextColor3 = theme.TextMuted
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Text = tr({ en = "Target", ru = "Цель" })

    local hpText = Instance.new("TextLabel", frame)
    hpText.Size = UDim2.new(0, 60, 0, 14)
    hpText.Position = UDim2.new(1, -68, 0, 27)
    hpText.BackgroundTransparency = 1
    hpText.Font = Enum.Font.GothamBold
    hpText.TextSize = 11
    hpText.TextColor3 = theme.TextMuted
    hpText.TextXAlignment = Enum.TextXAlignment.Right
    hpText.Text = ""
    targetHudHealthText = hpText

    local barBack = Instance.new("Frame", frame)
    barBack.Size = UDim2.new(1, -81, 0, 8)
    barBack.Position = UDim2.new(0, 72, 0, 48)
    barBack.BackgroundColor3 = theme.PillBg
    barBack.BorderSizePixel = 0
    Instance.new("UICorner", barBack).CornerRadius = UDim.new(0, 4)

    local bar = Instance.new("Frame", barBack)
    bar.Size = UDim2.new(1, 0, 1, 0)
    bar.BackgroundColor3 = theme.Accent
    bar.BorderSizePixel = 0
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 4)
    targetHudHealthBar = bar
end

local function updateTargetHud(player)
    if not targetHudFrame then return end

    if not S.targetHud or not player or not player.Character then
        targetHudFrame.Visible = false
        return
    end

    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        targetHudFrame.Visible = false
        return
    end

    targetHudFrame.Visible = true

    if targetHudPlayerId ~= player.UserId then
        targetHudPlayerId = player.UserId
        targetHudName.Text = player.DisplayName
        targetHudAvatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=150&h=150"
    end

    local health = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
    targetHudHealthBar.Size = UDim2.new(health, 0, 1, 0)
    targetHudHealthText.Text = string.format("%.0f HP", humanoid.Health)
end

RunService.RenderStepped:Connect(function()
    local target = nil
    if S.targetEsp or S.targetHud then
        target = getTargetEspPlayer()
    end

    if S.targetEsp then
        createTargetEspGui()
        updateTargetEsp(target)
    elseif targetEspFrame then
        targetEspFrame.Visible = false
    end

    if S.targetHud then
        createTargetHudGui()
        updateTargetHud(target)
    elseif targetHudFrame then
        targetHudFrame.Visible = false
    end
end)

-- =============================================================================
-- EMOTES
-- =============================================================================
local function stopEmotes()
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local animator = humanoid:FindFirstChildOfClass("Animator")
            if animator then
                for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                    track:Stop()
                end
            end
            local animate = character:FindFirstChild("Animate")
            if animate then
                animate.Disabled = false
            end
        end
    end
end

local function playEmote(name)
    local id = EMOTE_LIST[name]
    if not id then return end

    local character = LocalPlayer.Character
    if not character then
        notify("Character not found")
        return
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    stopEmotes()

    local description = humanoid:FindFirstChildOfClass("HumanoidDescription")
    pcall(function()
        humanoid:PlayEmote("")
    end)

    local ok, track = pcall(function()
        return humanoid:PlayEmoteAndGetAnimTrackById(id)
    end)
    if (not ok or not track) and description then
        pcall(function()
            description:AddEmote(name, id)
        end)
        ok, track = pcall(function()
            return humanoid:PlayEmoteAndGetAnimTrackById(id)
        end)
    end

    if ok and typeof(track) == "Instance" and track:IsA("AnimationTrack") then
        track.Priority = Enum.AnimationPriority.Idle
        track:Play(0)
    else
        pcall(function()
            local animation = Instance.new("Animation")
            animation.AnimationId = "rbxassetid://" .. id
            local loaded = humanoid:LoadAnimation(animation)
            loaded.Priority = Enum.AnimationPriority.Idle
            loaded:Play(0)
        end)
    end

    local animate = character:FindFirstChild("Animate")
    if animate and not animate.Disabled then
        animate.Disabled = true
    end
end

-- =============================================================================
-- ANIMATION PACKS
-- =============================================================================
local ANIM_URL = "http://www.roblox.com/asset/?id="
local originalAnims = nil

local function saveOriginalAnims()
    if originalAnims then return end
    local character = LocalPlayer.Character
    if not character then return end
    local animate = character:FindFirstChild("Animate")
    if not animate then return end

    local saved = {}
    pcall(function() saved.idle1 = animate.idle.Animation1.AnimationId end)
    pcall(function() saved.idle2 = animate.idle.Animation2.AnimationId end)
    pcall(function() saved.walk = animate.walk:FindFirstChildOfClass("Animation").AnimationId end)
    pcall(function() saved.run = animate.run:FindFirstChildOfClass("Animation").AnimationId end)
    pcall(function() saved.jump = animate.jump:FindFirstChildOfClass("Animation").AnimationId end)
    pcall(function() saved.climb = animate.climb:FindFirstChildOfClass("Animation").AnimationId end)
    pcall(function() saved.fall = animate.fall:FindFirstChildOfClass("Animation").AnimationId end)
    if animate:FindFirstChild("pose") then
        pcall(function() saved.pose = animate.pose:FindFirstChildOfClass("Animation").AnimationId end)
    end
    if animate:FindFirstChild("swim") then
        pcall(function() saved.swim = animate.swim:FindFirstChildOfClass("Animation").AnimationId end)
        pcall(function() saved.swimIdle = animate.swimidle:FindFirstChildOfClass("Animation").AnimationId end)
    end
    originalAnims = saved
end

local function playAnimationBody(pack)
    local character = LocalPlayer.Character
    if not character then return end
    local animate = character:FindFirstChild("Animate")
    if not animate then return end

    pcall(function()
        animate.idle.Animation1.AnimationId = ANIM_URL .. tostring(pack.Idle)
        animate.idle.Animation1.Weight.Value = tostring(pack.Weight)
        animate.idle.Animation2.Weight.Value = tostring(pack.Weight2)
        animate.idle.Animation2.AnimationId = ANIM_URL .. tostring(pack.Idle2)
    end)

    if pack.Idle3 and pack.Idle3 ~= "None" and tonumber(pack.Idle3) then
        pcall(function()
            if animate:FindFirstChild("pose") then
                local animation = animate.pose:FindFirstChildOfClass("Animation")
                if animation then
                    animation.AnimationId = ANIM_URL .. tostring(pack.Idle3)
                end
            end
        end)
    end

    pcall(function() animate.walk:FindFirstChildOfClass("Animation").AnimationId = ANIM_URL .. tostring(pack.Walk) end)
    pcall(function() animate.run:FindFirstChildOfClass("Animation").AnimationId = ANIM_URL .. tostring(pack.Run) end)
    pcall(function() animate.jump:FindFirstChildOfClass("Animation").AnimationId = ANIM_URL .. tostring(pack.Jump) end)
    pcall(function() animate.climb:FindFirstChildOfClass("Animation").AnimationId = ANIM_URL .. tostring(pack.Climb) end)
    pcall(function() animate.fall:FindFirstChildOfClass("Animation").AnimationId = ANIM_URL .. tostring(pack.Fall) end)
    if animate:FindFirstChild("swim") then
        pcall(function() animate.swim:FindFirstChildOfClass("Animation").AnimationId = ANIM_URL .. tostring(pack.Swim) end)
        pcall(function() animate.swimidle:FindFirstChildOfClass("Animation").AnimationId = ANIM_URL .. tostring(pack.SwimIdle) end)
    end
end

local function refreshAnims()
    local character = LocalPlayer.Character
    if not character then return end
    local animate = character:FindFirstChild("Animate")
    if not animate then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    animate.Disabled = true
    task.wait()
    for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
        track:Stop()
    end
    animate.Disabled = false
    local walkSpeed = humanoid.WalkSpeed
    humanoid.WalkSpeed = 0
    task.wait()
    humanoid.WalkSpeed = walkSpeed
end

local function resetAnimation()
    local character = LocalPlayer.Character
    if not character then return end
    local animate = character:FindFirstChild("Animate")
    if not animate or not originalAnims then return end

    pcall(function()
        if originalAnims.pose and animate:FindFirstChild("pose") then
            local animation = animate.pose:FindFirstChildOfClass("Animation")
            if animation then
                animation.AnimationId = originalAnims.pose
            end
        end
        animate.idle.Animation1.AnimationId = originalAnims.idle1
        animate.idle.Animation2.AnimationId = originalAnims.idle2
        animate.walk:FindFirstChildOfClass("Animation").AnimationId = originalAnims.walk
        animate.run:FindFirstChildOfClass("Animation").AnimationId = originalAnims.run
        animate.jump:FindFirstChildOfClass("Animation").AnimationId = originalAnims.jump
        animate.climb:FindFirstChildOfClass("Animation").AnimationId = originalAnims.climb
        animate.fall:FindFirstChildOfClass("Animation").AnimationId = originalAnims.fall
        if originalAnims.swim and animate:FindFirstChild("swim") then
            animate.swim:FindFirstChildOfClass("Animation").AnimationId = originalAnims.swim
            animate.swimidle:FindFirstChildOfClass("Animation").AnimationId = originalAnims.swimIdle
        end
    end)
    refreshAnims()
end

LocalPlayer.CharacterAdded:Connect(function()
    originalAnims = nil
    task.wait(0.5)
    saveOriginalAnims()
end)
task.spawn(function()
    local character = LocalPlayer.Character
    if character then
        character:WaitForChild("Animate", 10)
    end
    saveOriginalAnims()
end)

-- =============================================================================
-- HELPERS
-- =============================================================================
local THEME = THEMES[1].colors

local TWEEN_FAST = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_SLOW = TweenInfo.new(0.35, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)

local function make(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props) do inst[k] = v end
    if parent then inst.Parent = parent end
    return inst
end

local function corner(inst, radius)
    return make("UICorner", { CornerRadius = UDim.new(0, radius) }, inst)
end

local function stroke(inst, color, thickness, transparency)
    return make("UIStroke", {
        Color = color or THEME.Border,
        Thickness = thickness or 1,
        Transparency = transparency or 0
    }, inst)
end

local function label(props, parent)
    if props.BackgroundTransparency == nil then
        props.BackgroundTransparency = 1
    end
    props.Font = props.Font or Enum.Font.GothamMedium
    props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
    return make("TextLabel", props, parent)
end

local function icon(props, parent)
    props.BackgroundTransparency = 1
    props.ScaleType = props.ScaleType or Enum.ScaleType.Fit
    return make("ImageLabel", props, parent)
end

local function pointIn(guiObject, position)
    local ap = guiObject.AbsolutePosition
    local size = guiObject.AbsoluteSize
    return position.X >= ap.X and position.X <= ap.X + size.X
        and position.Y >= ap.Y and position.Y <= ap.Y + size.Y
end

-- Connections registry (current build only)
local Conns = {}
local function track(conn)
    Conns[#Conns + 1] = conn
    return conn
end

local ScreenGui = nil

local function destroyBuild()
    for _, conn in ipairs(Conns) do
        pcall(function() conn:Disconnect() end)
    end
    Conns = {}
    if ScreenGui then
        pcall(function() ScreenGui:Destroy() end)
        ScreenGui = nil
    end
end

-- =============================================================================
-- BUILD
-- =============================================================================
local function buildUI()
    destroyBuild()

    THEME = currentTheme().colors
    local loc = L()

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "NursultanClient"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    do
        local parented = false
        pcall(function()
            local hui = gethui and gethui()
            if hui then
                ScreenGui.Parent = hui
                parented = true
            end
        end)
        if not parented then
            local ok = pcall(function() ScreenGui.Parent = CoreGui end)
            if not ok or ScreenGui.Parent == nil then
                ScreenGui.Parent = PlayerGui
            end
        end
    end

    -- =========================================================================
    -- SHARED FEEDBACK + UI COMPONENTS
    -- =========================================================================
    local function toast(text)
        local t = make("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.new(0, 0, 0, 30),
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 1, -96),
            BackgroundColor3 = THEME.CardBg,
            BackgroundTransparency = 1,
            Text = tostring(text),
            Font = Enum.Font.GothamBold,
            TextSize = 10,
            TextColor3 = THEME.TextPrimary,
            TextTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 60,
            Parent = ScreenGui
        })
        corner(t, 8)
        stroke(t, THEME.Border, 1)

        make("UIPadding", {
            PaddingLeft = UDim.new(0, 16),
            PaddingRight = UDim.new(0, 16),
            PaddingTop = UDim.new(0, 8),
            PaddingBottom = UDim.new(0, 8),
            Parent = t
        })

        TweenService:Create(t, TWEEN_FAST, { TextTransparency = 0, BackgroundTransparency = 0.05 }):Play()

        task.delay(1.8, function()
            pcall(function()
                local out = TweenService:Create(t, TWEEN_FAST, { TextTransparency = 1, BackgroundTransparency = 1 })
                out.Completed:Connect(function()
                    t:Destroy()
                end)
                out:Play()
            end)
        end)
    end

    notifyHook = toast

    local ORDER_ATTR = "NursultanOrder"
    local function takeOrder(parent)
        local n = parent:GetAttribute(ORDER_ATTR) or 1
        parent:SetAttribute(ORDER_ATTR, n + 1)
        return n
    end

    local function styledSearch(parent, x, y, w, placeholder)
        local box = make("Frame", {
            Size = UDim2.new(0, w, 0, 34),
            Position = UDim2.new(0, x, 0, y),
            BackgroundColor3 = THEME.PillBg,
            BorderSizePixel = 0,
            Parent = parent
        })
        corner(box, 8)
        stroke(box, THEME.Border, 1)

        icon({
            Size = UDim2.new(0, 16, 0, 16),
            Position = UDim2.new(0, 11, 0.5, -8),
            Image = "rbxassetid://7733911828",
            ImageColor3 = THEME.TextMuted,
            Parent = box
        }, box)

        return make("TextBox", {
            PlaceholderText = placeholder,
            PlaceholderColor3 = THEME.TextMuted,
            TextColor3 = THEME.TextPrimary,
            Font = Enum.Font.Gotham,
            TextSize = 13,
            Position = UDim2.new(0, 34, 0, 0),
            Size = UDim2.new(1, -42, 1, 0),
            BackgroundTransparency = 1,
            Text = "",
            ClearTextOnFocus = false,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = box
        }), box
    end

    local PALETTE = {
        Color3.fromRGB(255, 60, 60), Color3.fromRGB(255, 105, 180), Color3.fromRGB(168, 112, 255),
        Color3.fromRGB(82, 160, 246), Color3.fromRGB(90, 220, 255), Color3.fromRGB(90, 230, 140),
        Color3.fromRGB(255, 215, 90), Color3.fromRGB(255, 150, 70), Color3.fromRGB(245, 245, 245),
        Color3.fromRGB(150, 150, 150), Color3.fromRGB(25, 25, 25), Color3.fromRGB(170, 255, 90),
        Color3.fromRGB(60, 220, 200), Color3.fromRGB(255, 80, 200), Color3.fromRGB(255, 190, 60),
        Color3.fromRGB(130, 200, 255), Color3.fromRGB(120, 255, 220), Color3.fromRGB(255, 120, 90)
    }

    local function openPalette(titleText, current, onPick)
        local overlay = make("TextButton", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 0.55,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 80,
            Parent = ScreenGui
        })

        local panel = make("Frame", {
            Size = UDim2.new(0, 280, 0, 205),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            BackgroundColor3 = THEME.CardBg,
            BorderSizePixel = 0,
            ZIndex = 81,
            Parent = overlay
        })
        corner(panel, 10)
        stroke(panel, THEME.Border, 1)

        label({
            Size = UDim2.new(1, -50, 0, 20),
            Position = UDim2.new(0, 14, 0, 12),
            Text = titleText,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextColor3 = THEME.TextPrimary,
            ZIndex = 82,
            Parent = panel
        }, panel)

        local close = make("TextButton", {
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(1, -30, 0, 11),
            BackgroundTransparency = 1,
            Text = "×",
            Font = Enum.Font.GothamBold,
            TextSize = 16,
            TextColor3 = THEME.TextMuted,
            AutoButtonColor = false,
            ZIndex = 82,
            Parent = panel
        })
        track(close.MouseButton1Click:Connect(function()
            overlay:Destroy()
        end))

        for i, color in ipairs(PALETTE) do
            local column = (i - 1) % 6
            local row = math.floor((i - 1) / 6)
            local swatch = make("TextButton", {
                Size = UDim2.new(0, 36, 0, 36),
                Position = UDim2.new(0, 14 + column * 43, 0, 44 + row * 44),
                BackgroundColor3 = color,
                Text = "",
                AutoButtonColor = false,
                ZIndex = 82,
                Parent = panel
            })
            corner(swatch, 8)
            stroke(swatch, color == current and THEME.TextPrimary or THEME.Border, color == current and 2 or 1, color == current and 0 or 0.3)

            track(swatch.MouseButton1Click:Connect(function()
                playSound("pick")
                onPick(color)
                overlay:Destroy()
            end))
        end

        track(overlay.MouseButton1Click:Connect(function()
            overlay:Destroy()
        end))
    end

    local function openList(titleText, options, current, onPick)
        local overlay = make("TextButton", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 0.55,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 80,
            Parent = ScreenGui
        })

        local panel = make("Frame", {
            Size = UDim2.new(0, 320, 0, 400),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            BackgroundColor3 = THEME.CardBg,
            BorderSizePixel = 0,
            ZIndex = 81,
            Parent = overlay
        })
        corner(panel, 10)
        stroke(panel, THEME.Border, 1)

        label({
            Size = UDim2.new(1, -50, 0, 20),
            Position = UDim2.new(0, 14, 0, 12),
            Text = titleText,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextColor3 = THEME.TextPrimary,
            ZIndex = 82,
            Parent = panel
        }, panel)

        local close = make("TextButton", {
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(1, -30, 0, 11),
            BackgroundTransparency = 1,
            Text = "×",
            Font = Enum.Font.GothamBold,
            TextSize = 16,
            TextColor3 = THEME.TextMuted,
            AutoButtonColor = false,
            ZIndex = 82,
            Parent = panel
        })
        track(close.MouseButton1Click:Connect(function()
            overlay:Destroy()
        end))

        local searchBox = nil
        local listY = 50
        if #options > 8 then
            searchBox = styledSearch(panel, 12, 40, 296, L().search)
            searchBox.ZIndex = 82
            listY = 82
        end

        local scroll = make("ScrollingFrame", {
            Size = UDim2.new(1, -24, 1, -(listY + 12)),
            Position = UDim2.new(0, 12, 0, listY),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = THEME.Border,
            ScrollBarImageTransparency = 0.3,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            ZIndex = 82,
            Parent = panel
        })
        make("UIListLayout", {
            Padding = UDim.new(0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = scroll
        })

        local entries = {}
        for index, optionText in ipairs(options) do
            local active = optionText == current
            local row = make("TextButton", {
                Size = UDim2.new(1, -6, 0, 36),
                BackgroundColor3 = active and THEME.SidebarActive or THEME.PillBg,
                BackgroundTransparency = active and 0 or 0.35,
                Text = "",
                AutoButtonColor = false,
                LayoutOrder = index,
                ZIndex = 82,
                Parent = scroll
            })
            corner(row, 8)
            local rowStroke = stroke(row, active and THEME.BorderActive or THEME.Border, 1, active and 0.1 or 0.6)

            label({
                Size = UDim2.new(1, -32, 1, 0),
                Position = UDim2.new(0, 14, 0, 0),
                Text = optionText,
                Font = Enum.Font.GothamMedium,
                TextSize = 13,
                TextColor3 = active and THEME.TextPrimary or THEME.TextMuted,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ZIndex = 82,
                Parent = row
            }, row)

            local dot = make("Frame", {
                Size = UDim2.new(0, 9, 0, 9),
                Position = UDim2.new(1, -22, 0.5, -4),
                BackgroundColor3 = THEME.Accent,
                BackgroundTransparency = active and 0 or 1,
                BorderSizePixel = 0,
                ZIndex = 82,
                Parent = row
            })
            corner(dot, 5)

            track(row.MouseEnter:Connect(function()
                TweenService:Create(row, TWEEN_FAST, { BackgroundTransparency = 0.1 }):Play()
                TweenService:Create(rowStroke, TWEEN_FAST, { Color = THEME.BorderActive, Transparency = 0.2 }):Play()
            end))
            track(row.MouseLeave:Connect(function()
                TweenService:Create(row, TWEEN_FAST, { BackgroundTransparency = active and 0 or 0.35 }):Play()
                TweenService:Create(rowStroke, TWEEN_FAST, { Color = active and THEME.BorderActive or THEME.Border, Transparency = active and 0.1 or 0.6 }):Play()
            end))
            track(row.MouseButton1Click:Connect(function()
                playSound("pick")
                onPick(optionText)
                overlay:Destroy()
            end))

            table.insert(entries, { Button = row, Name = string.lower(optionText) })
        end

        if searchBox then
            track(searchBox:GetPropertyChangedSignal("Text"):Connect(function()
                local query = string.lower(searchBox.Text)
                for _, entry in ipairs(entries) do
                    entry.Button.Visible = query == "" or string.find(entry.Name, query, 1, true) ~= nil
                end
            end))
        end

        track(overlay.MouseButton1Click:Connect(function()
            overlay:Destroy()
        end))
    end

    -- ---- cards & rows ----
    local function sectionCard(parent, titleText, subtitleText)
        local card = make("Frame", {
            Size = UDim2.new(1, -8, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = THEME.CardBg,
            BorderSizePixel = 0,
            LayoutOrder = takeOrder(parent),
            Parent = parent
        })
        corner(card, 10)
        stroke(card, THEME.Border, 1)

        make("UIPadding", {
            PaddingTop = UDim.new(0, 14),
            PaddingBottom = UDim.new(0, 14),
            PaddingLeft = UDim.new(0, 14),
            PaddingRight = UDim.new(0, 14),
            Parent = card
        })

        make("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = card
        })

        local head = make("Frame", {
            Size = UDim2.new(1, 0, 0, subtitleText and 46 or 28),
            BackgroundTransparency = 1,
            LayoutOrder = takeOrder(card),
            Parent = card
        })

        local tick = make("Frame", {
            Size = UDim2.new(0, 4, 0, 18),
            Position = UDim2.new(0, 0, 0, 5),
            BackgroundColor3 = THEME.Accent,
            BorderSizePixel = 0,
            Parent = head
        })
        corner(tick, 2)

        label({
            Size = UDim2.new(1, -18, 0, 22),
            Position = UDim2.new(0, 16, 0, 2),
            Text = titleText,
            Font = Enum.Font.GothamBold,
            TextSize = 17,
            TextColor3 = THEME.TextPrimary,
            Parent = head
        }, head)

        if subtitleText then
            label({
                Size = UDim2.new(1, -18, 0, 16),
                Position = UDim2.new(0, 16, 0, 25),
                Text = subtitleText,
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextColor3 = THEME.TextMuted,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = head
            }, head)
        end

        make("Frame", {
            Size = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = THEME.Divider,
            BorderSizePixel = 0,
            LayoutOrder = takeOrder(card),
            Parent = card
        })

        return card
    end

    local function toggleRow(card, titleText, descText, value, onChange)
        local height = descText and 54 or 42
        local row = make("TextButton", {
            Size = UDim2.new(1, 0, 0, height),
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = takeOrder(card),
            Parent = card
        })

        label({
            Size = UDim2.new(1, -72, 0, descText and 18 or 42),
            Position = UDim2.new(0, 0, 0, descText and 0 or 0),
            Text = titleText,
            Font = Enum.Font.GothamMedium,
            TextSize = 15,
            TextColor3 = THEME.TextPrimary,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = row
        }, row)

        if descText then
            label({
                Size = UDim2.new(1, -72, 0, 15),
                Position = UDim2.new(0, 0, 0, 20),
                Text = descText,
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextColor3 = THEME.TextMuted,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = row
            }, row)
        end

        local trackFrame = make("Frame", {
            Size = UDim2.new(0, 50, 0, 26),
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0),
            BackgroundColor3 = value and THEME.Accent or THEME.PillBg,
            BorderSizePixel = 0,
            Parent = row
        })
        corner(trackFrame, 13)
        local trackStroke = stroke(trackFrame, value and THEME.Accent or THEME.Border, 1)

        local knob = make("Frame", {
            Size = UDim2.new(0, 18, 0, 18),
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, value and 29 or 4, 0.5, 0),
            BackgroundColor3 = value and THEME.Background or THEME.TextMuted,
            BorderSizePixel = 0,
            ZIndex = 2,
            Parent = trackFrame
        })
        corner(knob, 9)

        local isOn = value
        local function paint(on)
            TweenService:Create(trackFrame, TWEEN_FAST, { BackgroundColor3 = on and THEME.Accent or THEME.PillBg }):Play()
            TweenService:Create(trackStroke, TWEEN_FAST, { Color = on and THEME.Accent or THEME.Border }):Play()
            TweenService:Create(knob, TWEEN_FAST, {
                Position = UDim2.new(0, on and 29 or 4, 0.5, 0),
                BackgroundColor3 = on and THEME.Background or THEME.TextMuted
            }):Play()
        end

        track(row.MouseButton1Click:Connect(function()
            isOn = not isOn
            paint(isOn)
            playSound(isOn and "on" or "off")
            onChange(isOn)
        end))
    end

    local function sliderRow(card, titleText, minValue, maxValue, value, step, format, onChange)
        local row = make("Frame", {
            Size = UDim2.new(1, 0, 0, 48),
            BackgroundTransparency = 1,
            LayoutOrder = takeOrder(card),
            Parent = card
        })

        label({
            Size = UDim2.new(0.7, 0, 0, 18),
            Text = titleText,
            Font = Enum.Font.GothamMedium,
            TextSize = 14,
            TextColor3 = THEME.TextMuted,
            Parent = row
        }, row)

        local valueLabel = label({
            Size = UDim2.new(0.3, 0, 0, 18),
            Position = UDim2.new(0.7, 0, 0, 0),
            Text = "",
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextColor3 = THEME.Accent,
            TextXAlignment = Enum.TextXAlignment.Right,
            Parent = row
        }, row)

        local bar = make("Frame", {
            Size = UDim2.new(1, 0, 0, 6),
            Position = UDim2.new(0, 0, 0, 33),
            BackgroundColor3 = THEME.PillBg,
            BorderSizePixel = 0,
            Parent = row
        })
        corner(bar, 3)

        local fill = make("Frame", {
            Size = UDim2.new(0, 0, 1, 0),
            BackgroundColor3 = THEME.Accent,
            BorderSizePixel = 0,
            Parent = bar
        })
        corner(fill, 3)

        local knob = make("Frame", {
            Size = UDim2.new(0, 15, 0, 15),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0, 0, 0.5, 0),
            BackgroundColor3 = THEME.TextPrimary,
            BorderSizePixel = 0,
            ZIndex = 2,
            Parent = bar
        })
        corner(knob, 8)

        local hit = make("TextButton", {
            Size = UDim2.new(1, 0, 0, 28),
            Position = UDim2.new(0, 0, 0, 20),
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            Parent = row
        })

        local function setValue(v, fire)
            v = math.clamp(v, minValue, maxValue)
            if step and step > 0 then
                v = math.clamp(minValue + math.floor((v - minValue) / step + 0.5) * step, minValue, maxValue)
            end

            local fraction = (v - minValue) / math.max(maxValue - minValue, 0.0001)
            fill.Size = UDim2.new(fraction, 0, 1, 0)
            knob.Position = UDim2.new(fraction, 0, 0.5, 0)
            valueLabel.Text = string.format(format, v)
            if fire then
                onChange(v)
            end
        end

        setValue(value, false)

        local dragging = false
        track(hit.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
            dragging = true
            local width = math.max(bar.AbsoluteSize.X, 1)
            setValue(minValue + (maxValue - minValue) * math.clamp((input.Position.X - bar.AbsolutePosition.X) / width, 0, 1), true)
        end))
        track(UserInputService.InputChanged:Connect(function(input)
            if not dragging then return end
            if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
            local width = math.max(bar.AbsoluteSize.X, 1)
            setValue(minValue + (maxValue - minValue) * math.clamp((input.Position.X - bar.AbsolutePosition.X) / width, 0, 1), true)
        end))
        track(UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end))
    end

    local function dropdownRow(card, titleText, options, current, onPick)
        local row = make("TextButton", {
            Size = UDim2.new(1, 0, 0, 42),
            BackgroundColor3 = THEME.PillBg,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = takeOrder(card),
            Parent = card
        })
        corner(row, 8)
        local rowStroke = stroke(row, THEME.Border, 1)

        label({
            Size = UDim2.new(1, -145, 1, 0),
            Position = UDim2.new(0, 14, 0, 0),
            Text = titleText,
            Font = Enum.Font.GothamMedium,
            TextSize = 14,
            TextColor3 = THEME.TextPrimary,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = row
        }, row)

        local valueLabel = label({
            Size = UDim2.new(0, 100, 1, 0),
            Position = UDim2.new(1, -125, 0, 0),
            Text = tostring(current),
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextColor3 = THEME.Accent,
            TextXAlignment = Enum.TextXAlignment.Right,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = row
        }, row)

        label({
            Size = UDim2.new(0, 12, 0, 12),
            Position = UDim2.new(1, -18, 0.5, -7),
            Text = "›",
            Font = Enum.Font.GothamBold,
            TextSize = 20,
            TextColor3 = THEME.TextMuted,
            TextXAlignment = Enum.TextXAlignment.Right,
            Parent = row
        }, row)

        track(row.MouseEnter:Connect(function()
            TweenService:Create(row, TWEEN_FAST, { BackgroundColor3 = THEME.SidebarActive }):Play()
            TweenService:Create(rowStroke, TWEEN_FAST, { Color = THEME.BorderActive }):Play()
        end))
        track(row.MouseLeave:Connect(function()
            TweenService:Create(row, TWEEN_FAST, { BackgroundColor3 = THEME.PillBg }):Play()
            TweenService:Create(rowStroke, TWEEN_FAST, { Color = THEME.Border }):Play()
        end))
        track(row.MouseButton1Click:Connect(function()
            playSound("pick")
            openList(titleText, options, current, function(option)
                valueLabel.Text = option
                onPick(option)
            end)
        end))
    end

    local function colorRow(card, titleText, current, onPick)
        local row = make("TextButton", {
            Size = UDim2.new(1, 0, 0, 42),
            BackgroundColor3 = THEME.PillBg,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = takeOrder(card),
            Parent = card
        })
        corner(row, 8)
        local rowStroke = stroke(row, THEME.Border, 1)

        label({
            Size = UDim2.new(1, -70, 1, 0),
            Position = UDim2.new(0, 14, 0, 0),
            Text = titleText,
            Font = Enum.Font.GothamMedium,
            TextSize = 14,
            TextColor3 = THEME.TextPrimary,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = row
        }, row)

        local swatch = make("Frame", {
            Size = UDim2.new(0, 24, 0, 24),
            Position = UDim2.new(1, -40, 0.5, -12),
            BackgroundColor3 = current,
            BorderSizePixel = 0,
            Parent = row
        })
        corner(swatch, 7)
        stroke(swatch, THEME.TextPrimary, 1, 0.6)

        track(row.MouseEnter:Connect(function()
            TweenService:Create(rowStroke, TWEEN_FAST, { Color = THEME.BorderActive }):Play()
        end))
        track(row.MouseLeave:Connect(function()
            TweenService:Create(rowStroke, TWEEN_FAST, { Color = THEME.Border }):Play()
        end))
        track(row.MouseButton1Click:Connect(function()
            playSound("pick")
            openPalette(titleText, current, function(color)
                swatch.BackgroundColor3 = color
                onPick(color)
            end)
        end))
    end

    local function bindRow(card, titleText, key, onChange)
        local row = make("TextButton", {
            Size = UDim2.new(1, 0, 0, 42),
            BackgroundColor3 = THEME.PillBg,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = takeOrder(card),
            Parent = card
        })
        corner(row, 8)
        local rowStroke = stroke(row, THEME.Border, 1)

        label({
            Size = UDim2.new(1, -130, 1, 0),
            Position = UDim2.new(0, 14, 0, 0),
            Text = titleText,
            Font = Enum.Font.GothamMedium,
            TextSize = 14,
            TextColor3 = THEME.TextPrimary,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = row
        }, row)

        local keyPill = make("Frame", {
            Size = UDim2.new(0, 104, 0, 26),
            Position = UDim2.new(1, -118, 0.5, -13),
            BackgroundColor3 = THEME.SidebarActive,
            BorderSizePixel = 0,
            Parent = row
        })
        corner(keyPill, 7)
        stroke(keyPill, THEME.BorderActive, 1, 0.3)

        local keyLabel = label({
            Size = UDim2.new(1, 0, 1, 0),
            Text = key and key.Name or "—",
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextColor3 = THEME.Accent,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = keyPill
        }, keyPill)

        local listening = false
        track(row.MouseEnter:Connect(function()
            TweenService:Create(rowStroke, TWEEN_FAST, { Color = THEME.BorderActive }):Play()
        end))
        track(row.MouseLeave:Connect(function()
            TweenService:Create(rowStroke, TWEEN_FAST, { Color = THEME.Border }):Play()
        end))
        track(row.MouseButton1Click:Connect(function()
            if listening then return end
            listening = true
            keyLabel.Text = "…"

            local conn
            conn = UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
                conn:Disconnect()
                listening = false

                if input.KeyCode == Enum.KeyCode.Escape then
                    key = nil
                else
                    key = input.KeyCode
                end

                keyLabel.Text = key and key.Name or "—"
                playSound("pick")
                onChange(key)
            end)
            track(conn)
        end))
    end

    local function actionRow(card, text, onClick, accent)
        local row = make("TextButton", {
            Size = UDim2.new(1, 0, 0, 42),
            BackgroundColor3 = accent and THEME.AccentDark or THEME.PillBg,
            BackgroundTransparency = accent and 0.55 or 0,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = takeOrder(card),
            Parent = card
        })
        corner(row, 8)
        local rowStroke = stroke(row, accent and THEME.BorderActive or THEME.Border, 1)

        label({
            Size = UDim2.new(1, -24, 1, 0),
            Position = UDim2.new(0, 14, 0, 0),
            Text = text,
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextColor3 = accent and THEME.AccentSoft or THEME.TextMuted,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = row
        }, row)

        track(row.MouseEnter:Connect(function()
            TweenService:Create(row, TWEEN_FAST, { BackgroundTransparency = accent and 0.35 or 0.35 }):Play()
            TweenService:Create(rowStroke, TWEEN_FAST, { Color = THEME.BorderActive }):Play()
        end))
        track(row.MouseLeave:Connect(function()
            TweenService:Create(row, TWEEN_FAST, { BackgroundTransparency = accent and 0.55 or 0 }):Play()
            TweenService:Create(rowStroke, TWEEN_FAST, { Color = accent and THEME.BorderActive or THEME.Border }):Play()
        end))
        track(row.MouseButton1Click:Connect(function()
            playSound("pick")
            onClick()
        end))
    end

    local function noteRow(card, text)
        label({
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = text,
            Font = Enum.Font.Gotham,
            TextSize = 13,
            TextColor3 = THEME.TextMuted,
            TextWrapped = true,
            TextYAlignment = Enum.TextYAlignment.Top,
            LayoutOrder = takeOrder(card),
            Parent = card
        }, card)
    end

    local function listRow(scroll, text, active, onClick, withDot)
        local row = make("TextButton", {
            Size = UDim2.new(1, -6, 0, 36),
            BackgroundColor3 = THEME.PillBg,
            BackgroundTransparency = active and 0 or 0.35,
            Text = text,
            Font = Enum.Font.GothamMedium,
            TextSize = 14,
            TextColor3 = active and THEME.TextPrimary or THEME.TextMuted,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            AutoButtonColor = false,
            Parent = scroll
        })
        corner(row, 8)
        make("UIPadding", {
            PaddingLeft = UDim.new(0, 14),
            PaddingRight = UDim.new(0, withDot and 34 or 14),
            Parent = row
        })
        stroke(row, active and THEME.BorderActive or THEME.Border, 1, active and 0.1 or 0.6)

        local dot = nil
        if withDot then
            dot = make("Frame", {
                Size = UDim2.new(0, 9, 0, 9),
                Position = UDim2.new(1, -22, 0.5, -4),
                BackgroundColor3 = THEME.Accent,
                BackgroundTransparency = active and 0 or 1,
                BorderSizePixel = 0,
                Parent = row
            })
            corner(dot, 5)
        end

        track(row.MouseButton1Click:Connect(function()
            playSound("pick")
            onClick()
        end))

        return row, dot
    end

    local BIND_LABELS = {
        Head = { en = "Head", ru = "Голова" },
        Torso = { en = "Torso", ru = "Торс" },
        Root = { en = "Root", ru = "Корень" },
        Solid = { en = "Solid", ru = "Сплошной" },
        Fade = { en = "Fade", ru = "Затухание" },
        Rainbow = { en = "Rainbow", ru = "Радуга" },
        Dotted = { en = "Dotted", ru = "Точки" },
        Off = { en = "Off", ru = "Выкл" },
        Rain = { en = "Rain", ru = "Дождь" },
        Snow = { en = "Snow", ru = "Снег" },
        Fog = { en = "Fog", ru = "Туман" },
        Dawn = { en = "Dawn", ru = "Рассвет" },
        Day = { en = "Day", ru = "День" },
        Sunset = { en = "Sunset", ru = "Закат" },
        Night = { en = "Night", ru = "Ночь" },
        Midnight = { en = "Midnight", ru = "Полночь" },
        Custom = { en = "Custom", ru = "Своё" }
    }

    local function optLabel(value)
        return BIND_LABELS[value] and tr(BIND_LABELS[value]) or value
    end

    local function labeledDropdown(card, titleText, values, current, onPick)
        local display = {}
        local reverse = {}
        for _, value in ipairs(values) do
            local text = optLabel(value)
            table.insert(display, text)
            reverse[text] = value
        end

        dropdownRow(card, titleText, display, optLabel(current), function(choice)
            onPick(reverse[choice] or choice)
        end)
    end

    local function flatButton(parent, x, y, w, h, text, onClick, accent)
        local button = make("TextButton", {
            Size = UDim2.new(0, w, 0, h),
            Position = UDim2.new(0, x, 0, y),
            BackgroundColor3 = accent and THEME.AccentDark or THEME.PillBg,
            BackgroundTransparency = accent and 0.55 or 0,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            Parent = parent
        })
        corner(button, 8)
        local buttonStroke = stroke(button, accent and THEME.BorderActive or THEME.Border, 1)

        label({
            Size = UDim2.new(1, -16, 1, 0),
            Position = UDim2.new(0, 12, 0, 0),
            Text = text,
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextColor3 = accent and THEME.AccentSoft or THEME.TextMuted,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = button
        }, button)

        track(button.MouseEnter:Connect(function()
            TweenService:Create(button, TWEEN_FAST, { BackgroundTransparency = 0.3 }):Play()
            TweenService:Create(buttonStroke, TWEEN_FAST, { Color = THEME.BorderActive }):Play()
        end))
        track(button.MouseLeave:Connect(function()
            TweenService:Create(button, TWEEN_FAST, { BackgroundTransparency = accent and 0.55 or 0 }):Play()
            TweenService:Create(buttonStroke, TWEEN_FAST, { Color = accent and THEME.BorderActive or THEME.Border }):Play()
        end))
        track(button.MouseButton1Click:Connect(function()
            playSound("pick")
            onClick()
        end))

        return button
    end

    -- =========================================================================
    -- 2. HUD WATERMARK
    -- =========================================================================
    local HudContainer = make("Frame", {
        Name = "HudContainer",
        Size = UDim2.new(0, 720, 0, 76),
        Position = STATE.hudPos,
        BackgroundTransparency = 1,
        Parent = ScreenGui
    })

    local HudScale = make("UIScale", { Scale = STATE.hudScale }, HudContainer)

    make("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        Parent = HudContainer
    })

    local function createHudRow(name, height, order)
        local row = make("Frame", {
            Name = name,
            Size = UDim2.new(1, 0, 0, height),
            BackgroundTransparency = 1,
            LayoutOrder = order,
            Parent = HudContainer
        })

        make("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 7),
            Parent = row
        })

        return row
    end

    local TopHudRow = createHudRow("TopRow", 34, 1)
    local BottomHudRow = createHudRow("BottomRow", 34, 2)

    local function createHudPill(parent, order)
        local pill = make("Frame", {
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.new(0, 0, 1, 0),
            BackgroundColor3 = THEME.PillBg,
            BorderSizePixel = 0,
            LayoutOrder = order,
            Parent = parent
        })

        corner(pill, 7)
        stroke(pill, THEME.Border, 1)

        make("UIPadding", {
            PaddingLeft = UDim.new(0, 9),
            PaddingRight = UDim.new(0, 9),
            Parent = pill
        })

        make("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 7),
            Parent = pill
        })

        return pill
    end

    local function addHudDivider(parent, order)
        make("Frame", {
            Size = UDim2.new(0, 1, 0, 16),
            BackgroundColor3 = THEME.Divider,
            BorderSizePixel = 0,
            LayoutOrder = order,
            Parent = parent
        })
    end

    local function addHudText(parent, text, isMuted, order)
        return label({
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.new(0, 0, 1, 0),
            Text = text,
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            TextColor3 = isMuted and THEME.TextMuted or THEME.TextPrimary,
            LayoutOrder = order,
            Parent = parent
        }, parent)
    end

    local function addHudSmallIcon(parent, iconId, order)
        return icon({
            Size = UDim2.new(0, 15, 0, 15),
            Image = iconId,
            ImageColor3 = THEME.Accent,
            LayoutOrder = order,
            Parent = parent
        }, parent)
    end

    -- Top Row
    local BrandPill = createHudPill(TopHudRow, 1)

    local HudLogoWrap = make("Frame", {
        Size = UDim2.new(0, 26, 0, 26),
        BackgroundTransparency = 1,
        LayoutOrder = 1,
        Parent = BrandPill
    })

    make("ImageLabel", {
        Size = UDim2.new(2, 0, 2, 0),
        Position = UDim2.new(-0.5, 0, -0.5, 0),
        BackgroundTransparency = 1,
        Image = "rbxassetid://5028857084",
        ImageColor3 = THEME.Accent,
        ImageTransparency = 0.65,
        ZIndex = 1,
        Parent = HudLogoWrap
    })

    local HudBrandLogo = icon({
        Size = UDim2.new(1.35, 0, 1.35, 0),
        Position = UDim2.new(-0.175, 0, -0.175, 0),
        Image = CUSTOM_LOGO_ID,
        ImageColor3 = Color3.fromRGB(255, 255, 255),
        ZIndex = 2,
        Parent = HudLogoWrap
    }, HudLogoWrap)

    make("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.0, THEME.AccentSoft),
            ColorSequenceKeypoint.new(0.55, THEME.Accent),
            ColorSequenceKeypoint.new(1.0, THEME.Accent:Lerp(THEME.AccentDark, 0.35))
        }),
        Rotation = -35,
        Parent = HudBrandLogo
    })

    addHudDivider(BrandPill, 2)

    local HudBrandText = addHudText(BrandPill, "Nursultan", false, 3)
    make("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.0, THEME.AccentSoft),
            ColorSequenceKeypoint.new(1.0, THEME.Accent)
        }),
        Parent = HudBrandText
    })

    local HudBrandSuffix = addHudText(BrandPill, loc.client, true, 4)
    HudBrandSuffix.Font = Enum.Font.Gotham
    HudBrandSuffix.TextSize = 11

    local StatsPill = createHudPill(TopHudRow, 2)
    addHudSmallIcon(StatsPill, "rbxassetid://7733954760", 1)
    addHudText(StatsPill, string.lower(LocalPlayer.Name), false, 2)
    addHudDivider(StatsPill, 3)
    addHudSmallIcon(StatsPill, "rbxassetid://7733749837", 4)
    local FpsLabel = addHudText(StatsPill, "0 " .. loc.fps, false, 5)
    addHudDivider(StatsPill, 6)
    addHudSmallIcon(StatsPill, "rbxassetid://7733734762", 7)
    local TimeLabel = addHudText(StatsPill, "00:00:00", false, 8)

    -- Bottom Row
    local PosPill = createHudPill(BottomHudRow, 1)
    addHudSmallIcon(PosPill, "rbxassetid://7733720755", 1)
    addHudDivider(PosPill, 2)
    local PosLabel = addHudText(PosPill, "0, 0, 0", false, 3)

    local PingPill = createHudPill(BottomHudRow, 2)
    addHudSmallIcon(PingPill, "rbxassetid://7734058495", 1)
    addHudDivider(PingPill, 2)
    local PingLabel = addHudText(PingPill, loc.noPing, false, 3)

    local TickPill = createHudPill(BottomHudRow, 3)
    addHudSmallIcon(TickPill, "rbxassetid://7734053426", 1)
    addHudDivider(TickPill, 2)
    local TickLabel = addHudText(TickPill, "20.0 " .. loc.ticks, false, 3)

    local SpeedPill = createHudPill(BottomHudRow, 4)
    addHudSmallIcon(SpeedPill, "rbxassetid://7733799901", 1)
    addHudDivider(SpeedPill, 2)
    local SpeedLabel = addHudText(SpeedPill, "0.0 " .. loc.bps, false, 3)

    -- Live runtime updates
    local fpsCounter = 0
    local lastFpsAt = os.clock()
    local lastClockText = ""
    local lastPingAt = 0
    local lastMoveAt = 0
    local lastPosition = Vector3.zero
    local pingStat = nil

    pcall(function()
        if Stats.Network and Stats.Network.ServerStatsItem then
            pingStat = Stats.Network.ServerStatsItem["Data Ping"]
        end
    end)

    track(RunService.RenderStepped:Connect(function()
        local l = L()

        fpsCounter += 1
        local now = os.clock()

        if now - lastFpsAt >= 1 then
            FpsLabel.Text = string.format("%d %s", fpsCounter, l.fps)
            fpsCounter = 0
            lastFpsAt = now
        end

        local clockText = os.date("%H:%M:%S")
        if clockText ~= lastClockText then
            TimeLabel.Text = clockText
            lastClockText = clockText
        end

        if now - lastPingAt >= 1 then
            lastPingAt = now
            local ping
            if pingStat then
                local ok, value = pcall(function() return pingStat:GetValue() end)
                if ok and type(value) == "number" then ping = math.floor(value) end
            end
            PingLabel.Text = ping and string.format("%d %s", ping, l.ping) or l.noPing
        end

        local character = LocalPlayer.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local currentPos = hrp.Position
            PosLabel.Text = string.format("%d, %d, %d", math.floor(currentPos.X), math.floor(currentPos.Y), math.floor(currentPos.Z))

            if now - lastMoveAt >= 0.1 then
                local delta = now - lastMoveAt
                local flatNow = Vector3.new(currentPos.X, 0, currentPos.Z)
                local flatLast = Vector3.new(lastPosition.X, 0, lastPosition.Z)
                local moved = (flatNow - flatLast).Magnitude
                local bps = (moved > 0.01 and delta > 0) and (moved / delta) or 0
                SpeedLabel.Text = string.format("%.1f %s", bps, l.bps)
                lastPosition = currentPos
                lastMoveAt = now
            end
        else
            PosLabel.Text = "0, 0, 0"
            SpeedLabel.Text = "0.0 " .. l.bps
            lastPosition = Vector3.zero
        end
    end))

    -- HUD dragging (InputBegan bubbles from pills)
    do
        local dragging = false
        local dragStart, startPos

        track(HudContainer.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            dragging = true
            dragStart = input.Position
            startPos = HudContainer.Position
        end))

        track(UserInputService.InputChanged:Connect(function(input)
            if not dragging or input.UserInputType ~= Enum.UserInputType.MouseMovement then return end

            local delta = input.Position - dragStart
            local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
            local size = HudContainer.AbsoluteSize

            local x = math.clamp(startPos.X.Offset + delta.X, -size.X + 60, vp.X - 60)
            local y = math.clamp(startPos.Y.Offset + delta.Y, -size.Y + 30, vp.Y - 30)
            HudContainer.Position = UDim2.new(0, x, 0, y)
            STATE.hudPos = HudContainer.Position
        end))

        track(UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end))
    end

    -- =========================================================================
    -- 2. MAIN WINDOW
    -- =========================================================================
    local Main = make("Frame", {
        Name = "MainFrame",
        Size = UDim2.new(0, 790, 0, 490),
        Position = STATE.mainPos,
        BackgroundColor3 = THEME.Background,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        Visible = STATE.shown,
        Parent = ScreenGui
    })
    corner(Main, 12)
    stroke(Main, THEME.Border, 1.2)

    local GuiScale = make("UIScale", { Scale = STATE.guiScale }, Main)

    local GlowBackdrop = make("ImageLabel", {
        Name = "GlowBackdrop",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, -45, 0, -45),
        Size = UDim2.new(1, 90, 1, 90),
        ZIndex = 0,
        Image = "rbxassetid://5028857084",
        ImageColor3 = THEME.AccentDark,
        ImageTransparency = STATE.shown and 0.83 or 1,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(24, 24, 276, 276),
        Parent = Main
    })

    -- Top Bar
    local TopBar = make("Frame", {
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundTransparency = 1,
        Parent = Main
    })

    -- Logo
    local MainLogoHolder = make("Frame", {
        Name = "LogoHolder",
        Size = UDim2.new(0, 64, 0, 64),
        Position = UDim2.new(0, 52, 0, -4),
        BackgroundTransparency = 1,
        Parent = TopBar
    })

    make("ImageLabel", {
        Name = "Halo",
        Size = UDim2.new(2.1, 0, 2.1, 0),
        Position = UDim2.new(-0.55, 0, -0.55, 0),
        BackgroundTransparency = 1,
        Image = "rbxassetid://5028857084",
        ImageColor3 = THEME.Accent,
        ImageTransparency = 0.58,
        ZIndex = 1,
        Parent = MainLogoHolder
    })

    icon({
        Name = "LogoShadow",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 2, 0, 2),
        Image = CUSTOM_LOGO_ID,
        ImageColor3 = THEME.AccentDark,
        ImageTransparency = 0.2,
        ZIndex = 2,
        Parent = MainLogoHolder
    }, MainLogoHolder)

    local MainLogoImg = icon({
        Name = "LogoMain",
        Size = UDim2.new(1, 0, 1, 0),
        Image = CUSTOM_LOGO_ID,
        ImageColor3 = Color3.fromRGB(255, 255, 255),
        ZIndex = 3,
        Parent = MainLogoHolder
    }, MainLogoHolder)

    make("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.0, THEME.AccentSoft),
            ColorSequenceKeypoint.new(0.55, THEME.Accent),
            ColorSequenceKeypoint.new(1.0, THEME.Accent:Lerp(THEME.AccentDark, 0.35))
        }),
        Rotation = -35,
        Parent = MainLogoImg
    })

    -- Dedication under the logo
    label({
        Size = UDim2.new(0, 166, 0, 14),
        Position = UDim2.new(0, 1, 0, 60),
        Text = "С любовью от Наташи для Артёма",
        Font = Enum.Font.GothamMedium,
        TextSize = 8,
        TextColor3 = THEME.TextMuted,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 4,
        Parent = TopBar
    }, TopBar)

    -- Search
    local SearchBox = make("Frame", {
        Size = UDim2.new(0, 250, 0, 26),
        Position = UDim2.new(0, 185, 0, 15),
        BackgroundColor3 = THEME.CardBg,
        BorderSizePixel = 0,
        Parent = TopBar
    })
    corner(SearchBox, 6)
    stroke(SearchBox, THEME.Border, 0.8)

    icon({
        Size = UDim2.new(0, 13, 0, 13),
        Position = UDim2.new(0, 9, 0.5, -6.5),
        Image = "rbxassetid://7733911828",
        ImageColor3 = THEME.TextMuted,
        Parent = SearchBox
    }, SearchBox)

    make("TextBox", {
        PlaceholderText = loc.search,
        PlaceholderColor3 = THEME.TextMuted,
        TextColor3 = THEME.TextPrimary,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        Position = UDim2.new(0, 30, 0, 0),
        Size = UDim2.new(1, -36, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = SearchBox
    })

    -- "UI ONLY" badge
    local OnlyBadge = make("Frame", {
        Size = UDim2.new(0, 66, 0, 26),
        Position = UDim2.new(1, -108, 0, 15),
        BackgroundColor3 = THEME.BadgeBg,
        BorderSizePixel = 0,
        Parent = TopBar
    })
    corner(OnlyBadge, 6)
    stroke(OnlyBadge, THEME.BorderActive, 0.8)
    label({
        Size = UDim2.new(1, 0, 1, 0),
        Text = loc.badge,
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        TextColor3 = THEME.Accent,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = OnlyBadge
    }, OnlyBadge)

    -- Menu button
    local MenuBtn = make("ImageButton", {
        Size = UDim2.new(0, 17, 0, 17),
        Position = UDim2.new(1, -32, 0.5, -8.5),
        BackgroundTransparency = 1,
        Image = "rbxassetid://7733993211",
        ImageColor3 = THEME.TextMuted,
        AutoButtonColor = false,
        Parent = TopBar
    })

    track(MenuBtn.MouseEnter:Connect(function()
        TweenService:Create(MenuBtn, TWEEN_FAST, { ImageColor3 = THEME.TextPrimary }):Play()
    end))
    track(MenuBtn.MouseLeave:Connect(function()
        TweenService:Create(MenuBtn, TWEEN_FAST, { ImageColor3 = THEME.TextMuted }):Play()
    end))

    -- Dragging (top bar only)
    do
        local dragging = false
        local dragStart, startPos

        track(Main.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            if input.Position.Y - Main.AbsolutePosition.Y > 56 then return end
            if pointIn(SearchBox, input.Position) or pointIn(MenuBtn, input.Position) then return end

            dragging = true
            dragStart = input.Position
            startPos = Main.Position
        end))

        track(UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                Main.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
                STATE.mainPos = Main.Position
            end
        end))

        track(UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end))
    end

    -- Sidebar
    local Sidebar = make("Frame", {
        Size = UDim2.new(0, 155, 1, -80),
        Position = UDim2.new(0, 14, 0, 76),
        BackgroundTransparency = 1,
        Parent = Main
    })

    make("UIListLayout", {
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = Sidebar
    })

    label({
        Size = UDim2.new(1, 0, 0, 20),
        LayoutOrder = 100,
        Text = "   " .. loc.features,
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        TextColor3 = THEME.TextDim,
        Parent = Sidebar
    }, Sidebar)

    -- Pages
    local PAGES = {
        { id = "profile", icon = "rbxassetid://7733954760" },
        { id = "combat", icon = "rbxassetid://7734053426" },
        { id = "movement", icon = "rbxassetid://7733799901" },
        { id = "visuals", icon = "rbxassetid://7733774602" },
        { id = "animations", icon = "rbxassetid://7733993211" },
        { id = "auras", icon = "rbxassetid://7733774602" },
        { id = "misc", icon = "rbxassetid://7734056411" }
    }

    local PageButtons = {}
    local Pages = {}
    local currentPage = nil
    local pageBuilders
    local ensurePage

    local function selectPage(id)
        if not pageBuilders[id] then
            id = PAGES[1].id
        end
        if not Pages[id] then
            ensurePage(id)
        end
        currentPage = id
        STATE.page = id

        for pageId, frame in pairs(Pages) do
            frame.Visible = (pageId == id)
        end

        for pageId, btn in pairs(PageButtons) do
            local active = (pageId == id)
            btn.Btn.BackgroundTransparency = active and 0 or 1
            btn.Stroke.Transparency = active and 0 or 1
            btn.Stroke.Color = active and THEME.BorderActive or THEME.Border
            btn.Icon.ImageColor3 = active and THEME.Accent or THEME.TextMuted
            btn.Title.TextColor3 = active and THEME.TextPrimary or THEME.TextMuted
        end
    end

    for index, page in ipairs(PAGES) do
        local btn = make("TextButton", {
            Size = UDim2.new(1, -4, 0, 29),
            BackgroundColor3 = THEME.SidebarActive,
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = 100 + index,
            Parent = Sidebar
        })
        corner(btn, 6)

        local btnStroke = stroke(btn, THEME.Border, 1, 1)
        local btnIcon = icon({
            Size = UDim2.new(0, 14, 0, 14),
            Position = UDim2.new(0, 9, 0.5, -7),
            Image = page.icon,
            ImageColor3 = THEME.TextMuted,
            Parent = btn
        }, btn)
        local btnTitle = label({
            Size = UDim2.new(1, -32, 1, 0),
            Position = UDim2.new(0, 30, 0, 0),
            Text = loc.pages[page.id] or page.id,
            TextSize = 11,
            TextColor3 = THEME.TextMuted,
            Parent = btn
        }, btn)

        PageButtons[page.id] = { Btn = btn, Icon = btnIcon, Title = btnTitle, Stroke = btnStroke }

        track(btn.MouseEnter:Connect(function()
            if currentPage ~= page.id then
                TweenService:Create(btnTitle, TWEEN_FAST, { TextColor3 = THEME.TextPrimary }):Play()
                TweenService:Create(btnIcon, TWEEN_FAST, { ImageColor3 = THEME.TextPrimary }):Play()
            end
        end))
        track(btn.MouseLeave:Connect(function()
            if currentPage ~= page.id then
                TweenService:Create(btnTitle, TWEEN_FAST, { TextColor3 = THEME.TextMuted }):Play()
                TweenService:Create(btnIcon, TWEEN_FAST, { ImageColor3 = THEME.TextMuted }):Play()
            end
        end))
        track(btn.MouseButton1Click:Connect(function()
            selectPage(page.id)
        end))
    end

    -- Content area
    local ContentArea = make("Frame", {
        Size = UDim2.new(1, -195, 1, -62),
        Position = UDim2.new(0, 182, 0, 54),
        BackgroundTransparency = 1,
        Parent = Main
    })

    -- Shared card frame
    local function createCard(parent, x, y, w, h, titleText, subtitleText)
        local card = make("Frame", {
            Size = UDim2.new(0, w, 0, h),
            Position = UDim2.new(0, x, 0, y),
            BackgroundColor3 = THEME.CardBg,
            BorderSizePixel = 0,
            Parent = parent
        })
        corner(card, 10)
        stroke(card, THEME.Border, 1)

        local tick = make("Frame", {
            Size = UDim2.new(0, 4, 0, 16),
            Position = UDim2.new(0, 12, 0, 14),
            BackgroundColor3 = THEME.Accent,
            BorderSizePixel = 0,
            Parent = card
        })
        corner(tick, 2)

        label({
            Size = UDim2.new(1, -44, 0, 18),
            Position = UDim2.new(0, 24, 0, 12),
            Text = titleText,
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextColor3 = THEME.TextPrimary,
            Parent = card
        }, card)

        local dividerY = 40
        if subtitleText then
            label({
                Size = UDim2.new(1, -44, 0, 14),
                Position = UDim2.new(0, 24, 0, 30),
                Text = subtitleText,
                Font = Enum.Font.Gotham,
                TextSize = 10,
                TextColor3 = THEME.TextMuted,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = card
            }, card)
            dividerY = 48
        end

        make("Frame", {
            Size = UDim2.new(1, -24, 0, 1),
            Position = UDim2.new(0, 12, 0, dividerY),
            BackgroundColor3 = THEME.Divider,
            BorderSizePixel = 0,
            Parent = card
        })

        return card
    end

    local function createScrollPage(page)
        local frame = make("Frame", {
            Name = page.id,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Visible = false,
            Parent = ContentArea
        })

        local scroll = make("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = THEME.Border,
            ScrollBarImageTransparency = 0.25,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            Parent = frame
        })
        make("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = scroll
        })
        make("UIPadding", {
            PaddingRight = UDim.new(0, 6),
            PaddingBottom = UDim.new(0, 4),
            Parent = scroll
        })

        return frame, scroll
    end

    local function createCombatPage(page)
        local frame, scroll = createScrollPage(page)

        local aimCard = sectionCard(scroll,
            tr({ en = "Aimbot", ru = "Аимбот" }),
            tr({ en = "hold the bind to smoothly lock onto the closest target", ru = "удерживай клавишу, чтобы плавно наводиться на ближайшую цель" }))

        toggleRow(aimCard,
            tr({ en = "Aimbot", ru = "Аимбот" }),
            tr({ en = "camera assist with smooth tracking", ru = "помощь камере с плавным следованием" }),
            S.aimbot,
            function(value)
                S.aimbot = value
                if not value then aiming = false end
            end)

        bindRow(aimCard, tr({ en = "Aim key", ru = "Клавиша аима" }), aimBind, function(key)
            aimBind = key
        end)

        labeledDropdown(aimCard,
            tr({ en = "Aim part", ru = "Часть прицеливания" }),
            { "Head", "Torso", "Root" },
            S.aimPart,
            function(value) S.aimPart = value end)

        sliderRow(aimCard,
            tr({ en = "FOV radius", ru = "Радиус FOV" }),
            40, 600, S.fov, 10, "%d px",
            function(value) S.fov = value end)

        sliderRow(aimCard,
            tr({ en = "Aim speed", ru = "Скорость наведения" }),
            5, 100, S.aimSpeed, 5, "%d%%",
            function(value) S.aimSpeed = value end)

        toggleRow(aimCard,
            tr({ en = "Wall check", ru = "Проверка стен" }),
            tr({ en = "ignore targets behind walls", ru = "игнорировать цели за стенами" }),
            S.wallCheck,
            function(value) S.wallCheck = value end)

        toggleRow(aimCard,
            tr({ en = "Team check", ru = "Проверка команды" }),
            tr({ en = "skip teammates", ru = "пропускать союзников" }),
            S.teamCheck,
            function(value) S.teamCheck = value end)

        toggleRow(aimCard,
            tr({ en = "Show FOV", ru = "Показывать FOV" }),
            tr({ en = "draw the aiming circle", ru = "рисовать круг прицеливания" }),
            S.showFov,
            function(value) S.showFov = value end)

        colorRow(aimCard, tr({ en = "FOV color", ru = "Цвет FOV" }), S.fovColor, function(color)
            S.fovColor = color
        end)

        local espCard = sectionCard(scroll, "ESP",
            tr({ en = "player highlight and name tags", ru = "подсветка игроков и ники" }))

        toggleRow(espCard,
            tr({ en = "Player ESP", ru = "ESP игроков" }),
            tr({ en = "highlight players and show their names", ru = "подсвечивать игроков и показывать ники" }),
            S.esp,
            function(value)
                if value then
                    espEnable()
                else
                    espDisable()
                end
            end)

        local trigCard = sectionCard(scroll,
            tr({ en = "Triggerbot", ru = "Триггербот" }),
            tr({ en = "automatic shooting", ru = "автоматическая стрельба" }))

        toggleRow(trigCard,
            tr({ en = "Triggerbot", ru = "Триггербот" }),
            tr({ en = "shoot when the crosshair is on a player", ru = "стрелять, когда прицел на игроке" }),
            S.trigger,
            function(value) S.trigger = value end)

        local hitboxCard = sectionCard(scroll,
            tr({ en = "Hitbox", ru = "Хитбокс" }),
            tr({ en = "bigger hitboxes for easier hits", ru = "увеличенные хитбоксы для попаданий" }))

        toggleRow(hitboxCard,
            tr({ en = "Hitbox expander", ru = "Расширение хитбокса" }),
            tr({ en = "enlarge hitboxes of other players", ru = "увеличивать хитбоксы других игроков" }),
            S.hitbox,
            function(value)
                S.hitbox = value
                if not value then
                    restoreHitboxes()
                end
            end)

        sliderRow(hitboxCard,
            tr({ en = "Hitbox size", ru = "Размер хитбокса" }),
            2, 20, S.hitboxSize, 1, "%.0f",
            function(value) S.hitboxSize = value end)

        actionRow(hitboxCard, tr({ en = "Restore hitboxes", ru = "Вернуть хитбоксы" }), function()
            restoreHitboxes()
            notify(tr({ en = "Hitboxes restored", ru = "Хитбоксы восстановлены" }))
        end)

        local screenStretchCard = sectionCard(scroll,
            tr({ en = "Screen stretch", ru = "Растяг экрана" }),
            tr({ en = "stretch the image for a wider view", ru = "растягивать изображение для более широкого обзора" }))

        toggleRow(screenStretchCard,
            tr({ en = "Screen stretch", ru = "Растяг экрана" }),
            tr({ en = "stretch the screen horizontally", ru = "растягивать экран по горизонтали" }),
            S.screenStretch,
            function(value) S.screenStretch = value end)

        sliderRow(screenStretchCard,
            tr({ en = "Stretch strength", ru = "Сила растяга" }),
            1, 2, S.screenStretchPower, 0.05, "%.2fx",
            function(value) S.screenStretchPower = value end)

        Pages[page.id] = frame
    end

    local function createMovementPage(page)
        local frame, scroll = createScrollPage(page)

        local moveCard = sectionCard(scroll,
            tr({ en = "Movement", ru = "Движение" }),
            tr({ en = "client-side movement helpers", ru = "клиентские помощники движения" }))

        toggleRow(moveCard,
            tr({ en = "Noclip", ru = "Ноклип" }),
            tr({ en = "walk through walls and objects", ru = "проходить сквозь стены и объекты" }),
            S.noclip,
            function(value) setNoclip(value) end)

        toggleRow(moveCard,
            tr({ en = "Invisibility", ru = "Невидимость" }),
            tr({ en = "hide your character (works in most games)", ru = "скрыть персонажа (работает в большинстве игр)" }),
            S.invis,
            function(value)
                task.spawn(function()
                    setInvisible(value)
                end)
            end)

        toggleRow(moveCard,
            tr({ en = "Bunny hop", ru = "Банни хоп" }),
            tr({ en = "automatic jumps with speed boost", ru = "авто-прыжки с ускорением" }),
            S.bunnyhop,
            function(value)
                S.bunnyhop = value
                if value then
                    task.spawn(startBunnyHop)
                else
                    stopBunnyHop()
                end
            end)

        noteRow(moveCard,
            tr({ en = "Noclip and invisibility may be blocked by some games. Turn them off before leaving the server.", ru = "Ноклип и невидимость могут блокироваться в некоторых играх. Выключи их перед выходом с сервера." }))

        Pages[page.id] = frame
    end

    local function createVisualsPage(page)
        local frame, scroll = createScrollPage(page)

        local fxCard = sectionCard(scroll,
            tr({ en = "Effects", ru = "Эффекты" }),
            tr({ en = "visual effects around your character", ru = "визуальные эффекты вокруг персонажа" }))

        toggleRow(fxCard,
            tr({ en = "Trail", ru = "Трейл" }),
            tr({ en = "beautiful trail behind your character", ru = "красивый след за персонажем" }),
            S.trail,
            function(value) S.trail = value end)

        labeledDropdown(fxCard,
            tr({ en = "Trail style", ru = "Стиль трейла" }),
            { "Solid", "Fade", "Rainbow", "Dotted" },
            S.trailStyle,
            function(value)
                S.trailStyle = value
                updateTrailAppearance()
            end)

        colorRow(fxCard, tr({ en = "Trail color", ru = "Цвет трейла" }), S.trailColor, function(color)
            S.trailColor = color
            updateTrailAppearance()
        end)

        toggleRow(fxCard,
            tr({ en = "Magic aura", ru = "Магическая аура" }),
            tr({ en = "orbiting neon spheres", ru = "летающие неоновые сферы" }),
            S.magicAura,
            function(value) S.magicAura = value end)

        toggleRow(fxCard,
            tr({ en = "RTX shader", ru = "RTX шейдер" }),
            tr({ en = "cinematic lighting and skybox", ru = "кинематографичный свет и скайбокс" }),
            S.rtx,
            function(value)
                if value then
                    enableRTX()
                else
                    disableRTX()
                end
            end)

        toggleRow(fxCard,
            tr({ en = "China hat", ru = "Китайская шляпа" }),
            tr({ en = "neon cone hat with glow", ru = "неоновая шляпа со свечением" }),
            S.chinaHat,
            function(value)
                S.chinaHat = value
                updateChinaHat()
            end)

        colorRow(fxCard, tr({ en = "Hat color", ru = "Цвет шляпы" }), S.chinaHatColor, function(color)
            S.chinaHatColor = color
            if S.chinaHat then
                updateChinaHat()
            end
        end)

        sliderRow(fxCard,
            tr({ en = "Hat height", ru = "Высота шляпы" }),
            -1, 3, S.chinaHatHeight, 0.1, "%.1f",
            function(value)
                S.chinaHatHeight = value
                local character = LocalPlayer.Character
                local hat = character and character:FindFirstChild("nursultanChinaHat")
                local weld = hat and hat:FindFirstChildOfClass("Weld")
                if weld then
                    weld.C0 = CFrame.new(0, value, 0)
                end
            end)

        local avatarCard = sectionCard(scroll,
            tr({ en = "Avatar", ru = "Аватар" }),
            tr({ en = "effects bound to your jumps", ru = "эффекты, привязанные к прыжкам" }))

        toggleRow(avatarCard,
            tr({ en = "Jump circle", ru = "Круг прыжка" }),
            tr({ en = "ring effect on every jump", ru = "эффект кольца при каждом прыжке" }),
            S.jumpCircle,
            function(value) S.jumpCircle = value end)

        colorRow(avatarCard, tr({ en = "Jump circle color", ru = "Цвет круга" }), S.jumpCircleColor, function(color)
            S.jumpCircleColor = color
        end)

        local envCard = sectionCard(scroll,
            tr({ en = "Environment", ru = "Окружение" }),
            tr({ en = "weather, time and sky", ru = "погода, время и небо" }))

        labeledDropdown(envCard,
            tr({ en = "Weather", ru = "Погода" }),
            { "Off", "Rain", "Snow", "Fog" },
            S.weather,
            function(value)
                S.weather = value
                applyWeather()
            end)

        labeledDropdown(envCard,
            tr({ en = "Time of day", ru = "Время суток" }),
            { "Off", "Dawn", "Day", "Sunset", "Night", "Midnight", "Custom" },
            S.timeMode,
            function(value) S.timeMode = value end)

        sliderRow(envCard,
            tr({ en = "Custom hour", ru = "Свой час" }),
            0, 24, S.timeValue, 1, "%d:00",
            function(value)
                S.timeValue = value
                if S.timeMode == "Custom" then
                    pcall(function() Lighting.ClockTime = value end)
                end
            end)

        local skyCard = sectionCard(scroll,
            tr({ en = "Skyboxes", ru = "Скайбоксы" }),
            tr({ en = "8 skies — tap to apply", ru = "8 небес — нажми, чтобы применить" }))

        for _, sky in ipairs(SKYBOXES) do
            actionRow(skyCard, sky.name, function()
                loadSkybox(sky.id, sky.name)
            end)
        end

        actionRow(skyCard, tr({ en = "Remove skybox", ru = "Убрать скайбокс" }), function()
            removeSkybox()
        end, true)

        local targetCard = sectionCard(scroll,
            tr({ en = "Target", ru = "Цель" }),
            tr({ en = "visuals for the closest player", ru = "визуал ближайшего игрока" }))

        toggleRow(targetCard,
            tr({ en = "Target ESP", ru = "ESP цели" }),
            tr({ en = "rotating corners around the target", ru = "вращающиеся углы вокруг цели" }),
            S.targetEsp,
            function(value) S.targetEsp = value end)

        toggleRow(targetCard,
            tr({ en = "Target HUD", ru = "HUD цели" }),
            tr({ en = "avatar and health of the target", ru = "аватар и здоровье цели" }),
            S.targetHud,
            function(value) S.targetHud = value end)

        Pages[page.id] = frame
    end

    local function createAnimationsPage(page)
        local frame = make("Frame", {
            Name = page.id,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Visible = false,
            Parent = ContentArea
        })

        -- Emotes
        local emoteCard = createCard(frame, 0, 0, 340, 428, loc.emotes)
        local emoteSearch = styledSearch(emoteCard, 10, 50, 320, loc.emoteSearch)

        local emoteScroll = make("ScrollingFrame", {
            Size = UDim2.new(0, 320, 0, 290),
            Position = UDim2.new(0, 10, 0, 92),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = THEME.Border,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            Parent = emoteCard
        })
        make("UIListLayout", {
            Padding = UDim.new(0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = emoteScroll
        })

        local emoteEntries = {}
        for index, emoteName in ipairs(emoteNames) do
            local row = listRow(emoteScroll, emoteName, false, function()
                playEmote(emoteName)
                notify(emoteName)
            end)
            row.LayoutOrder = index
            table.insert(emoteEntries, { Button = row, Name = string.lower(emoteName) })
        end

        track(emoteSearch:GetPropertyChangedSignal("Text"):Connect(function()
            local query = string.lower(emoteSearch.Text)
            for _, entry in ipairs(emoteEntries) do
                entry.Button.Visible = query == "" or string.find(entry.Name, query, 1, true) ~= nil
            end
        end))

        flatButton(emoteCard, 10, 390, 320, 32, tr({ en = "Stop animation", ru = "Остановить анимацию" }), function()
            stopEmotes()
            notify(tr({ en = "Animation stopped", ru = "Анимация остановлена" }))
        end)

        -- Animation packs
        local packCard = createCard(frame, 352, 0, 243, 428, loc.packs)
        local packSearch = styledSearch(packCard, 10, 50, 223, loc.packSearch)

        local packScroll = make("ScrollingFrame", {
            Size = UDim2.new(0, 223, 0, 290),
            Position = UDim2.new(0, 10, 0, 92),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = THEME.Border,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            Parent = packCard
        })
        make("UIListLayout", {
            Padding = UDim.new(0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = packScroll
        })

        local packEntries = {}
        for index, packName in ipairs(animationNames) do
            local row = listRow(packScroll, packName, false, function()
                local pack = ANIMATIONS[packName]
                if pack then
                    saveOriginalAnims()
                    playAnimationBody(pack)
                    task.spawn(refreshAnims)
                    notify(packName)
                end
            end)
            row.LayoutOrder = index
            table.insert(packEntries, { Button = row, Name = string.lower(packName) })
        end

        track(packSearch:GetPropertyChangedSignal("Text"):Connect(function()
            local query = string.lower(packSearch.Text)
            for _, entry in ipairs(packEntries) do
                entry.Button.Visible = query == "" or string.find(entry.Name, query, 1, true) ~= nil
            end
        end))

        flatButton(packCard, 10, 390, 223, 32, tr({ en = "Reset animation", ru = "Сбросить анимацию" }), function()
            resetAnimation()
            notify(tr({ en = "Animation reset", ru = "Анимация сброшена" }))
        end)

        Pages[page.id] = frame
    end

    local function createAurasPage(page)
        local frame = make("Frame", {
            Name = page.id,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Visible = false,
            Parent = ContentArea
        })

        local auraCard = createCard(frame, 0, 0, 350, 428, loc.auras,
            tr({ en = "tap to apply, tap again to remove", ru = "нажми, чтобы надеть, ещё раз — снять" }))

        local auraScroll = make("ScrollingFrame", {
            Size = UDim2.new(0, 330, 0, 306),
            Position = UDim2.new(0, 10, 0, 52),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = THEME.Border,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            Parent = auraCard
        })
        make("UIListLayout", {
            Padding = UDim.new(0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = auraScroll
        })

        local rows = {}
        local dots = {}

        local function refreshAuras()
            for name, row in pairs(rows) do
                local active = (auraName == name)
                row.BackgroundTransparency = active and 0 or 0.35
                row.TextColor3 = active and THEME.TextPrimary or THEME.TextMuted
                dots[name].BackgroundTransparency = active and 0 or 1
            end
        end

        for index, aura in ipairs(AURAS) do
            local row, dot = listRow(auraScroll, aura.name, auraName == aura.name, function()
                applyAura(aura.id, aura.name)
                refreshAuras()
            end, true)
            row.LayoutOrder = index
            rows[aura.name] = row
            dots[aura.name] = dot
        end

        flatButton(auraCard, 10, 368, 330, 34, loc.removeAura, function()
            clearAura()
            refreshAuras()
            notify(tr({ en = "Aura removed", ru = "Аура снята" }))
        end, true)

        Pages[page.id] = frame
    end

    -- Profile page: banner + Server / Executor / Friends
    local function createProfilePage(page)
        local frame = make("Frame", {
            Name = page.id,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Visible = false,
            Parent = ContentArea
        })

        -- Floating toast
        local function toast(text)
            local t = make("TextLabel", {
                AutomaticSize = Enum.AutomaticSize.X,
                Size = UDim2.new(0, 0, 0, 30),
                AnchorPoint = Vector2.new(0.5, 0),
                Position = UDim2.new(0.5, 0, 1, -96),
                BackgroundColor3 = THEME.CardBg,
                BackgroundTransparency = 1,
                Text = text,
                Font = Enum.Font.GothamBold,
                TextSize = 10,
                TextColor3 = THEME.TextPrimary,
                TextTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 60,
                Parent = ScreenGui
            })
            corner(t, 8)
            stroke(t, THEME.Border, 1)

            make("UIPadding", {
                PaddingLeft = UDim.new(0, 16),
                PaddingRight = UDim.new(0, 16),
                PaddingTop = UDim.new(0, 8),
                PaddingBottom = UDim.new(0, 8),
                Parent = t
            })

            TweenService:Create(t, TWEEN_FAST, { TextTransparency = 0, BackgroundTransparency = 0.05 }):Play()

            task.delay(1.6, function()
                pcall(function()
                    local out = TweenService:Create(t, TWEEN_FAST, { TextTransparency = 1, BackgroundTransparency = 1 })
                    out.Completed:Connect(function()
                        t:Destroy()
                    end)
                    out:Play()
                end)
            end)
        end

        local function copyJobId()
            local jobId = game.JobId
            if type(jobId) ~= "string" or jobId == "" then
                jobId = "—"
            end

            local ok = false
            if setclipboard then
                ok = pcall(function() setclipboard(jobId) end)
            end
            if not ok and syn and syn.write_clipboard then
                ok = pcall(function() syn.write_clipboard(jobId) end)
            end

            toast(ok and loc.copied or loc.noClipboard)
        end

        -- Banner
        local banner = make("Frame", {
            Size = UDim2.new(1, 0, 0, 74),
            BackgroundColor3 = THEME.CardBg,
            BorderSizePixel = 0,
            Parent = frame
        })
        corner(banner, 10)
        stroke(banner, THEME.Border, 1)

        local avatarHolder = make("Frame", {
            Size = UDim2.new(0, 56, 0, 56),
            Position = UDim2.new(0, 10, 0, 9),
            BackgroundColor3 = THEME.PillBg,
            BorderSizePixel = 0,
            Parent = banner
        })
        corner(avatarHolder, 9)
        stroke(avatarHolder, THEME.BorderActive, 1)

        local avatarImage = icon({
            Size = UDim2.new(1, 0, 1, 0),
            Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LocalPlayer.UserId) .. "&w=150&h=150",
            ScaleType = Enum.ScaleType.Crop,
            Parent = avatarHolder
        }, avatarHolder)
        corner(avatarImage, 9)

        local helloOk, helloText = pcall(string.format, loc.hello, LocalPlayer.DisplayName)
        if not helloOk then
            helloText = LocalPlayer.DisplayName
        end

        label({
            Size = UDim2.new(1, -100, 0, 22),
            Position = UDim2.new(0, 78, 0, 13),
            Text = helloText,
            Font = Enum.Font.GothamBold,
            TextSize = 15,
            TextColor3 = THEME.TextPrimary,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = banner
        }, banner)

        label({
            Size = UDim2.new(1, -100, 0, 16),
            Position = UDim2.new(0, 78, 0, 36),
            Text = LocalPlayer.Name .. " — Nursultan client",
            Font = Enum.Font.Gotham,
            TextSize = 10,
            TextColor3 = THEME.TextMuted,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = banner
        }, banner)

        -- Server card
        local serverCard = createCard(frame, 0, 86, 340, 324, loc.server, loc.serverSub)

        local function addInfoTile(x, y, w, h, titleText, valueText, onClick)
            local props = {
                Size = UDim2.new(0, w, 0, h),
                Position = UDim2.new(0, x, 0, y),
                BackgroundColor3 = onClick and THEME.SidebarActive or THEME.PillBg,
                BorderSizePixel = 0,
                Parent = serverCard
            }
            if onClick then
                props.Text = ""
                props.AutoButtonColor = false
            end

            local tile = make(onClick and "TextButton" or "Frame", props)
            corner(tile, 7)
            local tileStroke = stroke(tile, THEME.Border, 1)

            label({
                Size = UDim2.new(1, -20, 0, 13),
                Position = UDim2.new(0, 10, 0, 11),
                Text = titleText,
                Font = Enum.Font.GothamBold,
                TextSize = 9.5,
                TextColor3 = THEME.TextPrimary,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = tile
            }, tile)

            local valueLabel = label({
                Size = UDim2.new(1, -20, 0, 14),
                Position = UDim2.new(0, 10, 0, 29),
                Text = valueText,
                Font = Enum.Font.Gotham,
                TextSize = 9,
                TextColor3 = THEME.TextMuted,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = tile
            }, tile)

            if onClick then
                track(tile.MouseEnter:Connect(function()
                    TweenService:Create(tile, TWEEN_FAST, { BackgroundColor3 = THEME.CardBg }):Play()
                    TweenService:Create(tileStroke, TWEEN_FAST, { Color = THEME.BorderActive }):Play()
                end))
                track(tile.MouseLeave:Connect(function()
                    TweenService:Create(tile, TWEEN_FAST, { BackgroundColor3 = THEME.SidebarActive }):Play()
                    TweenService:Create(tileStroke, TWEEN_FAST, { Color = THEME.Border }):Play()
                end))
                track(tile.MouseButton1Click:Connect(onClick))
            end

            return valueLabel
        end

        local PlayersValue = addInfoTile(10, 56, 154, 80, loc.players, string.format(loc.playingFmt, #Players:GetPlayers()))
        addInfoTile(176, 56, 154, 80, loc.maxPlayers, tostring(Players.MaxPlayers))
        local PingValue = addInfoTile(10, 144, 154, 80, loc.latency, "— ms")
        local RegionValue = addInfoTile(176, 144, 154, 80, loc.region, STATE.region or "—")
        local SessionValue = addInfoTile(10, 232, 154, 80, loc.sessionTime, "00:00:00")
        addInfoTile(176, 232, 154, 80, loc.copyJob, loc.tapToCopy, function()
            copyJobId()
        end)

        -- Executor card
        local execCard = make("Frame", {
            Size = UDim2.new(0, 243, 0, 140),
            Position = UDim2.new(0, 352, 0, 86),
            BackgroundColor3 = THEME.AccentDark,
            BackgroundTransparency = 0.72,
            BorderSizePixel = 0,
            Parent = frame
        })
        corner(execCard, 10)
        stroke(execCard, THEME.BorderActive, 1, 0.3)

        local execName = "Roblox"
        pcall(function()
            if identifyexecutor then
                local name = identifyexecutor()
                if type(name) == "string" and name ~= "" then
                    execName = name
                end
            end
        end)

        label({
            Size = UDim2.new(1, -28, 0, 22),
            Position = UDim2.new(0, 14, 0, 12),
            Text = execName,
            Font = Enum.Font.GothamBold,
            TextSize = 17,
            TextColor3 = THEME.Accent,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = execCard
        }, execCard)

        label({
            Size = UDim2.new(1, -28, 0, 66),
            Position = UDim2.new(0, 14, 0, 42),
            Text = loc.execLine1 .. "\n" .. loc.execLine2,
            Font = Enum.Font.Gotham,
            TextSize = 9.5,
            TextColor3 = THEME.TextPrimary,
            TextWrapped = true,
            TextYAlignment = Enum.TextYAlignment.Top,
            Parent = execCard
        }, execCard)

        -- Friends card
        local friendsCard = createCard(frame, 352, 238, 243, 172, loc.friends, loc.friendsSub)

        local function addFriendTile(x, y, titleText)
            local tile = make("Frame", {
                Size = UDim2.new(0, 107, 0, 50),
                Position = UDim2.new(0, x, 0, y),
                BackgroundColor3 = THEME.PillBg,
                BorderSizePixel = 0,
                Parent = friendsCard
            })
            corner(tile, 7)
            stroke(tile, THEME.Border, 1)

            label({
                Size = UDim2.new(1, -16, 0, 12),
                Position = UDim2.new(0, 8, 0, 9),
                Text = titleText,
                Font = Enum.Font.GothamBold,
                TextSize = 9,
                TextColor3 = THEME.TextPrimary,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = tile
            }, tile)

            return label({
                Size = UDim2.new(1, -16, 0, 14),
                Position = UDim2.new(0, 8, 0, 25),
                Text = "…",
                Font = Enum.Font.Gotham,
                TextSize = 9,
                TextColor3 = THEME.TextMuted,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = tile
            }, tile)
        end

        local FriendInServer = addFriendTile(10, 56, loc.inServer)
        local FriendOffline = addFriendTile(125, 56, loc.offline)
        local FriendOnline = addFriendTile(10, 112, loc.online)
        local FriendAll = addFriendTile(125, 112, loc.all)

        -- Live values (1s throttle)
        local lastUpdate = 0
        track(RunService.Heartbeat:Connect(function()
            local now = os.clock()
            if now - lastUpdate < 1 then return end
            lastUpdate = now

            PlayersValue.Text = string.format(loc.playingFmt, #Players:GetPlayers())
            SessionValue.Text = formatDuration(now - STATE.sessionStart)
            RegionValue.Text = STATE.region or "—"

            local ping = getPing()
            PingValue.Text = ping and string.format("%d ms", ping) or "— ms"

            refreshFriends()

            local friends = STATE.friends
            if friends.ready then
                local inServer = 0
                if friends.onlineIds then
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr ~= LocalPlayer and friends.onlineIds[plr.UserId] then
                            inServer += 1
                        end
                    end
                end

                FriendInServer.Text = string.format(loc.friendsFmt, inServer)

                if friends.all and friends.online then
                    FriendOffline.Text = string.format(loc.friendsFmt, math.max(friends.all - friends.online, 0))
                else
                    FriendOffline.Text = "—"
                end

                FriendOnline.Text = friends.online and string.format(loc.friendsFmt, friends.online) or "—"
                FriendAll.Text = friends.all and string.format(loc.friendsFmt, friends.all) or "—"
            end
        end))

        Pages[page.id] = frame
    end

    -- Misc page: Theme / Speak / Size
    local function createMiscPage(page)
        local frame = make("Frame", {
            Name = page.id,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Visible = false,
            Parent = ContentArea
        })

        -- ---- Theme card ----
        local ThemeCard = createCard(frame, 0, 0, 250, 428, loc.theme)

        for i, t in ipairs(THEMES) do
            local active = (t.id == STATE.theme)
            local row = make("TextButton", {
                Size = UDim2.new(1, -20, 0, 70),
                Position = UDim2.new(0, 10, 0, 50 + (i - 1) * 74),
                BackgroundColor3 = THEME.SidebarActive,
                BackgroundTransparency = active and 0 or 1,
                Text = "",
                AutoButtonColor = false,
                Parent = ThemeCard
            })
            corner(row, 8)

            local rowStroke = stroke(row, THEME.BorderActive, 1, active and 0.4 or 1)

            local swatch = make("Frame", {
                Size = UDim2.new(0, 24, 0, 24),
                Position = UDim2.new(0, 14, 0.5, -12),
                BackgroundColor3 = t.colors.Accent,
                BorderSizePixel = 0,
                Parent = row
            })
            corner(swatch, 7)
            stroke(swatch, t.colors.AccentSoft, 1, 0.5)

            local themeName = (STATE.lang == "ru") and t.nameRu or t.name
            label({
                Size = UDim2.new(1, -80, 0, 16),
                Position = UDim2.new(0, 50, 0.5, -8),
                Text = themeName,
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                TextColor3 = active and THEME.TextPrimary or THEME.TextMuted,
                Parent = row
            }, row)

            local dot = make("Frame", {
                Size = UDim2.new(0, 8, 0, 8),
                Position = UDim2.new(1, -20, 0.5, -4),
                BackgroundColor3 = THEME.Accent,
                BackgroundTransparency = active and 0 or 1,
                BorderSizePixel = 0,
                Parent = row
            })
            corner(dot, 4)

            track(row.MouseEnter:Connect(function()
                if not active then
                    TweenService:Create(row, TWEEN_FAST, { BackgroundTransparency = 0.6 }):Play()
                    TweenService:Create(rowStroke, TWEEN_FAST, { Transparency = 0.7 }):Play()
                end
            end))
            track(row.MouseLeave:Connect(function()
                if not active then
                    TweenService:Create(row, TWEEN_FAST, { BackgroundTransparency = 1 }):Play()
                    TweenService:Create(rowStroke, TWEEN_FAST, { Transparency = 1 }):Play()
                end
            end))

            track(row.MouseButton1Click:Connect(function()
                if STATE.theme == t.id then return end
                STATE.theme = t.id
                rebuild()
            end))
        end

        -- ---- Speak card ----
        local SpeakCard = createCard(frame, 262, 0, 333, 176, loc.speak)

        local languages = {
            { id = "en", badge = "EN", name = "English" },
            { id = "ru", badge = "RU", name = "Русский" }
        }

        for i, lang in ipairs(languages) do
            local active = (STATE.lang == lang.id)
            local row = make("TextButton", {
                Size = UDim2.new(1, -20, 0, 56),
                Position = UDim2.new(0, 10, 0, 50 + (i - 1) * 58),
                BackgroundColor3 = THEME.SidebarActive,
                BackgroundTransparency = active and 0 or 1,
                Text = "",
                AutoButtonColor = false,
                Parent = SpeakCard
            })
            corner(row, 8)

            local rowStroke = stroke(row, THEME.BorderActive, 1, active and 0.4 or 1)

            local badge = make("Frame", {
                Size = UDim2.new(0, 26, 0, 26),
                Position = UDim2.new(0, 12, 0.5, -13),
                BackgroundColor3 = active and THEME.Accent or THEME.PillBg,
                BorderSizePixel = 0,
                Parent = row
            })
            corner(badge, 7)
            if not active then
                stroke(badge, THEME.Border, 1)
            end

            label({
                Size = UDim2.new(1, 0, 1, 0),
                Text = lang.badge,
                Font = Enum.Font.GothamBold,
                TextSize = 9,
                TextColor3 = active and THEME.Background or THEME.TextMuted,
                TextXAlignment = Enum.TextXAlignment.Center,
                Parent = badge
            }, badge)

            label({
                Size = UDim2.new(1, -80, 0, 16),
                Position = UDim2.new(0, 48, 0.5, -8),
                Text = lang.name,
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                TextColor3 = active and THEME.TextPrimary or THEME.TextMuted,
                Parent = row
            }, row)

            local dot = make("Frame", {
                Size = UDim2.new(0, 8, 0, 8),
                Position = UDim2.new(1, -20, 0.5, -4),
                BackgroundColor3 = THEME.Accent,
                BackgroundTransparency = active and 0 or 1,
                BorderSizePixel = 0,
                Parent = row
            })
            corner(dot, 4)

            track(row.MouseEnter:Connect(function()
                if not active then
                    TweenService:Create(row, TWEEN_FAST, { BackgroundTransparency = 0.6 }):Play()
                    TweenService:Create(rowStroke, TWEEN_FAST, { Transparency = 0.7 }):Play()
                end
            end))
            track(row.MouseLeave:Connect(function()
                if not active then
                    TweenService:Create(row, TWEEN_FAST, { BackgroundTransparency = 1 }):Play()
                    TweenService:Create(rowStroke, TWEEN_FAST, { Transparency = 1 }):Play()
                end
            end))

            track(row.MouseButton1Click:Connect(function()
                if STATE.lang == lang.id then return end
                STATE.lang = lang.id
                rebuild()
            end))
        end

        -- ---- Size card ----
        local SizeCard = createCard(frame, 262, 188, 333, 240, loc.size)

        local function addSlider(y, titleText, minV, maxV, value, onChange)
            local row = make("Frame", {
                Size = UDim2.new(1, -20, 0, 36),
                Position = UDim2.new(0, 10, 0, y),
                BackgroundTransparency = 1,
                Parent = SizeCard
            })

            label({
                Size = UDim2.new(0.6, 0, 0, 14),
                Text = titleText,
                TextSize = 10.5,
                TextColor3 = THEME.TextMuted,
                Parent = row
            }, row)

            local valueLabel = label({
                Size = UDim2.new(0.4, 0, 0, 14),
                Position = UDim2.new(0.6, 0, 0, 0),
                Text = "",
                Font = Enum.Font.GothamBold,
                TextSize = 10,
                TextColor3 = THEME.Accent,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = row
            }, row)

            local bar = make("Frame", {
                Size = UDim2.new(1, 0, 0, 4),
                Position = UDim2.new(0, 0, 0, 24),
                BackgroundColor3 = THEME.PillBg,
                BorderSizePixel = 0,
                Parent = row
            })
            corner(bar, 2)

            local fill = make("Frame", {
                Size = UDim2.new(0, 0, 1, 0),
                BackgroundColor3 = THEME.Accent,
                BorderSizePixel = 0,
                Parent = bar
            })
            corner(fill, 2)

            local knob = make("Frame", {
                Size = UDim2.new(0, 10, 0, 10),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0, 0, 0.5, 0),
                BackgroundColor3 = THEME.TextPrimary,
                BorderSizePixel = 0,
                ZIndex = 2,
                Parent = bar
            })
            corner(knob, 5)

            local hit = make("TextButton", {
                Size = UDim2.new(1, 0, 0, 20),
                Position = UDim2.new(0, 0, 0, 14),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
                Parent = row
            })

            local function setFraction(frac)
                frac = math.clamp(frac, 0, 1)
                local v = minV + (maxV - minV) * frac

                fill.Size = UDim2.new(frac, 0, 1, 0)
                knob.Position = UDim2.new(frac, 0, 0.5, 0)
                valueLabel.Text = string.format("%d%%", math.floor(v * 100 + 0.5))
                onChange(v)
            end

            local initFrac = (value - minV) / (maxV - minV)
            fill.Size = UDim2.new(initFrac, 0, 1, 0)
            knob.Position = UDim2.new(initFrac, 0, 0.5, 0)
            valueLabel.Text = string.format("%d%%", math.floor(value * 100 + 0.5))

            local dragging = false
            track(hit.InputBegan:Connect(function(input)
                if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                dragging = true
                local width = math.max(bar.AbsoluteSize.X, 1)
                setFraction((input.Position.X - bar.AbsolutePosition.X) / width)
            end))
            track(UserInputService.InputChanged:Connect(function(input)
                if not dragging or input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
                local width = math.max(bar.AbsoluteSize.X, 1)
                setFraction((input.Position.X - bar.AbsolutePosition.X) / width)
            end))
            track(UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end))
        end

        addSlider(52, loc.guiSize, 0.8, 1.8, STATE.guiScale, function(v)
            local old = STATE.guiScale
            if math.abs(v - old) < 0.0005 then return end
            STATE.guiScale = v
            GuiScale.Scale = v
            -- keep the window visually centered while scaling
            local p = Main.Position
            Main.Position = UDim2.new(
                p.X.Scale, p.X.Offset + 395 * (old - v),
                p.Y.Scale, p.Y.Offset + 245 * (old - v)
            )
            STATE.mainPos = Main.Position
        end)

        addSlider(112, loc.hudSize, 0.7, 1.6, STATE.hudScale, function(v)
            STATE.hudScale = v
            HudScale.Scale = v
        end)

        local ResetBtn = make("TextButton", {
            Size = UDim2.new(1, -20, 0, 26),
            Position = UDim2.new(0, 10, 0, 196),
            BackgroundColor3 = THEME.PillBg,
            BorderSizePixel = 0,
            Text = loc.reset,
            Font = Enum.Font.GothamBold,
            TextSize = 10,
            TextColor3 = THEME.TextMuted,
            AutoButtonColor = false,
            Parent = SizeCard
        })
        corner(ResetBtn, 6)
        stroke(ResetBtn, THEME.Border, 1)

        track(ResetBtn.MouseEnter:Connect(function()
            TweenService:Create(ResetBtn, TWEEN_FAST, { TextColor3 = THEME.Accent }):Play()
        end))
        track(ResetBtn.MouseLeave:Connect(function()
            TweenService:Create(ResetBtn, TWEEN_FAST, { TextColor3 = THEME.TextMuted }):Play()
        end))
        track(ResetBtn.MouseButton1Click:Connect(function()
            local p = STATE.mainPos
            STATE.mainPos = UDim2.new(
                p.X.Scale, p.X.Offset + 395 * (STATE.guiScale - 1.2),
                p.Y.Scale, p.Y.Offset + 245 * (STATE.guiScale - 1.2)
            )
            STATE.guiScale = 1.2
            STATE.hudScale = 1
            rebuild()
        end))

        Pages[page.id] = frame
    end

    pageBuilders = {
        profile = createProfilePage,
        combat = createCombatPage,
        movement = createMovementPage,
        visuals = createVisualsPage,
        animations = createAnimationsPage,
        auras = createAurasPage,
        misc = createMiscPage
    }

    ensurePage = function(id)
        if Pages[id] then return end
        for _, page in ipairs(PAGES) do
            if page.id == id then
                local builder = pageBuilders[id] or createCombatPage
                builder(page)
                return
            end
        end
    end

    -- Footer
    local Footer = make("Frame", {
        Size = UDim2.new(0, 160, 0, 28),
        Position = UDim2.new(0, 18, 1, -38),
        BackgroundTransparency = 1,
        Parent = Main
    })

    label({
        Size = UDim2.new(1, 0, 0, 13),
        Text = string.lower(LocalPlayer.Name),
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = THEME.TextMuted,
        Parent = Footer
    }, Footer)

    label({
        Size = UDim2.new(1, 0, 0, 11),
        Position = UDim2.new(0, 0, 0, 13),
        Text = loc.footer,
        Font = Enum.Font.Gotham,
        TextSize = 7.5,
        TextColor3 = THEME.TextDim,
        Parent = Footer
    }, Footer)

    selectPage(STATE.page)

    -- Sidebar collapse
    local function applySidebar(visible, animate)
        STATE.sidebar = visible
        Sidebar.Visible = visible
        Footer.Visible = visible

        local pos = visible and UDim2.new(0, 182, 0, 54) or UDim2.new(0, 14, 0, 54)
        local size = visible and UDim2.new(1, -195, 1, -62) or UDim2.new(1, -28, 1, -62)

        if animate then
            TweenService:Create(ContentArea, TWEEN_FAST, { Position = pos, Size = size }):Play()
        else
            ContentArea.Position = pos
            ContentArea.Size = size
        end
    end

    applySidebar(STATE.sidebar, false)

    track(MenuBtn.MouseButton1Click:Connect(function()
        applySidebar(not STATE.sidebar, true)
    end))

    -- =========================================================================
    -- 3. RightShift — show / hide window (HUD stays)
    -- =========================================================================
    track(UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        if input.KeyCode == aimBind then
            aiming = true
            return
        end

        if input.KeyCode ~= Enum.KeyCode.RightShift then return end

        STATE.shown = not STATE.shown
        local hiddenPos = STATE.mainPos + UDim2.new(0, 0, 0, 30)

        if STATE.shown then
            playSound("open")
            Main.Position = hiddenPos
            Main.Visible = true
            TweenService:Create(Main, TWEEN_SLOW, { Position = STATE.mainPos }):Play()
            TweenService:Create(GlowBackdrop, TWEEN_SLOW, { ImageTransparency = 0.83 }):Play()
        else
            local hideTween = TweenService:Create(Main, TWEEN_SLOW, { Position = hiddenPos })
            TweenService:Create(GlowBackdrop, TWEEN_SLOW, { ImageTransparency = 1 }):Play()
            hideTween.Completed:Connect(function()
                if not STATE.shown then
                    Main.Visible = false
                end
            end)
            hideTween:Play()
        end
    end))

    track(UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == aimBind then
            aiming = false
        end
    end))

    _G.NursultanUI = {
        ScreenGui = ScreenGui,
        Pages = Pages,
        selectPage = selectPage,
        state = STATE,
        rebuild = rebuild
    }
end

-- =============================================================================
-- REBUILD (theme / language changes)
-- =============================================================================
local rebuilding = false

function rebuild()
    if rebuilding then return end
    rebuilding = true
    task.defer(function()
        rebuilding = false
        buildUI()
    end)
end

buildUI()

task.delay(0.25, function()
    playSound("open")
end)

-- =============================================================================
-- UNLOAD
-- =============================================================================
function _G.NursultanUnload()
    pcall(function() espDisable() end)
    pcall(function() disableRTX() end)
    pcall(function() setNoclip(false) end)
    pcall(function() stopBunnyHop() end)
    pcall(function() clearAura() end)
    pcall(function() removeSkybox() end)
    pcall(function() clearWeatherParticles() end)
    pcall(function() setFog(false) end)
    pcall(function() stopEmotes() end)
    pcall(function() restoreHitboxes() end)
    pcall(function() RunService:UnbindFromRenderStep("NursultanScreenStretch") end)

    if targetEspGui then
        pcall(function() targetEspGui:Destroy() end)
    end
    if targetHudGui then
        pcall(function() targetHudGui:Destroy() end)
    end

    notifyHook = nil
    destroyBuild()
    _G.NursultanUnload = nil
    _G.NursultanUI = nil
end

print("[Nursultan Client " .. SCRIPT_VERSION .. "] loaded. RightShift - toggle window. Use _G.NursultanUnload() to unload.")
# SwagModeESPlibrary

Мощная и красивая ESP-библиотека для Roblox (Drawing lib). Плавный рендер, свечение, рейнбоу, пресеты, off-screen стрелки — и всё настраивается.

## Содержание
- [Возможности](#возможности)
- [Быстрый старт](#быстрый-старт)
- [Loadstring](#loadstring)
- [Полный конфиг](#полный-конфиг)
- [Пресеты](#пресеты)
- [API](#api)
- [Пример с хоткеями](#пример-с-хоткеями)
- [Производительность](#производительность)
- [Как работает](#как-работает)

## Возможности

| Фича | Описание |
|------|----------|
| **Box ESP** | 2D / Corner / 3D — куб из 12 рёбер |
| **Name ESP** | Имя игрока с обводкой, префикс/суффикс, HP и дистанция в тексте |
| **Health Bar ESP** | Вертикальная или горизонтальная, слева/справа/снизу, с цифрами HP |
| **Head Dot ESP** | Точка на голове цели |
| **Distance ESP** | Дистанция в метрах |
| **Tracer ESP** | Линии от края экрана к игрокам |
| **Skeleton ESP** | Скелет из 14 костей |
| **Tool ESP** | Название оружия/предмета в руке |
| **Tool Highlight** | Подсветка предмета в руке цели |
| **Chams ESP** | Подсветка тела игрока (Highlight) |
| **Off-screen Arrows** | Стрелки на краю экрана к игрокам вне экрана |
| **Rainbow** | Переливающиеся цвета (глобально или per-player) |
| **Team Color** | Цвет берётся из команды игрока |
| **Player Colors** | Свой цвет конкретному игроку |
| **Пресеты** | 7 готовых тем в один вызов |
| **Smooth рендер** | Плавное сглаживание позиций, FPS-независимое |
| **Glow свечение** | Слои свечения и пульсация яркости |
| **Team / Visibility Check** | Скрытие союзников и игроков за стенами |
| **Data API** | Ping, имя, дистанция, HP, предмет через методы |

## Быстрый старт

```lua
local NeonESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/Unwalker1337/SwagModeESPlibrary/main/init.lua"))()

local esp = NeonESP.new({ TeamCheck = true })
esp:Start()
```

## Loadstring

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Unwalker1337/SwagModeESPlibrary/main/init.lua"))()
```

> Кэш: если экзекутор кеширует файл, добавь к URL параметр: `init.lua?nocache=1`.

## Полный конфиг

Все разделы — это таблицы. Менять можно любой ключ.

```lua
-- Топ-уровневые
Enabled = true,                      -- главный выключатель
TeamCheck = false,                   -- скрывать союзников
VisibilityCheck = false,             -- скрывать за стенами
MaxDistance = 2000,                  -- макс. дистанция (стади)
UseTeamColor = false,                -- цвет из команды игрока

Rainbow = {
    Enabled = false,                 -- рейнбоу режим
    Speed = 2,                       -- скорость смены цвета
    PerPlayer = false,               -- у каждого игрока свой цвет
},

Smooth = {
    Enabled = true,
    Speed = 0.5,                     -- скорость сглаживания (больше = резче)
},

Glow = {
    Enabled = true,
    Speed = 1.6,                     -- скорость пульсации
    MinAlpha = 0.75,                 -- мин. яркость пульса
    MaxAlpha = 0.95,                 -- макс. яркость пульса
},

DistanceFade = {
    Enabled = true,
    StartDistance = 500,             -- отсюда начинается затухание
    EndDistance = 2000,              -- здесь альфа = MinAlpha
    MinAlpha = 0.45,
},

Box = {
    Enabled = true,
    Mode = "Corner",                 -- "Corner" | "2D" | "3D"
    Color = Color3.fromRGB(0, 180, 255),
    SecondaryColor = Color3.fromRGB(80, 120, 200),  -- цвет свечения
    Thickness = 1.25,
    Transparency = 0.85,             -- непрозрачность (0..1)
    CornerLength = 0,                -- длина уголков (0 = авто)
    Rainbow = false,
},

Name = {
    Enabled = true,
    Color = Color3.fromRGB(255, 255, 255),
    Size = 14,
    Font = Enum.Font.GothamBold,
    Outline = true,
    UseDisplayName = true,           -- false = обычный ник
    Prefix = "",                     -- текст перед именем
    Suffix = "",                     -- текст после имени
    ShowHealth = false,              -- добавить HP к имени
    ShowDistance = false,            -- добавить дистанцию к имени
    MaxLength = 32,                  -- обрезать длинные имена
    Rainbow = false,
},

HealthBar = {
    Enabled = true,
    Width = 3,
    Offset = 6,                      -- отступ от бокса
    Position = "Left",               -- "Left" | "Right" | "Back" | "Bottom"
    HighColor = Color3.fromRGB(0, 255, 120),
    LowColor = Color3.fromRGB(255, 40, 40),
    SmoothTransition = true,         -- плавное изменение HP
    ShowText = false,                -- цифры HP (120/100)
    TextColor = Color3.fromRGB(255, 255, 255),
    TextSize = 11,
    Rainbow = false,
},

HeadDot = {
    Enabled = true,
    Color = Color3.fromRGB(255, 255, 255),
    OutlineColor = Color3.fromRGB(40, 40, 40),
    Size = 5,
    Transparency = 0.85,
    Outline = true,
    Rainbow = false,
},

Distance = {
    Enabled = true,
    Color = Color3.fromRGB(180, 180, 200),
    Size = 12,
    Font = Enum.Font.Gotham,
    Suffix = "m",
    Rainbow = false,
},

Tracers = {
    Enabled = false,
    Origin = "Bottom",               -- "Top" | "Center" | "Bottom"
    Color = Color3.fromRGB(0, 180, 255),
    SecondaryColor = Color3.fromRGB(200, 220, 255), -- цвет на большой дистанции
    Thickness = 1,
    Transparency = 0.5,
    Rainbow = false,
},

Skeleton = {
    Enabled = false,
    Color = Color3.fromRGB(160, 170, 200),
    Thickness = 1,
    Transparency = 0.8,
    Rainbow = false,
},

ToolESP = {
    Enabled = false,
    Color = Color3.fromRGB(255, 220, 50),
    Size = 12,
    Font = Enum.Font.Gotham,
    Brackets = true,                 -- "[ Sword ]" или "Sword"
    Rainbow = false,
},

ToolHighlight = {
    Enabled = false,
    FillColor = Color3.fromRGB(255, 220, 50),
    FillTransparency = 0.5,
    OutlineColor = Color3.fromRGB(255, 255, 255),
    OutlineTransparency = 0.3,
},

Chams = {
    Enabled = false,
    FillColor = Color3.fromRGB(140, 60, 255),
    FillTransparency = 0.7,
    OutlineColor = Color3.fromRGB(200, 150, 255),
    OutlineTransparency = 0.5,
    Rainbow = false,
},

OffscreenArrows = {
    Enabled = true,
    Color = Color3.fromRGB(0, 180, 255),
    SecondaryColor = Color3.fromRGB(255, 255, 255),
    Size = 18,                       -- длина стрелки, px
    Width = 12,                      -- ширина стрелки, px
    Margin = 40,                     -- отступ от края экрана
    Transparency = 0.85,
    ShowDistance = true,             -- дистанция рядом со стрелкой
    Rainbow = false,
},
```

## Пресеты

Готовые темы — `esp:ApplyPreset("Имя")`:

| Пресет | Описание |
|--------|----------|
| `Default` | Стандартная синяя тема |
| `Neon` | Рейнбоу-переливы |
| `Cyber` | Неон зелёно-синий |
| `Amber` | Тёплый янтарь |
| `Crimson` | Красный |
| `Frost` | Холодный голубой |
| `Toxic` | Ядовито-зелёный |
| `Minimal` | Чистый минимализм (без свечения, без стрелок) |

Список имён: `esp:GetPresetNames()` — вернёт таблицу имён.
> Внимание: `ApplyPreset` вызывает `SetConfig`, а тот — `Refresh()` (пересоздание Drawing-объектов). Вызывай один раз при старте.

## API

### Управление
| Метод | Описание |
|-------|----------|
| `NeonESP.new(config?)` | Создать инстанс |
| `esp:Start()` | Запустить рендер |
| `esp:Stop()` | Остановить (можно `Start()` снова) |
| `esp:Destroy()` | Полностью удалить |
| `esp:IsRunning()` | `true`, если запущен |
| `esp:SetConfig(patch)` | Обновить конфиг (с `Refresh`) |
| `esp:Refresh()` | Пересоздать все Drawing из текущего конфига |
| `esp:ApplyPreset(name)` | Применить пресет |
| `esp:GetPresetNames()` | Таблица имён пресетов |
| `esp:SetPlayerColor(player, color)` | Цвет конкретному игроку (nil сброс) |

### Данные по игроку
| Метод | Возврат |
|-------|---------|
| `esp:GetPing(player)` | `number` мс |
| `esp:GetName(player)` | `string` |
| `esp:GetDistance(player)` | `number` стади |
| `esp:GetHealth(player)` | `hp, maxHP` |
| `esp:GetTool(player)` | `string?` название предмета |

> `NeonESP.Version` — версия библиотеки.

## Пример с хоткеями

```lua
local NeonESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/Unwalker1337/SwagModeESPlibrary/main/init.lua"))()

local esp = NeonESP.new({
    TeamCheck = true,
    MaxDistance = 5000,
    Box = { Mode = "Corner" },
    HealthBar = { ShowText = true, Position = "Bottom" },
    Name = { ShowDistance = true, ShowHealth = true },
    Tracers = { Enabled = true, Origin = "Bottom" },
    Chams = { Enabled = true },
})

esp:ApplyPreset("Cyber")
esp:Start()

game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.F then
        esp:SetConfig({ Tracers = { Enabled = not esp.Config.Tracers.Enabled } })
    elseif input.KeyCode == Enum.KeyCode.G then
        esp:SetConfig({ Chams = { Enabled = not esp.Config.Chams.Enabled } })
    elseif input.KeyCode == Enum.KeyCode.T then
        esp:SetConfig({ OffscreenArrows = { Enabled = not esp.Config.OffscreenArrows.Enabled } })
    end
end)
```

## Производительность

Новая версия заточена под много игроков без лагов:

- `GetBoundingBox` пересчитывается раз в 45 кадров, дальше движется вместе с персонажем
- 2D/Corner бокс — **одна** проекция через FOV-математику (было 8 проекций + GetBoundingBox)
- У игроков за экраном рисуются **только** offscreen-стрелки
- Текст и цвета пишутся в Drawing только при изменении (dirty-кэш)
- Скрытие мёртвых/далёких — по флагам, без записи сотен свойств каждый кадр
- 0 pcall в горячем пути скелета
- Общие величины кадра (viewport, FOV, glow, hue) — 1 раз за кадр
- `Camera + 1` — рендер после обновления камеры, без отставания на кадр

Снизить нагрузку ещё сильнее:
```lua
MaxDistance = 1500,
Glow = { Enabled = false },
Skeleton = { Enabled = false },
```

## Как работает

- **Сглаживание**: экспоненциальный lerp, FPS-независимый (`1 - exp(-Speed * 30 * dt)`). Если цель ушла слишком далеко (`SNAP_FAR`) — мгновенно догоняет, если почти на месте (`SNAP_NEAR`) — прилипает.
- **Стрелки**: направление считается в системе координат камеры (`PointToObjectSpace`), корректно даже когда враг за спиной. Стрелка плавно гаснет, когда враг возвращается на экран.
- **Rainbow**: оттенок `_hue` бежит по кругу, `PerPlayer` сдвигает фазу на `UserId % 360`.
- **Chams**: `Highlight` переиспользуется, пересоздаётся только при смене персонажа.

## Лицензия

MIT
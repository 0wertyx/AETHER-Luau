# AETHER — Luau

Исходники AETHER в виде отдельных Luau-модулей. Подготовлено для GitHub и Rojo.

## Статус

В архиве Astra было 12 файлов Luau. Они сохранены **без переписывания**.

**Обновлено:** добавлен `src/client/Aether.client.luau` — клиентская точка входа,
которая связывает исходные модули Astra. Roblox Studio runtime-тест пока не
выполнялся, поэтому это интеграционная сборка, а не подтверждённый релиз.

## Структура

- `src/shared/` — 11 модулей Luau (`require(script.Parent.Имя)`).
- `src/server/Profiles.server.luau` — серверное хранение профилей.
- `src/client/Aether.client.luau` — клиентский запуск, GUI, обновления, симулятор и очистка.
- `default.project.json` — Rojo-конфигурация для Roblox Studio.

Для серверного скрипта в конфигурации добавлен дочерний `Schema`,
поскольку текущий код вызывает `require(script.Schema)`.

## Работа с Roblox Studio

Установи [Rojo](https://rojo.space/) и его плагин для Roblox Studio.

Открой терминал в корне репозитория:

```powershell
rojo serve default.project.json
```

Подключись к серверу через плагин Rojo в Roblox Studio. Rojo синхронизирует
модули из файлов в дерево `ReplicatedStorage.Aether`, а серверный скрипт
в `ServerScriptService.AetherProfiles`, а запуск клиента — в `StarterPlayer.StarterPlayerScripts.AetherClient`.

Для сборки файла плейса (без запуска):

```powershell
rojo build default.project.json -o AETHER.rbxlx
```

Синхронизация через Rojo — это рабочий путь для разработки в своём плейсе,
**не** загрузчик в чужие игры Roblox.

## GitHub

Создай пустой репозиторий `AETHER-Luau` на GitHub и выполни из этой папки:

```powershell
git init
git add .
git commit -m "Import Astra AETHER Luau modules"
git branch -M main
git remote add origin https://github.com/USERNAME/AETHER-Luau.git
git push -u origin main
```

Замени `USERNAME` своим именем пользователя GitHub.

## Что ещё нужно сделать

Проверить новую клиентскую точку входа и механики непосредственно в Roblox Studio.
В среде подготовки были проверены наличие исходников и связи зависимостей;
полный синтаксический анализ Luau и игровой тест не выполнялись.

Управление: **RightShift** — меню; **LeftAlt** — переключение camera lock.
Работа в чужих играх Roblox не обеспечивается данным проектом или Rojo.


## Автономный клиент без Rojo

Для **своего плейса** можно использовать один собранный `LocalScript`:
`dist/AETHER.client.luau`. Сборка объединяет все `src/shared/*.luau` и
`src/client/Aether.client.luau` в один файл с локальным загрузчиком модулей.

```powershell
python tools/build.py
python tools/build.py --check
```

Содержимое `dist/AETHER.client.luau` вставляется в `LocalScript` внутри
`StarterPlayer > StarterPlayerScripts` в Roblox Studio. Оригинальные исходники
продолжают храниться раздельно в `src/`.

GitHub Actions пересобирает `dist` при изменениях модулей в `main`.
Для этого в настройках репозитория GitHub Actions должны быть разрешены права
записи в репозиторий. Если репозиторий приватный, ссылки GitHub Raw без
авторизации не будут доступны.

**Ограничение:** это обычный Roblox `LocalScript`, а не исполняемый инжектор и
не средство запуска в чужих играх. При запуске автономной сборки серверный
`Profiles.server.luau` отсутствует, поэтому постоянное сохранение профилей
без серверной части недоступно. Runtime-проверка внутри Roblox Studio
пока не проводилась.

## Оригинальные курсоры AETHER Desktop

Шесть исходных SVG-контуров из `AETHER_Build/Web/dist/cursors.js` сохранены в
`assets/cursors/` вместе с пятью цветовыми палитрами. В Roblox их обрабатывает
`src/shared/VectorCursor.luau`: кривые Безье и fill-rule evenodd растрируются
со сглаживанием в 128×128, затем `EditableImage` отображается через `ImageLabel.ImageContent`.
Один и тот же `EditableImage` используется для курсора и предпросмотра в Cursor Studio.

**Ограничения Roblox:** в опубликованных плейсах нужно включить Mesh / Image APIs
в настройках опыта; сам пользователь не может включить их для чужого плейса.
Когда `EditableImage` недоступен, применяется старый GUI-рендерер `Symbol`:
он работает без разрешений, но края могут быть ступенчатыми. Сами SVG-файлы
из GitHub не становятся Roblox-изображениями автоматически — для обычного
`ImageLabel.Image` требуется импорт PNG в Roblox и разрешённый asset ID.

Слой `AETHER_Pointer` использует **`ScreenInsets=Enum.ScreenInsets.None`**
в дополнение к `IgnoreGuiInset=true`. Это важно: в новых версиях Roblox
один `IgnoreGuiInset=true` выбирает `DeviceSafeInsets`, а не полный экран.
Координаты `UserInputService:GetMouseLocation()` соответствуют полному экрану;
`GuiService:GetGuiInset()` отдельно не вычитается. Позиция курсора обновляется
в отдельном `BindToRenderStep` с `Enum.RenderPriority.Last`, независимо
от SVG/HUD. SVG-маска строится только при изменении контура/свечения;
градиент анимируется с помощью `UIGradient.Rotation` без записей пикселей каждый кадр.
Точка привязки (hotspot) настраивается в Cursor.

Проверка графики, курсорных координат и ограничений API непосредственно в Roblox
Studio / опубликованном плейсе ещё нужна: автосборка не заменяет runtime-тест.


## Детализированные крылья, хало и походка

- В разделе **Wings** доступны `Feather detail` (Balanced / High / Ultra) и
  `Walking wing reaction`. Перья состоят из нескольких самостоятельных
  деталей: перо, прожилка и отдельные светящиеся кончики. При ходьбе изменяются
  взмах, разворот и разлёт перьев.
- В **Halos** доступны `Halo geometry detail` и `Walking halo reaction`.
  Формы собираются из внешнего и, где предусмотрено стилем, внутреннего кольца,
  орнаментов, светящихся сегментов и вращающихся акцентов.
- В **Character** добавлены `Custom walking animation`, `Walking style` и
  `Walking intensity %`. Стили Natural, Heroic, Floating, Bouncy дополняют
  обычную анимацию ходьбы через `Motor6D.Transform` в `PreSimulation` на
  локальном персонаже R6/R15. **По умолчанию выключено**, чтобы не затронуть
  встроенные анимации чужого плейса; включите через интерфейс или пресет.
- Доступность `EditableImage` влияет на качество SVG-курсора, **но не
  определяет правильность его координат**. Если курсор смещён в конкретном
  плейсе, нужна отдельная проверка ScreenInsets / MouseBehavior и реальной
  точки клика; изменения выше не гарантируют решения этого бага.

Обновление исходников и сборки проверяется автоматически, но визуальная
проверка новых форм и ходьбы в реальном Roblox пока не проведена.


## Ноябрь 2026 — редактор, иконки и плавные анимации

- **Иконки:** новый `src/shared/Icons.luau` умеет показывать все 32
  исходные иконки AETHER Desktop из одного atlas asset (см.
  `assets/icons/README.md`). Файл-атлас собирается из архива командой
  `python tools/export_desktop_icons.py "AETHER_Build(1).zip" assets/icons`.
  Из-за ограничений Roblox изображение нужно опубликовать как Roblox asset:
  прямой URL GitHub в `ImageLabel.Image` не подходит.
- **Цвет шрифта редактора:** Dashboard → `Studio text color` и
  `Studio secondary text`. HUD имеет отдельные прежние цвета
  `Fonts → Letter color / Letter gradient`.
- **Курсор:** Sway / Spin / Breathe / Pulse; регулируемая скорость и след.
  Переработан якорь: `MouseHotspot` всегда остаётся в точке мыши, а
  скин масштабируется и вращается вокруг своего заданного hotspot.
  Опции `Pointer offset X/Y` и `Show hotspot marker` помогают
  калибровать движок ввода в отдельных плейсах.
- **R6/R15:** `Glide` и `Ethereal` — плавное парение, наклоны корпуса,
  движения плеч и ног. Стили визуальные, не дают физического полёта и не
  влияют на положение `HumanoidRootPart`. Включаются через
  Character → `Custom walking animation`. Начальное значение Off.
- **Тестирование:** сборка синхронизируется с GitHub Actions, но реальный
  результат визуального позиционирования и анимаций зависит от плейса;
  runtime-тест в Roblox пока не подтверждён.

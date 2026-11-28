local U={}
function U.new(class,props,parent)
 local obj=Instance.new(class);for k,v in props or {} do obj[k]=v end;obj.Parent=parent;return obj
end
function U.scope()
 local s={items={},dead=false}
 function s:add(v) assert(not self.dead,"Closed scope");table.insert(self.items,v);return v end
 function s:on(signal,fn) return self:add(signal:Connect(fn)) end
 function s:clear() if self.dead then return end;self.dead=true;for i=#self.items,1,-1 do local v=self.items[i];local ok,err=pcall(function() if typeof(v)=="RBXScriptConnection" then v:Disconnect() elseif typeof(v)=="Instance" then v:Destroy() else v() end end);if not ok then warn("AETHER cleanup:",err) end end;table.clear(self.items) end
 return s
end
function U.corner(p,r) return U.new("UICorner",{CornerRadius=UDim.new(0,r or 10)},p) end
function U.stroke(p,c,alpha,width) return U.new("UIStroke",{Color=c,Transparency=alpha or .5,Thickness=width or 1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},p) end
function U.gradient(p,a,b,rot) return U.new("UIGradient",{Color=ColorSequence.new(a,b),Rotation=rot or 25},p) end
function U.frame(p,name,pos,size,color,alpha) return U.new("Frame",{Name=name,Position=pos or UDim2.new(),Size=size or UDim2.fromScale(1,1),BackgroundColor3=color or Color3.fromRGB(22,18,37),BackgroundTransparency=alpha or 0,BorderSizePixel=0},p) end
function U.label(p,text,sz,pos,size) return U.new("TextLabel",{BackgroundTransparency=1,Text=text,Font=Enum.Font.GothamMedium,TextSize=sz,TextColor3=Color3.fromRGB(242,237,255),TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,Position=pos or UDim2.new(),Size=size or UDim2.fromScale(1,1)},p) end
function U.button(p,text) local b=U.new("TextButton",{Text=text,Font=Enum.Font.GothamMedium,TextSize=13,TextColor3=Color3.fromRGB(241,234,255),BackgroundColor3=Color3.fromRGB(52,40,77),BorderSizePixel=0,AutoButtonColor=true},p);U.corner(b,8);return b end
-- Shared original panel components. Runtime attaches actions; HUD preview attaches
-- movement handles to the same components without executing game actions.
function U.topPanel(parent)
 local panel=U.frame(parent,"TopCapsule",nil,UDim2.fromOffset(136,38),Color3.fromRGB(19,16,32),.12)
 panel.AnchorPoint=Vector2.new(.5,0);panel.Position=UDim2.new(.5,0,0,12);U.corner(panel,18)
 local rim=U.stroke(panel,Color3.fromRGB(166,138,255),.42)
 panel.BackgroundTransparency=.12;rim.Enabled=true
 local label=U.label(panel,"A E T H E R",14,UDim2.fromOffset(4,4),UDim2.new(1,-8,1,-8))
 label.Name="AetherTitle";label.TextXAlignment=Enum.TextXAlignment.Center
 label.Active=false;label.Interactable=false
 return panel,rim,{label}
end
-- Display-only localization. Never translate configuration keys or action IDs.
local russian={
 ["main"]="Главное",
 ["visuals"]="Визуал",
 ["utility"]="Инструменты",
 ["interface"]="Интерфейс",
 ["dashboard"]="Обзор",
 ["profiles"]="Конфигурации",
 ["diagnostics"]="Диагностика",
 ["character"]="Персонаж",
 ["wings"]="Крылья",
 ["halos"]="Нимбы",
 ["ambient"]="Атмосфера",
 ["indicators"]="Индикаторы",
 ["cursor"]="Курсор",
 ["interaction"]="Управление",
 ["volleyball"]="Волейбол",
 ["clock"]="Часы",
 ["fps"]="FPS",
 ["top panel"]="Верхняя панель",
 ["input display"]="Клавиши",
 ["reticle"]="Прицел",
 ["keybinds"]="Горячие клавиши",
 ["quick menu"]="Быстрое меню",
 ["practice display"]="Тренировка",
 ["fonts"]="Шрифты",
 ["language"]="Язык",
 ["english"]="English",
 ["russian"]="Русский",
 ["gui view"]="GUI",
 ["node view"]="Ноды",
 ["gui"]="GUI",
 ["nodes"]="Ноды",
 ["home"]="Домой",
 ["aether / move"]="AETHER / ПЕРЕТАЩИТЬ",
 ["move panel"]="ПЕРЕТАЩИТЬ",
 ["appearance / move"]="ОФОРМЛЕНИЕ / ПЕРЕТАЩИТЬ",
 ["live preview / move"]="ПРЕДПРОСМОТР / ПЕРЕТАЩИТЬ",
 ["appearance"]="Оформление",
 ["live preview"]="Предпросмотр",
 ["all settings"]="Все настройки",
 ["search functions..."]="Поиск функций...",
 ["no functions found"]="Ничего не найдено",
 ["root node"]="Главная нода",
 ["appearance node"]="Нода оформления",
 ["live preview node"]="Нода предпросмотра",
 ["main branch"]="Ветка главного меню",
 ["visuals branch"]="Ветка визуала",
 ["utility branch"]="Ветка инструментов",
 ["interface branch"]="Ветка интерфейса",
 ["settings panel"]="Панель настроек",
 ["title bar"]="Заголовок",
 ["view switch"]="Переключатель вида",
 ["search"]="Поиск",
 ["branch button"]="Кнопка ветки",
 ["tab button"]="Кнопка вкладки",
 ["control row"]="Строка настройки",
 ["action button"]="Кнопка действия",
 ["visual catalog"]="Каталог",
 ["top capsule"]="Верхняя капсула",
 ["12:00 · clock"]="12:00 · Часы",
 ["120 fps"]="120 FPS",
 ["dock"]="Док",
 ["w a s d"]="W A S D",
 ["module row"]="Строка модуля",
 ["afk screen"]="Экран AFK",
 ["afk return"]="Выход из AFK",
 ["practice widget"]="Виджет тренировки",
 ["individual style"]="Индивидуальный стиль",
 ["fill color"]="Цвет заливки",
 ["fill transparency %"]="Прозрачность заливки %",
 ["outline color"]="Цвет обводки",
 ["outline transparency %"]="Прозрачность обводки %",
 ["outline width (tenths px)"]="Толщина обводки (0,1 пикс.)",
 ["text color"]="Цвет текста",
 ["secondary text color"]="Цвет вторичного текста",
 ["gradient end"]="Конец градиента",
 ["custom text color"]="Свой цвет текста",
 ["custom secondary text color"]="Свой вторичный текст",
 ["custom gradient end"]="Свой конец градиента",
 ["fill"]="Заливка",
 ["outline"]="Обводка",
 ["text & gradient"]="Текст и градиент",
 ["afk palette"]="Палитра AFK",
 ["quick menu palette"]="Палитра быстрого меню",
 ["pressed key"]="Нажатая клавиша",
 ["status dot"]="Индикатор состояния",
 ["infinite workspace"]="Бесконечное пространство",
 ["reset camera"]="Сбросить камеру",
 ["reset current workspace"]="Сбросить пространство",
 ["reset this element"]="Сбросить элемент",
 ["preview afk screen"]="Предпросмотр AFK",
 ["reset afk appearance"]="Сбросить оформление AFK",
 ["quick menu / appearance"]="Быстрое меню / оформление",
 ["reset quick menu appearance"]="Сбросить быстрое меню",
 ["layout & widgets"]="Расположение и виджеты",
 ["widget transitions"]="Переходы виджетов",
 ["edit gui size / position"]="Размер и позиция GUI",
 ["edit hud size / position"]="Размер и позиция HUD",
 ["reset gui layout"]="Сбросить GUI",
 ["save configuration"]="Сохранить конфигурацию",
 ["liquid glass"]="Жидкое стекло",
 ["space background"]="Космический фон",
 ["motion"]="Анимации",
 ["edit widget positions"]="Расположение виджетов",
 ["edit appearance"]="Изменить оформление",
 ["reset panel position"]="Сбросить позицию",
 ["return to workspace"]="ВЕРНУТЬСЯ",
 ["appearance preview"]="Предпросмотр оформления",
 ["aether · time"]="AETHER · ВРЕМЯ",
 ["performance"]="ПРОИЗВОДИТЕЛЬНОСТЬ",
 ["example setting"]="Пример настройки",
 ["interface option"]="Параметр интерфейса",
 ["example module"]="Пример модуля",
 ["visual setting"]="Визуальная настройка",
 ["sample toggle"]="Пример переключателя",
 ["modules / preview"]="МОДУЛИ / ПРЕДПРОСМОТР",
 ["no keybinds assigned"]="Нет привязок",
 ["ready"]="Готово",
 ["preview only"]="Только предпросмотр",
 ["tap a module to expand"]="Нажмите на модуль",
 ["bind"]="Привязать",
 ["press key"]="НАЖМИТЕ КЛАВИШУ",
 ["on"]="ВКЛ",
 ["off"]="ВЫКЛ",
 ["yes"]="Да",
 ["no"]="Нет",
 ["solid"]="Однотонный",
 ["gradient"]="Градиент",
 ["stars"]="Звёзды",
 ["grid"]="Сетка",
 ["orbits"]="Орбиты",
 ["image"]="Изображение",
 ["glass"]="Стекло",
 ["fade"]="Затухание",
 ["slide"]="Сдвиг",
 ["smooth"]="Плавно",
 ["linear"]="Линейно",
 ["sine"]="Синус",
 ["float"]="Парение",
 ["pulse"]="Пульсация",
 ["custom"]="Свой",
 ["sketch"]="Эскиз",
 ["left"]="Слева",
 ["right"]="Справа",
 ["top"]="Сверху",
 ["bottom"]="Снизу",
 ["floating"]="Свободно",
 ["mixed"]="Смешанный",
 ["high"]="Высокое",
 ["low"]="Низкое",
 ["balanced"]="Среднее",
 ["ultra"]="Ультра",
 ["local"]="Локально",
 ["replicated"]="Репликация",
 ["none"]="Нет",
 ["both"]="Оба",
 ["name"]="Имя",
 ["distance"]="Расстояние",
 ["pause"]="Пауза",
 ["play"]="Воспроизвести",
 ["reset view"]="Сбросить вид",
 ["save new"]="Сохранить новый",
 ["load"]="Загрузить",
 ["update selected"]="Обновить выбранный",
 ["rename"]="Переименовать",
 ["duplicate"]="Дублировать",
 ["delete"]="Удалить",
 ["save now"]="Сохранить сейчас",
 ["reload bank"]="Перезагрузить конфиги",
 ["export bank"]="Экспорт",
 ["import bank"]="Импорт",
 ["hide json tools"]="Скрыть JSON",
 ["advanced / json backup"]="Дополнительно / JSON",
 ["config manager"]="МЕНЕДЖЕР КОНФИГУРАЦИЙ",
 ["storage"]="ХРАНИЛИЩЕ",
 ["refresh"]="Обновить",
 ["clear log"]="Очистить журнал",
 ["reset settings"]="Сбросить настройки",
 ["session"]="СЕССИЯ",
 ["session events"]="События сессии",
 ["unload"]="Выгрузить",
 ["camera"]="КАМЕРА",
 ["shift lock"]="SHIFT LOCK / БЛОКИРОВКА",
 ["quick menu / modules"]="БЫСТРОЕ МЕНЮ / МОДУЛИ",
 ["follow"]="Слежение",
 ["first person"]="От первого лица",
 ["orbit"]="Орбита",
 ["custom lock / keybind"]="БЛОКИРОВКА КАМЕРЫ / КЛАВИША",
 ["shift-lock / reticle"]="SHIFT-LOCK / ПРИЦЕЛ",
 ["live input display"]="ВВОД В РЕАЛЬНОМ ВРЕМЕНИ",
 ["widget layout"]="РАСПОЛОЖЕНИЕ ВИДЖЕТОВ",
 ["trail colors"]="ЦВЕТА ШЛЕЙФА",
 ["search native typefaces"]="Поиск шрифтов",
 ["accent"]="Акцент",
 ["second neon"]="Второй неоновый цвет",
 ["glass tint"]="Цвет стекла",
 ["studio text color"]="Цвет текста интерфейса",
 ["studio secondary text"]="Вторичный текст интерфейса",
 ["original icon atlas roblox asset id"]="ID атласа иконок Roblox",
 ["atlas tile size (pixels)"]="Размер плитки атласа (пикс.)",
 ["glass opacity %"]="Непрозрачность стекла %",
 ["neon rim %"]="Неоновая обводка %",
 ["floating sparkles"]="Летающие искры",
 ["animated geometric background"]="Анимированный геометрический фон",
 ["background style"]="Стиль фона",
 ["background density"]="Плотность фона",
 ["background speed %"]="Скорость фона %",
 ["background intensity %"]="Интенсивность фона %",
 ["maximum connections"]="Максимум соединений",
 ["connection distance (px)"]="Дальность соединений (пикс.)",
 ["line width (tenths of px)"]="Толщина линий (0,1 пикс.)",
 ["figure size (px)"]="Размер фигур (пикс.)",
 ["background gradient angle"]="Угол градиента фона",
 ["background start"]="Начало фона",
 ["background end"]="Конец фона",
 ["line start"]="Начало линии",
 ["line end"]="Конец линии",
 ["figure start"]="Начало фигуры",
 ["figure end"]="Конец фигуры",
 ["menu screen particles"]="Частицы меню",
 ["screen particle style"]="Стиль частиц",
 ["screen particle count"]="Количество частиц",
 ["screen particle intensity %"]="Интенсивность частиц %",
 ["roblox shortcuts rail"]="Панель кнопок Roblox",
 ["top aether title"]="Верхний заголовок AETHER",
 ["menu docking side"]="Сторона закрепления меню",
 ["menu width (px)"]="Ширина меню (пикс.)",
 ["menu height (px)"]="Высота меню (пикс.)",
 ["drag / snap menu"]="Перетаскивание меню",
 ["resize with corner grip"]="Изменение размера за угол",
 ["floating horizontal %"]="Свободная позиция X %",
 ["floating vertical %"]="Свободная позиция Y %",
 ["reduce motion"]="Уменьшить анимации",
 ["animation speed %"]="Скорость анимации %",
 ["transition (ms)"]="Переход (мс)",
 ["interpolation"]="Интерполяция",
 ["menu transition"]="Переход меню",
 ["menu motion intensity %"]="Интенсивность движения меню %",
 ["animated page transitions"]="Анимация смены страниц",
 ["animated navigation glow"]="Свечение навигации",
 ["lock widget positions"]="Закрепить виджеты",
 ["allow moving top and left panels"]="Перемещение верхней и левой панелей",
 ["custom top panel position"]="Своя позиция верхней панели",
 ["top panel x %"]="Верхняя панель X %",
 ["top panel y %"]="Верхняя панель Y %",
 ["custom left panel position"]="Своя позиция левой панели",
 ["left panel x %"]="Левая панель X %",
 ["left panel y %"]="Левая панель Y %",
 ["show keybind widget"]="Показать горячие клавиши",
 ["custom keybind position"]="Своя позиция горячих клавиш",
 ["keybind widget x %"]="Горячие клавиши X %",
 ["keybind widget y %"]="Горячие клавиши Y %",
 ["custom quick menu position"]="Своя позиция быстрого меню",
 ["quick menu x %"]="Быстрое меню X %",
 ["quick menu y %"]="Быстрое меню Y %",
 ["compact health panel"]="Компактная панель здоровья",
 ["hud layout"]="Расположение HUD",
 ["widget transition"]="Переход виджета",
 ["widget motion intensity %"]="Интенсивность анимации виджета %",
 ["health bar shimmer"]="Блики полосы здоровья",
 ["damage and healing glow"]="Свечение при изменении здоровья",
 ["hud smoothing (ms)"]="Плавность HUD (мс)",
 ["health"]="Здоровье",
 ["player card"]="Карточка игрока",
 ["aether menu button"]="Кнопка AETHER",
 ["horizontal %"]="Горизонталь %",
 ["vertical %"]="Вертикаль %",
 ["scale %"]="Масштаб %",
 ["rotation"]="Поворот",
 ["opacity %"]="Непрозрачность %",
 ["last page"]="Последняя вкладка",
 ["panel tint"]="Цвет панели",
 ["button tint"]="Цвет кнопки",
 ["selected button tint"]="Цвет выбранной кнопки",
 ["control row tint"]="Цвет строки настройки",
 ["glass edge tint"]="Цвет края стекла",
 ["glass highlight"]="Блик стекла",
 ["clock glass tint"]="Цвет стекла часов",
 ["fps glass tint"]="Цвет стекла FPS",
 ["clock text"]="Текст часов",
 ["fps text"]="Текст FPS",
 ["panel opacity %"]="Непрозрачность панели %",
 ["glass reflection %"]="Отражение стекла %",
 ["custom gui arrangement"]="Свое расположение GUI",
 ["gui horizontal position %"]="Позиция GUI X %",
 ["gui vertical position %"]="Позиция GUI Y %",
 ["gui width %"]="Ширина GUI %",
 ["gui height %"]="Высота GUI %",
 ["branch rail width"]="Ширина панели веток",
 ["top capsule scale %"]="Масштаб верхней капсулы %",
 ["workspace view"]="Вид пространства",
 ["workspace zoom %"]="Масштаб пространства %",
 ["afk background style"]="Стиль фона AFK",
 ["afk background start"]="Начало фона AFK",
 ["afk background end"]="Конец фона AFK",
 ["afk pattern color"]="Цвет узора AFK",
 ["afk brand color"]="Цвет логотипа AFK",
 ["afk title color"]="Цвет заголовка AFK",
 ["afk description color"]="Цвет описания AFK",
 ["afk button color"]="Цвет кнопки AFK",
 ["afk button text"]="Текст кнопки AFK",
 ["afk button outline"]="Обводка кнопки AFK",
 ["afk image tint"]="Оттенок изображения AFK",
 ["afk gradient angle"]="Угол градиента AFK",
 ["afk pattern opacity %"]="Непрозрачность узора AFK %",
 ["afk image opacity %"]="Непрозрачность изображения AFK %",
 ["afk fade duration (ms)"]="Длительность перехода AFK (мс)",
 ["afk image asset id"]="ID изображения AFK",
 ["quick menu glass tint"]="Цвет стекла быстрого меню",
 ["quick menu row tint"]="Цвет строки быстрого меню",
 ["quick menu accent"]="Акцент быстрого меню",
 ["quick menu outline"]="Обводка быстрого меню",
 ["quick menu text"]="Текст быстрого меню",
 ["quick menu secondary text"]="Вторичный текст быстрого меню",
 ["quick menu on color"]="Цвет включения",
 ["quick menu off color"]="Цвет выключения",
 ["quick menu opacity %"]="Непрозрачность быстрого меню %",
 ["quick menu fade duration (ms)"]="Переход быстрого меню (мс)",
 ["custom walking animation"]="Своя анимация ходьбы",
 ["animation playback"]="Воспроизведение анимации",
 ["walking style"]="Стиль ходьбы",
 ["walking intensity %"]="Интенсивность ходьбы %",
 ["motion studio configuration"]="Настройки Motion Studio",
 ["aura particles"]="Частицы ауры",
 ["motion trail"]="Шлейф движения",
 ["emission / second"]="Частиц в секунду",
 ["trail lifetime (ms)"]="Время жизни шлейфа (мс)",
 ["aura color"]="Цвет ауры",
 ["show wings"]="Показать крылья",
 ["silhouette"]="Силуэт",
 ["span %"]="Размах %",
 ["sweep (degrees)"]="Стреловидность (град.)",
 ["flap speed %"]="Скорость взмахов %",
 ["feather color"]="Цвет перьев",
 ["prismatic feathers"]="Радужные перья",
 ["feather detail"]="Детализация перьев",
 ["walking wing reaction"]="Реакция крыльев на ходьбу",
 ["original sketch palette"]="Исходная палитра",
 ["wing neon glow %"]="Неоновое свечение крыльев %",
 ["floating motion %"]="Парение %",
 ["red rotating diamond"]="Красный вращающийся ромб",
 ["blue rotating diamond"]="Синий вращающийся ромб",
 ["diamond rotation %"]="Вращение ромба %",
 ["diamond size %"]="Размер ромба %",
 ["diamond rotation echoes"]="Следы вращения ромба",
 ["show halo"]="Показать нимб",
 ["orbit form"]="Форма орбиты",
 ["radius %"]="Радиус %",
 ["height above head %"]="Высота над головой %",
 ["orbit speed %"]="Скорость орбиты %",
 ["halo color"]="Цвет нимба",
 ["prismatic halo"]="Радужный нимб",
 ["halo geometry detail"]="Детализация нимба",
 ["walking halo reaction"]="Реакция нимба на ходьбу",
 ["primary color"]="Основной цвет",
 ["secondary color"]="Вторичный цвет",
 ["size %"]="Размер %",
 ["height %"]="Высота %",
 ["rotation speed %"]="Скорость вращения %",
 ["neon glow %"]="Неоновое свечение %",
 ["outline thickness %"]="Толщина обводки %",
 ["shape count"]="Количество фигур",
 ["tilt degrees"]="Наклон (град.)",
 ["apply local atmosphere"]="Локальная атмосфера",
 ["high sky"]="Верх неба",
 ["horizon"]="Горизонт",
 ["ground light"]="Освещение земли",
 ["fog density %"]="Плотность тумана %",
 ["time (tenths of an hour)"]="Время (0,1 часа)",
 ["brightness %"]="Яркость %",
 ["saturation %"]="Насыщенность %",
 ["depth blur"]="Размытие глубины",
 ["atmosphere fade (ms)"]="Переход атмосферы (мс)",
 ["contrast %"]="Контраст %",
 ["exposure %"]="Экспозиция %",
 ["atmospheric glare %"]="Блики атмосферы %",
 ["sun rays %"]="Солнечные лучи %",
 ["depth of field %"]="Глубина резкости %",
 ["focus distance (studs)"]="Дальность фокуса (studs)",
 ["bloom radius"]="Радиус свечения",
 ["falling shapes"]="Падающие фигуры",
 ["falling shape"]="Форма падающих фигур",
 ["star rotation (degrees/sec)"]="Вращение звёзд (град./с)",
 ["star material"]="Материал звёзд",
 ["star count"]="Количество звёзд",
 ["fall speed (studs/sec)"]="Скорость падения (studs/с)",
 ["star size (tenths of stud)"]="Размер звёзд (0,1 stud)",
 ["star opacity %"]="Непрозрачность звёзд %",
 ["star neon glow %"]="Свечение звёзд %",
 ["star streaks"]="Следы звёзд",
 ["rainbow stars"]="Радужные звёзды",
 ["star color start"]="Начальный цвет звёзд",
 ["star color end"]="Конечный цвет звёзд",
 ["directional indicators"]="Указатели направления",
 ["indicator shape"]="Форма указателя",
 ["size (px)"]="Размер (пикс.)",
 ["corner softness %"]="Скругление углов %",
 ["distance from edges %"]="Отступ от краёв %",
 ["rotation smoothing (ms)"]="Плавность вращения (мс)",
 ["neon intensity %"]="Интенсивность неона %",
 ["neon spread (px)"]="Рассеивание неона (пикс.)",
 ["gradient start"]="Начало градиента",
 ["rainbow gradient"]="Радужный градиент",
 ["pulsation"]="Пульсация",
 ["arrow labels"]="Подписи стрелок",
 ["nearby nameplates"]="Имена поблизости",
 ["tracking range (studs)"]="Дальность отслеживания (studs)",
 ["custom game pointer"]="Свой игровой курсор",
 ["pointer shape"]="Форма курсора",
 ["pointer size"]="Размер курсора",
 ["pointer glow %"]="Свечение курсора %",
 ["desktop aether palette"]="Палитра AETHER",
 ["hotspot x %"]="Точка клика X %",
 ["hotspot y %"]="Точка клика Y %",
 ["rainbow pointer"]="Радужный курсор",
 ["gradient speed %"]="Скорость градиента %",
 ["cursor animation"]="Анимация курсора",
 ["cursor motion trail"]="Шлейф курсора",
 ["trail style"]="Стиль шлейфа",
 ["trail width (tenths of px)"]="Толщина шлейфа (0,1 пикс.)",
 ["trail spacing (px)"]="Интервал шлейфа (пикс.)",
 ["trail glow %"]="Свечение шлейфа %",
 ["trail start"]="Начало шлейфа",
 ["trail end"]="Конец шлейфа",
 ["pointer offset x (px)"]="Смещение курсора X (пикс.)",
 ["pointer offset y (px)"]="Смещение курсора Y (пикс.)",
 ["show hotspot marker"]="Показать точку клика",
 ["roblox image asset id"]="ID изображения Roblox",
 ["enable camera settings"]="Настройки камеры",
 ["camera mode"]="Режим камеры",
 ["field of view"]="Поле зрения",
 ["shoulder offset (tenths)"]="Смещение плеча (0,1)",
 ["height offset (tenths)"]="Смещение высоты (0,1)",
 ["orbit radius (studs)"]="Радиус орбиты (studs)",
 ["orbit rate (degrees/s)"]="Скорость орбиты (град./с)",
 ["follow smoothing (ms)"]="Плавность слежения (мс)",
 ["custom camera lock"]="Своя блокировка камеры",
 ["share and see aether cosmetics"]="Обмен косметикой AETHER",
 ["peer rendering quality"]="Качество косметики других игроков",
 ["block both shift keys"]="Блокировать обе клавиши Shift",
 ["lock keybind"]="Клавиша блокировки",
 ["shift-lock reticle"]="Прицел Shift-lock",
 ["reticle size (px)"]="Размер прицела (пикс.)",
 ["reticle thickness (px)"]="Толщина прицела (пикс.)",
 ["reticle color"]="Цвет прицела",
 ["rainbow reticle"]="Радужный прицел",
 ["reticle animation"]="Анимация прицела",
 ["reticle animation %"]="Интенсивность анимации %",
 ["neon reticle glow"]="Неоновое свечение прицела",
 ["reticle glow intensity %"]="Интенсивность свечения %",
 ["reticle glow radius (px)"]="Радиус свечения (пикс.)",
 ["pulsating glow"]="Пульсирующее свечение",
 ["show input overlay"]="Показать клавиши",
 ["show mouse buttons"]="Показать кнопки мыши",
 ["input overlay x %"]="Панель клавиш X %",
 ["input overlay y %"]="Панель клавиш Y %",
 ["input overlay size %"]="Размер панели клавиш %",
 ["input overlay opacity %"]="Непрозрачность панели клавиш %",
 ["pressed key color"]="Цвет нажатой клавиши",
 ["wallhop helper"]="Тренировочный виджет",
 ["wallhop display x %"]="Тренировка X %",
 ["wallhop display y %"]="Тренировка Y %",
 ["wallhop display size %"]="Размер тренировки %",
 ["wallhop display opacity %"]="Непрозрачность тренировки %",
 ["typeface"]="Шрифт",
 ["weight"]="Насыщенность шрифта",
 ["optional roblox font family id"]="ID семейства шрифтов Roblox",
 ["preview text"]="Текст предпросмотра",
 ["hud type scale %"]="Размер текста HUD %",
 ["gradient lettering"]="Градиент текста",
 ["text outline %"]="Обводка текста %",
 ["letter glow %"]="Свечение букв %",
 ["letter color"]="Цвет букв",
 ["letter gradient"]="Градиент букв",
 ["middle mouse: pan. wheel on background or ctrl + wheel: zoom. drag node titles to move individual panels. home resets camera; shift + home resets the current workspace. double-click or double-tap the background to close."]="Средняя кнопка мыши — перемещение. Колесо на фоне или Ctrl + колесо — масштаб. Перетаскивайте ноды за заголовок. Home — сброс камеры, Shift + Home — сброс пространства. Двойное нажатие на фон закрывает меню.",
 ["edits automatically enable individual style and update live preview. turn it off to restore the shared theme."]="Изменения автоматически включают индивидуальный стиль и обновляют предпросмотр. Выключите его для возврата к общей теме.",
 ["type afk in the workspace to open its full-screen view. preview only changes appearance; it does not activate anti-afk."]="Введите AFK в рабочем пространстве для открытия экрана. Предпросмотр меняет только оформление.",
 ["image mode uses a roblox image asset id. only images accessible in the current experience can load."]="Укажите ID изображения Roblox. Доступны только разрешённые в текущей игре изображения.",
 ["independent colors and fade for the compact modules panel under the aether capsule."]="Отдельные цвета и плавный переход компактной панели под капсулой AETHER.",
 ["enabled styles use fade only. off disables transitions. no idle floating or pulsing."]="Плавное появление и исчезновение. Выкл. отключает переходы. Без постоянного покачивания и пульсации.",
 ["choose a branch on the left. visual collections, interface settings and profiles are organized separately."]="Выберите ветку слева. Визуальные коллекции, настройки интерфейса и конфигурации разделены.",
 ["no configurations yet. enter a name and save."]="Конфигураций пока нет. Введите имя и сохраните.",
 ["read-only practice display."]="Тренировочный виджет только для просмотра.",
}
local ruUpper="АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ"
local ruLower="абвгдеёжзийклмнопрстуфхцчшщъыьэюя"
local lowerMap={}
local lowerChars={}
for _,cp in utf8.codes(ruLower) do table.insert(lowerChars,utf8.char(cp)) end
local idx=0
for _,cp in utf8.codes(ruUpper) do idx+=1;lowerMap[utf8.char(cp)]=lowerChars[idx] end
function U.lowerText(str)
 local out={}
 for _,cp in utf8.codes(str) do local c=utf8.char(cp);out[#out+1]=lowerMap[c] or string.lower(c) end
 return table.concat(out)
end
function U.tr(s,str)
 if not s or s.language~="Russian" or type(str)~="string" then return str end
 local translated=russian[str:lower()]
 if translated then return translated end
 -- Generated setting labels and compound headings retain their original keys.
 local left,right=str:match("^(.-) · (.+)$")
 if left then return U.tr(s,left).." · "..U.tr(s,right) end
 left,right=str:match("^(.-)%s+/%s+(.+)$")
 if left then return U.tr(s,left).." / "..U.tr(s,right) end
 return str
end
function U.hex(s) return Color3.fromHex(s) end
function U.appearanceColor(s,id,slot,fallback)
 local key="appearance"..id..slot
 if s[key.."Custom"] and s[key] then return U.hex(s[key]) end
 return fallback
end
function U.appearanceText(s,id,muted,fallback)
 return U.appearanceColor(s,id,if muted then "Muted" else "Text",fallback)
end
function U.blockStyle(s,id,c,t,e,et,w)
 local p="appearance"..id
 if s[p.."Custom"] then
  return U.hex(s[p.."Color"]),s[p.."Transparency"]/100,U.hex(s[p.."Edge"]),s[p.."EdgeTransparency"]/100,s[p.."EdgeWidth"]/10
 end
 return c,t,e,et,w
end
function U.applyBlock(obj,s,id,c,t,e,et,w)
 local color,alpha,edge,edgeAlpha,width=U.blockStyle(s,id,c,t,e,et,w)
 obj.BackgroundColor3=color;obj.BackgroundTransparency=alpha
 local rim=obj:FindFirstChildOfClass("UIStroke")
 if not rim and s["appearance"..id.."Custom"] then rim=U.stroke(obj,edge,edgeAlpha,width) end
 if rim then
  rim.Color=edge;rim.Transparency=edgeAlpha;rim.Thickness=width
  rim.Enabled=width>0 and edgeAlpha<1
 end
end
function U.appearanceSample(s,d)
 local opacity=if type(d[4])=="number" then d[4] else s[d[4]]
 local edgeOpacity=if type(d[6])=="number" then d[6] else s[d[6]]
 return U.blockStyle(s,d[1],U.hex(s[d[3]]),1-opacity/100,U.hex(s[d[5]]),1-edgeOpacity/100,1.15)
end
function U.font(s) local w=Enum.FontWeight[s.weight];if s.fontAsset~="" then return Font.new("rbxassetid://"..s.fontAsset,w) end;local base=Font.fromEnum(Enum.Font[s.font]);return Font.new(base.Family,w,base.Style) end
function U.ease(t,name)
 t=math.clamp(t,0,1)
 if name=="Linear" then return t elseif name=="Sine" then return .5-.5*math.cos(math.pi*t) end
 -- Quintic smootherstep: continuous velocity and acceleration at both endpoints.
 return t*t*t*(t*(t*6-15)+10)
end
function U.approach(current,target,dt,seconds)
 if math.abs(current-target)<.0001 then return target end
 return target+(current-target)*math.exp(-dt/math.max(.001,seconds))
end
-- Horizontal air steering: rotate momentum instead of lerping opposing vectors.
-- No movement input or zero strength leaves the original velocity untouched.
function U.airRedirect(horizontal,input,cap,strength,dt)
 local magnitude=input.Magnitude
 local speed=horizontal.Magnitude
 local response=math.clamp(strength,0,100)/100
 dt=math.clamp(dt,0,.05)
 if magnitude<.01 or cap<=0 or response<=0 or dt<=0 then return horizontal end
 local target=math.atan2(input.Z,input.X)
 local angle=target
 if speed>.05 then
  local current=math.atan2(horizontal.Z,horizontal.X)
  local delta=math.atan2(math.sin(target-current),math.cos(target-current))
  local maxTurn=math.rad(900)*response*dt
  angle=current+math.clamp(delta,-maxTurn,maxTurn)
 end
 -- Keep existing momentum, including speeds above the nominal WalkSpeed.
 -- Steering cannot accelerate past the greater of current speed and WalkSpeed.
 local targetSpeed=math.max(speed,cap*math.min(magnitude,1))
 local nextSpeed=speed+(targetSpeed-speed)*(1-math.exp(-24*response*dt))
 return Vector3.new(math.cos(angle)*nextSpeed,0,math.sin(angle)*nextSpeed)
end
-- Swept sphere on an analytic curve. Subdivide high-curvature chords to
-- bound the geometric approximation independently of visual segment density.
function U.ballSweep(origin,v,a,j,t0,t1,radius,params)
 local function at(t)
  return origin+v*t+a*(.5*t*t)+j*(t*t*t/6)
 end
 local dt=t1-t0
 local curvature=math.max((a+j*t0).Magnitude,(a+j*t1).Magnitude)
 local tolerance=math.clamp(radius*.025,.008,.035)
 local steps=math.clamp(math.ceil(math.sqrt(curvature*dt*dt/(8*tolerance))),1,8)
 local prev=at(t0)
 for i=1,steps do
  local time=t0+dt*i/steps
  local nextPos=at(time)
  local delta=nextPos-prev
  local length=delta.Magnitude
  if length>.0001 then
   local hit=workspace:Spherecast(prev,radius,delta,params)
   if hit then
    local fraction=math.clamp(hit.Distance/length,0,1)
    return prev+delta*fraction,hit,time-dt/steps*(1-fraction)
   end
  end
  prev=nextPos
 end
 return prev,nil,t1
end
function U.keys(t) local a={};for k in t do table.insert(a,k) end;table.sort(a);return a end
function U.count(t) local n=0;for _ in t do n+=1 end;return n end
return U
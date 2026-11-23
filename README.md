# AETHER — Luau

Исходники AETHER в виде отдельных Luau-модулей. Подготовлено для GitHub и Rojo.

## Статус

В архиве Astra было 12 файлов Luau. Они сохранены **без переписывания**.

**Важно:** клиентский стартовый скрипт (`*.client.luau`), связывающий модули
в работающий HUD, отсутствует в полученном архиве. Поэтому данное состояние
проекта **ещё не запускает полноценный AETHER**. Его должен добавить разработчик
после завершения работы над клиентской инициализацией.

## Структура

- `src/shared/` — 11 модулей Luau (`require(script.Parent.Имя)`).
- `src/server/Profiles.server.luau` — серверное хранение профилей.
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
в `ServerScriptService.AetherProfiles`.

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

Добавить клиентскую точку входа в `StarterPlayerScripts`, которая инициализирует
Schema, HUD, Controls, Pages, Avatar, View, World, Storage и другие подсистемы,
связывает события и выполняет очистку. После этого проверить Luau-код
непосредственно в Roblox Studio. Компиляция и игровой тест не выполнялись.
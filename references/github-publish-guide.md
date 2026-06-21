# Как загрузить скилл на GitHub

Это руководство — как правильно выложить скилл `windows-russia-anti-dpi` на GitHub, чтобы другие пользователи могли им воспользоваться.

## 1. Подготовка репозитория

### Структура скилла (уже готова):
```
windows-russia-anti-dpi/
├── SKILL.md                          # главный файл скилла (frontmatter + инструкции)
├── scripts/
│   ├── block-webrtc.ps1              # Фаза 1: STUN/TURN/mDNS блок
│   ├── disable-quic.ps1              # Фаза 2: полное отключение QUIC
│   ├── disable-ipv6-full.ps1         # Фаза 3: полное отключение IPv6
│   ├── tcp-stack-tuning.ps1          # Фаза 4: тюнинг TCP стека
│   ├── telemetry-block.ps1           # Фаза 5a: телеметрия
│   ├── fix-all.ps1                   # Фаза 5b: службы + SSDP/LLMNR
│   ├── mtu-watcher.ps1               # Watcher для MTU + IPv6 на TUN
│   ├── create-task-schtasks.ps1      # Создание scheduled task
│   └── final-audit.ps1               # Финальный аудит (17 проверок)
├── references/
│   ├── troubleshooting.md            # типичные грабли
│   └── scripts-reference.md          # описание скриптов
├── README.md                         # README для GitHub (создаём ниже)
└── LICENSE                           # лицензия (создаём)
```

### Инициализация git-репозитория:
```bash
cd windows-russia-anti-dpi
git init
git add .
git commit -m "Initial commit: Windows 11 Russia anti-DPI & leak hardening skill"
```

## 2. Создание README.md для GitHub

README — это лицо репозитория. Он должен объяснять:
- что это и зачем
- кому подойдёт (Россия, Windows 11, HAPP/Clash/sing-box/VLESS+Reality)
- что делает (кратко, по фазам)
- как установить
- как проверить результат
- предупреждения о безопасности

Шаблон README.md ниже — создай этот файл в корне репозитория.

## 3. Лицензия

Для таких утилит хорошо подходит **MIT** — разрешает любое использование с сохранением копирайта.

Создай файл `LICENSE` (полный текст MIT-лицензии).

## 4. Загрузка на GitHub

### Через веб:
1. Зайди на https://github.com/new
2. Repository name: `windows-russia-anti-dpi`
3. Description: `Windows 11 anti-DPI & leak hardening skill for Russia (HAPP/Clash/sing-box + VLESS+Reality)`
4. **Public** (чтобы другие могли пользоваться)
5. НЕ ставь галки "Add README" / "Add .gitignore" / "license" — мы создадим свои локально
6. Create repository

### Привязка и push:
```bash
git remote add origin https://github.com/<твой-username>/windows-russia-anti-dpi.git
git branch -M main
git push -u origin main
```

## 5. Релиз (опционально, но полезно)

Релизы позволяют пользователям скачать архив без git:
1. На странице репозитория → **Releases** → **Create a new release**
2. Choose a tag → `v1.0.0` → Create new tag
3. Release title: `v1.0.0 — Initial release`
4. Description: скопируй ключевые пункты из README
5. Attach binaries: заархивируй папку в `windows-russia-anti-dpi-v1.0.0.zip` и прикрепи
6. Publish release

## 6. Популяризация (чтобы люди нашли)

- **Reddit:** r/russia, r/VPN, r/privacy, r/Piracy — пост с описанием и ссылкой
- **Habr:** статья "Настройка Windows 11 для обхода ТСПУ и защиты от утечек"
- **Telegram:** каналы по обходу блокировок, уютненькие каналы про DPI
- **4PDA / XX-XXX:** тема в разделе про обход блокировок
- **GitHub topics:** в About репозитория добавь топики: `windows`, `windows-11`, `anti-dpi`, `russia`, `vpn`, `proxy`, `vless`, `reality`, `happ`, `clash`, `sing-box`, `webrtc`, `leak-protection`, `privacy`, `powershell`

## 7. Поддержка и развитие

- В README добавь секцию **Issues** — куда писать о проблемах
- Создай `CONTRIBUTING.md` с правилами для контрибьюторов
- Включи GitHub Issues и Discussions
- Отмечай версии через git tags (`v1.0.0`, `v1.1.0`, ...)

## 8. Как пользователи будут устанавливать скилл

После публикации пользователи могут установить скилл двумя способами:

### Способ A — через pi settings.json (рекомендуемый для pi):
```json
{
  "skills": [
    "https://github.com/<username>/windows-russia-anti-dpi"
  ]
}
```

### Способ B — ручное клонирование:
```bash
git clone https://github.com/<username>/windows-russia-anti-dpi.git ~/.pi/agent/skills/windows-russia-anti-dpi
```
Затем запустить pi — скилл подхватится автоматически.

### Способ C — без pi (как набор скриптов):
```bash
git clone https://github.com/<username>/windows-russia-anti-dpi.git
cd windows-russia-anti-dpi/scripts
# Запускать скрипты вручную от администратора по фазам
```

## 9. Чек-лист перед публикацией

- [ ] README.md создан и проверен
- [ ] LICENSE добавлен (MIT)
- [ ] В SKILL.md корректный frontmatter (name, description)
- [ ] Все скрипты проверены на реальной машине
- [ ] В скриптах нет хардкода личных данных (IP, пути пользователя)
- [ ] В mtu-watcher.ps1 и final-audit.ps1 переменные `$tunName` помечены как "измени под себя"
- [ ] troubleshooting.md покрывает все грабли сессии
- [ ] .gitignore исключает логи (*.log, *.bin)
- [ ] Коммит и push выполнены
- [ ] Release опубликован
- [ ] Topics добавлены в About

## 10. Предупреждение в README (обязательно)

В README должен быть блок **⚠️ ВНИМАНИЕ**:
- Скрипты меняют системные настройки Windows — выполняй на свой страх и риск
- Обязательно создавай точку восстановления Windows перед запуском
- Скрипты отключают IPv6 полностью — это может сломать некоторые локальные сервисы
- Все скрипты требуют прав администратора
- Перед запуском проверь содержимое скриптов — не запускай вслепую
- Автор не несёт ответственности за любой ущерб

# Development Tasks: MVP AI Finance

**Версия:** 0.1 (черновик для обсуждения)
**Авторы:** Business Analyst + Principal Architect (декомпозиция [MVP_Spec.md](MVP_Spec.md))
**Дата:** 2026-07-16
**Статус:** на согласование

> Каждая задача — ≤1 рабочий день (правило CLAUDE.md), с чётким описанием, списком затрагиваемых файлов, тест-планом и зависимостью **только от уже перечисленных выше задач** — ни одна задача не ссылается вперёд. Порядок в документе = порядок исполнения.

---

## 0. Соглашения

### Предполагаемая структура репозитория

Ещё не создана в коде — фиксируется здесь как основа для путей к файлам ниже, подлежит подтверждению с DevOps перед первой задачей (T0.1):

```
backend/
  src/
    modules/<module>/
      domain/            (entities, repository-интерфейсы, domain events)
      application/       (use-cases)
      infrastructure/    (controllers, DTO, repository-реализации, внешние клиенты)
    database/
      migrations/
      seeds/
    shared/              (SharedKernel: currency, exchange-rate, общие guards/фильтры)
    main.ts               (entrypoint API-процесса)
    worker.ts             (entrypoint Worker-процесса)
  test/                   (integration/e2e-тесты, *.e2e-spec.ts)
mobile/
  lib/
    core/                (сетевой клиент, локальная БД, тема, роутер, уведомления)
    features/<feature>/
      presentation/      (screens, widgets, providers)
      domain/            (entities, usecases, repository-интерфейсы)
      data/              (repository-реализации, datasources)
  test/                   (widget/unit-тесты, зеркалят lib/)
.github/workflows/
docker-compose.yml
```

### Схема нумерации задач

`T<модуль>.<порядковый номер>` — модуль соответствует нумерации `M0`–`M10` из [MVP_Spec.md](MVP_Spec.md). Задачи внутри модуля и сами модули идут в порядке, обязательном к исполнению (граф зависимостей — в [MVP_Spec.md §1](MVP_Spec.md#1-модули-и-порядок-реализации)).

### Общий для всех задач пункт Definition of Done

Не повторяется в каждой карточке — см. единый чек-лист в [12_Backlog.md §0](12_Backlog.md#0-легенда). Тест-план ниже — это *что именно* проверяется сверх общего DoD, специфичное для задачи.

---

## Модуль M0 — Инфраструктура и фундамент

| ID | Задача | Зависит от |
|---|---|---|
| T0.1 | Инициализация backend-проекта NestJS | — |
| T0.2 | Docker Compose для dev-окружения | T0.1 |
| T0.3 | Первая миграция: расширения и ENUM-типы | T0.2 |
| T0.4 | GitHub Actions: lint + typecheck + unit-тесты на PR | T0.1 |
| T0.5 | Автодеплой в Staging при merge в main | T0.4, T0.2 |
| T0.6 | Инициализация Flutter-приложения и Splash-заглушка | — |

#### T0.1 — Инициализация backend-проекта NestJS
**Описание:** Создать базовый NestJS-проект с корневым модулем, конфигурацией окружения (`.env`) и одним health-check эндпоинтом.
**Файлы:**
- `backend/src/main.ts`
- `backend/src/app.module.ts`
- `backend/src/modules/health/health.controller.ts`
- `backend/package.json`
- `backend/tsconfig.json`
- `backend/.eslintrc.js`
**Тест-план:**
- Unit: `health.controller.spec.ts` — `GET /health` возвращает `200` и `{ "status": "ok" }`
- Ручная проверка: `npm run start:dev` поднимается без ошибок
**Зависит от:** —

#### T0.2 — Docker Compose для dev-окружения
**Описание:** Поднять `api`, `postgres`, `redis` в единой `docker-compose.yml` для локальной разработки с hot-reload backend.
> `worker` (второй entrypoint из [06_Architecture.md §10](06_Architecture.md#10-docker)) сюда не входит: на момент этой задачи в коде нет ни одного потребителя очереди (cron MVP работает через `@nestjs/schedule` внутри `api`, Redis в MVP — только прямой кэш). Заводится отдельной задачей, когда появится первая реальная очередь (Beta).
**Файлы:**
- `docker-compose.yml`
- `backend/Dockerfile` (dev-стадия; production-сборка — отдельно в T0.5)
- `.env.example`
**Тест-план:**
- Ручная проверка: `docker-compose up` поднимает 3 контейнера, `postgres`/`redis` переходят в `healthy` до старта `api`, `GET /health` доступен с хоста
- Ручная проверка: изменение файла в `backend/src` перезапускает процесс без пересборки образа
**Зависит от:** T0.1

#### T0.3 — Первая миграция: расширения и ENUM-типы
**Описание:** Настроить механизм миграций (data source) и первую миграцию с `CREATE EXTENSION pgcrypto`, ENUM-типами и функцией `set_updated_at()` из [07_Database.md §2–4](07_Database.md#2-расширения).
**Файлы:**
- `backend/src/database/data-source.ts`
- `backend/src/database/migrations/0001_init_extensions_and_enums.ts`
**Тест-план:**
- Integration: миграция `up` выполняется на чистой тестовой БД без ошибок
- Integration: миграция `down` откатывается без ошибок
**Зависит от:** T0.2

#### T0.4 — GitHub Actions: lint + typecheck + unit-тесты на PR
**Описание:** Настроить workflow, блокирующий merge при красном CI.
**Файлы:**
- `.github/workflows/ci.yml`
**Тест-план:**
- Ручная проверка: PR с намеренно проваленным тестом показывает красный статус и блокирует merge-кнопку
- Ручная проверка: корректный PR проходит все три шага (lint/typecheck/test) зелёным
**Зависит от:** T0.1

#### T0.5 — Автодеплой в Staging при merge в main
**Описание:** При успешном merge в `main` — сборка Docker-образа, push в registry, деплой в Staging.
**Файлы:**
- `.github/workflows/deploy-staging.yml`
**Тест-план:**
- Ручная проверка: тестовый merge в `main` триггерит деплой, `GET /health` на Staging отвечает `200` после завершения workflow
**Зависит от:** T0.4, T0.2

#### T0.6 — Инициализация Flutter-приложения и Splash-заглушка
**Описание:** Создать Flutter-проект, базовую тему ([09_Design_System.md](09_Design_System.md)), Splash-экран с автопереходом.
**Файлы:**
- `mobile/pubspec.yaml`
- `mobile/lib/main.dart`
- `mobile/lib/core/theme/app_theme.dart`
- `mobile/lib/features/splash/presentation/screens/splash_screen.dart`
- `mobile/lib/core/network/api_client.dart`
**Тест-план:**
- Widget-тест `splash_screen_test.dart`: логотип отрисовывается, автопереход происходит через заданный таймаут (таймер замокан)
**Зависит от:** —

---

## Модуль M1 — Auth & Onboarding

| ID | Задача | Зависит от |
|---|---|---|
| T1.1 | Схема БД: users, refresh_tokens, otp_codes | T0.3 |
| T1.2 | Backend: регистрация/вход + отправка OTP | T1.1 |
| T1.3 | Backend: подтверждение OTP + выдача JWT | T1.2 |
| T1.4 | Backend: refresh-токен с ротацией + logout | T1.3 |
| T1.5 | Backend: гостевой режим + апгрейд гостя | T1.3 |
| T1.6 | Backend: профиль пользователя (GET/PATCH /users/me) | T1.3 |
| T1.7 | Flutter: экраны Splash-обновление + выбор языка | T0.6 |
| T1.8 | Flutter: Onboarding value-экраны (карусель) | T1.7 |
| T1.9 | Flutter: экраны регистрации/входа + OTP | T1.8, T1.3 |
| T1.10 | Flutter: гостевой режим + экран выбора авторизации | T1.9, T1.5 |
| T1.11 | Flutter: токен-менеджмент клиента (auto-refresh) | T1.9, T1.4 |
| T1.12 | Flutter: первичная настройка аккаунта | T1.10, T1.6 |

#### T1.1 — Схема БД: users, refresh_tokens, otp_codes
**Описание:** Миграция и domain-сущности для таблиц `users`, `refresh_tokens`, `otp_codes` согласно [07_Database.md §5.1–5.3](07_Database.md#51-users) со всеми ограничениями.
**Файлы:**
- `backend/src/database/migrations/0002_users_auth.ts`
- `backend/src/modules/users/domain/entities/user.entity.ts`
- `backend/src/modules/auth/domain/entities/refresh-token.entity.ts`
- `backend/src/modules/auth/domain/entities/otp-code.entity.ts`
**Тест-план:**
- Integration: вставка пользователя без телефона и без email нарушает `chk_users_has_identifier`
- Integration: 6-я запись `otp_codes.attempts` для одного кода нарушает `chk_otp_attempts`
**Зависит от:** T0.3

#### T1.2 — Backend: регистрация/вход + отправка OTP
**Описание:** Реализовать `POST /auth/register` и `POST /auth/login`, генерацию и (заглушку) отправку OTP-кода.
**Файлы:**
- `backend/src/modules/auth/application/use-cases/register.use-case.ts`
- `backend/src/modules/auth/application/use-cases/login.use-case.ts`
- `backend/src/modules/auth/infrastructure/controllers/auth.controller.ts`
- `backend/src/modules/auth/infrastructure/dto/register.dto.ts`
- `backend/src/modules/auth/infrastructure/dto/login.dto.ts`
- `backend/src/modules/auth/infrastructure/services/otp-sender.service.ts`
**Тест-план:**
- Integration `auth.e2e-spec.ts`: `POST /auth/register` с новым телефоном возвращает `202` и `otpSentTo`
- Integration: повторная регистрация уже существующего телефона возвращает `409 USER_ALREADY_EXISTS`
**Зависит от:** T1.1

#### T1.3 — Backend: подтверждение OTP + выдача JWT
**Описание:** Реализовать `POST /auth/otp/verify` — проверка кода, создание пользователя (если новый), выдача access/refresh токенов.
**Файлы:**
- `backend/src/modules/auth/application/use-cases/verify-otp.use-case.ts`
- `backend/src/modules/auth/infrastructure/services/jwt.service.ts`
- `backend/src/modules/auth/infrastructure/repositories/refresh-token.repository.ts`
- `backend/src/modules/auth/infrastructure/controllers/auth.controller.ts` (доп. эндпоинт)
**Тест-план:**
- Integration: верный код возвращает `200` с валидным JWT (`sub`, `exp` проверены декодированием)
- Integration: неверный код возвращает `400 OTP_INVALID`
- Integration: 6-я подряд неверная попытка возвращает `429`, а не `400`
**Зависит от:** T1.2

#### T1.4 — Backend: refresh-токен с ротацией + logout
**Описание:** Реализовать `POST /auth/refresh` (с ротацией и отзывом при повторном использовании), `POST /auth/logout`, `POST /auth/logout-all`, `JwtAuthGuard`.
**Файлы:**
- `backend/src/modules/auth/application/use-cases/refresh-token.use-case.ts`
- `backend/src/modules/auth/application/use-cases/logout.use-case.ts`
- `backend/src/modules/auth/infrastructure/guards/jwt-auth.guard.ts`
**Тест-план:**
- Integration: `refresh` выдаёт новую пару и помечает старый refresh-токен `revoked_at`
- Integration: повторное использование уже отозванного refresh-токена возвращает `401 TOKEN_REVOKED` и отзывает все токены пользователя
**Зависит от:** T1.3

#### T1.5 — Backend: гостевой режим + апгрейд гостя
**Описание:** `POST /auth/guest` (токен со `scope: guest`, без refresh-токена), `POST /auth/guest/upgrade`.
**Файлы:**
- `backend/src/modules/auth/application/use-cases/guest-session.use-case.ts`
- `backend/src/modules/auth/application/use-cases/upgrade-guest.use-case.ts`
**Тест-план:**
- Integration: гостевой токен имеет `scope: guest`, попытка вызвать `/auth/refresh` с ним невозможна (нет refresh-токена)
- Integration: апгрейд гостя создаёт полноценного пользователя, привязанного к тому же `user_id`
**Зависит от:** T1.3

#### T1.6 — Backend: профиль пользователя
**Описание:** `GET /users/me`, `PATCH /users/me`.
**Файлы:**
- `backend/src/modules/users/application/use-cases/get-profile.use-case.ts`
- `backend/src/modules/users/application/use-cases/update-profile.use-case.ts`
- `backend/src/modules/users/infrastructure/controllers/users.controller.ts`
**Тест-план:**
- Integration: `GET /users/me` без токена — `401`; с токеном — корректные поля
- Integration: `PATCH` с невалидной `locale` (не `ru`/`kk`/`en`) — `400 VALIDATION_ERROR`
**Зависит от:** T1.3

#### T1.7 — Flutter: Splash-обновление и экран выбора языка
**Описание:** Дообработать Splash (ветвление сессии) и добавить экран выбора языка с сохранением выбора.
**Файлы:**
- `mobile/lib/features/splash/presentation/screens/splash_screen.dart` (обновление)
- `mobile/lib/features/onboarding/presentation/screens/language_screen.dart`
- `mobile/lib/core/localization/app_localizations.dart`
**Тест-план:**
- Widget-тест: выбор языка сохраняется в локальном хранилище и применяется без перезапуска
**Зависит от:** T0.6

#### T1.8 — Flutter: Onboarding value-экраны
**Описание:** Карусель из 3 value-экранов с кнопкой "Пропустить" ([04_User_Flows.md §2](04_User_Flows.md#2-первый-запуск-и-onboarding)).
**Файлы:**
- `mobile/lib/features/onboarding/presentation/screens/onboarding_carousel_screen.dart`
- `mobile/lib/features/onboarding/presentation/widgets/value_slide.dart`
**Тест-план:**
- Widget-тест: свайп переключает слайды; "Пропустить" на любом слайде ведёт на экран выбора авторизации
**Зависит от:** T1.7

#### T1.9 — Flutter: экраны регистрации/входа + OTP
**Описание:** Экраны регистрации, входа и ввода OTP-кода с интеграцией к API из T1.2/T1.3.
**Файлы:**
- `mobile/lib/features/auth/presentation/screens/register_screen.dart`
- `mobile/lib/features/auth/presentation/screens/login_screen.dart`
- `mobile/lib/features/auth/presentation/screens/otp_verify_screen.dart`
- `mobile/lib/features/auth/domain/repositories/auth_repository.dart`
- `mobile/lib/features/auth/data/repositories/auth_repository_impl.dart`
- `mobile/lib/features/auth/data/datasources/auth_remote_datasource.dart`
**Тест-план:**
- Widget-тест: неверный код показывает инлайн-ошибку без потери введённого номера телефона
- Integration-тест (мокнутый API): полный путь регистрация→OTP→переход на экран первичной настройки
**Зависит от:** T1.8, T1.3

#### T1.10 — Flutter: гостевой режим и экран выбора авторизации
**Описание:** Экран "Регистрация / Вход / Продолжить как гость".
**Файлы:**
- `mobile/lib/features/auth/presentation/screens/auth_choice_screen.dart`
- `mobile/lib/features/auth/domain/usecases/start_guest_session.dart`
**Тест-план:**
- Widget-тест: "Продолжить как гость" ведёт сразу на первичную настройку без полей ввода телефона
**Зависит от:** T1.9, T1.5

#### T1.11 — Flutter: токен-менеджмент клиента
**Описание:** Хранение access-токена в памяти, refresh-токена в secure storage, автоматическое обновление при `401`.
**Файлы:**
- `mobile/lib/core/network/token_manager.dart`
- `mobile/lib/core/network/auth_interceptor.dart`
**Тест-план:**
- Unit-тест: перехватчик при `401` вызывает `/auth/refresh` и повторяет исходный запрос ровно один раз (не зацикливается)
**Зависит от:** T1.9, T1.4

#### T1.12 — Flutter: первичная настройка аккаунта
**Описание:** Экран выбора базовой валюты и целей использования приложения.
**Файлы:**
- `mobile/lib/features/onboarding/presentation/screens/initial_setup_screen.dart`
- `mobile/lib/features/onboarding/domain/usecases/save_usage_goals.dart`
**Тест-план:**
- Widget-тест: мультивыбор целей сохраняется; валюта по умолчанию — KZT, изменяема
**Зависит от:** T1.10, T1.6

---

## Модуль M2 — Categories

| ID | Задача | Зависит от |
|---|---|---|
| T2.1 | Схема БД categories + seed системных категорий | T1.1 |
| T2.2 | Backend: CRUD категорий | T2.1 |
| T2.3 | Flutter: компонент выбора категории (Bottom Sheet) | T2.2, T1.11 |

#### T2.1 — Схема БД categories + seed системных категорий
**Описание:** Миграция таблицы `categories` и seed-скрипт локализованных (RU/KZ) системных категорий.
**Файлы:**
- `backend/src/database/migrations/0003_categories.ts`
- `backend/src/database/seeds/system-categories.seed.ts`
- `backend/src/modules/categories/domain/entities/category.entity.ts`
**Тест-план:**
- Integration: повторный запуск seed не создаёт дубликаты (проверка по `ux_categories_system_name`)
**Зависит от:** T1.1

#### T2.2 — Backend: CRUD категорий
**Описание:** `GET/POST/PATCH/DELETE /categories`.
**Файлы:**
- `backend/src/modules/categories/application/use-cases/create-category.use-case.ts`
- `backend/src/modules/categories/application/use-cases/update-category.use-case.ts`
- `backend/src/modules/categories/application/use-cases/delete-category.use-case.ts`
- `backend/src/modules/categories/infrastructure/controllers/categories.controller.ts`
- `backend/src/modules/categories/infrastructure/repositories/category.repository.ts`
**Тест-план:**
- Integration: попытка `PATCH`/`DELETE` системной категории (`user_id IS NULL`) возвращает `403`
- Integration: создание кастомной категории с именем, уже занятым у другого пользователя, не конфликтует
**Зависит от:** T2.1

#### T2.3 — Flutter: компонент выбора категории
**Описание:** Bottom Sheet выбора категории (сетка иконок) с инлайн-действием "+ Своя категория", переиспользуемый в Transactions и Budgets.
**Файлы:**
- `mobile/lib/features/categories/presentation/widgets/category_picker_sheet.dart`
- `mobile/lib/features/categories/domain/entities/category.dart`
- `mobile/lib/features/categories/data/repositories/category_repository_impl.dart`
**Тест-план:**
- Widget-тест: список показывает системные + кастомные категории пользователя; "+ создать" открывает мини-форму без закрытия родительского шита
**Зависит от:** T2.2, T1.11

---

## Модуль M3 — Wallet (Accounts)

| ID | Задача | Зависит от |
|---|---|---|
| T3.1 | Схема БД accounts + backend CRUD | T1.1 |
| T3.2 | Flutter: карусель счетов + детали счёта | T3.1, T1.11 |
| T3.3 | Flutter: добавление счёта (Bottom Sheet) | T3.2 |

> Ручная корректировка баланса (`POST /accounts/{id}/adjust-balance`) технически создаёт транзакцию — вынесена в **T4.3** (Модуль M4), т.к. зависит от таблицы `transactions`, которой ещё нет на этом этапе.

#### T3.1 — Схема БД accounts + backend CRUD
**Описание:** Миграция `accounts` и `GET/POST/PATCH/DELETE /accounts`, `GET /accounts/{id}`.
**Файлы:**
- `backend/src/database/migrations/0004_accounts.ts`
- `backend/src/modules/accounts/domain/entities/account.entity.ts`
- `backend/src/modules/accounts/application/use-cases/create-account.use-case.ts`
- `backend/src/modules/accounts/application/use-cases/update-account.use-case.ts`
- `backend/src/modules/accounts/application/use-cases/delete-account.use-case.ts`
- `backend/src/modules/accounts/infrastructure/controllers/accounts.controller.ts`
**Тест-план:**
- Integration: невалидный код валюты нарушает `chk_accounts_currency`
- Integration: `DELETE` — мягкое удаление (`deleted_at`), счёт пропадает из `GET /accounts`, но данные не физически удалены
**Зависит от:** T1.1

#### T3.2 — Flutter: карусель счетов + детали счёта
**Описание:** Экран Wallet с горизонтальной каруселью счетов и экран деталей одного счёта.
**Файлы:**
- `mobile/lib/features/wallet/presentation/screens/wallet_screen.dart`
- `mobile/lib/features/wallet/presentation/screens/account_detail_screen.dart`
- `mobile/lib/features/wallet/presentation/widgets/account_carousel.dart`
- `mobile/lib/features/wallet/domain/entities/account.dart`
- `mobile/lib/features/wallet/data/repositories/account_repository_impl.dart`
**Тест-план:**
- Widget-тест: карточка "+ Добавить счёт" всегда последняя в карусели; Empty-состояние при отсутствии счетов
**Зависит от:** T3.1, T1.11

#### T3.3 — Flutter: добавление счёта
**Описание:** Bottom Sheet добавления счёта с вариантами "Наличные"/"Ручной счёт".
**Файлы:**
- `mobile/lib/features/wallet/presentation/widgets/add_account_sheet.dart`
- `mobile/lib/features/wallet/domain/usecases/create_account.dart`
**Тест-план:**
- Widget-тест: вариант "Наличные" требует только название; сохранение закрывает шит и обновляет карусель
**Зависит от:** T3.2

---

## Модуль M4 — Transactions (+ OCR, AI-категоризация)

| ID | Задача | Зависит от |
|---|---|---|
| T4.1 | Схема БД transactions + receipt_scans | T3.1, T2.1 |
| T4.2 | Backend: CRUD транзакций (ручной ввод) | T4.1 |
| T4.3 | Backend: корректировка баланса счёта | T4.2, T3.1 |
| T4.4 | Backend: AI-автокатегоризация | T4.2 |
| T4.5 | Backend: OCR-сканирование чека | T4.4, T4.1 |
| T4.6 | Flutter: выбор способа ввода транзакции | T3.2, T2.3 |
| T4.7 | Flutter: экран ручного ввода транзакции | T4.6, T4.2 |
| T4.8 | Flutter: экран сканирования чека | T4.7, T4.5 |
| T4.9 | Flutter: лента транзакций с фильтрами | T4.7, T2.3 |

#### T4.1 — Схема БД transactions + receipt_scans
**Описание:** Миграции таблиц `transactions` и `receipt_scans` согласно [07_Database.md §5.6–5.7](07_Database.md#56-receipt_scans).
**Файлы:**
- `backend/src/database/migrations/0005_transactions.ts`
- `backend/src/modules/transactions/domain/entities/transaction.entity.ts`
- `backend/src/modules/ocr/domain/entities/receipt-scan.entity.ts`
**Тест-план:**
- Integration: `amount <= 0` нарушает `chk_transactions_amount_positive`
- Integration: вторая транзакция с тем же `receipt_scan_id` нарушает `ux_transactions_receipt_scan`
**Зависит от:** T3.1, T2.1

#### T4.2 — Backend: CRUD транзакций (ручной ввод)
**Описание:** `GET/POST/PATCH/DELETE /transactions`, `GET /transactions/{id}` с курсорной пагинацией и фильтрами.
**Файлы:**
- `backend/src/modules/transactions/application/use-cases/create-transaction.use-case.ts`
- `backend/src/modules/transactions/application/use-cases/list-transactions.use-case.ts`
- `backend/src/modules/transactions/application/use-cases/update-transaction.use-case.ts`
- `backend/src/modules/transactions/application/use-cases/delete-transaction.use-case.ts`
- `backend/src/modules/transactions/infrastructure/controllers/transactions.controller.ts`
- `backend/src/modules/transactions/infrastructure/dto/create-transaction.dto.ts`
**Тест-план:**
- Integration: создание с несуществующим `accountId` — `404`
- Integration: курсорная пагинация не теряет и не дублирует записи при вставке новой транзакции между двумя запросами страниц
**Зависит от:** T4.1

#### T4.3 — Backend: корректировка баланса счёта
**Описание:** `POST /accounts/{id}/adjust-balance` — создаёт корректирующую транзакцию с `source` пометкой.
**Файлы:**
- `backend/src/modules/accounts/application/use-cases/adjust-balance.use-case.ts`
- `backend/src/modules/accounts/infrastructure/controllers/accounts.controller.ts` (доп. эндпоинт)
**Тест-план:**
- Integration: вызов создаёт запись в `transactions` с корректной суммой/знаком и заметкой "Сверка баланса"
**Зависит от:** T4.2, T3.1

#### T4.4 — Backend: AI-автокатегоризация
**Описание:** Промпт категоризации из Prompt Registry, интеграция в `create-transaction.use-case`, кэш в Redis по `hash(merchant+amount)` ([10_AI.md §9](10_AI.md#9-prompt-engineering)).
**Файлы:**
- `backend/src/modules/ai/infrastructure/prompts/categorize.prompt.ts`
- `backend/src/modules/ai/infrastructure/services/categorization.service.ts`
- `backend/src/modules/transactions/application/use-cases/create-transaction.use-case.ts` (интеграция вызова)
**Тест-план:**
- Unit: при `confidence < 0.5` категория не проставляется автоматически
- Integration: повторный вызов с тем же мерчантом+суммой не порождает новый вызов OpenAI (мок считает количество обращений)
**Зависит от:** T4.2

#### T4.5 — Backend: OCR-сканирование чека
**Описание:** `POST /ocr/scans`, `GET /ocr/scans/{id}` — Google Vision → структурирование → предложенная категория.
**Файлы:**
- `backend/src/modules/ocr/infrastructure/services/vision.service.ts`
- `backend/src/modules/ocr/application/use-cases/scan-receipt.use-case.ts`
- `backend/src/modules/ocr/infrastructure/controllers/ocr.controller.ts`
- `backend/src/modules/ocr/infrastructure/prompts/parse-receipt.prompt.ts`
**Тест-план:**
- Integration: тестовый чек (фикстура-изображение) возвращает структурированный черновик за ≤3с
- Integration: нечитаемое изображение возвращает `422 RECEIPT_UNREADABLE`, не `500`
**Зависит от:** T4.4, T4.1

#### T4.6 — Flutter: выбор способа ввода транзакции
**Описание:** Bottom Sheet с вариантами "Вручную"/"Фото чека"/"Из шаблона".
**Файлы:**
- `mobile/lib/features/transactions/presentation/widgets/add_transaction_sheet.dart`
**Тест-план:**
- Widget-тест: каждый вариант ведёт на соответствующий экран/подшит
**Зависит от:** T3.2, T2.3

#### T4.7 — Flutter: экран ручного ввода транзакции
**Описание:** Форма суммы/категории/счёта/даты/заметки.
**Файлы:**
- `mobile/lib/features/transactions/presentation/screens/manual_entry_screen.dart`
- `mobile/lib/features/transactions/domain/entities/transaction.dart`
- `mobile/lib/features/transactions/data/repositories/transaction_repository_impl.dart`
**Тест-план:**
- Widget-тест: сумма `0` или пустая блокирует кнопку "Сохранить"; успешное сохранение закрывает шит и показывает тост-подтверждение
**Зависит от:** T4.6, T4.2

#### T4.8 — Flutter: экран сканирования чека
**Описание:** Камера с рамкой чека → экран предпросмотра распознанных данных (редактируемо) → подтверждение.
**Файлы:**
- `mobile/lib/features/transactions/presentation/screens/receipt_scan_screen.dart`
- `mobile/lib/features/transactions/presentation/screens/receipt_preview_screen.dart`
- `mobile/lib/features/transactions/data/datasources/ocr_remote_datasource.dart`
**Тест-план:**
- Widget-тест: предпросмотр из замоканного ответа OCR отображает редактируемые поля суммы/категории/позиций
- Widget-тест: отказ в доступе к камере предлагает переход на ручной ввод, а не пустой экран
**Зависит от:** T4.7, T4.5

#### T4.9 — Flutter: лента транзакций с фильтрами
**Описание:** Список операций с фильтрами по счёту/категории/периоду, курсорной пагинацией и свайп-действием смены категории.
**Файлы:**
- `mobile/lib/features/transactions/presentation/screens/transaction_list_screen.dart`
- `mobile/lib/features/transactions/presentation/widgets/transaction_tile.dart`
**Тест-план:**
- Widget-тест: свайп вправо по строке открывает быструю смену категории без перехода на новый экран
- Widget-тест: скролл до конца списка подгружает следующую страницу по курсору
**Зависит от:** T4.7, T2.3

---

## Модуль M5 — Notifications

| ID | Задача | Зависит от |
|---|---|---|
| T5.1 | Backend: устройства + уведомления (регистрация, диспетчер) | T1.1 |
| T5.2 | Flutter: регистрация устройства и обработка push | T5.1, T1.11 |

#### T5.1 — Backend: устройства + уведомления
**Описание:** `POST/DELETE /devices`, `GET /notifications`, `PATCH /notifications/{id}/read`, базовый диспетчер отправки push через FCM.
**Файлы:**
- `backend/src/database/migrations/0006_notifications.ts`
- `backend/src/modules/notifications/domain/entities/device.entity.ts`
- `backend/src/modules/notifications/domain/entities/notification.entity.ts`
- `backend/src/modules/notifications/infrastructure/services/fcm.service.ts`
- `backend/src/modules/notifications/application/use-cases/register-device.use-case.ts`
- `backend/src/modules/notifications/infrastructure/controllers/notifications.controller.ts`
**Тест-план:**
- Integration: повторная регистрация того же `fcmToken` — upsert, не дубликат (`uq_devices_user_token`)
- Integration: `GET /notifications?unreadOnly=true` возвращает только непрочитанные
**Зависит от:** T1.1

#### T5.2 — Flutter: регистрация устройства и обработка push
**Описание:** Запрос разрешения на уведомления, регистрация FCM-токена на бэкенде, обработка входящего push.
**Файлы:**
- `mobile/lib/core/notifications/push_service.dart`
- `mobile/lib/core/notifications/notification_permission_handler.dart`
**Тест-план:**
- Unit-тест: `push_service` регистрирует токен на бэкенде при первом запуске (мокнутый API-клиент)
**Зависит от:** T5.1, T1.11

---

## Модуль M6 — Budgets

| ID | Задача | Зависит от |
|---|---|---|
| T6.1 | Backend: CRUD бюджетов + расчёт прогресса | T4.2, T2.1 |
| T6.2 | Backend: уведомление о приближении к лимиту | T6.1, T5.1 |
| T6.3 | Flutter: список бюджетов | T6.1, T1.11 |
| T6.4 | Flutter: создание/редактирование бюджета | T6.3, T2.3 |

#### T6.1 — Backend: CRUD бюджетов + расчёт прогресса
**Описание:** `GET/POST/PATCH/DELETE /budgets` с полями `spentAmount`/`remainingAmount`/`progressPercent`, вычисляемыми из `transactions`.
**Файлы:**
- `backend/src/database/migrations/0007_budgets.ts`
- `backend/src/modules/budgets/domain/entities/budget.entity.ts`
- `backend/src/modules/budgets/application/use-cases/create-budget.use-case.ts`
- `backend/src/modules/budgets/application/use-cases/get-budgets.use-case.ts`
- `backend/src/modules/budgets/infrastructure/controllers/budgets.controller.ts`
**Тест-план:**
- Integration: повторный бюджет на ту же категорию/период — `409 CONFLICT` (`uq_budgets_user_category_period`)
- Unit: расчёт `progressPercent` корректен на 0%/50%/100%/перерасходе
**Зависит от:** T4.2, T2.1

#### T6.2 — Backend: уведомление о приближении к лимиту
**Описание:** Слушатель события создания транзакции, проверка порога 80%/100% лимита бюджета, создание уведомления не более одного раза за период.
**Файлы:**
- `backend/src/modules/transactions/domain/events/transaction-created.event.ts`
- `backend/src/modules/budgets/application/listeners/budget-threshold.listener.ts`
**Тест-план:**
- Integration: несколько транзакций подряд после пересечения 80% не создают дублирующихся уведомлений в рамках одного периода
**Зависит от:** T6.1, T5.1

#### T6.3 — Flutter: список бюджетов
**Описание:** Экран со списком бюджетов, прогресс-барами и цветовой индикацией.
**Файлы:**
- `mobile/lib/features/budgets/presentation/screens/budget_list_screen.dart`
- `mobile/lib/features/budgets/presentation/widgets/budget_card.dart`
- `mobile/lib/features/budgets/data/repositories/budget_repository_impl.dart`
**Тест-план:**
- Widget-тест: цвет индикатора соответствует порогам (зелёный <70%, жёлтый 70–99%, красный ≥100%)
**Зависит от:** T6.1, T1.11

#### T6.4 — Flutter: создание/редактирование бюджета
**Описание:** Bottom Sheet выбора категории и лимита.
**Файлы:**
- `mobile/lib/features/budgets/presentation/widgets/create_budget_sheet.dart`
**Тест-план:**
- Widget-тест: лимит `≤0` блокирует сохранение; конфликт дублирования показывает понятную ошибку, а не сырой код
**Зависит от:** T6.3, T2.3

---

## Модуль M7 — Installments

| ID | Задача | Зависит от |
|---|---|---|
| T7.1 | Схема БД installments + installment_payments | T1.1 |
| T7.2 | Backend: CRUD рассрочек + автогенерация графика | T7.1 |
| T7.3 | Backend: отметка платежа + cron-напоминания | T7.2, T5.1 |
| T7.4 | Flutter: экран сводной карты рассрочек | T7.2, T1.11 |
| T7.5 | Flutter: добавление рассрочки | T7.4 |

#### T7.1 — Схема БД installments + installment_payments
**Описание:** Миграция таблиц согласно [07_Database.md §5.11–5.12](07_Database.md#511-installments).
**Файлы:**
- `backend/src/database/migrations/0008_installments.ts`
- `backend/src/modules/installments/domain/entities/installment.entity.ts`
- `backend/src/modules/installments/domain/entities/installment-payment.entity.ts`
**Тест-план:**
- Integration: `installments_count <= 0` или `total_amount <= 0` нарушает соответствующие `CHECK`
**Зависит от:** T1.1

#### T7.2 — Backend: CRUD рассрочек + автогенерация графика платежей
**Описание:** `POST /installments` создаёт запись и автоматически генерирует N `installment_payments`.
**Файлы:**
- `backend/src/modules/installments/application/use-cases/create-installment.use-case.ts`
- `backend/src/modules/installments/application/services/payment-schedule-generator.service.ts`
- `backend/src/modules/installments/infrastructure/controllers/installments.controller.ts`
**Тест-план:**
- Unit: сумма всех сгенерированных `installment_payments.amount` равна `total_amount` (с корректным округлением последнего платежа)
- Integration: `GET /installments` возвращает суммарную долговую нагрузку
**Зависит от:** T7.1

#### T7.3 — Backend: отметка платежа + cron-напоминания
**Описание:** `PATCH /installments/{id}/payments/{paymentId}`, ежедневная cron-задача напоминаний за 1–3 дня до `due_date`.
**Файлы:**
- `backend/src/modules/installments/application/use-cases/mark-payment-paid.use-case.ts`
- `backend/src/modules/installments/infrastructure/jobs/installment-reminder.job.ts`
**Тест-план:**
- Integration: отметка одного платежа оплаченным не меняет статус других платежей графика
- Integration: cron создаёт уведомление только для платежей со статусом `pending` в окне 1–3 дня
**Зависит от:** T7.2, T5.1

#### T7.4 — Flutter: экран сводной карты рассрочек
**Описание:** Суммарная долговая нагрузка + карточки активных рассрочек + календарь ближайших платежей.
**Файлы:**
- `mobile/lib/features/installments/presentation/screens/installments_screen.dart`
- `mobile/lib/features/installments/presentation/widgets/installment_card.dart`
- `mobile/lib/features/installments/data/repositories/installment_repository_impl.dart`
**Тест-план:**
- Widget-тест: суммарная нагрузка корректно агрегирует все активные рассрочки; Empty-состояние при их отсутствии
**Зависит от:** T7.2, T1.11

#### T7.5 — Flutter: добавление рассрочки
**Описание:** Bottom Sheet добавления рассрочки (мерчант, сумма, количество платежей, дата начала).
**Файлы:**
- `mobile/lib/features/installments/presentation/widgets/add_installment_sheet.dart`
**Тест-план:**
- Widget-тест: количество платежей `≤0` блокирует сохранение
**Зависит от:** T7.4

---

## Модуль M8 — Dashboard

| ID | Задача | Зависит от |
|---|---|---|
| T8.1 | Flutter: layout Dashboard (остаток + лента операций) | T4.9, T3.2 |
| T8.2 | Flutter: виджеты бюджетов и рассрочек на Dashboard | T8.1, T6.3, T7.4 |
| T8.3 | Flutter: Empty-состояние, skeleton, pull-to-refresh | T8.2 |

> Dashboard не вводит собственных API-эндпоинтов — агрегирует уже существующие вызовы (`/accounts`, `/budgets`, `/installments`, `/transactions`), см. обоснование в [MVP_Spec.md §10](MVP_Spec.md#10-m8--dashboard).

#### T8.1 — Flutter: layout Dashboard
**Описание:** Основной layout с виджетом остатка бюджета периода и лентой последних операций.
**Файлы:**
- `mobile/lib/features/dashboard/presentation/screens/dashboard_screen.dart`
- `mobile/lib/features/dashboard/presentation/widgets/balance_widget.dart`
- `mobile/lib/features/dashboard/presentation/widgets/recent_transactions_widget.dart`
**Тест-план:**
- Widget-тест: виджеты корректно отрисовываются на замоканных данных провайдеров
**Зависит от:** T4.9, T3.2

#### T8.2 — Flutter: виджеты бюджетов и рассрочек на Dashboard
**Описание:** Превью 2–3 "горячих" бюджетов и виджет ближайшего платежа по рассрочке.
**Файлы:**
- `mobile/lib/features/dashboard/presentation/widgets/budgets_preview_widget.dart`
- `mobile/lib/features/dashboard/presentation/widgets/upcoming_installment_widget.dart`
**Тест-план:**
- Widget-тест: виджет рассрочки полностью скрыт, если активных рассрочек нет
**Зависит от:** T8.1, T6.3, T7.4

#### T8.3 — Flutter: Empty-состояние, skeleton, pull-to-refresh
**Описание:** Обработка состояния нового пользователя, скелетон при первичной загрузке, обновление по свайпу.
**Файлы:**
- `mobile/lib/features/dashboard/presentation/widgets/dashboard_empty_state.dart`
- `mobile/lib/features/dashboard/presentation/widgets/dashboard_skeleton.dart`
**Тест-план:**
- Widget-тест: пользователь без данных видит осмысленный Empty-state с CTA, не пустой экран
- Widget-тест: pull-to-refresh инициирует повторный запрос всех источников данных
**Зависит от:** T8.2

---

## Модуль M9 — Statistics

| ID | Задача | Зависит от |
|---|---|---|
| T9.1 | Backend: агрегация отчётов по категориям | T4.2, T2.1 |
| T9.2 | Flutter: экран статистики (диаграмма) | T9.1, T4.9 |

#### T9.1 — Backend: агрегация отчётов по категориям
**Описание:** `GET /reports/summary`, `GET /reports/by-category`.
**Файлы:**
- `backend/src/modules/reports/application/use-cases/get-summary.use-case.ts`
- `backend/src/modules/reports/application/use-cases/get-by-category.use-case.ts`
- `backend/src/modules/reports/infrastructure/controllers/reports.controller.ts`
**Тест-план:**
- Integration: транзакции без категории агрегируются в группу "Без категории", а не пропадают из суммы
**Зависит от:** T4.2, T2.1

#### T9.2 — Flutter: экран статистики
**Описание:** Переключатель периода + круговая диаграмма по категориям с текстовым выводом-инсайтом.
**Файлы:**
- `mobile/lib/features/statistics/presentation/screens/statistics_screen.dart`
- `mobile/lib/features/statistics/presentation/widgets/category_pie_chart.dart`
**Тест-план:**
- Widget-тест: тап по сектору диаграммы фильтрует список транзакций по этой категории
- Widget-тест: палитра диаграммы использует фиксированный порядок цветов из [09_Design_System.md §11](09_Design_System.md#11-charts)
**Зависит от:** T9.1, T4.9

---

## Модуль M10 — Settings

| ID | Задача | Зависит от |
|---|---|---|
| T10.1 | Backend: удаление аккаунта | T1.6 |
| T10.2 | Flutter: экран настроек | T10.1, T5.2, T1.11 |

#### T10.1 — Backend: удаление аккаунта
**Описание:** `DELETE /users/me` — мягкое удаление с отложенным полным стиранием.
**Файлы:**
- `backend/src/modules/users/application/use-cases/delete-account.use-case.ts`
- `backend/src/modules/users/infrastructure/controllers/users.controller.ts` (доп. эндпоинт)
**Тест-план:**
- Integration: ответ `202` со `scheduledPurgeAt`; повторный `GET /users/me` тем же токеном после удаления возвращает `401` (сессия недействительна)
**Зависит от:** T1.6

#### T10.2 — Flutter: экран настроек
**Описание:** Профиль, язык, валюта по умолчанию, тумблеры уведомлений, удаление аккаунта.
**Файлы:**
- `mobile/lib/features/settings/presentation/screens/settings_screen.dart`
- `mobile/lib/features/settings/presentation/widgets/notification_toggles.dart`
**Тест-план:**
- Widget-тест: смена языка применяется немедленно без перезапуска приложения
- Widget-тест: удаление аккаунта требует явного подтверждения и показывает дату фактического удаления
**Зависит от:** T10.1, T5.2, T1.11

---

## Итог

**51 задача** во всех 11 модулях, каждая ≤1 рабочего дня, с зависимостями строго "назад" по порядку документа — задачу можно начинать сразу, как только готовы все перечисленные в её "Зависит от". Порядок исполнения = порядок разделов выше (M0 → M10).

**Следующий шаг:** завести все 51 задачу в трекер (Linear/Jira/GitHub Projects) с сохранением ID из этого документа, чтобы коммиты/PR ссылались на `T<модуль>.<номер>`.

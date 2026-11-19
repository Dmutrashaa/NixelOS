import { createClient } from "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm";

export const SUPABASE_URL = "https://pmxbgdggupaznjnclpad.supabase.co";
export const SUPABASE_ANON_KEY = "sb_publishable_-Vmg7JLeeUA5VYnAtf5Y2Q_HllE6Zac";

export const sb = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: false }
});

export const USERNAME_RE = /^[A-Za-z0-9_]{3,20}$/;
export const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;
export const verifyUrl = () => new URL("verification.html", location.href).href;

export const I18N = {
  en: {
    loginTitle: "Log in", loginSub: "Welcome back to NixelOS", fUser: "Username", fPass: "Password", loginBtn: "Log in",
    noAcc: "No account yet?", signUp: "Sign up", regTitle: "Create account", regSub: "Join the NixelOS community",
    fDisp: "Display name (optional)", fPass2: "Repeat password", regBtn: "Sign up", haveAcc: "Already have an account?",
    logIn: "Log in", back: "Back to site",
    eFill: "Fill in all fields", eUser: "Username: 3–20 characters, letters, digits and _", ePassLen: "Password must be at least 8 characters",
    ePassMatch: "Passwords do not match", eTaken: "This username is not available", eCreds: "Wrong email or password",
    eNet: "Something went wrong. Try again later", eMailTaken: "This email is already registered", eRate: "Too many attempts. Wait a little", eDisp: "Display name: 2–32 characters",
    eDeviceBlocked: "This device is blocked on this account",
    pTitle: "Your profile", pChange: "Change avatar", pRemove: "Remove avatar", pBio: "About you", pSave: "Save", pSaved: "Saved",
    pLogout: "Log out", pNewPass: "New password", pChangePass: "Change password", pPassDone: "Password changed",
    eAvatar: "Only JPG, PNG or WebP up to 2 MB", pWait: "Please wait…", pUserHint: "Username can't be changed", pSecurity: "Security",
    pBannerLabel: "Profile banner", pBannerChange: "Change banner", pBannerRemove: "Remove banner",
    pBannerHint: "JPG, PNG or WebP up to 4 MB (recommended 3:1 ratio)", eBanner: "Only JPG, PNG or WebP up to 4 MB",
    pViewPublic: "View public profile",
    sessTitle: "Sessions & Devices", sessActive: "Active sessions", sessBlocked: "Blocked sessions",
    sessCount: "Devices signed in:", sessCurrent: "This device", sessLastSeen: "Last active:", sessBlockedAt: "Blocked:",
    sessDelete: "Delete session", sessUnblock: "Unblock", sessEmptyActive: "No active sessions found",
    sessEmptyBlocked: "No blocked devices", sessDeletedMsg: "Session removed and device blocked",
    sessUnblockedMsg: "Device unblocked", sessErr: "Failed to load sessions",
    sComments: "Comments", sWrite: "Write a comment…", sPost: "Post", sLoginC: "Log in to comment", sLoginR: "Log in to react",
    sDel: "Delete", sNone: "No comments yet. Be the first!", sEmpty: "Comment can't be empty", eLoad: "Failed to load comments",
    fEmail: "Email", eEmail: "Enter a valid email address", eUnconf: "Your email isn't confirmed yet. Check your inbox or resend the email", bResend: "Resend email", mResent: "An email is on its way to your inbox. Open the link and leave it to activate your account. Then log in with your email address and the password you chose.", ckTitle: "Check your email", ckText: "An email is on its way to your inbox. Open the link and leave it to activate your account. Then log in with your email address and the password you chose.", ckBack: "Back to log in", vWaitT: "Verifying your email…", vWaitX: "Just a moment", vOkT: "Email confirmed", vOkX: "Your account is active. You can log in or open your profile.", vProfile: "Open profile", vExpT: "Link expired", vExpX: "This link is invalid or has expired. Log in to request a new confirmation email.", vErrT: "Couldn't verify email", vErrX: "Something went wrong while verifying. Try opening the link again, or log in.", vNoneT: "Nothing to verify", vNoneX: "Open the confirmation link from your email.", sClose: "Close", sVerified: "Verified", sMod: "Admin / Mod", navAccount: "Log in / Sign up",
    navUsers: "Users", navChat: "OS Chat",
    sRules: "Rules",
    rulesTitle: "NixelOS Community Rules 🚀",
    rulesSub: "We're not the police here, but to keep the vibe friendly and fun for everyone, stick to these simple rules:",
    rule1T: "1. Don't spam or flood 🛑",
    rule1D: "No need to flood comments or chat with identical messages. One thoughtful message beats ten noisy ones!",
    rule2T: "2. Be cool — no insults 🤝",
    rule2D: "Respect other members! We're all here testing the OS of the future together, so keep it chill and toxicity-free.",
    rule3T: "3. No bad words or swearing 🧼",
    rule3D: "Keep the chat as clean as fresh NXBoot code. Bad language and profanity are strictly off-limits.",
    rule4T: "5. Insulting admins = Instant Ban ⚡",
    rule4D: "Yes, we skipped #4 because rule #5 is serious: our admins & devs code NixelOS late into the night. Insulting the team gets you a one-way ticket to Ban-land!",
    rulesFoot: "Follow the rules, enjoy smooth booting, and may your FPS always be high! 😎",
    rulesOk: "Got it, I'll be cool!",
    fAddFriend: "Add to friends",
    fReqSent: "Request sent (Cancel)",
    fAccept: "Accept friend",
    fDecline: "Decline",
    fFriends: "In friends ✓",
    fRemoveFriend: "Remove friend",
    fLoginFriend: "Log in to add friends",
    fSectionTitle: "Friends & Requests",
    fIncoming: "Incoming friend requests",
    fMyFriends: "Friends",
    fNoFriends: "No friends added yet. Find cool people in Users!",
    fNoRequests: "No pending friend requests",
    uTitle: "NixelOS Users",
    uIntro: "Meet the NixelOS community, view profiles, and add friends!",
    uSearch: "Search by name or @username…",
    uTabAll: "All Users",
    uTabFriends: "My Friends",
    uTabRequests: "Requests",
    uEmpty: "No users found.",
    uViewProfile: "View profile",
    pvTitle: "User Profile",
    pvJoined: "Joined:",
    pvBioLabel: "About user",
    pvBioEmpty: "This user hasn't written a bio yet.",
    pvEditOwn: "Edit my profile",
    pvNotFound: "User not found",
    pvNotFoundSub: "This account doesn't exist or the link is incorrect.",
    pvBackUsers: "All Users",
    pvReadOnlyBadge: "Viewing public profile (read-only)",
    cTitle: "NixelOS Community Chat",
    cIntro: "Live discussion about NixelOS builds, bootloader features, ideas, and feedback!",
    cWrite: "Write a message about NixelOS…",
    cSend: "Send",
    cEmpty: "No messages yet. Start the NixelOS discussion!",
    cLogin: "Log in to join the NixelOS chat",
    cRefresh: "Refresh"
  },
  ru: {
    loginTitle: "Вход", loginSub: "С возвращением в NixelOS", fUser: "Имя пользователя", fPass: "Пароль", loginBtn: "Войти",
    noAcc: "Ещё нет аккаунта?", signUp: "Регистрация", regTitle: "Создать аккаунт", regSub: "Присоединяйся к сообществу NixelOS",
    fDisp: "Отображаемое имя (необязательно)", fPass2: "Повторите пароль", regBtn: "Зарегистрироваться", haveAcc: "Уже есть аккаунт?",
    logIn: "Войти", back: "Назад на сайт",
    eFill: "Заполните все поля", eUser: "Имя: 3–20 символов, буквы, цифры и _", ePassLen: "Пароль должен быть не короче 8 символов",
    ePassMatch: "Пароли не совпадают", eTaken: "Это имя недоступно", eCreds: "Неверный email или пароль",
    eNet: "Что-то пошло не так. Попробуйте позже", eMailTaken: "Эта почта уже зарегистрирована", eRate: "Слишком много попыток. Подождите немного", eDisp: "Отображаемое имя: 2–32 символа",
    eDeviceBlocked: "Это устройство заблокировано в этом аккаунте",
    pTitle: "Ваш профиль", pChange: "Сменить аватарку", pRemove: "Убрать аватарку", pBio: "О себе", pSave: "Сохранить", pSaved: "Сохранено",
    pLogout: "Выйти", pNewPass: "Новый пароль", pChangePass: "Сменить пароль", pPassDone: "Пароль изменён",
    eAvatar: "Только JPG, PNG или WebP до 2 МБ", pWait: "Подождите…", pUserHint: "Имя пользователя изменить нельзя", pSecurity: "Безопасность",
    pBannerLabel: "Баннер профиля", pBannerChange: "Сменить баннер", pBannerRemove: "Убрать баннер",
    pBannerHint: "JPG, PNG или WebP до 4 МБ (рекомендуется формат 3:1)", eBanner: "Только JPG, PNG или WebP до 4 МБ",
    pViewPublic: "Как видят другие",
    sessTitle: "Сессии и устройства", sessActive: "Активные сессии", sessBlocked: "Заблокированные сессии",
    sessCount: "Устройств в аккаунте:", sessCurrent: "Это устройство", sessLastSeen: "Последняя активность:", sessBlockedAt: "Заблокировано:",
    sessDelete: "Удалить сессию", sessUnblock: "Разблокировать", sessEmptyActive: "Активных сессий не найдено",
    sessEmptyBlocked: "Нет заблокированных устройств", sessDeletedMsg: "Сессия удалена, устройство заблокировано",
    sessUnblockedMsg: "Устройство разблокировано", sessErr: "Не удалось загрузить сессии",
    sComments: "Комментарии", sWrite: "Напишите комментарий…", sPost: "Отправить", sLoginC: "Войдите, чтобы комментировать", sLoginR: "Войдите, чтобы ставить реакции",
    sDel: "Удалить", sNone: "Комментариев пока нет. Будьте первым!", sEmpty: "Комментарий не может быть пустым", eLoad: "Не удалось загрузить комментарии",
    fEmail: "Email", eEmail: "Введите корректный email", eUnconf: "Email ещё не подтверждён. Проверьте почту или отправьте письмо повторно", bResend: "Отправить письмо ещё раз", mResent: "На вашу электронную почту сейчас придёт письмо. Откройте ссылку и выйдите из неё, чтобы активировать ваш аккаунт. Далее входите со своим адресом и паролем, который вы выбрали.", ckTitle: "Проверьте почту", ckText: "На вашу электронную почту сейчас придёт письмо. Откройте ссылку и выйдите из неё, чтобы активировать ваш аккаунт. Далее входите со своим адресом и паролем, который вы выбрали.", ckBack: "Назад ко входу", vWaitT: "Проверяем почту…", vWaitX: "Одну секунду", vOkT: "Email подтверждён", vOkX: "Аккаунт активирован. Можно войти или открыть профиль.", vProfile: "Открыть профиль", vExpT: "Ссылка устарела", vExpX: "Ссылка недействительна или срок её действия истёк. Войдите, чтобы запросить новое письмо.", vErrT: "Не удалось подтвердить email", vErrX: "Во время проверки что-то пошло не так. Откройте ссылку ещё раз или войдите.", vNoneT: "Нечего проверять", vNoneX: "Откройте ссылку подтверждения из письма.", sClose: "Закрыть", sVerified: "Подтверждён", sMod: "Админ / Мод", navAccount: "Войти / Регистрация",
    navUsers: "Пользователи", navChat: "Чат ОС",
    sRules: "Правила",
    rulesTitle: "Правила сообщества NixelOS 🚀",
    rulesSub: "Мы тут не полиция, но чтобы всем было кайфово общаться, держи несколько простых правил:",
    rule1T: "1. Не спамить и не флудить 🛑",
    rule1D: "Не засыпай чат и комменты одинаковыми сообщениями. Лучше написать одну крутую мысль, чем десять пустых!",
    rule2T: "2. Не оскорблять участников 🤝",
    rule2D: "Уважай других! Мы тут все свои и тестируем ОС будущего, так что давай без токсичности и ссор.",
    rule3T: "3. Плохие слова запрещены 🧼",
    rule3D: "Держим общение чистым, как свежий код загрузчика NXBoot. Мат и ругательства оставь за пределами сайта.",
    rule4T: "5. Оскорбление админов — Бан ⚡",
    rule4D: "Да, пункт 4 мы перепрыгнули, потому что правило №5 железное: админы ночами пилят NixelOS, поэтому за наезды на команду — мгновенный билет в бан!",
    rulesFoot: "Соблюдай правила — и будет тебе счастье, быстрый бут и стабильный FPS! 😎",
    rulesOk: "Понял, буду котиком!",
    fAddFriend: "Добавить в друзья",
    fReqSent: "Запрос отправлен (Отменить)",
    fAccept: "Принять в друзья",
    fDecline: "Отклонить",
    fFriends: "В друзьях ✓",
    fRemoveFriend: "Удалить из друзей",
    fLoginFriend: "Войдите, чтобы добавить в друзья",
    fSectionTitle: "Друзья и запросы",
    fIncoming: "Входящие запросы в друзья",
    fMyFriends: "Друзья",
    fNoFriends: "Пока нет друзей. Найдите единомышленников во вкладке «Пользователи»!",
    fNoRequests: "Нет новых запросов в друзья",
    uTitle: "Пользователи NixelOS",
    uIntro: "Знакомьтесь с участниками сообщества NixelOS, смотрите профили и добавляйте друзей!",
    uSearch: "Поиск по имени или @username…",
    uTabAll: "Все пользователи",
    uTabFriends: "Мои друзья",
    uTabRequests: "Запросы",
    uEmpty: "Пользователи не найдены.",
    uViewProfile: "Профиль",
    pvTitle: "Профиль пользователя",
    pvJoined: "На сайте с:",
    pvBioLabel: "О пользователе",
    pvBioEmpty: "Пользователь ещё ничего о себе не рассказал.",
    pvEditOwn: "Редактировать мой профиль",
    pvNotFound: "Пользователь не найден",
    pvNotFoundSub: "Такого аккаунта не существует или ссылка неверна.",
    pvBackUsers: "Все пользователи",
    pvReadOnlyBadge: "Просмотр чужого профиля (только чтение)",
    cTitle: "Чат сообщества NixelOS",
    cIntro: "Живое обсуждение NixelOS, новых сборок, загрузчика NXBoot и ваших идей!",
    cWrite: "Напишите сообщение об ОС…",
    cSend: "Отправить",
    cEmpty: "Сообщений пока нет. Начните обсуждение NixelOS первым!",
    cLogin: "Войдите в аккаунт, чтобы общаться в чате NixelOS",
    cRefresh: "Обновить"
  },
  uk: {
    loginTitle: "Вхід", loginSub: "З поверненням у NixelOS", fUser: "Ім'я користувача", fPass: "Пароль", loginBtn: "Увійти",
    noAcc: "Ще немає акаунта?", signUp: "Реєстрація", regTitle: "Створити акаунт", regSub: "Приєднуйся до спільноти NixelOS",
    fDisp: "Відображуване ім'я (необов'язково)", fPass2: "Повторіть пароль", regBtn: "Зареєструватися", haveAcc: "Вже є акаунт?",
    logIn: "Увійти", back: "Назад на сайт",
    eFill: "Заповніть усі поля", eUser: "Ім'я: 3–20 символів, літери, цифри та _", ePassLen: "Пароль має бути не коротшим за 8 символів",
    ePassMatch: "Паролі не збігаються", eTaken: "Це ім'я недоступне", eCreds: "Неправильний email або пароль",
    eNet: "Щось пішло не так. Спробуйте пізніше", eMailTaken: "Ця пошта вже зареєстрована", eRate: "Забагато спроб. Зачекайте трохи", eDisp: "Відображуване ім'я: 2–32 символи",
    eDeviceBlocked: "Цей пристрій заблокований на цьому акаунті",
    pTitle: "Ваш профіль", pChange: "Змінити аватарку", pRemove: "Прибрати аватарку", pBio: "Про себе", pSave: "Зберегти", pSaved: "Збережено",
    pLogout: "Вийти", pNewPass: "Новий пароль", pChangePass: "Змінити пароль", pPassDone: "Пароль змінено",
    eAvatar: "Лише JPG, PNG або WebP до 2 МБ", pWait: "Зачекайте…", pUserHint: "Ім'я користувача змінити не можна", pSecurity: "Безпека",
    pBannerLabel: "Банер профілю", pBannerChange: "Змінити банер", pBannerRemove: "Прибрати банер",
    pBannerHint: "JPG, PNG або WebP до 4 МБ (рекомендовано пропорції 3:1)", eBanner: "Лише JPG, PNG або WebP до 4 МБ",
    pViewPublic: "Як бачать інші",
    sessTitle: "Сесії та пристрої", sessActive: "Активні сесії", sessBlocked: "Заблоковані сесії",
    sessCount: "Пристроїв в акаунті:", sessCurrent: "Цей пристрій", sessLastSeen: "Остання активність:", sessBlockedAt: "Заблоковано:",
    sessDelete: "Видалити сесію", sessUnblock: "Розблокувати", sessEmptyActive: "Активних сесій не знайдено",
    sessEmptyBlocked: "Немає заблокованих пристроїв", sessDeletedMsg: "Сесію видалено, пристрій заблоковано",
    sessUnblockedMsg: "Пристрій розблоковано", sessErr: "Не вдалося завантажити сесії",
    sComments: "Коментарі", sWrite: "Напишіть коментар…", sPost: "Надіслати", sLoginC: "Увійдіть, щоб коментувати", sLoginR: "Увійдіть, щоб ставити реакції",
    sDel: "Видалити", sNone: "Коментарів поки немає. Будьте першим!", sEmpty: "Коментар не може бути порожнім", eLoad: "Не вдалося завантажити коментарі",
    fEmail: "Email", eEmail: "Введіть коректний email", eUnconf: "Email ще не підтверджено. Перевірте пошту або надішліть лист повторно", bResend: "Надіслати лист ще раз", mResent: "На вашу електронну пошту зараз прийде лист. Відкрийте посилання, та вийдіть з нього щоб активувати ваш акаунт. Далі входьте з своєю адресою та своїм паролем який ви обирали.", ckTitle: "Перевірте пошту", ckText: "На вашу електронну пошту зараз прийде лист. Відкрийте посилання, та вийдіть з нього щоб активувати ваш акаунт. Далі входьте з своєю адресою та своїм паролем який ви обирали.", ckBack: "Назад до входу", vWaitT: "Перевіряємо пошту…", vWaitX: "Одну секунду", vOkT: "Email підтверджено", vOkX: "Акаунт активовано. Можна увійти або відкрити профіль.", vProfile: "Відкрити профіль", vExpT: "Посилання застаріло", vExpX: "Посилання недійсне або термін його дії минув. Увійдіть, щоб запросити новий лист.", vErrT: "Не вдалося підтвердити email", vErrX: "Під час перевірки щось пішло не так. Відкрийте посилання ще раз або увійдіть.", vNoneT: "Нічого перевіряти", vNoneX: "Відкрийте посилання підтвердження з листа.", sClose: "Закрити", sVerified: "Підтверджений", sMod: "Адмін / Мод", navAccount: "Увійти / Реєстрація",
    navUsers: "Користувачі", navChat: "Чат ОС",
    sRules: "Правила",
    rulesTitle: "Правила спільноти NixelOS 🚀",
    rulesSub: "Ми тут не поліція, але щоб усім було кайфово спілкуватися, тримай кілька простих правил:",
    rule1T: "1. Не спамити та не флудити 🛑",
    rule1D: "Не засипай коментарі чи чат однаковими повідомленнями. Краще написати одну круту думку, ніж десять порожніх!",
    rule2T: "2. Не ображати учасників 🤝",
    rule2D: "Поважай інших! Ми тут усі свої й разом тестуємо ОС майбутнього, тож давай без токсичності та сварок.",
    rule3T: "3. Погані слова заборонені 🧼",
    rule3D: "Тримаймо спілкування чистим, як свіженький код завантажувача NXBoot. Матюки та лайку залиш поза сайтом.",
    rule4T: "5. Образа адмінів — Бан ⚡",
    rule4D: "Так, пункт 4 ми перестрибнули, бо правило №5 залізне: адміни ночами пиляють NixelOS, тому за наїзди чи образу команди — миттєвий квиток у бан!",
    rulesFoot: "Дотримуйся правил — і буде тобі щастя, швидкий бут та стабільний FPS! 😎",
    rulesOk: "Зрозумів, буду котиком!",
    fAddFriend: "Додати в друзі",
    fReqSent: "Запит надіслано (Скасувати)",
    fAccept: "Прийняти в друзі",
    fDecline: "Відхилити",
    fFriends: "У друзях ✓",
    fRemoveFriend: "Видалити з друзів",
    fLoginFriend: "Увійдіть, щоб додати в друзі",
    fSectionTitle: "Друзі та запити",
    fIncoming: "Вхідні запити в друзі",
    fMyFriends: "Друзі",
    fNoFriends: "Поки немає друзів. Знайдіть однодумців у вкладці «Користувачі»!",
    fNoRequests: "Немає нових запитів у друзі",
    uTitle: "Користувачі NixelOS",
    uIntro: "Знайомтеся зі спільнотою NixelOS, переглядайте профілі та додавайте друзів!",
    uSearch: "Пошук за ім'ям або @username…",
    uTabAll: "Усі користувачі",
    uTabFriends: "Мої друзі",
    uTabRequests: "Запити",
    uEmpty: "Користувачів не знайдено.",
    uViewProfile: "Профіль",
    pvTitle: "Профіль користувача",
    pvJoined: "На сайті з:",
    pvBioLabel: "Про користувача",
    pvBioEmpty: "Користувач ще нічого про себе не розповів.",
    pvEditOwn: "Редагувати мій профіль",
    pvNotFound: "Користувача не знайдено",
    pvNotFoundSub: "Такого акаунта не існує або посилання неправильне.",
    pvBackUsers: "Усі користувачі",
    pvReadOnlyBadge: "Перегляд чужого профілю (лише читання)",
    cTitle: "Чат спільноти NixelOS",
    cIntro: "Живе обговорення NixelOS, нових збірок, завантажувача NXBoot та ваших ідей!",
    cWrite: "Напишіть повідомлення про ОС…",
    cSend: "Надіслати",
    cEmpty: "Повідомлень поки немає. Почніть обговорення NixelOS першим!",
    cLogin: "Увійдіть в акаунт, щоб спілкуватися в чаті NixelOS",
    cRefresh: "Оновити"
  }
};

export function getLang() {
  let l = "en";
  try { l = localStorage.getItem("nixelos-lang") || "en"; } catch (e) {}
  return I18N[l] ? l : "en";
}

export const t = key => (I18N[getLang()] && I18N[getLang()][key]) || I18N.en[key] || key;

export function applyLabels(root = document) {
  root.querySelectorAll("[data-sk]").forEach(el => { el.textContent = t(el.dataset.sk); });
  root.querySelectorAll("[data-sp]").forEach(el => { el.placeholder = t(el.dataset.sp); });
}

export function initLang() {
  document.documentElement.lang = getLang();
  applyLabels();
}

export function mapErr(error) {
  const m = String((error && error.message) || "").toLowerCase();
  const c = String((error && error.code) || "").toLowerCase();
  const s = error && error.status;
  if (c === "email_not_confirmed" || m.includes("not confirmed")) return "eUnconf";
  if (c === "invalid_credentials" || m.includes("invalid login")) return "eCreds";
  if (c === "email_address_invalid" || c === "validation_failed") return "eEmail";
  if (c === "weak_password") return "ePassLen";
  if (s === 429 || c.includes("rate_limit") || m.includes("rate limit")) return "eRate";
  if (m.includes("already registered") || m.includes("already been registered")) return "eMailTaken";
  if (m.includes("already") || m.includes("database error")) return "eTaken";
  return "eNet";
}

const DEVICE_KEY = "nixelos-device-id";
let _fallbackDeviceId = null;

export function getDeviceId() {
  try {
    let id = localStorage.getItem(DEVICE_KEY);
    if (!id) {
      id = (typeof crypto !== "undefined" && crypto.randomUUID)
        ? crypto.randomUUID()
        : "dev-" + Date.now().toString(36) + "-" + Math.random().toString(36).slice(2, 12);
      localStorage.setItem(DEVICE_KEY, id);
    }
    return id;
  } catch (e) {
    if (!_fallbackDeviceId) {
      _fallbackDeviceId = "dev-" + Date.now().toString(36) + "-" + Math.random().toString(36).slice(2, 12);
    }
    return _fallbackDeviceId;
  }
}

export function getDeviceName() {
  const ua = navigator.userAgent || "";
  let os = "Unknown OS";
  if (/Android/i.test(ua)) os = "Android";
  else if (/iPhone/i.test(ua)) os = "iPhone";
  else if (/iPad/i.test(ua)) os = "iPad";
  else if (/Windows NT/i.test(ua)) os = "Windows";
  else if (/Mac OS X|Macintosh/i.test(ua)) os = "macOS";
  else if (/CrOS/i.test(ua)) os = "ChromeOS";
  else if (/Linux/i.test(ua)) os = "Linux";

  let br = "Browser";
  if (/EdgA?|EdgiOS/i.test(ua)) br = "Edge";
  else if (/OPR|Opera/i.test(ua)) br = "Opera";
  else if (/Firefox|FxiOS/i.test(ua)) br = "Firefox";
  else if (/SamsungBrowser/i.test(ua)) br = "Samsung Internet";
  else if (/Chrome|CriOS/i.test(ua)) br = "Chrome";
  else if (/Safari/i.test(ua)) br = "Safari";

  return os + " · " + br;
}

export async function registerDeviceSession(uid) {
  if (!uid) return { blocked: false, ok: false };
  const deviceId = getDeviceId();
  const deviceName = getDeviceName();
  const ua = (navigator.userAgent || "").slice(0, 300);
  const now = new Date().toISOString();
  try {
    const { data: existing, error: selErr } = await sb
      .from("user_sessions")
      .select("id,is_blocked")
      .eq("user_id", uid)
      .eq("device_id", deviceId)
      .maybeSingle();
    if (selErr) return { blocked: false, ok: false, error: selErr };
    if (existing && existing.is_blocked) {
      return { blocked: true, ok: true };
    }
    if (existing) {
      await sb.from("user_sessions")
        .update({ device_name: deviceName, user_agent: ua, last_seen_at: now })
        .eq("id", existing.id);
      return { blocked: false, ok: true };
    }
    const { error: insErr } = await sb.from("user_sessions").insert({
      user_id: uid,
      device_id: deviceId,
      device_name: deviceName,
      user_agent: ua,
      is_blocked: false,
      last_seen_at: now
    });
    return { blocked: false, ok: !insErr, error: insErr || null };
  } catch (e) {
    return { blocked: false, ok: false, error: e };
  }
}

export async function removeCurrentDeviceSession(uid) {
  if (!uid) return;
  try {
    await sb.from("user_sessions")
      .delete()
      .eq("user_id", uid)
      .eq("device_id", getDeviceId())
      .eq("is_blocked", false);
  } catch (e) {}
}

export async function getUserSessions(uid) {
  const { data, error } = await sb
    .from("user_sessions")
    .select("*")
    .eq("user_id", uid)
    .order("last_seen_at", { ascending: false });
  return { data: data || [], error };
}

export async function blockDeviceSession(sessionId) {
  const { error } = await sb
    .from("user_sessions")
    .update({ is_blocked: true, blocked_at: new Date().toISOString() })
    .eq("id", sessionId);
  return { error };
}

export async function unblockDeviceSession(sessionId) {
  const { error } = await sb
    .from("user_sessions")
    .delete()
    .eq("id", sessionId);
  return { error };
}

let _syncedUid = null;
let _syncPromise = null;

export async function getSessionUser() {
  const { data } = await sb.auth.getSession();
  const user = data.session ? data.session.user : null;
  if (!user) {
    _syncedUid = null;
    _syncPromise = null;
    return null;
  }
  if (_syncedUid !== user.id) {
    if (!_syncPromise) {
      _syncPromise = registerDeviceSession(user.id).finally(() => { _syncPromise = null; });
    }
    const res = await _syncPromise;
    if (res && res.blocked) {
      await sb.auth.signOut();
      _syncedUid = null;
      return null;
    }
    _syncedUid = user.id;
  }
  return user;
}

export function avatarUrl(path) {
  if (!path) return null;
  return sb.storage.from("avatars").getPublicUrl(path).data.publicUrl;
}

export function bannerUrl(path) {
  if (!path) return null;
  if (/^https?:\/\//i.test(path)) return path;
  return sb.storage.from("avatars").getPublicUrl(path).data.publicUrl;
}

export function makeAvatar(profile, className) {
  const p = profile || {};
  const url = avatarUrl(p.avatar_path);
  let el;
  if (url) {
    el = document.createElement("img");
    el.src = url;
    el.alt = "";
    el.loading = "lazy";
    el.referrerPolicy = "no-referrer";
  } else {
    el = document.createElement("div");
    el.textContent = ((p.display_name || p.username || "?").trim()[0] || "?").toUpperCase();
  }
  el.className = className;
  return el;
}

export function applyBannerStyle(el, profile) {
  if (!el) return;
  let bPath = profile && profile.banner_path;
  if (!bPath && profile && profile.id) {
    try { bPath = localStorage.getItem("nixelos-banner-" + profile.id) || null; } catch (e) {}
  }
  const url = bannerUrl(bPath);
  if (url) {
    el.style.backgroundImage = `linear-gradient(180deg, rgba(9,10,14,.15) 0%, rgba(9,10,14,.55) 100%), url("${url.replace(/"/g, "%22")}")`;
    el.style.backgroundSize = "cover";
    el.style.backgroundPosition = "center";
    el.classList.add("has-banner");
  } else {
    el.style.backgroundImage = "";
    el.style.backgroundSize = "";
    el.style.backgroundPosition = "";
    el.classList.remove("has-banner");
  }
}

export function badge() {
  const s = document.createElement("span");
  s.title = t("sVerified");
  s.style.cssText = "display:inline-flex;flex:none;width:16px;height:16px;color:#5b8cff;vertical-align:middle";
  s.innerHTML = '<svg viewBox="0 0 24 24" width="16" height="16" aria-hidden="true"><path fill="currentColor" d="M12 1.8l2.6 1.9 3.2-.1 1 3 2.6 1.9-1 3.1 1 3.1-2.6 1.9-1 3-3.2-.1L12 22.2l-2.6-1.9-3.2.1-1-3-2.6-1.9 1-3.1-1-3.1 2.6-1.9 1-3 3.2.1z"/><path fill="none" stroke="#fff" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" d="M8 12.3l2.8 2.8L16.2 9.6"/></svg>';
  return s;
}

export function modBadge() {
  const s = document.createElement("span");
  s.textContent = "MOD";
  s.title = t("sMod");
  s.style.cssText = "display:inline-flex;align-items:center;padding:1px 6px;border-radius:999px;font-size:10px;font-weight:700;letter-spacing:.04em;color:#fff;background:linear-gradient(135deg,#ff6b8b,#a46bff);vertical-align:middle";
  return s;
}

export async function getMyProfile(uid) {
  const read = () => sb.from("profiles")
    .select("*")
    .eq("id", uid).maybeSingle();
  let { data } = await read();
  if (!data) {
    const r = await sb.rpc("ensure_my_profile");
    if (!r.error) ({ data } = await read());
  }
  return data;
}

export async function initMenuAccount(base) {
  const a = document.getElementById("account-link");
  if (!a) return;
  a.href = base + "Auth/login.html";
  try {
    const user = await getSessionUser();
    if (!user) return;
    a.href = base + "comunicate/profile.html";
    const p = await getMyProfile(user.id);
    if (!p) return;
    const av = a.querySelector(".menu-av");
    if (av) av.replaceWith(makeAvatar(p, "menu-av"));
    const name = a.querySelector(".menu-acc-name");
    if (name) {
      name.removeAttribute("data-i18n");
      name.removeAttribute("data-sk");
      name.textContent = p.display_name;
      if (p.is_verified) name.append(badge());
    }
    const sub = a.querySelector(".menu-acc-sub");
    if (sub) sub.textContent = "@" + p.username;
    if (p.banner_path) {
      const bUrl = bannerUrl(p.banner_path);
      if (bUrl) {
        a.style.backgroundImage = `linear-gradient(135deg, rgba(17,18,28,.78), rgba(20,22,38,.88)), url("${bUrl.replace(/"/g, "%22")}")`;
        a.style.backgroundSize = "cover";
        a.style.backgroundPosition = "center";
      }
    }
  } catch (e) {}
}

let rulesOverlay = null;

export function ensureRulesModal() {
  if (rulesOverlay) return rulesOverlay;

  if (!document.getElementById("nx-rules-style")) {
    const st = document.createElement("style");
    st.id = "nx-rules-style";
    st.textContent = `
      .nx-rules-btn{display:inline-flex;align-items:center;gap:6px;min-height:36px;padding:0 13px;border:1px solid rgba(151,166,255,.38);border-radius:999px;color:var(--text,#f5f5f7);background:rgba(133,151,255,.12);font:700 12px "Comfortaa",sans-serif;cursor:pointer;transition:transform 180ms ease,border-color 180ms ease,background 180ms ease}
      .nx-rules-btn:hover{transform:translateY(-2px);border-color:rgba(151,166,255,.75);background:rgba(133,151,255,.22)}
      .nx-rules-btn svg{width:15px;height:15px;color:#a8b4ff;flex:none}
      :root[data-theme="light"] .nx-rules-btn{border-color:rgba(91,111,255,.4);background:rgba(91,111,255,.1)}
      :root[data-theme="light"] .nx-rules-btn svg{color:#4a5bd8}
      .nx-rules-overlay{position:fixed;inset:0;z-index:80;display:grid;place-items:center;padding:16px;background:rgba(5,6,12,.68);-webkit-backdrop-filter:blur(7px);backdrop-filter:blur(7px);opacity:0;visibility:hidden;transition:opacity 220ms ease,visibility 220ms ease}
      .nx-rules-overlay.on{opacity:1;visibility:visible}
      .nx-rules-box{width:min(520px,100%);max-height:88vh;overflow-y:auto;padding:clamp(20px,4vw,28px);text-align:left;border:1px solid rgba(151,166,255,.36);border-radius:22px;background:linear-gradient(135deg,rgba(28,31,56,.97),rgba(16,18,30,.98));box-shadow:0 24px 70px rgba(0,0,0,.5);transform:translateY(16px) scale(.97);transition:transform 260ms cubic-bezier(.2,.7,.2,1)}
      .nx-rules-overlay.on .nx-rules-box{transform:none}
      :root[data-theme="light"] .nx-rules-box{background:linear-gradient(135deg,rgba(255,255,255,.98),rgba(238,242,255,.98));box-shadow:0 24px 70px rgba(20,24,60,.24)}
      .nx-rules-top{display:flex;align-items:flex-start;justify-content:space-between;gap:12px;margin-bottom:10px}
      .nx-rules-top h3{margin:0;font-size:clamp(19px,3.2vw,23px);line-height:1.3;letter-spacing:-.03em}
      .nx-rules-sub{margin:0 0 16px;color:var(--muted,#b9bbc7);font-size:13.5px;line-height:1.65}
      .nx-rules-list{display:grid;gap:10px;margin:0 0 16px;padding:0;list-style:none}
      .nx-rules-item{padding:12px 14px;border:1px solid rgba(151,166,255,.22);border-left:3px solid #8f9bff;border-radius:6px 14px 14px 6px;background:rgba(255,255,255,.04)}
      .nx-rules-item:nth-child(4){border-left-color:#ff7a8a;background:rgba(255,100,120,.07)}
      :root[data-theme="light"] .nx-rules-item{background:rgba(91,111,255,.06);border-color:rgba(91,111,255,.22)}
      :root[data-theme="light"] .nx-rules-item:nth-child(4){background:rgba(255,90,110,.09)}
      .nx-rules-item strong{display:block;margin-bottom:4px;font-size:14.5px;color:var(--text,#f5f5f7)}
      .nx-rules-item p{margin:0;font-size:13px;line-height:1.6;color:var(--muted,#b9bbc7)}
      .nx-rules-foot{margin:0 0 16px;padding:10px 12px;border-radius:12px;background:rgba(133,151,255,.1);font-size:13px;font-weight:700;line-height:1.55;text-align:center;color:var(--text,#f5f5f7)}
      .nx-rules-ok{width:100%}
    `;
    document.head.append(st);
  }

  rulesOverlay = document.createElement("div");
  rulesOverlay.className = "nx-rules-overlay";
  rulesOverlay.setAttribute("aria-hidden", "true");
  rulesOverlay.innerHTML = `
    <div class="nx-rules-box" role="dialog" aria-modal="true" aria-labelledby="nx-rules-h">
      <div class="nx-rules-top">
        <h3 id="nx-rules-h" data-sk="rulesTitle"></h3>
        <button type="button" class="nx-x nx-rules-close" aria-label="Close">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" width="16" height="16"><path d="M6 6l12 12M18 6 6 18"></path></svg>
        </button>
      </div>
      <p class="nx-rules-sub" data-sk="rulesSub"></p>
      <ul class="nx-rules-list">
        <li class="nx-rules-item"><strong data-sk="rule1T"></strong><p data-sk="rule1D"></p></li>
        <li class="nx-rules-item"><strong data-sk="rule2T"></strong><p data-sk="rule2D"></p></li>
        <li class="nx-rules-item"><strong data-sk="rule3T"></strong><p data-sk="rule3D"></p></li>
        <li class="nx-rules-item"><strong data-sk="rule4T"></strong><p data-sk="rule4D"></p></li>
      </ul>
      <p class="nx-rules-foot" data-sk="rulesFoot"></p>
      <button type="button" class="btn nx-rules-ok" data-sk="rulesOk"></button>
    </div>
  `;
  document.body.append(rulesOverlay);

  const close = () => {
    rulesOverlay.classList.remove("on");
    rulesOverlay.setAttribute("aria-hidden", "true");
  };
  rulesOverlay.querySelector(".nx-rules-close").addEventListener("click", close);
  rulesOverlay.querySelector(".nx-rules-ok").addEventListener("click", close);
  rulesOverlay.addEventListener("mousedown", e => { if (e.target === rulesOverlay) close(); });
  document.addEventListener("keydown", e => {
    if (e.key === "Escape" && rulesOverlay.classList.contains("on")) {
      e.stopPropagation();
      close();
    }
  });

  applyLabels(rulesOverlay);
  return rulesOverlay;
}

export function openRulesModal() {
  const ov = ensureRulesModal();
  applyLabels(ov);
  ov.classList.add("on");
  ov.setAttribute("aria-hidden", "false");
  const okBtn = ov.querySelector(".nx-rules-ok");
  if (okBtn) setTimeout(() => okBtn.focus(), 50);
}

export function makeRulesButton() {
  const b = document.createElement("button");
  b.type = "button";
  b.className = "nx-rules-btn";
  b.innerHTML = `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 3 4.5 6.5v5.8c0 4.6 3.2 8.4 7.5 10.2 4.3-1.8 7.5-5.6 7.5-10.2V6.5L12 3Z"></path><path d="M12 8v4.5"></path><path d="M12 16h.01"></path></svg><span data-sk="sRules">${t("sRules")}</span>`;
  b.addEventListener("click", openRulesModal);
  return b;
}

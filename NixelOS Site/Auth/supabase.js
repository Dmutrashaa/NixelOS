import { createClient } from "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm";

export const SUPABASE_URL = "https://YOUR-PROJECT-REF.supabase.co";
export const SUPABASE_ANON_KEY = "YOUR-ANON-OR-PUBLISHABLE-KEY";

export const sb = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: false }
});

export const USERNAME_RE = /^[A-Za-z0-9_]{3,20}$/;
export const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;
export const verifyUrl = () => new URL("verification.html", location.href).href;

const I18N = {
  en: {
    loginTitle: "Log in", loginSub: "Welcome back to NixelOS", fUser: "Username", fPass: "Password", loginBtn: "Log in",
    noAcc: "No account yet?", signUp: "Sign up", regTitle: "Create account", regSub: "Join the NixelOS community",
    fDisp: "Display name (optional)", fPass2: "Repeat password", regBtn: "Sign up", haveAcc: "Already have an account?",
    logIn: "Log in", back: "Back to site",
    eFill: "Fill in all fields", eUser: "Username: 3–20 characters, letters, digits and _", ePassLen: "Password must be at least 8 characters",
    ePassMatch: "Passwords do not match", eTaken: "This username is not available", eCreds: "Wrong email or password",
    eNet: "Something went wrong. Try again later", eRate: "Too many attempts. Wait a little", eDisp: "Display name: 2–32 characters",
    pTitle: "Your profile", pChange: "Change avatar", pRemove: "Remove avatar", pBio: "About you", pSave: "Save", pSaved: "Saved",
    pLogout: "Log out", pNewPass: "New password", pChangePass: "Change password", pPassDone: "Password changed",
    eAvatar: "Only JPG, PNG or WebP up to 2 MB", pWait: "Please wait…", pUserHint: "Username can't be changed", pSecurity: "Security",
    sComments: "Comments", sWrite: "Write a comment…", sPost: "Post", sLoginC: "Log in to comment", sLoginR: "Log in to react",
    sDel: "Delete", sNone: "No comments yet. Be the first!", sEmpty: "Comment can't be empty", eLoad: "Failed to load comments",
    fEmail: "Email", eEmail: "Enter a valid email address", eUnconf: "Your email isn't confirmed yet. Check your inbox or resend the email", bResend: "Resend email", mResent: "Email sent. Check your inbox", ckTitle: "Check your email", ckText: "We sent a confirmation link to the address below. Open it to activate your account. Check spam if you can't see it.", ckBack: "Back to log in", vWaitT: "Verifying your email…", vWaitX: "Just a moment", vOkT: "Email confirmed", vOkX: "Your account is active. You can log in or open your profile.", vProfile: "Open profile", vExpT: "Link expired", vExpX: "This link is invalid or has expired. Log in to request a new confirmation email.", vErrT: "Couldn't verify email", vErrX: "Something went wrong while verifying. Try opening the link again, or log in.", vNoneT: "Nothing to verify", vNoneX: "Open the confirmation link from your email.", sClose: "Close", sVerified: "Verified", navAccount: "Log in / Sign up"
  },
  ru: {
    loginTitle: "Вход", loginSub: "С возвращением в NixelOS", fUser: "Имя пользователя", fPass: "Пароль", loginBtn: "Войти",
    noAcc: "Ещё нет аккаунта?", signUp: "Регистрация", regTitle: "Создать аккаунт", regSub: "Присоединяйся к сообществу NixelOS",
    fDisp: "Отображаемое имя (необязательно)", fPass2: "Повторите пароль", regBtn: "Зарегистрироваться", haveAcc: "Уже есть аккаунт?",
    logIn: "Войти", back: "Назад на сайт",
    eFill: "Заполните все поля", eUser: "Имя: 3–20 символов, буквы, цифры и _", ePassLen: "Пароль должен быть не короче 8 символов",
    ePassMatch: "Пароли не совпадают", eTaken: "Это имя недоступно", eCreds: "Неверный email или пароль",
    eNet: "Что-то пошло не так. Попробуйте позже", eRate: "Слишком много попыток. Подождите немного", eDisp: "Отображаемое имя: 2–32 символа",
    pTitle: "Ваш профиль", pChange: "Сменить аватарку", pRemove: "Убрать аватарку", pBio: "О себе", pSave: "Сохранить", pSaved: "Сохранено",
    pLogout: "Выйти", pNewPass: "Новый пароль", pChangePass: "Сменить пароль", pPassDone: "Пароль изменён",
    eAvatar: "Только JPG, PNG или WebP до 2 МБ", pWait: "Подождите…", pUserHint: "Имя пользователя изменить нельзя", pSecurity: "Безопасность",
    sComments: "Комментарии", sWrite: "Напишите комментарий…", sPost: "Отправить", sLoginC: "Войдите, чтобы комментировать", sLoginR: "Войдите, чтобы ставить реакции",
    sDel: "Удалить", sNone: "Комментариев пока нет. Будьте первым!", sEmpty: "Комментарий не может быть пустым", eLoad: "Не удалось загрузить комментарии",
    fEmail: "Email", eEmail: "Введите корректный email", eUnconf: "Email ещё не подтверждён. Проверьте почту или отправьте письмо повторно", bResend: "Отправить письмо ещё раз", mResent: "Письмо отправлено. Проверьте почту", ckTitle: "Проверьте почту", ckText: "Мы отправили ссылку для подтверждения на адрес ниже. Откройте её, чтобы активировать аккаунт. Если письма нет — загляните в спам.", ckBack: "Назад ко входу", vWaitT: "Проверяем почту…", vWaitX: "Одну секунду", vOkT: "Email подтверждён", vOkX: "Аккаунт активирован. Можно войти или открыть профиль.", vProfile: "Открыть профиль", vExpT: "Ссылка устарела", vExpX: "Ссылка недействительна или срок её действия истёк. Войдите, чтобы запросить новое письмо.", vErrT: "Не удалось подтвердить email", vErrX: "Во время проверки что-то пошло не так. Откройте ссылку ещё раз или войдите.", vNoneT: "Нечего проверять", vNoneX: "Откройте ссылку подтверждения из письма.", sClose: "Закрыть", sVerified: "Подтверждён", navAccount: "Войти / Регистрация"
  },
  uk: {
    loginTitle: "Вхід", loginSub: "З поверненням у NixelOS", fUser: "Ім'я користувача", fPass: "Пароль", loginBtn: "Увійти",
    noAcc: "Ще немає акаунта?", signUp: "Реєстрація", regTitle: "Створити акаунт", regSub: "Приєднуйся до спільноти NixelOS",
    fDisp: "Відображуване ім'я (необов'язково)", fPass2: "Повторіть пароль", regBtn: "Зареєструватися", haveAcc: "Вже є акаунт?",
    logIn: "Увійти", back: "Назад на сайт",
    eFill: "Заповніть усі поля", eUser: "Ім'я: 3–20 символів, літери, цифри та _", ePassLen: "Пароль має бути не коротшим за 8 символів",
    ePassMatch: "Паролі не збігаються", eTaken: "Це ім'я недоступне", eCreds: "Неправильний email або пароль",
    eNet: "Щось пішло не так. Спробуйте пізніше", eRate: "Забагато спроб. Зачекайте трохи", eDisp: "Відображуване ім'я: 2–32 символи",
    pTitle: "Ваш профіль", pChange: "Змінити аватарку", pRemove: "Прибрати аватарку", pBio: "Про себе", pSave: "Зберегти", pSaved: "Збережено",
    pLogout: "Вийти", pNewPass: "Новий пароль", pChangePass: "Змінити пароль", pPassDone: "Пароль змінено",
    eAvatar: "Лише JPG, PNG або WebP до 2 МБ", pWait: "Зачекайте…", pUserHint: "Ім'я користувача змінити не можна", pSecurity: "Безпека",
    sComments: "Коментарі", sWrite: "Напишіть коментар…", sPost: "Надіслати", sLoginC: "Увійдіть, щоб коментувати", sLoginR: "Увійдіть, щоб ставити реакції",
    sDel: "Видалити", sNone: "Коментарів поки немає. Будьте першим!", sEmpty: "Коментар не може бути порожнім", eLoad: "Не вдалося завантажити коментарі",
    fEmail: "Email", eEmail: "Введіть коректний email", eUnconf: "Email ще не підтверджено. Перевірте пошту або надішліть лист повторно", bResend: "Надіслати лист ще раз", mResent: "Лист надіслано. Перевірте пошту", ckTitle: "Перевірте пошту", ckText: "Ми надіслали посилання для підтвердження на адресу нижче. Відкрийте його, щоб активувати акаунт. Якщо листа немає — зазирніть у спам.", ckBack: "Назад до входу", vWaitT: "Перевіряємо пошту…", vWaitX: "Одну секунду", vOkT: "Email підтверджено", vOkX: "Акаунт активовано. Можна увійти або відкрити профіль.", vProfile: "Відкрити профіль", vExpT: "Посилання застаріло", vExpX: "Посилання недійсне або термін його дії минув. Увійдіть, щоб запросити новий лист.", vErrT: "Не вдалося підтвердити email", vErrX: "Під час перевірки щось пішло не так. Відкрийте посилання ще раз або увійдіть.", vNoneT: "Нічого перевіряти", vNoneX: "Відкрийте посилання підтвердження з листа.", sClose: "Закрити", sVerified: "Підтверджений", navAccount: "Увійти / Реєстрація"
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
  if (m.includes("already") || m.includes("database error")) return "eTaken";
  return "eNet";
}

export function avatarUrl(path) {
  if (!path) return null;
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

export function badge() {
  const s = document.createElement("span");
  s.title = t("sVerified");
  s.style.cssText = "display:inline-flex;flex:none;width:16px;height:16px;color:#5b8cff";
  s.innerHTML = '<svg viewBox="0 0 24 24" width="16" height="16" aria-hidden="true"><path fill="currentColor" d="M12 1.8l2.6 1.9 3.2-.1 1 3 2.6 1.9-1 3.1 1 3.1-2.6 1.9-1 3-3.2-.1L12 22.2l-2.6-1.9-3.2.1-1-3-2.6-1.9 1-3.1-1-3.1 2.6-1.9 1-3 3.2.1z"/><path fill="none" stroke="#fff" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" d="M8 12.3l2.8 2.8L16.2 9.6"/></svg>';
  return s;
}

export async function getSessionUser() {
  const { data } = await sb.auth.getSession();
  return data.session ? data.session.user : null;
}

export async function getMyProfile(uid) {
  const read = () => sb.from("profiles")
    .select("id,username,display_name,bio,avatar_path,is_verified,is_moderator,created_at")
    .eq("id", uid).maybeSingle();
  let { data } = await read();
  if (!data) {
    // Confirmed account without a profile (an interrupted confirmation): ask the database to create it.
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
    a.href = base + "profile.html";
    const p = await getMyProfile(user.id);
    if (!p) return;
    const av = a.querySelector(".menu-av");
    if (av) av.replaceWith(makeAvatar(p, "menu-av"));
    const name = a.querySelector(".menu-acc-name");
    if (name) {
      name.removeAttribute("data-i18n");
      name.textContent = p.display_name;
      if (p.is_verified) name.append(badge());
    }
    const sub = a.querySelector(".menu-acc-sub");
    if (sub) sub.textContent = "@" + p.username;
  } catch (e) {}
}

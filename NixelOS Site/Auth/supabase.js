import { createClient } from "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm";

export const SUPABASE_URL = "https://YOUR-PROJECT-REF.supabase.co";
export const SUPABASE_ANON_KEY = "YOUR-ANON-OR-PUBLISHABLE-KEY";

export const sb = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: false }
});

export const USERNAME_RE = /^[A-Za-z0-9_]{3,20}$/;
export const emailFor = u => "nixelos.auth+" + u.toLowerCase() + "@gmail.com";

const I18N = {
  en: {
    loginTitle: "Log in", loginSub: "Welcome back to NixelOS", fUser: "Username", fPass: "Password", loginBtn: "Log in",
    noAcc: "No account yet?", signUp: "Sign up", regTitle: "Create account", regSub: "Join the NixelOS community",
    fDisp: "Display name (optional)", fPass2: "Repeat password", regBtn: "Sign up", haveAcc: "Already have an account?",
    logIn: "Log in", back: "Back to site",
    eFill: "Fill in all fields", eUser: "Username: 3–20 characters, letters, digits and _", ePassLen: "Password must be at least 8 characters",
    ePassMatch: "Passwords do not match", eTaken: "This username is not available", eCreds: "Wrong username or password",
    eNet: "Something went wrong. Try again later", eRate: "Too many attempts. Wait a little", eDisp: "Display name: 2–32 characters",
    pTitle: "Your profile", pChange: "Change avatar", pRemove: "Remove avatar", pBio: "About you", pSave: "Save", pSaved: "Saved",
    pLogout: "Log out", pNewPass: "New password", pChangePass: "Change password", pPassDone: "Password changed",
    eAvatar: "Only JPG, PNG or WebP up to 2 MB", pWait: "Please wait…", pUserHint: "Username can't be changed", pSecurity: "Security",
    sComments: "Comments", sWrite: "Write a comment…", sPost: "Post", sLoginC: "Log in to comment", sLoginR: "Log in to react",
    sDel: "Delete", sNone: "No comments yet. Be the first!", sEmpty: "Comment can't be empty", eLoad: "Failed to load comments",
    sClose: "Close", sVerified: "Verified", navAccount: "Account"
  },
  ru: {
    loginTitle: "Вход", loginSub: "С возвращением в NixelOS", fUser: "Имя пользователя", fPass: "Пароль", loginBtn: "Войти",
    noAcc: "Ещё нет аккаунта?", signUp: "Регистрация", regTitle: "Создать аккаунт", regSub: "Присоединяйся к сообществу NixelOS",
    fDisp: "Отображаемое имя (необязательно)", fPass2: "Повторите пароль", regBtn: "Зарегистрироваться", haveAcc: "Уже есть аккаунт?",
    logIn: "Войти", back: "Назад на сайт",
    eFill: "Заполните все поля", eUser: "Имя: 3–20 символов, буквы, цифры и _", ePassLen: "Пароль должен быть не короче 8 символов",
    ePassMatch: "Пароли не совпадают", eTaken: "Это имя недоступно", eCreds: "Неверное имя пользователя или пароль",
    eNet: "Что-то пошло не так. Попробуйте позже", eRate: "Слишком много попыток. Подождите немного", eDisp: "Отображаемое имя: 2–32 символа",
    pTitle: "Ваш профиль", pChange: "Сменить аватарку", pRemove: "Убрать аватарку", pBio: "О себе", pSave: "Сохранить", pSaved: "Сохранено",
    pLogout: "Выйти", pNewPass: "Новый пароль", pChangePass: "Сменить пароль", pPassDone: "Пароль изменён",
    eAvatar: "Только JPG, PNG или WebP до 2 МБ", pWait: "Подождите…", pUserHint: "Имя пользователя изменить нельзя", pSecurity: "Безопасность",
    sComments: "Комментарии", sWrite: "Напишите комментарий…", sPost: "Отправить", sLoginC: "Войдите, чтобы комментировать", sLoginR: "Войдите, чтобы ставить реакции",
    sDel: "Удалить", sNone: "Комментариев пока нет. Будьте первым!", sEmpty: "Комментарий не может быть пустым", eLoad: "Не удалось загрузить комментарии",
    sClose: "Закрыть", sVerified: "Подтверждён", navAccount: "Аккаунт"
  },
  uk: {
    loginTitle: "Вхід", loginSub: "З поверненням у NixelOS", fUser: "Ім'я користувача", fPass: "Пароль", loginBtn: "Увійти",
    noAcc: "Ще немає акаунта?", signUp: "Реєстрація", regTitle: "Створити акаунт", regSub: "Приєднуйся до спільноти NixelOS",
    fDisp: "Відображуване ім'я (необов'язково)", fPass2: "Повторіть пароль", regBtn: "Зареєструватися", haveAcc: "Вже є акаунт?",
    logIn: "Увійти", back: "Назад на сайт",
    eFill: "Заповніть усі поля", eUser: "Ім'я: 3–20 символів, літери, цифри та _", ePassLen: "Пароль має бути не коротшим за 8 символів",
    ePassMatch: "Паролі не збігаються", eTaken: "Це ім'я недоступне", eCreds: "Неправильне ім'я користувача або пароль",
    eNet: "Щось пішло не так. Спробуйте пізніше", eRate: "Забагато спроб. Зачекайте трохи", eDisp: "Відображуване ім'я: 2–32 символи",
    pTitle: "Ваш профіль", pChange: "Змінити аватарку", pRemove: "Прибрати аватарку", pBio: "Про себе", pSave: "Зберегти", pSaved: "Збережено",
    pLogout: "Вийти", pNewPass: "Новий пароль", pChangePass: "Змінити пароль", pPassDone: "Пароль змінено",
    eAvatar: "Лише JPG, PNG або WebP до 2 МБ", pWait: "Зачекайте…", pUserHint: "Ім'я користувача змінити не можна", pSecurity: "Безпека",
    sComments: "Коментарі", sWrite: "Напишіть коментар…", sPost: "Надіслати", sLoginC: "Увійдіть, щоб коментувати", sLoginR: "Увійдіть, щоб ставити реакції",
    sDel: "Видалити", sNone: "Коментарів поки немає. Будьте першим!", sEmpty: "Коментар не може бути порожнім", eLoad: "Не вдалося завантажити коментарі",
    sClose: "Закрити", sVerified: "Підтверджений", navAccount: "Акаунт"
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
  const s = error && error.status;
  if (m.includes("invalid login")) return "eCreds";
  if (m.includes("already") || m.includes("database error")) return "eTaken";
  if (s === 429 || m.includes("rate")) return "eRate";
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
  const { data } = await sb.from("profiles")
    .select("id,username,display_name,bio,avatar_path,is_verified,created_at")
    .eq("id", uid).maybeSingle();
  return data;
}

export async function initMenuAccount(base) {
  const a = document.getElementById("account-link");
  if (!a) return;
  try {
    const user = await getSessionUser();
    if (!user) { a.href = base + "Auth/login.html"; return; }
    a.href = base + "profile.html";
    const p = await getMyProfile(user.id);
    const span = a.querySelector("span");
    if (p && span) { span.removeAttribute("data-i18n"); span.textContent = p.display_name; }
  } catch (e) {}
}

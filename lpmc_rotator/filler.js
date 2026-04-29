// content/filler.js  v2.2
// LPMC Password Rotator — Заполнитель полей по маппингу
//
// Changelog v2.2:
//   - GitHub <auto-check> веб-компонент: ждём async-валидации перед переходом
//   - Правильный порядок событий для Stimulus/Turbo (GitHub)
//   - Раскрытие формы через "Change password" перед заполнением
//   - Исправлен submitForm: ищет кнопку "Update password" по тексту
//   - Улучшен waitForResult: GitHub flash-классы + перезагрузка страницы
//   - Вся старая логика v1 сохранена как fallback

'use strict';

(function () {
    if (window.__lpmc_filler_registered) return;
    window.__lpmc_filler_registered = true;

    const FILL_DELAY_MS   = 200;
    const RESULT_WAIT_MS  = 10_000;
    const VISIBLE_WAIT_MS = 7_000;
    // Пауза после заполнения поля нового пароля —
    // <auto-check> GitHub делает async-запрос к /users/password
    const AUTO_CHECK_WAIT_MS = 1_500;

    chrome.runtime.onMessage.addListener((msg, _sender, sendResponse) => {
        if (msg.action !== 'lpmc_fill') return false;
        fill(msg).then(sendResponse).catch(e =>
            sendResponse({ success: false, message: e.message })
        );
        return true;
    });

    // ─────────────────────────────────────────────────────────────────────
    // Основной поток
    // ─────────────────────────────────────────────────────────────────────

    async function fill({ mapping, oldPassword, newPassword }) {
        const { oldPassword: oldSel, newPassword: newSel,
                confirmPassword: confirmSel, submitAction } = mapping;

        // Шаг 0: убедиться что форма раскрыта
        await ensureFormVisible(newSel?.selector || newSel);

        // Шаг 1: старый пароль
        if (oldSel && oldPassword) {
            const el = await waitForVisible(oldSel.selector || oldSel, VISIBLE_WAIT_MS);
            if (el) {
                await fillInput(el, oldPassword);
                await sleep(FILL_DELAY_MS);
            } else {
                console.warn('[LPMC Filler] oldPassword field not found:', oldSel);
            }
        }

        // Шаг 2: новый пароль
        if (!newSel) return { success: false, message: 'mapping: нет newPassword' };

        const newEl = await waitForVisible(newSel.selector || newSel, VISIBLE_WAIT_MS);
        if (!newEl) return { success: false, message: `newPassword not found: ${newSel.selector || newSel}` };

        await fillInput(newEl, newPassword);
        // Ждём async-валидацию GitHub <auto-check>
        await sleep(AUTO_CHECK_WAIT_MS);

        // Шаг 3: подтверждение пароля
        if (confirmSel) {
            const confirmEl = await waitForVisible(confirmSel.selector || confirmSel, VISIBLE_WAIT_MS);
            if (confirmEl) {
                await fillInput(confirmEl, newPassword);
                await sleep(FILL_DELAY_MS);
            }
        }

        await sleep(400);

        // Шаг 4: отправка формы
        const submitted = await submitForm(submitAction, newEl);
        if (!submitted) console.warn('[LPMC Filler] Submit button not found.');

        // Шаг 5: ждём подтверждения
        const resultMsg = await waitForResult(RESULT_WAIT_MS);
        return { success: true, message: resultMsg };
    }

    // ─────────────────────────────────────────────────────────────────────
    // Раскрытие формы если скрыта
    // ─────────────────────────────────────────────────────────────────────

    async function ensureFormVisible(selector) {
        // Если целевое поле уже видно — выходим
        if (selector) {
            const el = resolveElement(selector);
            if (el && isVisible(el)) return;
        }

        // GitHub: ищем "Change password"
        const githubBtn = findButtonByText(['Change password', 'Change Password']);
        if (githubBtn) {
            githubBtn.click();
            // Ждём появления формы
            await waitForDom(
                () => document.querySelector('input[type="password"]') !== null,
                6_000
            );
            await sleep(600);
            return;
        }

        // Общие toggle-кнопки
        const toggleSelectors = [
            'button[aria-expanded="false"][aria-controls*="password" i]',
            '[class*="password-section"] button:not([type="submit"])',
        ];
        for (const sel of toggleSelectors) {
            const btn = document.querySelector(sel);
            if (btn) { btn.click(); await sleep(600); return; }
        }

        // details/summary
        document.querySelectorAll('details').forEach(det => {
            if (!det.open && det.querySelector('input[type="password"]')) det.open = true;
        });
        await sleep(400);
    }

    // ─────────────────────────────────────────────────────────────────────
    // Ждём видимости элемента
    // ─────────────────────────────────────────────────────────────────────

    function waitForVisible(selector, timeoutMs) {
        return new Promise(resolve => {
            const el = resolveElement(selector);
            if (el && isVisible(el)) { resolve(el); return; }

            const timer = setTimeout(() => {
                obs.disconnect();
                // Отдаём элемент даже если CSS скрыт — GitHub может скрывать через overflow/height
                resolve(resolveElement(selector));
            }, timeoutMs);

            const obs = new MutationObserver(() => {
                const found = resolveElement(selector);
                if (found && isVisible(found)) {
                    clearTimeout(timer); obs.disconnect(); resolve(found);
                }
            });
            obs.observe(document.body, { childList: true, subtree: true, attributes: true });
        });
    }

    // ─────────────────────────────────────────────────────────────────────
    // Заполнение поля
    // Совместимо с React, Vue, Angular, Stimulus (GitHub), Turbo
    // ─────────────────────────────────────────────────────────────────────

    async function fillInput(el, value) {
        el.scrollIntoView({ block: 'center' });
        el.focus();
        await sleep(50);

        // Очищаем поле перед вводом
        el.select?.();

        // Нативный setter — обходит React/Vue контроль
        const nativeSetter = Object.getOwnPropertyDescriptor(
            HTMLInputElement.prototype, 'value'
        )?.set;
        if (nativeSetter) nativeSetter.call(el, value);
        else el.value = value;

        // Полная цепочка событий для Stimulus/Turbo (GitHub)
        el.dispatchEvent(new Event('input',  { bubbles: true, cancelable: true }));
        el.dispatchEvent(new Event('change', { bubbles: true, cancelable: true }));
        el.dispatchEvent(new KeyboardEvent('keydown', { bubbles: true, key: 'a' }));
        el.dispatchEvent(new KeyboardEvent('keyup',   { bubbles: true, key: 'a' }));

        await sleep(80);
        el.blur();
    }

    // ─────────────────────────────────────────────────────────────────────
    // Отправка формы
    // ─────────────────────────────────────────────────────────────────────

    async function submitForm(submitAction, referenceEl) {
        // Точный selector из LPMC
        if (submitAction?.selector) {
            const btn = resolveElement(submitAction.selector);
            if (btn) {
                btn.click();
                if (submitAction.waitForNavigation) await sleep(submitAction.navigationTimeout || 5_000);
                return true;
            }
        }

        // GitHub: кнопка "Update password" по тексту
        const updateBtn = findButtonByText(['Update password', 'Update Password', 'Save password']);
        if (updateBtn) { updateBtn.click(); return true; }

        // Форма referenceEl
        const form = referenceEl?.closest('form');
        if (form) {
            const btn = form.querySelector(
                'button[type="submit"], input[type="submit"], button:not([type="button"]):not([type="reset"])'
            );
            if (btn) { btn.click(); return true; }
            form.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }));
            return true;
        }

        // Глобальный поиск
        const globalBtn = document.querySelector('button[type="submit"], input[type="submit"]');
        if (globalBtn) { globalBtn.click(); return true; }

        return false;
    }

    // ─────────────────────────────────────────────────────────────────────
    // Ожидание результата от страницы
    // ─────────────────────────────────────────────────────────────────────

    function waitForResult(ms) {
        return new Promise(resolve => {

            // ── GitHub специфичные проверки ───────────────────────────────
            const checkGitHub = () => {
                // Flash-уведомления
                const flashSuccess = document.querySelector(
                    '.flash-success, [data-flash-type="success"], .js-flash-container .flash:not(.flash-error)'
                );
                if (flashSuccess?.textContent.trim()) {
                    return 'Пароль успешно изменён: ' + flashSuccess.textContent.trim().substring(0, 80);
                }

                const flashError = document.querySelector(
                    '.flash-error, [data-flash-type="error"], .error-message'
                );
                if (flashError?.textContent.trim()) {
                    return 'Ошибка: ' + flashError.textContent.trim().substring(0, 80);
                }

                // GitHub показывает валидационные ошибки в .field_with_errors
                const fieldErr = document.querySelector('.field_with_errors, #error_explanation');
                if (fieldErr?.textContent.trim()) {
                    return 'Ошибка валидации: ' + fieldErr.textContent.trim().substring(0, 80);
                }

                return null;
            };

            // ── Общие текстовые паттерны ──────────────────────────────────
            const SUCCESS_RE = [
                /password.*(changed|updated|reset|saved|successfully)/i,
                /пароль.*(изменён|обновлён|сохранён|изменен|успешно)/i,
                /successfully.*(changed|updated|saved)/i,
                /успешно/i,
            ];
            const ERROR_RE = [
                /incorrect.*password/i,
                /wrong.*password/i,
                /password.*incorrect/i,
                /doesn.*t match/i,
                /не совпадают/i,
                /неверный.*пароль/i,
            ];

            // Немедленная проверка
            const immediate = checkGitHub();
            if (immediate) { resolve(immediate); return; }

            const timer = setTimeout(() => {
                obs.disconnect();
                resolve('Пароль отправлен (нет явного подтверждения от сайта)');
            }, ms);

            const obs = new MutationObserver(() => {
                const ghResult = checkGitHub();
                if (ghResult) { clearTimeout(timer); obs.disconnect(); resolve(ghResult); return; }

                const text = document.body.innerText;
                for (const re of SUCCESS_RE) {
                    if (re.test(text)) {
                        clearTimeout(timer); obs.disconnect();
                        resolve('Пароль успешно изменён'); return;
                    }
                }
                for (const re of ERROR_RE) {
                    if (re.test(text)) {
                        clearTimeout(timer); obs.disconnect();
                        resolve('Сайт сообщил об ошибке'); return;
                    }
                }
            });

            obs.observe(document.body, {
                childList: true, subtree: true, characterData: true, attributes: true
            });
        });
    }

    // ─────────────────────────────────────────────────────────────────────
    // Утилиты
    // ─────────────────────────────────────────────────────────────────────

    function resolveElement(selector) {
        if (!selector) return null;
        let el = document.querySelector(selector);
        if (el) return el;
        // Shadow DOM глубина 1
        for (const host of document.querySelectorAll('*')) {
            if (!host.shadowRoot) continue;
            el = host.shadowRoot.querySelector(selector);
            if (el) return el;
        }
        return null;
    }

    function isVisible(el) {
        if (!el) return false;
        const s = getComputedStyle(el);
        if (s.display === 'none' || s.visibility === 'hidden') return false;
        const r = el.getBoundingClientRect();
        return r.width > 0 && r.height > 0;
    }

    function findButtonByText(texts) {
        for (const btn of document.querySelectorAll('button')) {
            const t = btn.textContent.trim().toLowerCase();
            if (texts.some(target => t === target.toLowerCase())) return btn;
        }
        return null;
    }

    function waitForDom(predicate, timeoutMs) {
        return new Promise(resolve => {
            if (predicate()) { resolve(); return; }
            const t = setTimeout(() => { obs.disconnect(); resolve(); }, timeoutMs);
            const obs = new MutationObserver(() => {
                if (predicate()) { clearTimeout(t); obs.disconnect(); resolve(); }
            });
            obs.observe(document.body, { childList: true, subtree: true });
        });
    }

    function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

})();

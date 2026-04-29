// content/scanner.js  v2.2
// LPMC Password Rotator — Сканер полей страницы
//
// Changelog v2.2:
//   - Точные реальные id GitHub: user_old_password_sign_in_methods и др.
//   - Раскрытие формы через кнопку "Change password" (не "Hide")
//   - Ожидание появления полей ПОСЛЕ клика по кнопке раскрытия
//   - Сохранена вся старая логика как fallback

'use strict';

(function () {
    if (window.__lpmc_scanner_registered) return;
    window.__lpmc_scanner_registered = true;

    const DYNAMIC_FORM_WAIT_MS = 6_000;

    chrome.runtime.onMessage.addListener((msg, _sender, sendResponse) => {
        if (msg.action !== 'lpmc_scan') return false;
        waitForPasswordFields().then(sendResponse).catch(e =>
            sendResponse({ error: e.message, fields: [], forms: [], pageMetadata: {} })
        );
        return true;
    });

    // ─────────────────────────────────────────────────────────────────────
    // Главная точка входа
    // ─────────────────────────────────────────────────────────────────────

    async function waitForPasswordFields() {
        // Шаг 1: раскрыть секцию если она скрыта
        const clicked = await tryExpandPasswordSection();

        // Шаг 2: ждём появления полей после клика
        if (clicked) {
            await waitForDom(
                () => document.querySelector('input[type="password"]') !== null,
                DYNAMIC_FORM_WAIT_MS
            );
            await sleep(500);
        }

        // Шаг 3: поля всё ещё не появились — ждём без клика
        if (!document.querySelector('input[type="password"]')) {
            await waitForDom(
                () => document.querySelector('input[type="password"]') !== null,
                DYNAMIC_FORM_WAIT_MS
            );
        }

        const fields = findAllPasswordFields();
        return {
            status:       'scan_complete',
            fields,
            forms:        findForms(),
            pageMetadata: collectMetadata()
        };
    }

    // ─────────────────────────────────────────────────────────────────────
    // Раскрытие скрытой секции смены пароля
    // Возвращает true если был произведён клик
    // ─────────────────────────────────────────────────────────────────────

    async function tryExpandPasswordSection() {
        // Поля уже есть — ничего не делаем
        if (document.querySelector('input[type="password"]')) return false;

        // ── GitHub: кнопка "Change password" ─────────────────────────────
        const githubBtn = findButtonByText(['Change password', 'Change Password']);
        if (githubBtn) {
            githubBtn.click();
            return true;
        }

        // ── Общие паттерны ────────────────────────────────────────────────
        const toggleSelectors = [
            'button[aria-expanded="false"][aria-controls*="password" i]',
            'button[aria-controls*="password" i]',
            'button[data-toggle*="password" i]',
            '[class*="password-section"] button:not([type="submit"])',
            '[class*="password-form"] button:not([type="submit"])',
        ];

        for (const sel of toggleSelectors) {
            try {
                const btn = document.querySelector(sel);
                if (!btn) continue;
                const controlsId = btn.getAttribute('aria-controls');
                if (controlsId) {
                    const panel = document.getElementById(controlsId);
                    if (panel && isRendered(panel)) continue;
                }
                btn.click();
                return true;
            } catch { /* ignore */ }
        }

        // ── details/summary ───────────────────────────────────────────────
        for (const det of document.querySelectorAll('details')) {
            if (!det.open && det.querySelector('input[type="password"]')) {
                det.open = true;
                return true;
            }
        }

        return false;
    }

    function findButtonByText(texts) {
        for (const btn of document.querySelectorAll('button')) {
            const t = btn.textContent.trim().toLowerCase();
            if (texts.some(target => t === target.toLowerCase())) return btn;
        }
        return null;
    }

    // ─────────────────────────────────────────────────────────────────────
    // Поиск полей пароля
    // ─────────────────────────────────────────────────────────────────────

    function findAllPasswordFields() {
        const candidates = new Set();

        // Приоритет 1: реальные GitHub id (из DevTools /settings/security)
        const githubIds = [
            'user_old_password_sign_in_methods',
            'user_new_password_sign_in_methods',
            'user_confirm_new_password_sign_in_methods',
            // Запасные (старый GitHub)
            'user_old_password',
            'user_password',
            'user_password_confirmation',
        ];
        for (const id of githubIds) {
            const el = document.getElementById(id);
            if (el) candidates.add(el);
        }

        // Приоритет 2: стандартные атрибуты
        [
            'input[type="password"]',
            'input[autocomplete="current-password"]',
            'input[autocomplete="new-password"]',
        ].forEach(sel => document.querySelectorAll(sel).forEach(el => candidates.add(el)));

        // Приоритет 3: name/id с "password"
        [
            'input[name*="old_password" i]',
            'input[name*="current_password" i]',
            'input[name*="new_password" i]',
            'input[name*="password_confirmation" i]',
            'input[name*="confirm_password" i]',
            'input[id*="old_password" i]',
            'input[id*="new_password" i]',
            'input[id*="confirm"][type="password"]',
        ].forEach(sel => document.querySelectorAll(sel).forEach(el => candidates.add(el)));

        // Приоритет 4: текстовые поля с password-семантикой (старый fallback)
        [
            'input[type="text"][name*="pass" i]',
            'input[type="text"][name*="pwd" i]',
            'input[type="text"][id*="password" i]',
            'input[type="text"][placeholder*="password" i]',
            'input[type="text"][placeholder*="пароль" i]',
            'input[type="text"][aria-label*="password" i]',
            'input[type="text"][aria-label*="пароль" i]',
            'input[type="text"][data-testid*="password" i]',
            'input[type="text"][data-cy*="password" i]',
        ].forEach(sel => document.querySelectorAll(sel).forEach(el => candidates.add(el)));

        // Shadow DOM
        document.querySelectorAll('*').forEach(el => {
            if (!el.shadowRoot) return;
            el.shadowRoot.querySelectorAll('input[type="password"]').forEach(sh => candidates.add(sh));
        });

        // same-origin iframes
        document.querySelectorAll('iframe').forEach(frame => {
            try {
                const doc = frame.contentDocument;
                if (doc) doc.querySelectorAll('input[type="password"]').forEach(el => candidates.add(el));
            } catch { /* cross-origin */ }
        });

        return Array.from(candidates)
            .filter(el => isInDOM(el))
            .map(el => describeField(el));
    }

    function describeField(el) {
        return {
            type:       el.type || 'text',
            label:      findLabel(el),
            id:         el.id   || null,
            name:       el.name || null,
            selector:   buildSelector(el),
            container:  describeContainer(el),
            attributes: {
                autocomplete: el.getAttribute('autocomplete') || null,
                placeholder:  el.getAttribute('placeholder')  || null,
                'aria-label': el.getAttribute('aria-label')   || null,
                'data-testid':el.getAttribute('data-testid')  || null,
                'data-cy':    el.getAttribute('data-cy')      || null,
                'data-qa':    el.getAttribute('data-qa')      || null,
                name:         el.name || null,
            }
        };
    }

    function findLabel(el) {
        if (el.id) {
            const lbl = document.querySelector(`label[for="${CSS.escape(el.id)}"]`);
            if (lbl) return lbl.innerText.trim().substring(0, 80);
        }
        const parentLbl = el.closest('label');
        if (parentLbl) return parentLbl.innerText.trim().substring(0, 80);
        return el.getAttribute('aria-label') || el.getAttribute('placeholder') || null;
    }

    function describeContainer(el) {
        const container = el.closest('div, section, fieldset') || el.parentElement;
        if (!container) return null;
        return {
            tagName:   container.tagName,
            className: container.className.substring(0, 120),
            innerText: container.innerText.trim().substring(0, 200)
        };
    }

    // ─────────────────────────────────────────────────────────────────────
    // Формы
    // ─────────────────────────────────────────────────────────────────────

    function findForms() {
        return Array.from(document.querySelectorAll('form'))
            .filter(form => form.querySelector('input[type="password"]'))
            .map(form => ({
                selector:     buildSelector(form),
                action:       form.getAttribute('action') || null,
                method:       (form.getAttribute('method') || 'GET').toUpperCase(),
                submitButton: findSubmitButton(form)
            }));
    }

    function findSubmitButton(form) {
        const btn = form.querySelector(
            'button[type="submit"], input[type="submit"], button:not([type="button"]):not([type="reset"])'
        );
        return btn ? buildSelector(btn) : null;
    }

    // ─────────────────────────────────────────────────────────────────────
    // Метаданные
    // ─────────────────────────────────────────────────────────────────────

    function collectMetadata() {
        return {
            url:              location.href,
            title:            document.title,
            hasMultipleSteps: detectMultiStep(),
            frameworks:       detectFrameworks()
        };
    }

    function detectMultiStep() {
        return ['[class*="step"]','[class*="wizard"]','[class*="progress"]',
                '[role="progressbar"]','[aria-current="step"]']
            .some(sel => document.querySelector(sel) !== null);
    }

    function detectFrameworks() {
        const f = [];
        if (window.React || document.querySelector('[data-reactroot]')) f.push('react');
        if (window.Vue   || document.querySelector('[data-v-]'))        f.push('vue');
        if (window.ng    || document.querySelector('[ng-version]'))      f.push('angular');
        if (window.__NEXT_DATA__)                                        f.push('next.js');
        if (window.__nuxt__)                                             f.push('nuxt');
        return f;
    }

    // ─────────────────────────────────────────────────────────────────────
    // Утилиты
    // ─────────────────────────────────────────────────────────────────────

    function isInDOM(el) {
        return document.contains(el) && el.type !== 'hidden';
    }

    function isRendered(el) {
        const s = getComputedStyle(el);
        if (s.display === 'none' || s.visibility === 'hidden') return false;
        const r = el.getBoundingClientRect();
        return r.width > 0 && r.height > 0;
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

    function buildSelector(el) {
        if (el.id) return `#${CSS.escape(el.id)}`;
        const testid = el.getAttribute('data-testid') || el.getAttribute('data-cy');
        if (testid) return `[data-testid="${CSS.escape(testid)}"]`;
        if (el.name) return `${el.tagName.toLowerCase()}[name="${CSS.escape(el.name)}"]`;
        const parts = [];
        let node = el;
        while (node && node !== document.body) {
            let part = node.tagName.toLowerCase();
            const siblings = Array.from(node.parentElement?.children || [])
                .filter(c => c.tagName === node.tagName);
            if (siblings.length > 1) part += `:nth-of-type(${siblings.indexOf(node) + 1})`;
            parts.unshift(part);
            node = node.parentElement;
        }
        return parts.join(' > ');
    }

})();

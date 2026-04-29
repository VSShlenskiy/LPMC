// service_worker.js
// LPMC Password Rotator — Manifest V3 Service Worker
// Протокол v2: scan → request_field_mapping → fill по точным селекторам
// Обратная совместимость с v1 (прямое заполнение) сохранена.

'use strict';

// ─────────────────────────────────────────────────────────────────────────────
// Конфигурация
// ─────────────────────────────────────────────────────────────────────────────
const WS_URL              = 'ws://localhost:12310';
const RECONNECT_DELAY     = 3000;
const PAGE_LOAD_TIMEOUT   = 15_000;
const PAGE_LOAD_EXTRA     = 1_500;
const CONTENT_TIMEOUT     = 90_000;
const MAX_RECONNECTS      = 20;
const TAB_CLOSE_DELAY     = 2_500;
const SEND_MSG_RETRIES    = 5;
const SEND_MSG_DELAY      = 300;

// Новые константы для протокола v2
const SCAN_TIMEOUT        = 10_000;   // макс. время сканирования страницы
const MAPPING_TIMEOUT     = 30_000;   // ожидание field_mapping от LPMC
const CACHE_TTL_MS        = 7 * 24 * 60 * 60 * 1000; // 7 дней
const CACHE_KEY           = 'fieldMappings';

// SPA-сайты требуют увеличенной паузы после загрузки (Turbo, Next.js, etc.)
const SPA_HOSTS = ['github.com', 'gitlab.com', 'bitbucket.org'];
const PAGE_LOAD_EXTRA_SPA = 3_000; // 3с для SPA

function getPageLoadExtra(url) {
    try {
        const host = new URL(url).hostname;
        return SPA_HOSTS.some(h => host === h || host.endsWith('.' + h))
            ? PAGE_LOAD_EXTRA_SPA
            : PAGE_LOAD_EXTRA;
    } catch { return PAGE_LOAD_EXTRA; }
}

// ─────────────────────────────────────────────────────────────────────────────
// Состояние
// ─────────────────────────────────────────────────────────────────────────────
let ws              = null;
let reconnectTimer  = null;
let reconnectCount  = 0;

// Ожидающие ответа field_mapping: taskId → { resolve, reject, timer }
const pendingMappings = new Map();

// ─────────────────────────────────────────────────────────────────────────────
// WebSocket — управление соединением
// ─────────────────────────────────────────────────────────────────────────────

function connect() {
    if (ws && (ws.readyState === WebSocket.OPEN ||
               ws.readyState === WebSocket.CONNECTING)) return;

    console.log('[LPMC SW] Connecting to', WS_URL, `(attempt ${reconnectCount + 1})`);

    try {
        ws = new WebSocket(WS_URL);
    } catch (e) {
        console.error('[LPMC SW] WebSocket constructor error:', e.message);
        scheduleReconnect();
        return;
    }

    ws.onopen = () => {
        console.log('[LPMC SW] Connected to LPMC desktop app.');
        reconnectCount = 0;
        cancelReconnect();
        updateIcon(true);
    };

    ws.onmessage = (event) => handleIncoming(event.data);

    ws.onerror = () => console.warn('[LPMC SW] WebSocket error event.');

    ws.onclose = (event) => {
        console.warn(`[LPMC SW] Disconnected (code=${event.code}).`);
        ws = null;
        updateIcon(false);
        scheduleReconnect();
    };
}

function scheduleReconnect() {
    cancelReconnect();
    if (reconnectCount >= MAX_RECONNECTS) {
        console.error('[LPMC SW] Max reconnect attempts reached.');
        return;
    }
    reconnectCount++;
    const delay = Math.min(RECONNECT_DELAY * reconnectCount, 30_000);
    console.log(`[LPMC SW] Reconnecting in ${delay / 1000}s...`);
    reconnectTimer = setTimeout(connect, delay);
}

function cancelReconnect() {
    if (reconnectTimer !== null) { clearTimeout(reconnectTimer); reconnectTimer = null; }
}

function send(obj) {
    if (ws && ws.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify(obj));
        return true;
    }
    console.warn('[LPMC SW] Cannot send — WebSocket not open.');
    return false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Обработка входящих сообщений
// ─────────────────────────────────────────────────────────────────────────────

async function handleIncoming(raw) {
    let msg;
    try { msg = JSON.parse(raw); }
    catch (e) { console.error('[LPMC SW] Invalid JSON received.'); return; }

    const { action } = msg;

    switch (action) {
        case 'rotate_password':
            await handleRotateCommand(msg);
            break;

        // ── Ответ LPMC на запрос маппинга полей (протокол v2)
        case 'field_mapping':
            handleFieldMapping(msg);
            break;

        case 'pong':
            break;

        default:
            console.warn('[LPMC SW] Unknown action:', action);
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Основной поток ротации (v2 с fallback на v1)
// ─────────────────────────────────────────────────────────────────────────────

async function handleRotateCommand(cmd) {
    const { taskId, entryId, url, oldPassword, newPassword } = cmd;
    console.log(`[LPMC SW] Rotate task ${taskId} | url: ${url}`);

    let tab = null;
    try {
        setPopupStatus('opening');
        tab = await openTab(url);
        await waitForTabLoad(tab.id, PAGE_LOAD_TIMEOUT, getPageLoadExtra(url));
        setPopupStatus('scanning');

        // ── Шаг 1: проверить кэш селекторов
        const domain = extractDomain(url);
        const cached = await getCachedMapping(domain);

        let mapping = null;

        if (cached) {
            console.log(`[LPMC SW] Using cached selectors for ${domain}`);
            mapping = cached;
            setPopupStatus('filling');
        } else {
            // ── Шаг 2: сканировать страницу
            const pageData = await scanPage(tab.id);

            // ── Шаг 3: запросить маппинг у LPMC
            setPopupStatus('waiting_mapping');
            try {
                mapping = await requestFieldMapping(taskId, entryId, pageData);
                // сохранить в кэш
                await cacheMapping(domain, mapping);
            } catch (mappingErr) {
                // ── Fallback v1: использовать старую эвристику
                console.warn('[LPMC SW] Mapping timeout/error, using v1 fallback:', mappingErr.message);
                mapping = null;
            }
            setPopupStatus('filling');
        }

        let result;
        if (mapping) {
            result = await executeRotationV2(tab.id, { mapping, oldPassword, newPassword });
        } else {
            result = await executeRotationV1(tab.id, { oldPassword, newPassword });
        }

        console.log(`[LPMC SW] Task ${taskId} succeeded.`);
        send({ action: 'result', taskId, entryId, status: 'success', message: result.message || 'Пароль успешно изменён' });
        setPopupStatus('success');

    } catch (error) {
        console.error(`[LPMC SW] Task ${taskId} failed:`, error.message);
        send({ action: 'result', taskId, entryId, status: 'error', message: error.message });
        setPopupStatus('error');
    } finally {
        if (tab) setTimeout(() => chrome.tabs.remove(tab.id).catch(() => {}), TAB_CLOSE_DELAY);
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Шаг 2: Сканирование страницы через executeScript({func})
// ВАЖНО: files:[] заблокированы CSP GitHub и других сайтов.
// func выполняется напрямую в контексте страницы — CSP не применяется.
// ─────────────────────────────────────────────────────────────────────────────

async function scanPage(tabId) {
    try {
        const results = await chrome.scripting.executeScript({
            target: { tabId, allFrames: false },
            func:   scanPageInline
        });
        const result = results?.[0]?.result;
        if (result && result.fields) return result;
        return { fields: [], forms: [], pageMetadata: {} };
    } catch (e) {
        console.warn('[LPMC SW] scanPage failed:', e.message);
        return { fields: [], forms: [], pageMetadata: {} };
    }
}

// Инлайн-функция: выполняется в контексте страницы, самодостаточна.
// Содержит полную логику scanner.js — не требует загрузки внешних файлов.
function scanPageInline() {
    const GITHUB_IDS = [
        'user_old_password_sign_in_methods',
        'user_new_password_sign_in_methods',
        'user_confirm_new_password_sign_in_methods',
        'user_old_password',
        'user_password',
        'user_password_confirmation',
    ];

    function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }
    function isInDOM(el) { return document.contains(el) && el.type !== 'hidden'; }
    function isRendered(el) {
        const s = getComputedStyle(el);
        if (s.display === 'none' || s.visibility === 'hidden') return false;
        const r = el.getBoundingClientRect();
        return r.width > 0 && r.height > 0;
    }
    function findButtonByText(texts) {
        for (const btn of document.querySelectorAll('button')) {
            const t = btn.textContent.trim().toLowerCase();
            if (texts.some(tx => t === tx.toLowerCase())) return btn;
        }
        return null;
    }
    function waitForDom(predicate, ms) {
        return new Promise(resolve => {
            if (predicate()) { resolve(); return; }
            const t = setTimeout(() => { obs.disconnect(); resolve(); }, ms);
            const obs = new MutationObserver(() => {
                if (predicate()) { clearTimeout(t); obs.disconnect(); resolve(); }
            });
            obs.observe(document.body, { childList: true, subtree: true });
        });
    }
    function buildSelector(el) {
        if (el.id) return '#' + el.id;
        if (el.name) return el.tagName.toLowerCase() + '[name="' + el.name + '"]';
        const testid = el.getAttribute('data-testid') || el.getAttribute('data-cy');
        if (testid) return '[data-testid="' + testid + '"]';
        const parts = [];
        let node = el;
        while (node && node !== document.body) {
            let part = node.tagName.toLowerCase();
            const siblings = Array.from(node.parentElement?.children || []).filter(c => c.tagName === node.tagName);
            if (siblings.length > 1) part += ':nth-of-type(' + (siblings.indexOf(node) + 1) + ')';
            parts.unshift(part);
            node = node.parentElement;
        }
        return parts.join(' > ');
    }
    function describeField(el) {
        let label = null;
        if (el.id) {
            const lbl = document.querySelector('label[for="' + el.id + '"]');
            if (lbl) label = lbl.innerText.trim().substring(0, 80);
        }
        if (!label) label = el.getAttribute('aria-label') || el.getAttribute('placeholder') || null;
        return {
            type: el.type || 'text', label,
            id:   el.id || null,
            name: el.name || null,
            selector: buildSelector(el),
            attributes: {
                autocomplete: el.getAttribute('autocomplete') || null,
                placeholder:  el.getAttribute('placeholder')  || null,
                'aria-label': el.getAttribute('aria-label')   || null,
                'data-testid':el.getAttribute('data-testid')  || null,
                name:         el.name || null,
            }
        };
    }
    function findAllPasswordFields() {
        const candidates = new Set();
        for (const id of GITHUB_IDS) { const el = document.getElementById(id); if (el) candidates.add(el); }
        const sels = [
            'input[type="password"]',
            'input[autocomplete="current-password"]',
            'input[autocomplete="new-password"]',
            'input[name*="old_password" i]',
            'input[name*="current_password" i]',
            'input[name*="new_password" i]',
            'input[name*="password_confirmation" i]',
            'input[name*="confirm_password" i]',
            'input[type="text"][name*="pass" i]',
            'input[type="text"][id*="password" i]',
            'input[type="text"][placeholder*="password" i]',
            'input[type="text"][aria-label*="password" i]',
        ];
        for (const sel of sels) document.querySelectorAll(sel).forEach(el => candidates.add(el));
        document.querySelectorAll('*').forEach(el => {
            if (!el.shadowRoot) return;
            el.shadowRoot.querySelectorAll('input[type="password"]').forEach(sh => candidates.add(sh));
        });
        return Array.from(candidates).filter(isInDOM).map(describeField);
    }
    function findForms() {
        return Array.from(document.querySelectorAll('form'))
            .filter(f => f.querySelector('input[type="password"]'))
            .map(form => {
                const btn = form.querySelector('button[type="submit"],input[type="submit"],button:not([type="button"]):not([type="reset"])');
                return {
                    selector:     buildSelector(form),
                    action:       form.getAttribute('action') || null,
                    method:       (form.getAttribute('method') || 'GET').toUpperCase(),
                    submitButton: btn ? buildSelector(btn) : null
                };
            });
    }
    async function run() {
        if (!document.querySelector('input[type="password"]')) {
            const btn = findButtonByText(['Change password', 'Change Password']);
            if (btn) {
                btn.click();
                await waitForDom(() => document.querySelector('input[type="password"]') !== null, 6000);
                await sleep(600);
            }
        }
        return {
            status: 'scan_complete',
            fields: findAllPasswordFields(),
            forms:  findForms(),
            pageMetadata: { url: location.href, title: document.title }
        };
    }
    return run();
}

// ─────────────────────────────────────────────────────────────────────────────
// Шаг 3: Запрос field_mapping у LPMC
// ─────────────────────────────────────────────────────────────────────────────

function requestFieldMapping(taskId, entryId, pageData) {
    return new Promise((resolve, reject) => {
        const timer = setTimeout(() => {
            pendingMappings.delete(taskId);
            reject(new Error('field_mapping timeout after 30s'));
        }, MAPPING_TIMEOUT);

        pendingMappings.set(taskId, { resolve, reject, timer });

        send({
            action:   'request_field_mapping',
            taskId,
            entryId,
            pageData
        });
    });
}

function handleFieldMapping(msg) {
    const { taskId, mapping } = msg;
    const pending = pendingMappings.get(taskId);
    if (!pending) {
        console.warn('[LPMC SW] Received field_mapping for unknown taskId:', taskId);
        return;
    }
    clearTimeout(pending.timer);
    pendingMappings.delete(taskId);
    pending.resolve(mapping);
}

// ─────────────────────────────────────────────────────────────────────────────
// Шаг 4a: Заполнение по маппингу через executeScript({func})
// Не использует files: — обходит CSP GitHub.
// Mapping, oldPassword, newPassword передаются как args.
// ─────────────────────────────────────────────────────────────────────────────

async function executeRotationV2(tabId, payload) {
    try {
        const results = await chrome.scripting.executeScript({
            target: { tabId, allFrames: false },
            func:   fillPageInline,
            args:   [payload.mapping, payload.oldPassword, payload.newPassword]
        });
        const result = results?.[0]?.result;
        if (!result) throw new Error('Filler: пустой результат');
        if (!result.success) throw new Error(result.message || 'Filler reported failure');
        return result;
    } catch (e) {
        throw new Error('executeRotationV2: ' + e.message);
    }
}

// Инлайн-функция заполнения: самодостаточна, выполняется в контексте страницы.
// Содержит полную логику filler.js.
// mapping, oldPassword, newPassword передаются через args — доступны как параметры.
function fillPageInline(mapping, oldPassword, newPassword) {
    const FILL_DELAY      = 200;
    const AUTO_CHECK_WAIT = 1500;
    const VISIBLE_WAIT    = 7000;
    const RESULT_WAIT     = 10000;

    function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

    function isVisible(el) {
        if (!el) return false;
        const s = getComputedStyle(el);
        if (s.display === 'none' || s.visibility === 'hidden') return false;
        const r = el.getBoundingClientRect();
        return r.width > 0 && r.height > 0;
    }

    function resolveEl(selector) {
        if (!selector) return null;
        let el = document.querySelector(selector);
        if (el) return el;
        for (const host of document.querySelectorAll('*')) {
            if (!host.shadowRoot) continue;
            el = host.shadowRoot.querySelector(selector);
            if (el) return el;
        }
        return null;
    }

    function waitForVisible(selector, ms) {
        return new Promise(resolve => {
            const el = resolveEl(selector);
            if (el && isVisible(el)) { resolve(el); return; }
            const t = setTimeout(() => { obs.disconnect(); resolve(resolveEl(selector)); }, ms);
            const obs = new MutationObserver(() => {
                const found = resolveEl(selector);
                if (found && isVisible(found)) { clearTimeout(t); obs.disconnect(); resolve(found); }
            });
            obs.observe(document.body, { childList: true, subtree: true, attributes: true });
        });
    }

    function waitForDom(predicate, ms) {
        return new Promise(resolve => {
            if (predicate()) { resolve(); return; }
            const t = setTimeout(() => { obs.disconnect(); resolve(); }, ms);
            const obs = new MutationObserver(() => {
                if (predicate()) { clearTimeout(t); obs.disconnect(); resolve(); }
            });
            obs.observe(document.body, { childList: true, subtree: true });
        });
    }

    function findButtonByText(texts) {
        for (const btn of document.querySelectorAll('button')) {
            const t = btn.textContent.trim().toLowerCase();
            if (texts.some(tx => t === tx.toLowerCase())) return btn;
        }
        return null;
    }

    async function fillInput(el, value) {
        el.scrollIntoView({ block: 'center' });
        el.focus();
        await sleep(50);
        const setter = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value')?.set;
        if (setter) setter.call(el, value); else el.value = value;
        el.dispatchEvent(new Event('input',  { bubbles: true, cancelable: true }));
        el.dispatchEvent(new Event('change', { bubbles: true, cancelable: true }));
        el.dispatchEvent(new KeyboardEvent('keydown', { bubbles: true, key: 'a' }));
        el.dispatchEvent(new KeyboardEvent('keyup',   { bubbles: true, key: 'a' }));
        await sleep(80);
        el.blur();
    }

    async function ensureFormOpen(selector) {
        const el = resolveEl(selector);
        if (el && isVisible(el)) return;
        const btn = findButtonByText(['Change password', 'Change Password']);
        if (btn) {
            btn.click();
            await waitForDom(() => document.querySelector('input[type="password"]') !== null, 6000);
            await sleep(600);
            return;
        }
        document.querySelectorAll('details').forEach(d => {
            if (!d.open && d.querySelector('input[type="password"]')) d.open = true;
        });
        await sleep(400);
    }

    async function submitForm(submitAction, refEl) {
        if (submitAction?.selector) {
            const btn = resolveEl(submitAction.selector);
            if (btn) { btn.click(); return true; }
        }
        const updateBtn = findButtonByText(['Update password', 'Update Password', 'Save password', 'Save Password']);
        if (updateBtn) { updateBtn.click(); return true; }
        const form = refEl?.closest('form');
        if (form) {
            const btn = form.querySelector('button[type="submit"],input[type="submit"],button:not([type="button"]):not([type="reset"])');
            if (btn) { btn.click(); return true; }
            form.dispatchEvent(new Event('submit', { bubbles: true }));
            return true;
        }
        const g = document.querySelector('button[type="submit"],input[type="submit"]');
        if (g) { g.click(); return true; }
        return false;
    }

    function waitForResult(ms) {
        return new Promise(resolve => {
            const checkGH = () => {
                const ok = document.querySelector('.flash-success,[data-flash-type="success"],.js-flash-container .flash:not(.flash-error)');
                if (ok?.textContent.trim()) return 'Пароль успешно изменён: ' + ok.textContent.trim().substring(0, 80);
                const err = document.querySelector('.flash-error,[data-flash-type="error"],.field_with_errors,#error_explanation');
                if (err?.textContent.trim()) return 'Ошибка: ' + err.textContent.trim().substring(0, 80);
                return null;
            };
            const immediate = checkGH();
            if (immediate) { resolve(immediate); return; }
            const t = setTimeout(() => { obs.disconnect(); resolve('Пароль отправлен (нет подтверждения от сайта)'); }, ms);
            const obs = new MutationObserver(() => {
                const r = checkGH();
                if (r) { clearTimeout(t); obs.disconnect(); resolve(r); return; }
                const text = document.body.innerText;
                if (/password.*(changed|updated|saved|successfully)/i.test(text) ||
                    /успешно/i.test(text)) {
                    clearTimeout(t); obs.disconnect(); resolve('Пароль успешно изменён');
                }
            });
            obs.observe(document.body, { childList: true, subtree: true, characterData: true, attributes: true });
        });
    }

    async function run() {
        const { oldPassword: oldSel, newPassword: newSel, confirmPassword: confirmSel, submitAction } = mapping;

        await ensureFormOpen(newSel?.selector || newSel);

        if (oldSel && oldPassword) {
            const el = await waitForVisible(oldSel.selector || oldSel, VISIBLE_WAIT);
            if (el) { await fillInput(el, oldPassword); await sleep(FILL_DELAY); }
        }

        if (!newSel) return { success: false, message: 'mapping: нет newPassword' };
        const newEl = await waitForVisible(newSel.selector || newSel, VISIBLE_WAIT);
        if (!newEl) return { success: false, message: 'newPassword field not found: ' + (newSel.selector || newSel) };
        await fillInput(newEl, newPassword);
        await sleep(AUTO_CHECK_WAIT); // ждём <auto-check> GitHub

        if (confirmSel) {
            const confirmEl = await waitForVisible(confirmSel.selector || confirmSel, VISIBLE_WAIT);
            if (confirmEl) { await fillInput(confirmEl, newPassword); await sleep(FILL_DELAY); }
        }

        await sleep(400);
        await submitForm(submitAction, newEl);
        const msg = await waitForResult(RESULT_WAIT);
        return { success: true, message: msg };
    }

    return run();
}

// ─────────────────────────────────────────────────────────────────────────────
// Шаг 4b: Fallback — старая эвристика v1 (встроена в SW)
// ─────────────────────────────────────────────────────────────────────────────

function executeRotationV1(tabId, payload) {
    return new Promise((resolve, reject) => {
        const timer = setTimeout(() => reject(new Error('Rotation v1 timeout')), CONTENT_TIMEOUT);

        chrome.scripting.executeScript({
            target: { tabId },
            func:   rotatePasswordV1,
            args:   [payload.oldPassword, payload.newPassword]
        }).then(injections => {
            clearTimeout(timer);
            const r = injections?.[0]?.result;
            if (!r) reject(new Error('Пустой результат'));
            else if (!r.success) reject(new Error(r.message));
            else resolve(r);
        }).catch(e => { clearTimeout(timer); reject(e); });
    });
}

// Самодостаточная функция v1 (выполняется в контексте страницы)
async function rotatePasswordV1(oldPassword, newPassword) {
    const FILL_DELAY_MS    = 120;
    const RESULT_WAIT_MS   = 5_000;

    function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

    function isVisible(el) {
        const s = getComputedStyle(el);
        return s.display !== 'none' && s.visibility !== 'hidden' && s.opacity !== '0';
    }

    function findPasswordFields() {
        const fields = Array.from(document.querySelectorAll('input[type="password"]')).filter(isVisible);
        if (fields.length === 0) return { oldPassword: null, newPassword: null, confirmPassword: null };

        const oldF    = fields.find(f => (f.autocomplete || '').includes('current-password'));
        const newF    = fields.find(f => (f.autocomplete || '').includes('new-password'));
        const confirmF = fields.find(f => f !== newF && (f.autocomplete || '').includes('new-password'));

        if (newF) return { oldPassword: oldF, newPassword: newF, confirmPassword: confirmF };
        if (fields.length >= 3) return { oldPassword: fields[0], newPassword: fields[1], confirmPassword: fields[2] };
        if (fields.length === 2) return { oldPassword: null, newPassword: fields[0], confirmPassword: fields[1] };
        return { oldPassword: null, newPassword: fields[0], confirmPassword: null };
    }

    async function fillInput(el, value) {
        el.focus();
        const setter = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value')?.set;
        if (setter) setter.call(el, value); else el.value = value;
        el.dispatchEvent(new Event('input',  { bubbles: true }));
        el.dispatchEvent(new Event('change', { bubbles: true }));
        await sleep(80);
        el.blur();
    }

    async function submitForm(ref) {
        const form = ref?.closest('form');
        if (form) {
            const btn = form.querySelector('button[type="submit"], input[type="submit"], button');
            if (btn) { btn.click(); return true; }
            form.dispatchEvent(new Event('submit', { bubbles: true }));
            return true;
        }
        const btn = document.querySelector('button[type="submit"], input[type="submit"]');
        if (btn) { btn.click(); return true; }
        return false;
    }

    function waitForResult(ms) {
        return new Promise(resolve => {
            const t = setTimeout(() => { obs.disconnect(); resolve('Пароль отправлен (нет подтверждения от сайта)'); }, ms);
            const obs = new MutationObserver(() => {
                const text = document.body.innerText.toLowerCase();
                if ((text.includes('password') && (text.includes('changed') || text.includes('updated'))) ||
                    text.includes('успешно')) {
                    clearTimeout(t); obs.disconnect(); resolve('Пароль изменён');
                } else if (text.includes('error') || text.includes('wrong') || text.includes('incorrect')) {
                    clearTimeout(t); obs.disconnect(); resolve('Сайт сообщил об ошибке (v1 fallback)');
                }
            });
            obs.observe(document.body, { childList: true, subtree: true });
        });
    }

    const fields = findPasswordFields();
    if (!fields.newPassword) return { success: false, message: 'Поля пароля не найдены (v1)' };

    if (fields.oldPassword && oldPassword) { await fillInput(fields.oldPassword, oldPassword); await sleep(FILL_DELAY_MS); }
    await fillInput(fields.newPassword, newPassword); await sleep(FILL_DELAY_MS);
    if (fields.confirmPassword) await fillInput(fields.confirmPassword, newPassword);

    await sleep(300);
    await submitForm(fields.newPassword);

    const msg = await waitForResult(RESULT_WAIT_MS);
    return { success: true, message: msg };
}

// ─────────────────────────────────────────────────────────────────────────────
// Кэш селекторов
// ─────────────────────────────────────────────────────────────────────────────

function extractDomain(url) {
    try { return new URL(url).hostname.toLowerCase(); }
    catch { return url; }
}

async function getCachedMapping(domain) {
    return new Promise(resolve => {
        chrome.storage.local.get(CACHE_KEY, data => {
            const all = data[CACHE_KEY] || {};
            const entry = all[domain];
            if (!entry) return resolve(null);
            if (Date.now() - new Date(entry.lastUsed).getTime() > CACHE_TTL_MS) {
                // Кэш устарел
                delete all[domain];
                chrome.storage.local.set({ [CACHE_KEY]: all });
                return resolve(null);
            }
            resolve(entry);
        });
    });
}

async function cacheMapping(domain, mapping) {
    return new Promise(resolve => {
        chrome.storage.local.get(CACHE_KEY, data => {
            const all = data[CACHE_KEY] || {};
            all[domain] = {
                ...mapping,
                lastUsed:     new Date().toISOString(),
                successCount: (all[domain]?.successCount || 0) + 1
            };
            chrome.storage.local.set({ [CACHE_KEY]: all }, resolve);
        });
    });
}

// ─────────────────────────────────────────────────────────────────────────────
// Статус в popup
// ─────────────────────────────────────────────────────────────────────────────

function setPopupStatus(status) {
    chrome.storage.local.set({ lpmc_status: status }).catch(() => {});
}

// ─────────────────────────────────────────────────────────────────────────────
// Вспомогательные функции
// ─────────────────────────────────────────────────────────────────────────────

function openTab(url) {
    return new Promise((resolve, reject) => {
        chrome.tabs.create({ url, active: true }, tab => {
            if (chrome.runtime.lastError)
                reject(new Error('Не удалось открыть вкладку: ' + chrome.runtime.lastError.message));
            else resolve(tab);
        });
    });
}

function waitForTabLoad(tabId, timeoutMs, extraDelay = 0) {
    return new Promise((resolve, reject) => {
        const timer = setTimeout(() => {
            chrome.tabs.onUpdated.removeListener(listener);
            reject(new Error(`Страница не загрузилась за ${timeoutMs / 1000}с`));
        }, timeoutMs);

        function listener(id, changeInfo) {
            if (id === tabId && changeInfo.status === 'complete') {
                clearTimeout(timer);
                chrome.tabs.onUpdated.removeListener(listener);
                setTimeout(resolve, extraDelay);
            }
        }
        chrome.tabs.onUpdated.addListener(listener);
    });
}

function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

async function sendMessageWithRetry(tabId, msg, retries = SEND_MSG_RETRIES, delay = SEND_MSG_DELAY) {
    for (let i = 0; i < retries; i++) {
        try {
            const response = await new Promise((resolve, reject) => {
                chrome.tabs.sendMessage(tabId, msg, resp => {
                    if (chrome.runtime.lastError) reject(new Error(chrome.runtime.lastError.message));
                    else resolve(resp);
                });
            });
            if (response !== undefined) return response;
        } catch (e) {
            if (i === retries - 1) throw e;
            await sleep(delay);
        }
    }
    throw new Error('sendMessage: all retries exhausted');
}

function updateIcon(connected) {
    const icon = connected ? 'icons/icon48.png' : 'icons/icon48_gray.png';
    chrome.action.setIcon({ path: icon }).catch(() => {});
    chrome.action.setTitle({ title: connected ? 'LPMC: подключён' : 'LPMC: нет соединения' }).catch(() => {});
}

// ─────────────────────────────────────────────────────────────────────────────
// Инициализация
// ─────────────────────────────────────────────────────────────────────────────

self.addEventListener('install', () => { console.log('[LPMC SW] Installed.'); self.skipWaiting(); });
self.addEventListener('activate', () => { console.log('[LPMC SW] Activated.'); clients.claim(); connect(); });

connect();

chrome.alarms.create('LPMC_KEEPALIVE', { periodInMinutes: 0.5 });
chrome.alarms.onAlarm.addListener(alarm => {
    if (alarm.name !== 'LPMC_KEEPALIVE') return;
    if (!ws || ws.readyState !== WebSocket.OPEN) { console.log('[LPMC SW] Keepalive: reconnecting...'); connect(); }
    else send({ action: 'ping' });
});

// service_worker.js
// LPMC Password Rotator — Manifest V3 Service Worker
// Держит WebSocket соединение с LPMC Desktop App (ws://localhost:12310)
// и оркестрирует ротацию паролей через вкладки браузера.

'use strict';

// ─────────────────────────────────────────────────────────────────────────────
// Конфигурация
// ─────────────────────────────────────────────────────────────────────────────
const WS_URL            = 'ws://localhost:12310';
const RECONNECT_DELAY   = 3000;   // базовая задержка переподключения (мс)
const PAGE_LOAD_TIMEOUT = 15000;  // максимум ожидания загрузки страницы (мс)
const PAGE_LOAD_EXTRA   = 1500;   // доп. пауза после load для JS на странице (мс)
const CONTENT_TIMEOUT   = 90000;  // ожидание ответа от content script (мс)
const MAX_RECONNECTS    = 20;     // максимум попыток переподключения
const TAB_CLOSE_DELAY   = 2500;   // пауза перед закрытием вкладки (мс)

// FIX: параметры retry для sendMessage
const SEND_MSG_RETRIES  = 5;      // количество попыток sendMessage
const SEND_MSG_DELAY    = 300;    // задержка между попытками (мс)

// ─────────────────────────────────────────────────────────────────────────────
// Состояние
// ─────────────────────────────────────────────────────────────────────────────
let ws             = null;
let reconnectTimer = null;
let reconnectCount = 0;

// ─────────────────────────────────────────────────────────────────────────────
// WebSocket — управление соединением
// ─────────────────────────────────────────────────────────────────────────────

function connect() {
    if (ws && (ws.readyState === WebSocket.OPEN ||
               ws.readyState === WebSocket.CONNECTING)) {
        return;
    }

    console.log('[LPMC SW] Connecting to', WS_URL,
                `(attempt ${reconnectCount + 1})`);

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

    ws.onmessage = (event) => {
        handleIncoming(event.data);
    };

    ws.onerror = () => {
        console.warn('[LPMC SW] WebSocket error event.');
    };

    ws.onclose = (event) => {
        console.warn(`[LPMC SW] Disconnected (code=${event.code}, reason="${event.reason}").`);
        ws = null;
        updateIcon(false);
        scheduleReconnect();
    };
}

function scheduleReconnect() {
    cancelReconnect();

    if (reconnectCount >= MAX_RECONNECTS) {
        console.error('[LPMC SW] Max reconnect attempts reached. Stopping.');
        return;
    }

    reconnectCount++;
    const delay = Math.min(RECONNECT_DELAY * reconnectCount, 30_000);
    console.log(`[LPMC SW] Reconnecting in ${delay / 1000}s...`);
    reconnectTimer = setTimeout(connect, delay);
}

function cancelReconnect() {
    if (reconnectTimer !== null) {
        clearTimeout(reconnectTimer);
        reconnectTimer = null;
    }
}

function send(obj) {
    if (ws && ws.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify(obj));
        return true;
    }
    console.warn('[LPMC SW] Cannot send message — WebSocket not open.');
    return false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Обработка входящих сообщений от LPMC Desktop
// ─────────────────────────────────────────────────────────────────────────────

async function handleIncoming(raw) {
    let msg;
    try {
        msg = JSON.parse(raw);
    } catch (e) {
        console.error('[LPMC SW] Failed to parse JSON:', raw.substring(0, 200));
        return;
    }

    const { action } = msg;

    switch (action) {
        case 'rotate_password':
            await handleRotateCommand(msg);
            break;

        case 'pong':
            break;

        default:
            console.warn('[LPMC SW] Unknown action:', action);
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Основной поток ротации пароля
// ─────────────────────────────────────────────────────────────────────────────

async function handleRotateCommand(cmd) {
    const { taskId, entryId, url, oldPassword, newPassword } = cmd;

    console.log(`[LPMC SW] Rotate task ${taskId} started | url: ${url}`);

    let tab = null;

    try {
        tab = await openTab(url);
        await waitForTabLoad(tab.id, PAGE_LOAD_TIMEOUT, PAGE_LOAD_EXTRA);

        const result = await executeRotation(tab.id, { oldPassword, newPassword });

        console.log(`[LPMC SW] Task ${taskId} succeeded: ${result.message}`);
        send({
            action:  'result',
            taskId,
            entryId,
            status:  'success',
            message: result.message || 'Пароль успешно изменён'
        });

    } catch (error) {
        console.error(`[LPMC SW] Task ${taskId} failed: ${error.message}`);
        send({
            action:  'result',
            taskId,
            entryId,
            status:  'error',
            message: error.message || 'Неизвестная ошибка'
        });
    } finally {
        if (tab) {
            setTimeout(() => {
                chrome.tabs.remove(tab.id).catch(() => {});
            }, TAB_CLOSE_DELAY);
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Вспомогательные функции
// ─────────────────────────────────────────────────────────────────────────────

function openTab(url) {
    return new Promise((resolve, reject) => {
        chrome.tabs.create({ url, active: true }, (tab) => {
            if (chrome.runtime.lastError) {
                reject(new Error(
                    'Не удалось открыть вкладку: ' + chrome.runtime.lastError.message
                ));
            } else {
                resolve(tab);
            }
        });
    });
}

function waitForTabLoad(tabId, timeoutMs, extraDelay = 0) {
    return new Promise((resolve, reject) => {
        const timer = setTimeout(() => {
            chrome.tabs.onUpdated.removeListener(listener);
            reject(new Error(
                `Страница не загрузилась за ${timeoutMs / 1000} секунд`
            ));
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

// ─────────────────────────────────────────────────────────────────────────────
// FIX: утилита — задержка
// ─────────────────────────────────────────────────────────────────────────────
function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

// ─────────────────────────────────────────────────────────────────────────────
// FIX: sendMessage с повторными попытками
//
// Проблема: после executeScript content.js начинает выполняться асинхронно.
// К моменту вызова sendMessage listener в content.js ещё не зарегистрирован,
// поэтому Chrome возвращает "Receiving end does not exist".
//
// Решение: повторять sendMessage до SEND_MSG_RETRIES раз с паузой SEND_MSG_DELAY.
// Как только content script зарегистрирует listener — сообщение дойдёт.
// ─────────────────────────────────────────────────────────────────────────────


/**
 * Внедрить content.js и дождаться ответа с retry-логикой.
 */
async function executeRotation(tabId, payload) {
    return new Promise(async (resolve, reject) => {
        const timer = setTimeout(() => {
            reject(new Error(
                `Content script не ответил за ${CONTENT_TIMEOUT / 1000} секунд`
            ));
        }, CONTENT_TIMEOUT);

        try {
            const [injection] = await chrome.scripting.executeScript({
                target: { tabId },
                func: async (oldPassword, newPassword) => {

                    'use strict';

                    // ─────────────────────────────────────────
                    // CONFIG
                    // ─────────────────────────────────────────
                    const FILL_DELAY_MS  = 200;
                    const POST_FILL_MS   = 600;
                    const RESULT_WAIT_MS = 6000;
                    const RETRY_COUNT    = 3;
                    const RETRY_GAP_MS   = 2000;

                    const sleep = (ms) => new Promise(r => setTimeout(r, ms));

                    // ─────────────────────────────────────────
                    // MAIN
                    // ─────────────────────────────────────────
                    async function rotatePassword() {
                        let lastError = null;

                        for (let attempt = 1; attempt <= RETRY_COUNT; attempt++) {
                            try {
                                const fields = findPasswordFields();

                                if (!fields.newPassword) {
                                    throw new Error('Поле нового пароля не найдено');
                                }

                                await fillFields(fields);
                                await sleep(POST_FILL_MS);

                                const submitted = await submitForm(fields);
                                if (!submitted) {
                                    throw new Error('Не удалось отправить форму');
                                }

                                const result = await waitForPageResult(RESULT_WAIT_MS);
                                return { success: true, message: result };

                            } catch (e) {
                                lastError = e;
                                if (attempt < RETRY_COUNT) {
                                    await sleep(RETRY_GAP_MS);
                                }
                            }
                        }

                        throw lastError || new Error('Все попытки исчерпаны');
                    }

                    // ─────────────────────────────────────────
                    // FIND FIELDS
                    // ─────────────────────────────────────────
                    function findPasswordFields() {
                        const fields = Array.from(
                            document.querySelectorAll('input[type="password"]')
                        ).filter(isVisible);

                        if (fields.length === 0) {
                            return { oldPassword: null, newPassword: null, confirmPassword: null };
                        }

                        // autocomplete
                        const oldF = fields.find(f =>
                            (f.autocomplete || '').includes('current-password')
                        );

                        const newF = fields.find(f =>
                            (f.autocomplete || '').includes('new-password')
                        );

                        const confirmF = fields.find(f =>
                            f !== newF &&
                            (f.autocomplete || '').includes('new-password')
                        );

                        if (newF) {
                            return { oldPassword: oldF, newPassword: newF, confirmPassword: confirmF };
                        }

                        // fallback by position
                        if (fields.length >= 3) {
                            return {
                                oldPassword: fields[0],
                                newPassword: fields[1],
                                confirmPassword: fields[2]
                            };
                        }

                        if (fields.length === 2) {
                            return {
                                oldPassword: null,
                                newPassword: fields[0],
                                confirmPassword: fields[1]
                            };
                        }

                        return {
                            oldPassword: null,
                            newPassword: fields[0],
                            confirmPassword: null
                        };
                    }

                    // ─────────────────────────────────────────
                    // FILL
                    // ─────────────────────────────────────────
                    async function fillFields(fields) {
                        if (fields.oldPassword && oldPassword) {
                            await fillInput(fields.oldPassword, oldPassword);
                            await sleep(FILL_DELAY_MS);
                        }

                        await fillInput(fields.newPassword, newPassword);
                        await sleep(FILL_DELAY_MS);

                        if (fields.confirmPassword) {
                            await fillInput(fields.confirmPassword, newPassword);
                        }
                    }

                    async function fillInput(el, value) {
                        el.focus();

                        const setter = Object.getOwnPropertyDescriptor(
                            HTMLInputElement.prototype, 'value'
                        )?.set;

                        if (setter) setter.call(el, value);
                        else el.value = value;

                        el.dispatchEvent(new Event('input', { bubbles: true }));
                        el.dispatchEvent(new Event('change', { bubbles: true }));

                        await sleep(80);
                        el.blur();
                    }

                    // ─────────────────────────────────────────
                    // SUBMIT
                    // ─────────────────────────────────────────
                    async function submitForm(fields) {
                        const ref = fields.newPassword || fields.confirmPassword;
                        if (!ref) return false;

                        const form = ref.closest('form');

                        if (form) {
                            const btn = form.querySelector(
                                'button[type="submit"], input[type="submit"], button'
                            );
                            if (btn) {
                                btn.click();
                                return true;
                            }

                            form.dispatchEvent(new Event('submit', { bubbles: true }));
                            return true;
                        }

                        const btn = document.querySelector('button, input[type="submit"]');
                        if (btn) {
                            btn.click();
                            return true;
                        }

                        return false;
                    }

                    // ─────────────────────────────────────────
                    // RESULT
                    // ─────────────────────────────────────────
                    function waitForPageResult(timeout) {
                        return new Promise((resolve) => {
                            const timer = setTimeout(() => {
                                resolve('Пароль отправлен (нет подтверждения)');
                            }, timeout);

                            const observer = new MutationObserver(() => {
                                const text = document.body.innerText.toLowerCase();

                                if (text.includes('password') &&
                                    (text.includes('changed') || text.includes('updated'))) {
                                    clearTimeout(timer);
                                    observer.disconnect();
                                    resolve('Пароль изменён');
                                }

                                if (text.includes('error') || text.includes('wrong')) {
                                    clearTimeout(timer);
                                    observer.disconnect();
                                    resolve('Сайт сообщил об ошибке');
                                }
                            });

                            observer.observe(document.body, {
                                childList: true,
                                subtree: true
                            });
                        });
                    }

                    function isVisible(el) {
                        const s = getComputedStyle(el);
                        return s.display !== 'none' && s.visibility !== 'hidden';
                    }

                    // ─────────────────────────────────────────
                    return await rotatePassword();
                },
                args: [payload.oldPassword, payload.newPassword]
            });

            clearTimeout(timer);

            if (!injection || !injection.result) {
                throw new Error('Пустой результат');
            }

            if (!injection.result.success) {
                throw new Error(injection.result.message);
            }

            resolve(injection.result);

        } catch (e) {
            clearTimeout(timer);
            reject(new Error('Rotation failed: ' + e.message));
        }
    });
}

/**
 * Обновить иконку расширения.
 */
function updateIcon(connected) {
    const icon = connected ? 'icons/icon48.png' : 'icons/icon48_gray.png';
    chrome.action.setIcon({ path: icon }).catch(() => {});
    chrome.action.setTitle({
        title: connected
            ? 'LPMC: подключён'
            : 'LPMC: нет соединения с приложением'
    }).catch(() => {});
}

// ─────────────────────────────────────────────────────────────────────────────
// Инициализация Service Worker
// ─────────────────────────────────────────────────────────────────────────────

self.addEventListener('install', () => {
    console.log('[LPMC SW] Installed.');
    self.skipWaiting();
});

self.addEventListener('activate', () => {
    console.log('[LPMC SW] Activated.');
    clients.claim();
    connect();
});

connect();

// ─────────────────────────────────────────────────────────────────────────────
// Keepalive через Alarms
// ─────────────────────────────────────────────────────────────────────────────
chrome.alarms.create('LPMC_KEEPALIVE', { periodInMinutes: 0.5 });

chrome.alarms.onAlarm.addListener((alarm) => {
    if (alarm.name !== 'LPMC_KEEPALIVE') return;

    if (!ws || ws.readyState !== WebSocket.OPEN) {
        console.log('[LPMC SW] Keepalive: reconnecting...');
        connect();
    } else {
        send({ action: 'ping' });
    }
});

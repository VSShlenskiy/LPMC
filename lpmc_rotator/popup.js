// popup.js
// LPMC Password Rotator — Popup с детальным статусом операции

'use strict';

const dot        = document.getElementById('dot');
const statusText = document.getElementById('statusText');
const detailText = document.getElementById('detailText');

// ── Статусы операции ─────────────────────────────────────────────────────────
const STATUS_LABELS = {
    opening:         '🌐 Открываю страницу...',
    scanning:        '🔍 Сканирую поля...',
    waiting_mapping: '⏳ Ожидаю маппинг от LPMC...',
    filling:         '✏️ Заполняю поля...',
    success:         '✅ Пароль успешно изменён',
    error:           '❌ Ошибка при смене пароля'
};

// ── WebSocket: проверка соединения ────────────────────────────────────────────
const ws = new WebSocket('ws://localhost:12310');

ws.onopen = () => {
    setConnected(true);
    ws.close();
};

ws.onerror = () => setConnected(false);
ws.onclose = () => {};

function setConnected(connected) {
    dot.className = 'dot ' + (connected ? 'connected' : 'disconnected');
    statusText.textContent = connected ? 'Подключён к LPMC' : 'LPMC не запущен';
}

// ── Текущий статус операции из storage ───────────────────────────────────────
chrome.storage.local.get(['lpmc_status'], data => {
    const status = data.lpmc_status;
    if (status && STATUS_LABELS[status]) {
        if (detailText) detailText.textContent = STATUS_LABELS[status];
    }
});

// Обновление в реальном времени
chrome.storage.onChanged.addListener((changes, area) => {
    if (area !== 'local' || !changes.lpmc_status) return;
    const status = changes.lpmc_status.newValue;
    if (detailText && STATUS_LABELS[status]) {
        detailText.textContent = STATUS_LABELS[status];
    }
});

// ── Кэш: показать количество сохранённых доменов ─────────────────────────────
chrome.storage.local.get(['fieldMappings'], data => {
    const count = Object.keys(data.fieldMappings || {}).length;
    const cacheEl = document.getElementById('cacheCount');
    if (cacheEl) cacheEl.textContent = `Кэш: ${count} ${pluralize(count, 'домен', 'домена', 'доменов')}`;
});

function pluralize(n, one, few, many) {
    const mod10 = n % 10, mod100 = n % 100;
    if (mod10 === 1 && mod100 !== 11) return one;
    if ([2, 3, 4].includes(mod10) && ![12, 13, 14].includes(mod100)) return few;
    return many;
}

// ── Очистить кэш ─────────────────────────────────────────────────────────────
const clearBtn = document.getElementById('clearCache');
if (clearBtn) {
    clearBtn.addEventListener('click', () => {
        chrome.storage.local.remove('fieldMappings', () => {
            const cacheEl = document.getElementById('cacheCount');
            if (cacheEl) cacheEl.textContent = 'Кэш: очищен';
        });
    });
}

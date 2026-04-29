// content/submit_handler.js
// LPMC Password Rotator — Обработчик отправки формы и многошаговых процессов
// Используется как вспомогательный модуль filler.js для сложных сценариев:
//   - Форма с несколькими шагами (wizard)
//   - Модальные окна подтверждения
//   - 2FA / одноразовые коды

'use strict';

(function () {
    if (window.__lpmc_submit_handler_registered) return;
    window.__lpmc_submit_handler_registered = true;

    const STEP_TRANSITION_TIMEOUT = 10_000; // ожидание перехода между шагами

    chrome.runtime.onMessage.addListener((msg, _sender, sendResponse) => {
        if (msg.action === 'lpmc_submit') {
            handleSubmit(msg).then(sendResponse).catch(e => {
                sendResponse({ success: false, message: e.message });
            });
            return true;
        }

        if (msg.action === 'lpmc_detect_step') {
            sendResponse(detectCurrentStep());
            return false;
        }

        if (msg.action === 'lpmc_fill_2fa') {
            fill2FA(msg.code).then(sendResponse).catch(e => {
                sendResponse({ success: false, message: e.message });
            });
            return true;
        }

        return false;
    });

    // ─────────────────────────────────────────────────────────────────────
    // Отправка формы с ожиданием перехода
    // ─────────────────────────────────────────────────────────────────────

    async function handleSubmit({ selector, waitForNavigation, navigationTimeout }) {
        const btn = resolveElement(selector);
        if (!btn) return { success: false, message: `Submit button not found: ${selector}` };

        btn.click();

        if (waitForNavigation) {
            await waitForPageTransition(navigationTimeout || STEP_TRANSITION_TIMEOUT);
        }

        return { success: true, message: 'Форма отправлена' };
    }

    /**
     * Ожидает изменения URL или значимого изменения DOM (переход к следующему шагу).
     */
    function waitForPageTransition(timeoutMs) {
        return new Promise(resolve => {
            const initialUrl  = location.href;
            const initialHtml = document.body.innerHTML.length;

            const timer = setTimeout(() => { obs.disconnect(); resolve(); }, timeoutMs);

            const obs = new MutationObserver(() => {
                const urlChanged     = location.href !== initialUrl;
                const contentChanged = Math.abs(document.body.innerHTML.length - initialHtml) > 500;

                if (urlChanged || contentChanged) {
                    clearTimeout(timer);
                    obs.disconnect();
                    // Дополнительная пауза для завершения рендеринга
                    setTimeout(resolve, 800);
                }
            });

            obs.observe(document.body, { childList: true, subtree: true });
        });
    }

    // ─────────────────────────────────────────────────────────────────────
    // Определение текущего шага многошаговой формы
    // ─────────────────────────────────────────────────────────────────────

    function detectCurrentStep() {
        // Индикаторы шага
        const stepIndicators = [
            { selector: '[aria-current="step"]',      attr: 'textContent' },
            { selector: '[class*="step--active"]',    attr: 'textContent' },
            { selector: '[class*="current-step"]',    attr: 'textContent' },
            { selector: '[role="progressbar"]',        attr: 'aria-valuenow' },
            { selector: 'li.active, .step.active',    attr: 'textContent' }
        ];

        for (const { selector, attr } of stepIndicators) {
            const el = document.querySelector(selector);
            if (!el) continue;
            const value = attr === 'textContent' ? el.textContent.trim() : el.getAttribute(attr);
            if (value) return { stepLabel: value, selector };
        }

        // Поиск по URL (#step2, ?step=2)
        const stepMatch = location.href.match(/step[=\-_/]?(\d+)/i);
        if (stepMatch) return { stepLabel: `Step ${stepMatch[1]}`, source: 'url' };

        return { stepLabel: null };
    }

    // ─────────────────────────────────────────────────────────────────────
    // Заполнение поля 2FA
    // ─────────────────────────────────────────────────────────────────────

    async function fill2FA(code) {
        const selectors2FA = [
            'input[autocomplete="one-time-code"]',
            'input[name*="otp" i]',
            'input[name*="2fa" i]',
            'input[name*="token" i]',
            'input[id*="otp" i]',
            'input[id*="code" i]',
            'input[placeholder*="code" i]',
            'input[placeholder*="код" i]'
        ];

        let field = null;
        for (const sel of selectors2FA) {
            field = document.querySelector(sel);
            if (field && isVisible(field)) break;
        }

        if (!field) return { success: false, message: 'Поле 2FA не найдено' };

        await fillInput(field, code);
        return { success: true, message: '2FA код введён' };
    }

    // ─────────────────────────────────────────────────────────────────────
    // Утилиты
    // ─────────────────────────────────────────────────────────────────────

    async function fillInput(el, value) {
        el.scrollIntoView({ block: 'center' });
        el.focus();
        const nativeSetter = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value')?.set;
        if (nativeSetter) nativeSetter.call(el, value); else el.value = value;
        el.dispatchEvent(new Event('input',  { bubbles: true }));
        el.dispatchEvent(new Event('change', { bubbles: true }));
        await sleep(80);
        el.blur();
    }

    function resolveElement(selector) {
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

    function isVisible(el) {
        const s = getComputedStyle(el);
        return s.display !== 'none' && s.visibility !== 'hidden' && s.opacity !== '0';
    }

    function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

})();

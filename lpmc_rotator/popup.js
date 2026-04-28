// popup.js
const dot        = document.getElementById('dot');
const statusText = document.getElementById('statusText');

// Проверяем статус через однократный WebSocket
const ws = new WebSocket('ws://localhost:12310');

ws.onopen = () => {
  dot.className = 'dot connected';
  statusText.textContent = 'Подключён к LPMC';
  ws.close();
};

ws.onerror = () => {
  dot.className = 'dot disconnected';
  statusText.textContent = 'LPMC не запущен';
};

ws.onclose = () => {};

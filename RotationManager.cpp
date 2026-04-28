#include "RotationManager.h"
#include "PasswordModel.h"
#include "FileManager.h"

#include <QJsonDocument>
#include <QJsonObject>
#include <QUuid>
#include <QRandomGenerator>
#include <QDebug>
#include <utility>   // std::as_const

// ─────────────────────────────────────────────────────────────────────────────
// RotationManager.cpp
// ─────────────────────────────────────────────────────────────────────────────

// ── Конструктор / деструктор ──────────────────────────────────────────────────

RotationManager::RotationManager(PasswordModel* model,
                                 FileManager*   fileManager,
                                 QObject*       parent)
    : QObject(parent)
    , m_model(model)
    , m_fileManager(fileManager)
    , m_server(new QWebSocketServer(
          QStringLiteral("LPMC"),
          QWebSocketServer::NonSecureMode,
          this))
{
    Q_ASSERT_X(m_model,       "RotationManager", "PasswordModel* must not be null");
    Q_ASSERT_X(m_fileManager, "RotationManager", "FileManager* must not be null");
    startServer();
}

RotationManager::~RotationManager()
{
    stopServer();
}

// ── WebSocket сервер ──────────────────────────────────────────────────────────

void RotationManager::startServer()
{
    if (m_server->isListening()) return;

    if (!m_server->listen(QHostAddress::LocalHost, WS_PORT)) {
        qWarning() << "[RotationManager] Failed to start WS server on port"
                   << WS_PORT << ":" << m_server->errorString();
        return;
    }

    connect(m_server, &QWebSocketServer::newConnection,
            this,     &RotationManager::onNewConnection);

    qInfo() << "[RotationManager] WebSocket server started on ws://localhost:" << WS_PORT;
    emit serverRunningChanged();
}

void RotationManager::stopServer()
{
    if (!m_server->isListening()) return;

    for (QWebSocket* client : std::as_const(m_clients)) {
        client->close();
    }
    m_clients.clear();

    m_server->close();
    qInfo() << "[RotationManager] WebSocket server stopped.";
    emit serverRunningChanged();
    emit connectedClientsChanged();
}

bool RotationManager::isServerRunning() const
{
    return m_server && m_server->isListening();
}

int RotationManager::connectedClients() const
{
    return m_clients.size();
}

// ── Управление клиентами ──────────────────────────────────────────────────────

void RotationManager::onNewConnection()
{
    QWebSocket* socket = m_server->nextPendingConnection();
    if (!socket) return;

    // Разрешаем только localhost (IPv4 и IPv6 loopback)
    const QHostAddress peer = socket->peerAddress();
    if (peer != QHostAddress::LocalHost &&
        peer != QHostAddress(QStringLiteral("::1")))
    {
        qWarning() << "[RotationManager] Rejected non-local connection from"
                   << peer.toString();
        socket->close();
        socket->deleteLater();
        return;
    }

    m_clients.append(socket);
    qInfo() << "[RotationManager] Extension connected. Total clients:" << m_clients.size();
    emit connectedClientsChanged();

    connect(socket, &QWebSocket::textMessageReceived,
            this,   &RotationManager::onTextMessageReceived);
    connect(socket, &QWebSocket::disconnected,
            this,   &RotationManager::onClientDisconnected);
}

void RotationManager::onClientDisconnected()
{
    QWebSocket* socket = qobject_cast<QWebSocket*>(sender());
    if (!socket) return;

    m_clients.removeAll(socket);
    socket->deleteLater();

    qInfo() << "[RotationManager] Extension disconnected. Remaining:" << m_clients.size();
    emit connectedClientsChanged();
}

// ── Входящие сообщения ────────────────────────────────────────────────────────

void RotationManager::onTextMessageReceived(const QString& message)
{
    QJsonParseError parseErr;
    QJsonDocument doc = QJsonDocument::fromJson(message.toUtf8(), &parseErr);

    if (parseErr.error != QJsonParseError::NoError || !doc.isObject()) {
        qWarning() << "[RotationManager] Invalid JSON received:"
                   << parseErr.errorString();
        return;
    }

    QJsonObject json = doc.object();
    const QString action = json[QStringLiteral("action")].toString();

    if (action == QStringLiteral("result")) {
        handleResult(json);
    } else if (action == QStringLiteral("error")) {
        handleError(json);
    } else if (action == QStringLiteral("ping")) {
        QJsonObject pong;
        pong[QStringLiteral("action")] = QStringLiteral("pong");
        broadcast(pong);
    } else {
        qWarning() << "[RotationManager] Unknown action received:" << action;
    }
}

// ── Запуск ротации (вызывается из QML) ───────────────────────────────────────

void RotationManager::rotate(const QString& entryId)
{
    // 1. Проверить, есть ли подключённое расширение
    if (m_clients.isEmpty()) {
        qWarning() << "[RotationManager] Cannot rotate — no extension connected.";
        emit noExtensionConnected();
        return;
    }

    // 2. Получить данные из модели
    const QString url    = m_model->getWebsite(entryId);
    const QString oldPwd = m_model->getPassword(entryId);

    if (url.isEmpty()) {
        qWarning() << "[RotationManager] Entry" << entryId
                   << "not found or has no URL.";
        emit rotationFailed(entryId,
                            QStringLiteral("URL не задан для этой записи"));
        return;
    }

    // 3. Сгенерировать новый пароль
    const QString newPwd = generatePassword();

    // 4. Создать задачу
    const QString taskId = QUuid::createUuid().toString(QUuid::WithoutBraces);

    RotationTask task;
    task.taskId      = taskId;
    task.entryId     = entryId;
    task.url         = url;
    task.newPassword = newPwd;

    // Таймер защиты от зависания задачи
    task.timeoutTimer = new QTimer(this);
    task.timeoutTimer->setSingleShot(true);
    task.timeoutTimer->setProperty("taskId", taskId);
    connect(task.timeoutTimer, &QTimer::timeout,
            this,              &RotationManager::onTaskTimeout);
    task.timeoutTimer->start(TASK_TIMEOUT_MS);

    m_tasks.insert(taskId, task);

    // 5. Отправить команду (пароли в лог НЕ пишем)
    QJsonObject cmd;
    cmd[QStringLiteral("action")]      = QStringLiteral("rotate_password");
    cmd[QStringLiteral("taskId")]      = taskId;
    cmd[QStringLiteral("entryId")]     = entryId;
    cmd[QStringLiteral("url")]         = url;
    cmd[QStringLiteral("oldPassword")] = oldPwd;
    cmd[QStringLiteral("newPassword")] = newPwd;

    // SECURITY: пароли в лог не пишем даже в debug-режиме
    qInfo() << "[RotationManager] Dispatching rotate task" << taskId
            << "| url:" << url
            << "| old=*** new=***";

    broadcast(cmd);
    emit rotationStarted(entryId);
}

// ── Обработка результата ──────────────────────────────────────────────────────

void RotationManager::handleResult(const QJsonObject& json)
{
    const QString taskId  = json[QStringLiteral("taskId")].toString();
    const QString status  = json[QStringLiteral("status")].toString();
    const QString message = json[QStringLiteral("message")].toString();

    RotationTask* task = findTask(taskId);
    if (!task) {
        qWarning() << "[RotationManager] Received result for unknown taskId:"
                   << taskId;
        return;
    }

    const QString entryId = task->entryId;
    const QString newPwd  = task->newPassword;

    if (status == QStringLiteral("success")) {
        qInfo() << "[RotationManager] Task" << taskId
                << "succeeded. Updating model for entry" << entryId;

        bool updated = m_model->updatePassword(entryId, newPwd);
        if (!updated) {
            qWarning() << "[RotationManager] updatePassword failed for entry"
                       << entryId;
            emit rotationFailed(entryId,
                                QStringLiteral("Ошибка обновления локальной модели"));
        } else {
            // Сохранить на диск
            m_fileManager->savePasswords(m_model->toJson());
            emit rotationSucceeded(entryId);
            qInfo() << "[RotationManager] Password saved to disk.";
        }
    } else {
        qWarning() << "[RotationManager] Task" << taskId
                   << "failed:" << message;
        emit rotationFailed(entryId, message);
    }

    finishTask(taskId);
}

void RotationManager::handleError(const QJsonObject& json)
{
    const QString taskId  = json[QStringLiteral("taskId")].toString();
    const QString message = json[QStringLiteral("message")].toString();

    RotationTask* task = findTask(taskId);
    if (!task) return;

    qWarning() << "[RotationManager] Error on task" << taskId << ":" << message;
    emit rotationFailed(task->entryId, message);
    finishTask(taskId);
}

// ── Таймаут ───────────────────────────────────────────────────────────────────

void RotationManager::onTaskTimeout()
{
    QTimer* timer = qobject_cast<QTimer*>(sender());
    if (!timer) return;

    const QString taskId = timer->property("taskId").toString();
    RotationTask* task   = findTask(taskId);
    if (!task) return;

    qWarning() << "[RotationManager] Task" << taskId << "timed out after"
               << TASK_TIMEOUT_MS / 1000 << "seconds.";

    emit rotationFailed(task->entryId,
                        QStringLiteral("Таймаут: браузер не ответил за 2 минуты"));
    finishTask(taskId);
}

// ── Внутренние утилиты ────────────────────────────────────────────────────────

void RotationManager::broadcast(const QJsonObject& obj)
{
    const QByteArray data =
        QJsonDocument(obj).toJson(QJsonDocument::Compact);

    for (QWebSocket* client : std::as_const(m_clients)) {
        if (client && client->isValid()) {
            client->sendTextMessage(QString::fromUtf8(data));
        }
    }
}

RotationTask* RotationManager::findTask(const QString& taskId)
{
    auto it = m_tasks.find(taskId);
    return (it != m_tasks.end()) ? &it.value() : nullptr;
}

void RotationManager::finishTask(const QString& taskId)
{
    auto it = m_tasks.find(taskId);
    if (it == m_tasks.end()) return;

    if (it->timeoutTimer) {
        it->timeoutTimer->stop();
        it->timeoutTimer->deleteLater();
        it->timeoutTimer = nullptr;
    }
    m_tasks.erase(it);
}

// ── Генератор паролей ─────────────────────────────────────────────────────────

QString RotationManager::generatePassword()
{
    // Символьные группы для обеспечения сложности
    static const QString lowers  = QStringLiteral("abcdefghijklmnopqrstuvwxyz");
    static const QString uppers  = QStringLiteral("ABCDEFGHIJKLMNOPQRSTUVWXYZ");
    static const QString digits  = QStringLiteral("0123456789");
    static const QString specials= QStringLiteral("!@#$%^&*()-_=+[]{}|;:,.<>?");
    static const QString charset = lowers + uppers + digits + specials;

    // Вспомогательная лямбда — случайный символ из строки (криптостойкий RNG)
    auto pick = [](const QString& group) -> QChar {
        const quint32 idx = QRandomGenerator::securelySeeded().bounded(
                                static_cast<quint32>(group.size()));
        return group.at(static_cast<int>(idx));
    };

    QString pwd;
    pwd.reserve(16);

    // Гарантируем по 1 символу из каждой группы
    pwd += pick(lowers);
    pwd += pick(uppers);
    pwd += pick(digits);
    pwd += pick(specials);

    // Добираем до 16 символов из полного charset
    while (pwd.size() < 16) {
        pwd += pick(charset);
    }

    // Fisher-Yates shuffle — перемешать, чтобы гарантированные символы
    // не стояли в предсказуемых позициях
    for (int i = pwd.size() - 1; i > 0; --i) {
        const int j = static_cast<int>(
            QRandomGenerator::securelySeeded().bounded(
                static_cast<quint32>(i + 1)));
        QChar tmp = pwd[i];
        pwd[i]    = pwd[j];
        pwd[j]    = tmp;
    }

    return pwd;
}

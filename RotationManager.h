#ifndef ROTATIONMANAGER_H
#define ROTATIONMANAGER_H

#include <QObject>
#include <QHash>
#include <QTimer>
#include <QHostAddress>
#include <QtWebSockets/QWebSocketServer>
#include <QtWebSockets/QWebSocket>

class PasswordModel;
class FileManager;

// ─────────────────────────────────────────────────────────────────────────────
// RotationTask — активная задача смены пароля
//
// Хранит все данные задачи до получения ответа от расширения.
// taskId ≠ entryId: один и тот же entry может ротироваться несколько
// раз, каждый раз с новым taskId.
// ─────────────────────────────────────────────────────────────────────────────
struct RotationTask {
    QString taskId;          // UUID задачи (ключ в m_tasks)
    QString entryId;         // UUID записи в PasswordModel
    QString url;             // URL страницы смены пароля
    QString newPassword;     // сгенерированный пароль (ещё не применён)
    QTimer* timeoutTimer = nullptr;
};

// ─────────────────────────────────────────────────────────────────────────────
// RotationManager — оркестратор автоматической смены паролей
//
// Архитектура:
//   QML → rotate(entryId) → генерируем newPwd → broadcast → Chrome Extension
//   Chrome Extension → WebSocket → handleResult() → updatePassword() → save
//
// Безопасность:
//   • Сервер слушает только localhost (127.0.0.1)
//   • Нелокальные соединения отклоняются немедленно
//   • Пароли никогда не попадают в qDebug/qInfo
// ─────────────────────────────────────────────────────────────────────────────
class RotationManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool serverRunning    READ isServerRunning    NOTIFY serverRunningChanged)
    Q_PROPERTY(int  connectedClients READ connectedClients   NOTIFY connectedClientsChanged)

public:
    explicit RotationManager(PasswordModel* model,
                             FileManager*   fileManager,
                             QObject*       parent = nullptr);
    ~RotationManager() override;

    // ── Свойства (читаются из QML) ───────────────────────────────────────
    bool isServerRunning()  const;
    int  connectedClients() const;

    // ── Константы протокола ──────────────────────────────────────────────
    static constexpr quint16 WS_PORT         = 12310;
    static constexpr int     TASK_TIMEOUT_MS = 120'000; // 2 минуты

public slots:
    // ── Публичный API (вызывается из QML) ────────────────────────────────

    // Запустить ротацию пароля для записи с данным entryId
    Q_INVOKABLE void rotate(const QString& entryId);

    // Управление WebSocket сервером
    Q_INVOKABLE void startServer();
    Q_INVOKABLE void stopServer();

signals:
    void serverRunningChanged();
    void connectedClientsChanged();

    // Уведомления для QML — UI реагирует на эти сигналы
    void rotationStarted(const QString& entryId);
    void rotationSucceeded(const QString& entryId);
    void rotationFailed(const QString& entryId, const QString& reason);
    void noExtensionConnected();  // расширение не подключено к WS серверу

private slots:
    void onNewConnection();
    void onClientDisconnected();
    void onTextMessageReceived(const QString& message);
    void onTaskTimeout();

private:
    // Генерация криптографически случайного пароля (16 символов)
    static QString generatePassword();

    // Отправить JSON-сообщение всем подключённым расширениям
    void broadcast(const QJsonObject& obj);

    // Найти задачу по taskId (nullptr если не найдена)
    RotationTask* findTask(const QString& taskId);

    // Завершить задачу: остановить таймер, удалить из m_tasks
    void finishTask(const QString& taskId);

    // Обработчики входящих сообщений от расширения
    void handleResult(const QJsonObject& json);
    void handleError(const QJsonObject& json);

    PasswordModel*     m_model;
    FileManager*       m_fileManager;
    QWebSocketServer*  m_server;
    QList<QWebSocket*> m_clients;

    // Активные задачи: taskId → RotationTask
    QHash<QString, RotationTask> m_tasks;
};

#endif // ROTATIONMANAGER_H

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

struct RotationTask {
    QString taskId;          
    QString entryId;         
    QString url;             
    QString newPassword;     
    QTimer* timeoutTimer = nullptr;
};

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
    void noExtensionConnected();
    // Эмитируется когда автоматический маппинг не удался — UI должен запросить у пользователя
    void fieldMappingRequired(const QString& taskId, const QString& entryId, const QJsonObject& pageData);

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
    void handleFieldMappingRequest(const QJsonObject& json);  // протокол v2

    PasswordModel*     m_model;
    FileManager*       m_fileManager;
    QWebSocketServer*  m_server;
    QList<QWebSocket*> m_clients;

    // Активные задачи: taskId → RotationTask
    QHash<QString, RotationTask> m_tasks;
};

#endif // ROTATIONMANAGER_H

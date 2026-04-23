// === password_rotator.h ===
#ifndef PASSWORD_ROTATOR_H
#define PASSWORD_ROTATOR_H

#include <QObject>
#include <QQueue>

#include "database_extensions.h"
#include "api_client.h"

class PasswordRotator : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool busy         READ busy         NOTIFY busyChanged)
    Q_PROPERTY(int  pendingCount READ pendingCount NOTIFY pendingCountChanged)

public:
    explicit PasswordRotator(DatabaseExtensions* db,
                             ApiClient*          api,
                             QObject*            parent = nullptr);

    bool busy()         const { return m_busy; }
    int  pendingCount() const { return m_queue.size(); }

    // Вызывается из QML
    Q_INVOKABLE void rotatePassword(int            accountId,
                                    bool           useGeneratedPassword = true,
                                    const QString& customPassword = QString());

    Q_INVOKABLE void cancelAll();

signals:
    void rotationStarted   (int accountId, const QString& serviceName);
    void rotationSucceeded (int accountId, const QString& newPassword);
    void rotationFailed    (int accountId, const QString& errorMessage, int httpStatusCode);
    void busyChanged();
    void pendingCountChanged();

private slots:
    void onApiSucceeded();
    void onApiFailed(const QString& errorMessage, int httpStatusCode);
    void processQueue();

private:
    struct RotationTask {
        int     accountId;
        QString newPassword;   // уже сгенерированный
    };

    static QString generatePassword();
    void           setBusy(bool v);
    void           startTask(const RotationTask& task);
    void           wipeTask();

    DatabaseExtensions* m_db  = nullptr;
    ApiClient*          m_api = nullptr;

    QQueue<RotationTask> m_queue;
    RotationTask         m_current;
    bool                 m_busy = false;

    // Временное хранение для слотов
    QString m_pendingNewPassword;
    int     m_pendingAccountId = 0;
};

#endif // PASSWORD_ROTATOR_H

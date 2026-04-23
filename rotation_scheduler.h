// === rotation_scheduler.h ===
#ifndef ROTATION_SCHEDULER_H
#define ROTATION_SCHEDULER_H

#include <QObject>
#include <QTimer>
#include <QHash>
#include <QDateTime>
#include <QList>

#include "database_extensions.h"
#include "password_rotator.h"

class RotationScheduler : public QObject
{
    Q_OBJECT

public:
    explicit RotationScheduler(DatabaseExtensions* db,
                               PasswordRotator*    rotator,
                               QObject*            parent = nullptr);

    void start();
    void stop();

    Q_INVOKABLE void checkNow();
    Q_INVOKABLE void postponeAccount(int accountId, int days);
    Q_INVOKABLE void disableForAccount(int accountId);

signals:
    void dueAccountsFound(const QList<int>& accountIds);

private slots:
    void onDailyCheck();

private:
    bool shouldShowForAccount(int accountId) const;
    void markShownForAccount(int accountId);

    DatabaseExtensions* m_db      = nullptr;
    PasswordRotator*    m_rotator = nullptr;
    QTimer*             m_timer   = nullptr;

    // Защита от спама: время последнего показа диалога для каждого аккаунта
    QHash<int, QDateTime> m_lastShown;

    static constexpr int k_dailyIntervalMs  = 24 * 60 * 60 * 1000;
    static constexpr int k_suppressSecs     = 6 * 60 * 60;  // 6 часов
};

#endif // ROTATION_SCHEDULER_H

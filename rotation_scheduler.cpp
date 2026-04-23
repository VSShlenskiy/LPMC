// === rotation_scheduler.cpp ===
#include "rotation_scheduler.h"

#include <QDate>

RotationScheduler::RotationScheduler(DatabaseExtensions* db,
                                     PasswordRotator*    rotator,
                                     QObject*            parent)
    : QObject(parent), m_db(db), m_rotator(rotator)
{
    m_timer = new QTimer(this);
    m_timer->setInterval(k_dailyIntervalMs);
    connect(m_timer, &QTimer::timeout, this, &RotationScheduler::onDailyCheck);
}

void RotationScheduler::start()
{
    m_timer->start();
    // Проверить сразу при старте
    QMetaObject::invokeMethod(this, "checkNow", Qt::QueuedConnection);
}

void RotationScheduler::stop()
{
    m_timer->stop();
}

void RotationScheduler::checkNow()
{
    const QVector<int> due = m_db->getAccountsDueForRotation(QDate::currentDate());

    QList<int> toShow;
    for (int id : due) {
        if (shouldShowForAccount(id)) {
            toShow.append(id);
            markShownForAccount(id);
        }
    }

    if (!toShow.isEmpty())
        emit dueAccountsFound(toShow);
}

void RotationScheduler::postponeAccount(int accountId, int days)
{
    m_db->postponeRotation(accountId, QDate::currentDate().addDays(days));
}

void RotationScheduler::disableForAccount(int accountId)
{
    m_db->setAutoRotationEnabled(accountId, false, 0);
}

void RotationScheduler::onDailyCheck()
{
    checkNow();
}

bool RotationScheduler::shouldShowForAccount(int accountId) const
{
    auto it = m_lastShown.find(accountId);
    if (it == m_lastShown.end())
        return true;
    return it.value().secsTo(QDateTime::currentDateTime()) >= k_suppressSecs;
}

void RotationScheduler::markShownForAccount(int accountId)
{
    m_lastShown.insert(accountId, QDateTime::currentDateTime());
}

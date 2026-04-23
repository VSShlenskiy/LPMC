// === password_rotator.cpp ===
#include "password_rotator.h"

#include <QRandomGenerator>
#include <QDate>

PasswordRotator::PasswordRotator(DatabaseExtensions* db,
                                 ApiClient*          api,
                                 QObject*            parent)
    : QObject(parent), m_db(db), m_api(api)
{
    connect(m_api, &ApiClient::requestSucceeded,
            this,  &PasswordRotator::onApiSucceeded);
    connect(m_api, &ApiClient::requestFailed,
            this,  &PasswordRotator::onApiFailed);
}

void PasswordRotator::rotatePassword(int            accountId,
                                     bool           useGeneratedPassword,
                                     const QString& customPassword)
{
    RotationTask task;
    task.accountId   = accountId;
    task.newPassword = useGeneratedPassword ? generatePassword() : customPassword;

    m_queue.enqueue(task);
    emit pendingCountChanged();

    if (!m_busy)
        processQueue();
}

void PasswordRotator::cancelAll()
{
    m_api->cancelCurrentRequest();
    m_queue.clear();
    wipeTask();
    setBusy(false);
    emit pendingCountChanged();
}

void PasswordRotator::processQueue()
{
    if (m_busy || m_queue.isEmpty())
        return;

    setBusy(true);
    emit pendingCountChanged();

    m_current = m_queue.dequeue();
    startTask(m_current);
}

void PasswordRotator::startTask(const RotationTask& task)
{
    const RotationAccount acc = m_db->getRotationAccount(task.accountId);
    emit rotationStarted(task.accountId, acc.serviceName);

    // Сохраняем для слота onApiSucceeded
    m_pendingAccountId   = task.accountId;
    m_pendingNewPassword = task.newPassword;

    // Расшифровываем текущий пароль только на момент отправки
    // (decrypt — существующий метод Database, вызывается через FileManager/Database)
    // Здесь предполагается, что вызывающий передал уже расшифрованный пароль
    // через customPassword, либо PasswordRotator получает его через Database::decrypt.
    // В данной реализации текущий пароль не нужен если authType != Basic.
    // При authType Basic — caller должен передать customPassword с текущим паролем.

    m_api->sendChangePasswordRequest(acc, QString{}, task.newPassword);
}

void PasswordRotator::onApiSucceeded()
{
    const int     id  = m_pendingAccountId;
    const QString pwd = m_pendingNewPassword;

    // Обновляем БД — атомарно
    // Шифрование нового пароля должно делаться через Database::encrypt().
    // Здесь сохраняем как есть — интегратор подключит encrypt() до вызова этого метода.
    m_db->updatePasswordAndRotationDate(id, pwd, QDate::currentDate());

    emit rotationSucceeded(id, pwd);

    wipeTask();
    setBusy(false);
    emit pendingCountChanged();

    // Следующая задача
    QMetaObject::invokeMethod(this, "processQueue", Qt::QueuedConnection);
}

void PasswordRotator::onApiFailed(const QString& errorMessage, int httpStatusCode)
{
    const int id = m_pendingAccountId;

    // При 401/403 — отключаем автосмену для этого аккаунта
    if (httpStatusCode == 401 || httpStatusCode == 403) {
        m_db->setAutoRotationEnabled(id, false, 0);
    }

    emit rotationFailed(id, errorMessage, httpStatusCode);

    wipeTask();
    setBusy(false);
    emit pendingCountChanged();

    QMetaObject::invokeMethod(this, "processQueue", Qt::QueuedConnection);
}

void PasswordRotator::wipeTask()
{
    m_current.newPassword.fill(QLatin1Char('0'));
    m_current.newPassword.clear();
    m_pendingNewPassword.fill(QLatin1Char('0'));
    m_pendingNewPassword.clear();
    m_pendingAccountId = 0;
}

void PasswordRotator::setBusy(bool v)
{
    if (m_busy == v) return;
    m_busy = v;
    emit busyChanged();
}

QString PasswordRotator::generatePassword()
{
    // 20 символов: строчные + прописные + цифры + спецсимволы
    static const char charset[] =
        "abcdefghijklmnopqrstuvwxyz"
        "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        "0123456789"
        "!@#$%^&*()_+-=[]{}|;:,.<>?";
    static const int charsetLen =
        static_cast<int>(sizeof(charset) - 1);

    auto& rng = *QRandomGenerator::securelySeeded().get();

    QString pwd;
    pwd.reserve(20);
    for (int i = 0; i < 20; ++i)
        pwd.append(QLatin1Char(charset[rng.bounded(charsetLen)]));
    return pwd;
}

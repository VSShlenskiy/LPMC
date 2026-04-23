// === api_client.h ===
#ifndef API_CLIENT_H
#define API_CLIENT_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QTimer>

#include "rotation_account.h"

class ApiClient : public QObject
{
    Q_OBJECT

public:
    explicit ApiClient(QObject* parent = nullptr);

    // Отправить запрос на смену пароля.
    // currentPassword и newPassword никогда не логируются.
    void sendChangePasswordRequest(const RotationAccount& account,
                                   const QString& currentPassword,
                                   const QString& newPassword);

    void cancelCurrentRequest();

signals:
    void requestSucceeded();
    void requestFailed(const QString& errorMessage, int httpStatusCode);
    void requestProgress(int percent);

private slots:
    void onReplyFinished();
    void onUploadProgress(qint64 sent, qint64 total);
    void onSslErrors(const QList<QSslError>& errors);
    void onTimeout();
    void onRetry();

private:
    void doSend();
    void scheduleRetry();
    void cleanup();

    QNetworkAccessManager* m_nam     = nullptr;
    QNetworkReply*         m_reply   = nullptr;
    QTimer*                m_timeout = nullptr;
    QTimer*                m_retry   = nullptr;

    // Параметры текущего запроса — хранятся только на время запроса
    RotationAccount m_account;
    QString         m_currentPassword;
    QString         m_newPassword;

    int m_retryCount    = 0;
    static constexpr int k_maxRetries  = 3;
    static constexpr int k_timeoutMs   = 30'000;
    static constexpr int k_retryBaseMs = 2'000;
};

#endif // API_CLIENT_H

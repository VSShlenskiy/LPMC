// === api_client.cpp ===
#include "api_client.h"

#include <QNetworkRequest>
#include <QJsonObject>
#include <QJsonDocument>
#include <QSslConfiguration>
#include <QByteArray>
#include <QDebug>

ApiClient::ApiClient(QObject* parent) : QObject(parent)
{
    m_nam = new QNetworkAccessManager(this);

    m_timeout = new QTimer(this);
    m_timeout->setSingleShot(true);
    m_timeout->setInterval(k_timeoutMs);
    connect(m_timeout, &QTimer::timeout, this, &ApiClient::onTimeout);

    m_retry = new QTimer(this);
    m_retry->setSingleShot(true);
    connect(m_retry, &QTimer::timeout, this, &ApiClient::onRetry);
}

void ApiClient::sendChangePasswordRequest(const RotationAccount& account,
                                          const QString& currentPassword,
                                          const QString& newPassword)
{
    cancelCurrentRequest();

    // Проверяем HTTPS — никогда не отправляем пароли по HTTP
    if (!account.apiEndpoint.startsWith(QStringLiteral("https://"), Qt::CaseInsensitive)) {
        emit requestFailed(QStringLiteral("Only HTTPS endpoints are allowed"), 0);
        return;
    }

    m_account         = account;
    m_currentPassword = currentPassword;
    m_newPassword     = newPassword;
    m_retryCount      = 0;

    doSend();
}

void ApiClient::doSend()
{
    QUrl url(m_account.apiEndpoint);
    if (!url.isValid()) {
        emit requestFailed(QStringLiteral("Invalid API endpoint URL"), 0);
        return;
    }

    QNetworkRequest request(url);

    // SSL — строгая проверка, ничего не игнорируем
    QSslConfiguration ssl = QSslConfiguration::defaultConfiguration();
    ssl.setPeerVerifyMode(QSslSocket::VerifyPeer);
    request.setSslConfiguration(ssl);

    request.setHeader(QNetworkRequest::ContentTypeHeader,
                      QStringLiteral("application/json"));

    // Авторизация
    if (m_account.authType == QStringLiteral("Bearer")) {
        // authTokenEncrypted хранится зашифрованным — расшифровка на стороне вызывающего
        request.setRawHeader("Authorization",
            QStringLiteral("Bearer %1").arg(m_account.authTokenEncrypted).toUtf8());
    } else if (m_account.authType == QStringLiteral("Basic")) {
        const QByteArray creds =
            (m_account.login + QStringLiteral(":") + m_currentPassword).toUtf8().toBase64();
        request.setRawHeader("Authorization",
            QStringLiteral("Basic ").toUtf8() + creds);
    } else if (m_account.authType == QStringLiteral("Header")) {
        request.setRawHeader("Authorization", m_account.authTokenEncrypted.toUtf8());
    }

    // Дополнительные заголовки
    for (auto it = m_account.customHeaders.cbegin();
         it != m_account.customHeaders.cend(); ++it) {
        request.setRawHeader(it.key().toUtf8(), it.value().toUtf8());
    }

    // Тело запроса — поле нового пароля берётся из настроек аккаунта
    QJsonObject body;
    body[m_account.newPasswordFieldName] = m_newPassword;
    // Пароли НЕ логируем даже в debug
    const QByteArray payload = QJsonDocument(body).toJson(QJsonDocument::Compact);

    if (m_account.apiMethod == QStringLiteral("PUT")) {
        m_reply = m_nam->put(request, payload);
    } else {
        m_reply = m_nam->post(request, payload);
    }

    connect(m_reply, &QNetworkReply::finished,
            this, &ApiClient::onReplyFinished);
    connect(m_reply, &QNetworkReply::uploadProgress,
            this, &ApiClient::onUploadProgress);
    connect(m_reply, &QNetworkReply::sslErrors,
            this, &ApiClient::onSslErrors);

    m_timeout->start();
}

void ApiClient::cancelCurrentRequest()
{
    m_timeout->stop();
    m_retry->stop();

    if (m_reply) {
        m_reply->abort();
        m_reply->deleteLater();
        m_reply = nullptr;
    }

    // Затираем пароли в памяти
    m_currentPassword.fill(QLatin1Char('0'));
    m_currentPassword.clear();
    m_newPassword.fill(QLatin1Char('0'));
    m_newPassword.clear();
}

void ApiClient::onReplyFinished()
{
    m_timeout->stop();

    if (!m_reply) return;

    const int httpStatus = m_reply->attribute(
        QNetworkRequest::HttpStatusCodeAttribute).toInt();
    const QNetworkReply::NetworkError netError = m_reply->error();

    m_reply->deleteLater();
    m_reply = nullptr;

    // Успех: 2xx
    if (netError == QNetworkReply::NoError ||
        (httpStatus >= 200 && httpStatus < 300)) {
        cleanup();
        emit requestSucceeded();
        return;
    }

    // Ошибки, при которых НЕ нужно повторять
    if (httpStatus == 401 || httpStatus == 403 ||
        httpStatus == 404 || httpStatus == 400) {
        const QString msg = QStringLiteral("HTTP %1").arg(httpStatus);
        cleanup();
        emit requestFailed(msg, httpStatus);
        return;
    }

    // 429 — слишком много запросов
    if (httpStatus == 429) {
        cleanup();
        emit requestFailed(QStringLiteral("Too many requests (429)"), 429);
        return;
    }

    // 5xx — повторяем
    if (httpStatus >= 500 && m_retryCount < k_maxRetries) {
        scheduleRetry();
        return;
    }

    // Сетевая ошибка — повторяем
    if (netError != QNetworkReply::NoError && m_retryCount < k_maxRetries) {
        scheduleRetry();
        return;
    }

    const QString msg = QStringLiteral("Network error %1 (HTTP %2)")
                        .arg(netError).arg(httpStatus);
    cleanup();
    emit requestFailed(msg, httpStatus);
}

void ApiClient::onUploadProgress(qint64 sent, qint64 total)
{
    if (total > 0)
        emit requestProgress(static_cast<int>(sent * 100 / total));
}

void ApiClient::onSslErrors(const QList<QSslError>& errors)
{
    // Никогда не игнорируем SSL ошибки
    QString details;
    for (const QSslError& e : errors)
        details += e.errorString() + QStringLiteral("; ");

    cancelCurrentRequest();
    emit requestFailed(QStringLiteral("SSL error: ") + details, 0);
}

void ApiClient::onTimeout()
{
    if (m_reply) {
        m_reply->abort();
        m_reply->deleteLater();
        m_reply = nullptr;
    }

    if (m_retryCount < 1) {   // При таймауте — одна попытка
        scheduleRetry();
    } else {
        cleanup();
        emit requestFailed(QStringLiteral("Request timed out"), 0);
    }
}

void ApiClient::onRetry()
{
    ++m_retryCount;
    doSend();
}

void ApiClient::scheduleRetry()
{
    // Exponential backoff: 2s, 4s, 8s
    const int delayMs = k_retryBaseMs * (1 << m_retryCount);
    m_retry->setInterval(delayMs);
    m_retry->start();
}

void ApiClient::cleanup()
{
    m_retryCount = 0;
    m_currentPassword.fill(QLatin1Char('0'));
    m_currentPassword.clear();
    m_newPassword.fill(QLatin1Char('0'));
    m_newPassword.clear();
    m_account = RotationAccount{};
}

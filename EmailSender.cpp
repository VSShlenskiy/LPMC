#include "EmailSender.h"

#include <QSslSocket>
#include <QTcpSocket>
#include <QThread>
#include <QDateTime>
#include <QDebug>
#include <QCoreApplication>

// ── Static members ────────────────────────────────────────────────────────────
QMap<QString, SmtpConfig> EmailSender::s_smtpDefaults;
bool EmailSender::s_defaultsInit = false;

// ── Constructor ───────────────────────────────────────────────────────────────
EmailSender::EmailSender(QObject* parent) : QObject(parent)
{
    initDefaults();
    // Default empty config
    m_config = {"", 465, true};
}

void EmailSender::initDefaults()
{
    if (s_defaultsInit) return;
    s_defaultsInit = true;

    s_smtpDefaults = {
        {"gmail.com",       {"smtp.gmail.com",            465, true }},
        {"yandex.ru",       {"smtp.yandex.ru",            465, true }},
        {"yandex.com",      {"smtp.yandex.com",           465, true }},
        {"mail.ru",         {"smtp.mail.ru",              465, true }},
        {"inbox.ru",        {"smtp.mail.ru",              465, true }},
        {"list.ru",         {"smtp.mail.ru",              465, true }},
        {"bk.ru",           {"smtp.mail.ru",              465, true }},
        {"outlook.com",     {"smtp-mail.outlook.com",     587, false}},
        {"hotmail.com",     {"smtp-mail.outlook.com",     587, false}},
        {"live.com",        {"smtp-mail.outlook.com",     587, false}},
        {"icloud.com",      {"smtp.mail.me.com",          587, false}},
        {"yahoo.com",       {"smtp.mail.yahoo.com",       465, true }},
        {"rambler.ru",      {"smtp.rambler.ru",           465, true }}
    };
}

// ── Public API ────────────────────────────────────────────────────────────────
bool EmailSender::detectSmtp(const QString& email)
{
    QString domain = domainOf(email).toLower();
    if (s_smtpDefaults.contains(domain)) {
        m_config = s_smtpDefaults[domain];
        emit smtpDetected(m_config.host, m_config.port);
        return true;
    }
    return false;
}

void EmailSender::setManualSmtp(const QString& host, int port, bool ssl)
{
    m_config = {host, port, ssl};
}

void EmailSender::setSenderCredentials(const QString& senderEmail,
                                        const QString& appPassword)
{
    m_senderEmail = senderEmail;
    m_appPassword = appPassword;
}

void EmailSender::sendPasswordRecoveryEmail(const QString& toEmail,
                                             const QString& masterPassword)
{
    // Auto-detect if sender not set or domain differs
    if (m_config.host.isEmpty()) {
        if (!detectSmtp(m_senderEmail)) {
            emit emailFailed("SMTP server not configured. Please set it in Settings.");
            return;
        }
    }

    QString subject = "LPMC – Master Password Recovery";
    QString body =
        "Hello,\n\n"
        "A master-password recovery was requested for your LPMC vault.\n\n"
        "Your master password is:\n\n"
        "    " + masterPassword + "\n\n"
        "⚠  IMPORTANT: Please delete this email immediately after reading it.\n"
        "   Anyone with access to this email can unlock your vault.\n\n"
        "If you did not request this, someone may have access to your device.\n"
        "Consider changing your master password immediately.\n\n"
        "– LPMC Password Manager";

    doSend(toEmail, subject, body);
}

void EmailSender::sendTestEmail(const QString& toEmail)
{
    if (m_config.host.isEmpty()) {
        emit emailFailed("SMTP server not configured.");
        return;
    }

    QString subject = "LPMC – Test Email";
    QString body =
        "Hello,\n\n"
        "This is a test email from LPMC Password Manager.\n"
        "Your email recovery settings are working correctly.\n\n"
        "– LPMC Password Manager";

    doSend(toEmail, subject, body);
}

// ── Static helpers ────────────────────────────────────────────────────────────
QString EmailSender::domainOf(const QString& email)
{
    int at = email.lastIndexOf('@');
    if (at < 0) return QString();
    return email.mid(at + 1).toLower();
}

QString EmailSender::appPasswordUrl(const QString& domain)
{
    static const QMap<QString, QString> urls = {
        {"gmail.com",   "https://myaccount.google.com/apppasswords"},
        {"yandex.ru",   "https://id.yandex.ru/security/app-passwords"},
        {"yandex.com",  "https://id.yandex.ru/security/app-passwords"},
        {"mail.ru",     "https://account.mail.ru/user/2-step-auth/passwords"},
        {"inbox.ru",    "https://account.mail.ru/user/2-step-auth/passwords"},
        {"list.ru",     "https://account.mail.ru/user/2-step-auth/passwords"},
        {"bk.ru",       "https://account.mail.ru/user/2-step-auth/passwords"},
        {"outlook.com", "https://account.microsoft.com/security"},
        {"hotmail.com", "https://account.microsoft.com/security"},
        {"live.com",    "https://account.microsoft.com/security"},
        {"yahoo.com",   "https://login.yahoo.com/account/security"},
        {"icloud.com",  "https://appleid.apple.com/account/manage"},
        {"rambler.ru",  "https://id.rambler.ru/account/profile"}
    };
    return urls.value(domain.toLower(),
                      "https://www.google.com/search?q=" + domain + "+app+password+smtp");
}

// ── Private: dispatch ─────────────────────────────────────────────────────────
void EmailSender::doSend(const QString& toEmail,
                          const QString& subject,
                          const QString& body)
{
    if (m_senderEmail.isEmpty() || m_appPassword.isEmpty()) {
        emit emailFailed("Sender email or app-password not set.");
        return;
    }
    if (m_config.host.isEmpty()) {
        emit emailFailed("SMTP host not configured.");
        return;
    }

    QString err;
    bool ok = m_config.ssl
              ? sendViaSsl(toEmail, subject, body, err)
              : sendViaStartTls(toEmail, subject, body, err);

    if (ok)
        emit emailSent();
    else
        emit emailFailed(err);
}

// ── Base64 / MIME helpers ─────────────────────────────────────────────────────
QByteArray EmailSender::base64(const QByteArray& data)
{
    return data.toBase64();
}

QString EmailSender::mimeEncode(const QString& text)
{
    // =?UTF-8?B?...?= encoding for non-ASCII subjects
    return "=?UTF-8?B?" + QString::fromLatin1(base64(text.toUtf8())) + "?=";
}

// ── Build raw RFC 2822 message ────────────────────────────────────────────────
static QString buildRawMessage(const QString& from,
                                const QString& to,
                                const QString& subject,
                                const QString& body)
{
    QString date = QDateTime::currentDateTimeUtc().toString("ddd, dd MMM yyyy HH:mm:ss +0000");
    QString msg;
    msg += "Date: " + date + "\r\n";
    msg += "From: LPMC <" + from + ">\r\n";
    msg += "To: " + to + "\r\n";
    msg += "Subject: " + subject + "\r\n";
    msg += "MIME-Version: 1.0\r\n";
    msg += "Content-Type: text/plain; charset=UTF-8\r\n";
    msg += "Content-Transfer-Encoding: base64\r\n";
    msg += "\r\n";
    msg += QString::fromLatin1(body.toUtf8().toBase64()) + "\r\n";
    return msg;
}

// ── Read/send helpers ─────────────────────────────────────────────────────────
bool EmailSender::readResponse(QIODevice* sock, int expectedCode, QString& err)
{
    QByteArray resp;
    // wait up to 10 s for data
    for (int i = 0; i < 200; ++i) {
        if (sock->bytesAvailable() > 0) {
            resp += sock->readAll();
            // multi-line response ends when last line has "NNN "
            if (resp.contains(QByteArray::number(expectedCode) + " ") ||
                resp.contains(QByteArray::number(expectedCode) + "\r"))
                break;
            if (resp.size() > 3) {
                int code = resp.left(3).toInt();
                if (code > 0 && code != expectedCode) break;
            }
        }
        QThread::msleep(50);
        QCoreApplication::processEvents();
    }
    int code = resp.left(3).toInt();
    if (code != expectedCode) {
        err = QString("SMTP error %1: %2").arg(code).arg(QString::fromLatin1(resp).trimmed());
        return false;
    }
    return true;
}

bool EmailSender::sendCommand(QIODevice* sock,
                               const QByteArray& cmd,
                               int expected,
                               QString& err)
{
    sock->write(cmd + "\r\n");
    sock->waitForBytesWritten(5000);
    return readResponse(sock, expected, err);
}

// ── SSL / TLS (port 465) ──────────────────────────────────────────────────────
bool EmailSender::sendViaSsl(const QString& toEmail,
                              const QString& subject,
                              const QString& body,
                              QString& err)
{
    QSslSocket sock;
    sock.connectToHostEncrypted(m_config.host, static_cast<quint16>(m_config.port));
    if (!sock.waitForEncrypted(15000)) {
        err = "SSL handshake failed: " + sock.errorString();
        return false;
    }
    if (!readResponse(&sock, 220, err)) return false;

    QString rawMsg = buildRawMessage(m_senderEmail, toEmail, subject, body);
    return smtpDialog(&sock, m_senderEmail, toEmail, rawMsg, err);
}

// ── STARTTLS (port 587) ───────────────────────────────────────────────────────
bool EmailSender::sendViaStartTls(const QString& toEmail,
                                   const QString& subject,
                                   const QString& body,
                                   QString& err)
{
    QSslSocket sock;
    sock.connectToHost(m_config.host, static_cast<quint16>(m_config.port));
    if (!sock.waitForConnected(10000)) {
        err = "Connection failed: " + sock.errorString();
        return false;
    }
    if (!readResponse(&sock, 220, err)) return false;

    // EHLO
    if (!sendCommand(&sock,
                     "EHLO lpmc-client",
                     250, err)) return false;

    // STARTTLS
    if (!sendCommand(&sock, "STARTTLS", 220, err)) return false;

    sock.startClientEncryption();
    if (!sock.waitForEncrypted(10000)) {
        err = "STARTTLS upgrade failed: " + sock.errorString();
        return false;
    }

    QString rawMsg = buildRawMessage(m_senderEmail, toEmail, subject, body);
    return smtpDialog(&sock, m_senderEmail, toEmail, rawMsg, err);
}

// ── Common SMTP dialog (after TLS is up) ─────────────────────────────────────
bool EmailSender::smtpDialog(QIODevice* sock,
                               const QString& from,
                               const QString& to,
                               const QString& rawMsg,
                               QString& err)
{
    if (!sendCommand(sock, "EHLO lpmc-client", 250, err)) return false;

    // AUTH LOGIN
    if (!sendCommand(sock, "AUTH LOGIN", 334, err)) return false;
    if (!sendCommand(sock, base64(from.toUtf8()), 334, err)) return false;
    if (!sendCommand(sock, base64(m_appPassword.toUtf8()), 235, err)) return false;

    if (!sendCommand(sock, "MAIL FROM:<" + from.toLatin1() + ">", 250, err)) return false;
    if (!sendCommand(sock, "RCPT TO:<"   + to.toLatin1()   + ">", 250, err)) return false;
    if (!sendCommand(sock, "DATA",                                 354, err)) return false;

    // Send message body terminated by ".\r\n"
    QByteArray msgBytes = rawMsg.toUtf8() + "\r\n.\r\n";
    sock->write(msgBytes);
    sock->waitForBytesWritten(10000);
    if (!readResponse(sock, 250, err)) return false;

    sendCommand(sock, "QUIT", 221, err); // best-effort
    return true;
}

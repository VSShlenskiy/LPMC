#ifndef EMAILSENDER_H
#define EMAILSENDER_H

#include <QObject>
#include <QString>
#include <QMap>
#include <QSslSocket>
#include <QTcpSocket>
#include <QTimer>

struct SmtpConfig {
    QString host;
    int     port;
    bool    ssl;   // true = implicit SSL/TLS on connect (port 465)
                   // false = plain + STARTTLS (port 587)
};

class EmailSender : public QObject
{
    Q_OBJECT

public:
    explicit EmailSender(QObject* parent = nullptr);

    // Detect SMTP config from email domain; returns true if found in built-in DB
    Q_INVOKABLE bool detectSmtp(const QString& email);

    // Returns detected/stored host
    Q_INVOKABLE QString smtpHost() const { return m_config.host; }
    Q_INVOKABLE int     smtpPort() const { return m_config.port; }
    Q_INVOKABLE bool    smtpSsl()  const { return m_config.ssl;  }

    // Set manual server (when domain not found in DB)
    Q_INVOKABLE void setManualSmtp(const QString& host, int port, bool ssl);

    // Store sender credentials for the session (not persisted here — use FileManager)
    Q_INVOKABLE void setSenderCredentials(const QString& senderEmail,
                                          const QString& appPassword);

    // Send master-password recovery email (async)
    Q_INVOKABLE void sendPasswordRecoveryEmail(const QString& toEmail,
                                               const QString& masterPassword);

    // Send a test email to verify settings
    Q_INVOKABLE void sendTestEmail(const QString& toEmail);

    // Utility: extract domain from email
    Q_INVOKABLE static QString domainOf(const QString& email);

    // Instruction URL for obtaining an app-password for a given domain
    Q_INVOKABLE static QString appPasswordUrl(const QString& domain);

signals:
    void emailSent();
    void emailFailed(const QString& error);
    void smtpDetected(const QString& host, int port);

private:
    SmtpConfig m_config;
    QString    m_senderEmail;
    QString    m_appPassword;

    static QMap<QString, SmtpConfig> s_smtpDefaults;
    static bool s_defaultsInit;

    void initDefaults();
    void doSend(const QString& toEmail, const QString& subject, const QString& body);

    // Low-level SMTP over QSslSocket (port 465 / implicit TLS)
    bool sendViaSsl(const QString& toEmail,
                    const QString& subject,
                    const QString& body,
                    QString& errorOut);

    // Low-level SMTP over QTcpSocket + STARTTLS (port 587)
    bool sendViaStartTls(const QString& toEmail,
                         const QString& subject,
                         const QString& body,
                         QString& errorOut);

    // Helpers
    static QByteArray base64(const QByteArray& data);
    static QString    mimeEncode(const QString& text);
    bool              smtpLogin(QIODevice* sock, QString& err);
    bool              smtpDialog(QIODevice* sock,
                                 const QString& from,
                                 const QString& to,
                                 const QString& rawMsg,
                                 QString& err);
    static bool readResponse(QIODevice* sock, int expectedCode, QString& err);
    static bool sendCommand(QIODevice* sock, const QByteArray& cmd, int expected, QString& err);
};

#endif // EMAILSENDER_H

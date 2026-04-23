// === rotation_account.h ===
#ifndef ROTATION_ACCOUNT_H
#define ROTATION_ACCOUNT_H

#include <QString>
#include <QDate>
#include <QHash>

struct RotationAccount {
    int     id                  = 0;
    QString serviceName;
    QString login;
    QDate   lastPasswordChange;
    int     rotationIntervalDays = 0;   // 0 = выключено
    bool    autoRotationEnabled  = false;
    QString apiEndpoint;
    QString apiMethod            = QStringLiteral("POST");
    QString authTokenEncrypted;
    QString authType;                   // "Bearer" | "Basic" | "Header"
    QString newPasswordFieldName = QStringLiteral("password");
    QHash<QString, QString> customHeaders;

    // Возвращает true, если сегодня пора менять пароль
    bool isRotationDue(const QDate& today) const {
        if (!autoRotationEnabled || rotationIntervalDays <= 0)
            return false;
        if (!lastPasswordChange.isValid())
            return true;
        return lastPasswordChange.addDays(rotationIntervalDays) <= today;
    }

    QDate nextRotationDate() const {
        if (!autoRotationEnabled || rotationIntervalDays <= 0 || !lastPasswordChange.isValid())
            return QDate{};
        return lastPasswordChange.addDays(rotationIntervalDays);
    }
};

#endif // ROTATION_ACCOUNT_H

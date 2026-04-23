// === database_extensions.h ===
#ifndef DATABASE_EXTENSIONS_H
#define DATABASE_EXTENSIONS_H

#include <QObject>
#include <QDate>
#include <QVector>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QJsonDocument>
#include <QJsonObject>
#include <QDebug>

#include "rotation_account.h"

// Миксин-расширение: новые методы Database для ротации паролей.
// Подключается к существующему Database через наследование или
// включением этого заголовка внутрь существующего класса Database.
// Использует только QSqlDatabase::database() — существующее соединение.

class DatabaseExtensions : public QObject
{
    Q_OBJECT

public:
    explicit DatabaseExtensions(QObject* parent = nullptr) : QObject(parent) {}

    // ── Инициализация таблицы (вызвать один раз при открытии БД) ─────────────
    bool initRotationTable()
    {
        QSqlQuery q(db());
        const bool ok = q.exec(QStringLiteral(R"(
            CREATE TABLE IF NOT EXISTS rotation_settings (
                id                     INTEGER PRIMARY KEY,
                last_password_change   TEXT    DEFAULT '',
                rotation_interval_days INTEGER DEFAULT 0,
                auto_rotation_enabled  INTEGER DEFAULT 0,
                api_endpoint           TEXT    DEFAULT '',
                api_method             TEXT    DEFAULT 'POST',
                auth_token_encrypted   TEXT    DEFAULT '',
                auth_type              TEXT    DEFAULT '',
                new_password_field     TEXT    DEFAULT 'password',
                custom_headers_json    TEXT    DEFAULT '{}',
                postponed_until        TEXT    DEFAULT ''
            )
        )"));
        if (!ok)
            qWarning() << "[DB] initRotationTable:" << q.lastError().text();
        return ok;
    }

    // ── Получить аккаунт с данными ротации ────────────────────────────────────
    RotationAccount getRotationAccount(int id)
    {
        RotationAccount acc;
        acc.id = id;

        // Базовые поля из основной таблицы (используем существующие методы — читаем напрямую)
        QSqlQuery q(db());
        q.prepare(QStringLiteral(
            "SELECT service_name, login FROM accounts WHERE id = :id"));
        q.bindValue(QStringLiteral(":id"), id);
        if (q.exec() && q.next()) {
            acc.serviceName = q.value(0).toString();
            acc.login       = q.value(1).toString();
        }

        // Поля ротации
        QSqlQuery r(db());
        r.prepare(QStringLiteral(
            "SELECT last_password_change, rotation_interval_days, auto_rotation_enabled,"
            "       api_endpoint, api_method, auth_token_encrypted, auth_type,"
            "       new_password_field, custom_headers_json"
            " FROM rotation_settings WHERE id = :id"));
        r.bindValue(QStringLiteral(":id"), id);
        if (r.exec() && r.next()) {
            acc.lastPasswordChange    = QDate::fromString(r.value(0).toString(), Qt::ISODate);
            acc.rotationIntervalDays  = r.value(1).toInt();
            acc.autoRotationEnabled   = r.value(2).toBool();
            acc.apiEndpoint           = r.value(3).toString();
            acc.apiMethod             = r.value(4).toString();
            acc.authTokenEncrypted    = r.value(5).toString();
            acc.authType              = r.value(6).toString();
            acc.newPasswordFieldName  = r.value(7).toString();

            const QJsonObject hdrs = QJsonDocument::fromJson(
                r.value(8).toString().toUtf8()).object();
            for (auto it = hdrs.begin(); it != hdrs.end(); ++it)
                acc.customHeaders.insert(it.key(), it.value().toString());
        }
        return acc;
    }

    // ── Обновить настройки ротации ────────────────────────────────────────────
    bool updateRotationAccount(const RotationAccount& acc)
    {
        // UPSERT: вставить или обновить
        QJsonObject hdrs;
        for (auto it = acc.customHeaders.cbegin(); it != acc.customHeaders.cend(); ++it)
            hdrs.insert(it.key(), it.value());

        QSqlQuery q(db());
        q.prepare(QStringLiteral(R"(
            INSERT INTO rotation_settings
                (id, last_password_change, rotation_interval_days, auto_rotation_enabled,
                 api_endpoint, api_method, auth_token_encrypted, auth_type,
                 new_password_field, custom_headers_json)
            VALUES
                (:id, :lpc, :rid, :are, :ep, :meth, :tok, :atype, :npf, :hdrs)
            ON CONFLICT(id) DO UPDATE SET
                last_password_change   = excluded.last_password_change,
                rotation_interval_days = excluded.rotation_interval_days,
                auto_rotation_enabled  = excluded.auto_rotation_enabled,
                api_endpoint           = excluded.api_endpoint,
                api_method             = excluded.api_method,
                auth_token_encrypted   = excluded.auth_token_encrypted,
                auth_type              = excluded.auth_type,
                new_password_field     = excluded.new_password_field,
                custom_headers_json    = excluded.custom_headers_json
        )"));
        q.bindValue(QStringLiteral(":id"),   acc.id);
        q.bindValue(QStringLiteral(":lpc"),  acc.lastPasswordChange.toString(Qt::ISODate));
        q.bindValue(QStringLiteral(":rid"),  acc.rotationIntervalDays);
        q.bindValue(QStringLiteral(":are"),  acc.autoRotationEnabled ? 1 : 0);
        q.bindValue(QStringLiteral(":ep"),   acc.apiEndpoint);
        q.bindValue(QStringLiteral(":meth"), acc.apiMethod);
        q.bindValue(QStringLiteral(":tok"),  acc.authTokenEncrypted);
        q.bindValue(QStringLiteral(":atype"),acc.authType);
        q.bindValue(QStringLiteral(":npf"),  acc.newPasswordFieldName);
        q.bindValue(QStringLiteral(":hdrs"),
            QString::fromUtf8(QJsonDocument(hdrs).toJson(QJsonDocument::Compact)));

        const bool ok = q.exec();
        if (!ok) qWarning() << "[DB] updateRotationAccount:" << q.lastError().text();
        return ok;
    }

    // ── Атомарно обновить пароль и дату последней смены ──────────────────────
    bool updatePasswordAndRotationDate(int id,
                                       const QString& newEncryptedPassword,
                                       const QDate&   changeDate)
    {
        QSqlDatabase d = db();
        d.transaction();

        QSqlQuery q1(d);
        q1.prepare(QStringLiteral(
            "UPDATE accounts SET encrypted_password = :pwd WHERE id = :id"));
        q1.bindValue(QStringLiteral(":pwd"), newEncryptedPassword);
        q1.bindValue(QStringLiteral(":id"),  id);
        if (!q1.exec()) {
            qWarning() << "[DB] updatePassword accounts:" << q1.lastError().text();
            d.rollback();
            return false;
        }

        QSqlQuery q2(d);
        q2.prepare(QStringLiteral(R"(
            INSERT INTO rotation_settings (id, last_password_change)
            VALUES (:id, :dt)
            ON CONFLICT(id) DO UPDATE SET last_password_change = excluded.last_password_change
        )"));
        q2.bindValue(QStringLiteral(":id"), id);
        q2.bindValue(QStringLiteral(":dt"), changeDate.toString(Qt::ISODate));
        if (!q2.exec()) {
            qWarning() << "[DB] updateRotationDate:" << q2.lastError().text();
            d.rollback();
            return false;
        }

        d.commit();
        return true;
    }

    // ── Найти ID аккаунтов с наступившей датой смены ─────────────────────────
    QVector<int> getAccountsDueForRotation(const QDate& today)
    {
        QVector<int> ids;
        QSqlQuery q(db());
        q.prepare(QStringLiteral(R"(
            SELECT id FROM rotation_settings
            WHERE auto_rotation_enabled = 1
              AND rotation_interval_days > 0
              AND (
                  last_password_change = ''
                  OR date(last_password_change, '+' || rotation_interval_days || ' days') <= :today
              )
              AND (postponed_until = '' OR postponed_until <= :today2)
        )"));
        q.bindValue(QStringLiteral(":today"),  today.toString(Qt::ISODate));
        q.bindValue(QStringLiteral(":today2"), today.toString(Qt::ISODate));
        if (q.exec()) {
            while (q.next())
                ids.append(q.value(0).toInt());
        } else {
            qWarning() << "[DB] getAccountsDueForRotation:" << q.lastError().text();
        }
        return ids;
    }

    // ── Включить / выключить автосмену ────────────────────────────────────────
    bool setAutoRotationEnabled(int id, bool enabled, int intervalDays)
    {
        QSqlQuery q(db());
        q.prepare(QStringLiteral(R"(
            INSERT INTO rotation_settings (id, auto_rotation_enabled, rotation_interval_days)
            VALUES (:id, :en, :iv)
            ON CONFLICT(id) DO UPDATE SET
                auto_rotation_enabled  = excluded.auto_rotation_enabled,
                rotation_interval_days = excluded.rotation_interval_days
        )"));
        q.bindValue(QStringLiteral(":id"), id);
        q.bindValue(QStringLiteral(":en"), enabled ? 1 : 0);
        q.bindValue(QStringLiteral(":iv"), intervalDays);
        const bool ok = q.exec();
        if (!ok) qWarning() << "[DB] setAutoRotationEnabled:" << q.lastError().text();
        return ok;
    }

    // ── Отложить смену пароля для аккаунта ───────────────────────────────────
    bool postponeRotation(int id, const QDate& until)
    {
        QSqlQuery q(db());
        q.prepare(QStringLiteral(R"(
            INSERT INTO rotation_settings (id, postponed_until)
            VALUES (:id, :dt)
            ON CONFLICT(id) DO UPDATE SET postponed_until = excluded.postponed_until
        )"));
        q.bindValue(QStringLiteral(":id"), id);
        q.bindValue(QStringLiteral(":dt"), until.toString(Qt::ISODate));
        const bool ok = q.exec();
        if (!ok) qWarning() << "[DB] postponeRotation:" << q.lastError().text();
        return ok;
    }

private:
    static QSqlDatabase db() { return QSqlDatabase::database(); }
};

#endif // DATABASE_EXTENSIONS_H

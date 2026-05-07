#ifndef PASSWORDMODEL_H
#define PASSWORDMODEL_H

#include <QAbstractListModel>
#include <QVector>
#include <QString>
#include <QHash>

struct PasswordItem {
    QString id;
    QString title;
    QString username;
    QString password;
    QString website;
    QString category = "General";
};

class PasswordModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum Roles {
        IdRole = Qt::UserRole,
        TitleRole = Qt::UserRole + 1,
        UsernameRole,
        PasswordRole,
        WebsiteRole,
        CategoryRole
    };

    explicit PasswordModel(QObject* parent = nullptr);

    // ── QAbstractListModel interface ─────────────────────────────────────
    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    // ── CRUD ─────────────────────────────────────────────────────────────
    Q_INVOKABLE void addPassword(const QString& title,
        const QString& username,
        const QString& password,
        const QString& website,
        const QString& category = "General");

    Q_INVOKABLE void removePassword(int index);

    Q_INVOKABLE bool updatePasswordFull(const QString& id,
        const QString& title,
        const QString& username,
        const QString& password,
        const QString& website,
        const QString& category);

    // ── Сериализация ─────────────────────────────────────────────────────
    Q_INVOKABLE QString toJson() const;
    Q_INVOKABLE void fromJson(const QString& jsonStr);
    Q_INVOKABLE int count() const { return items.size(); }

    // ── Методы для RotationManager ────────────────────────────────────────
    Q_INVOKABLE bool    updatePassword(const QString& id, const QString& newPassword);
    Q_INVOKABLE QString getWebsite(const QString& id) const;
    Q_INVOKABLE QString getPassword(const QString& id) const;
    Q_INVOKABLE int     indexById(const QString& id) const;

    // ── Категории ──────────────────────────────────────────────────────────
    Q_INVOKABLE int countByCategory(const QString& category) const;

private:
    QVector<PasswordItem> items;
};

#endif // PASSWORDMODEL_H
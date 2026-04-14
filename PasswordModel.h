#ifndef PASSWORDMODEL_H
#define PASSWORDMODEL_H

#include <QAbstractListModel>
#include <QJsonArray>
#include <QJsonObject>

struct PasswordItem {
    QString title;
    QString username;
    QString password;
    QString website;
};

class PasswordModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum Roles {
        TitleRole = Qt::UserRole + 1,
        UsernameRole,
        PasswordRole,
        WebsiteRole
    };

    PasswordModel(QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void addPassword(QString title,
                                  QString username,
                                  QString password,
                                  QString website);

    Q_INVOKABLE void removePassword(int index);

    /** Serialize current list → JSON string for FileManager::savePasswords() */
    Q_INVOKABLE QString toJson() const;

    /** Deserialize JSON string from FileManager::loadPasswords() and replace list */
    Q_INVOKABLE void fromJson(const QString& jsonStr);

    Q_INVOKABLE int count() const { return items.size(); }

private:
    QList<PasswordItem> items;
};

#endif

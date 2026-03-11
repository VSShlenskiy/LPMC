#ifndef PASSWORDMODEL_H
#define PASSWORDMODEL_H

#include <QAbstractListModel>

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

private:
    QList<PasswordItem> items;
};

#endif
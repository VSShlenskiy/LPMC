#include "PasswordModel.h"

PasswordModel::PasswordModel(QObject* parent)
    : QAbstractListModel(parent)
{
}

int PasswordModel::rowCount(const QModelIndex&) const
{
    return items.size();
}

QVariant PasswordModel::data(const QModelIndex& index, int role) const
{
    const PasswordItem& item = items[index.row()];

    switch (role) {
    case TitleRole: return item.title;
    case UsernameRole: return item.username;
    case PasswordRole: return item.password;
    case WebsiteRole: return item.website;
    }

    return QVariant();
}

QHash<int, QByteArray> PasswordModel::roleNames() const
{
    return {
        {TitleRole, "title"},
        {UsernameRole, "username"},
        {PasswordRole, "password"},
        {WebsiteRole, "website"}
    };
}

void PasswordModel::addPassword(QString title,
    QString username,
    QString password,
    QString website)
{
    beginInsertRows(QModelIndex(), items.size(), items.size());

    items.append({ title, username, password, website });

    endInsertRows();
}
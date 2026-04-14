#include "PasswordModel.h"
#include <QJsonDocument>

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
    if (!index.isValid() || index.row() >= items.size())
        return QVariant();

    const PasswordItem& item = items[index.row()];

    switch (role) {
    case TitleRole:    return item.title;
    case UsernameRole: return item.username;
    case PasswordRole: return item.password;
    case WebsiteRole:  return item.website;
    }

    return QVariant();
}

QHash<int, QByteArray> PasswordModel::roleNames() const
{
    return {
        {TitleRole,    "title"},
        {UsernameRole, "username"},
        {PasswordRole, "password"},
        {WebsiteRole,  "website"}
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

void PasswordModel::removePassword(int index)
{
    if (index < 0 || index >= items.size())
        return;

    beginRemoveRows(QModelIndex(), index, index);
    items.removeAt(index);
    endRemoveRows();
}

QString PasswordModel::toJson() const
{
    QJsonArray arr;
    for (const PasswordItem& item : items) {
        QJsonObject obj;
        obj["title"]    = item.title;
        obj["username"] = item.username;
        obj["password"] = item.password;
        obj["website"]  = item.website;
        arr.append(obj);
    }
    return QString::fromUtf8(QJsonDocument(arr).toJson(QJsonDocument::Compact));
}

void PasswordModel::fromJson(const QString& jsonStr)
{
    QJsonDocument doc = QJsonDocument::fromJson(jsonStr.toUtf8());
    if (!doc.isArray())
        return;

    beginResetModel();
    items.clear();
    for (const QJsonValue& val : doc.array()) {
        QJsonObject obj = val.toObject();
        items.append({
            obj["title"].toString(),
            obj["username"].toString(),
            obj["password"].toString(),
            obj["website"].toString()
        });
    }
    endResetModel();
}

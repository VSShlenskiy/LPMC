#include "PasswordModel.h"

#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QUuid>

PasswordModel::PasswordModel(QObject* parent)
    : QAbstractListModel(parent)
{}

// ── QAbstractListModel interface ──────────────────────────────────────────────

int PasswordModel::rowCount(const QModelIndex& parent) const
{
    if (parent.isValid()) return 0;
    return items.size();
}

QVariant PasswordModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= items.size())
        return {};

    const PasswordItem& item = items.at(index.row());

    switch (role) {
    case IdRole:       return item.id;
    case TitleRole:    return item.title;
    case UsernameRole: return item.username;
    case PasswordRole: return item.password;
    case WebsiteRole:  return item.website;
    default:           return {};
    }
}

QHash<int, QByteArray> PasswordModel::roleNames() const
{
    QHash<int, QByteArray> hash;
    hash[IdRole]       = "itemId";     // в QML: model.itemId
    hash[TitleRole]    = "title";
    hash[UsernameRole] = "username";
    hash[PasswordRole] = "password";
    hash[WebsiteRole]  = "website";
    return hash;
}

// ── CRUD ──────────────────────────────────────────────────────────────────────

void PasswordModel::addPassword(const QString& title,
                                const QString& username,
                                const QString& password,
                                const QString& website)
{
    PasswordItem item;
    // Генерируем UUID без фигурных скобок: "550e8400-e29b-41d4-a716-446655440000"
    item.id       = QUuid::createUuid().toString(QUuid::WithoutBraces);
    item.title    = title;
    item.username = username;
    item.password = password;
    item.website  = website;

    beginInsertRows(QModelIndex(), items.size(), items.size());
    items.append(item);
    endInsertRows();
}

void PasswordModel::removePassword(int index)
{
    if (index < 0 || index >= items.size()) return;

    beginRemoveRows(QModelIndex(), index, index);
    items.removeAt(index);
    endRemoveRows();
}

// ── Сериализация ──────────────────────────────────────────────────────────────

QString PasswordModel::toJson() const
{
    QJsonArray arr;
    for (const PasswordItem& item : items) {
        QJsonObject obj;
        obj["id"]       = item.id;
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
    QJsonParseError err;
    QJsonDocument doc = QJsonDocument::fromJson(jsonStr.toUtf8(), &err);
    if (err.error != QJsonParseError::NoError || !doc.isArray()) return;

    beginResetModel();
    items.clear();

    for (const QJsonValue& val : doc.array()) {
        if (!val.isObject()) continue;
        QJsonObject obj = val.toObject();

        PasswordItem item;
        // Если id отсутствует (старые данные без UUID) — генерируем новый
        item.id       = obj["id"].toString();
        if (item.id.isEmpty())
            item.id = QUuid::createUuid().toString(QUuid::WithoutBraces);

        item.title    = obj["title"].toString();
        item.username = obj["username"].toString();
        item.password = obj["password"].toString();
        item.website  = obj["website"].toString();
        items.append(item);
    }

    endResetModel();
}

// ── Методы для RotationManager ────────────────────────────────────────────────

bool PasswordModel::updatePassword(const QString& id, const QString& newPassword)
{
    int idx = indexById(id);
    if (idx < 0) return false;

    items[idx].password = newPassword;

    // Уведомляем View об изменении конкретной ячейки
    QModelIndex mi = index(idx);
    emit dataChanged(mi, mi, { PasswordRole });
    return true;
}

QString PasswordModel::getWebsite(const QString& id) const
{
    int idx = indexById(id);
    return idx >= 0 ? items[idx].website : QString();
}

QString PasswordModel::getPassword(const QString& id) const
{
    int idx = indexById(id);
    return idx >= 0 ? items[idx].password : QString();
}

int PasswordModel::indexById(const QString& id) const
{
    for (int i = 0; i < items.size(); ++i) {
        if (items[i].id == id) return i;
    }
    return -1;
}

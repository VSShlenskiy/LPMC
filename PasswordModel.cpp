#include "PasswordModel.h"

#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QUuid>
#include <QDebug>

PasswordModel::PasswordModel(QObject* parent)
    : QAbstractListModel(parent)
{
}

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
    case CategoryRole: return item.category.isEmpty() ? "General" : item.category;
    default:           return {};
    }
}

QHash<int, QByteArray> PasswordModel::roleNames() const
{
    QHash<int, QByteArray> hash;
    hash[IdRole] = "itemId";
    hash[TitleRole] = "title";
    hash[UsernameRole] = "username";
    hash[PasswordRole] = "password";
    hash[WebsiteRole] = "website";
    hash[CategoryRole] = "category";
    return hash;
}

// ── CRUD ──────────────────────────────────────────────────────────────────────

void PasswordModel::addPassword(const QString& title,
    const QString& username,
    const QString& password,
    const QString& website,
    const QString& category)
{
    PasswordItem item;
    item.id = QUuid::createUuid().toString(QUuid::WithoutBraces);
    item.title = title;
    item.username = username;
    item.password = password;
    item.website = website;

    // Убедимся, что категория не пустая
    if (category.isEmpty() || category.isNull()) {
        item.category = "General";
    }
    else {
        item.category = category;
    }

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

bool PasswordModel::updatePasswordFull(const QString& id,
    const QString& title,
    const QString& username,
    const QString& password,
    const QString& website,
    const QString& category)
{
    int idx = indexById(id);
    if (idx < 0) return false;

    items[idx].title = title;
    items[idx].username = username;
    items[idx].password = password;
    items[idx].website = website;

    // Обновляем категорию
    if (!category.isEmpty() && !category.isNull()) {
        items[idx].category = category;
    }
    else if (items[idx].category.isEmpty()) {
        items[idx].category = "General";
    }

    QModelIndex mi = index(idx);
    emit dataChanged(mi, mi, { TitleRole, UsernameRole, PasswordRole, WebsiteRole, CategoryRole });
    return true;
}

// ── Сериализация ──────────────────────────────────────────────────────────────

QString PasswordModel::toJson() const
{
    QJsonArray arr;
    for (const PasswordItem& item : items) {
        QJsonObject obj;
        obj["id"] = item.id;
        obj["title"] = item.title;
        obj["username"] = item.username;
        obj["password"] = item.password;
        obj["website"] = item.website;
        obj["category"] = item.category.isEmpty() ? "General" : item.category;
        arr.append(obj);
    }
    return QString::fromUtf8(QJsonDocument(arr).toJson(QJsonDocument::Compact));
}

void PasswordModel::fromJson(const QString& jsonStr)
{
    QJsonParseError err;
    QJsonDocument doc = QJsonDocument::fromJson(jsonStr.toUtf8(), &err);
    if (err.error != QJsonParseError::NoError || !doc.isArray()) {
        return;
    }

    beginResetModel();
    items.clear();

    for (const QJsonValue& val : doc.array()) {
        if (!val.isObject()) continue;
        QJsonObject obj = val.toObject();

        PasswordItem item;
        item.id = obj["id"].toString();
        if (item.id.isEmpty())
            item.id = QUuid::createUuid().toString(QUuid::WithoutBraces);

        item.title = obj["title"].toString();
        item.username = obj["username"].toString();
        item.password = obj["password"].toString();
        item.website = obj["website"].toString();

        // Важно: правильно загружаем категорию
        QString category = obj["category"].toString();
        item.category = category.isEmpty() ? "General" : category;

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

// ── Категории ──────────────────────────────────────────────────────────────

int PasswordModel::countByCategory(const QString& category) const
{
    int count = 0;
    for (const auto& item : items) {
        QString itemCategory = item.category.isEmpty() ? "General" : item.category;
        if (itemCategory == category) {
            count++;
        }
    }
    return count;
}
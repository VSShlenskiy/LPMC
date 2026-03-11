#ifndef FILEMANAGER_H
#define FILEMANAGER_H

#include <QObject>
#include <QFile>
#include <QTextStream>
#include <QCryptographicHash>
#include <QDebug>
#include <QCoreApplication> // Добавлено!

class FileManager : public QObject
{
    Q_OBJECT // Добавлено! Это обязательно для Q_INVOKABLE

public:
    explicit FileManager(QObject* parent = nullptr) : QObject(parent) {}

    Q_INVOKABLE bool saveMasterPassword(const QString& password) {
        // Создаем хеш пароля
        QByteArray passwordHash = QCryptographicHash::hash(
            password.toUtf8(),
            QCryptographicHash::Sha256
        ).toHex();

        // Путь к файлу в папке приложения
        QString filePath = QCoreApplication::applicationDirPath() + "/master.hash";
        qDebug() << "Saving to:" << filePath; // Отладка

        QFile file(filePath);
        if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
            qDebug() << "Cannot open file for writing:" << file.errorString();
            return false;
        }

        QTextStream out(&file);
        out << passwordHash;
        file.close();

        qDebug() << "Master password hash saved to:" << filePath;
        return true;
    }

    Q_INVOKABLE bool verifyMasterPassword(const QString& password) {
        QString filePath = QCoreApplication::applicationDirPath() + "/master.hash";
        QFile file(filePath);

        if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
            qDebug() << "Cannot open file for reading:" << file.errorString();
            return false;
        }

        QTextStream in(&file);
        QString savedHash = in.readAll();
        file.close();

        QByteArray inputHash = QCryptographicHash::hash(
            password.toUtf8(),
            QCryptographicHash::Sha256
        ).toHex();

        return savedHash == inputHash;
    }

    Q_INVOKABLE bool isMasterPasswordSet() {
        QString filePath = QCoreApplication::applicationDirPath() + "/master.hash";
        return QFile::exists(filePath);
    }
};

#endif // FILEMANAGER_H
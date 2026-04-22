#ifndef FILEMANAGER_H
#define FILEMANAGER_H

#include <QObject>
#include <QFile>
#include <QDebug>
#include <QCoreApplication>
#include <QCryptographicHash>
#include <QJsonArray>
#include <QJsonObject>
#include <QJsonDocument>
#include <QVariantMap>

#include <openssl/evp.h>
#include <openssl/rand.h>

class FileManager : public QObject
{
    Q_OBJECT

public:
    explicit FileManager(QObject* parent = nullptr) : QObject(parent) {}

private:

    // ─── AES-256-GCM core ─────────────────────────────────────────────────────

    QByteArray encryptAES256GCM(const QByteArray& plaintext,
                                 const QByteArray& key,
                                 QByteArray& iv,
                                 QByteArray& tag)
    {
        EVP_CIPHER_CTX* ctx = EVP_CIPHER_CTX_new();

        iv.resize(12);
        RAND_bytes(reinterpret_cast<unsigned char*>(iv.data()), iv.size());

        EVP_EncryptInit_ex(ctx, EVP_aes_256_gcm(), nullptr, nullptr, nullptr);
        EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_IVLEN, iv.size(), nullptr);
        EVP_EncryptInit_ex(ctx, nullptr, nullptr,
            reinterpret_cast<const unsigned char*>(key.constData()),
            reinterpret_cast<const unsigned char*>(iv.constData()));

        QByteArray ciphertext(plaintext.size() + 16, '\0');

        int len = 0;
        EVP_EncryptUpdate(ctx,
            reinterpret_cast<unsigned char*>(ciphertext.data()),
            &len,
            reinterpret_cast<const unsigned char*>(plaintext.constData()),
            plaintext.size());

        int ciphertext_len = len;

        EVP_EncryptFinal_ex(ctx,
            reinterpret_cast<unsigned char*>(ciphertext.data()) + len,
            &len);

        ciphertext_len += len;
        ciphertext.resize(ciphertext_len);

        tag.resize(16);
        EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_GET_TAG, 16, tag.data());

        EVP_CIPHER_CTX_free(ctx);

        return ciphertext;
    }

    QByteArray decryptAES256GCM(const QByteArray& ciphertext,
                                 const QByteArray& key,
                                 const QByteArray& iv,
                                 const QByteArray& tag)
    {
        EVP_CIPHER_CTX* ctx = EVP_CIPHER_CTX_new();

        EVP_DecryptInit_ex(ctx, EVP_aes_256_gcm(), nullptr, nullptr, nullptr);
        EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_IVLEN, iv.size(), nullptr);
        EVP_DecryptInit_ex(ctx, nullptr, nullptr,
            reinterpret_cast<const unsigned char*>(key.constData()),
            reinterpret_cast<const unsigned char*>(iv.constData()));

        QByteArray plaintext(ciphertext.size(), '\0');

        int len = 0;
        EVP_DecryptUpdate(ctx,
            reinterpret_cast<unsigned char*>(plaintext.data()),
            &len,
            reinterpret_cast<const unsigned char*>(ciphertext.constData()),
            ciphertext.size());

        int plaintext_len = len;

        QByteArray tagCopy = tag;
        EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_TAG, tagCopy.size(),
            tagCopy.data());

        int ret = EVP_DecryptFinal_ex(ctx,
            reinterpret_cast<unsigned char*>(plaintext.data()) + len,
            &len);

        EVP_CIPHER_CTX_free(ctx);

        if (ret <= 0) {
            qWarning() << "[FileManager] AES-GCM decryption authentication failed";
            return {};
        }

        plaintext_len += len;
        plaintext.resize(plaintext_len);

        return plaintext;
    }

    QByteArray getDerivedKey() const
    {
        return QCryptographicHash::hash(
            "super_secret_key",
            QCryptographicHash::Sha256
        );
    }

    // ─── Generic encrypted file helpers ──────────────────────────────────────

    bool saveEncryptedString(const QString& filePath, const QString& data)
    {
        QFile file(filePath);
        if (!file.open(QIODevice::WriteOnly)) {
            qWarning() << "[FileManager] Cannot open for writing:" << filePath;
            return false;
        }

        QByteArray key = getDerivedKey();
        QByteArray iv, tag;
        QByteArray encrypted = encryptAES256GCM(data.toUtf8(), key, iv, tag);

        file.write(iv);
        file.write(tag);
        file.write(encrypted);
        file.close();
        return true;
    }

    QString loadEncryptedString(const QString& filePath)
    {
        QFile file(filePath);
        if (!file.exists() || !file.open(QIODevice::ReadOnly))
            return {};

        QByteArray iv         = file.read(12);
        QByteArray tag        = file.read(16);
        QByteArray ciphertext = file.readAll();
        file.close();

        if (iv.size() < 12 || tag.size() < 16 || ciphertext.isEmpty())
            return {};

        QByteArray decrypted = decryptAES256GCM(ciphertext, getDerivedKey(), iv, tag);
        return decrypted.isEmpty() ? QString() : QString::fromUtf8(decrypted);
    }

public:

    // ─── Master password ──────────────────────────────────────────────────────

    Q_INVOKABLE bool saveMasterPassword(const QString& password)
    {
        QString filePath = QCoreApplication::applicationDirPath() + "/master.dat";
        QFile file(filePath);
        if (!file.open(QIODevice::WriteOnly)) {
            qWarning() << "[FileManager] Cannot open master.dat for writing:" << filePath;
            return false;
        }

        QByteArray key = getDerivedKey();
        QByteArray iv, tag;
        QByteArray encrypted = encryptAES256GCM(password.toUtf8(), key, iv, tag);

        file.write(iv);
        file.write(tag);
        file.write(encrypted);
        file.close();
        return true;
    }

    Q_INVOKABLE bool verifyMasterPassword(const QString& password)
    {
        QString filePath = QCoreApplication::applicationDirPath() + "/master.dat";
        QFile file(filePath);
        if (!file.open(QIODevice::ReadOnly)) {
            qWarning() << "[FileManager] Cannot open master.dat for reading:" << filePath;
            return false;
        }

        QByteArray iv         = file.read(12);
        QByteArray tag        = file.read(16);
        QByteArray ciphertext = file.readAll();
        file.close();

        QByteArray decrypted = decryptAES256GCM(ciphertext, getDerivedKey(), iv, tag);
        return !decrypted.isEmpty() && (decrypted == password.toUtf8());
    }

    Q_INVOKABLE bool isMasterPasswordSet()
    {
        QString filePath = QCoreApplication::applicationDirPath() + "/master.dat";
        return QFile::exists(filePath);
    }

    // Returns the plain master password (used for recovery email)
    Q_INVOKABLE QString getMasterPassword()
    {
        QString filePath = QCoreApplication::applicationDirPath() + "/master.dat";
        QFile file(filePath);
        if (!file.open(QIODevice::ReadOnly))
            return {};

        QByteArray iv         = file.read(12);
        QByteArray tag        = file.read(16);
        QByteArray ciphertext = file.readAll();
        file.close();

        QByteArray decrypted = decryptAES256GCM(ciphertext, getDerivedKey(), iv, tag);
        return decrypted.isEmpty() ? QString() : QString::fromUtf8(decrypted);
    }

    // ─── Password vault ───────────────────────────────────────────────────────

    Q_INVOKABLE bool savePasswords(const QString& jsonArray)
    {
        QString filePath = QCoreApplication::applicationDirPath() + "/passwords.dat";
        QFile file(filePath);
        if (!file.open(QIODevice::WriteOnly)) {
            qWarning() << "[FileManager] Cannot open passwords.dat for writing:" << filePath;
            return false;
        }

        QByteArray key = getDerivedKey();
        QByteArray iv, tag;
        QByteArray encrypted = encryptAES256GCM(jsonArray.toUtf8(), key, iv, tag);

        file.write(iv);
        file.write(tag);
        file.write(encrypted);
        file.close();
        return true;
    }

    Q_INVOKABLE QString loadPasswords()
    {
        QString filePath = QCoreApplication::applicationDirPath() + "/passwords.dat";
        QFile file(filePath);
        if (!file.exists() || !file.open(QIODevice::ReadOnly))
            return "[]";

        QByteArray iv         = file.read(12);
        QByteArray tag        = file.read(16);
        QByteArray ciphertext = file.readAll();
        file.close();

        if (iv.size() < 12 || tag.size() < 16 || ciphertext.isEmpty())
            return "[]";

        QByteArray decrypted = decryptAES256GCM(ciphertext, getDerivedKey(), iv, tag);
        if (decrypted.isEmpty())
            return "[]";

        return QString::fromUtf8(decrypted);
    }

    // ─── Recovery email ───────────────────────────────────────────────────────

    Q_INVOKABLE bool saveUserEmail(const QString& email)
    {
        return saveEncryptedString(
            QCoreApplication::applicationDirPath() + "/email.dat",
            email);
    }

    Q_INVOKABLE QString getUserEmail()
    {
        return loadEncryptedString(
            QCoreApplication::applicationDirPath() + "/email.dat");
    }

    // ─── SMTP app-passwords ───────────────────────────────────────────────────
    // Stored as a JSON object { "domain": "apppassword", ... } in app_passwords.dat

    Q_INVOKABLE bool saveSmtpAppPassword(const QString& domain,
                                          const QString& appPassword)
    {
        QVariantMap all = getAllSmtpAppPasswords();
        all[domain.toLower()] = appPassword;

        QJsonObject obj;
        for (auto it = all.cbegin(); it != all.cend(); ++it)
            obj[it.key()] = it.value().toString();

        QString json = QString::fromUtf8(QJsonDocument(obj).toJson(QJsonDocument::Compact));
        return saveEncryptedString(
            QCoreApplication::applicationDirPath() + "/app_passwords.dat",
            json);
    }

    Q_INVOKABLE QString getSmtpAppPassword(const QString& domain)
    {
        QVariantMap all = getAllSmtpAppPasswords();
        return all.value(domain.toLower()).toString();
    }

    Q_INVOKABLE QVariantMap getAllSmtpAppPasswords()
    {
        QString json = loadEncryptedString(
            QCoreApplication::applicationDirPath() + "/app_passwords.dat");
        if (json.isEmpty())
            return {};

        QJsonObject obj = QJsonDocument::fromJson(json.toUtf8()).object();
        QVariantMap result;
        for (auto it = obj.constBegin(); it != obj.constEnd(); ++it)
            result[it.key()] = it.value().toString();
        return result;
    }

    Q_INVOKABLE bool deleteSmtpAppPassword(const QString& domain)
    {
        QVariantMap all = getAllSmtpAppPasswords();
        if (!all.remove(domain.toLower()))
            return false;

        QJsonObject obj;
        for (auto it = all.cbegin(); it != all.cend(); ++it)
            obj[it.key()] = it.value().toString();

        QString json = QString::fromUtf8(QJsonDocument(obj).toJson(QJsonDocument::Compact));
        return saveEncryptedString(
            QCoreApplication::applicationDirPath() + "/app_passwords.dat",
            json);
    }
};

#endif // FILEMANAGER_H

#ifndef FILEMANAGER_H
#define FILEMANAGER_H

#include <QObject>
#include <QFile>
#include <QDebug>
#include <QCoreApplication>
#include <QCryptographicHash>

#include <openssl/evp.h>
#include <openssl/rand.h>

class FileManager : public QObject
{
    Q_OBJECT

public:
    explicit FileManager(QObject* parent = nullptr) : QObject(parent) {}

private:

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
            reinterpret_cast<const unsigned char*>(key.data()),
            reinterpret_cast<const unsigned char*>(iv.data()));

        QByteArray ciphertext;
        ciphertext.resize(plaintext.size());

        int len;
        EVP_EncryptUpdate(ctx,
            reinterpret_cast<unsigned char*>(ciphertext.data()),
            &len,
            reinterpret_cast<const unsigned char*>(plaintext.data()),
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
            reinterpret_cast<const unsigned char*>(key.data()),
            reinterpret_cast<const unsigned char*>(iv.data()));

        QByteArray plaintext;
        plaintext.resize(ciphertext.size());

        int len;
        EVP_DecryptUpdate(ctx,
            reinterpret_cast<unsigned char*>(plaintext.data()),
            &len,
            reinterpret_cast<const unsigned char*>(ciphertext.data()),
            ciphertext.size());

        int plaintext_len = len;

        EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_TAG, tag.size(),
            const_cast<char*>(tag.data()));

        int ret = EVP_DecryptFinal_ex(ctx,
            reinterpret_cast<unsigned char*>(plaintext.data()) + len,
            &len);

        EVP_CIPHER_CTX_free(ctx);

        if (ret <= 0)
        {
            qDebug() << "Decryption failed (authentication error)";
            return {};
        }

        plaintext_len += len;
        plaintext.resize(plaintext_len);

        return plaintext;
    }


public:

    Q_INVOKABLE bool saveMasterPassword(const QString& password)
    {
        QString filePath = QCoreApplication::applicationDirPath() + "/master.dat";

        QFile file(filePath);
        if (!file.open(QIODevice::WriteOnly))
            return false;

        QByteArray key = QCryptographicHash::hash(
            "super_secret_key",
            QCryptographicHash::Sha256
        );

        QByteArray iv;
        QByteArray tag;

        QByteArray encrypted = encryptAES256GCM(
            password.toUtf8(),
            key,
            iv,
            tag
        );

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
        if (!file.open(QIODevice::ReadOnly))
            return false;

        QByteArray iv = file.read(12);
        QByteArray tag = file.read(16);
        QByteArray ciphertext = file.readAll();

        file.close();

        QByteArray key = QCryptographicHash::hash(
            "super_secret_key",
            QCryptographicHash::Sha256
        );

        QByteArray decrypted = decryptAES256GCM(
            ciphertext,
            key,
            iv,
            tag
        );

        return decrypted == password.toUtf8();
    }


    Q_INVOKABLE bool isMasterPasswordSet()
    {
        QString filePath = QCoreApplication::applicationDirPath() + "/master.dat";
        return QFile::exists(filePath);
    }
};

#endif
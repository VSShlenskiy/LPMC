// === main.cpp (только новые строки, помечены ADDED FOR ROTATION) ===
//
// Вставить эти изменения в существующий main.cpp:

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QIcon>
#include <QDebug>

#include "FileManager.h"
#include "PasswordModel.h"
#include "AppSettings.h"

// ADDED FOR ROTATION ─────────────────────────────────────────────────────────
#include "database_extensions.h"
#include "api_client.h"
#include "password_rotator.h"
#include "rotation_scheduler.h"
// ────────────────────────────────────────────────────────────────────────────

int main(int argc, char* argv[])
{
#if defined(Q_OS_WIN) && QT_VERSION_CHECK(5, 6, 0) <= QT_VERSION && QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif

    QGuiApplication app(argc, argv);
    app.setWindowIcon(QIcon(":/icon.png"));

    FileManager   fileManager;
    PasswordModel passwordModel;
    AppSettings   appSettings;

    // ADDED FOR ROTATION ─────────────────────────────────────────────────────
    DatabaseExtensions dbExt;
    dbExt.initRotationTable();          // создаёт таблицу если её нет

    ApiClient        apiClient;         // один экземпляр на всё приложение
    PasswordRotator  passwordRotator(&dbExt, &apiClient);
    RotationScheduler rotationScheduler(&dbExt, &passwordRotator);
    // ────────────────────────────────────────────────────────────────────────

    QQmlApplicationEngine engine;

    engine.rootContext()->setContextProperty("fileManager",    &fileManager);
    engine.rootContext()->setContextProperty("PasswordModel",  &passwordModel);
    engine.rootContext()->setContextProperty("AppSettings",    &appSettings);

    // ADDED FOR ROTATION ─────────────────────────────────────────────────────
    engine.rootContext()->setContextProperty("passwordRotator",    &passwordRotator);
    engine.rootContext()->setContextProperty("rotationScheduler",  &rotationScheduler);
    // ────────────────────────────────────────────────────────────────────────

    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));

    if (engine.rootObjects().isEmpty()) {
        qCritical() << "Failed to load main.qml";
        return -1;
    }

    // ADDED FOR ROTATION — подключаем сигналы после загрузки QML ────────────
    // Сигнал databaseUnlocked должен эмититься из FileManager при успешной
    // верификации мастер-пароля. Пример подключения:
    //   QObject::connect(&fileManager, &FileManager::databaseUnlocked,
    //                    &rotationScheduler, &RotationScheduler::checkNow);
    //
    // Обработка dueAccountsFound — показываем RotationPrompt через QML:
    QObject::connect(
        &rotationScheduler, &RotationScheduler::dueAccountsFound,
        [&engine](const QList<int>& ids) {
            QObject* root = engine.rootObjects().isEmpty()
                            ? nullptr : engine.rootObjects().first();
            if (!root) return;
            // Вызываем QML-функцию showRotationPrompt(accountId)
            for (int id : ids) {
                QMetaObject::invokeMethod(root, "showRotationPrompt",
                    Qt::QueuedConnection,
                    Q_ARG(QVariant, id));
            }
        });

    // Запускаем планировщик — только после разблокировки БД
    // rotationScheduler.start() вызывать из QML при успешном вводе мастер-пароля:
    //   onClicked: {
    //       if (fileManager.verifyMasterPassword(masterPass.text)) {
    //           rotationScheduler.start()    // ADDED FOR ROTATION
    //           stackView.push("homePage.qml")
    //       }
    //   }
    // ────────────────────────────────────────────────────────────────────────

    return app.exec();
}

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QIcon>
#include <QDebug>

#include "FileManager.h"
#include "PasswordModel.h"
#include "AppSettings.h"
#include "EmailSender.h"
#include "RotationManager.h"

int main(int argc, char* argv[])
{
#if defined(Q_OS_WIN) && QT_VERSION_CHECK(5, 6, 0) <= QT_VERSION && QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif

    QGuiApplication app(argc, argv);
    app.setWindowIcon(QIcon(":/icon.ico"));

    // ── Backend объекты ───────────────────────────────────────────────────
    FileManager    fileManager;
    PasswordModel  passwordModel;
    AppSettings    appSettings;
    EmailSender    emailSender;

    RotationManager rotationManager(&passwordModel, &fileManager);

    // ── QML Engine ────────────────────────────────────────────────────────
    QQmlApplicationEngine engine;

    // Все context properties ДОЛЖНЫ быть установлены ДО загрузки QML
    engine.rootContext()->setContextProperty("fileManager",     &fileManager);
    engine.rootContext()->setContextProperty("PasswordModel",   &passwordModel);
    engine.rootContext()->setContextProperty("AppSettings",     &appSettings);
    engine.rootContext()->setContextProperty("emailSender",     &emailSender);
    engine.rootContext()->setContextProperty("rotationManager", &rotationManager);

    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));

    if (engine.rootObjects().isEmpty()) {
        qCritical() << "Failed to load main.qml";
        return -1;
    }

    return app.exec();
}

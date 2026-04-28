#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QIcon>
#include <QDebug>

#include "FileManager.h"
#include "PasswordModel.h"
#include "AppSettings.h"
#include "EmailSender.h"
#include "RotationManager.h"   // ← ДОБАВЛЕНО

// ─────────────────────────────────────────────────────────────────────────────
// main.cpp
// Изменения:
//   1. Добавлен #include "RotationManager.h"
//   2. Создан экземпляр RotationManager (получает ссылки на модель и FileManager)
//   3. Зарегистрирован как context property "rotationManager" для QML
// ─────────────────────────────────────────────────────────────────────────────

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

    // RotationManager принимает указатели на модель и fileManager.
    // Порядок создания важен: модель и fileManager должны быть созданы раньше.
    RotationManager rotationManager(&passwordModel, &fileManager);

    // ── QML Engine ────────────────────────────────────────────────────────
    QQmlApplicationEngine engine;

    // Все context properties ДОЛЖНЫ быть установлены ДО загрузки QML
    engine.rootContext()->setContextProperty("fileManager",     &fileManager);
    engine.rootContext()->setContextProperty("PasswordModel",   &passwordModel);
    engine.rootContext()->setContextProperty("AppSettings",     &appSettings);
    engine.rootContext()->setContextProperty("emailSender",     &emailSender);
    engine.rootContext()->setContextProperty("rotationManager", &rotationManager); // ← ДОБАВЛЕНО

    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));

    if (engine.rootObjects().isEmpty()) {
        qCritical() << "Failed to load main.qml";
        return -1;
    }

    return app.exec();
}

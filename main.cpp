#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QIcon>
#include <QDebug>

#include "FileManager.h"
#include "PasswordModel.h"
#include "AppSettings.h"

int main(int argc, char* argv[])
{
#if defined(Q_OS_WIN) && QT_VERSION_CHECK(5, 6, 0) <= QT_VERSION && QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif

    QGuiApplication app(argc, argv);
    app.setWindowIcon(QIcon(":/icon.png"));

    // ── Backend objects ──────────────────────────────────────────────────────
    FileManager   fileManager;
    PasswordModel passwordModel;
    AppSettings   appSettings;

    // ── QML engine ───────────────────────────────────────────────────────────
    QQmlApplicationEngine engine;

    // Все контекстные свойства ДОЛЖНЫ быть установлены ДО загрузки QML
    engine.rootContext()->setContextProperty("fileManager",    &fileManager);
    engine.rootContext()->setContextProperty("PasswordModel",  &passwordModel);
    engine.rootContext()->setContextProperty("AppSettings",    &appSettings);

    // Единственная загрузка QML через ресурс
    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));

    if (engine.rootObjects().isEmpty()) {
        qCritical() << "Failed to load main.qml";
        return -1;
    }

    return app.exec();
}

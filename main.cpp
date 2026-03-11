#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QDir>
#include <QDebug>
#include <QFileInfo>
#include <QIcon>
#include <QQmlContext>
#include "FileManager.h"
#include <PasswordModel.h>


int main(int argc, char* argv[])
{
#if defined(Q_OS_WIN) && QT_VERSION_CHECK(5, 6, 0) <= QT_VERSION && QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif

    QGuiApplication app(argc, argv);

    qDebug() << "Application path:" << QCoreApplication::applicationDirPath();

    QQmlApplicationEngine engine;

    QString iconPath = ":/icon.png";
    QIcon appIcon(iconPath);
    if (!appIcon.isNull()) {
        app.setWindowIcon(appIcon);
    }
    PasswordModel passwordModel;

    engine.rootContext()->setContextProperty("PasswordModel", &passwordModel);

    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));
    FileManager fileManager;
    engine.rootContext()->setContextProperty("fileManager", &fileManager);

    engine.addImportPath(".");
    engine.addImportPath("./");

    qDebug() << "Import paths:" << engine.importPathList();

    engine.load(QUrl::fromLocalFile("main.qml"));

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
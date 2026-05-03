#ifndef APPSETTINGS_H
#define APPSETTINGS_H

#include <QObject>
#include <QFile>
#include <QJsonObject>
#include <QJsonDocument>
#include <QCoreApplication>
#include <QMap>

class AppSettings : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString theme    READ theme    WRITE setTheme    NOTIFY themeChanged)
    Q_PROPERTY(QString language READ language WRITE setLanguage NOTIFY languageChanged)

    // +++ новые свойства для авторотации +++
    Q_PROPERTY(int  rotationDays    READ rotationDays    WRITE setRotationDays    NOTIFY rotationDaysChanged)
    Q_PROPERTY(bool rotationEnabled READ rotationEnabled WRITE setRotationEnabled NOTIFY rotationEnabledChanged)

    Q_PROPERTY(QString bgPrimary   READ bgPrimary   NOTIFY themeChanged)
    Q_PROPERTY(QString bgSecondary READ bgSecondary NOTIFY themeChanged)
    Q_PROPERTY(QString bgCard      READ bgCard      NOTIFY themeChanged)
    Q_PROPERTY(QString bgInput     READ bgInput     NOTIFY themeChanged)
    Q_PROPERTY(QString accent      READ accent      NOTIFY themeChanged)
    Q_PROPERTY(QString textPrimary READ textPrimary NOTIFY themeChanged)
    Q_PROPERTY(QString textMuted   READ textMuted   NOTIFY themeChanged)
    Q_PROPERTY(QString border      READ border      NOTIFY themeChanged)

public:
    explicit AppSettings(QObject* parent = nullptr) : QObject(parent) { load(); }

    QString theme()           const { return m_theme; }
    QString language()        const { return m_language; }
    int     rotationDays()    const { return m_rotationDays; }
    bool    rotationEnabled() const { return m_rotationEnabled; }

    QString bgPrimary()   const { return pal("bgPrimary"); }
    QString bgSecondary() const { return pal("bgSecondary"); }
    QString bgCard()      const { return pal("bgCard"); }
    QString bgInput()     const { return pal("bgInput"); }
    QString accent()      const { return pal("accent"); }
    QString textPrimary() const { return pal("textPrimary"); }
    QString textMuted()   const { return pal("textMuted"); }
    QString border()      const { return pal("border"); }

    void setTheme(const QString& t) {
        if (m_theme == t) return;
        m_theme = t;
        emit themeChanged();
    }

    void setLanguage(const QString& l) {
        if (m_language == l) return;
        m_language = l;
        emit languageChanged();
    }

    // +++ сеттеры для авторотации +++
    void setRotationDays(int d) {
        if (m_rotationDays == d) return;
        m_rotationDays = d;
        emit rotationDaysChanged();
    }

    void setRotationEnabled(bool e) {
        if (m_rotationEnabled == e) return;
        m_rotationEnabled = e;
        emit rotationEnabledChanged();
    }

    Q_INVOKABLE void save() {
        QJsonObject obj;
        obj["theme"]           = m_theme;
        obj["language"]        = m_language;
        obj["rotationDays"]    = m_rotationDays;      // +++
        obj["rotationEnabled"] = m_rotationEnabled;   // +++
        QFile f(path());
        if (f.open(QIODevice::WriteOnly))
            f.write(QJsonDocument(obj).toJson(QJsonDocument::Compact));
    }

    Q_INVOKABLE void load() {
        QFile f(path());
        if (!f.exists() || !f.open(QIODevice::ReadOnly)) {
            m_theme           = "Dark";
            m_language        = "English";
            m_rotationDays    = 90;     // +++
            m_rotationEnabled = false;  // +++
            return;
        }
        QJsonObject obj    = QJsonDocument::fromJson(f.readAll()).object();
        m_theme            = obj.value("theme").toString("Dark");
        m_language         = obj.value("language").toString("English");
        m_rotationDays     = obj.value("rotationDays").toInt(90);        // +++
        m_rotationEnabled  = obj.value("rotationEnabled").toBool(false); // +++
    }

    Q_INVOKABLE QString tr(const QString& key) const {
        // [English, Russian, Lithuanian]
        static const QMap<QString, QStringList> T = {
            {"getStarted",      {"GET STARTED",          "НАЧАТЬ",                "PRADĖTI"}},
            {"allPasswords",    {"ALL PASSWORDS",         "ВСЕ ПАРОЛИ",            "VISI SLAPTAŽODŽIAI"}},
            {"addPassword",     {"ADD PASSWORD",          "ДОБАВИТЬ",              "PRIDĖTI"}},
            {"lockVault",       {"LOCK VAULT",            "ЗАБЛОКИРОВАТЬ",         "UŽRAKINTI"}},
            {"settings",        {"SETTINGS",              "НАСТРОЙКИ",             "NUSTATYMAI"}},
            {"save",            {"SAVE",                  "СОХРАНИТЬ",             "IŠSAUGOTI"}},
            {"cancel",          {"Cancel",                "Отмена",                "Atšaukti"}},
            {"add",             {"Add",                   "Добавить",              "Pridėti"}},
            {"fieldTitle",      {"Title *",               "Название *",            "Pavadinimas *"}},
            {"fieldUser",       {"Username/Email *",      "Логин/Email *",         "Vartotojas/El.paštas *"}},
            {"fieldPassword",   {"Password *",            "Пароль *",              "Slaptažodis *"}},
            {"fieldWebsite",    {"Website",               "Сайт",                  "Svetainė"}},
            {"fieldCategory",   {"Category",              "Категория",             "Kategorija"}},
            {"requiredFields",  {"* Required fields",     "* Обязательные поля",   "* Privalomi laukai"}},
            {"fillInfo",        {"Fill in your password information",
                                  "Заполните информацию о пароле",
                                  "Užpildykite slaptažodžio informaciją"}},
            {"addPasswordTitle",{"Add Password",          "Добавить пароль",       "Pridėti slaptažodį"}},
            {"masterPassword",  {"Master Password",       "Мастер-пароль",         "Pagrindinis slaptažodis"}},
            {"createMaster",    {"Create Master Password","Создайте мастер-пароль","Sukurkite pagrindinį slaptažodį"}},
            {"enterMaster",     {"Enter Master Password", "Введите мастер-пароль", "Įveskite pagrindinį slaptažodį"}},
            {"unlock",          {"UNLOCK",                "ВОЙТИ",                 "ATRAKINTI"}},
            {"create",          {"CREATE",                "СОЗДАТЬ",               "SUKURTI"}},
            {"searchPasswords", {"Search passwords...",   "Поиск паролей...",      "Ieškoti slaptažodžių..."}},
            {"noPasswords",     {"No passwords saved yet.\nClick ADD PASSWORD to get started.",
                                  "Паролей пока нет.\nНажмите ДОБАВИТЬ, чтобы начать.",
                                  "Slaptažodžių dar nėra.\nSpauskite PRIDĖTI, kad pradėtumėte."}},
            {"language",        {"Language",              "Язык",                  "Kalba"}},
            {"chooseLanguage",  {"Choose the interface language",
                                  "Выберите язык интерфейса",
                                  "Pasirinkite sąsajos kalbą"}},
            {"theme",           {"Theme",                 "Тема",                  "Tema"}},
            {"chooseTheme",     {"Choose the color theme","Выберите цветовую тему","Pasirinkite spalvų temą"}},
            {"categories",      {"Categories",            "Категории",             "Kategorijos"}},
            {"catAll",          {"All",                   "Все",                   "Visi"}},
            {"copyBtn",         {"COPY",                  "КОПИРОВАТЬ",            "KOPIJUOTI"}},
            {"incorrectPwd",    {"Incorrect password",    "Неверный пароль",       "Neteisingas slaptažodis"}},
            {"pwdNoMatch",      {"Passwords don't match", "Пароли не совпадают",   "Slaptažodžiai nesutampa"}},
            {"minChars",        {"Minimum 8 characters",  "Минимум 8 символов",    "Mažiausiai 8 simboliai"}},
            {"autoRotate",      {"Auto Password Rotation","Авто-смена пароля",     "Automatinis keitimas"}},
            {"rotationInterval",{"Rotation interval",     "Интервал смены",        "Keitimo intervalas"}},
            {"customDays",      {"Custom:",               "Свой:",                 "Pasirinktinis:"}},
            {"days",            {"days",                  "дней",                  "dienų"}},
        };

        int idx = (m_language == "Russian") ? 1 : (m_language == "Lithuanian") ? 2 : 0;
        auto it = T.find(key);
        if (it == T.end()) return key;
        const QStringList& list = it.value();
        if (idx < list.size()) return list.at(idx);
        return list.at(0);
    }

signals:
    void themeChanged();
    void languageChanged();
    void rotationDaysChanged();    // +++
    void rotationEnabledChanged(); // +++

private:
    QString m_theme           = "Dark";
    QString m_language        = "English";
    int     m_rotationDays    = 90;    // +++
    bool    m_rotationEnabled = false; // +++

    QString path() const {
        return QCoreApplication::applicationDirPath() + "/settings.json";
    }

    QString pal(const QString& role) const {
        static const QMap<QString, QStringList> P = {
            //               role         Dark       Light      Purple
            {"bgPrimary",   {"#0A0A0A", "#F0F0F0", "#0D0017"}},
            {"bgSecondary", {"#111111", "#FFFFFF",  "#1A0033"}},
            {"bgCard",      {"#1E1E1E", "#E8E8E8",  "#2D0055"}},
            {"bgInput",     {"#1E1E1E", "#EFEFEF",  "#220044"}},
            {"accent",      {"#9900FF", "#7700CC",  "#CC00FF"}},
            {"textPrimary", {"#FFFFFF", "#111111",  "#FFFFFF"}},
            {"textMuted",   {"#888888", "#555555",  "#BB99CC"}},
            {"border",      {"#333333", "#CCCCCC",  "#550088"}},
        };

        int idx = (m_theme == "Light") ? 1 : (m_theme == "Purple") ? 2 : 0;
        auto it = P.find(role);
        if (it == P.end()) return "#000000";
        const QStringList& list = it.value();
        if (idx < list.size()) return list.at(idx);
        return list.at(0);
    }
};

#endif // APPSETTINGS_H

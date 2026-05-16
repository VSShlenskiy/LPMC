# LPMC (Local Password Manager) 🔐

<div align="center">
<img alt="uml" src="https://img.shields.io/badge/C%2B%2B-17-blue?style=for-the-badge&logo=cplusplus" />
<img alt="uml" src="https://img.shields.io/badge/Qt-6-green?style=for-the-badge&logo=qt" />
<img alt="uml" src="https://img.shields.io/badge/OpenSSL-AES--256--GCM-orange?style=for-the-badge" />

<img alt="uml" src="https://img.shields.io/badge/Platform-Windows%20%7C%20Linux-lightgrey?style=for-the-badge" />
<img alt="uml" src="https://img.shields.io/badge/-JavaScript-333333?style=flat&logo=javascript" />
  
LPMC — кроссплатформенный локальный менеджер паролей с современным QML-интерфейсом.
Все данные хранятся на вашем устройстве, зашифрованные с помощью AES-256-GCM.
</div>

---
| Функции | Статус |
| --- | --- |
| Сделать автозамену паролей | ✔ |
| Реализовать редактирование сохраненных паролей|✔|
| Сделать кнопку показа паролей/копирование/удаление|✔|
|Добавить функционал настроек|✔|
|Восстановление пароля через почту |✔|

---
ОТЧЕТ ПО ПРОЕКТУ: «Разработка АРМ специалиста (LPMC)»
Введение
Целью данного проекта является разработка кроссплатформенного локального менеджера паролей с графическим интерфейсом (АРМ специалиста по информационной безопасности или обычного пользователя). Продукт LPMC (Local Password Manager) обеспечивает надежное локальное хранение учетных записей, защищенных единым мастер-паролем, а также предоставляет инструмент генерации сложных паролей.

Актуальность обусловлена необходимостью в безопасном, но простом инструменте управления личными данными, не использующем облачные хранилища.

1. Основной функционал программы

Функция	Описание	Реализация

Защита мастер-паролем	Доступ ко всем данным возможен только после ввода единого мастер-пароля.	C++ + QML (экраны regPage.qml, admission.qml)

Локальное хранение	База паролей хранится на диске, синхронизация с сервером отсутствует.	FileManager.h (чтение/запись/шифрование)

Генератор паролей	Встроенная утилита для создания случайных паролей по заданным параметрам.	generatePasswordPage.qml

Модель данных	Отображение списка записей в QML через модель C++.	PasswordModel.cpp / .h (наследуется от QAbstractListModel)

Кастомный интерфейс	Собственная строка заголовка, плавные переходы, карточки записей.	TitleBar.qml, PasswordItem.qml

Восстановление по email	Функция восстановления доступа через email (добавлена в последнем коммите).	EmailSender.cpp / .h

Настройки приложения	Страница с настройками (возможно, тема, автозапуск).	settingPage.qml, AppSettings.cpp / .h

**Архитектура проекта**
Проект построен по паттерну Model-View из экосистемы Qt. QML-слой отвечает исключительно за отображение и анимации, не содержа бизнес-логики. C++ классы предоставляют данные и функциональность через механизмы Q_INVOKABLE и Q_PROPERTY, зарегистрированные в контексте QML-движка при старте приложения.

**UML-диаграммы классов**
Общая диаграмма зависимостей
На диаграмме показано, как main.cpp создаёт четыре C++ объекта и передаёт их в QML-движок, а также как классы связаны между собой через зависимости и агрегацию.
<img width="900" height="640" alt="uml_overview" src="https://github.com/user-attachments/assets/87f01e66-37c3-4dbb-a4a9-3b31ddd123cc" />
**PasswordItem**
PasswordItem — простая структура (POD — Plain Old Data), описывающая одну запись в хранилище. Не является QObject, поэтому не имеет сигналов, слотов и не регистрируется в Qt Meta-Object System. Используется только внутри PasswordModel как элемент QList<PasswordItem>.
<img width="500" height="220" alt="uml_password_item" src="https://github.com/user-attachments/assets/218a44d8-a454-4084-9f23-27484d8313f8" />
Данные в QML передаются не напрямую через структуру, а через механизм ролей (RoleNames) в PasswordModel. Когда ListView обращается к model.title, Qt под капотом вызывает data(index, TitleRole).
**PasswordModel**
Центральный класс приложения. Наследует QAbstractListModel и является мостом между QList<PasswordItem> и QML ListView. Отвечает за CRUD-операции над записями и сериализацию данных в JSON.
<img width="640" height="680" alt="uml_password_model" src="https://github.com/user-attachments/assets/5e317f18-953b-49ef-87d3-fd28553352cb" />
QAbstractListModel требует реализации трёх виртуальных методов: rowCount() (число строк), data() (значение по индексу и роли) и roleNames() (маппинг числовых ролей на строковые имена для QML). addPassword и removePassword обёрнуты в beginInsertRows/endInsertRows и beginRemoveRows/endRemoveRows — это автоматически уведомляет View об изменениях без ручных вызовов обновления.
**FileManager**
Отвечает за все операции с файловой системой: хранение, шифрование AES-256-GCM через OpenSSL EVP API, скрытие файлов атрибутом HIDDEN на Windows. Полностью реализован в заголовочном файле.
<img width="700" height="820" alt="uml_file_manager" src="https://github.com/user-attachments/assets/3543dfcf-fbe0-41ba-bb6b-a855ac9bdcd4" />
Формат .dat файла: [IV — 12 байт][TAG — 16 байт][зашифрованные данные]. GCM (Galois/Counter Mode) обеспечивает не только конфиденциальность, но и целостность — любое изменение файла приведёт к отказу расшифровки. При каждой операции файлы скрываются через Win32 API SetFileAttributesW. Метод migrateFromOldLocation() обеспечивает обратную совместимость при обновлении приложения.
**EmailSender + SmtpConfig**
Реализует восстановление доступа через электронную почту, напрямую взаимодействуя с SMTP-серверами через сокеты Qt. Поддерживает два режима: implicit TLS (порт 465) и STARTTLS (порт 587).
<img width="700" height="860" alt="uml_email_sender" src="https://github.com/user-attachments/assets/477a5fa1-02c8-43dc-9f5f-a7e09f6dda93" />
detectSmtp() ищет домен отправителя в статической таблице известных SMTP-провайдеров (Gmail, Yandex, Mail.ru и другие). Если домен найден — конфигурация применяется автоматически; иначе используется setManualSmtp(). Отправка асинхронна: результат возвращается через сигналы emailSent() или emailFailed(). Приложение-пароль (App Password) хранится в FileManager в зашифрованном виде, а не в оперативной памяти процесса.

**Принцип работы:**

Запуск
main.cpp создаёт QQmlApplicationEngine, инстанцирует все четыре C++ объекта и регистрирует их как свойства корневого контекста. После этого загружается main.qml, который через fileManager.isMasterPasswordSet() определяет, показать экран регистрации (regPage.qml) или входа (admission.qml).
2. Первый запуск — регистрация
regPage.qml → пользователь создаёт мастер-пароль → fileManager.saveMasterPassword(pwd). Опционально указывается email для восстановления → fileManager.saveUserEmail(email). Оба вызова шифруют данные AES-256-GCM и записывают в скрытые .dat файлы.
3. Вход
admission.qml → ввод мастер-пароля → fileManager.verifyMasterPassword(pwd) расшифровывает master.dat и сравнивает хеш. При успехе стек навигации переключается на homePage.qml.
4. Работа с паролями
При загрузке главной страницы выполняется passwordModel.fromJson(fileManager.loadPasswords()). ListView автоматически отображает данные из модели. При добавлении или удалении записи изменения сразу сохраняются: fileManager.savePasswords(passwordModel.toJson()). Отдельной кнопки «Сохранить» нет — данные фиксируются немедленно.
5. Шифрование
Запись:
  plaintext → RAND_bytes(IV, 12 байт) → EVP_EncryptInit/Update/Final
            → [IV (12)][TAG (16)][ciphertext] → SetFileAttributesW(HIDDEN)

Чтение:
  файл → [IV][TAG][ciphertext] → EVP_DecryptInit/Update/Final
       → проверка TAG → plaintext (или ошибка при несовпадении)
6. Email-восстановление
emailSender.detectSmtp(email) заполняет SmtpConfig по домену. После ввода App Password (fileManager.saveSmtpAppPassword) вызов sendPasswordRecoveryEmail() выбирает sendViaSsl() (порт 465) или sendViaStartTls() (порт 587) в зависимости от флага ssl конфига. Результат приходит сигналом.

Ссылки на источники
Официальная документация Qt

The Qt Company. Qt 6 Documentation. — https://doc.qt.io/
The Qt Company. QAbstractListModel Class. — https://doc.qt.io/qt-6/qabstractlistmodel.html
The Qt Company. Qt QML — Integrating QML and C++. — https://doc.qt.io/qt-6/qtqml-cppintegration-overview.html
The Qt Company. The Property System (Q_PROPERTY). — https://doc.qt.io/qt-6/properties.html
The Qt Company. Qt Network — QSslSocket. — https://doc.qt.io/qt-6/qsslsocket.html
The Qt Company. Qt Network — QTcpSocket. — https://doc.qt.io/qt-6/qtcpsocket.html
The Qt Company. Qt Quick. — https://doc.qt.io/qt-6/qtquick-index.html

OpenSSL

OpenSSL Project. EVP Symmetric Encryption and Decryption. — https://wiki.openssl.org/index.php/EVP_Symmetric_Encryption_and_Decryption
OpenSSL Project. EVP Authenticated Encryption and Decryption (GCM). — https://wiki.openssl.org/index.php/EVP_Authenticated_Encryption_and_Decryption
OpenSSL Project. RAND_bytes. — https://www.openssl.org/docs/man3.0/man3/RAND_bytes.html

Стандарты шифрования

NIST. Recommendation for Block Cipher Modes of Operation: GCM. SP 800-38D. — https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-38d.pdf

Microsoft / Win32

Microsoft. SetFileAttributesW function. — https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-setfileattributesw
Microsoft. KNOWNFOLDERID — FOLDERID_LocalAppData. — https://learn.microsoft.com/en-us/windows/win32/shell/knownfolderid
Microsoft. Visual Studio 2022 Documentation. — https://learn.microsoft.com/en-us/visualstudio/

Авторы
|Автор|  GitHub|
|-------|---------|
|Шаисламов Михаил |@SHMIHAIL|
|Шленский Виталий| @VSShlenskiy|

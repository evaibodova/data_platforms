# Hive Deployment

Автоматизированное развертывание Apache Hive 4.0.0-alpha-2 и загрузка данных в партиционированную таблицу на существующем HDFS + YARN-кластере.

## Топология кластера

- `team-03-en` — Edge Node, SecondaryNameNode, HiveServer2, Hive Metastore, MySQL
- `team-03-nn` — NameNode, DataNode, ResourceManager, NodeManager, JobHistoryServer
- `team-03-00` — DataNode, NodeManager
- `team-03-01` — DataNode, NodeManager

Клиенты подключаются через Beeline к HiveServer2 (`team-03-en:10000`). Отдельный Metastore (`team-03-en:9083`) хранит метаданные в MySQL. Поддерживается одновременная работа нескольких клиентов.

## Requirements

Все скрипты запускаются от `team` на `team-03-en` из корня проекта `hive-deploy`.

Необходимы:

- Ubuntu 22.04/24.04, Java 11;
- работающий Hadoop 3.4.0 в `/home/hadoop/hadoop-3.4.0`, HDFS, YARN и JobHistoryServer;
- пользователь `hadoop`, настроенный SSH между узлами;
- права `sudo`, для удаленных команд — без запроса пароля;
- доступ к репозиториям Ubuntu, Apache Archive и Maven Central.

Скрипты `00–13` относятся к предыдущим ДЗ и повторно не запускаются. Перед первоначальной настройкой необходимо завершить другие YARN-задания, так как при исправлении сетевых настроек перезапускаются затронутые NodeManager.

## Развертывание

Из корня проекта выполнить:

```bash
bash scripts/deploy.sh
```

Скрипт последовательно запускает:

```bash
bash scripts/14_install_hive.sh
bash scripts/15_configure_hive.sh
bash scripts/16_start_hive.sh
bash scripts/17_load_data.sh
bash scripts/18_check_hive.sh
```

Выполняются подготовка сетевого окружения, установка Hive и JDBC-драйвера, настройка MySQL и схемы Metastore, запуск служб systemd, загрузка данных и проверка.

Пароль Metastore генерируется автоматически и сохраняется в `.env`. Файл `.env` не добавляется в Git.

## Загрузка данных

Файл `sql/01_create_table.sql` создает внешнюю таблицу `test.colours` с полями `colour STRING`, `number INT` и партицией `dt STRING`.

Данные находятся в `data/`. Имя файла — `YYYY-MM-DD.tsv`, содержимое — два поля через табуляцию без заголовка. Дата из имени определяет партицию.

Для отдельного запуска загрузки:

```bash
bash scripts/17_load_data.sh
```

Скрипт проверяет файлы, передает их в HDFS и выполняет `LOAD DATA ... OVERWRITE ... PARTITION`. Повторная загрузка заменяет данные соответствующей партиции без дублирования строк.

## Проверка Hive

Скрипт:

```bash
bash scripts/18_check_hive.sh
```

проверяет:

- работу MySQL, Metastore и HiveServer2;
- доступность веб-интерфейса HiveServer2;
- две одновременно открытые клиентские сессии;
- количество строк и максимальное значение `number` в тестовых партициях через MapReduce/YARN.

Ожидаемый результат для `dt`, `COUNT(*)`, `MAX(number)`:

```text
2024-08-09    4    12
2024-08-10    4    15
```

При успешной проверке выводится:

```text
OK: Hive accepts two clients; both partitions contain expected data
```

## Остановка

```bash
bash scripts/19_stop_hive.sh
```

Останавливаются HiveServer2 и Metastore. MySQL, HDFS и YARN продолжают работать; данные и схема сохраняются.

## Примечания

Временная директория `hadoop_ssh/` используется только для передачи SSH-ключей между нодами.

После успешной настройки SSH она удаляется.

Директория `hadoop_ssh/` и файл `.env` должны быть добавлены в `.gitignore`.

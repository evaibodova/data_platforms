# Spark Deployment

Автоматизированное развертывание Apache Spark 3.5.3 под управлением YARN, чтение и преобразование данных из HDFS, сохранение результата в партиционированную таблицу и проверка чтения через Hive.

## Топология кластера

- `team-03-en` — Edge Node, SecondaryNameNode, Spark Driver, HiveServer2, Hive Metastore, MySQL
- `team-03-nn` — NameNode, DataNode, ResourceManager, NodeManager, JobHistoryServer
- `team-03-00` — DataNode, NodeManager
- `team-03-01` — DataNode, NodeManager

Spark запускается в режиме `yarn` с `deploy-mode client`. Driver работает на `team-03-en`, executors запускаются под управлением YARN на worker-нодах. Данные хранятся в HDFS, результат доступен через Beeline и существующий HiveServer2.

## Requirements

Все скрипты запускаются от `team` на `team-03-en` из корня проекта `spark-deploy`.

Необходимы:

- Ubuntu 22.04/24.04, Java 11;
- работающий Hadoop 3.4.0 в `/home/hadoop/hadoop-3.4.0`, HDFS, YARN и JobHistoryServer;
- работающие HiveServer2, Hive Metastore и MySQL из предыдущего ДЗ;
- пользователь `hadoop`, настроенный SSH между узлами;
- права `sudo`, для удаленных команд — без запроса пароля;
- доступ к Apache Archive для загрузки Spark.

Имена узлов должны корректно разрешаться в сетевые IP-адреса. Скрипты `00–19` относятся к предыдущим ДЗ и не вызываются из `deploy.sh`. Предполагается, что HDFS, YARN и Hive уже настроены и запущены.

Переменные окружения и функции запуска находятся в `scripts/variables.sh`. Файл `.env` не добавляется в Git.

## Развертывание

Из корня проекта выполнить:

```bash
bash scripts/deploy.sh
```

Скрипт последовательно запускает:

```bash
bash scripts/20_install_spark.sh
bash scripts/21_setup_spark_env.sh
bash scripts/22_load_spark_data.sh
bash scripts/23_run_spark.sh
bash scripts/24_check_spark.sh
```

Выполняются установка Spark и проверка контрольной суммы, настройка окружения, загрузка данных в HDFS, запуск Spark-сессии под управлением YARN, преобразование данных, регистрация таблицы и проверка.

## Загрузка и преобразование данных

Тестовые данные находятся в `data/`. Имя файла — `YYYY-MM-DD.tsv`, содержимое — два поля через табуляцию без заголовка: цвет и число.

Для отдельного запуска загрузки:

```bash
bash scripts/22_load_spark_data.sh
```

Скрипт проверяет файлы и передает их в HDFS в каталог `/user/hadoop/spark-input/colours/dt=YYYY-MM-DD/`.

Код `spark/colours_transform.scala` использует созданную сессию Spark для чтения TSV, приведения чисел к `INT`, нормализации названий цветов и группировки по дате и цвету. Для каждой группы вычисляются количество строк, сумма и максимальное значение.

Результат сохраняется в Parquet с партиционированием по `dt`. Файл `sql/02_create_spark_table.sql` регистрирует внешнюю таблицу `test.colours_summary`, а `MSCK REPAIR TABLE` синхронизирует партиции в Hive.

Повторный запуск обработки заменяет результат без дублирования строк. Исходная таблица `test.colours` не изменяется.

## Проверка Spark

Скрипт:

```bash
bash scripts/24_check_spark.sh
```

проверяет:

- работу Metastore и HiveServer2;
- возможность чтения результата стандартным клиентом Hive — Beeline;
- наличие двух тестовых партиций;
- значения всех шести результирующих строк.

Ожидаемый результат для `dt`, `colour`, `row_count`, `total_number`, `max_number`:

```text
2024-08-09    blue     1    7     7
2024-08-09    green    1    3     3
2024-08-09    red      2    17    12
2024-08-10    blue     2    19    15
2024-08-10    green    1    8     8
2024-08-10    red      1    9     9
```

При успешной проверке выводится:

```text
OK: Hive reads Spark results; both partitions and all six rows are correct
```

## Остановка

Сессия Spark завершается автоматически после обработки через `spark.stop()`. HDFS, YARN, Hive и MySQL продолжают работать; данные и таблицы сохраняются.

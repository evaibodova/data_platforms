# Prefect Deployment

Автоматизированный запуск потока Prefect для обработки данных в Apache Spark под управлением YARN и сохранения результата как таблицы Hive

## Топология кластера

- `team-03-en` — Edge Node, SecondaryNameNode, Prefect, Spark Driver, HiveServer2, Hive Metastore, MySQL
- `team-03-nn` — NameNode, DataNode, ResourceManager, NodeManager, JobHistoryServer
- `team-03-00` — DataNode, NodeManager
- `team-03-01` — DataNode, NodeManager

## Requirements

Все скрипты запускаются от `team` на `team-03-en` из корня проекта `prefect-deploy`.

Необходимы:

- Python 3.11 или новее, Java 11;
- настроенные и работающие HDFS, YARN и Hive из предыдущих ДЗ;
- установленный Spark 3.5.3 и окружение из ДЗ-4;
- права `sudo` для команд существующих скриптов и доступ к репозиториям Ubuntu и PyPI.

Переменные окружения находятся в `scripts/variables.sh`. Для настройки зависимостей используются файлы предыдущих ДЗ. Скрипты `23` и `24` вызываются внутри потока

Если Hive остановлен, выполнить:

```bash
bash scripts/16_start_hive.sh
```

## Развертывание

Из корня проекта выполнить:

```bash
bash scripts/deploy.sh
```

Скрипт последовательно запускает:

```bash
bash scripts/25_install_prefect.sh
bash scripts/26_setup_prefect.sh
bash scripts/27_run_flow.sh
bash scripts/28_check_flow.sh
```

Выполняются установка Prefect 3.9.3, создание конфигурации, запуск потока и проверка результата

## Загрузка и преобразование данных

В `data/` находятся тестовые tsv-файлы без заголовка: цвет и число через табуляцию. Имя файла `YYYY-MM-DD.tsv` определяет дату.

Если данные еще не загружены в HDFS, выполнить:

```bash
bash scripts/22_load_spark_data.sh
```

Поток `flows/colours_flow.py` проверяет входной каталог HDFS, запускает обработку через `23_run_spark.sh` и проверяет результат через `24_check_spark.sh`

Spark читает tsv из HDFS, нормализует названия цветов, преобразует числа в `int` и вычисляет количество, сумму и максимум по дате и цвету. Результат сохраняется в Parquet с партиционированием по `dt` и регистрируется как внешняя таблица `test.colours_summary` через `sql/02_create_spark_table.sql`

При ошибке задача и поток завершаются с ошибкой. Повторная обработка заменяет результат без дублирования строк

## Проверка потока

Скрипт:

```bash
bash scripts/28_check_flow.sh
```

проверяет:

- сохраненный статус потока `COMPLETED` и идентификатор запуска;
- чтение таблицы через Beeline;
- две тестовые партиции и значения всех шести результирующих строк.

При успешной проверке выводится:

```text
OK: Prefect flow completed successfully and the result table is correct
```

Полный запуск должен завершиться с кодом `0`

## Остановка

Сессия Spark и временный сервер Prefect завершаются автоматически. HDFS, YARN и Hive продолжают работать; данные сохраняются

## Примечания

Директории `.venv/`, `.prefect/`, `logs/` и файл `.env` должны быть добавлены в `.gitignore`
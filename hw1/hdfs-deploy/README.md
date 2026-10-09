# HDFS Cluster Deployment

Автоматизированное развертывание HDFS-кластера с:

- 1 NameNode
- 1 SecondaryNameNode
- 3 DataNode

## Топология

- `team-03-en` — Edge Node, SecondaryNameNode
- `team-03-nn` — NameNode, DataNode
- `team-03-00` — DataNode
- `team-03-01` — DataNode

## Requirements

Все скрипты запускаются с `team-03-en` из корня проекта    `hw1/hdfs-deploy`.

Например:

```bash
cd ~/hw1/hdfs-deploy
bash scripts/00_setup_team_ssh.sh
```

В корне проекта должен находиться файл `.env`:

```bash
HADOOP_PASSWORD='...'
```

Файл `.env` содержит пароль пользователя `hadoop` и не должен попадать в Git.

## Deployment

Из корня проекта последовательно выполнить:

```bash
bash scripts/00_setup_team_ssh.sh
bash scripts/01_create_hadoop_user.sh
bash scripts/02_setup_hadoop_ssh.sh
bash scripts/03_setup_java.sh
bash scripts/04_install_hadoop.sh
bash scripts/05_setup_hadoop_env.sh
bash scripts/06_setup_hadoop_configs.sh
bash scripts/07_format_namenode.sh
bash scripts/08_start_hdfs.sh
bash scripts/09_check_cluster.sh
```

`07_format_namenode.sh` необходимо запускать только при первоначальной инициализации нового кластера.

## Верификация

Скрипт `09_check_cluster.sh` проверяет:

- наличие 3 live DataNode;
- работу NameNode;
- работу SecondaryNameNode;
- наличие процесса DataNode на каждой worker-ноде;
- запись и чтение файла в HDFS;
- целостность HDFS с помощью `fsck`.

При успешной проверке вывод завершается сообщением:

```text
OK: cluster is healthy
```

## Примечания

Временная директория `hadoop_ssh/` используется только для передачи SSH-ключей между нодами.

После успешной настройки SSH она удаляется.

Директория `hadoop_ssh/` и файл `.env` должны быть добавлены в `.gitignore`.
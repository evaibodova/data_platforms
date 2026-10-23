# YARN Cluster Deployment

Автоматизированное развертывание HDFS + YARN-кластера с веб-интерфейсами основных и вспомогательных демонов.

## Топология кластера

- `team-03-en` — Edge Node, SecondaryNameNode
- `team-03-nn` — NameNode, DataNode, ResourceManager, NodeManager, JobHistoryServer
- `team-03-00` — DataNode, NodeManager
- `team-03-01` — DataNode, NodeManager

Таким образом, кластер содержит:
- 1 NameNode
- 1 SecondaryNameNode
- 3 DataNode
- 1 ResourceManager
- 3 NodeManager
- 1 JobHistoryServer

## Requirements

Все скрипты запускаются на `team-03-en` из корня проекта `yarn-deploy`.

В корне проекта должен находиться файл `.env`:

```bash
HADOOP_PASSWORD='...'
```

Файл `.env` не добавляется в Git.

На машинах должны быть настроены имена узлов в `/etc/hosts`.

## Развертывание

Скрипты необходимо запускать по порядку из корня проекта:

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
bash scripts/10_setup_yarn_configs.sh
bash scripts/11_start_yarn.sh
bash scripts/12_start_history_server.sh
bash scripts/13_check_yarn.sh
```

`07_format_namenode.sh` необходимо запускать только при первоначальной инициализации нового кластера.

## Проверка кластера

Скрипт:

```bash
bash scripts/13_check_yarn.sh
```

проверяет:

- наличие процесса ResourceManager;
- наличие NodeManager на всех трех worker-нодах;
- регистрацию трех NodeManager в YARN и состояние `RUNNING`;
- наличие JobHistoryServer;
- доступность веб-интерфейсов Hadoop/YARN.

При успешной проверке выводится:

```text
OK: YARN cluster is healthy
```

## Веб-интерфейсы

Внутри кластера доступны следующие интерфейсы:

| Сервис | Адрес |
|---|---|
| NameNode | `team-03-nn:9870` |
| ResourceManager | `team-03-nn:8088` |
| JobHistoryServer | `team-03-nn:19888` |
| NodeManager (`team-03-nn`) | `team-03-nn:8042` |
| NodeManager (`team-03-00`) | `team-03-00:8042` |
| NodeManager (`team-03-01`) | `team-03-01:8042` |
| SecondaryNameNode | `team-03-en:9868` |

Для доступа к основным веб-интерфейсам с локального компьютера используется SSH.

На локальном компьютере выполнить:

```bash
ssh -i ~/.ssh/<PRIVATE_KEY> \
  -N \
  -L 9870:10.3.0.11:9870 \
  -L 8088:10.3.0.11:8088 \
  -L 19888:10.3.0.11:19888 \
  team@<EDGE_NODE_PUBLIC_IP>
```

После установки SSH-соединения интерфейсы доступны в браузере:

- NameNode: `http://localhost:9870`
- ResourceManager: `http://localhost:8088`
- JobHistoryServer: `http://localhost:19888`

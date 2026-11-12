# Terraform Yandex Cloud Lab

Учебный проект для развёртывания VPC, подсети и двух виртуальных машин в Yandex Cloud с помощью Terraform.

## Что создаётся

- VPC `tf-lesson-vpc`.
- Подсеть `tf-lesson-subnet` с CIDR `10.10.0.0/24` в зоне `ru-central1-a`.
- Security Group для `web`: входящий TCP/22 и TCP/8080 из `0.0.0.0/0`.
- Security Group для `worker`: входящий TCP/22 только из `10.10.0.0/24`.
- ВМ `web`: 2 vCPU, 2 GB RAM, публичный IP; cloud-init устанавливает Docker и запускает nginx на порту 8080.
- ВМ `worker`: 2 vCPU, 2 GB RAM, без публичного IP; cloud-init устанавливает Python и запускает фоновый цикл записи в `/var/log/worker.log`.

> **Безопасность:** SSH на `web` открыт всему интернету согласно заданию. Для реального использования замените `0.0.0.0/0` на свой публичный IP/CIDR. `worker` не имеет публичного IP, поэтому подключаться к нему напрямую из интернета нельзя.

## Требования

- Terraform `>= 1.5.0`.
- Yandex Cloud CLI (если используется CLI-профиль) либо переменные окружения для авторизации.
- Сервисный аккаунт с правами, достаточными для создания Compute Cloud, VPC и связанных ресурсов в выбранном каталоге.

## Аутентификация

Код не содержит токенов или приватных ключей.

### Вариант A: переменные окружения

В Bash текущего терминала:

```bash
export YC_TOKEN="$(yc iam create-token)"
export YC_CLOUD_ID="ваш_cloud_id"
export YC_FOLDER_ID="ваш_folder_id"
```

Провайдер Yandex Cloud также поддерживает получение учётных данных из окружения. Если используете сервисный аккаунт, убедитесь, что токен получен от пользователя/учётной записи с необходимыми правами либо используйте поддерживаемую провайдером схему авторизации.

При необходимости можно передать Cloud ID и Folder ID через переменные Terraform:

```bash
export TF_VAR_cloud_id="$YC_CLOUD_ID"
export TF_VAR_folder_id="$YC_FOLDER_ID"
```

### Вариант B: CLI-профиль

Настройте CLI:

```bash
yc init
```

Провайдер может использовать конфигурацию Yandex Cloud CLI. Если выбран отдельный профиль, проверьте его настройки командой `yc config list`.

## Развёртывание

Перейдите в каталог проекта и выполните:

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

Подтвердите применение, введя `yes`.

После завершения Terraform выведет:

- `web_public_ip` — публичный IP web;
- `web_private_ip` — внутренний IP web;
- `worker_private_ip` — внутренний IP worker;
- идентификаторы VPC, подсети и ВМ.

Открыть nginx можно по адресу:

```text
http://<web_public_ip>:8080
```

## Подключение по SSH

Для `web`:

```bash
ssh ubuntu@<web_public_ip>
```

Для `worker` публичного IP нет. Подключение возможно с другой ВМ внутри VPC или через bastion/VPN. Например, с `web`:

```bash
ssh ubuntu@<worker_private_ip>
```

Для этого заранее добавьте свой публичный SSH-ключ в metadata ВМ (например, через `ssh-keys`) либо настройте другой безопасный способ доступа. В текущем учебном шаблоне SSH-ключ пользователя намеренно не зашит.

## Проверка cloud-init

На `web`:

```bash
sudo cloud-init status --wait
sudo docker ps
curl http://localhost:8080
```

На `worker`:

```bash
sudo cloud-init status --wait
tail -f /var/log/worker.log
```

## Удаление ресурсов

```bash
terraform destroy
```

Команда удалит созданные Terraform ресурсы. Перед подтверждением проверьте план удаления.

## Важные замечания

- Состояние Terraform (`terraform.tfstate`) может содержать чувствительные данные. Не добавляйте его в Git.
- Не коммитьте `.tfvars`, ключи, IAM-токены и другие секреты.
- В этом задании используются публичный Ubuntu 22.04 LTS image family и платформа `standard-v3`. Доступность конкретных платформ и ресурсов зависит от квот и возможностей выбранной зоны.
- При первом запуске cloud-init потребуется доступ ВМ к репозиториям Ubuntu и Docker registry. У `web` он обеспечивается NAT; у `worker` NAT отключён, поэтому установка пакетов через интернет может не пройти. Для гарантированной установки Python на worker используйте образ, где Python уже установлен, либо предусмотрите NAT Gateway/зеркало пакетов. Требование `nat = false` при этом сохраняется.

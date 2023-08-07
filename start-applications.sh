az login --identity --allow-no-subscriptions

keycloak_admin_username=$(az keyvault secret show --name keycloakAdminUsername --vault-name budget-sandbox-vault --query "value")
keycloak_admin_username="${keycloak_admin_username%\"}"
keycloak_admin_username="${keycloak_admin_username#\"}"

keycloak_admin_password=$(az keyvault secret show --name keycloakAdminPassword --vault-name budget-sandbox-vault --query "value")
keycloak_admin_password="${keycloak_admin_password%\"}"
keycloak_admin_password="${keycloak_admin_password#\"}"

keycloak_database_username=$(az keyvault secret show --name keycloakDatabaseUsername --vault-name budget-sandbox-vault --query "value")
keycloak_database_username="${keycloak_database_username%\"}"
keycloak_database_username="${keycloak_database_username#\"}"

keycloak_database_password=$(az keyvault secret show --name keycloakDatabasePassword --vault-name budget-sandbox-vault --query "value")
keycloak_database_password="${keycloak_database_password%\"}"
keycloak_database_password="${keycloak_database_password#\"}"

api_database_username=$(az keyvault secret show --name apiDatabaseUsername --vault-name budget-sandbox-vault --query "value")
api_database_username="${api_database_username%\"}"
api_database_username="${api_database_username#\"}"

api_database_password=$(az keyvault secret show --name apiDatabasePassword --vault-name budget-sandbox-vault --query "value")
api_database_password="${api_database_password%\"}"
api_database_password="${api_database_password#\"}"

api_database_connection=$(az keyvault secret show --name apiDatabaseConnection --vault-name budget-sandbox-vault --query "value")
api_database_connection="${api_database_connection%\"}"
api_database_connection="${api_database_connection#\"}"

api_client_secret=$(az keyvault secret show --name apiClientSecret --vault-name budget-sandbox-vault --query "value")
api_client_secret="${api_client_secret%\"}"
api_client_secret="${api_client_secret#\"}"

keycloak_smtp_username=$(az keyvault secret show --name keycloakSmtpUsername --vault-name budget-sandbox-vault --query "value")
keycloak_smtp_username="${keycloak_smtp_username%\"}"
keycloak_smtp_username="${keycloak_smtp_username#\"}"

keycloak_smtp_password=$(az keyvault secret show --name keycloakSmtpPassword --vault-name budget-sandbox-vault --query "value")
keycloak_smtp_password="${keycloak_smtp_password%\"}"
keycloak_smtp_password="${keycloak_smtp_password#\"}"

test_user_username=$(az keyvault secret show --name testUserUsername --vault-name budget-sandbox-vault --query "value")
test_user_username="${test_user_username%\"}"
test_user_username="${test_user_username#\"}"

test_user_password=$(az keyvault secret show --name testUserPassword --vault-name budget-sandbox-vault --query "value")
test_user_password="${test_user_password%\"}"
test_user_password="${test_user_password#\"}"

test_user_email=$(az keyvault secret show --name testUserEmail --vault-name budget-sandbox-vault --query "value")
test_user_email="${test_user_email%\"}"
test_user_email="${test_user_email#\"}"

cd /datadrive/repos/keycloak-budget-sandbox

cat > .env <<EOF
KEYCLOAK_USER=$keycloak_admin_username
KEYCLOAK_PASSWORD=$keycloak_admin_password
POSTGRES_USERNAME=$keycloak_database_username
POSTGRES_PASSWORD=$keycloak_database_password
EOF

sudo git pull
sudo docker compose -f docker-compose-production.yml up --build -d

cd /datadrive/repos/budget-sandbox-api

cat > .env <<EOF
Keycloak__ClientSecret=$api_client_secret
PostgresDatabaseConnection=$api_database_connection
PostgressUsername=$api_database_username
PostgressPassword=$api_database_password
EOF

sudo git pull
sudo docker compose -f docker-compose-production.yml up --build -d

cd /datadrive/repos/budget-sandbox-web
sudo git pull
sudo docker compose up --build -d

cd /datadrive/repos/budget-sandbox-proxy
sudo git pull
sudo docker compose up --build -d

sudo docker exec -i keycloak-budget-sandbox-keycloak_web-1 /bin/sh -s \
    keycloak_admin_username="$keycloak_admin_username" \
    keycloak_admin_password="$keycloak_admin_password" \
    keycloak_smtp_username="$keycloak_smtp_username" \
    keycloak_smtp_password="$keycloak_smtp_password" \
    api_client_secret="$api_client_secret" \
    test_user_username="$test_user_username" \
    test_user_password="$test_user_password" \
    test_user_email="$test_user_email" \
    < $(dirname "$0")/keycloak-init.sh
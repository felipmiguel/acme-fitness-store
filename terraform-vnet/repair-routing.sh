readonly PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
readonly APPS_ROOT="${PROJECT_ROOT}/apps"

readonly REDIS_NAME="fitness-cache"
readonly ORDER_SERVICE_POSTGRES_CONNECTION="order_service_db"
readonly CART_SERVICE_REDIS_CONNECTION="cart_service_cache"
readonly CATALOG_SERVICE_DB_CONNECTION="catalog_service_db"
readonly ACMEFIT_CATALOG_DB_NAME="psqlfdb-fitness-store-prod-vnet-dev"
readonly ACMEFIT_ORDER_DB_NAME="acmefit_order"
readonly ACMEFIT_POSTGRES_DB_USER=dbadmin
readonly ACMEFIT_POSTGRES_SERVER="psqlf-fitness-store-prod-vnet-dev"
readonly ORDER_DB_NAME="orders"
readonly CART_SERVICE="cart-service"
readonly IDENTITY_SERVICE="identity-service"
readonly ORDER_SERVICE="order-service"
readonly PAYMENT_SERVICE="payment-service"
readonly CATALOG_SERVICE="catalog-service"
readonly CATALOG_SERVICE1="catalog-service-1"
readonly CATALOG_SERVICE2="catalog-service-2"
readonly CATALOG_SERVICE3="catalog-service-3"
readonly CATALOG_SERVICE_COSMOS="catalog-service-cosmos"
readonly CATALOG_SERVICE_COSMOS2="catalog-service-cosmos2"
readonly FRONTEND_APP="frontend"
readonly CUSTOM_BUILDER="no-bindings-builder"

RESOURCE_GROUP='Fitness-Store-Prod-VNET'
SPRING_APPS_SERVICE='fitness-store-prod-vnet'
REGION='eastus'

function deploy_terraform() {
    terraform init
    terraform apply -auto-approve
}

function configure_acs() {
    echo "Configuring Application Configuration Service to use repo: https://github.com/Azure-Samples/acme-fitness-store-config"
    az spring application-configuration-service git repo add --name acme-config --label Azure --patterns "catalog/default,catalog/key-vault,identity/default,identity/key-vault,payment/default" --uri "https://github.com/Azure-Samples/acme-fitness-store-config"
}

function repair_cart_service() {
    echo "Creating cart-service app"
    az spring gateway route-config update --name $CART_SERVICE --app-name $CART_SERVICE --routes-file "$PROJECT_ROOT/azure/routes/cart-service.json"
}

function repair_identity_service() {
    echo "Creating identity service"
    az spring application-configuration-service bind --app $IDENTITY_SERVICE
    az spring gateway route-config update --name $IDENTITY_SERVICE --app-name $IDENTITY_SERVICE --routes-file "$PROJECT_ROOT/azure/routes/identity-service.json"
}

function repair_order_service() {
    echo "Creating order service"
    az spring gateway route-config update --name $ORDER_SERVICE --app-name $ORDER_SERVICE --routes-file "$PROJECT_ROOT/azure/routes/order-service.json"
}

function repair_catalog_service() {
    echo "Repairing catalog service"
    az spring application-configuration-service bind --app $CATALOG_SERVICE
    az spring service-registry bind --app $CATALOG_SERVICE
    az spring gateway route-config update --name $CATALOG_SERVICE --app-name $CATALOG_SERVICE --routes-file "$PROJECT_ROOT/azure/routes/catalog-service.json"
}


function repair_catalog_cosmos_service() {
    echo "Repairing catalog cosmos service"
    az spring application-configuration-service bind --app $CATALOG_SERVICE_COSMOS
    az spring service-registry bind --app $CATALOG_SERVICE_COSMOS
}

function repair_payment_service() {
    echo "Creating payment service"
    az spring application-configuration-service bind --app $PAYMENT_SERVICE
    az spring service-registry bind --app $PAYMENT_SERVICE
}

function repair_frontend_app() {
    echo "Creating frontend"
    az spring gateway route-config update --name $FRONTEND_APP --app-name $FRONTEND_APP --routes-file "$PROJECT_ROOT/azure/routes/frontend.json"
}

function deploy_cart_service() {
    echo "Deploying cart-service application"
    local redis_conn_str=$(az spring connection show -g $RESOURCE_GROUP \
        --service $SPRING_APPS_SERVICE \
        --deployment default \
        --app $CART_SERVICE \
        --connection $CART_SERVICE_REDIS_CONNECTION | jq -r '.configurations[0].value')
    local gateway_url=$(az spring gateway show | jq -r '.properties.url')
    local app_insights_key=$(az spring build-service builder buildpack-binding show -n default | jq -r '.properties.launchProperties.properties."connection-string"')

    az spring app deploy --name $CART_SERVICE \
        --builder $CUSTOM_BUILDER \
        --env "CART_PORT=8080" "REDIS_CONNECTIONSTRING=$redis_conn_str" "AUTH_URL=https://${gateway_url}" "INSTRUMENTATION_KEY=$app_insights_key" \
        --source-path "$APPS_ROOT/acme-cart"
}

function deploy_identity_service() {
    echo "Deploying identity-service application"
    az spring app deploy --name $IDENTITY_SERVICE \
        --env "SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_JWK_SET_URI=${JWK_SET_URI}" \
        --config-file-pattern identity \
        --build-env BP_JVM_VERSION=17.* \
        --source-path "$APPS_ROOT/acme-identity"
}

function deploy_order_service() {
    echo "Deploying user-service application"
    local gateway_url=$(az spring gateway show | jq -r '.properties.url')
    # local postgres_connection_url=$(az spring connection show -g $RESOURCE_GROUP \
    #     --service $SPRING_APPS_SERVICE \
    #     --deployment default \
    #     --connection $ORDER_SERVICE_POSTGRES_CONNECTION \
    #     --app $ORDER_SERVICE | jq '.configurations[0].value' -r)
    local app_insights_key=$(az spring build-service builder buildpack-binding show -n default | jq -r '.properties.launchProperties.properties."connection-string"')

    az spring app deploy --name $ORDER_SERVICE \
        --builder $CUSTOM_BUILDER \
        --env "ConnectionStrings__OrderContext=$POSTGRESQL_CONNSTRING_DOTNET" "AcmeServiceSettings__AuthUrl=https://${gateway_url}" "ApplicationInsights__ConnectionString=$app_insights_key" \
        --source-path "$APPS_ROOT/acme-order"
}

function deploy_catalog_service() {
    echo "Deploying catalog-service application"

    az spring app deploy --name $CATALOG_SERVICE \
        --config-file-pattern catalog/default \
        --source-path "$APPS_ROOT/acme-catalog" \
        --build-env BP_JVM_VERSION=17.* \
        --env "SPRING_DATASOURCE_AZURE_PASSWORDLESSENABLED=true"
}

function deploy_catalog_service_1() {
    echo "Deploying catalog-service application 1"

    az spring app deploy --name $CATALOG_SERVICE_1 \
        --config-file-pattern catalog/default \
        --source-path "$APPS_ROOT/acme-catalog" \
        --build-env BP_JVM_VERSION=17.* \
        --env "SPRING_DATASOURCE_AZURE_PASSWORDLESSENABLED=true"
}


function deploy_catalog_service_2() {
    echo "Deploying catalog-service application 2"

    az spring app deploy --name $CATALOG_SERVICE_2 \
        --config-file-pattern catalog/default \
        --source-path "$APPS_ROOT/acme-catalog" \
        --build-env BP_JVM_VERSION=17.* \
        --env "SPRING_DATASOURCE_AZURE_PASSWORDLESSENABLED=true"
}


function deploy_catalog_service_3() {
    echo "Deploying catalog-service application"

    az spring app deploy --name $CATALOG_SERVICE_2 \
        --config-file-pattern catalog/default \
        --source-path "$APPS_ROOT/acme-catalog" \
        --build-env BP_JVM_VERSION=17.* \
        --env "SPRING_DATASOURCE_AZURE_PASSWORDLESSENABLED=true"
}




function deploy_catalog_service_cosmos() {
    echo "Deploying catalog-service-cosmos application"

    az spring app deploy --name $CATALOG_SERVICE_COSMOS \
        --config-file-pattern catalog/default \
        --source-path "$APPS_ROOT/acme-catalog-cosmos" \
        --build-env BP_JVM_VERSION=17.*
}

function deploy_catalog_service_cosmos2() {
    echo "Deploying catalog-service-cosmos application"

    az spring app deploy --name $CATALOG_SERVICE_COSMOS2 \
        --config-file-pattern catalog/default \
        --source-path "$APPS_ROOT/acme-catalog-cosmos" \
        --build-env BP_JVM_VERSION=17.*
}

function deploy_payment_service() {
    echo "Deploying payment-service application"

    az spring app deploy --name $PAYMENT_SERVICE \
        --config-file-pattern payment \
        --build-env BP_JVM_VERSION=17.* \
        --source-path "$APPS_ROOT/acme-payment"
}

function deploy_frontend_app() {
    echo "Deploying frontend application"
    local app_insights_key=$(az spring build-service builder buildpack-binding show -n default | jq -r '.properties.launchProperties.properties."connection-string"')

    rm -rf "$APPS_ROOT/acme-shopping/node_modules"
    az spring app deploy --name $FRONTEND_APP \
        --builder $CUSTOM_BUILDER \
        --env "APPLICATIONINSIGHTS_CONNECTION_STRING=$app_insights_key" \
        --source-path "$APPS_ROOT/acme-shopping"
}

function configure_defaults() {
    echo "Configure azure defaults resource group: $RESOURCE_GROUP and spring $SPRING_APPS_SERVICE"
    az configure --defaults group=$RESOURCE_GROUP spring=$SPRING_APPS_SERVICE location=${REGION}
}

function configure_gateway() {
    az spring gateway update --assign-endpoint true
    az spring gateway show
    local gateway_url=$(az spring gateway show --query 'properties.url' --output tsv)
    AZURE_AD_APP_NAME="acme-shopping-gateway-${RANDOM}"
    echo "Creating Azure AD app: ${AZURE_AD_APP_NAME}"
    CLIENT_ID=$(az ad app create --display-name $AZURE_AD_APP_NAME --web-redirect-uris "https://${gateway_url}/login/oauth2/code/azure" "https://${gateway_url}/login/oauth2/code/sso" --output tsv --query appId)
    echo "Created Azure AD app with ID: ${CLIENT_ID}"
    CLIENT_SECRET=$(az ad app credential reset --id ${CLIENT_ID} --append --output tsv --query password)
    echo "Created Azure AD app secret: ${CLIENT_SECRET}"
    az ad sp create --id ${CLIENT_ID}

    echo "Configuring Spring Cloud Gateway"
    az spring gateway update \
        --api-description "ACME Fitness API" \
        --api-title "ACME Fitness" \
        --api-version "v.01" \
        --server-url "https://$gateway_url" \
        --allowed-origins "*" \
        --client-id ${CLIENT_ID} \
        --client-secret ${CLIENT_SECRET} \
        --scope "openid,profile" \
        --issuer-uri ${ISSUER_URI}
}

function repair_all() {
    repair_identity_service &
    repair_cart_service &
    repair_order_service &
    repair_payment_service &
    repair_catalog_service &
    repair_catalog_cosmos_service &
    repair_frontend_app &
    wait
}

function deploy_all() {
    deploy_frontend_app &
    deploy_identity_service &
    deploy_cart_service &
    deploy_order_service &
    deploy_payment_service &
    deploy_catalog_service &
    deploy_catalog_service_cosmos &
    deploy_catalog_service_cosmos2 &
    wait
}

function retrieve_parameters() {
    POSTGRESQL_FQDN=$(terraform output -raw postgresql_fqdn)
    POSTGRESQL_USERNAME=$(terraform output -raw postgresql_user)
    POSTGRESQL_PASSWORD=$(terraform output -raw postgresql_password)
    POSTGRESQL_DATABASE=$(terraform output -raw postgresql_database)
    POSTGRESQL_CONNSTRING_DOTNET="Server=${POSTGRESQL_FQDN};Port=5432;Database=${POSTGRESQL_DATABASE};User Id=${POSTGRESQL_USERNAME};Password=${POSTGRESQL_PASSWORD};Ssl Mode=Require;"
    
    ISSUER_URI="https://login.microsoftonline.com/72f988bf-86f1-41af-91ab-2d7cd011db47/v2.0"
    JWK_SET_URI=https://login.microsoftonline.com/72f988bf-86f1-41af-91ab-2d7cd011db47/discovery/v2.0/keys
}

function main() {
    retrieve_parameters
    configure_defaults
    # repair_all    
    # configure_gateway
    deploy_all
}

main

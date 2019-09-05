printf "\n*** Creating the MongoDB Virtual Machine ***\n"

sed -i -e "s/REPLACEDROPUSERNAME/${USERNAME}/g" mongoconfigure.sh
sed -i -e "s/REPLACECREATEUSERNAME/${USERNAME}/g" mongoconfigure.sh
sed -i -e "s/REPLACEPASSWORD/${PASSWORD}/g" mongoconfigure.sh
sed -i -e "s/MONGO_IP_ADDRESS/${MONGO_IP_ADDRESS}/g" postprocess.sh

MONGODB_CONNECTION_STRING="mongodb://${USERNAME}:${PASSWORD}@${MONGO_IP_ADDRESS}:27017/tailwind"

printf "\n\n*** Configuring Product Service app settings ***\n"
az webapp config appsettings set -n $PRODUCT_SERVICE_NAME -g $RESOURCE_GROUP_NAME --settings "DB_CONNECTION_STRING=$MONGODB_CONNECTION_STRING" COLLECTION_NAME=inventory SEED_DATA=true

printf "\n\n*** Retrieving backend URLs ***\n"
PRODUCT_SERVICE_BASE_URL="https://$(az webapp show -n $PRODUCT_SERVICE_NAME -g $RESOURCE_GROUP_NAME --query defaultHostName -o tsv)/"
printf "\n$PRODUCT_SERVICE_BASE_URL\n"

printf "\n\n*** Configuring Frontend app settings ***\n"
az webapp config appsettings set -n $FRONTEND_NAME -g $RESOURCE_GROUP_NAME --settings "PRODUCT_SERVICE_BASE_URL=$PRODUCT_SERVICE_BASE_URL"

printf "\n\n*** Creating the SQL Manage Instance virtual network***\n\n"
az network vnet create -g $RESOURCE_GROUP_NAME -n $SQL_MI_VNET_NAME \
    --address-prefix 10.0.0.0/16 \
    --subnet-name $SQL_MI_SUBNET_NAME \
    --subnet-prefix 10.0.0.0/24

SQL_DMS_SUBNET_NAME=dms

printf "\n\n*** Configuring the Frontend to point at the Inventory Service VM***\n\n"
az webapp config appsettings set -n $FRONTEND_NAME -g $RESOURCE_GROUP_NAME --settings "INVENTORY_SERVICE_BASE_URL=http://$INVENTORY_VM_IP_ADDRESS:8080"
sed -i -e "s/INVENTORY_VM_IP_ADDRESS/${INVENTORY_VM_IP_ADDRESS}/g" inventorypostprocess.sh

printf "\n\n *** Configuring the post-processing Inventory VM script ***\n\n"
sed -i -e "s/REPLACE_CONTAINER_REGISTRY_USERNAME/${ACR_USERNAME}/g" inventoryvmconfigure.sh
sed -i -e 's/REPLACE_CONTAINER_REGISTRY_PASSWORD/${ACR_PASSWORD}/g' inventoryvmconfigure.sh
sed -i -e "s/REPLACE_CONTAINER_REGISTRY_SERVER/${ACR_SERVER}/g" inventoryvmconfigure.sh
sed -i -e "s/REPLACE_INVENTORY_IMAGE_NAME/${INVENTORY_SERVICE_IMAGE}/g" inventoryvmconfigure.sh
sed -i -e "s/REPLACE_SQL_IP/${SQL2012_VM_IP_ADDRESS}/g" inventoryvmconfigure.sh
sed -i -e "s/REPLACE_SQL_USERNAME/${USERNAME}/g" inventoryvmconfigure.sh
sed -i -e "s/REPLACE_SQL_PASSWORD/${PASSWORD}/g" inventoryvmconfigure.sh

# chmod +x postprocess.sh
sh postprocess.sh

# chmod +x inventorypostprocess.sh
sh inventorypostprocess.sh
#!/bin/bash

service_principal_name=$1
subscription_id=$2

# Replace this with the actual command that generates the JSON output
json_output=$(az ad sp create-for-rbac --name $service_principal_name --role Contributor --scopes /subscriptions/$subscription_id)

# Parse JSON using jq and set Azure subscription details
ARM_SUBSCRIPTION_ID=$subscription_id
ARM_TENANT_ID=$(echo "$json_output" | jq -r '.tenant')
ARM_CLIENT_ID=$(echo "$json_output" | jq -r '.appId')
ARM_CLIENT_SECRET=$(echo "$json_output" | jq -r '.password')

# Print the extracted values (optional)
echo "ARM_SUBSCRIPTION_ID: $ARM_SUBSCRIPTION_ID"
echo "ARM_TENANT_ID: $ARM_TENANT_ID"
echo "ARM_CLIENT_ID: $ARM_CLIENT_ID"
echo "ARM_CLIENT_SECRET: $ARM_CLIENT_SECRET"

# Now you can use these variables as needed in your script or export them to your environment
export ARM_SUBSCRIPTION_ID
export ARM_TENANT_ID
export ARM_CLIENT_ID
export ARM_CLIENT_SECRET

# Append or update these exports in your ~/.bashrc
if grep -q "export ARM_SUBSCRIPTION_ID=" ~/.bashrc; then
    # Update existing values
    sed -i "s/export ARM_SUBSCRIPTION_ID=\"[^\"]*\"/export ARM_SUBSCRIPTION_ID=\"$ARM_SUBSCRIPTION_ID\"/" ~/.bashrc
    sed -i "s/export ARM_TENANT_ID=\"[^\"]*\"/export ARM_TENANT_ID=\"$ARM_TENANT_ID\"/" ~/.bashrc
    sed -i "s/export ARM_CLIENT_ID=\"[^\"]*\"/export ARM_CLIENT_ID=\"$ARM_CLIENT_ID\"/" ~/.bashrc
    sed -i "s/export ARM_CLIENT_SECRET=\"[^\"]*\"/export ARM_CLIENT_SECRET=\"$ARM_CLIENT_SECRET\"/" ~/.bashrc
else
    # Append new values
    echo "export ARM_SUBSCRIPTION_ID=\"$ARM_SUBSCRIPTION_ID\"" >> ~/.bashrc
    echo "export ARM_TENANT_ID=\"$ARM_TENANT_ID\"" >> ~/.bashrc
    echo "export ARM_CLIENT_ID=\"$ARM_CLIENT_ID\"" >> ~/.bashrc
    echo "export ARM_CLIENT_SECRET=\"$ARM_CLIENT_SECRET\"" >> ~/.bashrc
fi
# Source the updated ~/.bashrc
. ~/.bashrc

echo "Azure subscription details set successfully."

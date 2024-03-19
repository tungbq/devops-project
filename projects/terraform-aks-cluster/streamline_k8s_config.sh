#!/bin/bash

# Replace 'your_file.yaml' with the actual name of your YAML file
yaml_file=$1

# Remove "<<EOT" at the beginning and "EOT" at the end using sed
sed -i '/<<EOT/d' "$yaml_file"
sed -i '$s/^EOT$//' "$yaml_file"

echo "Removed << EOT at the beginning and EOT at the end from $yaml_file."

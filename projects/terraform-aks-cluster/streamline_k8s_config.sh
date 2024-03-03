#!/bin/bash

# Replace 'your_file.yaml' with the actual name of your YAML file
yaml_file=$1

# Check if the file contains "<< EOT" at the beginning and "EOT" at the end
if [[ $(head -n 1 "$yaml_file") == "<< EOT" && $(tail -n 1 "$yaml_file") == "EOT" ]]; then
  # Remove "<< EOT" at the beginning and "EOT" at the end using sed
  sed -i '1s/^<< EOT$//' "$yaml_file"
  sed -i '$s/^EOT$//' "$yaml_file"

  echo "Removed << EOT at the beginning and EOT at the end from $yaml_file."
else
  echo "No << EOT at the beginning and EOT at the end found in $yaml_file. No changes made."
fi

#!/bin/bash

input_file="../../.github/aztfplan.json"

for value in "$@"; do
    sed -i -e "s/\"$value\": *\"[^\"]*\"/\"$value\": \"***\"/g" "$input_file"
done

#!/bin/bash

input_file="../.github/tfplan.json"

for value in "$@"; do
    sed -i "s/$value/***/g" "$input_file"
done

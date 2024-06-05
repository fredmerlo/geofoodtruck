#!/bin/bash

# values=(
#     "900357929763"
#     "E263E8AHYXLO8L"
#     "Z2FDTNDATAQYW2"
#     "GrXGgigVGyUzWjE0ppVRMRUgR"
#     "EOBBYJPMYN9AX"
#     "37f7809b-ea93-46f1-9d10-4050e2957f36"
#     "AROA5DIMDXMR6ITLNBKXN"
#     "6c1ead8a-5e71-4e33-ae37-010dbcd3c063"
# )

values=(
    "900357929763"
    "GrXGgigVGyUzWjE0ppVRMRUgR"
)

input_file="../.github/tfplan.json"

for value in "${values[@]}"; do
    sed -i "s/$value/***/g" "$input_file"
done

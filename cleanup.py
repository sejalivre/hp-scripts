#!/usr/bin/env python3
import os

script_dir = "/home/engine/project/scripts"
update_file = os.path.join(script_dir, "update.ps1")

if os.path.exists(update_file):
    os.remove(update_file)
    print(f"Arquivo {update_file} removido com sucesso")
else:
    print(f"Arquivo {update_file} não existe")

# Listar arquivos restantes
print("\nArquivos update*.ps1 restantes:")
for f in os.listdir(script_dir):
    if f.startswith("update") and f.endswith(".ps1"):
        print(f"  {f}")
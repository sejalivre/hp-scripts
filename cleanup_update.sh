#!/bin/bash
cd /home/engine/project/scripts
echo "Arquivos antes da limpeza:"
ls -la update*.ps1
echo ""
rm -f update.ps1
echo "Arquivos após a limpeza:"
ls -la update*.ps1
echo ""
echo "Finalizado!"
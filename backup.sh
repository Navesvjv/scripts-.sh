#!/bin/bash

path_root=/mnt/backup
path_destino=${path_root}/lvm01

# Verifica se o path_root existe.
if [ ! -d "$path_root" ]
then
    clear
    echo -e "\nPath_root não existe.\n"
    exit 1
fi

# Verifica se o path_destino existe.
if [ ! -d "$path_destino" ]
then
    clear
    echo -e "\nPath_destino não existe.\n"
    exit 1
fi

freeSizeDiskDest=$(df -h --output=source,avail | grep $path_destino | tr -s " " | cut -d" " -f2)

clear

Cabecalho(){
    livre=$(df -h | grep $path_destino | tr -s " " | cut -d" " -f4)
    usado=$(df -h | grep $path_destino | tr -s " " | cut -d" " -f3)
    total=$(df -h | grep $path_destino | tr -s " " | cut -d" " -f2)

    echo
    echo "========================= Disco Destino ========================="
    echo
    echo "caminho                  livre           usado           total"
    echo "$path_destino            $livre          $usado          $total"
    echo
    echo "================================================================="
    echo
}

DevicesUSB(){
    devUSB=$(lsblk -o name,tran | grep usb | cut -d" " -f1)
    if [ -z "$devUSB" ] # Se não encontrar dispositivo USB, sai do programa
    then
        clear
        echo -e "\nNão foi encontrado nenhum dispositivo USB.\n"
        exit 1
    fi
    declare -A array_usb
    count=1
    for i in $devUSB # Mostra todos os dispositivos USB encontrados
    do
        modelo=$(lsblk -d -o name,model | grep $i | tr -s " " | cut -d" " -f2)
        tamanho=$(lsblk -d -o name,size | grep $i | tr -s " " | cut -d" " -f2)
        echo "Disco ($count):   /dev/$i     $modelo     $tamanho"
        array_usb["$count"]="$i"
        count=$(expr $count + 1)
    done
    
    w=1
    while [ $w -eq 1 ]
    do
        echo
        read -n1 -p "Selecione o Disco Origem: " disk
        echo

        re='[0-9]'
        if [[ $disk == $re ]]
        then
            if [ $disk -gt 0 -a $disk -lt $count ]
            then
                w=0
            else
                echo "incorreto..."
            fi
        else
            echo "incorreto..."
        fi
    done

    disk_selected=${array_usb[$disk]}

    # Monta o disco selecionado, caso ele não esteja montado.
    df | grep $disk_selected > /dev/null
    if [ "$?" -eq 1 ] # verifica se o disco já esta montado
    then
        echo -e "Montando disco.."
        mkdir -p ${path_root}/${disk_selected}
        sudo mount /dev/${disk_selected}1 ${path_root}/${disk_selected}

        # verifica se o disco foi montado
        df | grep $disk_selected > /dev/null
        if [ "$?" -eq 1 ]
        then
            clear
            echo -e "Disco não foi montado..\n"
            exit 1
        fi
    fi

    # Pegar o caminho onde o disco ja esta montado
    path_origem=$(df | grep $disk_selected | tr -s " " | cut -d" " -f6)
}

DadosEmpresa(){
    echo
    read -p "Nome da Empresa:       " nome_empresa
    read -p "Nome do computador:    " nome_pc
    read -p "Numero OS:             " numero_os
    echo
}

StartBackup(){
    clear
    date_now="$(date +%d-%m-%Y_%H-%M-%S)"
    folder_backup=${path_destino}/${nome_empresa}_${nome_pc}_${numero_os}_${date_now}
    mkdir -p $folder_backup

    echo "========================= Backup ========================="
    echo
    echo "Empresa:       $nome_empresa"
    echo "PC:            $nome_pc"
    echo "OS:            $numero_os"
    echo
    echo "Salvo em:      $folder_backup"
    echo
    echo "=========================================================="
    echo

    echo -e "$date_now ==> Backup iniciado ...\n"
    rsync -r $path_origem $folder_backup
    date_now="$(date +%d-%m-%Y_%H-%M-%S)"
    echo -e "$date_now ==> Backup concluido!\n"
}

Cabecalho
DevicesUSB
DadosEmpresa
StartBackup
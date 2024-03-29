#!/bin/bash

# Esta linea la pongo para que se me ejecute el script en modo desarrollador
set -e

are_usuarios=0
usuarios=""
bool_device_files=0
bool_sopen=0
bool_sdevice=0
bool_inv=0

sort_method="sort -u"

lines=""

function print_header() {
  info="Filesistem Dispositive_name Storage Mount_on Total_Used Stat_Lower Stat_Higher"       
  if [ $bool_device_files -eq 1 ]; then
    if [ $are_usuarios -eq 1 ]; then
      info+=" Device_files Users"
      echo "||---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------||"
      header=$(printf "||%-30s |%-25s |%-25s |%-25s |%-25s |%-25s |%-25s |%-15s |%-25s ||\n" $info)
      echo "$header"
      echo "||---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------||"
    else 
      info+=" Device_files"
      echo "||------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------||"
      header=$(printf "||%-30s |%-25s |%-25s |%-25s |%-25s |%-25s |%-25s |%-15s ||\n" $info)
      echo "$header"
      echo "||------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------||"
    fi
  else
    if [ $are_usuarios -eq 1 ]; then
      echo "||----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------||"
      header=$(printf "||%-30s |%-25s |%-25s |%-25s |%-25s |%-25s |%-25s |%-25s ||\n" $info "Users")
      echo "$header"
      echo "||----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------||"
    else
      echo "||-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------||"
      header=$(printf "||%-30s |%-25s |%-25s |%-25s |%-25s |%-25s |%-25s ||\n" $info)
      echo "$header"
      echo "||-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------||"
    fi
  fi
}

function print_table() {
  if [ $bool_device_files -eq 1 ]; then
    if [ $are_usuarios -eq 1 ]; then
      line=$(printf "||%-30s |%-25s |%-25s |%-25s |%-25s |%-25s |%-25s |%-15s |%-25s ||\n" $lines)
      echo "$line"
      echo "||---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------||"
    else 
      line=$(printf "||%-30s |%-25s |%-25s |%-25s |%-25s |%-25s |%-25s |%-15s ||\n" $lines)
      echo "$line"
      echo "||------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------||"
    fi
  else
    if [ $are_usuarios -eq 1 ]; then
      line=$(printf "||%-30s |%-25s |%-25s |%-25s |%-25s |%-25s |%-25s |%-25s ||\n" $lines)
      echo "$line"
      echo "||----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------||"
    else 
      line=$(printf "||%-30s |%-25s |%-25s |%-25s |%-25s |%-25s |%-25s ||\n" $lines)
      echo "$line"
      echo "||-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------||"
    fi
  fi
}

function system_info() {
  if [ $bool_inv -eq 1 ]; then
    # Añadimos el -r para que ordene de forma inversa
    sort_method+=" -r"
  fi
  # Tipos es el tipo de sistema de archivos
  tipos=$(cat /proc/mounts | cut -d  ' ' -f3 | ${sort_method})
  tabla=""
  for tipo in $tipos; do
    line=$tipo
    line+=" "
    line+=$(df -a -t $tipo | tr -s ' ' | tail -n +2 | sort -k3 -n | tail -n -1 | cut -d ' ' -f 1,3,6)
    total_used=$(df -a -t $tipo | awk 'BEGIN {total=0} {total = total + $3} END {print total}')
    dispositive=$(df -a -t $tipo | tr -s ' ' | sort -k3 -n | tail -n -1 | cut -d ' ' -f 1)
    if [ $bool_device_files -eq 1 ]; then
      if [ -e $dispositive ]; then
        stat_lower=$(stat -c %t $dispositive)
        stat_higher=$(stat -c %T $dispositive)
        lsof_value=$(lsof -a $dispositive | tail -n +2 | wc -l)
        lines+="$line $total_used $stat_lower $stat_higher $lsof_value"
        if [ $are_usuarios -eq 1 ]; then
          variable=0
          for usuario in $usuarios; do
            variable=$((variable+$(lsof -a -u sernics /dev/sdc | tail -n +2 | wc -l)))
            lines+=" $lsof_value"
          done
        fi
        lines+=$'\n'
      fi
    else 
      if [ -e $dispositive ]; then
        stat_lower=$(stat -c %t $dispositive)
        stat_higher=$(stat -c %T $dispositive)
        lines+="$line $total_used $stat_lower $stat_higher"
        if [ $are_usuarios -eq 1 ]; then
          variable=0
          for usuario in $usuarios; do
            variable=$((variable+$(lsof -a -u sernics /dev/sdc | tail -n +2 | wc -l)))
          done
          lines+=" $variable"
        fi
      else 
        if [ $are_usuarios -eq 1 ]; then
          lines+="$line $total_used - - -"
        else
          lines+="$line $total_used - -"
        fi
      fi
      lines+=$'\n'
    fi
  done
}

function helper() {
  echo "Usage: cat [OPTION]..."
  echo "This script is to get information about our diferents partitions of the disk"
  echo "It is not necesary a FILE, but if you introduce a FILE you will get the output in the file (This will be in the future"
  echo ""
  echo "-inv       Print the inverse of the main output"
}

if [ $# -gt 0 ]; then
  while [ "$1" != "" ]; do
    case $1 in
      "-h" | "--help")
        helper
        shift
        ;;
      "-u")
        shift
        while [ "$1" != "" ]; do
          # Comprobar que el valor de $1 es un usuario
          if id "$1" >/dev/null 2>&1; then
            are_usuarios=1
            usuarios=$1
            usuarios+=" "
            # Implementar función para los usuarios
          else
            echo "The user $1 is not a valid user"
          fi
          shift
        done
        if [ $are_usuarios -eq 0 ]; then
          echo "You have to introduce at least one valid user"
          exit 1
        fi
        ;;
      "-inv" )
        bool_inv=1
        shift
        ;;
      "-devicefiles")
        bool_device_files=1
        shift
        ;;
      "-sopen")
        bool_sopen=1
        shift
        ;;
      "-sdevice")
        bool_sdevice=1
        shift
        ;;
      * )
        echo "You have introduced an invalid option"
        exit 1
        shift
        ;;
    esac
  done
fi
# Ejecución de las funciones necesarias
print_header
system_info
 if [ $bool_sdevice -eq 1 ]; then
  echo
fi
if [ $bool_sopen -eq 1 ]; then
  echo
fi
print_table

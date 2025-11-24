#!/usr/bin/env bash
# Projeto A3 – Shell Script – Butantã/2025-2
# Integrantes:
# Eric Próspero Viana de Souza (825143006)
# Ikaro Nascimento de Camargo (82519864)
# Vitor Enzo Rocha e Silva (82516568)
# Turma: Sistemas Computacionais e Segurança
# Professor: Nicolas Kassalias


clear_screen() { printf "\n\n"; }
press_enter() { read -rp "Pressione <ENTER> para voltar ao menu..." _; }

check_dir_access() {
  local dir="$1"
  if [[ ! -d "$dir" ]]; then
    echo "Erro: diretório não existe ou não é válido: $dir"
    return 1
  fi
  if [[ ! -r "$dir" || ! -x "$dir" ]]; then
    echo "Erro: sem permissão para acessar: $dir"
    return 1
  fi
  return 0
}

check_file_exists() {
  local file="$1"
  if [[ ! -e "$file" ]]; then
    echo "Erro: arquivo não existe: $file"
    return 1
  fi
  if [[ ! -f "$file" ]]; then
    echo "Erro: não é arquivo regular: $file"
    return 1
  fi
  return 0
}

opt1_count_files() {
  read -rp "Informe o caminho absoluto do diretório: " dir
  read -rp "Informe a string a procurar: " str
  check_dir_access "$dir" || { press_enter; return; }
  local count
  count=$(find "$dir" -maxdepth 1 -type f -iname "*${str}*" 2>/dev/null | wc -l)
  echo "Total de arquivos em '$dir' com '$str': $count"
  press_enter
}

opt2_change_perms() {
  read -rp "Informe o caminho absoluto do arquivo: " file
  check_file_exists "$file" || { press_enter; return; }
  read -rp "Informe a permissão em octal: " mode
  if [[ ! $mode =~ ^[0-7]{3,4}$ ]]; then
    echo "Formato inválido"
    press_enter
    return
  fi
  if chmod "$mode" "$file" 2>/dev/null; then
    echo "Permissões alteradas para $mode"
  else
    echo "Erro ao alterar permissões"
  fi
  press_enter
}

opt3_create_dir() {
  read -rp "Informe o caminho absoluto do diretório a criar: " dir
  if [[ -e "$dir" ]]; then
    if [[ -d "$dir" ]]; then echo "Diretório já existe"
    else echo "Existe um arquivo com esse nome"
    fi
    press_enter
    return
  fi
  if mkdir -p -- "$dir" 2>/dev/null; then
    echo "Diretório criado: $dir"
  else
    echo "Erro ao criar diretório"
  fi
  press_enter
}

opt4_show_file() {
  read -rp "Informe o caminho absoluto do arquivo: " file
  check_file_exists "$file" || { press_enter; return; }
  echo "---- Conteúdo de: $file ----"
  if command -v less >/dev/null 2>&1; then
    less "$file"
  else
    cat "$file"
    echo
    press_enter
  fi
}

opt5_sys_info() {
  echo "Memória RAM:"
  if command -v free >/dev/null 2>&1; then free -h
  else cat /proc/meminfo | head -n 5
  fi
  echo
  echo "CPU:"
  if command -v lscpu >/dev/null 2>&1; then
    lscpu | grep -E "^Model name|^Architecture" || true
  else
    grep -m1 "model name" /proc/cpuinfo || true
  fi
  echo
  echo "Disco:"
  df -h --total | awk 'NR==1 || /total/' || df -h
  press_enter
}

opt6_file_details() {
  read -rp "Informe o caminho absoluto do arquivo: " file
  check_file_exists "$file" || { press_enter; return; }
  stat "$file"
  echo
  ls -l -- "$file"
  press_enter
}

opt7_quick_backup() {
  read -rp "Informe o arquivo para backup: " file
  check_file_exists "$file" || { press_enter; return; }
  local dir name ts dest
  dir=$(dirname -- "$file")
  name=$(basename -- "$file")
  ts=$(date +"%Y%m%d%H%M%S")
  dest="$dir/${name}.bak.$ts"
  if cp -- "$file" "$dest" 2>/dev/null; then
    echo "Backup criado: $dest"
  else
    echo "Erro ao criar backup"
  fi
  press_enter
}

opt8_search_replace() {
  read -rp "Informe o diretório: " dir
  check_dir_access "$dir" || { press_enter; return; }
  read -rp "String a procurar: " old
  read -rp "String de substituição: " new
  read -rp "Confirmar substituição? (s/N): " c
  [[ $c =~ ^[sS] ]] || { echo "Cancelado"; press_enter; return; }
  find "$dir" -type f -exec sed -i.orig "s/${old//\//\\/}/${new//\//\\/}/g" {} + 2>/dev/null || true
  echo "Substituição concluída"
  press_enter
}

opt9_top_proc() {
  ps aux --sort=-%mem | awk 'NR<=10{printf("%s\t%s\t%s\n",$2,$4,$11)}' | column -t -s $'\t'
  echo
  read -rp "Encerrar PID (ou vazio para sair): " pid
  [[ -z "$pid" ]] && { press_enter; return; }
  if ! [[ $pid =~ ^[0-9]+$ ]]; then
    echo "PID inválido"
    press_enter
    return
  fi
  if kill -15 "$pid" 2>/dev/null; then echo "Processo encerrado"
  else echo "Erro ao encerrar"
  fi
  press_enter
}

opt10_exit() {
  echo "Encerrando"
  exit 0
}

main_menu() {
  while true; do
    clear
    cat <<'MENU'
Projeto A3 - Shell Script (Butantã/2025-2)
1) Contar arquivos
2) Alterar permissões
3) Criar diretório
4) Mostrar conteúdo de arquivo
5) Informações do sistema
6) Detalhes de arquivo
7) Backup rápido
8) Procurar e substituir
9) Top processos
10) Sair
MENU
    read -rp "Opção: " opt
    case $opt in
      1) opt1_count_files ;;
      2) opt2_change_perms ;;
      3) opt3_create_dir ;;
      4) opt4_show_file ;;
      5) opt5_sys_info ;;
      6) opt6_file_details ;;
      7) opt7_quick_backup ;;
      8) opt8_search_replace ;;
      9) opt9_top_proc ;;
      10) opt10_exit ;;
      *) echo "Opção inválida"; press_enter ;;
    esac
  done
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main_menu
fi

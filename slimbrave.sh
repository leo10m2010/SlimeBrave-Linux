#!/usr/bin/env bash

set -u

# -----------------------------------------------------------------------------
# Global state
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$SCRIPT_DIR/backups"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/slimbrave"
CONFIG_FILE="$CONFIG_DIR/config.env"

declare -a OPTION_IDS=()
declare -A OPT_CATEGORY=()
declare -A OPT_TITLE=()
declare -A OPT_KEY=()
declare -A OPT_JSON=()

declare -A ENABLED=()
declare -A ORIGINAL_ENABLED=()

DNS_MODE=""
DNS_TEMPLATES=""
ORIGINAL_DNS_MODE=""
ORIGINAL_DNS_TEMPLATES=""

POLICY_FILE=""

POLICY_CANDIDATES=(
  "/etc/brave/policies/managed/slimbrave.json"
  "/etc/brave-browser/policies/managed/slimbrave.json"
)

C_RESET=""
C_TITLE=""
C_ACCENT=""
C_SUB=""
C_OK=""
C_WARN=""
C_ERR=""
TRUECOLOR_ENABLED=0
ANIMATE_TITLE=1
UI_LANG="es"

if [[ "${SLIMBRAVE_ANIMATE:-1}" == "0" ]]; then
  ANIMATE_TITLE=0
fi

supports_utf8() {
  case "${LC_ALL:-${LANG:-}}" in
    *UTF-8*|*utf8*) return 0 ;;
    *) return 1 ;;
  esac
}

detect_default_language() {
  local lang
  lang=$(printf '%s' "${LC_ALL:-${LANG:-es}}" | tr '[:upper:]' '[:lower:]')
  case "$lang" in
    fr* ) UI_LANG="fr" ;;
    pt* ) UI_LANG="pt" ;;
    en* ) UI_LANG="en" ;;
    * ) UI_LANG="es" ;;
  esac
}

load_user_config() {
  if [[ ! -f "$CONFIG_FILE" ]]; then
    return
  fi

  while IFS='=' read -r key value; do
    [[ -z "${key:-}" ]] && continue
    case "$key" in
      UI_LANG)
        case "$value" in
          es|en|fr|pt) UI_LANG="$value" ;;
        esac
        ;;
    esac
  done < "$CONFIG_FILE"
}

save_user_config() {
  mkdir -p "$CONFIG_DIR"
  cat > "$CONFIG_FILE" <<EOF
UI_LANG=$UI_LANG
EOF
}

t() {
  local key="$1"
  case "${UI_LANG}:${key}" in
    es:press_enter) echo "Presiona Enter para continuar..." ;;
    en:press_enter) echo "Press Enter to continue..." ;;
    fr:press_enter) echo "Appuyez sur Entree pour continuer..." ;;
    pt:press_enter) echo "Pressione Enter para continuar..." ;;

    es:invalid_option) echo "Opcion invalida" ;;
    en:invalid_option) echo "Invalid option" ;;
    fr:invalid_option) echo "Option invalide" ;;
    pt:invalid_option) echo "Opcao invalida" ;;

    es:main_presets) echo "Presets rapidos" ;;
    en:main_presets) echo "Quick presets" ;;
    fr:main_presets) echo "Presets rapides" ;;
    pt:main_presets) echo "Presets rapidos" ;;

    es:main_manual) echo "Configuracion manual (toggle por toggle)" ;;
    en:main_manual) echo "Manual configuration (toggle by toggle)" ;;
    fr:main_manual) echo "Configuration manuelle (toggle par toggle)" ;;
    pt:main_manual) echo "Configuracao manual (toggle por toggle)" ;;

    es:main_pending) echo "Ver cambios pendientes" ;;
    en:main_pending) echo "View pending changes" ;;
    fr:main_pending) echo "Voir les changements en attente" ;;
    pt:main_pending) echo "Ver alteracoes pendentes" ;;

    es:main_backup) echo "Backup de politica actual" ;;
    en:main_backup) echo "Backup current policy" ;;
    fr:main_backup) echo "Sauvegarder la politique actuelle" ;;
    pt:main_backup) echo "Backup da politica atual" ;;

    es:main_restore) echo "Restaurar backup" ;;
    en:main_restore) echo "Restore backup" ;;
    fr:main_restore) echo "Restaurer sauvegarde" ;;
    pt:main_restore) echo "Restaurar backup" ;;

    es:main_reset) echo "Reset total (quitar slimbrave.json)" ;;
    en:main_reset) echo "Full reset (remove slimbrave.json)" ;;
    fr:main_reset) echo "Reset complet (supprimer slimbrave.json)" ;;
    pt:main_reset) echo "Reset total (remover slimbrave.json)" ;;

    es:main_status) echo "Estado actual" ;;
    en:main_status) echo "Current status" ;;
    fr:main_status) echo "Etat actuel" ;;
    pt:main_status) echo "Estado atual" ;;

    es:main_language) echo "Cambiar idioma" ;;
    en:main_language) echo "Change language" ;;
    fr:main_language) echo "Changer la langue" ;;
    pt:main_language) echo "Mudar idioma" ;;

    es:main_help) echo "Ayuda / Verificacion" ;;
    en:main_help) echo "Help / Verification" ;;
    fr:main_help) echo "Aide / Verification" ;;
    pt:main_help) echo "Ajuda / Verificacao" ;;

    es:main_exit) echo "Salir" ;;
    en:main_exit) echo "Exit" ;;
    fr:main_exit) echo "Quitter" ;;
    pt:main_exit) echo "Sair" ;;

    es:main_select) echo "Selecciona opcion: " ;;
    en:main_select) echo "Choose option: " ;;
    fr:main_select) echo "Choisissez une option: " ;;
    pt:main_select) echo "Escolha uma opcao: " ;;

    es:bye) echo "Hasta luego." ;;
    en:bye) echo "See you later." ;;
    fr:bye) echo "A bientot." ;;
    pt:bye) echo "Ate logo." ;;

    es:pending_short) echo "Pendientes" ;;
    en:pending_short) echo "Pending" ;;
    fr:pending_short) echo "En attente" ;;
    pt:pending_short) echo "Pendentes" ;;

    es:language_title) echo "Idioma / Language" ;;
    en:language_title) echo "Language" ;;
    fr:language_title) echo "Langue" ;;
    pt:language_title) echo "Idioma" ;;

    es:lang_changed) echo "Idioma actualizado." ;;
    en:lang_changed) echo "Language updated." ;;
    fr:lang_changed) echo "Langue mise a jour." ;;
    pt:lang_changed) echo "Idioma atualizado." ;;

    es:presets_title) echo "Presets rapidos" ;;
    en:presets_title) echo "Quick presets" ;;
    fr:presets_title) echo "Presets rapides" ;;
    pt:presets_title) echo "Presets rapidos" ;;

    es:recommended_tip) echo "Tip: Enter aplica balanced (recomendado)." ;;
    en:recommended_tip) echo "Tip: Enter applies balanced (recommended)." ;;
    fr:recommended_tip) echo "Astuce: Entree applique balanced (recommande)." ;;
    pt:recommended_tip) echo "Dica: Enter aplica balanced (recomendado)." ;;

    es:preset_prompt) echo "Selecciona preset [1]: " ;;
    en:preset_prompt) echo "Choose preset [1]: " ;;
    fr:preset_prompt) echo "Choisissez un preset [1]: " ;;
    pt:preset_prompt) echo "Escolha preset [1]: " ;;

    es:manual_title) echo "Configuracion manual" ;;
    en:manual_title) echo "Manual configuration" ;;
    fr:manual_title) echo "Configuration manuelle" ;;
    pt:manual_title) echo "Configuracao manual" ;;

    es:status_title_file) echo "Archivo de politica" ;;
    en:status_title_file) echo "Policy file" ;;
    fr:status_title_file) echo "Fichier de politique" ;;
    pt:status_title_file) echo "Arquivo de politica" ;;

    es:status_title_menu) echo "Configuracion en menu" ;;
    en:status_title_menu) echo "Menu configuration" ;;
    fr:status_title_menu) echo "Configuration du menu" ;;
    pt:status_title_menu) echo "Configuracao no menu" ;;

    es:status_title_sync) echo "Sincronizacion" ;;
    en:status_title_sync) echo "Synchronization" ;;
    fr:status_title_sync) echo "Synchronisation" ;;
    pt:status_title_sync) echo "Sincronizacao" ;;

    es:help_title) echo "Como usar:" ;;
    en:help_title) echo "How to use:" ;;
    fr:help_title) echo "Comment utiliser:" ;;
    pt:help_title) echo "Como usar:" ;;

    es:warn_no_policy_backup) echo "No hay politica actual para respaldar." ;;
    en:warn_no_policy_backup) echo "No current policy to back up." ;;
    fr:warn_no_policy_backup) echo "Aucune politique actuelle a sauvegarder." ;;
    pt:warn_no_policy_backup) echo "Nao ha politica atual para backup." ;;

    es:err_backup_create) echo "No se pudo crear backup de" ;;
    en:err_backup_create) echo "Could not create backup of" ;;
    fr:err_backup_create) echo "Impossible de creer une sauvegarde de" ;;
    pt:err_backup_create) echo "Nao foi possivel criar backup de" ;;

    es:ok_backup_created) echo "Backup creado:" ;;
    en:ok_backup_created) echo "Backup created:" ;;
    fr:ok_backup_created) echo "Sauvegarde creee:" ;;
    pt:ok_backup_created) echo "Backup criado:" ;;

    es:ok_applied_in) echo "Aplicado en:" ;;
    en:ok_applied_in) echo "Applied to:" ;;
    fr:ok_applied_in) echo "Applique a:" ;;
    pt:ok_applied_in) echo "Aplicado em:" ;;

    es:ok_done_verify) echo "Listo. Reinicia Brave y verifica en brave://policy" ;;
    en:ok_done_verify) echo "Done. Restart Brave and verify at brave://policy" ;;
    fr:ok_done_verify) echo "Termine. Redemarrez Brave et verifiez dans brave://policy" ;;
    pt:ok_done_verify) echo "Pronto. Reinicie o Brave e verifique em brave://policy" ;;

    es:warn_no_backups) echo "No hay backups en" ;;
    en:warn_no_backups) echo "No backups found in" ;;
    fr:warn_no_backups) echo "Aucune sauvegarde dans" ;;
    pt:warn_no_backups) echo "Nenhum backup em" ;;

    es:backups_available) echo "Backups disponibles:" ;;
    en:backups_available) echo "Available backups:" ;;
    fr:backups_available) echo "Sauvegardes disponibles:" ;;
    pt:backups_available) echo "Backups disponiveis:" ;;

    es:prompt_choose_backup) echo "Elige backup para restaurar: " ;;
    en:prompt_choose_backup) echo "Choose backup to restore: " ;;
    fr:prompt_choose_backup) echo "Choisissez la sauvegarde a restaurer: " ;;
    pt:prompt_choose_backup) echo "Escolha o backup para restaurar: " ;;

    es:err_invalid_selection) echo "Seleccion invalida." ;;
    en:err_invalid_selection) echo "Invalid selection." ;;
    fr:err_invalid_selection) echo "Selection invalide." ;;
    pt:err_invalid_selection) echo "Selecao invalida." ;;

    es:err_restore_failed) echo "No se pudo restaurar en:" ;;
    en:err_restore_failed) echo "Could not restore to:" ;;
    fr:err_restore_failed) echo "Impossible de restaurer vers:" ;;
    pt:err_restore_failed) echo "Nao foi possivel restaurar em:" ;;

    es:ok_restore_done) echo "Backup restaurado en:" ;;
    en:ok_restore_done) echo "Backup restored to:" ;;
    fr:ok_restore_done) echo "Sauvegarde restauree vers:" ;;
    pt:ok_restore_done) echo "Backup restaurado em:" ;;

    es:prompt_reset_confirm) echo "Esto elimina" ;;
    en:prompt_reset_confirm) echo "This will delete" ;;
    fr:prompt_reset_confirm) echo "Cela supprimera" ;;
    pt:prompt_reset_confirm) echo "Isto removera" ;;

    es:warn_cancelled) echo "Operacion cancelada." ;;
    en:warn_cancelled) echo "Operation cancelled." ;;
    fr:warn_cancelled) echo "Operation annulee." ;;
    pt:warn_cancelled) echo "Operacao cancelada." ;;

    es:warn_no_active_file_remove) echo "No habia archivo para eliminar en la ruta activa." ;;
    en:warn_no_active_file_remove) echo "No file to remove at active path." ;;
    fr:warn_no_active_file_remove) echo "Aucun fichier a supprimer sur le chemin actif." ;;
    pt:warn_no_active_file_remove) echo "Nenhum arquivo para remover no caminho ativo." ;;

    es:ok_removed) echo "Eliminado:" ;;
    en:ok_removed) echo "Removed:" ;;
    fr:ok_removed) echo "Supprime:" ;;
    pt:ok_removed) echo "Removido:" ;;

    es:err_remove_failed) echo "No se pudo eliminar:" ;;
    en:err_remove_failed) echo "Could not remove:" ;;
    fr:err_remove_failed) echo "Impossible de supprimer:" ;;
    pt:err_remove_failed) echo "Nao foi possivel remover:" ;;

    es:err_write_failed) echo "No se pudo escribir:" ;;
    en:err_write_failed) echo "Could not write:" ;;
    fr:err_write_failed) echo "Impossible d'ecrire:" ;;
    pt:err_write_failed) echo "Nao foi possivel gravar:" ;;

    es:confirm_suffix) echo "Continuar? (y/N): " ;;
    en:confirm_suffix) echo "Continue? (y/N): " ;;
    fr:confirm_suffix) echo "Continuer? (y/N): " ;;
    pt:confirm_suffix) echo "Continuar? (y/N): " ;;

    es:dns_title) echo "DNS over HTTPS" ;;
    en:dns_title) echo "DNS over HTTPS" ;;
    fr:dns_title) echo "DNS over HTTPS" ;;
    pt:dns_title) echo "DNS over HTTPS" ;;

    es:dns_current) echo "Estado actual:" ;;
    en:dns_current) echo "Current state:" ;;
    fr:dns_current) echo "Etat actuel:" ;;
    pt:dns_current) echo "Estado atual:" ;;

    es:dns_clear) echo "limpiar valor" ;;
    en:dns_clear) echo "clear value" ;;
    fr:dns_clear) echo "effacer la valeur" ;;
    pt:dns_clear) echo "limpar valor" ;;

    es:dns_back) echo "volver" ;;
    en:dns_back) echo "back" ;;
    fr:dns_back) echo "retour" ;;
    pt:dns_back) echo "voltar" ;;

    es:dns_prompt_template) echo "Template DoH (ej: https://dns.google/dns-query): " ;;
    en:dns_prompt_template) echo "DoH template (e.g.: https://dns.google/dns-query): " ;;
    fr:dns_prompt_template) echo "Template DoH (ex: https://dns.google/dns-query): " ;;
    pt:dns_prompt_template) echo "Template DoH (ex: https://dns.google/dns-query): " ;;

    es:toggle_select_prompt) echo "Selecciona opcion para toggle: " ;;
    en:toggle_select_prompt) echo "Choose option to toggle: " ;;
    fr:toggle_select_prompt) echo "Choisissez l'option a basculer: " ;;
    pt:toggle_select_prompt) echo "Escolha opcao para alternar: " ;;

    es:auto_apply_enabled) echo "Aplicacion automatica activada" ;;
    en:auto_apply_enabled) echo "Auto-apply enabled" ;;
    fr:auto_apply_enabled) echo "Application automatique activee" ;;
    pt:auto_apply_enabled) echo "Aplicacao automatica ativada" ;;

    es:manual_cat_telemetry) echo "Telemetria y reportes" ;;
    en:manual_cat_telemetry) echo "Telemetry and reports" ;;
    fr:manual_cat_telemetry) echo "Telemetrie et rapports" ;;
    pt:manual_cat_telemetry) echo "Telemetria e relatorios" ;;

    es:manual_cat_privacy) echo "Privacidad y seguridad" ;;
    en:manual_cat_privacy) echo "Privacy and security" ;;
    fr:manual_cat_privacy) echo "Confidentialite et securite" ;;
    pt:manual_cat_privacy) echo "Privacidade e seguranca" ;;

    es:manual_cat_features) echo "Funciones Brave" ;;
    en:manual_cat_features) echo "Brave features" ;;
    fr:manual_cat_features) echo "Fonctionnalites Brave" ;;
    pt:manual_cat_features) echo "Funcoes do Brave" ;;

    es:manual_cat_performance) echo "Rendimiento y bloat" ;;
    en:manual_cat_performance) echo "Performance and bloat" ;;
    fr:manual_cat_performance) echo "Performance et bloat" ;;
    pt:manual_cat_performance) echo "Desempenho e bloat" ;;

    es:manual_cat_dns) echo "DNS over HTTPS" ;;
    en:manual_cat_dns) echo "DNS over HTTPS" ;;
    fr:manual_cat_dns) echo "DNS over HTTPS" ;;
    pt:manual_cat_dns) echo "DNS over HTTPS" ;;

    es:manual_back) echo "Volver" ;;
    en:manual_back) echo "Back" ;;
    fr:manual_back) echo "Retour" ;;
    pt:manual_back) echo "Voltar" ;;

    es:preset_balanced_rec) echo "balanced (recomendado)" ;;
    en:preset_balanced_rec) echo "balanced (recommended)" ;;
    fr:preset_balanced_rec) echo "balanced (recommande)" ;;
    pt:preset_balanced_rec) echo "balanced (recomendado)" ;;

    es:preset_back) echo "volver" ;;
    en:preset_back) echo "back" ;;
    fr:preset_back) echo "retour" ;;
    pt:preset_back) echo "voltar" ;;

    es:preset_loaded_disk_fail) echo "Preset cargado en menu, pero no se pudo escribir en disco." ;;
    en:preset_loaded_disk_fail) echo "Preset loaded in menu, but could not write to disk." ;;
    fr:preset_loaded_disk_fail) echo "Preset charge dans le menu, mais echec d'ecriture sur disque." ;;
    pt:preset_loaded_disk_fail) echo "Preset carregado no menu, mas nao foi possivel gravar em disco." ;;

    es:pending_title) echo "Cambios pendientes:" ;;
    en:pending_title) echo "Pending changes:" ;;
    fr:pending_title) echo "Changements en attente:" ;;
    pt:pending_title) echo "Alteracoes pendentes:" ;;

    es:no_pending_changes) echo "Sin cambios pendientes." ;;
    en:no_pending_changes) echo "No pending changes." ;;
    fr:no_pending_changes) echo "Aucun changement en attente." ;;
    pt:no_pending_changes) echo "Sem alteracoes pendentes." ;;

    es:status_keys_on_disk) echo "Keys activas en disco:" ;;
    en:status_keys_on_disk) echo "Active keys on disk:" ;;
    fr:status_keys_on_disk) echo "Cles actives sur disque:" ;;
    pt:status_keys_on_disk) echo "Chaves ativas em disco:" ;;

    es:status_file_missing) echo "No existe aun (se crea al aplicar por primera vez)." ;;
    en:status_file_missing) echo "Does not exist yet (created on first apply)." ;;
    fr:status_file_missing) echo "N'existe pas encore (cree a la premiere application)." ;;
    pt:status_file_missing) echo "Ainda nao existe (criado na primeira aplicacao)." ;;

    es:status_options_on) echo "Opciones ON:" ;;
    en:status_options_on) echo "Options ON:" ;;
    fr:status_options_on) echo "Options ON:" ;;
    pt:status_options_on) echo "Opcoes ON:" ;;

    es:status_pending_unapplied) echo "Pendientes sin aplicar:" ;;
    en:status_pending_unapplied) echo "Pending unapplied:" ;;
    fr:status_pending_unapplied) echo "En attente non appliques:" ;;
    pt:status_pending_unapplied) echo "Pendentes sem aplicar:" ;;

    es:status_state) echo "Estado:" ;;
    en:status_state) echo "State:" ;;
    fr:status_state) echo "Etat:" ;;
    pt:status_state) echo "Estado:" ;;

    es:status_synced) echo "Menu y disco en sincronizacion" ;;
    en:status_synced) echo "Menu and disk are in sync" ;;
    fr:status_synced) echo "Le menu et le disque sont synchronises" ;;
    pt:status_synced) echo "Menu e disco estao sincronizados" ;;

    es:status_not_synced) echo "Hay cambios locales sin aplicar" ;;
    en:status_not_synced) echo "There are local unapplied changes" ;;
    fr:status_not_synced) echo "Il y a des changements locaux non appliques" ;;
    pt:status_not_synced) echo "Ha alteracoes locais sem aplicar" ;;

    es:tip_auto_apply) echo "Tip: presets y toggles manuales se aplican automaticamente." ;;
    en:tip_auto_apply) echo "Tip: presets and manual toggles apply automatically." ;;
    fr:tip_auto_apply) echo "Astuce: les presets et toggles manuels s'appliquent automatiquement." ;;
    pt:tip_auto_apply) echo "Dica: presets e toggles manuais sao aplicados automaticamente." ;;

    es:tip_restart_verify) echo "Luego reinicia Brave y abre brave://policy." ;;
    en:tip_restart_verify) echo "Then restart Brave and open brave://policy." ;;
    fr:tip_restart_verify) echo "Ensuite redemarrez Brave et ouvrez brave://policy." ;;
    pt:tip_restart_verify) echo "Depois reinicie o Brave e abra brave://policy." ;;

    es:help_step_1) echo "1) Elige un preset rapido o entra a configuracion manual." ;;
    en:help_step_1) echo "1) Pick a quick preset or enter manual configuration." ;;
    fr:help_step_1) echo "1) Choisissez un preset rapide ou ouvrez la configuration manuelle." ;;
    pt:help_step_1) echo "1) Escolha um preset rapido ou entre na configuracao manual." ;;

    es:help_step_2) echo "2) Cambios se aplican automaticamente." ;;
    en:help_step_2) echo "2) Changes are applied automatically." ;;
    fr:help_step_2) echo "2) Les changements sont appliques automatiquement." ;;
    pt:help_step_2) echo "2) As alteracoes sao aplicadas automaticamente." ;;

    es:help_step_3) echo "3) Revisa cambios pendientes/estado." ;;
    en:help_step_3) echo "3) Check pending changes/status." ;;
    fr:help_step_3) echo "3) Verifiez les changements en attente/l'etat." ;;
    pt:help_step_3) echo "3) Verifique alteracoes pendentes/estado." ;;

    es:help_step_4) echo "4) Reinicia Brave." ;;
    en:help_step_4) echo "4) Restart Brave." ;;
    fr:help_step_4) echo "4) Redemarrez Brave." ;;
    pt:help_step_4) echo "4) Reinicie o Brave." ;;

    es:help_step_5) echo "5) Verifica en brave://policy." ;;
    en:help_step_5) echo "5) Verify in brave://policy." ;;
    fr:help_step_5) echo "5) Verifiez dans brave://policy." ;;
    pt:help_step_5) echo "5) Verifique em brave://policy." ;;

    es:notes_title) echo "Notas:" ;;
    en:notes_title) echo "Notes:" ;;
    fr:notes_title) echo "Notes:" ;;
    pt:notes_title) echo "Notas:" ;;

    es:note_active_path_only) echo "- El script escribe solo en la ruta activa detectada para evitar duplicados." ;;
    en:note_active_path_only) echo "- The script writes only to the detected active path to avoid duplicates." ;;
    fr:note_active_path_only) echo "- Le script ecrit uniquement sur le chemin actif detecte pour eviter les doublons." ;;
    pt:note_active_path_only) echo "- O script grava apenas no caminho ativo detectado para evitar duplicados." ;;

    es:note_backup_restore) echo "- Usa Backup/Restore para volver atras." ;;
    en:note_backup_restore) echo "- Use Backup/Restore to roll back." ;;
    fr:note_backup_restore) echo "- Utilisez Backup/Restore pour revenir en arriere." ;;
    pt:note_backup_restore) echo "- Use Backup/Restore para voltar atras." ;;

    es:note_reset) echo "- Usa Reset total para eliminar slimbrave.json." ;;
    en:note_reset) echo "- Use Full reset to remove slimbrave.json." ;;
    fr:note_reset) echo "- Utilisez le reset complet pour supprimer slimbrave.json." ;;
    pt:note_reset) echo "- Use reset total para remover slimbrave.json." ;;

    *) echo "$key" ;;
  esac
}

# -----------------------------------------------------------------------------
# UI helpers
# -----------------------------------------------------------------------------

supports_truecolor() {
  case "${COLORTERM:-}" in
    truecolor|24bit) return 0 ;;
    *) return 1 ;;
  esac
}

fg_rgb() {
  printf '\033[38;2;%s;%s;%sm' "$1" "$2" "$3"
}

init_colors() {
  if [[ ! -t 1 ]]; then
    return
  fi

  if supports_truecolor; then
    TRUECOLOR_ENABLED=1
    C_RESET="$(printf '\033[0m')"
    C_TITLE="$(printf '\033[1m')$(fg_rgb 251 84 43)"
    C_ACCENT="$(fg_rgb 251 84 43)"
    C_SUB="$(fg_rgb 240 240 240)"
    C_OK="$(fg_rgb 40 167 69)"
    C_WARN="$(fg_rgb 251 84 43)"
    C_ERR="$(fg_rgb 220 53 69)"
    return
  fi

  if command -v tput >/dev/null 2>&1 && tput colors >/dev/null 2>&1; then
    C_RESET="$(tput sgr0)"
    C_TITLE="$(tput bold)$(tput setaf 1)"
    C_ACCENT="$(tput setaf 1)"
    C_SUB="$(tput setaf 7)"
    C_OK="$(tput setaf 2)"
    C_WARN="$(tput setaf 3)"
    C_ERR="$(tput setaf 1)"
  fi
}

print_wave_block_phase() {
  # Deterministic frame for animated title.
  local phase="$1"
  local lines=()
  local line
  while IFS= read -r line; do
    lines+=("$line")
  done

  if (( TRUECOLOR_ENABLED == 0 )); then
    for line in "${lines[@]}"; do
      printf "%s\n" "$line"
    done
    return
  fi

  local palette=(
    "251;84;43"
    "255;106;56"
    "255;128;69"
    "255;106;56"
  )

  local i idx rgb r g b
  for i in "${!lines[@]}"; do
    idx=$(( (i + phase) % ${#palette[@]} ))
    rgb="${palette[$idx]}"
    IFS=';' read -r r g b <<< "$rgb"
    printf "%b%s%b\n" "$(fg_rgb "$r" "$g" "$b")" "${lines[$i]}" "$C_RESET"
  done
}

print_title_art() {
  local phase="${1:-0}"
  if supports_utf8 && (( $(term_cols) >= 80 )); then
    print_wave_block_phase "$phase" <<'EOF'
███████╗██╗     ██╗███╗   ███╗██████╗ ██████╗  █████╗ ██╗   ██╗███████╗
██╔════╝██║     ██║████╗ ████║██╔══██╗██╔══██╗██╔══██╗██║   ██║██╔════╝
███████╗██║     ██║██╔████╔██║██████╔╝██████╔╝███████║██║   ██║█████╗
╚════██║██║     ██║██║╚██╔╝██║██╔══██╗██╔══██╗██╔══██║╚██╗ ██╔╝██╔══╝
███████║███████╗██║██║ ╚═╝ ██║██████╔╝██║  ██║██║  ██║ ╚████╔╝ ███████╗
╚══════╝╚══════╝╚═╝╚═╝     ╚═╝╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝
EOF
  elif (( $(term_cols) >= 100 )); then
    printf "%b" "$C_TITLE"
    cat <<'EOF'
   ____  _      ___ __  __ ____  ____    ____  ____   ___   __
  / ___|| |    |_ _|  \/  | __ )|  _ \  | __ )|  _ \ / _ \  \ \
  \___ \| |     | || |\/| |  _ \| |_) | |  _ \| |_) | | | |  \ \
   ___) | |___  | || |  | | |_) |  _ <  | |_) |  _ <| |_| |  / /
  |____/|_____| |___|_|  |_|____/|_| \_\ |____/|_| \_\\___/  /_/
                          L I N U X
EOF
    printf "%b" "$C_RESET"
  elif (( $(term_cols) >= 80 )); then
    printf "%b" "$C_TITLE"
    cat <<'EOF'
  ____  _      ___ __  __ ____  ____   ____  ____
 / ___|| |    |_ _|  \/  | __ )|  _ \ / __ )|  _ \
 \___ \| |     | || |\/| |  _ \| |_) |\__ \ | |_) |
  ___) | |___  | || |  | | |_) |  _ < ___) ||  _ <
 |____/|_____| |___|_|  |_|____/|_| \_\____/ |_| \_\
EOF
    printf "%b" "$C_RESET"
  else
    printf "%b" "$C_TITLE"
    print_center "SLIMBRAVE LINUX"
    printf "%b" "$C_RESET"
  fi
}

say_ok() {
  printf "%b%s%b\n" "$C_OK" "$1" "$C_RESET"
}

say_warn() {
  printf "%b%s%b\n" "$C_WARN" "$1" "$C_RESET"
}

say_err() {
  printf "%b%s%b\n" "$C_ERR" "$1" "$C_RESET"
}

menu_item() {
  local key="$1"
  local text="$2"
  printf "%b%s)%b %s\n" "$C_ACCENT" "$key" "$C_RESET" "$text"
}

hotkey_item() {
  local key="$1"
  local text="$2"
  printf " %b%s)%b %s\n" "$C_ACCENT" "$key" "$C_RESET" "$text"
}

screen_clear() {
  if [[ -t 1 ]]; then
    clear
  fi
}

term_cols() {
  local cols
  cols=$(tput cols 2>/dev/null || echo 80)
  if (( cols < 40 )); then
    cols=40
  fi
  printf '%s' "$cols"
}

print_hr() {
  local cols
  cols=$(term_cols)
  if (( cols > 100 )); then cols=100; fi
  printf "%b" "$C_ACCENT"
  printf '%*s\n' "$cols" '' | tr ' ' '-'
  printf "%b" "$C_RESET"
}

print_center() {
  local text="$1"
  local cols pad
  cols=$(term_cols)
  if (( cols > 100 )); then cols=100; fi
  if (( ${#text} >= cols )); then
    printf "%s\n" "$text"
    return
  fi
  pad=$(( (cols - ${#text}) / 2 ))
  printf "%*s%s\n" "$pad" "" "$text"
}

print_logo_block() {
  local cols
  cols=$(term_cols)
  if (( cols > 100 )); then cols=100; fi

  printf "%b" "$C_ACCENT"
  printf "+"
  printf '%*s' "$((cols-2))" '' | tr ' ' '-'
  printf "+\n"
  printf "%b" "$C_RESET"
}

print_banner() {
  local cols
  local phase=0
  cols=$(term_cols)

  if (( ANIMATE_TITLE == 1 )) && (( TRUECOLOR_ENABLED == 1 )) && supports_utf8 && (( cols >= 80 )); then
    phase=$(( $(date +%s) % 4 ))
  fi

  print_logo_block
  print_title_art "$phase"
  printf "%b" "$C_SUB"
  print_center "SlimBrave - Debloat + Privacy for Brave"
  printf "%b" "$C_RESET"
  print_logo_block
}

pause_enter() {
  read -r -p "$(t press_enter)" _
}

json_string() {
  python3 - "$1" <<'PY'
import json, sys
print(json.dumps(sys.argv[1], ensure_ascii=True))
PY
}

# -----------------------------------------------------------------------------
# Policy option registry
# -----------------------------------------------------------------------------

add_option() {
  local id="$1"
  local category="$2"
  local title="$3"
  local key="$4"
  local json_value="$5"

  OPTION_IDS+=("$id")
  OPT_CATEGORY["$id"]="$category"
  OPT_TITLE["$id"]="$title"
  OPT_KEY["$id"]="$key"
  OPT_JSON["$id"]="$json_value"
  ENABLED["$id"]=0
  ORIGINAL_ENABLED["$id"]=0
}

init_options() {
  # Telemetria
  add_option o01 telemetry "Desactivar metricas" "MetricsReportingEnabled" "0"
  add_option o02 telemetry "Desactivar reporte Safe Browsing" "SafeBrowsingExtendedReportingEnabled" "0"
  add_option o03 telemetry "Desactivar coleccion de URL" "UrlKeyedAnonymizedDataCollectionEnabled" "0"
  add_option o04 telemetry "Desactivar encuestas" "FeedbackSurveysEnabled" "0"

  # Privacidad
  add_option o05 privacy "Desactivar Safe Browsing" "SafeBrowsingProtectionLevel" "0"
  add_option o06 privacy "Desactivar autofill direcciones" "AutofillAddressEnabled" "0"
  add_option o07 privacy "Desactivar autofill tarjetas" "AutofillCreditCardEnabled" "0"
  add_option o08 privacy "Desactivar password manager" "PasswordManagerEnabled" "0"
  add_option o09 privacy "Desactivar browser sign-in" "BrowserSignin" "0"
  add_option o10 privacy "Bloquear fuga IP WebRTC" "WebRtcIPHandling" "\"disable_non_proxied_udp\""
  add_option o11 privacy "Desactivar protocolo QUIC" "QuicAllowed" "0"
  add_option o12 privacy "Bloquear cookies de terceros" "BlockThirdPartyCookies" "1"
  add_option o13 privacy "Activar Do Not Track" "EnableDoNotTrack" "1"
  add_option o14 privacy "Forzar Google SafeSearch" "ForceGoogleSafeSearch" "1"
  add_option o15 privacy "Desactivar IPFS" "IPFSEnabled" "0"
  add_option o16 privacy "Desactivar modo incognito" "IncognitoModeAvailability" "1"

  # Funciones Brave
  add_option o17 features "Desactivar Brave Rewards" "BraveRewardsDisabled" "1"
  add_option o18 features "Desactivar Brave Wallet" "BraveWalletDisabled" "1"
  add_option o19 features "Desactivar Brave VPN" "BraveVPNDisabled" "1"
  add_option o20 features "Desactivar Brave AI Chat" "BraveAIChatEnabled" "0"
  add_option o21 features "Desactivar Tor" "TorDisabled" "1"
  add_option o22 features "Desactivar Sync" "SyncDisabled" "1"
  add_option o23 features "Desactivar Brave News" "BraveNewsDisabled" "1"

  # Rendimiento
  add_option o24 performance "Desactivar background mode" "BackgroundModeEnabled" "0"
  add_option o25 performance "Desactivar media recommendations" "MediaRecommendationsEnabled" "0"
  add_option o26 performance "Desactivar shopping list" "ShoppingListEnabled" "0"
  add_option o27 performance "Abrir PDF externamente" "AlwaysOpenPdfExternally" "1"
  add_option o28 performance "Desactivar translate" "TranslateEnabled" "0"
  add_option o29 performance "Desactivar spellcheck" "SpellcheckEnabled" "0"
  add_option o30 performance "Desactivar promociones" "PromotionsEnabled" "0"
  add_option o31 performance "Desactivar sugerencias de busqueda" "SearchSuggestEnabled" "0"
  add_option o32 performance "Desactivar impresion" "PrintingEnabled" "0"
  add_option o33 performance "Desactivar aviso browser default" "DefaultBrowserSettingEnabled" "0"
  add_option o34 performance "Desactivar developer tools" "DeveloperToolsDisabled" "1"
  add_option o35 performance "Desactivar web discovery" "BraveWebDiscoveryEnabled" "0"
  add_option o36 performance "Desactivar stats ping" "BraveStatsPingEnabled" "0"
  add_option o37 performance "Desactivar playlist" "BravePlaylistEnabled" "0"
  add_option o38 performance "Desactivar P3A" "BraveP3AEnabled" "\"Disabled\""
}

# -----------------------------------------------------------------------------
# Policy paths and loading
# -----------------------------------------------------------------------------

detect_policy_file() {
  local preferred fallback

  if [[ -f "/etc/default/brave-browser" ]]; then
    preferred="/etc/brave-browser/policies/managed/slimbrave.json"
    fallback="/etc/brave/policies/managed/slimbrave.json"
  else
    preferred="/etc/brave/policies/managed/slimbrave.json"
    fallback="/etc/brave-browser/policies/managed/slimbrave.json"
  fi

  if [[ -f "$preferred" ]]; then
    POLICY_FILE="$preferred"
    return
  fi
  if [[ -f "$fallback" ]]; then
    POLICY_FILE="$fallback"
    return
  fi

  if [[ -d "$(dirname "$preferred")" ]]; then
    POLICY_FILE="$preferred"
    return
  fi
  if [[ -d "$(dirname "$fallback")" ]]; then
    POLICY_FILE="$fallback"
    return
  fi

  POLICY_FILE="$preferred"
}

count_enabled() {
  local id count=0
  for id in "${OPTION_IDS[@]}"; do
    if [[ "${ENABLED[$id]}" == "1" ]]; then
      ((count+=1))
    fi
  done
  printf '%s' "$count"
}

# -----------------------------------------------------------------------------
# Presets and JSON generation
# -----------------------------------------------------------------------------

enable_only() {
  local ids=("$@")
  local id
  for id in "${OPTION_IDS[@]}"; do
    ENABLED["$id"]=0
  done
  for id in "${ids[@]}"; do
    ENABLED["$id"]=1
  done
}

apply_preset() {
  local name="$1"
  case "$name" in
    max-privacy)
      enable_only \
        o01 o02 o03 o04 o05 o06 o07 o08 o09 o10 o11 o12 o13 o15 o16 \
        o17 o18 o19 o20 o21 o22 o23 \
        o24 o25 o26 o27 o28 o29 o30 o31 o32 o33 o35 o36 o37 o38
      DNS_MODE="off"
      DNS_TEMPLATES=""
      ;;
    balanced)
      enable_only \
        o01 o02 o03 o04 o06 o07 o09 o10 o11 o12 o13 o15 \
        o17 o18 o19 o20 o22 o23 \
        o24 o25 o26 o27 o28 o30 o31 o33 o35 o36
      DNS_MODE="automatic"
      DNS_TEMPLATES=""
      ;;
    performance)
      enable_only \
        o01 o04 \
        o17 o18 o19 o20 o23 \
        o24 o25 o26 o27 o28 o29 o30 o31 o33 o35 o36 o37
      DNS_MODE="automatic"
      DNS_TEMPLATES=""
      ;;
    developer)
      enable_only \
        o01 o02 o03 o04 o10 o11 o12 o13 \
        o17 o18 o19 o20 o22 o23 \
        o24 o25 o26 o27 o28 o30 o31 o33 o35 o36
      ENABLED[o34]=0
      DNS_MODE="automatic"
      DNS_TEMPLATES=""
      ;;
    parental)
      enable_only \
        o09 o12 o14 o16 \
        o17 o18 o19 o20 o21 o22 o23 \
        o24 o25 o26 o30 o31 o32 o34 o35
      DNS_MODE="secure"
      DNS_TEMPLATES="https://family.cloudflare-dns.com/dns-query"
      ;;
  esac
}

load_policy_from_file() {
  local source_file="$1"
  local parsed key value id

  parsed=$(python3 - "$source_file" <<'PY'
import json, sys
path = sys.argv[1]
try:
    with open(path, 'r', encoding='utf-8') as f:
        data = json.load(f)
except Exception:
    data = {}
for k, v in data.items():
    print(f"{k}\t{json.dumps(v, ensure_ascii=True)}")
PY
)

  while IFS=$'\t' read -r key value; do
    [[ -z "${key:-}" ]] && continue

    if [[ "$key" == "DnsOverHttpsMode" ]]; then
      DNS_MODE=$(printf '%s' "$value" | sed 's/^"//; s/"$//')
      continue
    fi
    if [[ "$key" == "DnsOverHttpsTemplates" ]]; then
      DNS_TEMPLATES=$(printf '%s' "$value" | sed 's/^"//; s/"$//')
      continue
    fi

    for id in "${OPTION_IDS[@]}"; do
      if [[ "${OPT_KEY[$id]}" == "$key" ]] && [[ "${OPT_JSON[$id]}" == "$value" ]]; then
        ENABLED["$id"]=1
        break
      fi
    done
  done <<< "$parsed"
}

load_current_policy() {
  local id
  for id in "${OPTION_IDS[@]}"; do
    ENABLED["$id"]=0
    ORIGINAL_ENABLED["$id"]=0
  done
  DNS_MODE=""
  DNS_TEMPLATES=""
  ORIGINAL_DNS_MODE=""
  ORIGINAL_DNS_TEMPLATES=""

  detect_policy_file

  if command -v python3 >/dev/null 2>&1 && [[ -f "$POLICY_FILE" ]]; then
    load_policy_from_file "$POLICY_FILE"
  fi

  for id in "${OPTION_IDS[@]}"; do
    ORIGINAL_ENABLED["$id"]="${ENABLED[$id]}"
  done
  ORIGINAL_DNS_MODE="$DNS_MODE"
  ORIGINAL_DNS_TEMPLATES="$DNS_TEMPLATES"
}

count_policy_keys_file() {
  local file_path="$1"
  if [[ ! -f "$file_path" ]] || ! command -v python3 >/dev/null 2>&1; then
    printf '0'
    return
  fi
  python3 - "$file_path" <<'PY'
import json, sys
path = sys.argv[1]
try:
    with open(path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    print(len(data) if isinstance(data, dict) else 0)
except Exception:
    print(0)
PY
}

pending_changes_count() {
  local id count=0
  for id in "${OPTION_IDS[@]}"; do
    if [[ "${ENABLED[$id]}" != "${ORIGINAL_ENABLED[$id]}" ]]; then
      ((count+=1))
    fi
  done
  if [[ "$DNS_MODE" != "$ORIGINAL_DNS_MODE" ]]; then
    ((count+=1))
  fi
  if [[ "$DNS_MODE" == "secure" ]] && [[ "$DNS_TEMPLATES" != "$ORIGINAL_DNS_TEMPLATES" ]]; then
    ((count+=1))
  fi
  printf '%s' "$count"
}

write_policy_json() {
  local out_file="$1"
  local entries=()
  local id
  local dns_mode_json dns_tpl_json

  for id in "${OPTION_IDS[@]}"; do
    if [[ "${ENABLED[$id]}" == "1" ]]; then
      entries+=("\"${OPT_KEY[$id]}\": ${OPT_JSON[$id]}")
    fi
  done

  if [[ -n "$DNS_MODE" ]]; then
    dns_mode_json=$(json_string "$DNS_MODE")
    entries+=("\"DnsOverHttpsMode\": $dns_mode_json")
    if [[ "$DNS_MODE" == "secure" ]] && [[ -n "$DNS_TEMPLATES" ]]; then
      dns_tpl_json=$(json_string "$DNS_TEMPLATES")
      entries+=("\"DnsOverHttpsTemplates\": $dns_tpl_json")
    fi
  fi

  {
    echo "{"
    local i
    for i in "${!entries[@]}"; do
      if (( i < ${#entries[@]} - 1 )); then
        echo "  ${entries[$i]},"
      else
        echo "  ${entries[$i]}"
      fi
    done
    echo "}"
  } > "$out_file"
}

# -----------------------------------------------------------------------------
# Filesystem actions (backup/apply/restore/reset)
# -----------------------------------------------------------------------------

ensure_policy_dir() {
  local dir
  detect_policy_file
  dir="$(dirname "$POLICY_FILE")"
  if [[ -d "$dir" ]]; then
    return 0
  fi
  if mkdir -p "$dir" 2>/dev/null; then
    return 0
  fi
  sudo mkdir -p "$dir"
}

backup_current_policy() {
  detect_policy_file
  mkdir -p "$BACKUP_DIR"

  local ts name backup_file
  ts=$(date +"%Y%m%d-%H%M%S")

  if [[ ! -f "$POLICY_FILE" ]]; then
    say_warn "$(t warn_no_policy_backup)"
    return 1
  fi

  name=$(echo "$POLICY_FILE" | sed 's#/#_#g' | sed 's#^_##')
  backup_file="$BACKUP_DIR/slimbrave-${ts}-${name}"

  if cp "$POLICY_FILE" "$backup_file" 2>/dev/null; then
    :
  elif sudo sh -c "cat \"$POLICY_FILE\" > \"$backup_file\""; then
    :
  else
    say_err "$(t err_backup_create) $POLICY_FILE"
    return 1
  fi

  say_ok "$(t ok_backup_created) $backup_file"
  return 0
}

apply_configuration() {
  local tmp
  tmp=$(mktemp)
  write_policy_json "$tmp"

  ensure_policy_dir
  backup_current_policy >/dev/null 2>&1 || true

  detect_policy_file
  if install -m 644 "$tmp" "$POLICY_FILE" 2>/dev/null; then
    :
  elif sudo install -m 644 "$tmp" "$POLICY_FILE"; then
    :
  else
    rm -f "$tmp"
    say_err "$(t err_write_failed) $POLICY_FILE"
    return 1
  fi

  rm -f "$tmp"

  load_current_policy
  say_ok "$(t ok_applied_in) $POLICY_FILE"
  say_ok "$(t ok_done_verify)"
  return 0
}

restore_backup() {
  mkdir -p "$BACKUP_DIR"

  local files=()
  local f
  while IFS= read -r f; do
    files+=("$f")
  done < <(ls -1 "$BACKUP_DIR"/*.json 2>/dev/null | sort -r)

  if (( ${#files[@]} == 0 )); then
    say_warn "$(t warn_no_backups) $BACKUP_DIR"
    return 1
  fi

  echo
  echo "$(t backups_available)"
  local i=1
  for f in "${files[@]}"; do
    echo "  $i) $(basename "$f")"
    ((i+=1))
  done

  echo
  read -r -p "$(t prompt_choose_backup)" choice
  if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#files[@]} )); then
    say_err "$(t err_invalid_selection)"
    return 1
  fi

  local selected
  selected="${files[$((choice-1))]}"

  detect_policy_file
  ensure_policy_dir

  if install -m 644 "$selected" "$POLICY_FILE" 2>/dev/null; then
    :
  elif sudo install -m 644 "$selected" "$POLICY_FILE"; then
    :
  else
    say_err "$(t err_restore_failed) $POLICY_FILE"
    return 1
  fi

  say_ok "$(t ok_restore_done) $POLICY_FILE"

  load_current_policy
  return 0
}

reset_policy() {
  detect_policy_file
  read -r -p "$(t prompt_reset_confirm) $POLICY_FILE. $(t confirm_suffix)" ans
  if [[ ! "$ans" =~ ^[Yy]$ ]]; then
    say_warn "$(t warn_cancelled)"
    return 1
  fi

  backup_current_policy >/dev/null 2>&1 || true

  if [[ ! -f "$POLICY_FILE" ]]; then
    say_warn "$(t warn_no_active_file_remove)"
    load_current_policy
    return 0
  fi

  if rm -f "$POLICY_FILE" 2>/dev/null; then
    say_ok "$(t ok_removed) $POLICY_FILE"
  elif sudo rm -f "$POLICY_FILE"; then
    say_ok "$(t ok_removed) $POLICY_FILE"
  else
    say_err "$(t err_remove_failed) $POLICY_FILE"
    return 1
  fi

  load_current_policy
  return 0
}

# -----------------------------------------------------------------------------
# Menu rendering
# -----------------------------------------------------------------------------

status_text() {
  local value="$1"
  if [[ "$value" == "1" ]]; then
    printf "%b[ON ]%b" "$C_OK" "$C_RESET"
  else
    printf "%b[OFF]%b" "$C_WARN" "$C_RESET"
  fi
}

show_dns_status() {
  case "$DNS_MODE" in
    "") echo "Not configured" ;;
    automatic) echo "automatic" ;;
    off) echo "off" ;;
    secure)
      if [[ -n "$DNS_TEMPLATES" ]]; then
        echo "custom ($DNS_TEMPLATES)"
      else
        echo "custom (no template)"
      fi
      ;;
    *) echo "$DNS_MODE" ;;
  esac
}

list_category_ids() {
  local category="$1"
  local id
  for id in "${OPTION_IDS[@]}"; do
    if [[ "${OPT_CATEGORY[$id]}" == "$category" ]]; then
      echo "$id"
    fi
  done
}

choose_dns_mode() {
  while true; do
    screen_clear
    print_banner
    echo "$(t dns_title)"
    echo "$(t dns_current) $(show_dns_status)"
    echo
    menu_item "1" "automatic"
    menu_item "2" "off"
    menu_item "3" "custom"
    menu_item "4" "$(t dns_clear)"
    menu_item "0" "$(t dns_back)"
    echo
    read -r -p "$(t main_select)" c
    case "$c" in
      1)
        DNS_MODE="automatic"
        DNS_TEMPLATES=""
        if ! apply_configuration; then
          pause_enter
        fi
        return
        ;;
      2)
        DNS_MODE="off"
        DNS_TEMPLATES=""
        if ! apply_configuration; then
          pause_enter
        fi
        return
        ;;
      3)
        DNS_MODE="secure"
        read -r -p "$(t dns_prompt_template)" DNS_TEMPLATES
        if ! apply_configuration; then
          pause_enter
        fi
        return
        ;;
      4)
        DNS_MODE=""
        DNS_TEMPLATES=""
        if ! apply_configuration; then
          pause_enter
        fi
        return
        ;;
      0) return ;;
      *) say_err "$(t invalid_option)"; sleep 1 ;;
    esac
  done
}

category_menu() {
  local category="$1"
  local title="$2"

  while true; do
    screen_clear
    print_banner
    echo "$title"
    echo

    local ids=() id i=1
    while IFS= read -r id; do
      ids+=("$id")
    done < <(list_category_ids "$category")

    for id in "${ids[@]}"; do
      echo " $i) $(status_text "${ENABLED[$id]}") ${OPT_TITLE[$id]}"
      ((i+=1))
    done

    echo
    echo "$(t auto_apply_enabled)"
    hotkey_item "b" "$(t manual_back)"
    hotkey_item "q" "$(t main_exit)"
    echo
    read -r -p "$(t toggle_select_prompt)" c

    case "$c" in
      b|B) return ;;
      q|Q) exit 0 ;;
      *)
        if [[ "$c" =~ ^[0-9]+$ ]] && (( c >= 1 && c <= ${#ids[@]} )); then
          id="${ids[$((c-1))]}"
          if [[ "${ENABLED[$id]}" == "1" ]]; then
            ENABLED[$id]=0
          else
            ENABLED[$id]=1
          fi
          if ! apply_configuration; then
            pause_enter
          fi
        else
          say_err "$(t invalid_option)"
          sleep 1
        fi
        ;;
    esac
  done
}

manual_config_menu() {
  while true; do
    screen_clear
    print_banner
    echo "$(t manual_title)"
    echo
    menu_item "1" "$(t manual_cat_telemetry)"
    menu_item "2" "$(t manual_cat_privacy)"
    menu_item "3" "$(t manual_cat_features)"
    menu_item "4" "$(t manual_cat_performance)"
    menu_item "5" "$(t manual_cat_dns)"
    menu_item "0" "$(t manual_back)"
    echo
    read -r -p "$(t main_select)" c
    case "$c" in
      1) category_menu "telemetry" "$(t manual_cat_telemetry)" ;;
      2) category_menu "privacy" "$(t manual_cat_privacy)" ;;
      3) category_menu "features" "$(t manual_cat_features)" ;;
      4) category_menu "performance" "$(t manual_cat_performance)" ;;
      5) choose_dns_mode ;;
      0) return ;;
      *) say_err "$(t invalid_option)"; sleep 1 ;;
    esac
  done
}

preset_menu() {
  while true; do
    screen_clear
    print_banner
    echo "$(t presets_title)"
    echo
    menu_item "1" "$(t preset_balanced_rec)"
    menu_item "2" "max-privacy"
    menu_item "3" "performance"
    menu_item "4" "developer"
    menu_item "5" "parental"
    menu_item "0" "$(t preset_back)"
    echo
    echo "$(t recommended_tip)"
    read -r -p "$(t preset_prompt)" c
    c=${c:-1}
    case "$c" in
      1)
        apply_preset "balanced"
        if apply_configuration; then
          say_ok "Preset balanced applied."
        else
          say_warn "$(t preset_loaded_disk_fail)"
        fi
        pause_enter
        return
        ;;
      2)
        apply_preset "max-privacy"
        if apply_configuration; then
          say_ok "Preset max-privacy applied."
        else
          say_warn "$(t preset_loaded_disk_fail)"
        fi
        pause_enter
        return
        ;;
      3)
        apply_preset "performance"
        if apply_configuration; then
          say_ok "Preset performance applied."
        else
          say_warn "$(t preset_loaded_disk_fail)"
        fi
        pause_enter
        return
        ;;
      4)
        apply_preset "developer"
        if apply_configuration; then
          say_ok "Preset developer applied."
        else
          say_warn "$(t preset_loaded_disk_fail)"
        fi
        pause_enter
        return
        ;;
      5)
        apply_preset "parental"
        if apply_configuration; then
          say_ok "Preset parental applied."
        else
          say_warn "$(t preset_loaded_disk_fail)"
        fi
        pause_enter
        return
        ;;
      0) return ;;
      *) say_err "$(t invalid_option)"; sleep 1 ;;
    esac
  done
}

show_pending_changes() {
  screen_clear
  print_banner

  local count
  count=$(pending_changes_count)
  echo "$(t pending_title) $count"
  echo

  local id
  for id in "${OPTION_IDS[@]}"; do
    if [[ "${ENABLED[$id]}" != "${ORIGINAL_ENABLED[$id]}" ]]; then
      echo " - $(status_text "${ENABLED[$id]}") ${OPT_TITLE[$id]} (${OPT_KEY[$id]}=${OPT_JSON[$id]})"
    fi
  done

  if [[ "$DNS_MODE" != "$ORIGINAL_DNS_MODE" ]] || [[ "$DNS_TEMPLATES" != "$ORIGINAL_DNS_TEMPLATES" ]]; then
    echo " - DNS: $(show_dns_status)"
  fi

  if (( count == 0 )); then
    say_warn "$(t no_pending_changes)"
  fi
  pause_enter
}

language_menu() {
  while true; do
    screen_clear
    print_banner
    echo "$(t language_title)"
    echo
    menu_item "1" "Espanol"
    menu_item "2" "English"
    menu_item "3" "Francais"
    menu_item "4" "Portugues"
    menu_item "0" "$(t main_exit)"
    echo
    read -r -p "$(t main_select)" c
    case "$c" in
      1) UI_LANG="es"; save_user_config; say_ok "$(t lang_changed)"; pause_enter; return ;;
      2) UI_LANG="en"; save_user_config; say_ok "$(t lang_changed)"; pause_enter; return ;;
      3) UI_LANG="fr"; save_user_config; say_ok "$(t lang_changed)"; pause_enter; return ;;
      4) UI_LANG="pt"; save_user_config; say_ok "$(t lang_changed)"; pause_enter; return ;;
      0) return ;;
      *) say_err "$(t invalid_option)"; sleep 1 ;;
    esac
  done
}

show_status_screen() {
  screen_clear
  print_banner

  detect_policy_file
  local keys pending
  keys=$(count_policy_keys_file "$POLICY_FILE")
  pending=$(pending_changes_count)

  echo "$(t status_title_file)"
  if [[ -f "$POLICY_FILE" ]]; then
    printf " - %b[OK]%b %s\n" "$C_OK" "$C_RESET" "$POLICY_FILE"
    echo " - $(t status_keys_on_disk) $keys"
  else
    printf " - %b[--]%b %s\n" "$C_WARN" "$C_RESET" "$POLICY_FILE"
    echo " - $(t status_file_missing)"
  fi

  echo
  echo "$(t status_title_menu)"
  echo " - $(t status_options_on) $(count_enabled)/${#OPTION_IDS[@]}"
  echo " - DNS: $(show_dns_status)"

  echo
  echo "$(t status_title_sync)"
  echo " - $(t status_pending_unapplied) $pending"
  if (( pending == 0 )); then
    printf " - %b%s%b %s\n" "$C_OK" "$(t status_state)" "$C_RESET" "$(t status_synced)"
  else
    printf " - %b%s%b %s\n" "$C_WARN" "$(t status_state)" "$C_RESET" "$(t status_not_synced)"
  fi

  echo
  echo "$(t tip_auto_apply)"
  echo "$(t tip_restart_verify)"
  pause_enter
}

show_help() {
  screen_clear
  print_banner
  cat <<EOF
$(t help_title)
$(t help_step_1)
$(t help_step_2)
$(t help_step_3)
$(t help_step_4)
$(t help_step_5)

$(t notes_title)
$(t note_active_path_only)
$(t note_backup_restore)
$(t note_reset)
EOF
  pause_enter
}

main_menu() {
  local c
  while true; do
    screen_clear
    print_banner
    printf "%b%s:%b %s | %bDNS:%b %s\n" "$C_ACCENT" "$(t pending_short)" "$C_RESET" "$(pending_changes_count)" "$C_ACCENT" "$C_RESET" "$(show_dns_status)"
    echo
    menu_item "1" "$(t main_presets)"
    menu_item "2" "$(t main_manual)"
    menu_item "3" "$(t main_pending)"
    menu_item "4" "$(t main_backup)"
    menu_item "5" "$(t main_restore)"
    menu_item "6" "$(t main_reset)"
    menu_item "7" "$(t main_status)"
    menu_item "8" "$(t main_language)"
    menu_item "9" "$(t main_help)"
    menu_item "0" "$(t main_exit)"
    echo
    read -r -p "$(t main_select)" c

    case "$c" in
      1) preset_menu ;;
      2) manual_config_menu ;;
      3) show_pending_changes ;;
      4) backup_current_policy; pause_enter ;;
      5) restore_backup; pause_enter ;;
      6) reset_policy; pause_enter ;;
      7) show_status_screen ;;
      8) language_menu ;;
      9) show_help ;;
      0) echo "$(t bye)"; exit 0 ;;
      *) say_err "$(t invalid_option)"; sleep 1 ;;
    esac
  done
}

# -----------------------------------------------------------------------------
# Entry point
# -----------------------------------------------------------------------------

main() {
  detect_default_language
  load_user_config
  init_colors
  init_options
  load_current_policy
  main_menu
}

main

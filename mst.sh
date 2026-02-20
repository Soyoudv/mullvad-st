#!/usr/bin/env bash

# ---------------------------------- FUNCTIONS ---------------------------------- #

load_config(){
  #load excluded apps from config
  CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/mst"
  EXCLUDED_APPS_FILE="$CONFIG_DIR/excluded-apps.txt"
  if [ ! -f "$EXCLUDED_APPS_FILE" ]; then
    echo "Missing excluded apps file: $EXCLUDED_APPS_FILE" >&2
    exit 1
  fi
}

refresh_excluded_apps(){
  #read excluded apps into array
  mapfile -t EXCLUDED_APPS < "$EXCLUDED_APPS_FILE"

  #check if any excluded apps were found, else open config for editing
  if [ ${#EXCLUDED_APPS[@]} -eq 0 ]; then
    echo "No excluded apps found in $EXCLUDED_APPS_FILE" >&2
    xdg-open "$EXCLUDED_APPS_FILE"
    exit 1
  fi
}

load_excluded_apps(){
  load_config
  refresh_excluded_apps
}

cleanup(){
  echo -e "Cleaning up split tunnel pids..."
  mullvad split-tunnel clear > /dev/null 2>&1
}

cleanup_exit(){
  echo ""
  cleanup
}

app_include(){
  if [[ $found -eq 0 ]]; then # if an app was removed from the excluded apps list
    app="${EXCLUDED_APPS_save[i]}"
      
    pidtoadd=() #reset applist array
    while read -r pid; do #check for pids to remove from split tunnel
      if grep -q "^$pid$" "$STATE_FILE"; then
        pidtoadd+=("$pid") #add new pid to array
      fi
    done < <(pgrep -f "$app")

    for addpid in "${pidtoadd[@]}"; do
      while read -r pid; do
        if mullvad split-tunnel delete "$addpid" > /dev/null 2>&1; then
          echo "$addpid" >> "$STATE_FILE"
        else 
          echo "Failed to remove $app [$addpid] from split tunnel"
        fi
      done < <(pgrep -f "${EXCLUDED_APPS_save[i]}")
    done
    echo -e "\e[4m\e[95m$app\e[0m \e[91mincluded\e[0m\n ╰(\e[90m${pidtoadd[*]}\e[0m)" #avec une virgule entre les pids
    # Remove PIDs from state file
    grep -v -F -f <(pgrep -f "${EXCLUDED_APPS_save[i]}") "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
  fi
}

blacklist(){
  while true; do

    #--- PARTIE INCLUSION ---

    EXCLUDED_APPS_save=("${EXCLUDED_APPS[@]}") #save current excluded apps
    refresh_excluded_apps # refresh excluded apps list

    for i in "${!EXCLUDED_APPS_save[@]}"; do #loop through saved excluded apps
      found=0
      for j in "${!EXCLUDED_APPS[@]}"; do
        if [[ "${EXCLUDED_APPS_save[i]}" == "${EXCLUDED_APPS[j]}" ]]; then
          found=1
        fi
      done
      app_include
      found=0
    done
    
    #--- PARTIE EXCLUSION ---

    for app in "${EXCLUDED_APPS[@]}"; do 
    # echo "Checking for app: $app"

      pidtodelete=() #reset applist array

      while read -r pid; do
        if ! grep -q "^$pid$" "$STATE_FILE"; then
          pidtodelete+=("$pid") #add new pid to array
        fi
      done < <(pgrep -f "$app")

      #remove pids that are no longer running
      if [ ${#pidtodelete[@]} -eq 0 ]; then
        continue
      else
        for delpid in "${pidtodelete[@]}"; do
          if mullvad split-tunnel add "$delpid" > /dev/null 2>&1; then
            echo "$delpid" >> "$STATE_FILE"
          else 
            echo "Failed to add $app [$delpid] to split tunnel"
          fi
        done
        echo -e "\e[4m\e[95m$app\e[0m \e[92mexcluded\e[0m\n ╰(\e[90m${pidtodelete[*]}\e[0m)"
      fi
    done

    sleep 5
  done
}

delete_empty_lines(){
  sed -i '/^$/d' "$EXCLUDED_APPS_FILE"
}

add_line(){
  if grep -Fxq "$OPTARG" "$EXCLUDED_APPS_FILE"; then
    echo -e "\e[91mLine already exists in $EXCLUDED_APPS_FILE\e[0m"
  else
    printf "\n" >> "$EXCLUDED_APPS_FILE"
    echo "$OPTARG" >> "$EXCLUDED_APPS_FILE"
    echo -e "\e[92mAdded line to $EXCLUDED_APPS_FILE:\e[0m \e[95m$OPTARG\e[0m"

    delete_empty_lines
  fi
}

remove_line(){
  if grep -Fxq "$OPTARG" "$EXCLUDED_APPS_FILE"; then
    sed -i "\|^$OPTARG$|d" "$EXCLUDED_APPS_FILE"
    echo -e "\e[92mRemoved line from $EXCLUDED_APPS_FILE:\e[0m \e[95m$OPTARG\e[0m"

    delete_empty_lines
  else
    echo -e "\e[91mLine not found in $EXCLUDED_APPS_FILE\e[0m"
  fi
}


# ---------------------------------- ARGUMENTS ---------------------------------- #

while getopts ": s a: r: l e h" opt; do
  case ${opt} in
    s)
      # silent mode
      echo -e "\e[92mExécution en mode silencieux...\e[0m"
      exec >/dev/null 2>&1
    ;;
    a)
      # add line to excluded apps file
      load_config
      add_line "$OPTARG"
      exit 1
    ;;
    r)
      # remove line to excluded apps file
      load_config
      remove_line "$OPTARG"
      exit 1
    ;;
    l)
      # list excluded apps
      load_config
      echo -e "\e[1mListe des applications exclues dans le split tunnel:\e[0m"
      echo -e "\e[4m\e[95m$(cat "$EXCLUDED_APPS_FILE")\e[0m"
      exit 1
    ;;
    e)
      # open excluded apps file
      load_config
      echo -e "\e[92mOuverture du fichier de configuration pour modification...\e[0m"
      xdg-open "$EXCLUDED_APPS_FILE"
      exit 1
    ;;
    h)
        echo -e "   \e[4m\e[1mMULLVAD SPLIT TUNNEL\e[0m (help menu)"
        echo -e "\e[1m-h\e[0m\thelp"
        echo -e "\e[1m-s\e[0m\tsilent mode, no output"
        echo -e "\e[1m-a\e[0m\tadd a line to the excluded apps file"
        echo -e "\e[1m-r\e[0m\tremove a line from the excluded apps file"
        echo -e "\e[1m-l\e[0m\tlist excluded apps"
        echo -e "\e[1m-e\e[0m\tedit excluded apps file"
        exit 0
    ;;
    ?)
      # the rest
      echo -e "\e[91mInvalid option: -${OPTARG}.\e[0m"
      exit 1
    ;;
  esac
done


# ---------------------------------- MAIN SCRIPT ---------------------------------- #

trap cleanup_exit EXIT # clean up on exit

echo -e "\e[92mRunning mullvad split tunnel...\e[0m"

load_excluded_apps # config already loaded once, just refresh excluded apps
echo -e "Using list from: \e[1m$EXCLUDED_APPS_FILE\e[0m"

cleanup # clean up any existing split tunnel pids before starting

# state file to keep track of added pids
STATE_FILE="$HOME/.cache/mullvad-split-pids"
mkdir -p "$(dirname "$STATE_FILE")" #ensure state file directory exists
: > "$STATE_FILE" # reset state file // : because > alone can fail if noclobber is set

echo -e "\e[1mSplit tunnel running, ${#EXCLUDED_APPS[*]} apps excluded.\e[0m"

blacklist # start split tunnel loop


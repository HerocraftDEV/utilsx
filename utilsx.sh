#!/bin/bash
ver="v1.5"
longver="v1.5.7"
longvernv="1.5.7"

# Definiendo rutas de los archivos y variables
PROGRAMPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$PROGRAMPATH/utilsx_data/utilsx.conf"
TODO_FILE="$PROGRAMPATH/utilsx_data/TODO.txt"
AGENDA_FILE="$PROGRAMPATH/utilsx_data/AGENDA.txt"
NOTES_FILE="$PROGRAMPATH/utilsx_data/NOTES.txt"
PASSWORD_FILE="$PROGRAMPATH/utilsx_data/.passwords.enc"
DATA_PATH="$PROGRAMPATH/utilsx_data"
HISTFILE="$PROGRAMPATH/utilsx_data/.hist"
MAXLINES=50
COMMANDCOUNT=0
PLUGINS_PATH="$PROGRAMPATH/utilsx_plugins"
BACKUPS_PATH="$PROGRAMPATH/.utilsx_backups"
dnmode=false
copilotcommandfunc=false
if [ ! -e $HOME/.devmodeverifier ]; then
devmode=false
else
devmode=true
fi

# Función de temporizador simple, comando TIMER
timer() {
sleeptime=$1
while [ $sleeptime -gt 0 ]; do
  echo -ne "Tiempo restante: $sleeptime segundos\r"
  sleep 1
  ((sleeptime--))
done
echo -e "\n✅ Tiempo terminado"
echo " "
}

# Temporizador silencioso
silenttimer() {
sleeptime=$1
while [ $sleeptime -gt 0 ]; do
  echo -ne -e "\e[33mTiempo restante: $sleeptime segundos\e[0m \r"
  sleep 1
  ((sleeptime--))
done
}

# Verifica si el directorio de datos del programa existe
if [ -e "$DATA_PATH" ]; then
:
else
echo -e "\e[32mSe creará un nuevo directorio para datos del programa...\e[0m"
echo -e "\e[32mVerificando dependencias...\e[0m"
mkdir $PROGRAMPATH/utilsx_data
fi
touch "$HISTFILE"
checkdep() {
if ! command -v "$1" >/dev/null 2>&1; then
echo -e "\e[31mFalta '$1'.\e[0m"
fi
}

# Verifica las dependencias
checkdep jq
checkdep qrencode
checkdep openssl

# Verifica si existe el archivo de configuración
if [ -f "$CONFIG_FILE" ]; then
   source "$CONFIG_FILE"
else
  echo -e "\e[32mSe creará un archivo de configuración...\e[0m"
  echo "Puedes editar tus configuraciones con el comando CONFIG"
  touch "$CONFIG_FILE"
fi
echo " "

# Carga de plugins
loadplugins() {
shopt -s nullglob
local plugins=("$PLUGINS_PATH"/*.sh)
shopt -u nullglob
if [ -d "$PLUGINS_PATH" ]; then
 if [ ${#plugins[@]} -eq 0 ]; then
 :
 else
 for plugin in "${plugins[@]}"; do
    source "$plugin"
 done
 fi
else
:
fi
}

loadplugins

# Verifica si USERNAME existe o no, si no es así pregunta tu nombre y lo guarda en el archivo de configuración 
if [ -z "$USERNAME" ]; then
  read -p "Escriba su nombre... " USERNAME
  echo "USERNAME=\"$USERNAME\"" >> "$CONFIG_FILE"
  source "$CONFIG_FILE"
  echo -e "¡Bienvenido, \e[32m$USERNAME!\e[0m Ahora estás en \e[33mUtilsX $ver. \e[0m"
else
# Verifica si pusiste algún parametro
if [ $# -gt 0 ]; then
dnmode=true
echo -e "\e[33mUtilsX $ver\e[0m |\e[1;34m $(date)\e[0m"
else
  echo -e "\e[33mUtilsX $ver\e[0m |\e[1;34m $(date)\e[0m"
  echo -e "¡Hola de nuevo, $USERNAME!"
fi
fi

# Verificación x2
if [ $# -gt 0 ]; then
echo "Ejecutando comando del parámetro..."
else
echo "Para ver la lista de utilidades, escriba HELP"
echo " "
fi

# Define el texto del prompt, carga el historial y habilita la visibilidad del directorio actual en lugar del texto del prompt
if [ $devmode == true ]; then
prompttext="UtilsX (devmode) > "
else
prompttext="UtilsX > "
fi
showdir=true
history -r $HISTFILE

# Para el comando NOTES
notes() {
local cmd="$1"
shift
# Lista de los parámetros y lo que hacen del comando NOTES
case "$cmd" in
  add)
    echo "$*" >> $NOTES_FILE
    echo "📝 Notas 📝"
    cat $NOTES_FILE
    echo " "
    ;;
  view)
    echo "📝 Notas 📝"
    cat $NOTES_FILE
    echo " "
    ;;
  clear)
    > $NOTES_FILE
    echo "📝 Notas 📝"
    cat $NOTES_FILE
    echo " "
    ;;
  *) echo "Uso: notes (clear/add/view) y (nombre de nota) si es necesario"
esac
}

# Función de la calculadora usando bc con los números seleccionados, comando CALC
calc() {
read -p "Seleccione el primer número: " fn
read -p "Seleccione el operador (+ * / -): " op
read -p "Seleccione el segundo número: " sn
resultado=$(echo "scale=2; $fn $op $sn" | bc)
echo "Resultado: $resultado"
echo " "
}

# Usa /dev/urandom para generar una contraseña aleatoria de determinada longitud, comando PASSGEN
random_pass_gen() {
read -p "Longitud: " LONGITUD
echo "Contraseña generada: "
< /dev/urandom tr -dc 'A-Za-z0-9!@#$%&*()_=/\[]' | head -c $LONGITUD
echo
echo " "
}

# Eliminar copia 
removebackup() {
echo "Lista de copias: "
ls $BACKUPS_PATH
read -p "Copia a eliminar: " backuptodelete
if [ -d $BACKUPS_PATH/$backuptodelete ]; then
rm -r $BACKUPS_PATH/$backuptodelete
else
echo "La copia elegida no existe. "
fi
}

# Activar / Deshabilitar modo de desarrollador
devmode() {
echo "El modo de desarrollador es un modo especial que borra tus configuraciones al salir y permite ver información sobre la ejecución de comandos."
read -p "¿Desea activar el modo de desarrollador ahora? (S/N) " devmodeactivateselec
if [ $devmodeactivateselec == S ]; then
devmode=true
prompttext="UtilsX (devmode) > "
touch $HOME/.devmodeverifier
elif [ $devmodeactivateselec == N ]; then
devmode=false
prompttext="UtilsX > "
rm $HOME/.devmodeverifier
fi
echo "Hecho."
}

# Backup completo
completebackup() {
read -p "Nombre: " backupname
if [ -z "$backupname" ]; then
local BACKUP_PATH="$BACKUPS_PATH/$(date +'%Y-%m-%d_%H-%M-%S')"
else
local BACKUP_PATH="$BACKUPS_PATH/$backupname"
fi
if [ -d $BACKUP_PATH ]; then
echo "Ya se está usando ese nombre para una copia."
else
mkdir -p $BACKUP_PATH
if [ -d $PROGRAMPATH/utilsx_plugins ]; then
mkdir -p $BACKUP_PATH/utilsx_plugins
cp -r $PROGRAMPATH/utilsx_plugins $BACKUP_PATH/
fi
mkdir -p $BACKUP_PATH/utilsx_data
cp -r $PROGRAMPATH/utilsx_data $BACKUP_PATH/
cp -r $PROGRAMPATH/utilsx.sh $BACKUP_PATH/utilsx.sh
echo -e "\e[32mHecho. \e[0m"
fi
}

# Restaurar el programa a un punto anterior
restoreprogram() {
echo -e "\e[33mLista de copias para restaurar: \e[0m"
ls $BACKUPS_PATH
read -p "Elija una opción: " restoreselec
local BACKUP_PATH="$BACKUPS_PATH/$restoreselec"
if [ -d $BACKUP_PATH ]; then
echo -e "\e[32mRestaurando datos..."
rm -r $PROGRAMPATH/utilsx_data
cp $BACKUP_PATH/utilsx_data $PROGRAMPATH/utilsx_data
if [ -d $PLUGINS_PATH ]; then
echo -e "Restaurando plugins..."
rm -r $PROGRAMPATH/utilsx_plugins
cp $BACKUP_PATH/utilsx_plugins $PROGRAMPATH/utilsx_plugins
fi
echo -e "Restaurando programa...\e[0m"
rm -r $PROGRAMPATH/utilsx.sh
cp $BACKUP_PATH/utilsx.sh $PROGRAMPATH/utilsx.sh
sleep 1
echo -e "\e[33mCompletado. El programa se reiniciará para terminar los cambios.\e[0m"
silenttimer 3
echo " "
$PROGRAMPATH/utilsx.sh
break
else
echo -e "\e[33mNo se encontró la copia de seguridad\e[0m"
echo " "
fi
}

# Menú de backups
backupmenu() {
dontquitbackupmenu=true
if [ -e $BACKUPS_PATH ]; then
:
else
mkdir $BACKUPS_PATH
echo -e "\e[32mSe creará una nueva carpeta de copias de seguridad...\e[0m"
fi
echo -e "\e[1;34mCreación de copias de seguridad de UtilsX\e[0m"
echo -e "\e[33mElija una opción para continuar: \e[0m"
echo "1) Crear una copia del programa"
echo "2) Volver a un punto anterior"
echo "3) Eliminar una copia"
echo "4) Salir"
while $dontquitbackupmenu; do
read -p $'\e[1;33m'"> "$'\e[0m' BACKUPSELEC
case "$BACKUPSELEC" in
  1) completebackup ;;
  2) restoreprogram ;;
  3) removebackup ;;
  4) dontquitbackupmenu=false ;;
esac
done
}

# Función principal del comando CLIMA
clima() {
errorcode=0
# Verifica si USE_DEFAULT_CITY es true en el archivo de configuración, si no es asi pregunta al usuario la ciudad deseada
if [ "$USE_DEFAULT_CITY" = "true" ]; then
CITY="$DEFAULT_CITY"
else 
if [ -z "$1" ]; then
read -p "Elija una ciudad: " CITY
else
CITY=$1
fi
fi
# Verifica si configuraste tu API key
if [ -z "$OPENWEATHERMAP_API_KEY" ]; then
echo -e "\e[33mNo se configuró una API key."
echo "Para obtener su API key de openweathermap, regístrese en openweathermap.org y genere una."
echo -e "Para configurar su API key en UtilsX, use el comando config.\e[0m"
echo " "
errorcode=1
fi
# curl a la API de openweathermap
if [ $errorcode != 1 ]; then
API_KEY="$OPENWEATHERMAP_API_KEY"
cityurl=$(echo "$CITY" | sed 's/ /%20/g')
UNITS="metric"
respuesta=$(curl -s "https://api.openweathermap.org/data/2.5/weather?q=$cityurl&appid=$API_KEY&units=$UNITS")
temp=$(echo "$respuesta" | jq '.main.temp')
desc=$(echo "$respuesta" | jq -r '.weather[0].description')
fi
# Verifica si pusiste una ciudad válida
if [ $errorcode == 0 ]; then
if [ "$temp" == "null" ] || [ -z "$temp" ]; then
echo "Verifica la ciudad y vuelve a intentarlo."
echo " "
errorcode=2
fi
fi
# Muestra la información en pantalla
if [ $errorcode == 0 ]; then
echo "Temperatura en $CITY: $temp ºC"
echo "Estado: $desc"
if [ "$USE_DEFAULT_CITY" = "true" ]; then
echo "¿No es esta tu ciudad? Puedes editarla en las opciones de configuración."
fi
echo " "
fi
}

# Ajustar permisos para copilot
copilotpermissons(){
if [ -e $PROGRAMPATH/utilsx_data/.copilotpermissons.conf ]; then
rm $PROGRAMPATH/utilsx_data/.copilotpermissons.conf
fi
read -p "¿Permite que Copilot pueda ver el contenido de tu directorio actual? (S/N) " copilotfspermissonselec
if [ $copilotfspermissonselec == S ] || [ $copilotfspermissonselec == s ]; then
echo "COPILOT_FS_ACCESS=true" >> $PROGRAMPATH/utilsx_data/.copilotpermissons.conf
else
:
fi
}

# Asistente de IA con openrouter API y modelo deepseek
copilot() {
if [ ! -e $PROGRAMPATH/utilsx_data/.copilotverifier ]; then
echo -e "\e[32mPuedes configurar el asistente con el comando copilot -config\e[0m"
echo "Para ver la lista de parámetros, usa copilot -help"
touch $PROGRAMPATH/utilsx_data/.copilotverifier
fi

# Variables principales
errorcodecopilot=0
dontquitcopilotconfig=true
dontquitcopilotchatmode=true

# Cleanmem
if [[ "$1" == "-cleanmem" ]]; then
rm $PROGRAMPATH/utilsx_data/.copilothist.json
echo " "
echo -e "\e[1;32mHecho.\e[0m"
echo " "
return 0
fi

# Ayuda de UtilsX Copilot
if [[ "$1" == "-help" ]]; then
echo " "
echo "Lista de parámetros para el comando copilot:"
echo "-chat = Inicia el modo chat"
echo "-help = Muestra esta ayuda"
echo "-config = Configura UtilsX Copilot"
echo "-cleanmem = Borra la memoria temporal de Copilot"
echo " "
return 0
fi

# Modo chat
if [[ "$1" == "-chat" ]]; then
echo " "
echo -e "\e[1;34mEntrando en modo chat con UtilsX Copilot.\e[0m"
echo -e "\e[32mEscribe 'exit' para salir del chat.\e[0m"
echo -e "\e[33mAdvertencia: En el modo chat, UtilsX Copilot no podrá ejecutar comandos de UtilsX. Los comandos que UtilsX Copilot intente ejecutar se mostrarán al salir del modo chat."
echo " "
while $dontquitcopilotchatmode; do
read -p $'\e[1;33mUtilsX Copilot > \e[0m' copilotchatmodeinput
if [[ "$copilotchatmodeinput" == "exit" ]]; then
echo " "
echo -e "\e[1;34mSaliendo del modo chat...\e[0m"
echo " "
dontquitcopilotchatmode=false
return 0
fi
copilot "$copilotchatmodeinput"
done
return 0
fi

# Configuración de UtilsX copilot
if [[ "$1" == "-config" ]]; then
echo " "
echo -e "\e[1;34mConfiguración de UtilsX Copilot\e[0m"
echo -e "\e[33mOpciones: \e[0m"
echo "1) Permisos"
echo "2) Salir"
while [ "$dontquitcopilotconfig" == "true" ]; do
read -p $'\e[1;33m'"Elija una opción: "$'\e[0m' copilotconfigselec
case $copilotconfigselec in
1) copilotpermissons ;;
2) dontquitcopilotconfig=false ;;
esac
done
fi

# Variables principales
mensaje="$*"
local api_key="$OPENROUTER_API_KEY"
if [ -e $PROGRAMPATH/utilsx_data/.copilotpermissons.conf ]; then
source $PROGRAMPATH/utilsx_data/.copilotpermissons.conf
fi
if [ "$COPILOT_FS_ACCESS" == "true" ]; then
FILE_LIST=$(ls -1 | head -n 20)
local sysmsg="Eres UtilsX Copilot, un asistente integrado en el programa UtilsX ($longver). Estas en una terminal. Usas solo texto (sin markdown ni LaTeX). El usuario con el que vas a hablar se llama $USERNAME. El directorio actual del usuario es $(pwd) y tiene los archivos $FILE_LIST Puedes ejecutar comandos del programa escribiendo 'utilsx <comando> [argumentos]' sin texto adicional. Los comandos de UtilsX son: help, config, backupmenu, wiki [artículo-de-wikipedia], add_tasks_todo [tarea], timer [segundos], updateprogram, agenda, searchfiles [nombre], todo, qrgen [URL], clima [ciudad-opcional], plugins [parametros: install <nombre>, update, remove], notes [parametros: add <texto>, view, clear]."
else
local sysmsg="Eres UtilsX Copilot, un asistente integrado en el programa UtilsX ($longver). Estas en una terminal. Usas solo texto (sin markdown ni LaTeX). El usuario con el que vas a hablar se llama $USERNAME. Puedes ejecutar comandos del programa escribiendo 'utilsx <comando> [argumentos]' sin texto adicional. Los comandos de UtilsX son: help, config, timer [segundos], agenda, updateprogram, backupmenu, todo, qrgen [URL], clima [ciudad-opcional], searchfiles [nombre], wiki [artículo-de-wikipedia], add_tasks_todo [tarea], plugins [parametros: install <nombre>, update, remove], notes [parametros: add <texto>, view, clear]."
fi

# Verifica si tienes una API key configurada
if [ -z "$api_key" ]; then
echo " "
echo -e "\e[33mNo se encontró una API key para OpenRouter en el archivo de configuración"
echo "Para obtener una, inicie sesión en https://openrouter.ai/ y cree una key"
echo -e "Para configurar sus API keys, use el comando CONFIG\e[0m"
echo " "
errorcodecopilot=1
return 1
echo " "
fi

# Crea el historial de copilot si no existe
if [ ! -e $PROGRAMPATH/utilsx_data/.copilothist.json ]; then
touch $PROGRAMPATH/utilsx_data/.copilothist.json
fi

# Pasa el mensaje a un formato json y lo escribe en el archivo .copilothist.json
json_msg=$(echo "$mensaje" | jq -R '{role: "user", content:.}')
echo "$json_msg">> "$PROGRAMPATH/utilsx_data/.copilothist.json"
mensajes=$(jq -s '.' "$PROGRAMPATH/utilsx_data/.copilothist.json")

# Genera el payload final
payload=$(jq -n \
  --arg model "deepseek/deepseek-r1-distill-llama-70b:free" \
  --arg sysmsg "$sysmsg" \
  --argjson msgs "$mensajes" \
  '{
    model: $model,
    messages: ([{"role": "system", "content": $sysmsg}] + $msgs)
}')

# Curl a la API con el modelo deepseek-r1-distill-llama-70b
if [ $errorcodecopilot == 0 ]; then
RESPONSE=$(curl -s https://openrouter.ai/api/v1/chat/completions \
  -H "Authorization: Bearer $api_key" \
  -H "Content-Type: application/json" \
  -d "$payload" | jq -r '.choices[0].message.content')
fi

# Verifica si la IA utilizó el prefijo para ejecutar comandos de UtilsX
if [[ "$RESPONSE" == *"utilsx "* ]]; then
 comando=$(echo "$RESPONSE" | grep -oP '(?<=utilsx ).*' | head -n 1)
 comando=$(echo "$comando" | cut -d$'\n' -f1)
 copilotcommandfunc=true
fi

# Imprime la respuesta en pantalla sin los comandos ejecutados por la IA
CLEAN_RESPONSE="$(echo "$RESPONSE" | sed -E 's/utilsx[[:space:]]+[[:print:]]*//g')"
echo " "
echo "$CLEAN_RESPONSE"
echo "$RESPONSE" | jq -R '{role: "assistant", content:.}' >> "$PROGRAMPATH/utilsx_data/.copilothist.json"
if [[ "$copilotcommandfunc" == "false" ]]; then
echo " "
fi
}

# Función para buscar un resumen en wikipedia usando su API
wiki() {
local query=$(echo "$*" | sed 's/ /_/g')
local response=$(curl -s "https://es.wikipedia.org/api/rest_v1/page/summary/$query")
local extract=$(echo "$response" | jq -r '.extract')
if [[ "$extract" == "null" || -z "$extract" ]]; then
echo "No se encontró resumen para '$*'."
else 
echo "$extract"
fi
}

# Función para mostrar las tareas en to-do
show_tasks_todo() {
echo "📃 Lista de tareas 📃"
nl -w2 -s'. ' "$TODO_FILE"
echo " "
}

# Función para añadir una contraseña
add_password() {
openssl enc -aes-256-cbc -pbkdf2 -d -iter 200000 -salt -in "$PASSWORD_FILE" -pass pass:"$MASTERKEY" > temp.txt 2>/dev/null || touch temp.txt
read -p "Nombre: " service
read -s -p "Contraseña: " password
echo " "
echo "$service:$password" >> temp.txt
openssl enc -aes-256-cbc -pbkdf2 -iter 200000 -salt -in temp.txt -out "$PASSWORD_FILE" -pass pass:"$MASTERKEY"
echo " "
rm temp.txt
echo "Contraseña guardada y cifrada"
echo " "
}

# Función para ver tus contraseñas guardadas
view_passwords(){
read -s -p "Ingresa tu clave de descifrado: " key
echo " "
echo " "
MASTERKEYVERIFY=$(openssl enc -aes-256-cbc -pbkdf2 -d -salt -iter 200000 -in $PROGRAMPATH/utilsx_data/.masterkey.enc -pass pass:"$key")
openssl enc -aes-256-cbc -pbkdf2 -iter 200000 -d -in "$PASSWORD_FILE" -pass pass:"$MASTERKEYVERIFY"
echo " "
}

# Función del menú del password manager, comando PASSMANAGER
pass_manager() {
dontclosepassmanager=true
# Verifica si es la primera vez que entras al PASSMANAGER, si es así crea una nueva MASTERKEY
if [ -e "$PROGRAMPATH/utilsx_data/.verifier" ]; then
:
else
touch $PROGRAMPATH/utilsx_data/.verifier
read -p "Elija su clave de descifrado: " USERPASS
MASTERKEY=$(openssl rand -base64 32) 
echo "$MASTERKEY" | openssl enc -aes-256-cbc -pbkdf2 -salt -iter 200000 -out ./utilsx_data/.masterkey.enc -pass pass:"$USERPASS"
USERPASS="0"
fi
# Muestra la lista de opciones
echo " "
echo -e "\e[1;34m¡Bienvenido al gestor de contraseñas de UtilsX!\e[0m"
echo -e "\e[33mOpciones: \e[0m"
echo "add = Agregar contraseña"
echo "view = Ver contraseñas"
echo "exit = Salir"
# Bucle principal en el que se definen las opciones
while $dontclosepassmanager; do
read -p $'\e[1;33m'"Elija una opción: "$'\e[0m' opcion
case $opcion in
  add) add_password ;;
  view) view_passwords ;;
  exit) echo " "
        dontclosepassmanager=false ;;
  *) echo "Opción no válida"
esac
done
}

# Función para marcar una tarea como completada en to-do
complete_tasks_todo() {
read -p "Número de tarea a completar: " num
sed -i "${num}s/^/✅ /" "$TODO_FILE"
echo "✅ Tarea marcada como completada"
echo " "
}

# Función para añadir una tarea a to-do
add_tasks_todo() {
if [ -z "$*" ]; then
read -p "Nombre de la tarea a añadir: " task
else
task="$*"
fi
echo "$task" >> "$TODO_FILE"
echo "✅ Tarea añadida"
echo " "
}

# Función para eliminar tareas de to-do
delete_tasks_todo() {
read -p "Número de tarea a eliminar: " num
sed -i "${num}d" "$TODO_FILE"
echo "🗑️ Tarea eliminada"
echo " "
}

# Función principal del menú de to-do
todo() {
echo " "
dontendtodo=true
# Verifica si existe el archivo TODO.txt, si no es así lo crea
if [ -f "$TODO_FILE" ]; then
  echo -e "\e[1;34m¡Bienvenido a UtilsX To-Do!\e[0m"
else
  echo -e "\e[32mSe creará un archivo de tareas en el directorio del programa...\e[0m"
  touch "$TODO_FILE"
  echo -e "\e[1;34m¡Bienvenido a UtilsX To-Do!\e[0m"
fi
# Lista de opciones
echo -e "\e[33mOpciones: \e[0m"
echo "list = Ver lista de tareas"
echo "add = Agregar una tarea"
echo "complete = Marcar una tarea como completada"
echo "del = Eliminar una tarea"
echo "exit = Salir"
echo "help = Muestra este mensaje"
# Aquí se definen las opciones
while $dontendtodo; do
  read -p $'\e[1;33m'"Elija una opción: "$'\e[0m' opciontodo
  case $opciontodo in
    list) show_tasks_todo ;;
    add) add_tasks_todo ;;
    complete) complete_tasks_todo ;;
    exit) echo " "
          dontendtodo=false ;;
    del) delete_tasks_todo ;;
    help) echo -e "\e[33mOpciones: \e[0m"
          echo "list = Ver lista de tareas"
          echo "add = Agregar una tarea"
          echo "complete = Marcar una tarea como completada"
          echo "del = Eliminar una tarea"
          echo "exit = Salir"
          echo "help = Muestra este mensaje"
          echo " " ;;
    *) echo -e "\e[33mEntrada no válida\e[0m" ;;
esac
done
}

# Función para cambiar las API keys en el archivo de configuración, parte del comando CONFIG
setapikeys() {
read -e -p "Escriba su API key de OpenWeatherMap: " newowmapikey
if [[ ! -z "$newowmapikey" ]]; then
if grep -q "^OPENWEATHERMAP_API_KEY=" "$CONFIG_FILE"; then
sed -i "s/^OPENWEATHERMAP_API_KEY=.*/OPENWEATHERMAP_API_KEY=\"$newowmapikey\"/" "$CONFIG_FILE"
else
echo "OPENWEATHERMAP_API_KEY=\"$newowmapikey\"" >> "$CONFIG_FILE"
fi
fi
source "$CONFIG_FILE"

read -e -p "Escriba su API key de OpenRouter: " newopenrtapikey
if [[ ! -z "$newopenrtapikey" ]]; then
if grep -q "^OPENROUTER_API_KEY=" "$CONFIG_FILE"; then
sed -i "s/^OPENROUTER_API_KEY=.*/OPENROUTER_API_KEY=\"$newopenrtapikey\"/" "$CONFIG_FILE"
else
echo "OPENROUTER_API_KEY=\"$newopenrtapikey\"" >> "$CONFIG_FILE"
fi
fi
source "$CONFIG_FILE"

echo "Todas las API keys han sido actualizadas."
}

# Función para cambiar el nombre de usuario en el archivo de configuración, parte del comando CONFIG
setuser() {
read -p "Nuevo nombre de usuario: " newusername
sed -i "s/^USERNAME=.*/USERNAME=\"$newusername\"/" "$CONFIG_FILE"
source "$CONFIG_FILE"
echo "Nombre de usuario actualizado a $USERNAME"
}

# Función de eliminar de la agenda, parte del comando AGENDA
delete_agenda() {
read -p "Número a eliminar: " num
sed -i "${num}d" "$AGENDA_FILE"
echo "🗑️ Eliminado"
echo " "
}

# Función de mostrar a la agenda, parte del comando AGENDA
show_agenda() {
echo "📖 Agenda 📖"
nl -w2 -s'. ' "$AGENDA_FILE"
echo " "
}

# Función de añadir a la agenda, parte del comando AGENDA
add_agenda() {
read -p "Nombre: " name
read -p "Fecha: " fecha
echo "$fecha $name" >> "$AGENDA_FILE"
echo "✅ Añadido"
echo " "
}

# Buscar archivos, comando SEARCHFILES
findmyfiles() {
if [ -z "$1" ]; then
read -p "Nombre (o parte del nombre): " name
elif [ "$1" == "searchfiles" ]; then
read -p "Nombre (o parte del nombre): " name
else
name="$1"
fi
echo "Resultados para $name:"
find . -type f -name "*$name*.*"
echo " "
}

# Función principal de agenda usando el archivo AGENDA.txt, comando AGENDA
agenda() {
echo " "
dontendagenda=true
# Verifica si exite el archivo AGENDA.txt en la carpeta de datos, si no es así crea un archivo nuevo
if [ -f "$AGENDA_FILE" ]; then
  echo -e "\e[1;34m¡Bienvenido a la agenda de UtilsX!\e[0m"
else
  echo -e "\e[32mSe creará un archivo de agenda en el directorio del programa...\e[0m"
  touch "$AGENDA_FILE"
  echo -e "\e[1;34m¡Bienvenido a la agenda de UtilsX!\e[0m"
fi
# Muestra las opciones
echo -e "\e[33mOpciones: \e[0m"
echo "list = Muestra la agenda"
echo "add = Añadir a la agenda"
echo "del = Eliminar de la agenda"
echo "help = Muestra esta ayuda"
echo "exit = Salir"
# Bucle principal, aquí se definen las opciones
while $dontendagenda; do
  read -p $'\e[1;33m'"Elija una opción: "$'\e[0m' opcionagenda
  case $opcionagenda in
    list) show_agenda ;;
    add) add_agenda ;;
    exit) echo " "
	  dontendagenda=false ;;
    del) delete_agenda ;;
    help) echo -e "\e[33mOpciones: \e[0m"
          echo "list = Muestra la agenda"
          echo "add = Añadir a la agenda"
          echo "del = Eliminar de la agenda"
          echo "help = Muestra esta ayuda"
          echo "exit = Salir"
          echo " " ;;
    *) echo "Entrada no válida" ;;
esac
done
}

# Muestra toda la lista de comandos
ayuda() {
if [ $dnmode == false ]; then
echo "Lista de utilidades y comandos:"
echo "1) clima = Ver el clima"
echo "2) passgen = Generador de contraseñas"
echo "3) todo = Lista de tareas"
echo "4) qrgen = Generador de códigos QR"
echo "5) passmanager = Administrador de contraseñas utilizando cifrado"
echo "6) timer (tiempo) = Temporizador"
echo "8) wiki (nombre) = Busca una página en wikipedia y muestra el resumen"
echo "9) agenda = Agenda"
echo "10) notes = Notas rápidas"
echo "11) searchfiles (parte del nombre) = Buscar archivos"
echo "12) copilot <mensaje> = Envía un mensaje a un modelo de IA"
echo "13) ver = Muestra la versión del programa"
echo "14) showmydir/dontshowmydir = Cambia el modo del prompt"
echo "15) plugins = Gestionar plugins (usa plugins help para ver parámetros)"
echo "16) help = Muestra esta ayuda"
echo "17) exit = Salir"
echo "18) config = Configuración del programa"
echo "19) reload = Recarga el programa"
echo "20) El resto de comandos de bash son compatibles"
echo " "
elif [ $dnmode == true ]; then
echo "Lista de utilidades disponibles en este modo: "
echo "1) clima = Ver el clima"
echo "2) passgen = Generador de contraseñas"
echo "3) todo = Lista de tareas"
echo "4) qrgen = Generador de códigos QR"
echo "5) passmanager = Administrador de contraseñas utilizando cifrado"
echo "6) timer (tiempo) = Temporizador"
echo "7) sysinfo = Muestra información del sistema"
echo "8) wiki (nombre) = Busca una página en wikipedia y muestra el resumen"
echo "9) agenda = Agenda"
echo "10) notes = Notas rápidas"
echo "11) searchfiles (parte del nombre) = Buscar archivos"
echo "12) ver = Muestra la versión del programa"
echo "13) plugins = Gestionar plugins (usa plugins help para ver parámetros)"
echo "14) copilot <mensaje> = Envia un mensaje a un modelo de IA"
echo "15) help = Muestra esta ayuda"
echo "16) config = Configuración del programa"
echo " "
else
:
fi
}

# Función para seleccionar el texto del prompt, parte del comando CONFIG
setprompttext() {
read -p "Seleccione el texto del prompt: " selec
prompttext="$selec > "
}

# Eliminar un plugin
removeplugin() {
local pluginnametoremove="$1"
if [ -e $PLUGINS_PATH/${pluginnametoremove}.sh ]; then
rm "$PLUGINS_PATH/${pluginnametoremove}.sh"
echo -e "\e[1;34mEl plugin ha sido removido de su sistema.\e[0m"
echo " "
else
echo -e "\e[33mNo se encontró el plugin $pluginname\e[0m"
echo " "
fi
}

# Instalar plugins desde un repositorio
installplugin() {
local pluginnametoinstall="$1"
local repo_url="https://raw.githubusercontent.com/HerocraftDEV/utilsx-plugins/main/${pluginnametoinstall}.sh"
echo -e "\e[1;34mBuscando el plugin $pluginnametoinstall...\e[0m"

# Descarga el plugin en el directorio de plugins
if curl --head --silent --fail "$repo_url" > /dev/null; then
curl -fsSL "$repo_url" -o "$PROGRAMPATH/utilsx_plugins/${pluginnametoinstall}.sh"
source "$PLUGINS_PATH/${pluginnametoinstall}.sh"
echo -e "\e[1;32mEl plugin ha sido descargado correctamente. \e[0m"

# Verifica si existe una lista de dependencias para este plugin
if grep -q "^plugindep=" "$PLUGINS_PATH/${pluginnametoinstall}.sh"; then
echo -e "\e[33m¡Advertencia! El plugin requiere las siguientes dependencias para su correcto funcionamiento: \e[0m"
for dep in ${plugindep[@]}; do
echo -e "\e[33m$dep\e[0m"
done
echo -e "\e[33mPuedes verificar su disponibilidad con el comando plugins depcheck $pluginnametoinstall"
fi

else
echo -e "\e[1;31mEl plugin no se ha podido descargar correctamente. Verifica su existencia en los repositorios o tu conexión a internet.\e[0m"
fi
echo " "
}

# Actualizar todos los plugins
updateplugins() {
local repo_base="https://raw.githubusercontent.com/HerocraftDEV/utilsx-plugins/main"
for plugin in "$PLUGINS_PATH"/*.sh; do
local name=$(basename "$plugin" .sh)
echo -e "\e[1;34mActualizando $name...\e[0m"
sleep 0.1
curl -s -o "$PLUGINS_PATH/$name.sh" "$repo_base/$name.sh" && \
  echo -e "\e[32mHecho.\e[0m" || \
  echo -e "\e[31mError al actualizar $name. \e[0m"
done
echo -e "\e[1;34mTodos los plugins han sido actualizados.\e[0m"
}

# Verificar las dependencias instaladas de un plugin 
plugindepcheck() {
local pluginnametocheck="$1"
echo -e "\e[32mVerificando dependencias faltantes para el plugin ${pluginnametocheck}...\e[0m"
if [ -e $PLUGINS_PATH/${pluginnametocheck}.sh ]; then
 source "$PLUGINS_PATH/${pluginnametocheck}.sh"
 if grep -q "^plugindep=" "$PLUGINS_PATH/${pluginnametocheck}.sh"; then
  for dep in ${plugindep[@]}; do
  checkdep "$dep"
  done
 else
 echo -e "\e[33mEl plugin no tiene una lista de dependencias.\e[0m"
 fi
else
echo -e "\e[33mPlugin no encontrado.\e[0m"
fi
echo " "
}

# Función para plugins
plugin() {
# Verifica si existe la carpeta de plugins
if [ -d "$PLUGINS_PATH" ]; then
:
else
mkdir "$PLUGINS_PATH"
echo -e "\e[32mSe creará una nueva carpeta de plugins...\e[0m"
fi
PLUGIN_FILE="$PLUGINS_PATH/$2.sh"
# Define cada parámetro
case "$1" in
  view)
  ls $PLUGINS_PATH
  ;;
  info)
  nombre="$2"
  if [ ! -f "$PLUGIN_FILE" ]; then
    echo "Plugin $nombre no encontrado"
  fi
  source "$PLUGIN_FILE"
  echo "Nombre: ${pluginname:-$nombre}"
  echo "Autor: ${pluginauthor:-Desconocido}"
  echo "Descripción: ${plugindesc:-N/A}"
  echo "Versión: ${pluginver:-N/A}"
  ;;
  install*)
  nombre="$2"
  installplugin "$nombre"
  ;;
  remove*)
  nombre="$2"
  removeplugin "$nombre"
  ;;
  update)
  updateplugins
  ;;
  depcheck*)
  nombre="$2"
  plugindepcheck "$nombre"
  ;;
  help)
  echo "Lista de parámetros: "
  echo "install <nombre> - Instala un plugin desde el repositorio oficial"
  echo "remove <nombre> - Elimina un plugin de tu dispositivo"
  echo "view - Muestra la lista de plugins instalados"
  echo "info <nombre> - Muestra la información de un plugin"
  echo "depcheck <nombre> - Verifica si están instaladas las dependencias de un plugin"
  echo " "
  ;;
  *) echo "Escriba plugins help para más información" ;;
esac
}

# Función para mostrar las dependencias, comando DEPENDENCIAS
dependencias() {
echo "Lista de dependencias:"
echo "1) jq - Comando CLIMA"
echo "2) qrencode - Comando QRGEN"
echo "3) openssl - Comando PASSMANAGER"
echo " "
}

# Función de configuración para SET_DEFAULT_CITY en el archivo utilsx.conf, esta función parte del comando CONFIG
setdefaultcity() {
# Eliges tu ciudad predeterminada y verifica si ya existe esa línea en utilsx.conf, si es así modifica la linea actual, si no es asi la añade
read -p "Escriba la ciudad que desea usar como predeterminada: " newcity
if grep -q "^DEFAULT_CITY=" "$CONFIG_FILE"; then
sed -i "s/^DEFAULT_CITY=.*/DEFAULT_CITY=\"$newcity\"/" "$CONFIG_FILE"
else
echo "DEFAULT_CITY=\"$newcity\"" >> "$CONFIG_FILE"
fi

# Te pregunta si deseas usar esa ciudad para todos los comandos que la requieran, y define la variable USE_DEFAULT_CITY en utilsx.conf
read -p "Desea usar siempre esta ciudad para los comandos? (S/N) " tfcity
tfcityselect=$(echo "$tfcity" | tr '[:upper:]' '[:lower:]')
case $tfcityselect in
  s) if grep -q "^USE_DEFAULT_CITY=" "$CONFIG_FILE"; then
     sed -i "s/^USE_DEFAULT_CITY=.*/USE_DEFAULT_CITY=\"true\"/" "$CONFIG_FILE"
     else
     echo "USE_DEFAULT_CITY=true" >> "$CONFIG_FILE"
     fi
     source "$CONFIG_FILE"
     ;;
  n) if grep -q "^USE_DEFAULT_CITY=" "$CONFIG_FILE"; then
     sed -i "s/^USE_DEFAULT_CITY=.*/USE_DEFAULT_CITY=\"false\"/" "$CONFIG_FILE"
     else
     echo "USE_DEFAULT_CITY=false" >> "$CONFIG_FILE"
     fi
     source "$CONFIG_FILE"
     ;;
esac
echo "La ciudad predeterminada se ha establecido correctamente."
}

# Función que muestra información del sistema, comando SYSINFO
systeminfo() {
echo "🖥️ Hostname: $(hostname)"
echo "💿 Sistema operativo: $(uname -o)"
echo "👑 Versión del kernel: $(uname -r)"
echo "👓 Arquitectura: $(uname -m)"
echo "☀  Uptime: $(uptime -p)"
echo " "
}

# Función para generar códigos QR usando qrencode, comando QRGEN
qrgen() {
# Verifica si pusiste algún parámetro, si es así lo usa como texto/URL para el QR
if [ -z "$1" ]; then
read -p "Ingrese el texto o URL para el QR: " qrinput
else
qrinput="$1"
fi
# Genera el qr con qrencode
qrencode -t ANSIUTF8 <<< "$qrinput"
echo "QR generado."
# Pregun
read -p "¿Desea guardar el QR en un archivo? (S/N): " qrsaveoption
qrcleansaveoption=$(echo "$qrsaveoption" | tr '[:upper:]' '[:lower:]')
if [ "$qrcleansaveoption" == "s" ]; then
read -p "Elija el nombre del archivo de salida: " qrname
qrencode -o "${qrname}.png" "$qrinput"
echo "QR guardado como ${qrname}.png"
fi
echo " "
}

# Función para actualizar el programa
updateprogram() {
cp $PROGRAMPATH/utilsx.sh $PROGRAMPATH/utilsx.sh.bak
local repo_url="https://raw.githubusercontent.com/HerocraftDEV/utilsx/refs/heads/master/utilsx.sh"
echo -e "\e[1;34mActualizando UtilsX...\e[0m"
if curl -s "$repo_url" -o "$0"; then
echo -e "\e[32mUtilsX actualizado. Reinicie el programa con RELOAD para completar los cambios\e[0m"
else
echo -e "\e[31mError al actualizar UtilsX.\e[0m"
fi
}

# Función del comando CONFIG
configurar() {
echo " "
# Texto de ayuda
dontquitconfig=true
echo -e "\e[1;34mConfiguración de UtilsX\e[0m"
echo -e "\e[33mSeleccione una opción para continuar...\e[0m"
echo -e "1) Configurar API keys"
echo -e "2) Cambiar nombre de usuario"
echo -e "3) Cambiar ciudad predeterminada"
echo -e "4) Cambiar el texto del prompt"
echo -e "5) Crear copias de seguridad del programa"
echo -e "6) Información de UtilsX"
echo -e "7) Buscar actualizaciones"
echo -e "8) Salir"
while $dontquitconfig; do
read -p $'\e[1;33m'"Opción > "$'\e[0m' configselec
case $configselec in 
  1) setapikeys ;;
  2) setuser ;;
  3) setdefaultcity ;;
  4) setprompttext ;;
  6) echo -e "\e[1;34mUtilsX versión\e[0m \e[33m$longvernv\e[0m"
     echo -e "\e[1;33mComandos ejecutados en esta sesión: $COMMANDCOUNT \e[0m"
     echo "Copyright (C) 2025 HerocraftDEV"
     echo -e "Este software está cubierto por los términos de la licencia GPLv3.\e[0m" ;;
  5) backupmenu ;;
  7) updateprogram ;;
  8) dontquitconfig=false ;; 
  *) echo "Opción no válida"
     echo " " ;;
esac
done
}

# Modo para ejecutar comandos sin entrar al prompt
if [ $# -gt 0 ]; then
dnmodeentry="$1"
shift
cleandnmodeentry=$(echo "$dnmodeentry" | tr '[:upper:]' '[:lower:]')
  case "$cleandnmodeentry" in 
  clima)
    clima
    ;;
  calc)
    calc
    ;;
  wiki*)
    wiki "$@"
    echo " "
    ;;
  help)
    ayuda
    ;;
  saludo)
    echo "¡Hola, $USERNAME!"
    echo " "
    ;;
  todo)
    todo
    ;;
  notes*)
     notes $@
     ;;
  passmanager)
    pass_manager
    ;;    
  timer)
    timer
    ;;
  plugins*)
    plugin $@
    ;;
  plugin*)
    plugin $@
    ;;
  qrgen)
    qrgen $@
    ;;
  passgen)
    random_pass_gen $@
    ;;
  config)
    configurar
    echo " "
    ;;
  searchfiles*)
    findmyfiles $@
    ;;
  copilot)
    copilot $@
    ;;
  ver)
    echo -e "\e[36mUtilsX \e[33m$longver \e[0m"
    echo " "
    ;;
  sysinfo)
    systeminfo
    ;;
  *)
    echo "Parámetro no válido"
    ;;
esac
exit 0
fi

# Bucle principal en donde se definen los comandos
while true; do
  # Define el texto del prompt según la variable showdir
  if [ "$showdir" = "true" ]; then
   prompt="$(pwd) > "
  else
   prompt="$prompttext"
  fi
  
  # Define el read principal y el historial de mensajes
  if [ $copilotcommandfunc == false ]; then
  read -e -p $'\e[32m'"$prompt"$'\e[0m' primeraentrada
  else 
  primeraentrada=$comando
  copilotcommandfunc=false
  fi
  COMMANDCOUNT=$((COMMANDCOUNT +1))
  entradafinal=$(echo "$primeraentrada" | tr '[:upper:]' '[:lower:]')
  if [ -z "$entradafinal" ]; then
    continue
  fi

  # Guarda la entrada en el historial
  echo "$primeraentrada" >> $HISTFILE
  history -s "$primeraentrada"
  
  # Controla la longitud del historial
  LINEAS=$(wc -l < "$HISTFILE")
  if [ "$LINEAS" -gt "$MAXLINES" ]; then
  tail -n "$MAXLINES" "$HISTFILE" > "$HISTFILE.tmp" && mv "$HISTFILE.tmp" "$HISTFILE"
  fi
  
  # Aquí se define lo que hace cada comando
  case "$entradafinal" in 
  wiki*)
    buscar="${primeraentrada#wiki}"
    wiki "$buscar"
    echo " "
    ;;
  help)
    ayuda
    ;;
  qrgen)
    parametro="$primeraentrada#qrgen}"
    qrgen $parametro
    ;;
  exit)
    echo "Cerrando..."
    if [ $devmode == true ]; then
    echo "Eliminando datos y configuraciones del programa..."
    rm -r $PROGRAMPATH/utilsx_data
    if [ -d $PLUGINS_PATH ]; then
    echo "Eliminando plugins..."
    rm -r $PLUGINS_PATH
    fi
    echo "Eliminando verificador de sesión Devmode..."
    rm $HOME/.devmodeverifier
    fi
    if [ -e $PROGRAMPATH/utilsx_data/.copilothist.json ]; then
    rm $PROGRAMPATH/utilsx_data/.copilothist.json
    fi
    break
    ;;
  reload)
    $PROGRAMPATH/utilsx.sh
    break
    ;;
  passmanager)
    pass_manager
    ;;
  dependencias)
    dependencias
    ;;    
  timer)
    timer
    ;;
  plugins*)
    parametro="${primeraentrada#plugins}"
    plugin $parametro
    ;;
  plugin*)
    parametro="${primeraentrada#plugin}"
    plugin $parametro
    ;;
  passgen)
    parametro="${primeraentrada#passgen}"
    random_pass_gen $parametro
    ;;
  config)
    configurar
    echo " "
    ;;
  searchfiles*)
    parametro="${primeraentrada#searchfiles}"
    findmyfiles $parametro
    ;;
  ver)
    echo -e "\e[36mUtilsX \e[33m$longver \e[0m"
    echo " "
    ;;
  showmydir)
    showdir=true
    ;;
  sysinfo)
    systeminfo
    ;;
  dontshowmydir)
    showdir=false
    ;;
  *)
    $primeraentrada
    ;;
esac
parametro=""
done

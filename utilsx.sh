#!/bin/bash
ver="v1.5"
longver="v1.5.4"

# Definiendo rutas de los archivos
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

# Verifica si el directorio de datos del programa existe
if [ -e "$DATA_PATH" ]; then
:
else
echo -e "\e[32mSe creará un nuevo directorio para datos del programa...\e[0m"
echo -e "\e[32mVerificando dependencias...\e[0m"
mkdir utilsx_data
fi
touch "$HISTFILE"
checkdep() {
if ! command -v "$1" >/dev/null 2>&1; then
echo -e "\e[31mFalta '$1'.\e[0m"
fi
}

# Verifica las dependencias
checkdep jq
checkdep bc
checkdep qrencode
checkdep openssl

# Carga de plugins
loadplugins

# Verifica si existe el archivo de configuración
if [ -f "$CONFIG_FILE" ]; then
   source "$CONFIG_FILE"
else
  echo -e "\e[32mSe creará un archivo de configuración...\e[0m"
  echo "Puedes editar tus configuraciones con el comando CONFIG"
  touch "$CONFIG_FILE"
fi
echo " "

# Verifica si USERNAME existe o no, si no es así pregunta tu nombre y lo guarda en el archivo de configuración 
if [ -z "$USERNAME" ]; then
  read -p "Escriba su nombre... " USERNAME
  echo "USERNAME=\"$USERNAME\"" >> "$CONFIG_FILE"
  source "$CONFIG_FILE"
  echo -e "¡Bienvenido, \e[32m$USERNAME!\e[0m Ahora estás en el prompt de \e[33mUtilsX $ver. \e[0m"
else
  echo -e "\e[33mUtilsX $ver\e[0m |\e[1;34m $(date)\e[0m"
  echo -e "¡Hola de nuevo, $USERNAME!"
fi

echo "Para ver la lista de utilidades, escriba HELP"
echo " "

# Define el texto del prompt, carga el historial y habilita la visibilidad del directorio actual en lugar del texto del prompt
prompttext="UtilsX > "
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

# Función principal del comando CLIMA
clima() {
# Verifica si USE_DEFAULT_CITY es true en el archivo de configuración, si no es asi pregunta al usuario la ciudad deseada
if [ "$USE_DEFAULT_CITY" = "true" ]; then
CITY="$DEFAULT_CITY"
else 
read -p "Elija una ciudad: " CITY
fi
# curl a la API de openweathermap
API_KEY="$OPENWEATHERMAP_API_KEY"
cityurl=$(echo "$CITY" | sed 's/ /%20/g')
UNITS="metric"
respuesta=$(curl -s "https://api.openweathermap.org/data/2.5/weather?q=$cityurl&appid=$API_KEY&units=$UNITS")
temp=$(echo "$respuesta" | jq '.main.temp')
desc=$(echo "$respuesta" | jq -r '.weather[0].description')
echo "Temperatura en $CITY: $temp ºC"
echo "Estado: $desc"
if [ "$USE_DEFAULT_CITY" = "true" ]; then
echo "¿No es esta tu ciudad? Puedes editarla en las opciones de configuración."
fi
echo " "
}

# Función para buscar un resumen en wikipedia usando su API
wiki() {
local query=$(echo "$1" | sed 's/ /_/g')
local response=$(curl -s "https://es.wikipedia.org/api/rest_v1/page/summary/$query")
local extract=$(echo "$response" | jq -r '.extract')
if [[ "$extract" == "null" || -z "$extract" ]]; then
echo "No se encontró resumen para '$1'."
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
touch ./utilsx_data/.verifier
read -p "Elija su clave de descifrado: " USERPASS
MASTERKEY=$(openssl rand -base64 32) 
echo "$MASTERKEY" | openssl enc -aes-256-cbc -pbkdf2 -salt -iter 200000 -out ./utilsx_data/.masterkey.enc -pass pass:"$USERPASS"
USERPASS="0"
fi
# Muestra la lista de opciones
echo " "
echo "¡Bienvenido al gestor de contraseñas de UtilsX!"
echo "Opciones: "
echo "add = Agregar contraseña"
echo "view = Ver contraseñas"
echo "exit = Salir"
# Bucle principal en el que se definen las opciones
while $dontclosepassmanager; do
read -p "Elija una opción: " opcion
case $opcion in
  add) add_password ;;
  view) view_passwords ;;
  exit) dontclosepassmanager=false ;;
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
read -p "Nombre de la tarea a añadir: " task
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
dontendtodo=true
# Verifica si existe el archivo TODO.txt, si no es así lo crea
if [ -f "$TODO_FILE" ]; then
  echo "¡Bienvenido a UtilsX To-Do!"
else
  echo "Se creará un archivo de tareas en el directorio del programa..."
  touch "$TODO_FILE"
  echo "¡Bienvenido a UtilsX To-Do!"
fi
# Lista de opciones
echo "Opciones: "
echo "list = Ver lista de tareas"
echo "add = Agregar una tarea"
echo "complete = Marcar una tarea como completada"
echo "del = Eliminar una tarea"
echo "exit = Salir"
echo "help = Muestra este mensaje"
echo " "
# Aquí se definen las opciones
while $dontendtodo; do
  read -p "Seleccione una opción: " opciontodo
  case $opciontodo in
    list) show_tasks_todo ;;
    add) add_tasks_todo ;;
    complete) complete_tasks_todo ;;
    exit) dontendtodo=false ;;
    del) delete_tasks_todo ;;
    help) echo "Opciones: "
          echo "list = Ver lista de tareas"
          echo "add = Agregar una tarea"
          echo "complete = Marcar una tarea como completada"
          echo "del = Eliminar una tarea"
          echo "exit = Salir"
          echo "help = Muestra este mensaje"
          echo " " ;;
    *) echo "Entrada no válida" ;;
esac
done
}

# Función para cambiar las API keys en el archivo de configuración, parte del comando CONFIG
setapikeys() {
read -e -p "Escriba su API key de OpenWeatherMap: " newowmapikey
if grep -q "^OPENWEATHERMAP_API_KEY=" "$CONFIG_FILE"; then
sed -i "s/^OPENWEATHERMAP_API_KEY=.*/OPENWEATHERMAP_API_KEY=\"$newowmapikey\"/" "$CONFIG_FILE"
else
echo "OPENWEATHERMAP_API_KEY=\"$newowmapikey\"" >> "$CONFIG_FILE"
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
read -p "Nombre (o parte del nombre): " name
find . -type f -name "*$name*.*"
echo " "
}

# Función principal de agenda usando el archivo AGENDA.txt, comando AGENDA
agenda() {
dontendagenda=true
# Verifica si exite el archivo AGENDA.txt en la carpeta de datos, si no es así crea un archivo nuevo
if [ -f "$AGENDA_FILE" ]; then
  echo "¡Bienvenido a la agenda de UtilsX!"
else
  echo "Se creará un archivo de agenda en el directorio del programa..."
  touch "$AGENDA_FILE"
  echo "¡Bienvenido a la agenda de UtilsX!"
fi
# Muestra las opciones
echo "Opciones: "
echo "list = Muestra la agenda"
echo "add = Añadir a la agenda"
echo "del = Eliminar de la agenda"
echo "help = Muestra esta ayuda"
echo "exit = Salir"
# Bucle principal, aquí se definen las opciones
while $dontendagenda; do
  read -p "Seleccione una opción: " opcionagenda
  case $opcionagenda in
    list) show_agenda ;;
    add) add_agenda ;;
    exit) dontendagenda=false ;;
    del) delete_agenda ;;
    help) echo "Opciones: "
          echo "list = Muestra la agenda"
          echo "add = Añadir a la agenda"
          echo "del = Eliminar de la agenda"
          echo "help = Muestra esta ayuda"
          echo "exit = Salir";;
    *) echo "Entrada no válida" ;;
esac
done
}

# Muestra toda la lista de comandos
ayuda() {
echo "Lista de utilidades y comandos:"
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
echo "11) searchfiles = Buscar archivos"
echo "12) ver = Muestra la versión del programa"
echo "13) showmydir = Cambia el texto del prompt al directorio actual"
echo "14) dontshowmydir = Cambia el texto del prompt al texto normal"
echo "15) plugins (load/view) = Ver o cargar plugins"
echo "16) help = Muestra esta ayuda"
echo "17) exit = Salir"
echo "18) dependencias = Muestra la lista de programas necesarios para una experiencia completa"
echo "19) config = Configuración del programa"
echo "20) reload = Recarga el programa"
echo "21) El resto de comandos de bash son compatibles"
echo " "
}

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

# Función para seleccionar el texto del prompt, parte del comando CONFIG
setprompttext() {
read -p "Seleccione el texto del prompt: " selec
prompttext="$selec > "
}

removeplugin() {
local pluginname="$1"
if [ -e $PLUGINS_PATH/${pluginname}.sh ]; then
rm "$PLUGINS_PATH/${pluginname}.sh"
echo "El plugin ha sido removido de su sistema."
else
echo "No se encontró el plugin $pluginname"
fi
}

# Instalar plugins desde un repositorio
installplugin() {
local pluginnametoinstall="$1"
local repo_url="https://raw.githubusercontent.com/HerocraftDEV/utilsx-plugins/main/${pluginnametoinstall}.sh"
echo -e "\e[1;34mBuscando el plugin...\e[0m"
if curl --head --silent --fail "$repo_url" > /dev/null; then
curl -fsSL "$repo_url" -o "$PROGRAMPATH/utilsx_plugins/${pluginnametoinstall}.sh"
source "$PLUGINS_PATH/${pluginnametoinstall}.sh"
echo -e "\e[1;32mEl plugin ha sido descargado correctamente. \e[0m"
if grep -q "^plugindep=" "$PLUGINS_PATH/${pluginnametoinstall}.sh"; then
echo -e "\e[33m¡Advertencia! El plugin requiere las siguientes dependencias para su correcto funcionamiento: \e[0m"
echo -e "\e[33m$plugindep\e[0m"
fi

else
echo -e "\e[1;31mEl plugin no se ha podido descargar correctamente.\e[0m"
fi
echo " "
}

# Función para plugins
plugin() {
if [ -d "$PLUGINS_PATH" ]; then
:
else
mkdir "$PLUGINS_PATH"
echo -e "\e[32mSe creará una nueva carpeta de plugins...\e[0m"
fi
PLUGIN_FILE="$PLUGINS_PATH/$2.sh"
case "$1" in
  load)
  if [ -f "$PLUGIN_FILE" ]; then
  source "$PLUGIN_FILE"
  echo -e "\e[32mPlugin cargado\e[0m"
  else
  echo -e "\e[33mPlugin no encontrado\e[0m"
  fi
  ;;
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
  *)
  echo "Uso: plugins (load/view/install) (nombre del plugin si es necesario)"
  ;;
esac
}

# Función para mostrar las dependencias, comando DEPENDENCIAS
dependencias() {
echo "Lista de dependencias:"
echo "1) bc - Comando CALC"
echo "2) jq - Comando CLIMA"
echo "3) qrencode - Comando QRGEN"
echo "4) openssl - Comando PASSMANAGER"
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
read -p "Ingrese el texto o URL para el QR: " qrinput
read -p "Nombre del archivo de salida (sin extensión): " qrname
qrencode -o "${qrname}.png" "$qrinput"
qrencode -t ANSIUTF8 <<< "$qrinput"
echo "QR generado como ${qrname}.png"
echo " "
}

gxstat() {
echo "Información de esta sesión de UtilsX"
echo "Versión: $longver"
echo "Comandos ejecutados: $COMMANDCOUNT"
}

# Función del comando CONFIG
configurar() {
# Texto de ayuda
dontquitconfig=true
echo "Configuración de UtilsX"
echo "Seleccione una opción para continuar..."
echo "1) Configurar API keys"
echo "2) Cambiar nombre de usuario"
echo "3) Cambiar ciudad predeterminada"
echo "4) Cambiar el texto del prompt"
echo "5) Eliminar historial de comandos"
echo "6) Muestra el historial de comandos"
echo "7) Salir"

# Mientras la variable dontquitconfig sea true, se podrá seleccionar una de las 7 opciones
while $dontquitconfig; do
read -p "> " configselec
case $configselec in 
  1) setapikeys ;;
  2) setuser ;;
  3) setdefaultcity ;;
  4) setprompttext ;;
  5) rm $HISTFILE 
     echo "Reinicie el programa con RELOAD para completar los cambios"
     echo " " ;;
  6) cat "$HISTFILE"
     echo " " ;;
  7) dontquitconfig=false ;; 
  *) echo "Opción no válida" ;;
esac
done
}

# Bucle principal en donde se definen los comandos
while true; do
  # Define el texto del prompt según la variable showdir
  if [ "$showdir" = "true" ]; then
   prompt="$(pwd) > "
  else
   prompt="$prompttext"
  fi
  # Define el read principal y el historial de mensajes
  read -e -p $'\e[32m'"$prompt"$'\e[0m' primeraentrada
  COMMANDCOUNT=$((COMMANDCOUNT +1))
  entradafinal=$(echo "$primeraentrada" | tr '[:upper:]' '[:lower:]')
  if [ -z "$entradafinal" ]; then
    continue
  fi
  echo "$primeraentrada" >> $HISTFILE
  history -s "$primeraentrada"
  LINEAS=$(wc -l < "$HISTFILE")
  if [ "$LINEAS" -gt "$MAXLINES" ]; then
  tail -n "$MAXLINES" "$HISTFILE" > "$HISTFILE.tmp" && mv "$HISTFILE.tmp" "$HISTFILE"
  fi
  # Aquí se define lo que hace cada comando
  case "$entradafinal" in 
  clima)
    clima
    ;;
  calc)
    calc
    ;;
  wiki*)
    buscar="${primeraentrada#wiki }"
    wiki "$buscar"
    echo " "
    ;;
  help)
    ayuda
    ;;
  date)
    echo "Fecha: $(date)"
    echo " "
    ;;
  saludo)
    echo "¡Hola, $USERNAME!"
    echo " "
    ;;
  exit)
    echo "Cerrando..."
    break
    ;;
  todo)
    todo
    ;;
  reload)
    $PROGRAMPATH/utilsx.sh
    break
    ;;
   notes)
     notes
     ;;
  gxstat)
     gxstat
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
  plugin*)
    parametro="${primeraentrada#plugins }"
    plugin $parametro
    ;;
  passgen)
    random_pass_gen
    ;;
  config)
    configurar
    echo " "
    ;;
  searchfiles)
    findmyfiles 
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
done




#!/bin/bash
ver="v1.4"
CONFIG_FILE="./utilsx_data/utilsx.conf"
TODO_FILE="./utilsx_data/TODO.txt"
AGENDA_FILE="./utilsx_data/AGENDA.txt"
NOTES_FILE="./utilsx_data/NOTES.txt"
PASSWORD_FILE="./utilsx_data/.passwords.enc"
CONFIG_PATH="./utilsx_data"
if [ -e "$CONFIG_PATH" ]; then
:
else
echo "Se creará un nuevo directorio para datos del programa..."
mkdir utilsx_data
fi

checkdep() {
if ! command -v "$1" >/dev/null 2>&1; then
echo "Falta '$1'. Para más información use el comando DEPENDENCIAS"
fi
}

echo "Verificando dependencias..."
checkdep jq
checkdep bc
checkdep qrencode
checkdep openssl

if [ -f "$CONFIG_FILE" ]; then
   source "$CONFIG_FILE"
else
  echo "Se creará un archivo de configuración..."
  echo "Puedes editar tus configuraciones con el comando CONFIG"
  touch "$CONFIG_FILE"
fi
echo " "
echo "UtilsX $ver | Fecha: $(date)"
if [ -z "$USERNAME" ]; then
  read -p "Escriba su nombre... " USERNAME
  echo "USERNAME=\"$USERNAME\"" >> "$CONFIG_FILE"
  source "$CONFIG_FILE"
  echo "¡Bienvenido, $USERNAME!"
else
  echo "¡Hola, $USERNAME!"
fi

echo "Para ver la lista de utilidades, escriba HELP"
echo " "
prompttext="UtilsX > "
showdir=false

notes() {
local cmd="$1"
shift
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

calc() {
read -p "Seleccione el primer número: " fn
read -p "Seleccione el operador (+ * / -): " op
read -p "Seleccione el segundo número: " sn
resultado=$(echo "scale=2; $fn $op $sn" | bc)
echo "Resultado: $resultado"
echo " "
}
 
random_pass_gen() {
read -p "Longitud: " LONGITUD
echo "Contraseña generada: "
< /dev/urandom tr -dc 'A-Za-z0-9!@#$%&*()_=/\[]' | head -c $LONGITUD
echo
echo " "
}

clima() {
if $USE_DEFAULT_CITY; then
CITY="$DEFAULT_CITY"
else 
read -p "Elija una ciudad: " CITY
fi
API_KEY="$OPENWEATHERMAP_API_KEY"
cityurl=$(echo "$CITY" | sed 's/ /%20/g')
UNITS="metric"
respuesta=$(curl -s "https://api.openweathermap.org/data/2.5/weather?q=$cityurl&appid=$API_KEY&units=$UNITS")
temp=$(echo "$respuesta" | jq '.main.temp')
desc=$(echo "$respuesta" | jq -r '.weather[0].description')
echo "Temperatura en $CITY: $temp ºC"
echo "Estado: $desc"
if $USE_DEFAULT_CITY; then
echo "¿No es esta tu ciudad? Puedes editarla en las opciones de configuración."
fi
echo " "
}

show_tasks_todo() {
echo "📃 Lista de tareas 📃"
nl -w2 -s'. ' "$TODO_FILE"
echo " "
}

add_password() {
openssl enc -aes-256-cbc -d -in  "$PASSWORD_FILE" -pass pass:"$MASTERKEY" > temp.txt 2>/dev/null || touch temp.txt
read -p "Nombre: " service
read -s -p "Contraseña: " password
echo " "
echo "$service:$password" >> temp.txt
openssl enc -aes-256-cbc -salt -in temp.txt -out "$PASSWORD_FILE" -pass pass:"$MASTERKEY"
echo " "
rm temp.txt
echo "Contraseña guardada y cifrada"
echo " "
}

view_passwords(){
read -s -p "Ingresa tu clave de descifrado: " key
echo " "
echo " "
openssl enc -aes-256-cbc -d -in "$PASSWORD_FILE" -pass pass:"$MASTERKEY"
echo " "
}

pass_manager() {
dontclosepassmanager=true
if [ -e "./utilsx_data/.verifier" ]; then
:
else
touch ./utilsx_data/.verifier
echo "$MASTERKEY" | openssl enc -aes-256-cbc -salt -out ./utilsx_data/.masterkey.enc
fi
echo " "
echo "¡Bienvenido al gestor de contraseñas de UtilsX!"
echo "Opciones: "
echo "add = Agregar contraseña"
echo "view = Ver contraseñas"
echo "exit = Salir"
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


complete_tasks_todo() {
read -p "Número de tarea a completar: " num
sed -i "${num}s/^/✅ /" "$TODO_FILE"
echo "✅ Tarea marcada como completada"
echo " "
}

add_tasks_todo() {
read -p "Nombre de la tarea a añadir: " task
echo "$task" >> "$TODO_FILE"
echo "✅ Tarea añadida"
echo " "
}

delete_tasks_todo() {
read -p "Número de tarea a eliminar: " num
sed -i "${num}d" "$TODO_FILE"
echo "🗑️ Tarea eliminada"
echo " "
}

todo() {
dontendtodo=true
if [ -f "$TODO_FILE" ]; then
  echo "¡Bienvenido a UtilsX To-Do!"
else
  echo "Se creará un archivo de tareas en el directorio del programa..."
  touch "$TODO_FILE"
  echo "¡Bienvenido a UtilsX To-Do!"
fi
echo "Opciones: "
echo "list = Ver lista de tareas"
echo "add = Agregar una tarea"
echo "complete = Marcar una tarea como completada"
echo "del = Eliminar una tarea"
echo "exit = Salir"
echo "help = Muestra este mensaje"
echo " "
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

setapikeys() {
read -s -p "Escriba su API key de OpenWeatherMap: " newowmapikey
if grep -q "^OPENWEATHERMAP_API_KEY=" "$CONFIG_FILE"; then
sed -i "s/^OPENWEATHERMAP_API_KEY=.*/OPENWEATHERMAP_API_KEY=\"$newowmapikey\"/" "$CONFIG_FILE"
else
echo "OPENWEATHERMAP_API_KEY=\"$newowmapikey\"" >> "$CONFIG_FILE"
fi
source "$CONFIG_FILE"
echo "Todas las API keys han sido actualizadas."
}

setuser() {
read -p "Nuevo nombre de usuario: " newusername
sed -i "s/^USERNAME=.*/USERNAME=\"$newusername\"/" "$CONFIG_FILE"
source "$CONFIG_FILE"
echo "Nombre de usuario actualizado a $USERNAME"
}

delete_agenda() {
read -p "Número a eliminar: " num
sed -i "${num}d" "$AGENDA_FILE"
echo "🗑️ Eliminado"
echo " "
}

show_agenda() {
echo "📖 Agenda 📖"
nl -w2 -s'. ' "$AGENDA_FILE"
echo " "
}

add_agenda() {
read -p "Nombre: " name
read -p "Fecha: " fecha
echo "$fecha $name" >> "$AGENDA_FILE"
echo "✅ Añadido"
echo " "
}

findmyfiles() {
read -p "Nombre (o parte del nombre): " name
find . -type f -name "*$name*.*"
echo " "
}

agenda() {
dontendagenda=true
if [ -f "$AGENDA_FILE" ]; then
  echo "¡Bienvenido a la agenda de UtilsX!"
else
  echo "Se creará un archivo de agenda en el directorio del programa..."
  touch "$AGENDA_FILE"
  echo "¡Bienvenido a la agenda de UtilsX!"
fi
echo "Opciones: "
echo "list = Muestra la agenda"
echo "add = Añadir a la agenda"
echo "del = Eliminar de la agenda"
echo "help = Muestra esta ayuda"
echo "exit = Salir"
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


ayuda() {
echo "Lista de utilidades y comandos:"
echo "1) calc = Calculadora simple"
echo "2) clima = Ver el clima"
echo "3) passgen = Generador de contraseñas"
echo "4) todo = Lista de tareas"
echo "5) qrgen = Generador de códigos QR"
echo "6) passmanager = Administrador de contraseñas utilizando cifrado"
echo "7) timer (tiempo) = Temporizador"
echo "8) sysinfo = Muestra información del sistema"
echo "9) agenda = Agenda"
echo "10) notes = Notas rápidas"
echo "11) searchfiles = Buscar archivos"
echo "12) ver = Muestra la versión del programa"
echo "13) showmydir = Cambia el texto del prompt al directorio actual"
echo "14) dontshowmydir = Cambia el texto del prompt al texto normal"
echo "15) help = Muestra esta ayuda"
echo "16) exit = Salir"
echo "17) dependencias = Muestra la lista de programas necesarios para una experiencia completa"
echo "18) config = Configuración del programa"
echo "19) reload = Recarga el programa"
echo "20) El resto de comandos de bash son compatibles"
echo " "
}

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

setprompttext() {
read -p "Seleccione el texto del prompt: " selec
prompttext="$selec > "
}

dependencias() {
echo "Lista de dependencias:"
echo "1) bc - Comando CALC"
echo "2) jq - Comando CLIMA"
echo "3) qrencode - Comando QRGEN"
echo "4) openssl - Comando PASSMANAGER"
echo " "
}

setdefaultcity() {
read -p "Escriba la ciudad que desea usar como predeterminada: " newcity
if grep -q "^DEFAULT_CITY=" "$CONFIG_FILE"; then
sed -i "s/^DEFAULT_CITY=.*/DEFAULT_CITY=\"$newcity\"/" "$CONFIG_FILE"
else
echo "DEFAULT_CITY=\"$newcity\"" >> "$CONFIG_FILE"
fi
read -p "Desea usar siempre esta ciudad para los comandos? (S/N) " tfcityselect
case $tfcityselect in
  S) if grep -q "^USE_DEFAULT_CITY=" "$CONFIG_FILE"; then
     sed -i "s/^USE_DEFAULT_CITY=.*/USE_DEFAULT_CITY=\"true\"/" "$CONFIG_FILE"
     else
     echo "USE_DEFAULT_CITY=true" >> "$CONFIG_FILE"
     fi
     source "$CONFIG_FILE"
     ;;
  N) if grep -q "^USE_DEFAULT_CITY=" "$CONFIG_FILE"; then
     sed -i "s/^USE_DEFAULT_CITY=.*/USE_DEFAULT_CITY=\"false\"/" "$CONFIG_FILE"
     else
     echo "USE_DEFAULT_CITY=false" >> "$CONFIG_FILE"
     fi
     source "$CONFIG_FILE"
     ;;
esac
echo "La ciudad predeterminada se ha establecido correctamente."
}

systeminfo() {
echo "🖥️ Hostname: $(hostname)"
echo "💿 Sistema operativo: $(uname -o)"
echo "👑 Versión del kernel: $(uname -r)"
echo "👓 Arquitectura: $(uname -m)"
echo "☀  Uptime: $(uptime -p)"
echo " "
}

qrgen() {
read -p "Ingrese el texto o URL para el QR: " qrinput
read -p "Nombre del archivo de salida (sin extensión): " qrname
qrencode -o "${qrname}.png" "$qrinput"
qrencode -t ANSIUTF8 <<< "$qrinput"
echo "QR generado como ${qrname}.png"
echo " "
}

configurar() {
dontquitconfig=true
echo "Configuración de UtilsX"
echo "Seleccione una opción para continuar..."
echo "1) Configurar API keys"
echo "2) Cambiar nombre de usuario"
echo "3) Cambiar ciudad predeterminada"
echo "4) Cambiar el texto del prompt"
echo "5) Salir"
while $dontquitconfig; do
read -p "> " configselec
case $configselec in 
  1) setapikeys ;;
  2) setuser ;;
  3) setdefaultcity ;;
  4) setprompttext ;;
  5) dontquitconfig=false ;; 
  *) echo "Opción no válida" ;;
esac
done
}

while true; do
  if $showdir; then
   prompt="$(pwd) > "
  else
   prompt="$prompttext"
  fi

  read -p "$prompt" primeraentrada
  entradafinal=$(echo "$primeraentrada" | tr '[:upper:]' '[:lower:]')
  case "$entradafinal" in 
  clima)
    clima
    ;;
  calc)
    calc
    ;;
  help)
    ayuda
    ;;
  date)
    echo "Fecha: $(date)"
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
    ./utilsx.sh
    break
    ;;
   notes)
     notes
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
    echo "UtilsX $ver"
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




#!/bin/bash
ver="v1.3"
CONFIG_FILE="./utilsx.conf"
TODO_FILE="todo.txt"
checkdep() {
if ! command -v "$1" >/dev/null 2>&1; then
echo "Falta '$1'x no podrás usar comandos que lo requieran. Para más información use el comando DEPENDENCIAS"
fi
}

echo "Verificando dependencias..."
checkdep jq
checkdep bc
checkdep qrencode

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
fi

echo "¡Hola de nuevo, $USERNAME!"
echo "Para ver la lista de utilidades, escriba HELP"
echo " "
prompttext="UtilsX > "
showdir=false
calc() {
read -p "Seleccione el primer número: " fn
read -p "Seleccione el operador (+ * / -): " op
read -p "Seleccione el segundo número: " sn
resultado=$(echo "scale=2; $fn $op $sn" | bc)
echo "Resultado: $resultado"
echo " "
}
 
random_pass_gen() {
read -p "Seleccione la longitud: " LONGITUD
echo "Contraseña generada: "
< /dev/urandom tr -dc 'A-Za-z0-9!@#$%&*()_=/\[]' | head -c $LONGITUD
echo
echo " "
}

ppt() {
opciones=("piedra" "papel" "tijera")
read -p "Elije piedra, papel o tijera: " opcppt
jugada=$((RANDOM % 3))
echo "La máquina eligió: ${opciones[$jugada]}"
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

complete_tasks_todo() {
read -p "Número de tarea a completar: "
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
echo "1) list = Ver lista de tareas"
echo "2) add = Agregar una tarea"
echo "3) complete = Marcar una tarea como completada"
echo "4) del = Eliminar una tarea"
echo "5) exit = Salir"
echo "6) help = Muestra este mensaje"
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
          echo "1) list = Ver lista de tareas"
          echo "2) add = Agregar una tarea"
          echo "3) complete = Marcar una tarea como completada"
          echo "4) del = Eliminar una tarea"
          echo "5) exit = Salir"
          echo "6) help = Muestra este mensaje"
          echo " " ;;
    *) echo "Entrada no válida" ;;
esac
done
}

setapikeys() {
read -p "Escriba su API key de OpenWeatherMap: " newowmapikey
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

ayuda() {
echo "Lista de utilidades y comandos:"
echo "1) calc = Calculadora simple"
echo "2) clima = Ver el clima"
echo "3) passgen = Generador de contraseñas"
echo "4) ppt = Juego de piedra, papel o tijera contra la máquina"
echo "5) todo = Lista de tareas"
echo "6) qrgen = Generador de códigos QR"
echo "7) ver = Muestra la versión del programa"
echo "8) showmydir = Cambia el texto del prompt al directorio actual"
echo "9) dontshowmydir = Cambia el texto del prompt al texto normal"
echo "10) help = Muestra esta ayuda"
echo "11) exit = Salir"
echo "12) dependencias = Muestra la lista de programas necesarios para una experiencia completa"
echo "13) config = Configuración del programa"
echo "14) reload = Recarga el programa"
echo "15) El resto de comandos de bash son compatibles"
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
echo "La ciudad predeterminada se ha establecido correctamente. Puedes verificarlo en el archivo utilsx.conf"
}

systeminfo() {
echo "Hostname: $(hostname)"
echo "Sistema operativo: $(uname -o)"
echo "Versión del kernel: $(uname -r)"
echo "Arquitectura: $(uname -m)"
echo "Uptime: $(uptime -p)"
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
echo "Configuración de UtilsX"
echo "Seleccione una opción para continuar..."
echo "1) Configurar API keys"
echo "2) Cambiar nombre de usuario"
echo "3) Cambiar ciudad predeterminada"
echo "4) Cambiar el texto del prompt"
read -p "> " configselec
case $configselec in 
  1) setapikeys ;;
  2) setuser ;;
  3) setdefaultcity ;;
  4) setprompttext ;; 
  *) echo "Opción no válida" ;;
esac
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
  saludo)
    echo "¡Hola, $name!"
    echo " "
    ;;
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
  dependencias)
    dependencias
    ;;    
  ppt)
    ppt
    ;;
  passgen)
    random_pass_gen
    ;;
  config)
    configurar
    echo " "
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




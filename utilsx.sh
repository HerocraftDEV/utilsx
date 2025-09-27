#!/bin/bash
ver="v1.2"
CONFIG_FILE="./utilsx.conf"
if [ -f "$CONFIG_FILE" ]; then
   source "$CONFIG_FILE"
else
  echo "Archivo de configuración no encontrado. El programa creará uno..."
  touch "$CONFIG_FILE"
fi

echo "UtilsX $ver | Fecha: $(date)"
if [ -z "$USERNAME" ]; then
  read -p "Escriba su nombre... " USERNAME
  echo "USERNAME=\"$USERNAME\"" >> "$CONFIG_FILE"
  source "$CONFIG_FILE"
fi

echo "¡Bienvenido, $USERNAME!"
echo "Para ver la lista de utilidades, escriba help"
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
read -p "Ciudad: " city
API_KEY="$OPENWEATHERMAP_API_KEY"
cityurl=$(echo "$city" | sed 's/ /%20/g')
CIUDAD="$cityurl"
UNITS="metric"
respuesta=$(curl -s "https://api.openweathermap.org/data/2.5/weather?q=$CIUDAD&appid=$API_KEY&units=$UNITS")
temp=$(echo "$respuesta" | jq '.main.temp')
desc=$(echo "$respuesta" | jq -r '.weather[0].description')
echo "Temperatura en $city: $temp ºC"
echo "Estado: $desc"
echo " "
}

setapikeys() {
  read -p "Escriba su API key de OpenWeatherMap: " newowmapikey
  echo "OPENWEATHERMAP_API_KEY=\"$newowmapikey\"" >> "$CONFIG_FILE"
  source "$CONFIG_FILE"
  echo "Todas las API keys han sido actualizadas. Puedes revisarlo en el archivo utilsx.conf"
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
echo "5) ver = Muestra la versión del programa"
echo "6) showmydir = Cambia el texto del prompt al directorio actual"
echo "7) dontshowmydir = Cambia el texto del prompt al texto normal"
echo "8) setprompttext = Cambia el texto del prompt al que decidas"
echo "9) help = Muestra esta ayuda"
echo "10) date = Muestra la fecha y hora"
echo "11) saludo = Te saluda"
echo "12) exit = Salir"
echo "13) dependencias = Muestra la lista de programas necesarios para una experiencia completa"
echo "14) reload = Recarga el programa"
echo "15) setusername = Cambia el nombre de usuario"
echo "16) setapikeys = Configura las API keys"
echo " "
}

dependencias() {
echo "Lista de dependencias:"
echo "1) bc - Para los cálculos"
echo "2) jq - Para procesar JSON"
echo "3) curl - Para conectarse a APIs"
echo " "
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
  setapikeys)
    setapikeys
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
  setusername)
    setuser
    ;;
  passgen)
    random_pass_gen
    ;;
  ver)
    echo "UtilsX $ver"
    echo " "
    ;;
  showmydir)
    showdir=true
    ;;
  dontshowmydir)
    showdir=false
    ;;
  setprompttext)
    read -p "Seleccione el texto del prompt: " selec
    prompttext="$selec > "
    ;;
  *)
    $entradafinal
    ;;
esac
done




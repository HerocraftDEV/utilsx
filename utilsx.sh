#!/bin/bash
ver="v1.1"
echo "UtilsX $ver | Fecha: $(date)"
read -p "Escriba su nombre... " name
echo "¡Bienvenido, $name!"
echo "Para ver la lista de utilidades, escriba help"
echo " "

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
API_KEY="a7c478c9d8c57d5d8473860ab40d5f51"
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

ayuda() {
echo "Advertencia: es sensible a mayúsculas"
echo "Lista de utilidades y comandos:"
echo "1) calc = Calculadora simple"
echo "2) clima = Ver el clima"
echo "3) passgen = Generador de contraseñas"
echo "4) ppt = Juego de piedra, papel o tijera contra la máquina"
echo "5) ver = Muestra la versión de la aplicación"
echo "6) help = Muestra esta ayuda"
echo "7) date = Muestra la fecha y hora"
echo "8) saludo = Te saluda"
echo "9) exit = Salir"
echo "10) dependencias = Muestra la lista de programas necesarios para una experiencia completa."
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
  read -p "UtilsX: " entrada
  
  case "$entrada" in 
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
  dependencias)
    dependencias
    ;;    
  ppt)
    ppt
    ;;
  passgen)
    random_pass_gen
    ;;
  ver)
    echo "UtilsX $ver"
    echo " "
    ;;
  *)
    echo "Error: $entrada no es un comando válido"
    echo " "
    ;;
esac
done




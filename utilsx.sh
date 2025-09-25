#!/bin/bash
echo "UtilsX v1.0 | Fecha: $(date)"
read -p "Escriba su nombre... " name
echo "¡Bienvenido, $name!"
echo "Para ver la lista de utilidades, escriba help"
echo " "

calc() {
read -p "Seleccione el primer número: " fn
read -p "Seleccione el segundo número: " sn
read -p "Seleccione el operador (+ * / -): " op
resultado=$(echo "scale=2; $fn $op $sn" | bc)
echo "Resultado: $resultado"
echo " "
} 

clima() {
read -p "Ciudad: " city
API_KEY=""
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
echo "3) help = Muestra esta ayuda"
echo "4) date = Muestra la fecha y hora"
echo "5) saludo = Te saluda"
echo "6) exit = Salir"
echo "7) dependencias = Muestra la lista de programas necesarios para una experiencia completa."
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
    ;;
  exit)
    echo "Cerrando..."
    break
    ;;
  dependencias)
    dependencias
    ;;    
  *)
    echo "Error: $entrada no es un comando válido"
    ;;
esac
done




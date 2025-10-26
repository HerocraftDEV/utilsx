# UtilsX

UtilsX es una herramienta para bash que permite ampliar los comandos que este tiene con herramientas todo en uno. Posee herramientas como ver rápidamente el clima, generador de códigos QR, administrador de contraseñas con cifrado, notas rápidas, y compatibilidad total con los comandos que ya trae el mismo bash. Todo sin salir de la terminal.

## Instalación

Cloná el repositorio y ejecuta el script:
```bash
git clone https://github.com/HerocraftDEV/utilsx.git
cd utilsx
./utilsx.sh
```
Asegurate de tener las siguientes dependencas para una experiencia completa:
- qrencode
- openssl
- jq
- bc

### Características

- 'calc' - Calculadora simple
- 'clima' - Ver el clima actual (requiere configurar tu ciudad en configuraciones y API key)
- 'passgen' - Generador de contraseñas
- 'todo' - Un to-do simple que se guarda en TODO.txt
- 'notes' - Notas rápidas: un solo comando para cualquier cosa
- 'agenda' - Similar a to-do pero modificado para que sea agenda. Se guarda en AGENDA.txt
- 'wiki' - Buscar un resumen en wikipedia
- 'passmanager' - Gestiona contraseñas mediante cifrado
- 'showmydir' / 'dontshowmydir' - Permite cambiar el prompt por el directorio actual o por un texto personalizado que puedes elegir en configuración
- 'qrgen' - Generador de códigos QR
- 'timer' - Temporizador.
- 'searchfiles' - Buscador de archivos por nombre o parte del nombre
- 'config' - Configuración del programa (se guarda en utilsx_data)
- 'sysinfo' - Muestra información de tu sistema
- Y compatibilidad con comandos de bash estándar además de otras utilidades

#### **Configuración**

UtilsX guarda tus preferencias en el archivo utilsx.conf dentro del directorio utilsx_data.
El programa creará los archivos necesarios dentro de ese directorio según las utilidades que vayas usando y las opciones que elijas en el menú CONFIG.

#### Plugins

Los plugins son scripts .sh cuyas funciones se pueden ejecutar como comandos de bash dentro de UtilsX.
Se guardan en la carpeta utilsx_plugins y pueden ser instalados desde el repositorio oficial con PLUGINS INSTALL <nombre> o ser añadidos manualmente por el usuario en el directorio de plugins.

 

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
- curl

### Características

- 'clima' - Ver el clima actual (requiere configurar tu ciudad en configuraciones y API key)
- 'passgen' - Generador de contraseñas
- 'todo' - Un to-do simple que se guarda en TODO.txt
- 'qrgen' - Generador de códigos QR
- 'passmanager' - Administrador de contraseñas
- 'timer <segundos>' - Temporizador
- 'wiki <nombre>' - Resúmen de un artículo de wikipedia
- 'agenda' - Agenda
- 'notes <add/view/clear>' - Notas rápidas
- 'searchfiles <archivoabuscar>' - Buscador de archivos
- 'copilot <mensaje>' - Asistente de IA
- 'plugins' - Sistema de plugins
- Otros comandos de personalización y configuración
- El resto de comandos bash funcionan dentro de UtilsX 

#### **Configuración**

UtilsX guarda tus preferencias en el archivo utilsx.conf dentro del directorio utilsx_data.
El programa creará los archivos necesarios dentro de ese directorio según las utilidades que vayas usando y las opciones que elijas en el menú CONFIG.

#### Plugins

Los plugins son scripts .sh cuyas funciones se pueden ejecutar como comandos de bash dentro de UtilsX.
Se guardan en la carpeta utilsx_plugins y pueden ser instalados desde el repositorio oficial con PLUGINS INSTALL <nombre> o ser añadidos manualmente por el usuario en el directorio de plugins.

 

# Dragon Realm — servidor de desarrollo

Servidor TCP mínimo para probar presencia multijugador, movimiento, chat y persistencia local.

## Requisitos

- Python 3.10 o superior
- Sin dependencias externas

## Ejecutar

Desde la carpeta raíz del proyecto:

    python3 server/server.py

El servidor escucha en el puerto TCP 4010. Para probar desde otro dispositivo de la red local, configura en el cliente la IP LAN del equipo que ejecuta el servidor.

## Protocolo

Los mensajes son objetos JSON, uno por línea. Los tipos implementados son AUTH, MOVE, CHAT, PING y ACTION. El servidor responde con WELCOME, AUTH_OK, STATE y PONG, y emite eventos de presencia, chat y acciones.

Este servidor es una base de desarrollo, no un backend de producción: antes de publicar hacen falta autenticación segura, validación autoritativa del estado, límites de frecuencia, TLS y gestión de sesiones.

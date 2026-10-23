# Dragon Realm development server

Servidor TCP sencillo para probar presencia, movimiento, chat y persistencia básica de personaje.

## Ejecutar

```bash
python3 server.py
```

Escucha en `0.0.0.0:4010` y crea `dragon_realm.db` automáticamente.

## Protocolo actual

- `AUTH`: identifica al personaje y recupera Poder/zona/posición/Zeni guardados.
- `MOVE`: actualiza posición y zona con límites básicos.
- `CHAT`: retransmite mensajes del canal.
- `PING`: responde `PONG`.
- `ACTION`: relay experimental.
- `STATE`: snapshot de jugadores cada 100 ms.

## Estado de producción

Esto sigue siendo un servidor de desarrollo. Antes de exponerlo públicamente deben añadirse TLS, autenticación real, sesiones/tokens, validación autoritativa de movimiento y combate, límites por paquete, rate limit, moderación, backups, migraciones y observabilidad.

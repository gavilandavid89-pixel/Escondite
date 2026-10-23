# Dragon Ball: Dragon Realm

Prototipo RPG 2D para Godot 4.7.2, construido desde cero a partir de ideas de un MMORPG 2D de referencia.

> Este repositorio no reutiliza el código, sprites, mapas, sonidos ni servidores del APK analizado. Los personajes y efectos actuales son recursos originales del prototipo. El proyecto usa nombres/técnicas inspirados en Dragon Ball porque el objetivo actual es un fan-project; una distribución pública de contenido protegido requiere revisar los derechos correspondientes.

## Estado actual

- Mundo lateral con 14 zonas: Valle Azul, Ciudad Capsule, Bosque Oscuro, Desierto Carmesí, Costa Kame, Montañas del Norte, Pantanos de Namek, Base del Ejército Red, Templo del KI, Torre Sagrada, Llanuras del Torneo, Arena Celestial, Tierra Devastada y Camino del Otro Mundo.
- Jugador con HP/KI/Poder/Potencial/Zeni, atributos y puntos de técnica.
- Movimiento lateral, salto, cámara, colisiones y controles táctiles.
- Combate cuerpo a cuerpo y técnicas KI.
- Técnicas raciales cerradas: cada raza posee 6 técnicas propias. Se empieza únicamente con Puño Básico; al completar la quinta misión se desbloquea gratis el KI racial y las demás se compran con Potencial. Las habilidades de mayor daño, control, curación o transformación tienen multiplicadores de coste mayores. Las técnicas aprendidas se pueden mejorar hasta Rango 10. El desbloqueo base parte en 5.000 POT y los rangos 2-10 usan: 10.000 / 25.000 / 60.000 / 100.000 / 160.000 / 250.000 / 500.000 / 1.250.000 / 2.000.000 POT, multiplicados por la dificultad de cada técnica. La técnica KI racial se obtiene gratis al completar la quinta misión.
- 18 familias de mobs, patrullas a distancia, enemigos élite y varios jefes con fase 2 y recompensas regionales. El Poder de cada enemigo es fijo por territorio; al hacer daño ganas Poder y Potencial según daño relativo y diferencia de Poder, con recompensa mínima de +1 para mobs que ya son triviales.
- Misiones principales, entrenamiento, diaria, jefe y las siete esferas.
- NPC maestro, mercader y Shenron.
- Inventario, consumibles, equipo, tienda y crafting.
- Colección persistente de siete Orbes del Dragón.
- Guardado local JSON.
- HUD móvil, minimapa, menú de jugador, social, clan local, ajustes y chat online.
- Cliente TCP JSON y servidor Python con snapshot de presencia, chat y persistencia básica SQLite para desarrollo.
- Sonidos originales y música generada para el prototipo.

## Ejecutar

1. Abre el proyecto con Godot 4.7.2.
2. Ejecuta `Main.tscn`.
3. Para pruebas automáticas:

```bash
Godot --headless --path . -- --self-test
```

4. Para el servidor de desarrollo:

```bash
python3 server/server.py
```

5. Para el test de red:

```bash
Godot --headless --path . --script tests/network_test.gd
```

## Arquitectura

```text
Main
└── World
    ├── MapBase / Valley / City / Forest / Temple
    ├── Player
    ├── Enemies / Boss
    ├── NPC / Merchant / Shenron
    ├── Projectiles / Beam / VFX
    └── HUD

Autoloads
├── GameState
├── SaveManager
├── QuestManager
├── InventoryManager
├── SkillManager
├── AudioManager
└── NetworkClient

Servidor
├── TCP JSON
├── Presence / STATE
├── CHAT
├── AUTH de desarrollo
└── SQLite de desarrollo
```

## Siguiente salto técnico

La base ya está preparada para separar el juego offline del online. Antes de un lanzamiento público faltan, entre otras cosas, autenticación real con TLS, servidor autoritativo de combate, anti-cheat, grupos/clanes sincronizados, PvP, matchmaking, backups/migraciones, panel de administración, más contenido, optimización móvil y un pipeline de recursos/licencias para arte final.

## Reglas de razas
Cada personaje pertenece a una raza y el juego aplica un árbol cerrado de técnicas por raza. `RaceManager` y `SkillManager` validan el aprendizaje y el uso: una habilidad de otra raza no aparece en la barra, no puede aprenderse y no puede ejecutarse aunque se fuerce su ID.

Razas actuales:
- Saiyan: Ráfaga Saiyan, Galick Gun, Kaioken, Meteor Crash, Super Saiyan, Super Saiyan 2.
- Humano: Ráfaga Humana, Kamehameha, Destello Solar, Puño Lobo, Concentración Espiritual, Potencial Liberado.
- Namekiano: Ráfaga Namekiana, Masenko, Brazo Demonio, Regeneración, Explosión Namekiana, Gigante Namekiano.
- Majin: Ráfaga Majin, Majin Beam, Cuerpo Elástico, Regeneración Majin, Candy Beam, Pure Majin.
- Raza Helada: Ráfaga Helada, Death Beam, Telequinesis, Golpe de Cola, Barrera Helada, Golden Form.

## Pruebas recientes
- `RACE_TEST PASS`: restricciones de habilidades por raza + mapas nuevos.
- `SELF_TEST PASS`: mundo, jugador, enemigos, misiones, técnicas y progresión.
- Pruebas visuales: menú, Valle Azul, Ciudad Capsule, Pantanos de Namek, Costa Kame, vuelo y Arena Celestial.
- Jefes avanzados: patrones distintos para Campeón de la Arena, Señor de la Tierra Devastada y Juez del Otro Mundo, además de segunda fase.

### Estadísticas y Potencial
Los personajes no tienen niveles. Todos empiezan con Poder 10. El Potencial acumulado puede gastarse en nueve atributos: Vida, Ataque, KI, Armadura, Crítico %, Daño crítico %, Velocidad, Regeneración KI y Evasión %. Cada atributo tiene un coste independiente: la primera mejora cuesta 1 Potencial, la segunda 2, la tercera 3 y así sucesivamente. Las compras afectan el combate y se guardan en la partida.


## Combat scale (Power-based)

- Characters have no levels; **Power** is the main combat scale.
- Mob HP and attack are derived from mob Power and combat role (melee/ranged/elite/boss).
- Hidden mob stats include armor rating, KI power, crit chance, crit damage and dodge chance.
- Bosses are intentionally durable, but an equal-Power player should defeat one in dozens of meaningful hits, not hundreds/thousands.
- A future boss with 500,000 Power will sit around 3.4 million HP and ~190,000 base attack before phase/critical modifiers.
- Player attack/HP/KI/armor now scale with Power as well, while Potential-funded stats still change the build.
- Early mobs remain useful at the start, then become effectively trivial as Power rises; Power rewards retain the diminishing-return model.

### Progresión de técnicas
Todas las técnicas llegan a Rango 10. La tabla base de Potencial es: desbloqueo/R1 5.000, R2 10.000, R3 25.000, R4 60.000, R5 100.000, R6 160.000, R7 250.000, R8 500.000, R9 1.250.000 y R10 2.000.000. El coste final se multiplica según la dificultad de cada técnica. El KI racial continúa siendo el desbloqueo gratuito de la misión 5.

Cada técnica tiene icono y un directorio de VFX preparado. Si se añade `effect.png`/`effect.webp`/`effect.svg` o `sprite.png`/`sprite.webp` dentro de su carpeta, `SkillPresentation` lo utiliza automáticamente como visual de efecto y conserva un fallback al icono actual.

## Controles de habilidades
- Al entrar, **Puño Básico** queda seleccionado por defecto.
- Un toque sobre una skill solo la selecciona; no la ejecuta.
- Un doble toque rápido ejecuta esa misma skill.
- El botón **EJECUTAR** siempre ejecuta la skill seleccionada. No tiene un ataque propio.
- Si seleccionas Kamehameha, Super Saiyan, Barrera, etc., **EJECUTAR** pasa a ejecutar esa técnica hasta que selecciones otra.
- La selección permanece después de ejecutar la técnica.
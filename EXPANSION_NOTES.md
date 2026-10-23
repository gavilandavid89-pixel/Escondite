# Dragon Realm — expansión inspirada en la referencia del APK

Esta iteración toma ideas observables en el APK aportado por el usuario (mundo 2D online, variedad de mapas, zonas de Tierra/Namek/frío, mobs por zona, progresión y NPCs) y las convierte en contenido original dentro del proyecto.

## Nuevas zonas
- Valle Azul
- Bosque Oscuro
- Ciudad Capsule
- Desierto Carmesí
- Costa Kame
- Montañas del Norte
- Pantanos de Namek
- Templo del KI

## Nuevos mobs
- Lobo Salvaje
- Saibaman
- Saibaman Élite
- Bandido del Desierto
- Dino Carroñero
- Pirata de Kame
- Lobo de Hielo
- Soldado Glacial
- Asaltante de Namek
- Guardián del Templo

## Sistemas ampliados
- Drops por enemigo
- Bestiario persistente
- Contador de derrotas por mob
- Zonas descubiertas
- Más misiones por región
- Nuevo crafting
- Proyectiles de enemigos a distancia
- Jefe con recompensa persistente
- Orbes distribuidos por el mundo

### Expansión de mundo 2
Se añadieron Base del Ejército Red y Torre Sagrada; además de mobs regionales (jabalí, dinosaurio alfa, patrullas Red, comandantes glaciales, guardianes Namek y saqueadores galácticos), loot específico, misiones y bestiario ampliado.

### Expansión de mundo 3 — mobs regionales y territorio
- El catálogo queda en 18 familias de enemigos (incluyendo jefes), cada una con nivel, HP, daño, velocidad, tipo de ataque, color, loot y comportamiento.
- Los mobs se distribuyen por zonas: Valle, Bosque, Desierto, Costa Kame, Montañas del Norte, Namek, Base Red, Templo y Torre Sagrada.
- Los jefes tienen ubicaciones fijas y fase 2 al bajar de 60% HP.
- Los enemigos a distancia usan proyectiles propios.
- Los mobs tienen un límite de territorio para no arrastrar enemigos por todo el mapa.
- El HUD ahora prioriza la misión relacionada con la zona actual.
- El bestiario usa el catálogo real de mobs y el mundo registra zonas descubiertas.
- Los sprites regionales actuales son arte original SVG; están separados del controlador de IA para poder sustituirlos después por sprites pixel-art animados.

## Power / Potential Stat Screen
- No character levels.
- All characters start at Power 10.
- Potential is spendable.
- Statistics: Vida, Ataque, KI, Armadura, Crítico %, Daño crítico %, Velocidad, Regeneración KI and Evasión %.
- First upgrade of each stat costs 1 Potential; each later upgrade of that same stat costs one more than the previous upgrade.
- Stat effects are wired into HP, physical damage, KI pool/damage, damage reduction, crit rolls, movement, KI regeneration and evasion.

### Balance recalibration
Mob balance was reworked around Power as the master scale. Hand-tuned HP/damage values are no longer authoritative for combat; derived role profiles determine HP, attack and hidden combat stats. World spawn difficulty no longer multiplies mob stats from the player's current Power, preventing a high-Power player from accidentally turning a fixed boss into a giant stat sponge.

## Skill progression v10
La progresión de técnicas deja de usar rangos 1-5 y pasa a 1-10. El coste base es 5.000 POT para desbloquear y luego 10.000 / 25.000 / 60.000 / 100.000 / 160.000 / 250.000 / 500.000 / 1.250.000 / 2.000.000 POT por objetivo de rango. Cada técnica aplica un multiplicador de dificultad propio; se ponderan daño base, control, curación, buffs y transformaciones. Esto hace que una técnica de transformación con sustain, como Super Saiyan, sea mucho más cara que una ráfaga básica.

Cada skill mantiene una carpeta visual independiente en `assets/skills/effects/` y la escena `scenes/skills/skill_presentation.tscn` funciona como plantilla para futuras animaciones pixel-art.

## Selección y ejecución de habilidades
- Un toque selecciona una habilidad.
- Doble toque sobre la misma habilidad la ejecuta inmediatamente.
- El botón EJECUTAR usa la habilidad seleccionada; sin selección ejecuta Puño Básico.
- Puño Básico: 1 KI, 1 s de recuperación, escala con Ataque.
- Barrera: universal; mientras dura, cada ataque de mob/boss causa exactamente 1 daño. Cada rango aumenta solo la duración.

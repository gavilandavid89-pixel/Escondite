# Ciclo de verificación

Para cada cambio importante:

1. Ejecutar escaneo/compilación en Godot.
2. Ejecutar `--self-test`.
3. Ejecutar la escena gráficamente con OpenGL si se necesita revisión visual.
4. Buscar `SCRIPT ERROR`, `Parse Error` e `Invalid call`.
5. Ejecutar el test de red si se toca networking.
6. Corregir.
7. Repetir hasta que las pruebas vuelvan a pasar.

Las advertencias de ALSA/dummy audio de la máquina de CI no cuentan como error de lógica del juego.

## Regresión racial y de bosses
- [x] Cada raza muestra solo sus técnicas.
- [x] Una técnica de otra raza no puede aprenderse.
- [x] Una técnica de otra raza no puede usarse.
- [x] Transformación de cada raza se restringe a su propia rama.
- [x] Boss arena_champion: embestida/segunda fase.
- [x] Boss wasteland_overlord: área + ráfaga múltiple/segunda fase.
- [x] Boss otherworld_judge: ráfaga escalonada + reposicionamiento/segunda fase.

## Statistics screen / Potential upgrades
- [x] No character levels; Power is the progression number.
- [x] Potential is spendable for stats and skills.
- [x] Stats screen: Vida, Ataque, KI, Armadura, Crítico %, Daño crítico %, Velocidad, Regeneración KI, Evasión %.
- [x] First upgrade of each stat costs 1 Potential; next upgrade of that same stat costs 2, then 3, etc.
- [x] Stats affect real combat values and are persisted by the save system.
- [x] Critical chance/damage and evasion are wired into damage calculations.
- [x] Statistics regression test passes.

## Habilidades Rango 10
- [x] Todas las técnicas llegan a Rango 10.
- [x] Desbloqueo base: 5.000 POT, ajustado por multiplicador de dificultad.
- [x] Costes de mejora base: 10k / 25k / 60k / 100k / 160k / 250k / 500k / 1.25M / 2M.
- [x] Multiplicadores mayores para daño alto, control, curación y transformaciones.
- [x] Super Saiyan / Super Saiyan 2 tienen curación por golpe y coste de transformación elevado.
- [x] Cada habilidad tiene icono y carpeta `assets/skills/effects/<skill_id>` para sprite/VFX.
- [x] `SkillPresentation` acepta `effect.png`, `effect.webp`, `effect.svg`, `sprite.png` o `sprite.webp` antes de caer al icono.

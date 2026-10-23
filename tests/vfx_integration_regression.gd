extends SceneTree

const REQUIRED_SKILLS := [
    "kamehameha", "galick_gun", "masenko", "death_beam", "majin_beam",
    "namek_burst", "saiyan_ki_burst", "human_ki_burst", "namek_ki_burst",
    "majin_ki_burst", "frost_ki_burst"
]

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var failures: Array[String] = []
    var sm: Node = get_root().get_node("SkillManager")
    for id in REQUIRED_SKILLS:
        var dir: String = str(sm.effect_dir(id))
        if dir == "":
            failures.append("missing_effect_dir:%s" % id)
            continue
        for r in range(1, 11):
            var path := "%s/rank_%02d.png" % [dir, r]
            if not ResourceLoader.exists(path):
                failures.append("missing:%s:%d" % [id, r])
    # Taiyōken and universal Barrier intentionally remain procedural.
    for id in ["solar_flare", "barrier"]:
        var dir: String = str(sm.effect_dir(id))
        if dir == "":
            failures.append("missing_procedural_dir:%s" % id)
        elif ResourceLoader.exists("%s/rank_10.png" % dir):
            failures.append("procedural_skill_got_vfx_assets:%s" % id)
    if failures.is_empty():
        print("[VFX_INTEGRATION_TEST] PASS assets + procedural exclusions")
        quit(0)
    else:
        print("[VFX_INTEGRATION_TEST] FAIL " + ", ".join(failures))
        quit(1)

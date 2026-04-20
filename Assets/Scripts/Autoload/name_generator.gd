extends Node

const NOUNS: Array = [
	"llama", "blob", "mote", "wisp", "ooze", "grub", "slug", "fuzz",
	"spore", "cyst", "mite", "lobe", "glob", "pulp", "yolk", "worm",
	"zoid", "pith", "nub", "tang", "mold", "dust", "fern", "goop",
	"sludge", "clump", "fleck", "murk", "frond", "germ", "speck",
	"crud", "gunk", "slime", "rind", "node", "prion", "drake", "newt",
	"moth", "flea", "toad", "larva", "polyp", "brine", "kelp", "algae",
	"scum", "film", "dreg", "muck", "silt", "naiad", "sprig", "resin",
	"wax", "ichor", "marrow", "cilia", "vacuole", "vesicle", "filament",
	"dendrite", "tendril", "plasm", "spleen", "lumen", "cortex", "ganglion",
	"flagella", "membrane", "capsid", "ribosome", "nucleus", "pilus",
	"zoea", "nauplius", "rotifera", "amoeba", "paramecia", "euglena",
	"tardigrade", "nematode", "rotifer", "daphnia", "copepod", "ciliate",
	"dinoflagellate", "radiolaria", "foraminifera"
]

const ADJECTIVES: Array = [
	"agitated", "slumber", "ancient", "hollow", "feral", "crimson",
	"silent", "noble", "amber", "neon", "vile", "bold", "dire", "calm",
	"wild", "deep", "slow", "vast", "grim", "tame", "pale", "iron",
	"dark", "bright", "swift", "ghost", "sleepy", "hungry", "angry",
	"fuzzy", "tiny", "massive", "glowing", "spotted", "drifting",
	"lurking", "prowling", "resting", "frenzied", "docile", "restless",
	"wandering", "primordial", "evolved", "mutant", "bizarre", "peculiar",
	"rabid", "sunken", "bloated", "withered", "radiant", "sullen",
	"frantic", "serene", "manic", "drowsy", "lurching", "virulent",
	"toxic", "dormant", "spectral", "frozen", "scorched", "thriving",
	"decaying", "festering", "smoldering", "trembling", "seething",
	"brooding", "surging", "waning", "pulsing", "skittering", "lumbering",
	"writhing", "coiling", "starving", "sated", "looming", "fleeting",
	"dwindling", "blooming", "shambling", "darting", "spiraling",
	"wandering", "hollow", "sunlit", "murky", "pallid", "shriveled",
	"swollen", "luminous", "iridescent", "translucent", "opaque",
	"crystalline", "gelatinous", "fibrous", "filamentous", "granular",
	"spiny", "bulbous", "elongated", "flattened", "segmented", "branching"
]

var rng := RandomNumberGenerator.new()

func new_name() -> String:
	return _title_case(NOUNS[rng.randi() % NOUNS.size()])

func mutate_name(parent_name: String) -> String:
	if parent_name.is_empty():
		return new_name()
	var parts := parent_name.to_lower().split(" ")
	var noun  := parts[-1]
	if parts.size() == 1:
		return _title_case(_rand_adj() + " " + noun)
	var adj := parts[0]
	if rng.randf() < 0.75:
		var new_adj := _rand_adj()
		while new_adj == adj:
			new_adj = _rand_adj()
		return _title_case(new_adj + " " + noun)
	else:
		var new_noun: String = NOUNS[rng.randi() % NOUNS.size()]
		return _title_case(adj + " " + new_noun)

func _rand_adj() -> String:
	return ADJECTIVES[rng.randi() % ADJECTIVES.size()]

func _title_case(s: String) -> String:
	var parts := s.split(" ")
	var out   := PackedStringArray()
	for p in parts:
		out.append(p.capitalize())
	return " ".join(out)

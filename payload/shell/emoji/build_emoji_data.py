#!/usr/bin/env python3
"""Parse Unicode emoji-test.txt into the JSON the island emoji panel loads.

Usage: python3 build_emoji_data.py [--source PATH] [--out PATH]

Only "fully-qualified" sequences are kept. Skin-tone variants are dropped from
the list; the base entry gets "tone": true when a single modifier insertion
produces a sequence that exists in the source file (that is the only shape the
panel can rebuild correctly without storing the variants themselves).
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
DEFAULT_SOURCE = HERE.parents[1] / "ref" / "emoji-test.txt"
DEFAULT_OUT = HERE / "emoji-data.json"

LINE_RE = re.compile(
    r"^([0-9A-F ]+?)\s*;\s*([a-z-]+)\s*#\s*(\S+)\s+(E\d+\.\d+)\s+(.*)$"
)

MODIFIERS = (0x1F3FB, 0x1F3FC, 0x1F3FD, 0x1F3FE, 0x1F3FF)
VS16 = 0xFE0F
SKIP_GROUPS = {"Component"}


PHRASE_SYNONYMS: list[tuple[str, list[str]]] = [
    ("thumbs up", ["+1", "ok", "yes", "approve"]),
    ("thumbs down", ["-1", "no", "disagree", "downvote"]),
    ("clapping", ["applause", "bravo", "clap"]),
    ("flexed", ["muscle", "strong", "flex", "power"]),
    ("ok hand", ["okay", "agree", "fine"]),
    ("victory hand", ["peace", "win"]),
    ("crossed fingers", ["luck", "hope", "wish"]),
    ("middle finger", ["rude", "flip"]),
    ("waving hand", ["hello", "hi", "bye", "goodbye", "wave"]),
    ("raised hand", ["stop", "halt", "high five"]),
    ("handshake", ["deal", "agreement", "partnership"]),
    ("folded hands", ["pray", "please", "thanks", "namaste"]),
    ("tears of joy", ["lol", "hilarious", "rofl"]),
    ("grinning", ["happy", "smile", "teeth"]),
    ("smiling face", ["happy", "smile"]),
    ("winking", ["wink", "joke", "flirt"]),
    ("crying", ["sad", "tear", "sob"]),
    ("sobbing", ["sad", "cry", "tears"]),
    ("with steam", ["angry", "mad", "fuming"]),
    ("angry", ["mad", "upset", "rage"]),
    ("skull", ["dead", "dying", "bones"]),
    ("pile of poo", ["poop", "crap", "poo"]),
    ("birthday", ["party", "cake", "celebrate"]),
    ("tada", ["congrats", "hooray", "celebrate", "party"]),
    ("hundred", ["100", "perfect", "score"]),
    ("fire", ["lit", "flame", "burn"]),
    ("rocket", ["launch", "space", "startup", "fast"]),
    ("sparkles", ["shine", "magic", "glitter"]),
    ("broken heart", ["sad", "breakup", "heartbreak"]),
    ("love you", ["ily"]),
    ("kiss", ["mwah", "lips"]),
    ("eyes", ["look", "see", "watch", "stare"]),
    ("brain", ["mind", "think", "smart"]),
    ("light bulb", ["idea", "inspire", "lamp"]),
    ("warning", ["alert", "caution", "careful"]),
    ("check mark", ["yes", "done", "correct"]),
    ("with check", ["vote", "yes"]),
    ("cross mark", ["no", "wrong", "cancel", "x"]),
    ("question mark", ["help", "ask", "why"]),
    ("exclamation", ["wow", "alert", "attention"]),
    ("coffee", ["cafe", "espresso", "caffeine", "morning"]),
    ("beer", ["drink", "alcohol", "cheers"]),
    ("pizza", ["cheese", "slice", "italian"]),
    ("hamburger", ["burger", "fast food"]),
    ("shortcake", ["dessert", "sweet"]),
    ("christmas", ["xmas", "holiday", "santa"]),
    ("halloween", ["spooky", "pumpkin", "scary"]),
    ("gift", ["present", "surprise"]),
    ("money", ["cash", "dollar", "rich"]),
    ("crown", ["king", "queen", "royal", "boss"]),
    ("laptop", ["computer", "pc", "work"]),
    ("mobile phone", ["call", "cell", "text"]),
    ("camera", ["photo", "picture", "selfie"]),
    ("musical note", ["song", "melody"]),
    ("headphone", ["music", "audio", "listen"]),
    ("locked", ["secure", "private", "closed"]),
    ("key", ["password", "access", "unlock"]),
    ("umbrella", ["rain", "weather"]),
    ("snowflake", ["cold", "winter", "ice", "freeze"]),
    ("sun with face", ["sunny", "warm", "weather"]),
    ("crescent moon", ["night", "sleep"]),
    ("high voltage", ["lightning", "electric", "power"]),
    ("dog face", ["puppy", "pet", "doggo"]),
    ("cat face", ["kitten", "pet", "meow"]),
    ("unicorn", ["magic", "mythical", "rainbow"]),
    ("dragon", ["fantasy", "myth"]),
    ("seedling", ["grow", "plant", "sprout"]),
    ("airplane", ["flight", "travel", "plane"]),
    ("automobile", ["car", "drive", "vehicle"]),
    ("shrug", ["whatever", "idk", "dunno"]),
    ("palms up together", ["please", "beg", "receive"]),
    ("facepalm", ["smh", "oops", "doh"]),
    ("yawning", ["tired", "sleepy", "boring"]),
    ("nerd face", ["geek", "glasses", "smart"]),
    ("sunglasses", ["cool", "shade"]),
    ("zany", ["crazy", "wild", "goofy"]),
    ("partying", ["celebrate", "hat", "confetti"]),
    ("saluting", ["respect", "acknowledged"]),
    ("heart eyes", ["love", "crush", "adore"]),
    ("blowing a kiss", ["flirt", "love"]),
    ("red heart", ["love"]),
    ("love letter", ["romance", "crush"]),
    ("shopping", ["buy", "cart", "store"]),
    ("index pointing", ["point", "one"]),
    ("vulcan", ["spock", "live long"]),
    ("writing hand", ["pen", "note", "signature"]),
]


WORD_SYNONYMS: dict[str, list[str]] = {
    "heart": ["love", "romance"],
    "joy": ["lol", "laugh", "haha"],
    "laugh": ["lol", "funny"],
    "party": ["celebrate", "birthday"],
    "star": ["favorite", "rating", "shine"],
    "flower": ["bloom", "spring"],
    "sun": ["sunny", "day"],
    "moon": ["night", "sleep"],
    "snow": ["cold", "winter"],
    "cake": ["dessert", "sweet"],
    "candy": ["sweet", "sugar"],
    "flag": ["country", "nation"],
    "bell": ["notification", "alert"],
    "bug": ["insect", "error"],
    "eye": ["look", "see"],
    "mouth": ["smile", "talk"],
    "wave": ["hello", "goodbye"],
    "clap": ["applause", "bravo"],
    "pray": ["thanks", "please"],
    "walk": ["step", "stroll"],
    "run": ["sprint", "jog"],
    "poop": ["crap", "poo"],
    "ghost": ["boo", "spooky"],
    "pumpkin": ["halloween"],
    "zap": ["lightning", "electric"],
    "anchor": ["ship", "boat", "sea"],
    "coin": ["money", "gold"],
    "chart": ["graph", "growth", "stats"],
    "mail": ["email", "message", "letter"],
    "phone": ["call", "mobile"],
    "bulb": ["idea", "light"],
    "book": ["read", "study"],
    "music": ["song", "melody"],
    "video": ["movie", "film"],
    "mask": ["disguise", "theater"],
    "tool": ["fix", "repair", "wrench"],
    "hammer": ["fix", "build"],
    "pill": ["medicine", "drug", "vitamin"],
    "syringe": ["vaccine", "medicine", "doctor"],
    "bed": ["sleep", "rest"],
    "shower": ["bath", "clean"],
    "broom": ["clean", "sweep"],
    "package": ["box", "delivery"],
    "clown": ["funny", "circus"],
    "alien": ["ufo", "space"],
    "robot": ["bot", "machine", "ai"],
    "gem": ["diamond", "jewel"],
    "trophy": ["winner", "award"],
    "medal": ["award", "win"],
    "dice": ["random", "game", "luck"],
    "chess": ["game", "strategy", "board"],
    "guitar": ["music", "instrument", "rock"],
    "microphone": ["karaoke", "sing", "record"],
    "paint": ["art", "color", "draw"],
    "ticket": ["event", "admit one"],
    "compass": ["direction", "navigate"],
    "mountain": ["hike", "nature", "peak"],
    "beach": ["vacation", "sand", "summer"],
    "camping": ["tent", "outdoors", "hike"],
    "city": ["skyline", "urban"],
    "hospital": ["doctor", "clinic", "health"],
    "school": ["study", "education", "class"],
    "satellite": ["space", "orbit"],
    "shoe": ["sneaker", "footwear", "boot"],
    "glasses": ["spectacles", "nerd"],
    "watch": ["time", "clock"],
    "alarm": ["clock", "wake up"],
    "hourglass": ["time", "wait"],
    "candle": ["light", "birthday"],
    "bomb": ["explosive", "boom"],
    "knife": ["cut", "dagger"],
    "bottle": ["drink", "wine"],
    "balloon": ["party", "birthday"],
    "carousel": ["circus", "fair"],
    "ferris": ["wheel", "fair"],
    "roller": ["coaster", "amusement"],
    "surf": ["wave", "ocean"],
    "ski": ["snow", "slope"],
    "soccer": ["football", "sport"],
    "basketball": ["sport", "hoop"],
    "baseball": ["sport", "bat"],
    "tennis": ["sport"],
    "bowling": ["sport", "pins"],
    "fishing": ["rod", "catch"],
    "yoga": ["meditation", "stretch", "zen"],
    "bicycle": ["bike", "ride", "cycling"],
    "taxi": ["cab", "ride"],
    "truck": ["delivery", "lorry"],
    "tractor": ["farm"],
    "police": ["officer", "cop", "law"],
    "firefighter": ["rescue"],
    "astronaut": ["space"],
    "detective": ["spy", "investigator"],
    "ninja": ["stealth", "fighter"],
    "superhero": ["hero", "comic"],
    "vampire": ["dracula", "fangs"],
    "zombie": ["undead", "brains"],
    "mermaid": ["ocean", "tail"],
    "fairy": ["magic", "wings"],
    "genie": ["wish", "lamp"],
    "bride": ["wedding", "marriage"],
    "baby": ["infant", "cute"],
    "family": ["parents", "kids"],
    "muscle": ["strong", "flex"],
    "lipstick": ["makeup", "cosmetics"],
    "perfume": ["scent", "smell"],
    "soap": ["wash"],
    "tooth": ["dentist", "brush", "teeth"],
    "stethoscope": ["doctor", "medical"],
    "microbe": ["germ", "virus", "bacteria"],
    "test tube": ["science", "lab", "experiment"],
    "dna": ["genetics", "science"],
    "telescope": ["stars", "astronomy"],
    "microscope": ["science", "lab"],
    "extinguisher": ["safety"],
    "couch": ["sofa", "relax"],
    "chair": ["seat", "sit"],
    "cart": ["groceries", "buy"],
    "magnet": ["attract", "fridge"],
    "luggage": ["travel", "baggage", "suitcase"],
    "sunflower": ["yellow"],
    "clover": ["luck", "irish"],
    "mushroom": ["fungus"],
    "cactus": ["desert"],
    "palm": ["tropical", "beach"],
    "tulip": ["spring"],
    "rose": ["love", "romance"],
    "paw": ["pet"],
    "monkey": ["banana", "ape"],
    "bear": ["teddy", "grizzly"],
    "fox": ["kitsune"],
    "wolf": ["howl"],
    "lion": ["savanna"],
    "tiger": ["zoo"],
    "deer": ["antlers", "forest"],
    "raccoon": ["trash panda"],
    "hedgehog": ["spiky"],
    "bat": ["night"],
    "bee": ["honey", "buzz", "sting"],
    "butterfly": ["wings"],
    "snail": ["slow"],
    "spider": ["web", "arachnid"],
    "turtle": ["tortoise", "slow"],
    "snake": ["reptile", "hiss"],
    "dolphin": ["flipper"],
    "whale": ["ocean"],
    "shark": ["ocean"],
    "octopus": ["tentacles"],
    "crab": ["pinch"],
    "lobster": ["seafood"],
    "penguin": ["tuxedo"],
    "eagle": ["freedom"],
    "dove": ["peace"],
    "owl": ["wise", "night"],
    "parrot": ["talk"],
    "flamingo": ["pink"],
    "cocktail": ["drink", "party"],
    "wine": ["drink", "glass"],
    "chopsticks": ["asian", "noodles"],
    "sushi": ["japanese", "fish", "rice"],
    "ramen": ["noodles", "japanese", "soup"],
    "taco": ["mexican", "food"],
    "burrito": ["mexican", "wrap"],
    "french": ["fries", "food"],
    "cookie": ["biscuit", "sweet"],
    "chocolate": ["sweet", "candy"],
    "honey": ["sweet", "bee"],
    "egg": ["breakfast"],
    "bacon": ["breakfast", "meat"],
    "avocado": ["guacamole", "green"],
    "broccoli": ["healthy", "vegetable"],
    "carrot": ["vegetable", "orange"],
    "corn": ["popcorn", "maize"],
    "pepper": ["spicy", "vegetable"],
    "pineapple": ["tropical"],
    "watermelon": ["summer", "fruit"],
    "strawberry": ["berry", "fruit"],
    "banana": ["fruit", "monkey"],
    "apple": ["fruit", "mac"],
    "lemon": ["sour", "fruit"],
}


def words(text: str) -> list[str]:
    return [w for w in re.split(r"[^a-z0-9]+", text.lower()) if w]


def name_tokens(name: str) -> list[str]:
    out = []
    for w in words(name):
        if len(w) >= 2 or w in ("+1", "-1"):
            out.append(w)
    return out


def tone_variants(codepoints: tuple[int, ...], qualified: set[tuple[int, ...]]) -> int:
    """Count valid modifier insertions of the two shapes the panel can build."""
    hits = 0
    for mod in MODIFIERS:
        keep = codepoints[:1] + (mod,) + codepoints[1:]
        if keep in qualified:
            hits += 1
        if len(codepoints) >= 2 and codepoints[1] == VS16:
            drop = codepoints[:1] + (mod,) + codepoints[2:]
            if drop in qualified:
                hits += 1
    return hits


def parse(source: Path) -> tuple[list[dict], dict]:
    group = subgroup = None
    qualified: set[tuple[int, ...]] = set()
    rows: list[tuple[tuple[int, ...], str, str, str]] = []

    for raw in source.read_text(encoding="utf-8").splitlines():
        if raw.startswith("# group:"):
            group = raw[len("# group:"):].strip()
            continue
        if raw.startswith("# subgroup:"):
            subgroup = raw[len("# subgroup:"):].strip()
            continue
        if not raw or raw.startswith("#"):
            continue
        m = LINE_RE.match(raw)
        if not m:
            raise SystemExit(f"unparsable line: {raw!r}")
        cps = tuple(int(h, 16) for h in m.group(1).split())
        if m.group(2) != "fully-qualified":
            continue
        qualified.add(cps)
        rows.append((cps, m.group(5), group or "", subgroup or ""))

    entries: list[dict] = []
    seen: set[tuple[int, ...]] = set()
    stats = {"tone": 0, "skipped_component": 0, "skipped_toned": 0}

    for cps, name, g, sg in rows:
        if g in SKIP_GROUPS:
            stats["skipped_component"] += 1
            continue
        if any(cp in MODIFIERS for cp in cps):
            stats["skipped_toned"] += 1
            continue
        if cps in seen:
            continue
        seen.add(cps)

        name = name.strip()
        tokens = name_tokens(name)
        sub_tokens = [w for w in words(sg) if len(w) >= 2]
        keys: list[str] = []
        for w in tokens + sub_tokens:
            if w not in keys:
                keys.append(w)
        low = name.lower()
        for phrase, extra in PHRASE_SYNONYMS:
            if phrase in low:
                for w in extra:
                    if w not in keys:
                        keys.append(w)
        for w in tokens:
            for extra in WORD_SYNONYMS.get(w, ()):
                if extra not in keys:
                    keys.append(extra)

        tone = tone_variants(cps, qualified) > 0
        if tone:
            stats["tone"] += 1
        entries.append({
            "e": "".join(chr(c) for c in cps),
            "n": name,
            "g": g,
            "sg": sg,
            "k": keys,
            "tone": tone,
        })

    stats["total"] = len(entries)
    return entries, stats


def write_json(path: Path, entries: list[dict]) -> None:
    body = ",\n".join(json.dumps(e, ensure_ascii=False) for e in entries)
    path.write_text("[\n" + body + "\n]\n", encoding="utf-8")


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--source", type=Path, default=DEFAULT_SOURCE)
    ap.add_argument("--out", type=Path, default=DEFAULT_OUT)
    args = ap.parse_args(argv)

    if not args.source.is_file():
        raise SystemExit(f"source not found: {args.source}")

    entries, stats = parse(args.source)
    write_json(args.out, entries)

    by_group: dict[str, int] = {}
    for e in entries:
        by_group[e["g"]] = by_group.get(e["g"], 0) + 1

    print(f"wrote {args.out} ({args.out.stat().st_size} bytes)")
    print(f"  emoji: {stats['total']}  tone-capable: {stats['tone']}")
    print(f"  dropped: {stats['skipped_toned']} toned variants, "
          f"{stats['skipped_component']} component entries")
    for g, n in by_group.items():
        print(f"  {g}: {n}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

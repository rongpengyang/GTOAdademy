#!/usr/bin/env python3
"""离线内容校验（镜像 Swift 侧 ContentValidationTests 的核心规则）。
用法: python3 tools/validate_content.py   # 仓库根目录运行
"""
import json, os, sys

CONTENT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "GTOAcademy", "Content")
os.chdir(CONTENT)

errors = []
RANKS = "23456789TJQKA"

def hc_norm(s):
    if len(s) == 2:
        a, b = s[0].upper(), s[1].upper()
        if a not in RANKS or b not in RANKS or a != b: return None
        return a + a
    if len(s) == 3:
        a, b, k = s[0].upper(), s[1].upper(), s[2].lower()
        if a not in RANKS or b not in RANKS or k not in "so" or a == b: return None
        hi, lo = (a, b) if RANKS.index(a) > RANKS.index(b) else (b, a)
        return hi + lo + k
    return None

def combos(h):
    return 6 if len(h) == 2 else (4 if h.endswith("s") else 12)

def parse_notation(notation):
    result = {}
    for raw in [t.strip() for t in notation.split(",") if t.strip()]:
        token, weight = raw, 1.0
        if ":" in token:
            token, w = token.split(":", 1)
            token = token.strip(); weight = float(w)
            assert 0 < weight <= 1, f"weight out of range: {raw}"
        if "-" in token:
            a, b = token.split("-", 1)
            ha, hb = hc_norm(a), hc_norm(b)
            assert ha and hb, f"bad span token: {raw}"
            if len(ha) == 2 and len(hb) == 2:
                i, j = sorted([RANKS.index(ha[0]), RANKS.index(hb[0])])
                hands = [RANKS[r] * 2 for r in range(i, j + 1)]
            else:
                assert ha[0] == hb[0] and ha[2] == hb[2], f"span mismatch: {raw}"
                i, j = sorted([RANKS.index(ha[1]), RANKS.index(hb[1])])
                hands = [ha[0] + RANKS[r] + ha[2] for r in range(i, j + 1)]
        elif token.endswith("+"):
            h = hc_norm(token[:-1])
            assert h, f"bad plus token: {raw}"
            if len(h) == 2:
                hands = [RANKS[r] * 2 for r in range(RANKS.index(h[0]), 13)]
            else:
                hi, lo = RANKS.index(h[0]), RANKS.index(h[1])
                hands = [h[0] + RANKS[r] + h[2] for r in range(lo, hi)]
        else:
            h = hc_norm(token)
            assert h, f"bad token: {raw}"
            hands = [h]
        for h in hands:
            result[h] = weight
    return result

def lt_ok(obj, ctx):
    if not isinstance(obj, dict) or not obj.get("zh") or not obj.get("en"):
        errors.append(f"{ctx}: 双语字段缺失/为空")
        return False
    return True

texts = []
def collect(obj):
    if isinstance(obj, dict) and set(obj.keys()) == {"zh", "en"}:
        texts.extend([obj["zh"], obj["en"]])

manifest = json.load(open("manifest.json"))
all_ids = []

for name in manifest["lessonFiles"]:
    if not os.path.exists(f"lessons/{name}.json"): errors.append(f"manifest 引用缺失: lessons/{name}.json")
for key, name in manifest["scenarioFiles"].items():
    if not os.path.exists(f"scenarios/{name}.json"): errors.append(f"manifest 引用缺失: scenarios/{name}.json")
for name in manifest["rangeFiles"]:
    if not os.path.exists(f"ranges/{name}.json"): errors.append(f"manifest 引用缺失: ranges/{name}.json")

lesson_ids = set()
for name in manifest["lessonFiles"]:
    tf = json.load(open(f"lessons/{name}.json"))
    all_ids.append(tf["track"]["id"])
    lt_ok(tf["track"]["title"], f"track {tf['track']['id']}"); collect(tf["track"]["title"])
    if tf["track"].get("subtitle"): collect(tf["track"]["subtitle"])
    qmap = {q["id"]: q for q in tf["questions"]}
    for q in tf["questions"]:
        all_ids.append(q["id"])
        if len(q["choices"]) != len(q["choiceExplanations"]):
            errors.append(f"{q['id']}: choices != explanations")
        if not (0 <= q["correctIndex"] < len(q["choices"])):
            errors.append(f"{q['id']}: correctIndex 越界")
        lt_ok(q["prompt"], q["id"]); collect(q["prompt"]); collect(q["objective"])
        for c in q["choices"]: lt_ok(c, f"{q['id']} choice"); collect(c)
        for e in q["choiceExplanations"]: lt_ok(e, f"{q['id']} expl"); collect(e)
    for lesson in tf["lessons"]:
        all_ids.append(lesson["id"]); lesson_ids.add(lesson["id"])
        lt_ok(lesson["title"], lesson["id"]); collect(lesson["title"])
        types = [b["type"] for b in lesson["blocks"]]
        if "concept" not in types: errors.append(f"{lesson['id']}: 缺 concept")
        if "mistake" not in types: errors.append(f"{lesson['id']}: 缺 mistake")
        refs = [b["ref"] for b in lesson["blocks"] if b["type"] == "quizRef"]
        if not refs: errors.append(f"{lesson['id']}: 没有 quizRef")
        for r in refs:
            if r not in qmap: errors.append(f"{lesson['id']}: quizRef {r} 不存在")
        for b in lesson["blocks"]:
            if b["type"] in ("concept", "example", "mistake", "tip"):
                lt_ok(b["text"], f"{lesson['id']} {b['type']}"); collect(b["text"])

pf = json.load(open(f"scenarios/{manifest['scenarioFiles']['preflop']}.json"))
for s in pf["scenarios"]:
    all_ids.append(s["id"])
    lt_ok(s["explanation"], s["id"]); collect(s["explanation"]); collect(s["objective"])
    wrong = s.get("wrongChoices", {})
    if s["correct"] in wrong: errors.append(f"{s['id']}: wrongChoices 含正确答案")
    for a in s.get("acceptable", []):
        if a in wrong: errors.append(f"{s['id']}: wrongChoices 含可接受答案 {a}")
    for k, v in wrong.items():
        if k not in ("fold", "call", "raise", "3bet"): errors.append(f"{s['id']}: 非法 wrong 键 {k}")
        lt_ok(v, f"{s['id']} wrong[{k}]"); collect(v)
    if hc_norm(s["hand"]) != s["hand"]: errors.append(f"{s['id']}: hand 未归一 {s['hand']}")
    if s.get("lessonRef") and s["lessonRef"] not in lesson_ids:
        errors.append(f"{s['id']}: lessonRef {s['lessonRef']} 不存在")
    if s["kind"] == "rfi" and s["facing"]: errors.append(f"{s['id']}: RFI 不应有 facing")
    if s["kind"] != "rfi" and not s["facing"]: errors.append(f"{s['id']}: 缺 facing")
    if not (1 <= s["difficulty"] <= 3): errors.append(f"{s['id']}: difficulty 越界")

def choice_key(c): return c["action"] + (str(c["sizePct"]) if c.get("sizePct") is not None else "")
po = json.load(open(f"scenarios/{manifest['scenarioFiles']['postflop']}.json"))
CARDS = set(r + s for r in RANKS for s in "shdc")
for s in po["scenarios"]:
    all_ids.append(s["id"])
    board = s["board"]
    if len(board) not in (3, 4, 5) or len(set(board)) != len(board) or any(c not in CARDS for c in board):
        errors.append(f"{s['id']}: 非法公共牌 {board}")
    hh = s["heroHand"]
    if len(hh) != 4 or hh[:2] not in CARDS or hh[2:] not in CARDS or hh[:2] == hh[2:]:
        errors.append(f"{s['id']}: 非法 heroHand {hh}")
    if hh[:2] in board or hh[2:] in board:
        errors.append(f"{s['id']}: heroHand 与公共牌冲突")
    ck = choice_key(s["correct"])
    wrong = s.get("wrongChoices", {})
    if ck in wrong: errors.append(f"{s['id']}: wrongChoices 含正确答案 {ck}")
    for a in s.get("acceptable", []):
        if choice_key(a) in wrong: errors.append(f"{s['id']}: wrongChoices 含可接受答案")
    if not s.get("reasonTags"): errors.append(f"{s['id']}: 缺 reasonTags")
    if not s.get("history"): errors.append(f"{s['id']}: 缺 history")
    lt_ok(s["explanation"], s["id"]); collect(s["explanation"]); collect(s["objective"])
    for h in s["history"]: collect(h)
    for v in wrong.values(): collect(v)

VALID_TYPES = {"nit", "tag", "lag", "maniac", "calling_station", "passive_fish"}
pt = json.load(open(f"scenarios/{manifest['scenarioFiles']['playerType']}.json"))
for s in pt["scenarios"]:
    all_ids.append(s["id"])
    if s["correct"] not in VALID_TYPES: errors.append(f"{s['id']}: 非法类型 {s['correct']}")
    if s["stats"]["hands"] <= 0: errors.append(f"{s['id']}: hands 非正")
    lt_ok(s["explanation"], s["id"]); collect(s["explanation"]); collect(s["objective"])

windows = {"rfi-utg-100bb": (12, 16, 182),
           "rfi-hj-100bb": (17, 23, 266),
           "rfi-co-100bb": (24, 29, 350),
           "rfi-btn-100bb": (39, 44, 550),
           "rfi-sb-100bb": (41, 46, 578),
           "bb-call-vs-btn-100bb": (24, 28, 346),
           "bb-call-vs-utg-100bb": (10, 15, 162),
           "bb-call-vs-co-100bb": (18, 23, 266),
           "bb-call-vs-sb-100bb": (29, 34, 424),
           "bb-3bet-vs-btn-100bb": (5, 10, 106),
           "sb-3bet-vs-btn-100bb": (8, 13, 138),
           "btn-3bet-vs-co-100bb": (4, 9, 86)}
for name in manifest["rangeFiles"]:
    rf = json.load(open(f"ranges/{name}.json"))
    all_ids.append(rf["id"])
    collect(rf["name"])
    parsed = parse_notation(rf["notation"])
    total = sum(combos(h) * w for h, w in parsed.items())
    pct = total / 1326 * 100
    lo, hi, expect = windows.get(rf["id"], (5, 60, None))
    ok = lo <= pct <= hi and (expect is None or total == expect)
    if not ok:
        errors.append(f"{rf['id']}: combos={total} pct={pct:.1f}% 预期 {expect} / {lo}-{hi}%")
    print(f"  range {rf['id']}: {len(parsed)} 格, {total:.0f} combos, {pct:.1f}% [{'OK' if ok else 'FAIL'}]")

dup = [i for i in set(all_ids) if all_ids.count(i) > 1]
if dup: errors.append(f"重复 id: {dup}")

banned = json.load(open("config/banned_phrases.json"))["phrases"]
for phrase in banned:
    for t in texts:
        if phrase.lower() in t.lower():
            errors.append(f"命中禁用话术「{phrase}」: {t[:50]}")

cfg = json.load(open("config/classifier.json"))
rule_types = [r["type"] for r in cfg["rules"]]
if set(rule_types) != VALID_TYPES: errors.append(f"分类器规则类型不全: {rule_types}")
if rule_types[:3] != ["maniac", "passive_fish", "calling_station"]:
    errors.append("分类器极端型应排前")

_levels = json.load(open("config/levels.json"))["levels"]
if len(_levels) != 8: errors.append("等级数应为 8")
if [l["id"] for l in _levels] != list(range(1, len(_levels) + 1)):
    errors.append("等级 id 应为 1..n 连续")
_minxp = [l.get("minXP") for l in _levels]
if None in _minxp:
    errors.append("等级缺少 minXP")
elif _minxp[0] != 0 or any(a >= b for a, b in zip(_minxp, _minxp[1:])):
    errors.append("等级 minXP 应自 0 严格递增")

print(f"\n文本片段 {len(texts)} 条 | 内容 id {len(all_ids)} 个")
if errors:
    print("\n=== 校验失败 ===")
    for e in errors: print(" ✗", e)
    sys.exit(1)
print("=== 全部校验通过 ✓ ===")

#!/usr/bin/env python3
"""翻前精编题同源生成器（M8，PRD §215 / §312 钦定的"模板化生成"策略）。

原理：答案不靠人写，从 12 张范围表机械推导——与 Tools 页范围矩阵、无尽模式
判定永远同源。解释按「家族 × 判定类」模板渲染（人工口径，确定性变体）。

幂等：重跑只重建 id 前缀为 `pf-g-` 的生成题，手写题（pf-*）原样保留。
同源对账：本文件的记法解析与 tools/validate_content.py 保持同一语法；
运行时把每张表的总组合数与校验器固化的 windows 精确核对，漂移即崩。

用法: python3 tools/generate_preflop.py   # 仓库根目录运行
"""
import json, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
CONTENT = os.path.join(HERE, "..", "GTOAcademy", "Content")
RANKS = "23456789TJQKA"

# ---- 记法解析（与 validate_content.py 同源；改语法须两处同步）----
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
        if "-" in token:
            a, b = token.split("-", 1)
            ha, hb = hc_norm(a), hc_norm(b)
            if len(ha) == 2 and len(hb) == 2:
                i, j = sorted([RANKS.index(ha[0]), RANKS.index(hb[0])])
                hands = [RANKS[r] * 2 for r in range(i, j + 1)]
            else:
                i, j = sorted([RANKS.index(ha[1]), RANKS.index(hb[1])])
                hands = [ha[0] + RANKS[r] + ha[2] for r in range(i, j + 1)]
        elif token.endswith("+"):
            h = hc_norm(token[:-1])
            if len(h) == 2:
                hands = [RANKS[r] * 2 for r in range(RANKS.index(h[0]), 13)]
            else:
                hi, lo = RANKS.index(h[0]), RANKS.index(h[1])
                hands = [h[0] + RANKS[r] + h[2] for r in range(lo, hi)]
        else:
            hands = [hc_norm(token)]
        for h in hands:
            result[h] = weight
    return result

# ---- 载入图表并与校验器固化窗口对账 ----
vsrc = open(os.path.join(HERE, "validate_content.py"), encoding="utf-8").read()
windows = eval(re.search(r"windows = (\{.*?\})", vsrc, re.S).group(1))

manifest = json.load(open(os.path.join(CONTENT, "manifest.json"), encoding="utf-8"))
charts, pct = {}, {}
for name in manifest["rangeFiles"]:
    d = json.load(open(os.path.join(CONTENT, "ranges", f"{name}.json"), encoding="utf-8"))
    weights = parse_notation(d["notation"])
    for c in d.get("cells") or []:
        weights[hc_norm(c["hand"])] = c["weight"]
    total = sum(combos(h) * w for h, w in weights.items())
    cid = d["id"]
    assert cid in windows and round(total) == windows[cid][2], \
        f"同源对账失败 {cid}: 解析 {round(total)} vs 校验器 {windows[cid][2]}"
    charts[cid], pct[cid] = weights, round(total / 1326 * 100)
print(f"同源对账：{len(charts)} 张表组合数与校验器逐表一致 ✓")

def W(cid, hand): return charts[cid].get(hand, 0.0)

# ---- 手牌特征 ----
def traits(h):
    pair = len(h) == 2
    suited = h.endswith("s"); off = h.endswith("o")
    hi, lo = h[0], h[1]
    gap = 0 if pair else RANKS.index(hi) - RANKS.index(lo)
    return dict(pair=pair, suited=suited, off=off, hi=hi, lo=lo,
                conn=(not pair and gap == 1),
                wheel=(suited and hi == "A" and lo in "2345"),
                broad=set(h[:2]) <= set("AKQJT"),
                bigpair=(pair and RANKS.index(hi) >= RANKS.index("T")),
                lowpair=(pair and RANKS.index(hi) <= RANKS.index("7")))

def trait_phrase(h):
    t = traits(h)
    if t["bigpair"]: return ("大口袋对自带摊牌价值与压制力", "a big pocket pair with built-in showdown value and dominance")
    if t["lowpair"]: return ("小口袋对的核心资产是暗三条潜力", "a small pair whose core asset is set potential")
    if t["pair"]: return ("中口袋对兼具摊牌价值与成套潜力", "a middling pair with both showdown value and set potential")
    if t["wheel"]: return ("轮子 A 同花：阻断 AA/AK 关键组合，还带同花与顺子补牌", "a wheel ace: it blocks key AA/AK combos and carries flush and straight backup")
    if t["suited"] and t["conn"]: return ("同花连张的全方位可玩性：同花、顺子、两对路线齐备", "a suited connector with full playability — flush, straight and two-pair routes")
    if t["suited"] and t["broad"]: return ("同花高张：命中顶对带好踢脚，还有坚果同花潜力", "suited broadway: top pair comes with a good kicker plus nut-flush potential")
    if t["suited"]: return ("同花结构提供后门与可玩性，但当下牌力有限", "the suited structure offers backdoors and playability, though raw strength is modest")
    if t["broad"]: return ("两张高张好看，但反向支配风险高——命中顶对常被更大踢脚压住", "two pretty high cards with heavy reverse-domination risk — top pair often loses to a bigger kicker")
    return ("既缺连接又缺同花，几乎没有翻后剧本", "no connectivity, no suit — almost no postflop script")

POS = {"utg": "UTG", "hj": "HJ", "co": "CO", "btn": "BTN", "sb": "SB", "bb": "BB"}
def L(zh, en): return {"zh": zh, "en": en}
def FACING(opp): return [{"position": opp, "action": "raise", "sizeBB": 2.5}]
def pick(seq, key): return seq[sum(map(ord, key)) % len(seq)]

# ---- 模板（zh, en 成对；{hand}{pos}{opp}{pct}{op_pct}{trz}{tre} 槽位）----
TPL = {
 "r_premium": [
  ("{hand} 在 {pos} 属于无条件开局的顶端牌力：{trz}。加注 2.5bb 同时完成建锅、争位与施压三件事。",
   "{hand} is unconditional opening strength from {pos}: {tre}. Raising to 2.5bb builds the pot, fights for position and applies pressure in one motion."),
  ("范围最顶端不需要犹豫：{hand} 从 {pos} 加注既为价值也为主动权——这正是该位置约 {pct}% 开局范围的骨架。",
   "The top of the range needs no deliberation: {hand} opens from {pos} for value and initiative alike — the very skeleton of its ~{pct}% opening range.")],
 "r_std": [
  ("{hand} 落在 {pos} 约 {pct}% 的开局范围之内：{trz}。标准加注 2.5bb，让更差的牌付费进场。",
   "{hand} sits inside {pos}'s ~{pct}% opening range: {tre}. Open the standard 2.5bb and make worse hands pay to play."),
  ("按表行事：{pos} 的开局表收录了 {hand}——{trz}。开到 2.5bb 即可，不需要额外理由。",
   "Play the chart: {pos}'s opening range includes {hand} — {tre}. Raise to 2.5bb; no further justification required.")],
 "r_spec": [
  ("{hand} 进入 {pos} 开局表靠的不是当下牌力而是结构：{trz}。位置越靠后这类牌越值钱，照表加注 2.5bb。",
   "{hand} earns its slot in {pos}'s chart on structure, not raw strength: {tre}. Hands like this gain value with position — open 2.5bb per the chart."),
  ("{pos} 约 {pct}% 的范围宽到足以容纳 {hand}：{trz}，偷盲收益与翻后可玩性双线进账。",
   "{pos}'s ~{pct}% range is wide enough for {hand}: {tre}, collecting on both blind pressure and postflop playability.")],
 "r_mixed": [
  ("{hand} 正坐在 {pos} 开局线的边缘（混合频率格）：{trz}。本表以加注为主线，弃牌同样在均衡之内——别把它当成必开牌。",
   "{hand} sits right on {pos}'s opening line (a mixed-frequency cell): {tre}. The chart leans raise, and folding lives in the equilibrium too — never treat it as a mandatory open.")],
 "f_trap": [
  ("{hand} 是 {pos} 最典型的「好看陷阱」：{trz}。它落在约 {pct}% 开局线之外——损失不发生在现在，而发生在翻后被更大踢脚收割时。",
   "{hand} is {pos}'s classic pretty trap: {tre}. It sits outside the ~{pct}% opening line — the loss comes not now, but postflop when a bigger kicker collects."),
  ("高张不等于好牌：{pos} 的开局表把 {hand} 留在门外，因为命中顶对反而是它最贵的剧本。",
   "High cards are not good cards: {pos}'s chart leaves {hand} outside, because hitting top pair is its most expensive script.")],
 "f_near": [
  ("{hand} 紧贴 {pos} 开局线的外侧：同样的结构放进更宽的范围就是标准开局，在这里仍是纪律弃牌——每一格收紧，都是位置在说话。",
   "{hand} hugs the outside of {pos}'s opening line: the same structure is a standard open in a wider range, here it stays a disciplined fold — every notch of tightening is position speaking.")],
 "f_junk": [
  ("{hand} 与 {pos} 约 {pct}% 的开局范围之间隔着整张牌表：{trz}。弃牌，把筹码留给有故事的牌。",
   "{hand} sits a full chart away from {pos}'s ~{pct}% opening range: {tre}. Fold and save the chips for hands with a story.")],
 "c_pair": [
  ("口袋 {hand} 防守 {opp} 开局的首选是平跟：关锅价合适、暗三条潜力完整；3-bet 反而赶走愿意付钱的部分。",
   "Pocket {hand} defends the {opp} open by calling: the closing price is right and set potential stays intact; 3-betting only chases away the hands that pay."),
  ("{hand} 走「便宜进场、命中成套再收割」的剧本：大盲只需再补 1.5bb，这正是小对最舒服的价格。",
   "{hand} runs the cheap-entry, set-and-collect script: the big blind tops up only 1.5bb — exactly the price small pairs love.")],
 "c_suited": [
  ("{hand} 进入大盲防守表：{trz}。作为关锅方只需再补 1.5bb，这类牌的隐含赔率因此成立。",
   "{hand} makes the big-blind defending chart: {tre}. Closing the action for just 1.5bb more is what makes its implied odds work."),
  ("面对 {opp} 约 {op_pct}% 的开局，{hand} 的防守逻辑是价格 + 结构：{trz}。",
   "Against {opp}'s ~{op_pct}% open, {hand} defends on price plus structure: {tre}.")],
 "c_broad": [
  ("{hand} 对 {opp} 约 {op_pct}% 的开局范围领先或持平大半，平跟防守把对手的弱牌留在锅里继续犯错。",
   "{hand} runs ahead of or even with most of {opp}'s ~{op_pct}% opening range; calling keeps his weaker hands in the pot to keep making mistakes.")],
 "c_mixed": [
  ("{hand} 坐在防守线边缘（混合频率）：价格勉强成立，劣势同样真实。本表以跟注为主线，弃牌完全均衡。",
   "{hand} sits on the defending line (mixed frequency): the price barely works and the drawbacks are real. The chart leans call; folding is fully balanced.")],
 "df_dom": [
  ("{hand} 面对 {opp} 开局的问题不是牌力而是「赢小输大」：{trz}。这正是防守表把它排除的原因。",
   "{hand}'s problem against the {opp} open is not strength but win-small-lose-big: {tre}. That is exactly why the defending chart leaves it out.")],
 "df_near": [
  ("{hand} 贴着防守线外：同样结构再高一格就进表。关锅价虽诱人，纪律弃牌长期更便宜。",
   "{hand} hugs the outside of the defending line: one notch higher and the same structure makes the chart. The closing price tempts, but the disciplined fold is cheaper long-term.")],
 "df_junk": [
  ("{hand} 连大盲的关锅价都救不动：{trz}。省下这 1.5bb。",
   "Not even the big blind's closing price rescues {hand}: {tre}. Save the 1.5bb.")],
 "t_value": [
  ("{hand} 对 {opp} 约 {op_pct}% 的开局是清晰的价值 3-bet：把死钱与更差牌的跟注一起收进来，同时夺回主动权。",
   "{hand} is a clean value 3-bet against {opp}'s ~{op_pct}% open: collect the dead money and worse hands' calls while taking back the initiative."),
  ("面对这么宽的开局范围，{hand} 的压制力必须立刻变现——3-bet 为价值建锅，也让对手的中等牌当场两难。",
   "Against an open this wide, {hand}'s dominance must cash in now — 3-bet to build for value and put his medium hands in an instant bind.")],
 "t_value_dual": [
  ("{hand} 对 {opp} 的宽开局以价值 3-bet 为主线；平跟伪装同样收录在防守表里——两条路都在均衡内，但别把弃牌当选项。",
   "{hand} 3-bets {opp}'s wide open for value as the main line; the disguised flat-call also lives in the defending chart — both roads are in equilibrium, but folding is not one of them.")],
 "t_blocker": [
  ("{hand} 是 3-bet 表的诈唬翼：轮子 A 阻断对手 AA/AK 的关键组合，被跟注仍有同花顺子补牌，被 4-bet 时弃牌损失最小——教科书阻断牌诈唬。",
   "{hand} is the bluff wing of the 3-bet chart: the wheel ace blocks his key AA/AK combos, flush and straight backup survives a call, and folding to a 4-bet costs the minimum — textbook blocker bluff.")],
 "t_semibluff": [
  ("{hand} 站在 3-bet 表的进攻翼：同花结构带补牌、对 {opp} 约 {op_pct}% 的宽开局有充足弃牌权益，被跟注也不至于裸奔——价值与诈唬之间的弹性件，平跟同样收录在防守表里。",
   "{hand} mans the attacking wing of the 3-bet chart: suited backup, ample fold equity against {opp}'s ~{op_pct}% open, and never naked when called — the flex piece between value and bluff, with the flat-call also living in the defending chart.")],
 "tf_pretty": [
  ("{pos} 面对 {opp} 开局的剧本是「3-bet 或弃牌」：{hand} 价值不足、阻断平庸，平跟又把自己钉在劣势位置——按表弃牌。",
   "{pos}'s script versus the {opp} open is 3-bet-or-fold: {hand} lacks the value, the blockers are ordinary, and flatting nails you into the worst seat — fold per the chart.")],
 "tf_junk": [
  ("{hand} 离 {pos} 的 3-bet 表（约 {pct}% ）很远：没有价值、没有阻断、没有补牌结构——连诈唬的资格都排不上。",
   "{hand} sits far from {pos}'s ~{pct}% 3-bet chart: no value, no blockers, no backup structure — it does not even qualify as a bluff.")],
}

WRONG = {
 ("raise", "fold"): [
  ("{hand} 在 {pos} 的开局表内，弃牌等于每圈白交盲注税。", "{hand} is inside {pos}'s opening chart; folding it pays blind tax every orbit for nothing."),
  ("按 {pos} 约 {pct}% 的范围口径，{hand} 是标准开局——弃牌过紧。", "By {pos}'s ~{pct}% range, {hand} is a standard open — folding is too tight.")],
 ("raise", "call"): [
  ("跛入是最贵的中庸：不抢位、不施压，还把盲注请进多人锅。", "Limping is the priciest compromise: no position fight, no pressure, and the blinds get invited into a multiway pot."),
  ("开局表里没有「跛入」这一栏——要么加注要么弃牌。", "There is no limp column on an opening chart — raise or fold.")],
 ("fold", "raise"): [
  ("把 {hand} 开进 {pos} 是给后排送 3-bet 靶子——范围外的牌经不起反击。", "Opening {hand} from {pos} hangs a 3-bet target for the seats behind — off-chart hands cannot take the counterpunch."),
  ("范围纪律的意义正在这种牌上：偶尔偷成一锅，长期漏率稳定为负。", "Range discipline exists for exactly this hand: it steals the odd pot and leaks steadily forever.")],
 ("fold", "call"): [
  ("价位诱人不等于价值存在：{hand} 的翻后剧本几乎全是「赢小输大」。", "A tempting price is not value: {hand}'s postflop scripts are almost all win-small-lose-big."),
  ("跛入救不了范围外的牌——问题在牌本身，不在进场方式。", "Limping cannot rescue an off-chart hand — the problem is the cards, not the entry method.")],
 ("fold", "3bet"): [
  ("诈唬也讲组合学：{hand} 既无阻断也无补牌，被跟注后只剩祈祷。", "Bluffs obey combinatorics too: {hand} holds no blockers and no backup — once called, only prayer remains.")],
 ("call", "fold"): [
  ("关锅只需再补 1.5bb，弃掉 {hand} 是把价位白白退回去。", "Closing the action costs just 1.5bb more; folding {hand} hands the price straight back."),
  ("面对 {opp} 这么宽的开局弃 {hand}，等于宣布大盲不设防。", "Folding {hand} to an open this wide announces an undefended big blind.")],
 ("call", "3bet"): [
  ("用 {hand} 升级底池两头不讨好：更好的牌不走、更差的牌不跟——潜力牌要的是便宜看翻牌。", "Escalating with {hand} pleases nobody: better hands stay, worse hands leave — potential hands want a cheap flop."),
  ("3-bet 把这手牌的伪装全部撕掉，还把可玩性押在翻前。", "A 3-bet strips the hand's disguise and stakes its playability on preflop.")],
 ("3bet", "fold"): [
  ("面对 {opp} 的宽开局弃 {hand} 严重过紧——这手牌压制其范围一大截。", "Folding {hand} to {opp}'s wide open is far too tight — it dominates a large slice of that range."),
  ("把范围里最能打的牌弃掉，等于自愿只剩中庸部分作战。", "Folding the most capable part of your range volunteers to fight with only the mediocre middle.")],
 ("3bet", "call"): [
  ("{pos} 没有舒适的平跟剧本：位置吃亏、还邀请后手挤压——价值牌直接 3-bet。", "{pos} owns no comfortable flatting script: bad position and an open invitation to squeezes — value hands 3-bet outright.")],
}

OBJ = {
 "r_premium": ("顶端牌力无条件开局。", "Open the top of the range unconditionally."),
 "r_std": ("按位置范围执行标准开局。", "Execute the standard open by positional range."),
 "r_spec": ("理解结构型牌的开局价值。", "Value structural hands in the opening range."),
 "r_mixed": ("识别开局线上的混合频率格。", "Recognize mixed-frequency cells on the opening line."),
 "f_trap": ("识破高张陷阱，守住范围纪律。", "See through pretty traps and hold range discipline."),
 "f_near": ("体会范围随位置逐格收紧。", "Feel the range tighten seat by seat."),
 "f_junk": ("垃圾牌不进锅。", "Junk stays out of the pot."),
 "c_pair": ("用关锅价为小对买成套彩票。", "Buy set lottery tickets at the closing price."),
 "c_suited": ("用价格 + 结构防守大盲。", "Defend the big blind on price plus structure."),
 "c_broad": ("用领先范围的高张平跟防守。", "Defend by calling with range-beating broadways."),
 "c_mixed": ("识别防守线上的混合频率格。", "Recognize mixed cells on the defending line."),
 "df_dom": ("识别「赢小输大」的被支配牌。", "Spot win-small-lose-big dominated hands."),
 "df_near": ("贴线牌守住弃牌纪律。", "Hold the fold line on near-miss hands."),
 "df_junk": ("再便宜也不防守空气。", "No price defends pure air."),
 "t_value": ("对宽开局执行价值 3-bet。", "Value 3-bet the wide open."),
 "t_value_dual": ("掌握 3-bet 为主、平跟为辅的双线。", "Run the 3-bet-first, flat-second dual line."),
 "t_blocker": ("用阻断牌构建 3-bet 诈唬翼。", "Build the 3-bet bluff wing with blockers."),
 "t_semibluff": ("用同花弹性件扩充 3-bet 进攻翼。", "Stretch the 3-bet attack with suited flex hands."),
 "tf_pretty": ("执行盲注位的 3-bet 或弃牌纪律。", "Execute blind-seat 3-bet-or-fold discipline."),
 "tf_junk": ("诈唬资格也要按组合学排队。", "Even bluffs queue by combinatorics."),
}

LESSON = {
 "r_premium": "l2-01-rfi-principles", "r_std": "l2-01-rfi-principles",
 "r_spec": "l2-02-range-shapes", "r_mixed": "l4-03-frequencies",
 "f_trap": "l1-06-starting-hands", "f_near": "l2-02-range-shapes", "f_junk": "l1-06-starting-hands",
 "c_pair": "l2-04-facing-rfi", "c_suited": "l2-04-facing-rfi", "c_broad": "l2-04-facing-rfi",
 "c_mixed": "l4-03-frequencies", "df_dom": "l2-04-facing-rfi", "df_near": "l2-02-range-shapes",
 "df_junk": "l1-06-starting-hands", "t_value": "l2-03-threebet-basics",
 "t_value_dual": "l2-03-threebet-basics", "t_blocker": "l4-04-blockers", "t_semibluff": "l2-03-threebet-basics",
 "tf_pretty": "l2-05-blind-battle", "tf_junk": "l2-03-threebet-basics",
}
DIFF = {"r_premium": 1, "r_std": 1, "r_spec": 2, "r_mixed": 3, "f_trap": 2, "f_near": 3,
        "f_junk": 1, "c_pair": 1, "c_suited": 2, "c_broad": 2, "c_mixed": 3,
        "df_dom": 2, "df_near": 3, "df_junk": 1, "t_value": 2, "t_value_dual": 3,
        "t_blocker": 3, "t_semibluff": 3, "tf_pretty": 2, "tf_junk": 1}

# ---- 判定类解析 ----
def rfi_class(h, wv):
    t = traits(h)
    if 0 < wv < 1: return "r_mixed"
    if wv >= 1:
        if t["bigpair"] or h in ("AKs", "AKo", "AQs"): return "r_premium"
        if t["wheel"] or (t["suited"] and t["conn"]) or t["lowpair"] or \
           (t["suited"] and not t["broad"]): return "r_spec"
        return "r_std"
    if t["broad"] and t["off"]: return "f_trap"
    if t["pair"] or (t["suited"] and t["hi"] in "AKQJ") or (t["off"] and t["hi"] == "A"): return "f_near"
    return "f_junk"

def def_class(h, wc):
    t = traits(h)
    if 0 < wc < 1: return "c_mixed"
    if wc >= 1:
        if t["pair"]: return "c_pair"
        if t["broad"]: return "c_broad"
        return "c_suited"
    if t["broad"] or (t["off"] and t["hi"] in "AK"): return "df_dom"
    if t["suited"] or t["pair"]: return "df_near"
    return "df_junk"

def tb_class(h, w3, wc_dual):
    t = traits(h)
    if w3 > 0:
        if t["wheel"]: return "t_blocker"
        if t["suited"] and not t["broad"] and not t["pair"]: return "t_semibluff"
        return "t_value_dual" if wc_dual > 0 else "t_value"
    if t["broad"] or (t["off"] and t["hi"] in "AK") or t["pair"]: return "tf_pretty"
    return "tf_junk"

def build(idx, kind, pos, opp, hand, correct, acceptable, cls, chart_id, op_chart=None):
    ctx = dict(hand=hand, pos=POS[pos], opp=POS[opp] if opp else "",
               pct=pct[chart_id], op_pct=pct[op_chart] if op_chart else "",
               trz=trait_phrase(hand)[0], tre=trait_phrase(hand)[1])
    zh, en = pick(TPL[cls], idx)
    wrongs = {}
    for wk in WRONG_KEYS[cls]:
        if wk == correct or wk in acceptable: continue
        wz, we = pick(WRONG[(correct, wk)], idx + wk)
        wrongs[wk] = L(wz.format(**ctx), we.format(**ctx))
    return {"id": idx, "kind": kind, "position": pos, "facing": FACING(opp) if opp else [],
            "hand": hand, "correct": correct, "acceptable": acceptable,
            "explanation": L(zh.format(**ctx), en.format(**ctx)),
            "wrongChoices": wrongs,
            "objective": L(*OBJ[cls]), "lessonRef": LESSON[cls],
            "difficulty": DIFF[cls], "tags": [TAG[kind], cls.split("_")[0], "chart-derived"]}

TAG = {"rfi": "rfi", "bb_defense": "bb_defense", "vs_rfi": "vs_rfi"}
WRONG_KEYS = {
 "r_premium": ["fold", "call"], "r_std": ["fold", "call"], "r_spec": ["fold"],
 "r_mixed": ["call"], "f_trap": ["raise", "call"], "f_near": ["raise"], "f_junk": ["raise"],
 "c_pair": ["fold", "3bet"], "c_suited": ["fold", "3bet"], "c_broad": ["fold"],
 "c_mixed": ["3bet"], "df_dom": ["call"], "df_near": ["call"], "df_junk": ["call", "3bet"],
 "t_value": ["fold", "call"], "t_value_dual": ["fold"], "t_blocker": ["fold"],
 "t_semibluff": ["fold"],
 "tf_pretty": ["3bet", "call"], "tf_junk": ["3bet", "call"],
}

# ---- 题单（人工选牌：覆盖表内骨架、贴线、陷阱、阻断、垃圾）----
RFI_HANDS = {
 "utg": ["ATs", "99", "KQo", "A9s", "QJs", "66"],
 "hj":  ["AJo", "KQo", "77", "A9s", "KTs", "QTs", "44", "T9s"],
 "co":  ["A5s", "KJo", "66", "JTs", "A9o", "K9s", "Q9s", "22"],
 "btn": ["33", "Q9o", "96s", "K5s", "A7o"],
 "sb":  ["K7s", "Q8s", "A8o", "87s", "T7s", "65s", "84o", "44"],
}
BB_DEF = {  # opp → hands（vs utg/co/sb 已剔除显然 3-bet 的超强牌）
 "btn": ["TT", "A5s", "JTs", "KQo", "22", "76s", "K9s", "QTo", "J8s", "A9o", "Q5s", "84o"],
 "utg": ["88", "76s", "ATo", "KJo", "T9s", "K8s"],
 "co":  ["77", "KTs", "A8s", "65s", "J9s", "Q9o"],
 "sb":  ["K9o", "Q8s", "A7o", "T8s", "96s", "54s", "K4s", "73o"],
}
TB_SPOTS = {  # (hero, opp, 3bet 表, 平跟双轨表 or None)
 ("sb", "btn"): (["QQ", "AKo", "A4s", "KQs", "J7o", "Q6o"], "sb-3bet-vs-btn-100bb", None),
 ("btn", "co"): (["QQ", "AKo", "A5s", "Q8o", "J7o"], "btn-3bet-vs-co-100bb", None),
}

generated = []
for pos, hands in RFI_HANDS.items():
    cid = f"rfi-{pos}-100bb"
    for h in hands:
        wv = W(cid, h)
        cls = rfi_class(h, wv)
        correct = "raise" if wv > 0 else "fold"
        acc = ["fold"] if cls == "r_mixed" else []
        generated.append(build(f"pf-g-rfi-{pos}-{h.lower()}", "rfi", pos, None, h,
                               correct, acc, cls, cid))
for opp, hands in BB_DEF.items():
    call_id = f"bb-call-vs-{opp}-100bb"
    tb_id = "bb-3bet-vs-btn-100bb" if opp == "btn" else None
    for h in hands:
        wc = W(call_id, h)
        w3 = W(tb_id, h) if tb_id else 0.0
        if w3 > 0:
            cls = tb_class(h, w3, wc)
            correct, acc = "3bet", (["call"] if wc > 0 else [])
            chart, op_chart = tb_id, f"rfi-{opp}-100bb"
        else:
            cls = def_class(h, wc)
            correct = "call" if wc > 0 else "fold"
            acc = ["fold"] if cls == "c_mixed" else []
            chart, op_chart = call_id, f"rfi-{opp}-100bb"
        generated.append(build(f"pf-g-bbv{opp}-{h.lower()}", "bb_defense", "bb", opp, h,
                               correct, acc, cls, chart, op_chart))
for (hero, opp), (hands, tb_id, _) in TB_SPOTS.items():
    for h in hands:
        w3 = W(tb_id, h)
        cls = tb_class(h, w3, 0.0)
        correct = "3bet" if w3 > 0 else "fold"
        acc = ["fold"] if (0 < w3 < 1) else []
        generated.append(build(f"pf-g-{hero}v{opp}-{h.lower()}", "vs_rfi", hero, opp, h,
                               correct, acc, cls, tb_id, f"rfi-{opp}-100bb"))

# ---- 合并写入（幂等：仅替换 pf-g-*）----
path = os.path.join(CONTENT, "scenarios", "preflop.json")
doc = json.load(open(path, encoding="utf-8"))
hand_written = [s for s in doc["scenarios"] if not s["id"].startswith("pf-g-")]
seen = {(s["kind"], s["position"], s["hand"],
         s["facing"][0]["position"] if s["facing"] else "") for s in hand_written}
for s in generated:
    key = (s["kind"], s["position"], s["hand"],
           s["facing"][0]["position"] if s["facing"] else "")
    assert key not in seen, f"与手写题重复: {s['id']}"
    seen.add(key)
doc["scenarios"] = hand_written + generated
json.dump(doc, open(path, "w", encoding="utf-8"), ensure_ascii=False, indent=2)

from collections import Counter
print(f"\n生成 {len(generated)} 道 | 手写保留 {len(hand_written)} | 总计 {len(doc['scenarios'])}")
print("判定类分布:", dict(Counter(s["tags"][1] for s in generated)))
print("\n=== 判定一览（人工口径核查用）===")
for s in generated:
    f = f" vs {s['facing'][0]['position'].upper()}" if s["facing"] else ""
    acc = f" acc={s['acceptable']}" if s["acceptable"] else ""
    print(f"  {s['id']:26s} {s['position'].upper():3s}{f:8s} {s['hand']:4s} → {s['correct']}{acc}")

"""Parse the Flutter app's data definitions to extract entity/field metadata.

Reads ``mobile/lib/data/reference_data.dart`` and ``entities.dart`` and
produces structured Python objects (lists of dicts) usable by the PDF
renderer.  The Flutter spec is the canonical source of truth for the
protocol documentation.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional, Tuple

REF_PATH = Path("mobile/lib/data/reference_data.dart")
ENT_PATH = Path("mobile/lib/data/entities.dart")


@dataclass
class Choice:
    value: str
    label: str


@dataclass
class FieldSpec:
    key: str
    label: str
    ftype: str
    section: str = "عام"
    required: bool = False
    help_text: Optional[str] = None
    choices_ref: Optional[str] = None  # e.g. "Ref.governorates"
    choices: List[Choice] = field(default_factory=list)


@dataclass
class EntitySpec:
    var_name: str  # kSurvivorSpec, kConsentSpec, ...
    table: str
    title_ar: str
    icon: str  # Icons.foo
    singleton: bool
    fields: List[FieldSpec] = field(default_factory=list)


# ---------------- choices parsing ----------------

_CHOICE_RE = re.compile(r"Choice\(\s*'([^']+)'\s*,\s*'([^']+)'\s*\)")


def parse_choices(ref_text: str) -> Dict[str, List[Choice]]:
    """Pull every ``static const NAME = <Choice>[ ... ];`` block."""
    out: Dict[str, List[Choice]] = {}

    # static const|List<Choice> get name => ...;
    static_pat = re.compile(
        r"static\s+const\s+(\w+)\s*=\s*<Choice>\[(.*?)\];", re.DOTALL,
    )
    for m in static_pat.finditer(ref_text):
        name = m.group(1)
        body = m.group(2)
        choices = [Choice(v, l) for v, l in _CHOICE_RE.findall(body)]
        out[name] = choices

    # Special: facilities and tortureMethods are computed from _facilityNames
    # / _tortureMethodNames; we handle these separately.
    out["facilities"] = _parse_named_list(
        ref_text, "_facilityNames", as_choice_self=True,
        extra=Choice("__other__", "أخرى — غير مدرجة (اكتبها في الحقل التالي)"),
    )
    out["tortureMethods"] = _parse_named_list(
        ref_text, "_tortureMethodNames", as_choice_self=True,
    )
    return out


def _parse_named_list(text: str, name: str, *, as_choice_self: bool,
                       extra: Optional[Choice] = None) -> List[Choice]:
    pat = re.compile(rf"static\s+const\s+{re.escape(name)}\s*=\s*<String>\[(.*?)\];",
                     re.DOTALL)
    m = pat.search(text)
    if not m:
        return []
    body = m.group(1)
    names = re.findall(r"'([^']+)'", body)
    out = [Choice(n, n) for n in names] if as_choice_self else [Choice(n, n) for n in names]
    if extra:
        out.append(extra)
    return out


# ---------------- entity parsing ----------------

_ENT_HEADER_RE = re.compile(
    r"final\s+EntitySpec\s+(\w+)\s*=\s*EntitySpec\(", re.MULTILINE,
)


def _balanced_block(text: str, start_paren_pos: int) -> Tuple[int, int]:
    """Given the position of '(', return (content_start, end_paren_pos+1)."""
    assert text[start_paren_pos] == "("
    depth = 1
    i = start_paren_pos + 1
    n = len(text)
    in_str = None
    while i < n and depth > 0:
        c = text[i]
        if in_str:
            if c == "\\":
                i += 2
                continue
            if c == in_str:
                in_str = None
            i += 1
            continue
        if c in ("'", '"'):
            in_str = c
            i += 1
            continue
        if c == "/":
            if i + 1 < n and text[i + 1] == "/":
                while i < n and text[i] != "\n":
                    i += 1
                continue
        if c == "(":
            depth += 1
        elif c == ")":
            depth -= 1
            if depth == 0:
                return start_paren_pos + 1, i + 1
        i += 1
    raise ValueError("Unbalanced parens")


def _kw_value(args: str, key: str) -> Optional[str]:
    """Extract `key:` value from a keyword arg list (best-effort)."""
    # very simple — fine because we control the source format
    m = re.search(rf"\b{re.escape(key)}\s*:\s*", args)
    if not m:
        return None
    start = m.end()
    # parse until matching delimiter (top-level , or end)
    depth = 0
    in_str = None
    i = start
    while i < len(args):
        c = args[i]
        if in_str:
            if c == "\\":
                i += 2
                continue
            if c == in_str:
                in_str = None
            i += 1
            continue
        if c in ("'", '"'):
            in_str = c
            i += 1
            continue
        if c in "([{":
            depth += 1
        elif c in ")]}":
            depth -= 1
        elif c == "," and depth == 0:
            return args[start:i].strip()
        i += 1
    return args[start:i].strip()


_STR_RE = re.compile(r"^'((?:[^'\\]|\\.)*)'$", re.DOTALL)


def _str_value(raw: Optional[str]) -> Optional[str]:
    if raw is None:
        return None
    raw = raw.strip()
    m = _STR_RE.match(raw)
    if not m:
        return None
    s = m.group(1)
    # نُفكّ تبسيط محارف الـDart المهرّبة الشائعة فقط (لا تحويل UTF-8)
    return (s.replace("\\n", "\n").replace("\\t", "\t")
            .replace("\\'", "'").replace('\\"', '"')
            .replace("\\\\", "\\"))


def _parse_field_specs(fields_block: str,
                        choices_map: Dict[str, List[Choice]]) -> List[FieldSpec]:
    """Find each ``FieldSpec(...)`` call in the fields block."""
    out: List[FieldSpec] = []
    i = 0
    while True:
        m = re.search(r"(?<![A-Za-z_])(?:const\s+)?FieldSpec\s*\(",
                      fields_block[i:])
        if not m:
            break
        open_pos = i + m.end() - 1
        content_start, end_pos = _balanced_block(fields_block, open_pos)
        body = fields_block[content_start:end_pos - 1]
        out.append(_parse_one_field(body, choices_map))
        i = end_pos
    return out


def _parse_one_field(body: str, choices_map: Dict[str, List[Choice]]) -> FieldSpec:
    # First 3 positional args: 'key', 'label', FieldType.x
    parts = _split_top_level(body)
    key = _str_value(parts[0]) or ""
    label = _str_value(parts[1]) or ""
    type_raw = parts[2].strip()
    ftype = type_raw.split(".")[-1]
    spec = FieldSpec(key=key, label=label, ftype=ftype)

    rest = ",".join(parts[3:])
    section = _str_value(_kw_value(rest, "section"))
    if section:
        spec.section = section
    req = _kw_value(rest, "required")
    if req and "true" in req:
        spec.required = True
    help_raw = _kw_value(rest, "help")
    h = _str_value(help_raw)
    if h:
        spec.help_text = h
    choices_raw = _kw_value(rest, "choices")
    if choices_raw:
        choices_raw = choices_raw.strip()
        spec.choices_ref = choices_raw
        if choices_raw.startswith("Ref."):
            name = choices_raw.split(".", 1)[1]
            spec.choices = choices_map.get(name, [])
    return spec


def _split_top_level(body: str) -> List[str]:
    parts = []
    depth = 0
    in_str = None
    last = 0
    i = 0
    while i < len(body):
        c = body[i]
        if in_str:
            if c == "\\":
                i += 2
                continue
            if c == in_str:
                in_str = None
            i += 1
            continue
        if c in ("'", '"'):
            in_str = c
            i += 1
            continue
        if c in "([{":
            depth += 1
        elif c in ")]}":
            depth -= 1
        elif c == "," and depth == 0:
            parts.append(body[last:i])
            last = i + 1
        i += 1
    parts.append(body[last:])
    return [p for p in parts if p.strip()]


def parse_entities(text: str,
                    choices_map: Dict[str, List[Choice]]) -> List[EntitySpec]:
    entities: List[EntitySpec] = []
    for m in _ENT_HEADER_RE.finditer(text):
        open_pos = m.end() - 1
        content_start, end_pos = _balanced_block(text, open_pos)
        body = text[content_start:end_pos - 1]
        table = _str_value(_kw_value(body, "table")) or ""
        title = _str_value(_kw_value(body, "titleAr")) or ""
        icon = (_kw_value(body, "icon") or "").strip()
        singleton_raw = _kw_value(body, "singleton") or ""
        singleton = "true" in singleton_raw

        fields_raw = _kw_value(body, "fields") or "[]"
        # strip surrounding [ ]
        fields_raw = fields_raw.strip()
        if fields_raw.startswith("["):
            fields_raw = fields_raw[1:-1]

        e = EntitySpec(
            var_name=m.group(1),
            table=table, title_ar=title, icon=icon, singleton=singleton,
        )
        e.fields = _parse_field_specs(fields_raw, choices_map)
        entities.append(e)
    return entities


def load_all() -> Tuple[Dict[str, List[Choice]], List[EntitySpec]]:
    ref_text = REF_PATH.read_text(encoding="utf-8")
    ent_text = ENT_PATH.read_text(encoding="utf-8")
    choices = parse_choices(ref_text)
    entities = parse_entities(ent_text, choices)
    return choices, entities


if __name__ == "__main__":
    choices, entities = load_all()
    print(f"choice lists: {len(choices)}")
    for n, lst in choices.items():
        print(f"  {n}: {len(lst)} options")
    print(f"\nentities: {len(entities)}")
    for e in entities:
        print(f"  [{e.table}] {e.title_ar}  ({len(e.fields)} fields, singleton={e.singleton})")
        # show first 2 fields
        for f in e.fields[:2]:
            opts = f" — {len(f.choices)} options" if f.choices else ""
            req = " *" if f.required else ""
            print(f"      · {f.key} ({f.ftype}){req}: {f.label}{opts}")

"""يولّد كتيب PDF شامل (عربي RTL) لبروتوكولات التوثيق وحقول النظام كاملة.

يقرأ كل التعريفات من ``mobile/lib/data/entities.dart`` و
``reference_data.dart`` (المصدر الأساسي للحقائق) ويُخرج وثيقة احترافية
تحوي مخططات سير العمل وجداول كل الحقول والخيارات.

الاستخدام:
    python3 scripts/build_protocol_pdf.py [اسم_الملف.pdf]
"""

from __future__ import annotations

import html
import sys
from pathlib import Path

import weasyprint

# Make the parser importable when running from any cwd.
sys.path.insert(0, str(Path(__file__).resolve().parent))

from protocol_data import EntitySpec, FieldSpec, load_all  # noqa: E402


# ============================================================
# 1)  المحتوى التحريري (مقدمات ومخططات)
# ============================================================

DOC_TITLE = "كتيب البروتوكولات وحقول التوثيق"
DOC_SUBTITLE = "نظام جمعية حقّنا لتوثيق الناجين من الاحتجاز السوري"
DOC_VERSION = "الإصدار 2.0"
DOC_AUDIENCE = (
    "للموثّقين الميدانيين، المشرفين، والباحثين الاجتماعيين العاملين على "
    "ملفات الناجين."
)

INTRO_HTML = """
<p>
هذا الكتيب وثيقة مرجعية رسمية لكل من يعمل على توثيق ملفات الناجين من
الاحتجاز السوري ضمن منظومة جمعية حقّنا. يصف الكتيب بدقّة المعايير
والبروتوكولات المعتمَدة، ويعرض سير العمل التوثيقي خطوةً بخطوة، ثم يقدّم
مرجعاً ميدانياً تفصيلياً لكل حقل من حقول النموذج، مع كل قائمة الخيارات
المتاحة فيه.
</p>
<p>
الهدف الأسمى: إنتاج ملفات قابلة للقبول قضائياً أمام المحاكم الدولية
وآلية الـIIIM ولجنة التحقيق الأممية ومسارات الولاية القضائية العالمية،
مع صون كرامة الناجي وحماية بياناته الشخصية.
</p>
"""

STANDARDS = [
    {
        "title": "بروتوكول إسطنبول (Istanbul Protocol – Rev. 2, 2022)",
        "scope": "الدليل الدولي الأول لتوثيق التعذيب وسوء المعاملة.",
        "use": (
            "نتّبع منهجيته في إجراء المقابلات، توثيق الإصابات الجسدية والنفسية، "
            "وتقييم مدى توافق النتائج الطبية مع رواية الناجي (مقياس "
            "<em>التوافق</em> الإسطنبولي السداسي)."
        ),
    },
    {
        "title": "بروتوكول بيركلي (Berkeley Protocol, 2022)",
        "scope": "معايير التحقق من المصادر الرقمية المفتوحة المصدر.",
        "use": (
            "نطبّقه عند توثيق الوثائق المسرّبة والوسائط من الإنترنت: التحقق "
            "من الميتاداتا، أرشفة الروابط، توثيق تاريخ ووقت الوصول، وسلسلة "
            "الحيازة الرقمية."
        ),
    },
    {
        "title": "منهجية الـIIIM (Annex A, 2024)",
        "scope": "متطلبات الآلية الدولية المحايدة المستقلة لسوريا.",
        "use": (
            "نلتزم بمتطلبات سلامة الأدلة وقابليتها للقبول: الموافقة المستنيرة "
            "الطبقية، تتبّع سلسلة الحيازة (Chain of Custody) لكل وثيقة، "
            "والأرشفة الآمنة بدلاً من الحذف."
        ),
    },
    {
        "title": "دليل Eurojust / ICC للمجتمع المدني (2022)",
        "scope": "مرشد المنظمات المدنية في التعاون مع التحقيقات الدولية.",
        "use": (
            "نعتمد توصياته في تصنيف الملفات (A/B/C)، تمرير الأدلة لجهات "
            "الادعاء الوطنية، وإعداد الحزم القابلة للإحالة."
        ),
    },
]

# مخطّط سير العمل (HTML/CSS — لأن SVG لا يُشكّل العربية في WeasyPrint)
WORKFLOW_HTML = """
<div class="flow">
  <div class="step step-h">
    <div class="num">١</div>
    <div class="step-body">
      <div class="step-title">التعرّف والاتصال الأولي</div>
      <div class="step-desc">تحديد الناجي، شرح هويّة الجمعية ودورها وحدود السرّية</div>
    </div>
  </div>
  <div class="arrow"></div>

  <div class="step">
    <div class="num">٢</div>
    <div class="step-body">
      <div class="step-title">الموافقة المستنيرة الطبقية</div>
      <div class="step-desc">حقوق الانسحاب، حدود السرّية، الجهات المسموح بمشاركة الملف معها</div>
    </div>
  </div>
  <div class="arrow"></div>

  <div class="step">
    <div class="num">٣</div>
    <div class="step-body">
      <div class="step-title">البيانات البيوغرافية الأساسية</div>
      <div class="step-desc">الاسم الرباعي، الجنس، الإقامة، المهنة، النشاط السياسي</div>
    </div>
  </div>
  <div class="arrow"></div>

  <div class="step-row">
    <div class="step step-half">
      <div class="num">٤أ</div>
      <div class="step-body">
        <div class="step-title">وقائع الاعتقال</div>
        <div class="step-desc">التاريخ، المكان، الجهة المعتقِلة، الظروف التفصيلية</div>
      </div>
    </div>
    <div class="step step-half">
      <div class="num">٤ب</div>
      <div class="step-body">
        <div class="step-title">فترات الاحتجاز</div>
        <div class="step-desc">المراكز (من قائمة 128+ مركزاً)، التواريخ، أنماط التعذيب</div>
      </div>
    </div>
  </div>
  <div class="arrow"></div>

  <div class="step">
    <div class="num">٥</div>
    <div class="step-body">
      <div class="step-title">واقعة الإفراج</div>
      <div class="step-desc">نوع الإفراج (مشروط/عفو/فدية/...)، التاريخ، الظروف</div>
    </div>
  </div>
  <div class="arrow"></div>

  <div class="step">
    <div class="num">٦</div>
    <div class="step-body">
      <div class="step-title">الأدلة المُعزِّزة</div>
      <div class="step-desc">شهود مستقلون، وثائق بسلسلة حيازة، تقييم طبي وفق إسطنبول</div>
    </div>
  </div>
  <div class="arrow"></div>

  <div class="step">
    <div class="num">٧</div>
    <div class="step-body">
      <div class="step-title">المقابلات الموسّعة</div>
      <div class="step-desc">منهجية إسطنبول، جلسات متتابعة، تسجيلات بموافقة الناجي</div>
    </div>
  </div>
  <div class="arrow"></div>

  <div class="step">
    <div class="num">٨</div>
    <div class="step-body">
      <div class="step-title">المسح الاجتماعي</div>
      <div class="step-desc">الأسرة، السكن، التعليم، العمل، الصحة، تقييم الاحتياجات</div>
    </div>
  </div>
  <div class="arrow"></div>

  <div class="step">
    <div class="num">٩</div>
    <div class="step-body">
      <div class="step-title">مراجعة وتدقيق المشرف</div>
      <div class="step-desc">حسبة النقاط الثلاث آلياً (موثوقية/تحقق/اكتمال) ثم تصنيف A/B/C</div>
    </div>
  </div>
  <div class="arrow"></div>

  <div class="step step-h">
    <div class="num">١٠</div>
    <div class="step-body">
      <div class="step-title">الأرشفة الآمنة و/أو الإحالة</div>
      <div class="step-desc">IIIM · COI · ICC · الولاية القضائية العالمية · شركاء معتمدون</div>
    </div>
  </div>
</div>
"""

# شرح موجز لكل بروتوكول قبل عرض حقوله
ENTITY_INTROS = {
    "survivor": (
        "البطاقة المرجعية لكل ناجٍ. تُجمَع في الجلسة الأولى وتُنشأ معها "
        "بقية الكيانات. <strong>رقم القضية يُولَّد آلياً</strong> بصيغة "
        "<code>HQ-&lt;السنة&gt;-&lt;6 خانات هكساديسيمال&gt;</code> ولا داعي "
        "لإدخاله يدوياً."
    ),
    "consent": (
        "العمود الفقري الأخلاقي والقانوني للملف. <strong>الموافقة طبقية</strong>:"
        " الناجي يحدّد بنفسه أي الجهات مسموح بمشاركة ملفه معها (IIIM، ICC،"
        " الولاية العالمية، إلخ) ومتى تُخفى هويته. حق الانسحاب مكفول."
    ),
    "detention_event": (
        "كل اعتقال = واقعة منفصلة. لبعض الناجين أكثر من واقعة. الحقل "
        "<em>«ظروف الاعتقال»</em> هو الأساس لقياس درجة الموثوقية: نوصي بنص "
        "تفصيلي يتجاوز 150 حرفاً."
    ),
    "detention_period": (
        "الخط الزمني للمحتجَز داخل المراكز. لكل فترة يُربط مركز محدد من "
        "قائمة الـ128+ مركزاً المثبتة، وتُسجَّل أنماط التعذيب من قائمة "
        "موحّدة (تصنيف إسطنبول)."
    ),
    "release": (
        "واقعة الإفراج لها أنواع مميَّزة قانونياً (إفراج مشروط، عفو، فدية، "
        "تبادل، فرار، ...) تؤثّر على تقييم سياق الانتهاك."
    ),
    "witness": (
        "<strong>المعيار الذهبي للتحقق المتقاطع</strong>. الشاهد المستقل "
        "(الذي لم يلتقِ الناجي بعد الإفراج قبل الإدلاء بشهادته) أهم دليل "
        "في الملف بعد الناجي نفسه."
    ),
    "document": (
        "كل وثيقة لها سلسلة حيازة موثَّقة (مَن، متى، أين، كيف). يحسب النظام "
        "بصمة SHA-256 للملف فور رفعه. الوثائق المسرَّبة تخضع لتحقق إضافي "
        "وفق بروتوكول بيركلي."
    ),
    "medical": (
        "تقييم فاحص مؤهَّل وفق بروتوكول إسطنبول. مقياس التوافق السداسي "
        "(من «لم يُقيَّم» إلى «تشخيصي - دليل قاطع») هو معيار قبول الدليل "
        "الطبي في المحاكم الدولية."
    ),
    "impact": (
        "الأثر طويل الأمد ضروري للملفات المُحالة لطلبات اللجوء، الجبر، "
        "والمساعدة الإنسانية. يُملأ مرة واحدة لكل ناجٍ."
    ),
    "interview": (
        "الناجي يخضع لمقابلات متعددة بمرور الوقت. كل مقابلة لها رقم متسلسل، "
        "منهجية، ولغة. <strong>المقابلة الأولى</strong> ذات أهمية خاصة "
        "(تجنّب إعادة الصدمة)."
    ),
    "note": (
        "ملاحظات داخلية للموثّقين والمشرفين لا تُشارَك خارجياً. تُصنَّف حسب "
        "نوعها (طبية، قانونية، أمنية...) ويمكن تثبيتها وجعلها سرّية."
    ),
    "household": (
        "افتتاحية المسح الاجتماعي. وضع الأسرة الحالي، التهجير، عدد الأفراد. "
        "تتفرَّع منها بقية أقسام المسح."
    ),
    "child": (
        "لكل ابن/ابنة بطاقة مستقلة. التركيز على التعليم، الصحة، والعمل لتحديد "
        "حالات عمالة الأطفال والتسرب الدراسي بسبب اعتقال الوالد."
    ),
    "housing": (
        "وصف السكن الحالي، المرافق، والوضع التهجيري. يشمل أيضاً ملكية المنزل "
        "الأصلي وحالات المصادرة."
    ),
    "education": (
        "وضع الناجي التعليمي قبل وبعد الاعتقال — مهم لتحديد أثر الاحتجاز على "
        "مساره التعليمي."
    ),
    "employment": (
        "الوضع المهني والدخل، ومدى تأثُّر القدرة على العمل بالاحتجاز. مهم "
        "للجبر الاقتصادي."
    ),
    "health": (
        "وصول الأسرة كاملةً للرعاية الصحية والأمن الغذائي. لا يقتصر على "
        "الناجي بل يشمل المعالين."
    ),
    "needs": (
        "تقييم الأولويات لتوجيه برامج الاستجابة الإنسانية والقانونية. تسع "
        "أولويات مصنَّفة من «لا حاجة» إلى «حرج/طارئ»."
    ),
}

# مجموعات الكيانات بترتيب العرض
GROUPS = [
    ("الملف الرئيسي للناجي", ["survivor"]),
    ("بروتوكولات التوثيق", [
        "consent", "detention_event", "detention_period", "release",
        "witness", "document", "medical", "impact", "interview", "note",
    ]),
    ("المسح الاجتماعي", [
        "household", "child", "housing", "education", "employment",
        "health", "needs",
    ]),
]


# ============================================================
# 2)  الترميز إلى HTML
# ============================================================

FTYPE_LABEL = {
    "text": "نص قصير",
    "multiline": "نص طويل",
    "integer": "عدد صحيح",
    "decimal": "عدد عشري",
    "date": "تاريخ",
    "boolean": "نعم/لا",
    "choice": "اختيار من قائمة",
    "multiChoice": "اختيار متعدد",
    "image": "صورة (كاميرا أو معرض)",
}


def render_field_row(f: FieldSpec) -> str:
    star = " <span class='req'>*</span>" if f.required else ""
    help_block = (
        f"<div class='help'>{html.escape(f.help_text)}</div>"
        if f.help_text else ""
    )
    choices_block = ""
    if f.choices:
        items = "".join(
            f"<li><code>{html.escape(c.value)}</code> — "
            f"{html.escape(c.label)}</li>"
            for c in f.choices
        )
        title = f"الخيارات المتاحة ({len(f.choices)})"
        if len(f.choices) > 20:
            choices_block = (
                f"<details><summary>{title}</summary>"
                f"<ul class='choices'>{items}</ul></details>"
            )
        else:
            choices_block = (
                f"<div class='choices-title'>{title}:</div>"
                f"<ul class='choices'>{items}</ul>"
            )
    return (
        "<tr>"
        f"<td class='fkey'><code>{html.escape(f.key)}</code></td>"
        f"<td class='flabel'>{html.escape(f.label)}{star}{help_block}"
        f"{choices_block}</td>"
        f"<td class='ftype'>{FTYPE_LABEL.get(f.ftype, f.ftype)}</td>"
        "</tr>"
    )


def render_entity_section(e: EntitySpec) -> str:
    cardinality = "سجل واحد لكل ناجٍ" if e.singleton else "متعدد السجلات"
    intro = ENTITY_INTROS.get(e.table, "")

    # تجميع الحقول حسب القسم
    sections: list[tuple[str, list[FieldSpec]]] = []
    seen: dict[str, list[FieldSpec]] = {}
    for f in e.fields:
        seen.setdefault(f.section, []).append(f)
    for s, fs in seen.items():
        sections.append((s, fs))

    out = [
        f"<section class='entity' id='ent-{e.table}'>",
        f"<h2>{html.escape(e.title_ar)} "
        f"<span class='ent-meta'>· {cardinality} · {len(e.fields)} حقل</span>"
        "</h2>",
    ]
    if intro:
        out.append(f"<div class='intro'>{intro}</div>")

    for section_name, fs in sections:
        if len(sections) > 1:
            out.append(f"<h3>{html.escape(section_name)}</h3>")
        out.append("<table class='fields'>")
        out.append(
            "<thead><tr><th>المفتاح التقني</th><th>الاسم والوصف</th>"
            "<th>النوع</th></tr></thead><tbody>"
        )
        for f in fs:
            out.append(render_field_row(f))
        out.append("</tbody></table>")
    out.append("</section>")
    return "\n".join(out)


def render_group(name: str, entities_in_group: list[EntitySpec]) -> str:
    parts = [f"<h1 class='group-title'>{html.escape(name)}</h1>"]
    parts.extend(render_entity_section(e) for e in entities_in_group)
    return "\n".join(parts)


def render_html(entities: list[EntitySpec]) -> str:
    by_table = {e.table: e for e in entities}

    # ====== توليد فهرس الكيانات ======
    toc_items = []
    for group_name, tables in GROUPS:
        toc_items.append(
            f"<li class='toc-group'>{html.escape(group_name)}</li>"
        )
        for t in tables:
            if t in by_table:
                e = by_table[t]
                toc_items.append(
                    f"<li><a href='#ent-{t}'>"
                    f"{html.escape(e.title_ar)}</a></li>"
                )
    toc_html = "<ul class='toc'>" + "".join(toc_items) + "</ul>"

    # ====== توليد بطاقات المعايير ======
    standards_html = ""
    for s in STANDARDS:
        standards_html += (
            "<div class='std-card'>"
            f"<h4>{s['title']}</h4>"
            f"<p class='scope'><strong>النطاق:</strong> {s['scope']}</p>"
            f"<p><strong>كيف نستخدمه:</strong> {s['use']}</p>"
            "</div>"
        )

    # ====== توليد أقسام الكيانات ======
    body_sections = []
    for group_name, tables in GROUPS:
        group_entities = [by_table[t] for t in tables if t in by_table]
        body_sections.append(render_group(group_name, group_entities))
    body_html = "\n".join(body_sections)

    return f"""<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
<meta charset="utf-8">
<title>{html.escape(DOC_TITLE)}</title>
<style>
@page {{
  size: A4;
  margin: 2cm 1.6cm 2cm 1.6cm;
  @bottom-center {{
    content: counter(page) " / " counter(pages);
    font-family: 'DejaVu Sans';
    font-size: 9pt;
    color: #777;
  }}
  @top-center {{
    content: "{html.escape(DOC_TITLE)} — {html.escape(DOC_VERSION)}";
    font-family: 'DejaVu Sans';
    font-size: 9pt;
    color: #777;
  }}
}}
@page :first {{ @top-center {{ content: ""; }} @bottom-center {{ content: ""; }} }}

* {{ box-sizing: border-box; }}
html, body {{
  font-family: 'DejaVu Sans', sans-serif;
  direction: rtl;
  color: #1a1a1a;
  font-size: 10.5pt;
  line-height: 1.65;
}}

/* ============= صفحة الغلاف ============= */
.cover {{
  page-break-after: always;
  text-align: center;
  padding-top: 4cm;
  color: #1C6B85;
}}
.cover .org {{ font-size: 14pt; letter-spacing: 2px; color: #555; }}
.cover .title {{
  font-size: 28pt; font-weight: bold; margin: 0.8em 0 0.4em 0;
  color: #0E3D4D;
}}
.cover .subtitle {{ font-size: 14pt; color: #1C6B85; margin-bottom: 4em; }}
.cover .tagline {{
  background: #E8F4F8; border-right: 4px solid #1C6B85; border-left: 4px solid #1C6B85;
  padding: 1em 1.5em; display: inline-block; max-width: 14cm; text-align: right;
  border-radius: 8px; margin: 0 auto;
}}
.cover .audience {{ margin-top: 6em; font-size: 11pt; color: #555; }}
.cover .meta {{ margin-top: 2em; font-size: 10pt; color: #777; }}

/* ============= فهرس ============= */
.toc-page {{ page-break-after: always; }}
h1.section-title {{
  color: #0E3D4D; font-size: 22pt; padding-bottom: 0.2em;
  border-bottom: 3px solid #1C6B85; margin-top: 0;
}}
ul.toc {{ list-style: none; padding-right: 0; columns: 2; column-gap: 2em; }}
ul.toc li {{ margin: 0.25em 0; break-inside: avoid; }}
ul.toc li.toc-group {{
  font-weight: bold; color: #1C6B85; margin-top: 0.8em;
  border-bottom: 1px solid #ccd;
}}
ul.toc a {{ color: #1a1a1a; text-decoration: none; }}

/* ============= المعايير ============= */
.standards-page {{ page-break-after: always; }}
.std-card {{
  background: #F8FAFC; border-right: 4px solid #1C6B85;
  padding: 0.8em 1em; margin: 0.6em 0; border-radius: 6px;
  break-inside: avoid;
}}
.std-card h4 {{ margin: 0 0 0.4em 0; color: #0E3D4D; font-size: 12pt; }}
.std-card p {{ margin: 0.3em 0; }}
.std-card .scope {{ color: #555; }}

/* ============= مخطط سير العمل ============= */
.workflow-page {{ page-break-after: always; }}
.workflow-caption {{
  text-align: center; color: #555; font-size: 10pt; margin-top: 0.6em;
}}
.flow {{
  max-width: 14cm; margin: 0.6em auto; display: flex; flex-direction: column;
  align-items: stretch;
}}
.step {{
  display: flex; align-items: stretch; background: #E8F4F8;
  border: 2px solid #1C6B85; border-radius: 8px; overflow: hidden;
  break-inside: avoid;
}}
.step.step-h {{ background: #1C6B85; color: #FFFFFF; }}
.step.step-h .num {{ background: #0E3D4D; }}
.step.step-h .step-desc {{ color: #E8F4F8; }}
.step .num {{
  background: #1C6B85; color: #FFFFFF; font-weight: bold; font-size: 14pt;
  display: flex; align-items: center; justify-content: center;
  min-width: 2.2cm; padding: 0.3em 0.4em;
}}
.step .step-body {{ padding: 0.5em 0.7em; flex-grow: 1; }}
.step .step-title {{ font-weight: bold; font-size: 11pt; color: #0E3D4D; }}
.step.step-h .step-title {{ color: #FFFFFF; }}
.step .step-desc {{ font-size: 9pt; color: #555; margin-top: 2px; }}
.step-row {{ display: flex; gap: 0.4cm; }}
.step.step-half {{ flex: 1 1 0; }}
.arrow {{
  width: 0; height: 0; border-right: 9px solid transparent;
  border-left: 9px solid transparent; border-top: 12px solid #1C6B85;
  margin: 0.25em auto;
}}

/* ============= الكيانات والحقول ============= */
h1.group-title {{
  color: #FFFFFF; background: #1C6B85; padding: 0.4em 0.8em;
  font-size: 18pt; margin-top: 2em; border-radius: 6px;
  page-break-before: always;
}}
section.entity {{ margin: 1.5em 0; page-break-inside: auto; }}
section.entity h2 {{
  color: #0E3D4D; font-size: 14pt;
  border-right: 5px solid #1C6B85; padding-right: 0.5em;
  margin-top: 1.4em; page-break-after: avoid;
}}
section.entity h2 .ent-meta {{
  font-size: 10pt; color: #777; font-weight: normal;
}}
section.entity h3 {{
  color: #1C6B85; font-size: 11pt; margin: 1.2em 0 0.4em 0;
  background: #E8F4F8; padding: 0.25em 0.6em; border-radius: 4px;
  page-break-after: avoid;
}}
.intro {{
  background: #FFF8E7; border-right: 3px solid #FFC107;
  padding: 0.6em 0.8em; border-radius: 4px; margin-bottom: 0.8em;
  font-size: 10pt; line-height: 1.6;
}}

table.fields {{
  width: 100%; border-collapse: collapse; margin: 0.4em 0;
}}
table.fields thead {{ display: table-header-group; }}
table.fields th {{
  background: #1C6B85; color: white; padding: 6px 8px;
  font-size: 9.5pt; font-weight: bold; text-align: right;
}}
table.fields td {{
  border: 1px solid #d8dde2; padding: 6px 8px; vertical-align: top;
  font-size: 9.5pt;
}}
table.fields tr {{ page-break-inside: avoid; }}
td.fkey {{ width: 22%; white-space: nowrap; }}
td.ftype {{ width: 14%; color: #1C6B85; font-weight: bold; }}
.fkey code {{
  background: #F0F4F8; padding: 1px 6px; border-radius: 3px;
  font-family: 'DejaVu Sans Mono', monospace; font-size: 8.5pt;
  color: #0E3D4D;
}}
.req {{
  color: #DC3545; font-weight: bold; padding-right: 4px;
}}
.help {{
  color: #666; font-size: 9pt; margin-top: 3px; font-style: italic;
}}
.choices-title {{
  margin-top: 6px; font-size: 9pt; color: #0E3D4D; font-weight: bold;
}}
ul.choices {{
  margin: 4px 0; padding-right: 1.2em; font-size: 9pt;
  columns: 2; column-gap: 1em;
}}
ul.choices li {{ break-inside: avoid; padding: 1px 0; }}
ul.choices code {{
  background: #F0F4F8; padding: 0 4px; border-radius: 3px;
  font-family: 'DejaVu Sans Mono', monospace; font-size: 8pt;
  color: #555;
}}
details > summary {{ cursor: pointer; }}

/* ============= قواعد العمل المهنية ============= */
.principles {{ page-break-before: always; }}
.principles ol {{ padding-right: 1.5em; }}
.principles li {{
  margin: 0.6em 0; padding: 0.5em 0.8em; background: #F8FAFC;
  border-right: 3px solid #1C6B85; border-radius: 4px;
  break-inside: avoid;
}}
.principles strong {{ color: #0E3D4D; }}

footer.end {{
  margin-top: 4em; padding-top: 1em; border-top: 2px solid #1C6B85;
  color: #555; font-size: 9pt; text-align: center;
}}
</style>
</head>
<body>

<!-- ====== الغلاف ====== -->
<div class="cover">
  <div class="org">جـمـعـيـة حـقّـنـا</div>
  <div class="title">{html.escape(DOC_TITLE)}</div>
  <div class="subtitle">{html.escape(DOC_SUBTITLE)}</div>
  <div class="tagline">
    الخدمات الاجتماعية · القانون والدفاع والحقوق · التعليم والتمكين
  </div>
  <div class="audience">{html.escape(DOC_AUDIENCE)}</div>
  <div class="meta">{html.escape(DOC_VERSION)}</div>
</div>

<!-- ====== المقدّمة + الفهرس ====== -->
<div class="toc-page">
  <h1 class="section-title">المقدّمة</h1>
  {INTRO_HTML}
  <h1 class="section-title" style="margin-top:2em;">الفهرس</h1>
  {toc_html}
</div>

<!-- ====== المعايير الدولية ====== -->
<div class="standards-page">
  <h1 class="section-title">المعايير والبروتوكولات المرجعية</h1>
  <p>
    منظومة حقّنا التوثيقية مبنية على أربعة معايير دولية. كل حقل في النظام
    له جذر منهجي في واحد أو أكثر منها:
  </p>
  {standards_html}
</div>

<!-- ====== مخطط سير العمل ====== -->
<div class="workflow-page">
  <h1 class="section-title">مخطط سير العمل التوثيقي</h1>
  <p>
    من اللحظة الأولى للتعرّف على الناجي وحتى الأرشفة الآمنة أو الإحالة لجهة
    قضائية دولية. هذه هي العشر مراحل المعتمَدة:
  </p>
  {WORKFLOW_HTML}
  <div class="workflow-caption">
    سير العمل التوثيقي — كل مرحلة منها تُسجَّل في النظام عبر الكيانات
    التالية في هذا الكتيب.
  </div>
</div>

<!-- ====== مبادئ مهنية ====== -->
<div class="principles">
  <h1 class="section-title">عشرة مبادئ مهنية ملزِمة</h1>
  <ol>
    <li><strong>الموافقة المستنيرة أولاً.</strong> لا توثيق دون موافقة موثّقة
    ومفهومة من الناجي على الاستخدامات المحتملة.</li>
    <li><strong>كرامة الناجي قبل أي شيء.</strong> أوقف المقابلة فوراً عند
    ظهور علامات إعادة الصدمة وأحلّ لدعم نفسي.</li>
    <li><strong>دقّة الأقوال.</strong> سجّل بأقوال الناجي مباشرةً قدر الإمكان،
    لا بتلخيصك. الاقتباس المباشر له ثقل قانوني أعلى.</li>
    <li><strong>سلسلة الحيازة لكل دليل.</strong> كل وثيقة لها بصمة SHA-256
    ومسار توثيقي كامل (مَن، متى، أين، كيف).</li>
    <li><strong>التحقق المتقاطع.</strong> اسعَ دائماً لشاهد مستقل واحد على
    الأقل بمعزل عن الناجي.</li>
    <li><strong>الحساسية الجنسية والنفسية.</strong> اعتبارات النوع الاجتماعي
    في تعيين المحاوِر، وحساسية فائقة في تفاصيل العنف الجنسي.</li>
    <li><strong>سرّية البيانات.</strong> لا تُفصح عن بيانات أي ناجٍ خارج
    دائرة المُخوَّلين. الملاحظات السرّية للمشرفين فقط.</li>
    <li><strong>أرشفة بدلاً من حذف.</strong> الحذف النهائي مخالف لمتطلبات
    سلامة الأدلة. نُؤرشف فقط مع تسجيل السبب والشخص.</li>
    <li><strong>أمن الموثّق.</strong> لا تأخذ مخاطر شخصية أو أمنية. سجّل
    المخاوف في «ملاحظات أمنية» وأبلغ المشرف فوراً.</li>
    <li><strong>تكامل البيانات.</strong> لا تترك حقلاً مهماً فارغاً. ما لا
    تعرفه اكتب صراحةً «غير متوفر» مع السبب.</li>
  </ol>
</div>

<!-- ====== الكيانات والحقول ====== -->
{body_html}

<footer class="end">
  جمعية حقّنا · هذا الكتيب وثيقة داخلية للموثّقين والمشرفين — يُحدَّث
  دورياً بحسب تطوّر النظام.
</footer>

</body>
</html>
"""


def main() -> None:
    out_path = (
        Path(sys.argv[1]) if len(sys.argv) > 1
        else Path("scripts/output/كتيب-البروتوكولات-والحقول.pdf")
    )
    out_path.parent.mkdir(parents=True, exist_ok=True)
    _, entities = load_all()
    html_str = render_html(entities)
    # نحفظ نسخة HTML أيضاً للمراجعة
    html_path = out_path.with_suffix(".html")
    html_path.write_text(html_str, encoding="utf-8")
    weasyprint.HTML(string=html_str).write_pdf(str(out_path))
    print(f"PDF: {out_path}  ({out_path.stat().st_size // 1024} KB)")
    print(f"HTML (للمراجعة): {html_path}")


if __name__ == "__main__":
    main()

/**
 * مكتبة الجولات التفاعلية لجمعية حقّنا
 * تعرض tooltips على عناصر محددة في الصفحة لتوجيه المتطوّعين.
 *
 * الاستخدام:
 *   const tour = new HaqqunaTour([
 *     {target: '[name=case_reference]', title: '...', content: '...'},
 *     ...
 *   ]);
 *   tour.start();
 *
 * تُشغَّل تلقائياً عند وجود ?tour=<lesson_id> في URL
 */

class HaqqunaTour {
  constructor(steps, options = {}) {
    this.steps = steps || [];
    this.options = options;
    this.currentIndex = 0;
    this.overlay = null;
    this.tooltip = null;
    this.highlight = null;
    this.onComplete = options.onComplete || (() => {});
  }

  start() {
    if (!this.steps.length) return;
    this._buildOverlay();
    this.show(0);
  }

  _buildOverlay() {
    if (this.overlay) return;
    this.overlay = document.createElement('div');
    this.overlay.className = 'haqquna-tour-overlay';
    this.highlight = document.createElement('div');
    this.highlight.className = 'haqquna-tour-highlight';
    this.tooltip = document.createElement('div');
    this.tooltip.className = 'haqquna-tour-tooltip';
    document.body.appendChild(this.overlay);
    document.body.appendChild(this.highlight);
    document.body.appendChild(this.tooltip);
  }

  show(index) {
    if (index < 0 || index >= this.steps.length) return;
    this.currentIndex = index;
    const step = this.steps[index];
    const target = document.querySelector(step.target);

    if (!target) {
      // إن لم نجد العنصر، أظهر الـtooltip في وسط الشاشة
      this.highlight.style.display = 'none';
      this._renderTooltip(step, null);
      return;
    }

    target.scrollIntoView({behavior: 'smooth', block: 'center', inline: 'center'});

    // أعطِ المتصفح وقتاً للـscroll قبل تحديد الموقع
    setTimeout(() => {
      const rect = target.getBoundingClientRect();
      const pad = 6;
      Object.assign(this.highlight.style, {
        display: 'block',
        position: 'fixed',
        top: (rect.top - pad) + 'px',
        left: (rect.left - pad) + 'px',
        width: (rect.width + pad * 2) + 'px',
        height: (rect.height + pad * 2) + 'px',
      });
      this._renderTooltip(step, rect);
    }, 200);
  }

  _renderTooltip(step, rect) {
    const total = this.steps.length;
    const i = this.currentIndex;
    this.tooltip.innerHTML = `
      <div class="haqquna-tour-tooltip-inner">
        <div class="haqquna-tour-header">
          <span class="haqquna-tour-step">${i + 1} / ${total}</span>
          <strong class="haqquna-tour-title">${this._esc(step.title || '')}</strong>
        </div>
        <div class="haqquna-tour-body">${this._esc(step.content || '')}</div>
        <div class="haqquna-tour-footer">
          ${i > 0 ? '<button class="htour-prev btn btn-sm btn-outline-secondary">السابق</button>' : ''}
          <button class="htour-skip btn btn-sm btn-outline-danger">إنهاء</button>
          ${i < total - 1
            ? '<button class="htour-next btn btn-sm btn-haqquna">التالي →</button>'
            : '<button class="htour-finish btn btn-sm btn-success">إنهاء ✓</button>'
          }
        </div>
      </div>
    `;

    // موضع الـtooltip
    if (rect) {
      const tipW = 320;
      const top = rect.bottom + 14;
      let left = rect.left + (rect.width / 2) - (tipW / 2);
      left = Math.max(20, Math.min(left, window.innerWidth - tipW - 20));
      Object.assign(this.tooltip.style, {
        position: 'fixed',
        top: top + 'px',
        left: left + 'px',
        width: tipW + 'px',
        display: 'block',
      });
    } else {
      Object.assign(this.tooltip.style, {
        position: 'fixed',
        top: '40%', left: '50%', width: '340px',
        transform: 'translate(-50%, -50%)',
        display: 'block',
      });
    }

    this.tooltip.querySelector('.htour-skip')?.addEventListener('click', () => this.end());
    this.tooltip.querySelector('.htour-next')?.addEventListener('click', () => this.next());
    this.tooltip.querySelector('.htour-prev')?.addEventListener('click', () => this.prev());
    this.tooltip.querySelector('.htour-finish')?.addEventListener('click', () => {
      this.onComplete();
      this.end();
    });
  }

  _esc(s) {
    return String(s)
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  }

  next() {
    if (this.currentIndex < this.steps.length - 1) this.show(this.currentIndex + 1);
  }

  prev() {
    if (this.currentIndex > 0) this.show(this.currentIndex - 1);
  }

  end() {
    [this.overlay, this.tooltip, this.highlight].forEach(el => el?.remove());
    this.overlay = this.tooltip = this.highlight = null;
  }
}

// التشغيل التلقائي إن وُجد ?tour=<lesson_id> في URL
(function() {
  const params = new URLSearchParams(window.location.search);
  const lessonId = params.get('tour');
  if (!lessonId) return;

  fetch(`/tutorials/lesson/${lessonId}/tour/`)
    .then(r => r.json())
    .then(data => {
      if (!data.steps || !data.steps.length) return;
      const tour = new HaqqunaTour(data.steps, {
        onComplete: () => {
          // ضع علامة إنجاز الجولة (اختياري)
          const csrf = document.querySelector('[name=csrfmiddlewaretoken]')?.value;
          if (csrf) {
            fetch(`/tutorials/lesson/${lessonId}/complete/`, {
              method: 'POST',
              headers: {'X-CSRFToken': csrf, 'Content-Type': 'application/json'},
              body: '{}',
            });
          }
        }
      });
      // أعطِ الصفحة وقتاً للتحميل الكامل
      setTimeout(() => tour.start(), 500);
    });
})();

window.HaqqunaTour = HaqqunaTour;

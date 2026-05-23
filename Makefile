.PHONY: help install migrate seed admin run dev test clean reset backup restore export-excel train train-reset train-seed

PYTHON := python3
PORT ?= 8000
HOST ?= 0.0.0.0

help:
	@echo "جمعية حقّنا - HAQQUNA - أوامر التشغيل"
	@echo ""
	@echo "=== الإنتاج (التوثيق الفعلي - المنفذ 8000) ==="
	@echo "  make run         - تشغيل النظام الفعلي"
	@echo "  make backup      - نسخة احتياطية JSON"
	@echo ""
	@echo "=== التدريب (المتطوّعون - المنفذ 8001) ==="
	@echo "  make train       - تشغيل بيئة التدريب المنفصلة"
	@echo "  make train-reset - مسح بيانات التدريب وإعادة البدء"
	@echo "  make train-seed  - بذر بيانات تجريبية للمتدرّبين"
	@echo ""
	@echo "=== أوامر تقنية ==="
	@echo "  make install     - تثبيت الحزم فقط"
	@echo "  make migrate     - ترحيل قاعدة البيانات فقط"
	@echo "  make seed        - بذر مراكز الاحتجاز وأنماط التعذيب"
	@echo "  make admin       - إنشاء/إعادة ضبط حساب admin"
	@echo "  make dev         - تشغيل سيرفر التطوير فقط"
	@echo "  make reset       - حذف القاعدة الفعلية وإعادة البناء (DESTRUCTIVE!)"
	@echo "  make clean       - تنظيف __pycache__ والملفات المؤقتة"

train:
	@bash run_training.sh

train-reset:
	DJANGO_MODE=training $(PYTHON) manage.py reset_training_db --yes-i-am-sure

train-seed:
	DJANGO_MODE=training $(PYTHON) manage.py seed_training_data

run:
	@bash run.sh

install:
	$(PYTHON) -m pip install -r requirements.txt

migrate:
	$(PYTHON) manage.py migrate

seed:
	$(PYTHON) manage.py seed_reference_data

admin:
	$(PYTHON) manage.py create_admin

dev:
	$(PYTHON) manage.py runserver $(HOST):$(PORT)

backup:
	@mkdir -p backups
	$(PYTHON) manage.py dumpdata survivors social_survey accounts \
		--natural-foreign --natural-primary --indent 2 \
		-o backups/backup_$(shell date +%Y%m%d_%H%M%S).json
	@echo "✓ تم النسخ في مجلد backups/"

reset:
	@echo "⚠ سيتم حذف قاعدة البيانات!"
	@read -p "اكتب 'yes' للتأكيد: " confirm && [ "$$confirm" = "yes" ]
	rm -f db.sqlite3
	$(PYTHON) manage.py migrate
	$(PYTHON) manage.py create_admin
	$(PYTHON) manage.py seed_reference_data
	@echo "✓ تم إعادة البناء"

clean:
	find . -name __pycache__ -type d -not -path "./.git/*" -exec rm -rf {} + 2>/dev/null || true
	find . -name "*.pyc" -not -path "./.git/*" -delete 2>/dev/null || true
	@echo "✓ تم التنظيف"

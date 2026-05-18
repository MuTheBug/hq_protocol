from django.urls import path

from . import exports, views

app_name = "survivors"

urlpatterns = [
    path("", views.survivor_list, name="list"),
    path("new/", views.survivor_create, name="create"),
    path("<int:pk>/", views.survivor_detail, name="detail"),
    path("<int:pk>/edit/", views.survivor_edit, name="edit"),
    path("<int:pk>/archive/", views.survivor_archive, name="archive"),
    path("<int:pk>/unarchive/", views.survivor_unarchive, name="unarchive"),
    path("archive/", views.survivor_archive_list, name="archive_list"),
    path("<int:pk>/print/", exports.survivor_print, name="print"),
    path("<int:pk>/contact/", views.contact_edit, name="contact_edit"),
    path("<int:pk>/photos/", views.photos_edit, name="photos_edit"),
    path("<int:pk>/referrals/", views.referrals_edit, name="referrals_edit"),
    path("<int:pk>/consent/", views.consent_edit, name="consent_edit"),
    path("<int:pk>/consent/print/", exports.consent_print, name="consent_print"),
    path("<int:pk>/detention-event/add/",
         views.detention_event_add, name="detention_event_add"),
    path("<int:pk>/detention-period/add/",
         views.detention_period_add, name="detention_period_add"),
    path("<int:pk>/release/", views.release_edit, name="release_edit"),
    path("<int:pk>/witness/add/", views.witness_add, name="witness_add"),
    path("<int:pk>/document/add/", views.document_add, name="document_add"),
    path("<int:pk>/medical/add/", views.medical_add, name="medical_add"),
    # ملاحظات
    path("<int:pk>/note/add/", views.note_add, name="note_add"),
    path("note/<int:pk>/edit/", views.note_edit, name="note_edit"),
    path("note/<int:pk>/delete/", views.note_delete, name="note_delete"),
    # مقابلات
    path("<int:pk>/interview/add/", views.interview_add, name="interview_add"),
    path("interview/<int:pk>/", views.interview_detail, name="interview_detail"),
    path("interview/<int:pk>/edit/", views.interview_edit, name="interview_edit"),
    path("interview/<int:interview_pk>/media/add/",
         views.media_add, name="media_add"),
    path("media/<int:pk>/delete/", views.media_delete, name="media_delete"),
    # تصدير واستيراد
    path("export/", exports.export_chooser, name="export_chooser"),
    path("export/excel/", exports.export_excel, name="export_excel"),
    path("export/pdf/", exports.export_pdf_print, name="export_pdf"),
    path("export/json/", exports.export_json, name="export_json"),
    path("import/json/", exports.import_json, name="import_json"),
    # الإحالة لجهات خارجية
    path("<int:pk>/transmit/", exports.transmit_chooser, name="transmit_chooser"),
    path("<int:pk>/transmit/package/", exports.transmit_package, name="transmit_package"),
    # API للقوائم المتدرّجة (المدن/الأحياء)
    path("api/syria/cities/", exports.api_cities, name="api_cities"),
    path("api/syria/neighborhoods/", exports.api_neighborhoods, name="api_neighborhoods"),
]

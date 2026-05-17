from django.urls import path

from . import views

app_name = "survivors"

urlpatterns = [
    path("", views.survivor_list, name="list"),
    path("new/", views.survivor_create, name="create"),
    path("<int:pk>/", views.survivor_detail, name="detail"),
    path("<int:pk>/edit/", views.survivor_edit, name="edit"),
    path("<int:pk>/consent/", views.consent_edit, name="consent_edit"),
    path("<int:pk>/detention-event/add/",
         views.detention_event_add, name="detention_event_add"),
    path("<int:pk>/detention-period/add/",
         views.detention_period_add, name="detention_period_add"),
    path("<int:pk>/release/", views.release_edit, name="release_edit"),
    path("<int:pk>/witness/add/", views.witness_add, name="witness_add"),
    path("<int:pk>/document/add/", views.document_add, name="document_add"),
    path("<int:pk>/medical/add/", views.medical_add, name="medical_add"),
]

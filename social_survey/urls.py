from django.urls import path

from . import views

app_name = "social_survey"

urlpatterns = [
    path("", views.survey_list, name="list"),
    path("household/<int:pk>/", views.household_detail, name="household_detail"),
    path("survivor/<int:survivor_pk>/household/",
         views.household_create_or_edit, name="household_edit"),
    path("household/<int:household_pk>/child/add/",
         views.child_add, name="child_add"),
    path("child/<int:pk>/edit/", views.child_edit, name="child_edit"),
    path("household/<int:household_pk>/housing/",
         views.housing_edit, name="housing_edit"),
    path("household/<int:household_pk>/health/",
         views.health_edit, name="health_edit"),
    path("household/<int:household_pk>/needs/",
         views.needs_edit, name="needs_edit"),
    path("survivor/<int:survivor_pk>/education/",
         views.education_edit, name="education_edit"),
    path("survivor/<int:survivor_pk>/employment/",
         views.employment_edit, name="employment_edit"),
]

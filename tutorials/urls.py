from django.urls import path

from . import views

app_name = "tutorials"

urlpatterns = [
    path("", views.home, name="home"),
    path("lesson/<str:lesson_id>/", views.lesson, name="lesson"),
    path("lesson/<str:lesson_id>/submit/", views.submit_quiz, name="submit_quiz"),
    path("lesson/<str:lesson_id>/complete/", views.mark_complete, name="mark_complete"),
    path("lesson/<str:lesson_id>/tour/", views.tour_data, name="tour_data"),
]

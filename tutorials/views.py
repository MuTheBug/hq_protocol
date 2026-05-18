import json

from django.contrib import messages
from django.contrib.auth.decorators import login_required
from django.http import JsonResponse
from django.shortcuts import redirect, render
from django.utils import timezone
from django.views.decorators.http import require_POST

from .lessons import LESSONS, get_lesson, lessons_ordered
from .models import TutorialProgress


@login_required
def home(request):
    """صفحة الدروس الرئيسية - شبكة الدروس مع التقدّم."""
    user_progress = {
        p.lesson_id: p
        for p in TutorialProgress.objects.filter(user=request.user)
    }
    lessons_with_progress = []
    for lesson in lessons_ordered():
        prog = user_progress.get(lesson["id"])
        lessons_with_progress.append({
            **lesson,
            "progress": prog,
            "is_completed": prog and prog.is_completed,
            "is_started": prog is not None,
        })

    total = len(LESSONS)
    completed = sum(1 for l in lessons_with_progress if l["is_completed"])
    percent = round(completed / total * 100) if total else 0

    return render(request, "tutorials/home.html", {
        "lessons": lessons_with_progress,
        "total": total, "completed": completed, "percent": percent,
    })


@login_required
def lesson(request, lesson_id):
    """صفحة درس فردي - محتوى + اختبار + جولة."""
    data = get_lesson(lesson_id)
    if not data:
        messages.error(request, "الدرس غير موجود.")
        return redirect("tutorials:home")

    progress, _ = TutorialProgress.objects.get_or_create(
        user=request.user, lesson_id=lesson_id,
    )

    # حدّد الدرس التالي والسابق
    all_lessons = lessons_ordered()
    idx = next((i for i, l in enumerate(all_lessons) if l["id"] == lesson_id), -1)
    prev_lesson = all_lessons[idx - 1] if idx > 0 else None
    next_lesson = all_lessons[idx + 1] if 0 <= idx < len(all_lessons) - 1 else None

    return render(request, "tutorials/lesson.html", {
        "lesson": data,
        "progress": progress,
        "prev_lesson": prev_lesson,
        "next_lesson": next_lesson,
        "lesson_json": json.dumps({
            "id": data["id"],
            "quiz": data.get("quiz", []),
            "tour": data.get("tour"),
        }, ensure_ascii=False),
    })


@login_required
@require_POST
def submit_quiz(request, lesson_id):
    """يحفظ نتيجة الاختبار ويُعلن إكمال الدرس."""
    data = get_lesson(lesson_id)
    if not data:
        return JsonResponse({"error": "lesson_not_found"}, status=404)

    body = json.loads(request.body or b"{}")
    answers = body.get("answers", [])
    quiz = data.get("quiz", [])
    if len(answers) != len(quiz):
        return JsonResponse({"error": "answers_count_mismatch"}, status=400)

    correct_count = 0
    results = []
    for i, q in enumerate(quiz):
        user_ans = answers[i] if i < len(answers) else None
        is_correct = user_ans == q["correct"]
        if is_correct:
            correct_count += 1
        results.append({
            "correct": is_correct,
            "correct_answer": q["correct"],
            "explanation": q.get("explanation", ""),
        })

    progress, _ = TutorialProgress.objects.get_or_create(
        user=request.user, lesson_id=lesson_id,
    )
    progress.quiz_score = correct_count
    progress.quiz_max = len(quiz)
    # الإكمال بنسبة نجاح 60%+
    pass_threshold = len(quiz) * 0.6
    if correct_count >= pass_threshold and not progress.completed_at:
        progress.completed_at = timezone.now()
    progress.save()

    return JsonResponse({
        "score": correct_count,
        "max": len(quiz),
        "percent": round(correct_count / len(quiz) * 100),
        "passed": correct_count >= pass_threshold,
        "results": results,
        "completed": progress.is_completed,
    })


@login_required
@require_POST
def mark_complete(request, lesson_id):
    """يُعلن إكمال الدرس يدوياً (للدروس بدون اختبار)."""
    data = get_lesson(lesson_id)
    if not data:
        return JsonResponse({"error": "lesson_not_found"}, status=404)
    progress, _ = TutorialProgress.objects.get_or_create(
        user=request.user, lesson_id=lesson_id,
    )
    if not progress.completed_at:
        progress.completed_at = timezone.now()
        progress.save()
    return JsonResponse({"completed": True})


@login_required
def tour_data(request, lesson_id):
    """يُرجع خطوات الجولة التفاعلية بصيغة JSON."""
    data = get_lesson(lesson_id)
    if not data or not data.get("tour"):
        return JsonResponse({"steps": []})
    return JsonResponse(data["tour"])

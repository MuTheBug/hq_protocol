"""Signals لحساب درجات الناجي تلقائياً عند تحديث أي دليل مرتبط."""

from django.db.models.signals import post_delete, post_save
from django.dispatch import receiver

from .models import (
    DetentionEvent, DetentionPeriod, InformedConsent, Interview,
    MedicalAssessment, ReleaseEvent, SupportingDocument, SurvivorProfile,
    Witness,
)


def _recompute_for_survivor(survivor):
    if survivor and survivor.pk:
        try:
            survivor.recompute_scores(save=True)
        except Exception:
            pass


@receiver([post_save, post_delete], sender=DetentionEvent)
@receiver([post_save, post_delete], sender=DetentionPeriod)
@receiver([post_save, post_delete], sender=Witness)
@receiver([post_save, post_delete], sender=SupportingDocument)
@receiver([post_save, post_delete], sender=MedicalAssessment)
@receiver([post_save, post_delete], sender=ReleaseEvent)
@receiver([post_save, post_delete], sender=InformedConsent)
@receiver([post_save, post_delete], sender=Interview)
def update_scores_on_evidence_change(sender, instance, **kwargs):
    _recompute_for_survivor(getattr(instance, "survivor", None))


@receiver(post_save, sender=SurvivorProfile)
def recompute_on_profile_save(sender, instance, created, **kwargs):
    # عند الإنشاء فقط - لتجنّب الـrecursion
    if created:
        _recompute_for_survivor(instance)

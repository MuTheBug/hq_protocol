"""تحويل النماذج إلى/من dictionaries لـ JSON.

نظام مبسّط بدون DRF - دالة لكل نوع تحوّل كائناً أو queryset لـJSON.
"""

from datetime import date, datetime


def _date(d):
    return d.isoformat() if d else None


def _dt(d):
    return d.isoformat() if d else None


def serialize_user(user):
    if not user:
        return None
    return {
        "id": user.id,
        "username": user.username,
        "full_name_ar": user.full_name_ar,
        "role": user.role,
        "role_display": user.get_role_display(),
        "can_document": user.can_document,
        "can_review": user.can_review,
        "is_superuser": user.is_superuser,
    }


def serialize_facility(f):
    return {
        "id": f.id,
        "name_ar": f.name_ar,
        "name_en": f.name_en,
        "branch_number": f.branch_number,
        "parent_entity": f.parent_entity,
        "parent_entity_display": f.get_parent_entity_display(),
        "governorate": f.governorate,
        "address": f.address,
    }


def serialize_torture_method(t):
    return {
        "id": t.id,
        "name_ar": t.name_ar,
        "name_en": t.name_en,
        "category": t.category,
        "category_display": t.get_category_display(),
    }


def serialize_survivor(s, detail=False):
    """ملخص أو تفاصيل ناجٍ."""
    data = {
        "id": s.id,
        "case_reference": s.case_reference,
        "case_uid": str(s.case_uid),
        "full_name": s.full_name,
        "first_name": s.first_name,
        "father_name": s.father_name,
        "grandfather_name": s.grandfather_name,
        "family_name": s.family_name,
        "mother_name": s.mother_name,
        "alias": s.alias,
        "national_id": s.national_id,
        "birth_date": _date(s.birth_date),
        "birth_date_approximate": s.birth_date_approximate,
        "birth_governorate": s.birth_governorate,
        "birth_place_detail": s.birth_place_detail,
        "gender": s.gender,
        "gender_display": s.get_gender_display(),
        "nationality": s.nationality,
        "marital_status_at_detention": s.marital_status_at_detention,
        "address_at_detention": s.address_at_detention,
        "governorate_at_detention": s.governorate_at_detention,
        "occupation_category": s.occupation_category,
        "occupation_detail": s.occupation_detail,
        "political_activity_category": s.political_activity_category,
        "political_activity_detail": s.political_activity_detail,
        "current_phone": s.current_phone,
        "current_email": s.current_email,
        "current_country": s.current_country,
        "current_governorate": s.current_governorate,
        "current_city": s.current_city,
        "next_of_kin_name": s.next_of_kin_name,
        "next_of_kin_relation": s.next_of_kin_relation,
        "next_of_kin_phone": s.next_of_kin_phone,
        "file_classification": s.file_classification,
        "file_classification_display": s.get_file_classification_display(),
        "reliability_score": s.reliability_score,
        "corroboration_score": s.corroboration_score,
        "completeness_score": s.completeness_score,
        "overall_score": float(s.overall_score),
        "is_archived": s.is_archived,
        "created_at": _dt(s.created_at),
        "updated_at": _dt(s.updated_at),
    }
    if detail:
        data["detention_events"] = [
            serialize_detention_event(e) for e in s.detention_events.all()
        ]
        data["detention_periods"] = [
            serialize_detention_period(p) for p in
            s.detention_periods.select_related("facility").all()
        ]
        data["witnesses_count"] = s.witnesses.count()
        data["documents_count"] = s.documents.count()
        data["notes"] = [serialize_note(n) for n in s.notes.all()]
        data["consent"] = (
            serialize_consent(s.consent) if hasattr(s, "consent") else None
        )
        data["release_event"] = (
            serialize_release(s.release_event) if hasattr(s, "release_event") else None
        )
    return data


def serialize_detention_event(e):
    return {
        "id": e.id,
        "survivor_id": e.survivor_id,
        "detention_date": _date(e.detention_date),
        "date_approximate": e.date_approximate,
        "detention_location": e.detention_location,
        "governorate": e.governorate,
        "arresting_entity": e.arresting_entity,
        "arresting_personnel_details": e.arresting_personnel_details,
        "reason_stated": e.reason_stated,
        "circumstances": e.circumstances,
        "witnesses_to_arrest": e.witnesses_to_arrest,
        "family_notified": e.family_notified,
        "notes": e.notes,
    }


def serialize_detention_period(p):
    return {
        "id": p.id,
        "survivor_id": p.survivor_id,
        "detention_event_id": p.detention_event_id,
        "facility_id": p.facility_id,
        "facility_name": str(p.facility),
        "from_date": _date(p.from_date),
        "to_date": _date(p.to_date),
        "from_date_approximate": p.from_date_approximate,
        "to_date_approximate": p.to_date_approximate,
        "order_index": p.order_index,
        "cell_description": p.cell_description,
        "cellmates_count": p.cellmates_count,
        "torture_description": p.torture_description,
        "sexual_violence_reported": p.sexual_violence_reported,
        "torture_method_ids": list(p.torture_methods.values_list("id", flat=True)),
    }


def serialize_release(r):
    return {
        "id": r.id,
        "survivor_id": r.survivor_id,
        "release_date": _date(r.release_date),
        "release_type": r.release_type,
        "release_type_display": r.get_release_type_display(),
        "release_location": r.release_location,
        "bribe_amount": r.bribe_amount,
        "conditions": r.conditions,
        "circumstances": r.circumstances,
    }


def serialize_consent(c):
    return {
        "id": c.id,
        "survivor_id": c.survivor_id,
        "consent_documented": c.consent_documented,
        "consent_date": _date(c.consent_date),
        "consent_witness": c.consent_witness,
        "share_with_iiim": c.share_with_iiim,
        "share_with_coi": c.share_with_coi,
        "share_with_icc": c.share_with_icc,
        "share_with_universal_jurisdiction": c.share_with_universal_jurisdiction,
        "share_with_partner_orgs": c.share_with_partner_orgs,
        "share_with_media": c.share_with_media,
        "share_publicly": c.share_publicly,
        "anonymize_name": c.anonymize_name,
        "anonymize_photo": c.anonymize_photo,
        "anonymize_location": c.anonymize_location,
        "anonymize_family_details": c.anonymize_family_details,
        "withdrawal_right_explained": c.withdrawal_right_explained,
        "confidentiality_limits_explained": c.confidentiality_limits_explained,
        "intended_uses_explained": c.intended_uses_explained,
        "consent_withdrawn": c.consent_withdrawn,
        "is_fully_compliant": c.is_fully_compliant,
    }


def serialize_note(n):
    return {
        "id": n.id,
        "survivor_id": n.survivor_id,
        "note_type": n.note_type,
        "title": n.title,
        "content": n.content,
        "is_pinned": n.is_pinned,
        "is_confidential": n.is_confidential,
        "author_username": n.author.username if n.author else None,
        "created_at": _dt(n.created_at),
    }

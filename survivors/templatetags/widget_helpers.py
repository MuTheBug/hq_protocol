"""Template tags لمساعدة الـtemplates في تحديد نوع الـwidget ديناميكياً."""

from django import forms, template

register = template.Library()


@register.filter
def widget_type(field):
    """يُرجع اسم نوع widget الحقل (Textarea, Select, CheckboxInput, ...)"""
    if not hasattr(field, "field"):
        return ""
    return field.field.widget.__class__.__name__


@register.filter
def is_textarea(field):
    """هل الحقل من نوع Textarea؟"""
    if not hasattr(field, "field"):
        return False
    return isinstance(field.field.widget, forms.Textarea)


@register.filter
def is_checkbox(field):
    """هل الحقل CheckBox؟"""
    if not hasattr(field, "field"):
        return False
    return isinstance(field.field.widget, forms.CheckboxInput)


@register.filter
def field_col(field):
    """يُرجع class عرض البوتستراب المناسب: 12 للحقول النصية الطويلة، 6 لبقية."""
    if not hasattr(field, "field"):
        return "col-md-6"
    widget = field.field.widget
    if isinstance(widget, forms.Textarea):
        return "col-md-12"
    if isinstance(widget, forms.CheckboxInput):
        return "col-md-6"
    return "col-md-6"

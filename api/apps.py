from django.apps import AppConfig


# To this:
class ApiConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'api'  # <-- Should only be 'api'
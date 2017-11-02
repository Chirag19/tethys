{%- set ACTIVATE_DIR = salt['environ.get']('ACTIVATE_DIR') -%}
{%- set DEACTIVATE_DIR = salt['environ.get']('DEACTIVATE_DIR') -%}
{%- set ACTIVATE_SCRIPT = salt['environ.get']('ACTIVATE_SCRIPT') -%}
{%- set DEACTIVATE_SCRIPT = salt['environ.get']('DEACTIVATE_SCRIPT') -%}
{%- set TETHYS_HOME = salt['environ.get']('TETHYS_HOME') -%}
{%- set TETHYS_DB_USERNAME = salt['environ.get']('TETHYS_DB_USERNAME') -%}
{%- set TETHYS_DB_PASSWORD = salt['environ.get']('TETHYS_DB_PASSWORD') -%}
{%- set TETHYS_DB_PORT = salt['environ.get']('TETHYS_DB_PORT') -%}
{%- set ALLOWED_HOST = salt['environ.get']('ALLOWED_HOST') -%}
{%- set TETHYSBUILD_PUBLIC_HOST = salt['environ.get']('TETHYSBUILD_PUBLIC_HOST') -%}
{%- set TETHYS_SUPER_USER = salt['environ.get']('TETHYS_SUPER_USER') -%}
{%- set TETHYS_SUPER_USER_PASS = salt['environ.get']('TETHYS_SUPER_USER_PASS') -%}
{%- set TETHYS_SUPER_USER_EMAIL = salt['environ.get']('TETHYS_SUPER_USER_EMAIL') -%}
{%- set BLERG = salt['environ.get']('BLERG') -%}
{%- set BLERG = salt['environ.get']('BLERG') -%}
{%- set BLERG = salt['environ.get']('BLERG') -%}
{%- set BLERG = salt['environ.get']('BLERG') -%}

ACTIVATE_DIR:
  file.directory:
    - name: {{ ACTIVATE_DIR }}
    - makedirs: True

DEACTIVATE_DIR:
  file.directory:
    - name: {{ DEACTIVATE_DIR }}
    - makedirs: True

~/.bashrc:
  file.append:
    - text: |
      # Tethys Platform
      alias t='. {{ CONDA_HOME }}/bin/activate {{ CONDA_ENV_NAME }}

ACTIVATE_SCRIPT:
  file.managed:
    - name: {{ ACTIVATE_SCRIPT }}
    - source: "salt://setup/files/activate.jinja"
    - template: jinja

DEACTIVATE_SCRIPT:
  file.managed:
    - name: {{ DEACTIVATE_SCRIPT }}
    - source: "salt://setup/files/deactivate.jinja"
    - template: jinja

Generate Tethys Settings:
  cmd.run:
    - name |
      tethys gen settings --production --allowed-host={{ ALLOWED_HOST }} --db-username {{ TETHYS_DB_USERNAME }} --db-password {{ TETHYS_DB_PASSWORD }} --db-port {{ TETHYS_DB_PORT }} --overwrite

Edit Tethys Settings File (HOST):
  file.replace:
    - name: {{ TETHYS_HOME }}/src/tethys_portal/settings.py
    - pattern: "'HOST': '127.0.0.1'"
    - repl: {{ TETHYSBUILD_DB_HOST }}

Edit Tethys Settings File (HOME_PAGE):
  file.replace:
    - name: {{ TETHYS_HOME }}/src/tethys_portal/settings.py
    - pattern: "BYPASS_TETHYS_HOME_PAGE = False"
    - repl: "BYPASS_TETHYS_HOME_PAGE = True"

Edit Tethys Settings File (SESSION_WARN):
  file.replace:
    - name: {{ TETHYS_HOME }}/src/tethys_portal/settings.py
    - pattern: "SESSION_SECURITY_WARN_AFTER = 840"
    - repl: "SESSION_SECURITY_WARN_AFTER = 25 * 60"

Edit Tethys Settings File (SESSION_EXPIRE):
  file.replace:
    - name: {{ TETHYS_HOME }}/src/tethys_portal/settings.py
    - pattern: "SESSION_SECURITY_EXPIRE_AFTER = 900"
    - repl: "SESSION_SECURITY_EXPIRE_AFTER = 30 * 60"

Edit Tethys Settings File (SESSION_EXPIRE):
  file.append:
    - name: {{ TETHYS_HOME }}/src/tethys_portal/settings.py
    - text: "PUBLIC_HOST = \"{{ TETHYSBUILD_PUBLIC_HOST }}\""

Generate NGINX Settings:
  cmd.run:
    - tethys gen nginx --overwrite

Generate uwsgi Settings:
  cmd.run:
    - tethys gen uwsgi_settings --overwrite

Generate uwsgi service:
  cmd.run:
    - tethys gen uwsgi_service --overwrite
  file.managed:
    - name: /var/log/uwsgi/tethys.log
    - makedirs: True

Prepare Database:
  postgres_user.present:
    - name: {{ TETHYS_DB_USERNAME }}
    - password: {{ TETHYS_DB_PASSWORD }}
    - login: True
  postgres_database.present:
    - name: {{ TETHYS_DB_USERNAME }}
  cmd.run:
    - name: tethys manage syncdb

Create Super User:
  cmd.run:
    - name: |
    echo "from django.contrib.auth.models import User; User.objects.create_superuser('{{ TETHYS_SUPER_USER }}', '{{ TETHYS_SUPER_USER_EMAIL }}', '{{ TETHYS_SUPER_USER_PASS }}')" | python manage.py shell
    - cwd: {{ TETHYS_HOME }}

Link NGINX Config:
  file.symlink:
    - name: /etc/nginx/sites-enabled
    - target: ${TETHYS_HOME}/src/tethys_portal/tethys_nginx.conf


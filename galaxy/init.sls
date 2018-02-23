{% from "galaxy/map.jinja" import galaxy with context %}

/etc/environment:
  file.append:
    - text:
      - galaxy_home={{ galaxy.home }}
      - galaxy_dir=$galaxy_home/galaxy

galaxy-create-user:
  user.present:
    - name: galaxy
    - fullname: galaxy user
    {% if galaxy.user.uid is defined -%}
    - uid: {{ galaxy.user.uid }}
    {% endif %}
    {% if galaxy.user.gid is defined -%}
    - gid: {{ galaxy.user.gid }}
    {% endif %}
    - shell: /bin/sh
    - home: {{ galaxy.home }}
  group.present:
    - name: galaxy
    - members:
      - galaxy

galaxy-pkg-dependencies:
  pkg.installed:
    - pkgs: {{ galaxy.system_packages }}

galaxy-download-extract:
  archive.extracted:
    - name: {{ galaxy.home }}
    - source: {{ galaxy.archive_url }}/v{{ galaxy.version }}.tar.gz
    - archive_format: tar
    - skip_verify: True
    - user: galaxy
    - group: galaxy
    - keep_source: True
    - listen_in:
      - service: galaxy-service

galaxy-app-symlink:
  file.symlink:
    - name: {{ galaxy.home }}/galaxy
    - target: {{ galaxy.home }}/galaxy-{{ galaxy.version }}
    - user: galaxy
    - group: galaxy
    - watch:
      - archive: galaxy-download-extract

galaxy-app-config:
  file.managed:
    - template: jinja
    - name: '{{ galaxy.home }}/galaxy/config/galaxy.ini'
    - source: salt://galaxy/templates/config-galaxy-ini.tmpl
    - user: galaxy
    - group: galaxy

galaxy-startup-pypi-index:
  file.replace:
    - name: '{{ galaxy.home }}/galaxy/scripts/common_startup.sh'
    - pattern: 'PYPI_INDEX_URL:="https://pypi.python.org/simple"'
    - repl: 'PYPI_INDEX_URL:="{{ galaxy.venv.index_url }}"'
    - backup: False
    - require:
      - archive: galaxy-download-extract

galaxy-pip-config:
    file.managed:
      - template: jinja
      - name: '{{ galaxy.home }}/.config/pip/pip.conf'
      - source: salt://galaxy/templates/config-pip-conf.tmpl
      - makedirs: True
      - user: galaxy
      - group: galaxy

galaxy-virtualenv:
  pkg.installed:
    - name: virtualenv
  virtualenv.managed:
    - name: '{{ galaxy.home }}/galaxy/.venv'
    - user: galaxy
    - requirements: {{ galaxy.home }}/galaxy/requirements.txt
    - pip_pkgs:
      - psycopg2
    - index_url: {{ galaxy.venv.index_url }}
    - extra_index_url: {{ galaxy.venv.extra_index_url }}
    {% if galaxy.venv.proxy is defined -%}
    - proxy: {{ galaxy.venv.proxy }}
    - env_vars:
        - HTTP_PROXY: {{ galaxy.venv.proxy }}
        - HTTPS_PROXY: {{ galaxy.venv.proxy }}
    {% endif %}

galaxy-auth-config:
  file.managed:
    - template: jinja
    - name: '{{ galaxy.home }}/galaxy/config/auth_conf.xml'
    - source: salt://galaxy/templates/config-auth-xml.tmpl
    - user: galaxy
    - group: galaxy

galaxy-tool-sheds-repo-config:
  file.managed:
    - template: jinja
    - name: '{{ galaxy.home }}/galaxy/config/tool_sheds_conf.xml'
    - source: salt://galaxy/templates/config-sheds-repo-xml.tmpl
    - user: galaxy
    - group: galaxy

{% if galaxy.customise_localtools == True -%}
galaxy-local-tools-config:
  file.managed:
    - template: jinja
    - name: '{{ galaxy.home }}/galaxy/config/tool_conf.xml'
    - source: salt://galaxy/templates/config-tool-local-xml.tmpl
    - user: galaxy
    - group: galaxy
{% endif %}

{% if galaxy.localtools.liftOver is defined -%}
galaxy-local-tools-liftover-fix:
  file.managed:
    - name: '{{ galaxy.home }}/galaxy/tool-data/liftOver.loc'
    - user: galaxy
    - group: galaxy
{% endif %}

{% if galaxy.home_page_source is defined -%}
galaxy-homepage-html:
  file.managed:
    - name: '{{ galaxy.home }}/galaxy/static/welcome.html'
    - source: '{{ galaxy.home_page_source }}'
    {% if galaxy.home_page_source_hash is defined -%}
    - source_hash: '{{ galaxy.home_page_source_hash }}'
    {% else %}
    - skip_verify: true
    {% endif %}
    - user: galaxy
    - group: galaxy
{% endif %}

{% if galaxy.jobs is defined and galaxy.jobs.enable == True -%}
galaxy-jobs-config:
  file.managed:
    - template: jinja
    - name: '{{ galaxy.home }}/galaxy/config/job_conf.xml'
    - source: salt://galaxy/templates/config-jobs-advanced-xml.tmpl
    - user: galaxy
    - group: galaxy
{% endif %}

galaxy-systemd-service:
  file.managed:
    - name: /etc/systemd/system/galaxy.service
    - source: salt://galaxy/templates/systemd-galaxy.tmpl
    - template: jinja
    - user: root
    - group: root
    - mode: 0644
    - require:
      - archive: galaxy-download-extract

galaxy-permissions:
  file.directory:
    - user: galaxy
    - group: galaxy
    - makedirs: True
    - recurse:
      - user
      - group
    - names:
      - {{ galaxy.home }}
      - {{ galaxy.log_dir }}
      - /var/run/galaxy

galaxy-service:
  service.running:
    - name: galaxy
    - enable: True
    - init_delay: 300
    - require:
      - archive: galaxy-download-extract
      - file: galaxy-app-config
      - file: galaxy-systemd-service
    - watch:
      - file: galaxy-app-symlink
      - file: galaxy-app-config
      - file: galaxy-auth-config
      - file: galaxy-tool-sheds-repo-config
      - file: galaxy-startup-pypi-index
      {% if galaxy.customise_localtools == True -%}
      - file: galaxy-local-tools-config
      {% endif %}
      {% if galaxy.jobs is defined and galaxy.jobs.enable == True -%}
      - file: galaxy-jobs-config
      {% endif %}

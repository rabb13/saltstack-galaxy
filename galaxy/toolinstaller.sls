{% from "galaxy/map.jinja" import galaxy with context %}

galaxy_tools_source_yaml:
  file.managed:
    - name: {{ galaxy.home }}/galaxy/tmp/install_tool_list.yaml
    - source: {{ galaxy.tool_installer.yaml_source }}
    {% if galaxy.tool_installer.yaml_source_hash is defined -%}
    - source_hash: {{ galaxy.tool_installer.yaml_source_hash }}
    {% else %}
    - skip_verify: True
    {% endif %}
    - makedirs: True
    - user: galaxy
    - group: galaxy

galaxy-ephemeris-shedtool-install:
  virtualenv.managed:
    - name: '{{ galaxy.home }}/galaxy/.venv-ephemeris'
    - user: galaxy
    - pip_pkgs:
      - ephemeris==0.8.0
      - bioblend==0.10.0
    - index_url: {{ galaxy.venv.index_url }}
    - extra_index_url: {{ galaxy.venv.extra_index_url }}
    {% if galaxy.tool_installer.force_run == False -%}
    - onchanges:
      - file: galaxy_tools_source_yaml
    {% endif %}

galaxy_tools_install_bootstrap_user:
  file.managed:
    - name: {{ galaxy.home }}/galaxy/tmp/manage_bootstrap_user.py
    - source: salt://galaxy/files/manage_bootstrap_user.py
    - makedirs: True
    - user: galaxy
  cmd.run:
    - cwd: {{ galaxy.home }}/galaxy
    - runas: galaxy
    - name: 'sleep 120 && ./.venv/bin/python tmp/manage_bootstrap_user.py -c config/galaxy.ini create -u "{{ galaxy.tool_installer.user_name }}" -e "{{ galaxy.tool_installer.user_email }}" -p "{{ galaxy.tool_installer.user_password }}" -a "{{ galaxy.tool_installer.api_key }}" > {{ galaxy.log_dir }}/toolinstaller.log'
    {% if galaxy.tool_installer.force_run == False -%}
    - onchanges:
      - file: galaxy_tools_source_yaml
    {% endif %}

galaxy_tools_install_run:
  cmd.run:
    - cwd: {{ galaxy.home }}/galaxy
    - runas: galaxy
    - name: './.venv-ephemeris/bin/shed-tools install -t tmp/install_tool_list.yaml -a "{{ galaxy.tool_installer.api_key }}" -g  "{{ galaxy.tool_installer.galaxy_instance }}" >> {{ galaxy.log_dir }}/toolinstaller.log'
    - require:
      - file: galaxy_tools_install_bootstrap_user
    {% if galaxy.tool_installer.force_run == False -%}
    - onchanges:
      - file: galaxy_tools_source_yaml
    {% endif %}

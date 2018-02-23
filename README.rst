
Galaxy
===============
Galaxy formula
===============

This formula is for deploying galaxy from git https://galaxyproject.org/admin/.

.. note::

    See the full `Salt Formulas installation and usage instructions
    <http://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html>`_.

Available states
================


``galaxy``
-----------------

Installs Galaxy.


``galaxy.toolinstaller``
-----------------
Install tools automatically as part of the installation.


Original Configuration samples
=====================
For full list of config option please check sample files config folder or in galaxy project in github- [galaxy.ini.sample](https://github.com/galaxyproject/galaxy/blob/dev/config/) .

Application: galaxy.ini.sample
Authentication: auth_conf.xml.sample
Local tools: tool_conf.xml.sample
Tool sheds: tool_sheds_conf.xml.sample
Shed tools: shed_tool_conf.xml
Jobs (cluster): job_conf.xml


For production use and customisation, see pillar.example

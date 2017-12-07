Specifications
==============

File: project.yml
-----------------

.. list-table:: Top level definitions for project.yml file
   :widths: 15, 15, 120
   :header-rows: 1

   * - Key
     - Value
     - Description
   * - command
     - *string*
     - Command which is executed for container. See Docker's CMD entry
   * - volumes
     - *list*
     - Volumes to mount from host Command which is executed for container. See Docker's CMD entry
   * - volumes
     - *list*
     - Volumes to mount from host to container e.g. html:/usr/share/nginx/html:ro
   * - files
     - *list*
     - Files to copy from host or created with given contents on the fly
   * - dirs
     - *list*
     - Directories to create on the fly when container is started


File: environment.yml
---------------------

.. list-table:: Top level definitions for environment.yml file
   :widths: 15, 15, 120
   :header-rows: 1

   * - Key
     - Value
     - Description
   * - type
     - environment | *string*
     - Describes what kind of definition file is this
   * - name
     - *string*
     - Informative purposes only. Used on graphical user interfaces in the future
   * - desc 
     - *string*
     - Informative purposes only. Describe your environment.
   * - *folder/path*
     - *string*
     - Key is folder path to project and value defines project configuration. Identical to *project.yml* definitions. Values here override *project.yml* definitions.


File: $HOME/.platform/config.yml
--------------------------------

.. list-table:: Top level definitions for config.yml file
   :widths: 15, 15, 120
   :header-rows: 1

   * - Key
     - Value
     - Description
   * - packages
     - *string*
     - List of package names to be installed after project is started.

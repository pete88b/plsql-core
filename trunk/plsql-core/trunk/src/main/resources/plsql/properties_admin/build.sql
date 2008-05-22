/*
  Build script for properties admin.

  Depends on: constants.
  Depends on: logger.
  Depends on: messages.
  Depends on: types.
*/

PROMPT ___ Start of properties admin build.sql ___

PROMPT Creating property_value package specification
@@property_value.spc

PROMPT Creating property_group package specification
@@property_group.spc

PROMPT Creating property_groups package specification
@@property_groups.spc


PROMPT Creating property_value package body
@@property_value.bdy

PROMPT Creating property_group package body
@@property_group.bdy

PROMPT Creating property_groups package body
@@property_groups.bdy


PROMPT ___ End of properties adin build.sql ___
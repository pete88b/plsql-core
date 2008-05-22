
PROMPT ___ Start of collections build.sql ___

PROMPT Creating collection types
CREATE OR REPLACE TYPE varchar_table IS TABLE OF VARCHAR2(4000);
/

CREATE OR REPLACE TYPE number_table IS TABLE OF NUMBER;
/

PROMPT Creating collections specification
@@collections.pck

PROMPT ___ End of collections build.sql ___
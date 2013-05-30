/**
 * Copyright (C) 2008 Peter Butterfill.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
  Build script for user messages.
*/

PROMPT ___ Start of user_messages build.sql ___

PROMPT Creating sequence message_log_id

CREATE SEQUENCE user_message_id
MINVALUE 0
MAXVALUE 99999999999999999999999999
START WITH 0
INCREMENT BY 1
CACHE 10
CYCLE
ORDER;

PROMPT Creating table user_message_temp

CREATE GLOBAL TEMPORARY TABLE user_message_temp (
  message_id INTEGER,
  message_level INTEGER,
  message_detail VARCHAR2(4000)
)
ON COMMIT PRESERVE ROWS;

/*
PROMPT Creating table user_message_temp

CREATE GLOBAL TEMPORARY TABLE user_message_temp (
  message_id INTEGER,
  message_level INTEGER,
  message_summary VARCHAR2(2000),
  message_detail VARCHAR2(4000)
)
ON COMMIT PRESERVE ROWS;

PROMPT Creating table user_message_argument_temp

CREATE GLOBAL TEMPORARY TABLE user_message_argument_temp (
  message_id INTEGER,
  argument_order INTEGER,
  argument_text VARCHAR2(4000)
)
ON COMMIT PRESERVE ROWS;
*/

@@user_messages.spc
@@user_messages.bdy

PROMPT ___ End of user_messages build.sql ___
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
  Build script for properties admin.
*/

PROMPT ___ Start of properties admin build.sql ___

PROMPT Creating property_group package specification
@@property_group.spc

PROMPT Creating property_group package body
@@property_group.bdy


PROMPT Creating property_key package specification
@@property_key.spc

PROMPT Creating property_key package body
@@property_key.bdy


PROMPT Creating property_value package specification
@@property_value.spc

PROMPT Creating property_value package body
@@property_value.bdy


PROMPT ___ End of properties admin build.sql ___

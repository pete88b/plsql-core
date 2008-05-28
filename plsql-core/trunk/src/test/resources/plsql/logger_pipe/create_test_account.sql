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


-- XE run as SYS
drop user logger_test cascade;

create user logger_test
  identified by star01
  default tablespace USERS
  temporary tablespace TEMP
  profile DEFAULT;
 
grant dba to logger_test;

grant select any dictionary to logger_test;
grant execute on dbms_lock to logger_test;
grant execute on dbms_pipe to logger_test;

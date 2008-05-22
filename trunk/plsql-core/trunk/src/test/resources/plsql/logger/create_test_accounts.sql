/*
  Creates accounts needed by logger test scripts.
*/
-- c3adev run as DBA
sqlplus /

drop user logger_test cascade;
 
create user logger_test
  identified by star01
  default tablespace CT_USERS
  temporary tablespace USERTEMP
  profile DEFAULT;

grant dba to logger_test;
grant execute any procedure to logger_test;
grant select any table to logger_test;


drop user logger_test2 cascade;
 
create user logger_test2
  identified by star01
  default tablespace CT_USERS
  temporary tablespace USERTEMP
  profile DEFAULT;

grant dba to logger_test2;
grant execute any procedure to logger_test2;



-- XE run as SYS
drop user logger_test cascade;

create user logger_test
  identified by star01
  default tablespace USERS
  temporary tablespace TEMP
  profile DEFAULT;
 
grant dba to logger_test;
grant select any dictionary to logger_test;
grant execute any procedure to logger_test;
grant execute on dbms_lock to logger_test;
grant execute on dbms_pipe to logger_test;


drop user logger_test2 cascade;

create user logger_test2
  identified by star01
  default tablespace USERS
  temporary tablespace TEMP
  profile DEFAULT;
 
grant dba to logger_test2;
grant execute any procedure to logger_test2;

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
  Tests for logger_utils. 
*/
declare

  l_first_pre_log_proces_call date;

  procedure assert(
    p_condition in boolean,
    p_message in varchar2
  )
  is
  begin
    if (not p_condition or p_condition is null)
    then
      raise_application_error(
        -20000, p_message);
    end if;
  end;
  
  procedure init
  is
  begin 
    execute immediate 'truncate table logger_flags';
    logger_utils.set_user(USER);
    logger.set_feedback_level(logger.g_default_feedback_level);
    
    assert(
      logger.get_feedback_level = logger.g_default_feedback_level,
      'init failed: expected feedback level ' || logger.g_default_feedback_level || 
      ' found ' || logger.get_feedback_level);
      
    assert(
      logger_utils.get_user = USER,
      'init failed: expected user ' || USER || ' found ' || logger_utils.get_user);
      
  end;
  
begin
  -- start of get_user tests
  assert(
    logger_utils.get_user = USER,
    'check default get_user failed: expected user ' || USER || ' found ' || logger_utils.get_user);
  
  init;
  
  logger_utils.set_user(null);
  assert(
    logger_utils.get_user is null,
    'expected user NULL found ' || logger_utils.get_user);
    
  logger_utils.set_user(rpad('a', 32000, 'b'));
  assert(
    logger_utils.get_user = rpad('a', 32000, 'b'),
    'check default get_user failed: expected user rpad(''a'', 32000, ''b'') found ' || logger_utils.get_user);
  
  -- end  of get_user tests
  
  -- start of set_user tests
  init;
  
  logger.set_feedback_level(-8);
  logger_utils.set_user(null);
  
  assert(
    logger.get_feedback_level = logger.g_default_feedback_level,
    'expected feedback level ' || logger.g_default_feedback_level || 
    ' found ' || logger.get_feedback_level);
    
  assert(
    logger_utils.get_user is null,
    'expected user NULL found ' || logger_utils.get_user);
  
  logger_utils.pre_log_process;
  
  insert into logger_flags(
    log_user, log_level)
  values(
    'PUBLIC', -9);
  
  assert(
    logger.get_feedback_level = logger.g_default_feedback_level,
    'expected feedback level ' || logger.g_default_feedback_level || 
    ' found ' || logger.get_feedback_level);
  
  -- show that user switch causes flags to be checked (without waiting for a minute)
  logger_utils.set_user('a');
  
  logger_utils.pre_log_process;
  
  assert(
    logger.get_feedback_level = -9,
    'expected feedback level -9 found ' || logger.get_feedback_level);
    
  rollback;
  
  -- end of set_user tests
  
  -- start of pre_log_process tests
  init;
  
  logger_utils.pre_log_process;
  l_first_pre_log_proces_call := sysdate;
  
  assert(
    logger.get_feedback_level = logger.g_default_feedback_level,
    'expected feedback level ' || logger.g_default_feedback_level || ' found ' || logger.get_feedback_level);
    
  insert into logger_flags(
    log_user, log_level)
  values(
    'PUBLIC', -9);
  
  -- make sure flags are not check within 58 seconds of making the first pre log process call
  while (sysdate < (l_first_pre_log_proces_call + (1/24/60) - (1/24/60/60) - (1/24/60/60)))
  loop
    assert(
      logger.get_feedback_level = logger.g_default_feedback_level,
      'expected feedback level ' || logger.g_default_feedback_level || ' found ' || logger.get_feedback_level);
    logger_utils.pre_log_process;
  end loop;
  
  -- we need to wait the full minute before flags will be checked
  while (sysdate <= (l_first_pre_log_proces_call + (1/24/60)))
  loop
    logger_utils.pre_log_process;
  end loop;
  
  logger_utils.pre_log_process;
  
  assert(
    logger.get_feedback_level = -9,
    'expected feedback level -9 found ' || logger.get_feedback_level);
    
  rollback;
  
  -- end of pre_log_process tests
  
end;

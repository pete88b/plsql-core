CREATE OR REPLACE PACKAGE BODY user_messages
IS

  /*
    This package body provides the "default" implementation.
    Messages are saved in a temp table that can be retrieved via the get_messages function.
  */

  PROCEDURE add_debug_message(
    p_message IN VARCHAR2,
    p_arguments IN types.varchar_table := types.new_varchar_table
  )
  IS
  BEGIN
    add_message(3, p_message, p_arguments);
  END;

  PROCEDURE add_info_message(
    p_message IN VARCHAR2,
    p_arguments IN types.varchar_table := types.new_varchar_table
  )
  IS
  BEGIN
    add_message(200, p_message, p_arguments);
  END;

  PROCEDURE add_warn_message(
    p_message IN VARCHAR2,
    p_arguments IN types.varchar_table := types.new_varchar_table
  )
  IS
  BEGIN
    add_message(500, p_message, p_arguments);
  END;

  PROCEDURE add_error_message(
    p_message IN VARCHAR2,
    p_arguments IN types.varchar_table := types.new_varchar_table
  )
  IS
  BEGIN
    add_message(6000, p_message, p_arguments);
  END;

  /*
    Saves the message in user_message_temp after replacing placeholders with arguments.
  */
  PROCEDURE add_message(
    p_level IN INTEGER,
    p_message IN VARCHAR2,
    p_arguments IN types.varchar_table := types.new_varchar_table
  )
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    l_message VARCHAR2(32767) := p_message;
    l_argument_index INTEGER := p_arguments.FIRST;

  BEGIN
    WHILE (l_argument_index IS NOT NULL)
    LOOP
      <<try_replace_argument>>
      BEGIN
        l_message := REPLACE(
                       l_message,
                       '{' || l_argument_index || '}',
                       p_arguments(l_argument_index));

      EXCEPTION
        WHEN OTHERS
        THEN
          -- if we can't replace a placeholder, just log the error 
          -- and leave the placeholder un-replaced
          logger.error(
            'failed to replace argument ' || l_argument_index || ' in message ' || l_message);

      END try_replace_argument;

      l_argument_index := p_arguments.NEXT(l_argument_index);

    END LOOP;

    IF (LENGTH(l_message) > 4000)
    THEN
      -- if a message is too long to save in the user_message_temp, log an error
      logger.error('message is too long to store. ' || l_message);
      -- and truncate the message
      l_message := SUBSTR(l_message, 1, 3996) || ' ...';

    END IF;

    INSERT INTO user_message_temp(
      message_id, message_level, message_detail)
    VALUES (
      user_message_id.NEXTVAL, p_level, l_message);

    COMMIT;

  END;

  /*
    Adds the specified argument at the specified index.
  */
  FUNCTION add_argument(
    p_argument_index IN INTEGER,
    p_argument IN VARCHAR2,
    p_arguments IN types.varchar_table := types.new_varchar_table
  )
  RETURN types.varchar_table
  IS
    l_arguments types.varchar_table := p_arguments;

  BEGIN
    l_arguments(p_argument_index) := p_argument;
    RETURN l_arguments;

  END;

  /*
    Converts the specified argument to varchar2 and then adds it at the specified index.
  */
  FUNCTION add_argument(
    p_argument_index IN INTEGER,
    p_argument IN DATE,
    p_arguments IN types.varchar_table := types.new_varchar_table
  )
  RETURN types.varchar_table
  IS
  BEGIN
    RETURN add_argument(
             p_argument_index,
             TO_CHAR(p_argument, 'dd-Mon-yyyy hh24:mi:ss'),
             p_arguments);

  END;

  /*
    Converts the specified argument to varchar2 and then adds it at the specified index.
  */
  FUNCTION add_argument(
    p_argument_index IN INTEGER,
    p_argument IN BOOLEAN,
    p_arguments IN types.varchar_table := types.new_varchar_table
  )
  RETURN types.varchar_table
  IS
    l_argument VARCHAR2(4000);

  BEGIN
    IF (p_argument)
    THEN
      l_argument := 'TRUE';

    ELSIF (NOT p_argument)
    THEN
      l_argument := 'FALSE';

    END IF;

    RETURN add_argument(p_argument_index, l_argument, p_arguments);

  END;

  /*
    Clears all messages for this session.
  */
  PROCEDURE clear_messages
  IS
  BEGIN
    EXECUTE IMMEDIATE 'TRUNCATE TABLE user_message_temp';

  END;

  /*
    Returns all messages saved for this session.
  */
  FUNCTION get_messages(
    p_locale IN VARCHAR2 := NULL
  )
  RETURN SYS_REFCURSOR
  IS
    l_result SYS_REFCURSOR;
    
  BEGIN
    OPEN l_result FOR
    SELECT
      *
    FROM
      user_message_temp
    ORDER BY
      message_id;

    RETURN l_result;

  END;

END user_messages;
/

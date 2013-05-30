CREATE OR REPLACE PACKAGE BODY user_messages
IS

  /*
    This package provides an implementation that sends messages to the event mediator.
    Using this implementation, anyone interested in receiving messages can register as an observer
    of the 'user_message' event.
    The observer must provide a procedure with the following signature;
      PROCEDURE add_message(p_level IN INTEGER, p_message IN VARCHAR2)
  */

  PROCEDURE add_message(
    p_level IN INTEGER,
    p_message IN VARCHAR2,
    p_arguments IN types.varchar_table := types.new_varchar_table
  )
  IS
    l_message VARCHAR2(32767) := p_message;
    l_argument_index INTEGER := p_arguments.FIRST;

  BEGIN
    WHILE (l_argument_index IS NOT NULL)
    LOOP
      l_message := REPLACE(
                     l_message,
                     '{' || l_argument_index || '}',
                     p_arguments(l_argument_index));

      l_argument_index := p_arguments.NEXT(l_argument_index);

    END LOOP;

    event_mediator.event(
      'user_message',
      'add_message(' || p_level || ', ''' || REPLACE(l_message, '''', '''''') || ''')');

  END;

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

  PROCEDURE clear_messages
  IS
  BEGIN
    EXECUTE IMMEDIATE 'TRUNCATE TABLE user_message_temp';

  END;

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

CREATE OR REPLACE PACKAGE user_messages
IS

  /*
    This package defines a standard interface for sending messages to users from PL/SQL.

    You can create messages either with or without arguments;

      begin
        user_messages.add_info_message(
          'about to do some work');

        user_messages.add_info_message(
          'doing some work with {1} and {2}',
          user_messages.add_argument(1, 'this',
          user_messages.add_argument(2, 'that')));

      end;

    The above example, would create 2 messages; 
      about to do some work
      doing some work with this and that

    For all of the add message procedures;

      p_message
        Is the message string that can contain any number of placeholders.
        Placeholders are an integer enclosed in curly brackets.

      p_arguments
        Is a collection of arguments that can be used to replace placeholders in p_message.
        The index of an element in p_arguments should match the number of a placeholder -
        no error will be raised if;
          the placeholder does not exist for an argument index or
          there is a placeholder but no corresponding index in p_arguments.

      p_level
        Is an integer to make sorting/filtering messages by level easy.
        The higher the number, the more important the message is.
        You're free to use any level you want but it is expected that the
        add_[debug|info|warn|error]_message procedures will cover most requirements.

        The following integer values are used (to match the levels used by the logger package).

        Level Integer value
        ----- -------------
        DEBUG 3
        INFO  200
        WARN  500
        ERROR 6000

    For all of the add argument procedures;
      p_argument_index
        Must not be NULL.
        Used to create an index in p_arguments.

      p_argument
        The argument value.

      p_arguments
        If p_arguments is not specified, a new collection is created and returned.
        If p_arguments is specified, the specified collection is updated and returned.

  */

  /*opb-package
    field
      name=locale;
  */

  /*
    Adds a message at the specified level.
  */
  PROCEDURE add_message(
    p_level IN INTEGER,
    p_message IN VARCHAR2,
    p_arguments IN types.varchar_table := types.new_varchar_table
  );

  /*
    Adds a message at DEBUG level.
  */
  PROCEDURE add_debug_message(
    p_message IN VARCHAR2,
    p_arguments IN types.varchar_table := types.new_varchar_table
  );

  /*
    Adds a message at INFO level.
  */
  PROCEDURE add_info_message(
    p_message IN VARCHAR2,
    p_arguments IN types.varchar_table := types.new_varchar_table
  );

  /*
    Adds a message at WARN level.
  */
  PROCEDURE add_warn_message(
    p_message IN VARCHAR2,
    p_arguments IN types.varchar_table := types.new_varchar_table
  );

  /*
    Adds a message at ERROR level.
  */
  PROCEDURE add_error_message(
    p_message IN VARCHAR2,
    p_arguments IN types.varchar_table := types.new_varchar_table
  );

  /*
    Adds a varchar argument at the specified index.
  */
  FUNCTION add_argument(
    p_argument_index IN INTEGER,
    p_argument IN VARCHAR2,
    p_arguments IN types.varchar_table := types.new_varchar_table
  )
  RETURN types.varchar_table;

  /*
    Adds a date argument at the specified index.
  */
  FUNCTION add_argument(
    p_argument_index IN INTEGER,
    p_argument IN DATE,
    p_arguments IN types.varchar_table := types.new_varchar_table
  )
  RETURN types.varchar_table;

  /*
    Adds a boolean argument at the specified index.
  */
  FUNCTION add_argument(
    p_argument_index IN INTEGER,
    p_argument IN BOOLEAN,
    p_arguments IN types.varchar_table := types.new_varchar_table
  )
  RETURN types.varchar_table;

  /*
    Clears all messages for the current session.
  */
  PROCEDURE clear_messages;

  /*
    Returns messages added since the last clear_messages call for this session.

    p_locale
      A locale in [language]_[country] format. e.g. "en" or "en_GB".
  */
  /*opb
    param
      name=p_locale
      field=locale;

    param
      name=RETURN
      use_result_cache=N;
  */
  FUNCTION get_messages(
    p_locale IN VARCHAR2 := NULL
  )
  RETURN SYS_REFCURSOR;

END user_messages;
/

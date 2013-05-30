CREATE OR REPLACE PACKAGE property_key
IS

  /*
    Represents a single property key.
  */


  /*opb-package
    field
      name=key_id
      datatype=INTEGER
      id=Y;

    field
      name=key_description
      datatype=VARCHAR2;

    field
      name=single_value_per_key
      datatype=VARCHAR2
      initial_value=Y;

    field
      name=group_id
      datatype=INTEGER;

    field
      name=key
      datatype=VARCHAR2;


    field
      name=value
      datatype=VARCHAR2
      in_load=ignored;

  */


  /*
    Deletes a Property Key by primary key.

    Parameters:
      p_key_id
        ID of the key to delete.
  */
  /*opb
    param
      name=p_key_id
      field=key_id;

    clear_cached
      name=this;
  */
  PROCEDURE del(
    p_key_id IN INTEGER);


  /*
    Creates a Property Key returning it's new primary key value.

    Parameters:
      p_key_id
        ID of the key created.

      p_key_description
        The description of the key.

      p_single_value_per_key
        Pass 'N' to allow this key to have multiple values.
        Pass 'Y' to create a key that can have one value at most.

      p_group_id
        ID of the group to which the key will belong.

      p_key
        The name of the key to create.
        This must not be NULL.

  */
  /*opb
    param
      name=p_key_id
      field=key_id;

    param
      name=p_key_description
      field=key_description;

    param
      name=p_single_value_per_key
      field=single_value_per_key;

    param
      name=p_group_id
      field=group_id;

    param
      name=p_key
      field=key;

    invalidate_cached
      name=this;
  */
  PROCEDURE ins(
    p_key_id OUT INTEGER,
    p_key_description IN VARCHAR2,
    p_single_value_per_key IN VARCHAR2,
    p_group_id IN INTEGER,
    p_key IN VARCHAR2);


  /*
    Updates a Property Key by primary key.

    Parameters:
      p_key_id
        ID of the key to update.

      p_key_description
        The new description for the key.

      p_single_value_per_key
        Pass 'N' to allow this key to have multiple values.
        Pass 'Y' to restrict this key to having one value at most.

      p_old_single_value_per_key
        The old value for single_value_per_key.

      p_group_id
        ID of the group to which the key should belong.

      p_key
        The new name for this key.

      p_old_key
        The old name for this key.

  */
  /*opb
    param
      name=p_key_id
      field=key_id;

    param
      name=p_key_description
      field=key_description;

    param
      name=p_single_value_per_key
      field=single_value_per_key;

    param
      name=p_old_single_value_per_key
      field=single_value_per_key_data_source_value;

    param
      name=p_group_id
      field=group_id;

    param
      name=p_key
      field=key;

    param
      name=p_old_key
      field=key_data_source_value;

    invalidate_cached
      name=this;

    invalidate_cached
      name=property_value;
  */
  PROCEDURE upd(
    p_key_id IN INTEGER,
    p_key_description IN VARCHAR2,
    p_single_value_per_key IN VARCHAR2,
    p_old_single_value_per_key IN VARCHAR2,
    p_group_id IN INTEGER,
    p_key IN VARCHAR2,
    p_old_key IN VARCHAR2);


  /*
    Returns all keys of this group.

    If the specified key does not exist, no values will be returned.

    Parameters:
      p_key_id
        ID of the key who's values should be returned.

      p_value
        Filter parameter.
  */
  /*opb
    param
      name=p_key_id
      field=key_id;

    param
      name=p_value
      field=value;

    param
      name=RETURN
      datatype=cursor?property_value;
  */
  FUNCTION get_values(
    p_key_id IN INTEGER,
    p_value IN VARCHAR2
  )
  RETURN SYS_REFCURSOR;


END property_key;
/
CREATE OR REPLACE PACKAGE property_value
IS

  /*
    Represents a single property value.
  */


  /*opb-package
    field
      name=value_id
      datatype=INTEGER
      id=Y;

    field
      name=sort_order
      datatype=INTEGER;

    field
      name=value
      datatype=VARCHAR2;

    field
      name=single_value_per_key
      datatype=VARCHAR2;

    field
      name=key_id
      datatype=INTEGER;

  */


  /*
    Deletes a Property Value by primary key.

    Parameters:
      p_value_id
        ID of the value to delete.
  */
  /*opb
    param
      name=p_value_id
      field=value_id;

    clear_cached
      name=this;
  */
  PROCEDURE del(
    p_value_id IN INTEGER);


  /*
    Creates a Property Value returning it's new primary key value.

    Parameters:
      p_value_id
        ID of the value created.

      p_sort_order
        The sort order for this key.
        Sort orders are used to order multiple values associated with
        a single key.

      p_value
        The value of this property.

      p_key_id
        ID of the key with which this value is associated.
  */
  /*opb
    param
      name=p_value_id
      field=value_id;

    param
      name=p_sort_order
      field=sort_order;

    param
      name=p_value
      field=value;

    param
      name=p_key_id
      field=key_id;

    invalidate_cached
      name=this;
  */
  PROCEDURE ins(
    p_value_id OUT INTEGER,
    p_sort_order IN INTEGER,
    p_value IN VARCHAR2,
    p_key_id IN INTEGER);


  /*
    Updates a Property Value by primary key.

    Parameters:
      p_value_id
        ID of the value to update.

      p_sort_order
        The new sort order for this key.

      p_value
        The new value of this property.

      p_key_id
        ID of the key with which this value should be associated.
  */
  /*opb
    param
      name=p_value_id
      field=value_id;

    param
      name=p_sort_order
      field=sort_order;

    param
      name=p_value
      field=value;

    param
      name=p_key_id
      field=key_id;

    invalidate_cached
      name=this;
  */
  PROCEDURE upd(
    p_value_id IN INTEGER,
    p_sort_order IN INTEGER,
    p_value IN VARCHAR2,
    p_key_id IN INTEGER);


END property_value;
/
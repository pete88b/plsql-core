CREATE OR REPLACE PACKAGE value_groups
AS

  /*opb-package
    field
      name=description
      datatype=VARCHAR2;

    field
      name=group_name
      datatype=VARCHAR2;

  */

  /*
  Define SYS_REFCURSOR so this package can be used in pre-10g databases.
  */
  TYPE SYS_REFCURSOR IS REF CURSOR;
  

  /*opb
    param
      name=p_description
      field=description;

    param
      name=p_group_name
      field=group_name;

    param
      name=RETURN
      datatype=cursor?value_group;
  */
  FUNCTION get_filtered(
    p_description IN VARCHAR2,
    p_group_name IN VARCHAR2
  )
  RETURN SYS_REFCURSOR;

END value_groups;
/

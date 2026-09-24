CLASS zcl_inct_catalog_327 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.

CLASS zcl_inct_catalog_327 IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.

    DATA lt_status TYPE STANDARD TABLE OF zdt_status_327
                   WITH EMPTY KEY.
    DATA lt_priority TYPE STANDARD TABLE OF zdt_priority_327
                     WITH EMPTY KEY.

    lt_status = VALUE #(
      ( status_code = 'OP' status_description = 'Open' )
      ( status_code = 'IP' status_description = 'In Progress' )
      ( status_code = 'PE' status_description = 'Pending' )
      ( status_code = 'CO' status_description = 'Completed' )
      ( status_code = 'CL' status_description = 'Closed' )
      ( status_code = 'CN' status_description = 'Canceled' )
    ).

    lt_priority = VALUE #(
      ( priority_code = 'H' priority_description = 'High' )
      ( priority_code = 'M' priority_description = 'Medium' )
      ( priority_code = 'L' priority_description = 'Low' )
    ).

    MODIFY zdt_status_327 FROM TABLE @lt_status.
    DATA(lv_status_rows) = sy-dbcnt.

    MODIFY zdt_priority_327 FROM TABLE @lt_priority.
    DATA(lv_priority_rows) = sy-dbcnt.

    COMMIT WORK.

    out->write( |Estados procesados: { lv_status_rows }| ).
    out->write( |Prioridades procesadas: { lv_priority_rows }| ).

  ENDMETHOD.
ENDCLASS.

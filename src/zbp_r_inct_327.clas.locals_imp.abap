CLASS lhc_incident DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

METHODS setInitialValues FOR DETERMINE ON MODIFY
  IMPORTING keys FOR Incident~setInitialValues.

ENDCLASS.

CLASS lhc_incident IMPLEMENTATION.

  METHOD setInitialValues.
    DATA(lv_today) = cl_abap_context_info=>get_system_date( ).

  MODIFY ENTITIES OF ZR_INCT_327 IN LOCAL MODE
    ENTITY Incident
      UPDATE FIELDS ( Status CreationDate ChangedDate )
      WITH VALUE #(
        FOR key IN keys
        ( %tky         = key-%tky
          Status       = 'OP'
          CreationDate = lv_today
          ChangedDate  = lv_today )
      ).
  ENDMETHOD.

ENDCLASS.

*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations


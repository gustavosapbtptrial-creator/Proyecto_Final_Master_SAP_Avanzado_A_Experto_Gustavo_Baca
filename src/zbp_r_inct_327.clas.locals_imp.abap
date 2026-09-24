CLASS lhc_incident DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

METHODS setInitialValues FOR DETERMINE ON MODIFY
  IMPORTING keys FOR Incident~setInitialValues.
METHODS get_instance_features FOR INSTANCE FEATURES
  keys REQUEST requested_features FOR Incident RESULT result.

METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
  keys REQUEST requested_authorizations FOR Incident RESULT result.

METHODS changeStatus FOR MODIFY
  keys FOR ACTION Incident~changeStatus RESULT result.

ENDCLASS.

CLASS lhc_incident IMPLEMENTATION.

METHOD setInitialValues.

  DATA(lv_today) = cl_abap_context_info=>get_system_date( ).

  SELECT MAX( incident_id )
    FROM zdt_inct_327
    INTO @DATA(lv_last_id).

  DATA(lv_next_id) = CONV i( lv_last_id ).

  DATA lt_updates TYPE TABLE FOR UPDATE ZR_INCT_327.

  LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
    lv_next_id += 1.

    APPEND VALUE #(
      %tky         = <key>-%tky
      IncidentId   = CONV #( lv_next_id )
      Status       = 'OP'
      CreationDate = lv_today
      ChangedDate  = lv_today
    ) TO lt_updates.
  ENDLOOP.

  MODIFY ENTITIES OF ZR_INCT_327 IN LOCAL MODE
    ENTITY Incident
      UPDATE FIELDS ( IncidentId Status CreationDate ChangedDate )
      WITH lt_updates.

ENDMETHOD.

  METHOD get_instance_features.
  ENDMETHOD.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD changeStatus.
  ENDMETHOD.

ENDCLASS.

*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations


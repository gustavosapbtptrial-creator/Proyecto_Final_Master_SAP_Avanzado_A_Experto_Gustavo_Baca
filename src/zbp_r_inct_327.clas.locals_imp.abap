CLASS lhc_incident DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

METHODS setInitialValues FOR DETERMINE ON MODIFY
  IMPORTING keys FOR Incident~setInitialValues.
METHODS get_instance_features FOR INSTANCE FEATURES
  IMPORTING keys REQUEST requested_features FOR Incident RESULT result.

METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
  IMPORTING keys REQUEST requested_authorizations FOR Incident RESULT result.

METHODS changeStatus FOR MODIFY
  IMPORTING keys FOR ACTION Incident~changeStatus RESULT result.

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

  READ ENTITIES OF ZR_INCT_327 IN LOCAL MODE
    ENTITY Incident
      FIELDS ( IncUuid Status )
      WITH CORRESPONDING #( keys )
    RESULT DATA(lt_incidents)
    FAILED failed.

  LOOP AT lt_incidents ASSIGNING FIELD-SYMBOL(<incident>).

    "Un borrador nuevo todavía no tiene registro activo.
    SELECT SINGLE inc_uuid
      FROM zdt_inct_327
      WHERE inc_uuid = @<incident>-IncUuid
      INTO @DATA(lv_existing_uuid).

    DATA(lv_exists) = xsdbool( sy-subrc = 0 ).

    APPEND VALUE #(
      %tky = <incident>-%tky
      %action-changeStatus = COND #(
        WHEN lv_exists = abap_true
         AND <incident>-Status <> 'CN'
         AND <incident>-Status <> 'CO'
         AND <incident>-Status <> 'CL'
        THEN if_abap_behv=>fc-o-enabled
        ELSE if_abap_behv=>fc-o-disabled )
    ) TO result.

  ENDLOOP.

ENDMETHOD.

METHOD get_instance_authorizations.

  DATA(lv_user) = cl_abap_context_info=>get_user_technical_name( ).

  READ ENTITIES OF ZR_INCT_327 IN LOCAL MODE
    ENTITY Incident
      FIELDS ( Responsible )
      WITH CORRESPONDING #( keys )
    RESULT DATA(lt_incidents)
    FAILED failed.

  LOOP AT lt_incidents ASSIGNING FIELD-SYMBOL(<incident>).

    DATA(lv_can_update) = xsdbool(
      lv_user = 'CB9980001327'
      OR lv_user = <incident>-Responsible ).

    APPEND VALUE #( %tky = <incident>-%tky )
      TO result ASSIGNING FIELD-SYMBOL(<authorization>).

IF requested_authorizations-%update = if_abap_behv=>mk-on
   OR requested_authorizations-%action-Edit = if_abap_behv=>mk-on.

      <authorization>-%update = COND #(
        WHEN lv_can_update = abap_true
        THEN if_abap_behv=>auth-allowed
        ELSE if_abap_behv=>auth-unauthorized ).

    ENDIF.

    IF requested_authorizations-%delete = if_abap_behv=>mk-on.
      <authorization>-%delete = if_abap_behv=>auth-allowed.
    ENDIF.

  ENDLOOP.

ENDMETHOD.

  METHOD changeStatus.
  ENDMETHOD.

ENDCLASS.

*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations


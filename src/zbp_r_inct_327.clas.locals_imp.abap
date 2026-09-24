CLASS lsc_zr_inct_327 DEFINITION INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

ENDCLASS.

CLASS lsc_zr_inct_327 IMPLEMENTATION.

METHOD save_modified.

  LOOP AT update-Incident ASSIGNING FIELD-SYMBOL(<incident>).

    DATA(lv_status_changed) = xsdbool(
      <incident>-%control-Status = if_abap_behv=>mk-on ).

    DATA(lv_details_changed) = xsdbool(
         <incident>-%control-Title       = if_abap_behv=>mk-on
      OR <incident>-%control-Description = if_abap_behv=>mk-on
      OR <incident>-%control-Priority    = if_abap_behv=>mk-on
      OR <incident>-%control-Responsible = if_abap_behv=>mk-on ).

    IF lv_status_changed = abap_false
       AND lv_details_changed = abap_false.
      CONTINUE.
    ENDIF.

    "El guardado gestionado ya ha escrito el historial creado por
    "recordInitialHistory o changeStatus.
    SELECT FROM zdt_inct_h_327
      FIELDS his_id, new_status
      WHERE inc_uuid = @<incident>-IncUuid
      ORDER BY his_id DESCENDING
      INTO TABLE @DATA(lt_last_history)
      UP TO 1 ROWS.

    READ TABLE lt_last_history INDEX 1
      INTO DATA(ls_last_history).
    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    "La acción changeStatus ya creó esta transición: no duplicarla.
    IF lv_status_changed = abap_true
       AND ls_last_history-new_status = <incident>-Status.
      CONTINUE.
    ENDIF.

    DATA ls_history TYPE zdt_inct_h_327.

    TRY.
        ls_history-his_uuid =
          cl_system_uuid=>create_uuid_x16_static( ).
      CATCH cx_uuid_error INTO DATA(lx_uuid).
        RAISE SHORTDUMP lx_uuid.
    ENDTRY.

    ls_history-inc_uuid = <incident>-IncUuid.
    ls_history-his_id =
      CONV #( CONV i( ls_last_history-his_id ) + 1 ).
    ls_history-previous_status = ls_last_history-new_status.
    ls_history-new_status = <incident>-Status.

    IF lv_status_changed = abap_true.
      ls_history-text = 'Status changed'.
    ELSE.
      ls_history-text = 'Incident updated'.
    ENDIF.

    ls_history-local_created_by =
      cl_abap_context_info=>get_user_technical_name( ).
    ls_history-local_last_changed_by =
      ls_history-local_created_by.

    GET TIME STAMP FIELD ls_history-local_created_at.
    ls_history-local_last_changed_at =
      ls_history-local_created_at.
    ls_history-last_changed_at =
      ls_history-local_created_at.

    INSERT zdt_inct_h_327 FROM @ls_history.

  ENDLOOP.

ENDMETHOD.

ENDCLASS.

CLASS lhc_incident DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS setInitialValues FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Incident~setInitialValues.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features
        FOR Incident RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations
        FOR Incident RESULT result.

    METHODS changeStatus FOR MODIFY
      IMPORTING keys FOR ACTION Incident~changeStatus
        RESULT result.

    METHODS recordInitialHistory FOR DETERMINE ON SAVE
      IMPORTING keys FOR Incident~recordInitialHistory.
METHODS validateIncident FOR VALIDATE ON SAVE
  IMPORTING keys FOR Incident~validateIncident.

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
        FIELDS ( Responsible Status )
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
  <authorization>-%delete = COND #(
    WHEN <incident>-Status = 'OP'
    THEN if_abap_behv=>auth-allowed
    ELSE if_abap_behv=>auth-unauthorized ).
ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD changeStatus.

    DATA lt_updates TYPE TABLE FOR UPDATE ZR_INCT_327.
    DATA(lv_today) = cl_abap_context_info=>get_system_date( ).

    READ ENTITIES OF ZR_INCT_327 IN LOCAL MODE
      ENTITY Incident
        FIELDS ( IncUuid Status Responsible )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_incidents)
      FAILED failed.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).

      READ TABLE lt_incidents ASSIGNING FIELD-SYMBOL(<incident>)
        WITH KEY %tky = <key>-%tky.

      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      DATA(lv_new_status) = <key>-%param-NewStatus.

      "La acción solo aplica a incidentes ya guardados.
      SELECT SINGLE inc_uuid
        FROM zdt_inct_327
        WHERE inc_uuid = @<incident>-IncUuid
        INTO @DATA(lv_existing_uuid).

      IF sy-subrc <> 0.
        APPEND VALUE #( %tky = <key>-%tky ) TO failed-Incident.
        APPEND VALUE #(
          %tky = <key>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = 'Guarda el incidente antes de cambiar su estado.' )
        ) TO reported-Incident.
        CONTINUE.
      ENDIF.

      "Rechazar códigos que no pertenecen al catálogo.
      IF lv_new_status <> 'OP'
         AND lv_new_status <> 'IP'
         AND lv_new_status <> 'PE'
         AND lv_new_status <> 'CO'
         AND lv_new_status <> 'CL'
         AND lv_new_status <> 'CN'.

        APPEND VALUE #( %tky = <key>-%tky ) TO failed-Incident.
        APPEND VALUE #(
          %tky = <key>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = 'El estado indicado no es válido.' )
        ) TO reported-Incident.
        CONTINUE.
      ENDIF.

      IF lv_new_status = <incident>-Status.
        APPEND VALUE #( %tky = <key>-%tky ) TO failed-Incident.
        APPEND VALUE #(
          %tky = <key>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = 'El incidente ya tiene ese estado.' )
        ) TO reported-Incident.
        CONTINUE.
      ENDIF.

      IF <incident>-Status = 'CN'
         OR <incident>-Status = 'CO'
         OR <incident>-Status = 'CL'.

        APPEND VALUE #( %tky = <key>-%tky ) TO failed-Incident.
        APPEND VALUE #(
          %tky = <key>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = 'Un incidente en estado final no puede cambiar.' )
        ) TO reported-Incident.
        CONTINUE.
      ENDIF.

      IF <incident>-Status = 'PE'
         AND ( lv_new_status = 'CO' OR lv_new_status = 'CL' ).

        APPEND VALUE #( %tky = <key>-%tky ) TO failed-Incident.
        APPEND VALUE #(
          %tky = <key>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = 'Un incidente pendiente no puede completarse ni cerrarse.' )
        ) TO reported-Incident.
        CONTINUE.
      ENDIF.

      IF lv_new_status = 'IP' AND <incident>-Responsible IS INITIAL.
        APPEND VALUE #( %tky = <key>-%tky ) TO failed-Incident.
        APPEND VALUE #(
          %tky = <key>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = 'Asigna un responsable antes de pasar a En progreso.' )
        ) TO reported-Incident.
        CONTINUE.
      ENDIF.

      APPEND VALUE #(
        %tky        = <key>-%tky
        Status      = lv_new_status
        ChangedDate = lv_today
      ) TO lt_updates.

    ENDLOOP.

    IF lt_updates IS INITIAL.
      RETURN.
    ENDIF.

    MODIFY ENTITIES OF ZR_INCT_327 IN LOCAL MODE
      ENTITY Incident
        UPDATE FIELDS ( Status ChangedDate )
        WITH lt_updates
      FAILED DATA(ls_update_failed)
      REPORTED DATA(ls_update_reported).

    APPEND LINES OF ls_update_failed-Incident TO failed-Incident.
    APPEND LINES OF ls_update_reported-Incident TO reported-Incident.

    DATA lv_history_cid TYPE i.

    LOOP AT lt_updates ASSIGNING FIELD-SYMBOL(<history_update>).

      "No registrar un cambio si falló la actualización del incidente.
      READ TABLE ls_update_failed-Incident TRANSPORTING NO FIELDS
        WITH KEY %tky = <history_update>-%tky.
      IF sy-subrc = 0.
        CONTINUE.
      ENDIF.

      READ TABLE lt_incidents ASSIGNING FIELD-SYMBOL(<old_incident>)
        WITH KEY %tky = <history_update>-%tky.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      READ TABLE keys ASSIGNING FIELD-SYMBOL(<action_key>)
        WITH KEY %tky = <history_update>-%tky.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      "Leer también las filas presentes en el buffer RAP.
      READ ENTITIES OF ZR_INCT_327 IN LOCAL MODE
        ENTITY Incident BY \_History
          FIELDS ( HisId )
          WITH VALUE #( ( %tky = <history_update>-%tky ) )
        RESULT DATA(lt_history)
        FAILED DATA(ls_history_read_failed).

      IF ls_history_read_failed IS NOT INITIAL.
        APPEND LINES OF ls_history_read_failed-Incident
          TO failed-Incident.
        APPEND LINES OF ls_history_read_failed-History
          TO failed-History.
        CONTINUE.
      ENDIF.

      DATA(lv_next_history_id) = 1.
      LOOP AT lt_history ASSIGNING FIELD-SYMBOL(<history>).
        IF CONV i( <history>-HisId ) >= lv_next_history_id.
          lv_next_history_id = CONV i( <history>-HisId ) + 1.
        ENDIF.
      ENDLOOP.

      lv_history_cid += 1.

      MODIFY ENTITIES OF ZR_INCT_327 IN LOCAL MODE
        ENTITY Incident
          CREATE BY \_History
          FIELDS ( HisId PreviousStatus NewStatus Text )
          WITH VALUE #(
            (
              %tky = <history_update>-%tky
              %target = VALUE #(
                (
                  %cid           = |HIST{ lv_history_cid }|
                  HisId          = CONV #( lv_next_history_id )
                  PreviousStatus = <old_incident>-Status
                  NewStatus      = <history_update>-Status
                  Text           = <action_key>-%param-Observation
                )
              )
            )
          )
        FAILED DATA(ls_history_failed)
        REPORTED DATA(ls_history_reported).

      APPEND LINES OF ls_history_failed-Incident TO failed-Incident.
      APPEND LINES OF ls_history_failed-History TO failed-History.
      APPEND LINES OF ls_history_reported-Incident TO reported-Incident.
      APPEND LINES OF ls_history_reported-History TO reported-History.

    ENDLOOP.

    READ ENTITIES OF ZR_INCT_327 IN LOCAL MODE
      ENTITY Incident
        ALL FIELDS WITH CORRESPONDING #( lt_updates )
      RESULT DATA(lt_updated_incidents).

    result = VALUE #(
      FOR ls_incident IN lt_updated_incidents
      ( %tky   = ls_incident-%tky
        %param = ls_incident )
    ).

  ENDMETHOD.

  METHOD recordInitialHistory.

    READ ENTITIES OF ZR_INCT_327 IN LOCAL MODE
      ENTITY Incident
        FIELDS ( Status )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_incidents).

    IF lt_incidents IS INITIAL.
      RETURN.
    ENDIF.

    MODIFY ENTITIES OF ZR_INCT_327 IN LOCAL MODE
      ENTITY Incident
        CREATE BY \_History
        FIELDS ( HisId NewStatus Text )
        WITH VALUE #(
          FOR ls_incident IN lt_incidents INDEX INTO i
          (
            %tky = ls_incident-%tky
            %target = VALUE #(
              (
                %cid      = |INIT{ i }|
                HisId     = '00000001'
                NewStatus = ls_incident-Status
                Text      = 'First Incident'
              )
            )
          )
        ).

  ENDMETHOD.

METHOD validateIncident.

  DATA(lv_today) = cl_abap_context_info=>get_system_date( ).

  READ ENTITIES OF ZR_INCT_327 IN LOCAL MODE
    ENTITY Incident
      FIELDS ( Title Description Priority Status
               CreationDate ChangedDate )
      WITH CORRESPONDING #( keys )
    RESULT DATA(lt_incidents).

  LOOP AT lt_incidents ASSIGNING FIELD-SYMBOL(<incident>).

    DATA lv_message TYPE string.

    IF <incident>-Title IS INITIAL
       OR <incident>-Description IS INITIAL
       OR <incident>-Priority IS INITIAL
       OR <incident>-Status IS INITIAL
       OR <incident>-CreationDate IS INITIAL.

      lv_message = 'Completa título, descripción, prioridad, estado y fecha de creación.'.

    ELSEIF <incident>-Priority <> 'H'
       AND <incident>-Priority <> 'M'
       AND <incident>-Priority <> 'L'.

      lv_message = 'La prioridad debe ser H, M o L.'.

    ELSEIF <incident>-Status <> 'OP'
       AND <incident>-Status <> 'IP'
       AND <incident>-Status <> 'PE'
       AND <incident>-Status <> 'CO'
       AND <incident>-Status <> 'CL'
       AND <incident>-Status <> 'CN'.

      lv_message = 'El estado del incidente no es válido.'.

    ELSEIF <incident>-CreationDate > lv_today
       OR <incident>-ChangedDate > lv_today.

      lv_message = 'No se permiten fechas futuras.'.

    ELSEIF <incident>-ChangedDate < <incident>-CreationDate.

      lv_message = 'La fecha de cambio no puede ser anterior a la de creación.'.

    ENDIF.

    IF lv_message IS NOT INITIAL.
      APPEND VALUE #( %tky = <incident>-%tky )
        TO failed-Incident.

      APPEND VALUE #(
        %tky = <incident>-%tky
        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = lv_message )
      ) TO reported-Incident.
    ENDIF.

  ENDLOOP.

ENDMETHOD.

ENDCLASS.


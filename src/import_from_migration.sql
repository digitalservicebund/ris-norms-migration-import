DELETE FROM :NORMS_SCHEMA.announcements;
DELETE FROM :NORMS_SCHEMA.norms;

INSERT INTO :NORMS_SCHEMA.norms (xml) SELECT ldml_xml.content FROM :MIGRATION_SCHEMA.migration_record
         INNER JOIN :MIGRATION_SCHEMA.ldml ldml ON migration_record.id = ldml.migration_record_id
         INNER JOIN :MIGRATION_SCHEMA.ldml_xml ldml_xml ON ldml.id = ldml_xml.ldml_id
         LEFT OUTER JOIN :MIGRATION_SCHEMA.migration_error migration_error on migration_record.id = migration_error.migration_record_id
         WHERE
             migration_status = 'LEGALDOCML_TRANSFORMATION_SUCCEEDED'
            AND xpath_exists('//akn:act[@name="regelungstext"]', ldml_xml.content, '{{akn,http://Inhaltsdaten.LegalDocML.de/1.7/}}')
            AND migration_error.id IS NULL;

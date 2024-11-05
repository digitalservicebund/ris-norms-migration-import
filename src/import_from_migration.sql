DELETE FROM :NORMS_SCHEMA.release_norms;
DELETE FROM :NORMS_SCHEMA.announcement_releases;
DELETE FROM :NORMS_SCHEMA.releases;
DELETE FROM :NORMS_SCHEMA.announcements;
DELETE FROM :NORMS_SCHEMA.norms WHERE
    -- keep our seeds, for now
    eli_manifestation NOT IN (
        'eli/bund/bgbl-1/1964/s593/1964-08-05/1/deu/1964-08-05/regelungstext-1.xml',
        'eli/bund/bgbl-1/1990/s2954/2022-12-19/1/deu/1990-12-20/regelungstext-1.xml',
        'eli/bund/bgbl-1/1000/1/1000-01-01/1/deu/1000-01-01/regelungstext-1.xml',
        'eli/bund/bgbl-1/2009/s3366/2023-12-23/1/deu/2023-12-23/regelungstext-1.xml',
        'eli/bund/bgbl-1/1001/1/1001-01-01/1/deu/1001-01-01/regelungstext-1.xml',
        'eli/bund/bgbl-1/1002/1/1002-01-01/1/deu/1002-01-01/regelungstext-1.xml'
    );

INSERT INTO :NORMS_SCHEMA.norms (xml) SELECT ldml_xml.content FROM :MIGRATION_SCHEMA.migration_record
         INNER JOIN :MIGRATION_SCHEMA.ldml ldml ON migration_record.id = ldml.migration_record_id
         INNER JOIN :MIGRATION_SCHEMA.ldml_xml ldml_xml ON ldml.id = ldml_xml.ldml_id
         LEFT OUTER JOIN :MIGRATION_SCHEMA.migration_error migration_error on
            migration_record.id = migration_error.migration_record_id
                -- ignore violations of schematron rules SCH-00200-005 and SCH-00210-005 for existing norms
                AND migration_error.description NOT LIKE '%SCH-00210-005%'
                AND migration_error.description NOT LIKE '%SCH-00200-005%'
         WHERE
            migration_status IN ('LEGALDOCML_TRANSFORMATION_SUCCEEDED', 'LEGALDOCML_VALIDATION_FAILED')
            AND xpath_exists('//akn:act[@name="regelungstext"]', ldml_xml.content, '{{akn,http://Inhaltsdaten.LegalDocML.de/1.7/}}')
            AND migration_error.id IS NULL
    ON CONFLICT DO NOTHING;

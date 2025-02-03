DELETE FROM :NORMS_SCHEMA.release_norms;
DELETE FROM :NORMS_SCHEMA.announcement_releases;
DELETE FROM :NORMS_SCHEMA.releases;
DELETE FROM :NORMS_SCHEMA.announcements;
DELETE FROM :NORMS_SCHEMA.dokumente WHERE
    -- keep our seeds, for now
    eli_dokument_manifestation NOT IN (
        'eli/bund/bgbl-1/1964/s593/1964-08-05/1/deu/1964-08-05/regelungstext-1.xml',
        'eli/bund/bgbl-1/1990/s2954/2022-12-19/1/deu/1990-12-20/regelungstext-1.xml',
        'eli/bund/bgbl-1/1000/1/1000-01-01/1/deu/1000-01-01/regelungstext-1.xml',
        'eli/bund/bgbl-1/2009/s3366/2023-12-23/1/deu/2023-12-23/regelungstext-1.xml',
        'eli/bund/bgbl-1/1001/1/1001-01-01/1/deu/1001-01-01/regelungstext-1.xml',
        'eli/bund/bgbl-1/1002/1/1002-01-01/1/deu/1002-01-01/regelungstext-1.xml'
    );
DELETE FROM norms.norm_manifestation WHERE
    -- keep our seeds, for now
    eli_norm_manifestation NOT IN (
        'eli/bund/bgbl-1/1964/s593/1964-08-05/1/deu/1964-08-05',
        'eli/bund/bgbl-1/1990/s2954/2022-12-19/1/deu/1990-12-20',
        'eli/bund/bgbl-1/1000/1/1000-01-01/1/deu/1000-01-01',
        'eli/bund/bgbl-1/2009/s3366/2023-12-23/1/deu/2023-12-23',
        'eli/bund/bgbl-1/1001/1/1001-01-01/1/deu/1001-01-01',
        'eli/bund/bgbl-1/1002/1/1002-01-01/1/deu/1002-01-01'
        );
DELETE FROM norms.norm_expression WHERE
    -- keep our seeds, for now
    eli_norm_expression NOT IN (
        'eli/bund/bgbl-1/1964/s593/1964-08-05/1/deu',
        'eli/bund/bgbl-1/1990/s2954/2022-12-19/1/deu',
        'eli/bund/bgbl-1/1000/1/1000-01-01/1/deu',
        'eli/bund/bgbl-1/2009/s3366/2023-12-23/1/deu',
        'eli/bund/bgbl-1/1001/1/1001-01-01/1/deu',
        'eli/bund/bgbl-1/1002/1/1002-01-01/1/deu'
        );

-- Insert into dokumente table and track inserted rows
WITH inserted_dokumente AS (
    INSERT INTO :NORMS_SCHEMA.dokumente (xml)
    SELECT ldml_xml.content
    FROM :MIGRATION_SCHEMA.migration_record
        INNER JOIN :MIGRATION_SCHEMA.ldml ldml ON migration_record.id = ldml.migration_record_id
        INNER JOIN :MIGRATION_SCHEMA.ldml_xml ldml_xml ON ldml.id = ldml_xml.ldml_id
        LEFT OUTER JOIN :MIGRATION_SCHEMA.migration_error migration_error ON
            migration_record.id = migration_error.migration_record_id
            AND migration_error.description NOT LIKE '%SCH-00210-005%'
            AND migration_error.description NOT LIKE '%SCH-00200-005%'
    WHERE
        migration_status IN ('LEGALDOCML_TRANSFORMATION_SUCCEEDED', 'LEGALDOCML_VALIDATION_FAILED')
        AND ldml_xml.type = 'regelungstext'
        AND migration_error.id IS NULL
    ON CONFLICT DO NOTHING -- ensures duplicates are ignored
    RETURNING eli_norm_manifestation
)

-- Log the number of inserted rows
INSERT INTO :NORMS_SCHEMA.migration_log (size)
SELECT COUNT(*) FROM inserted_dokumente;

-- Update publish_state in norm_manifestation only for entries related to inserted dokumente
UPDATE :NORMS_SCHEMA.norm_manifestation nm
SET publish_state = 'QUEUED_FOR_PUBLISH'
FROM inserted_dokumente id
WHERE nm.eli_norm_manifestation = id.eli_dokument_manifestation
  AND nm.publish_state = 'UNPUBLISHED';


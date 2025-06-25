DELETE FROM :NORMS_SCHEMA.verkuendungen;
DELETE FROM :NORMS_SCHEMA.binary_files;
DELETE FROM :NORMS_SCHEMA.dokumente WHERE
    -- keep our seeds, for now
    eli_dokument_manifestation NOT IN (
        'eli/bund/bgbl-1/1990/s2954/2022-12-19/1/deu/1990-12-20/regelungstext-1.xml',
        'eli/bund/bgbl-1/1000/1/1000-01-01/1/deu/1000-01-01/regelungstext-1.xml',
        'eli/bund/bgbl-1/2009/s3366/2023-12-23/1/deu/2023-12-23/regelungstext-1.xml',
        'eli/bund/bgbl-1/1001/1/1001-01-01/1/deu/1001-01-01/regelungstext-1.xml',
        'eli/bund/bgbl-1/1002/1/1002-01-01/1/deu/1002-01-01/regelungstext-1.xml',

        'eli/bund/bgbl-1/1990/s2954/2022-12-19/1/deu/1990-12-20/regelungstext-verkuendung-1.xml',
        'eli/bund/bgbl-1/1000/1/1000-01-01/1/deu/1000-01-01/regelungstext-verkuendung-1.xml',
        'eli/bund/bgbl-1/2009/s3366/2023-12-23/1/deu/2023-12-23/regelungstext-verkuendung-1.xml',
        'eli/bund/bgbl-1/1001/1/1001-01-01/1/deu/1001-01-01/regelungstext-verkuendung-1.xml',
        'eli/bund/bgbl-1/1002/1/1002-01-01/1/deu/1002-01-01/regelungstext-verkuendung-1.xml',

        'eli/bund/bgbl-1/1990/s2954/2022-12-19/1/deu/1990-12-20/rechtsetzungsdokument-1.xml',
        'eli/bund/bgbl-1/1000/1/1000-01-01/1/deu/1000-01-01/rechtsetzungsdokument-1.xml',
        'eli/bund/bgbl-1/2009/s3366/2023-12-23/1/deu/2023-12-23/rechtsetzungsdokument-1.xml',
        'eli/bund/bgbl-1/1001/1/1001-01-01/1/deu/1001-01-01/rechtsetzungsdokument-1.xml',
        'eli/bund/bgbl-1/1002/1/1002-01-01/1/deu/1002-01-01/rechtsetzungsdokument-1.xml'
    );
DELETE FROM :NORMS_SCHEMA.norm_manifestation WHERE
    -- keep our seeds, for now
    eli_norm_manifestation NOT IN (
        'eli/bund/bgbl-1/1990/s2954/2022-12-19/1/deu/1990-12-20',
        'eli/bund/bgbl-1/1000/1/1000-01-01/1/deu/1000-01-01',
        'eli/bund/bgbl-1/2009/s3366/2023-12-23/1/deu/2023-12-23',
        'eli/bund/bgbl-1/1001/1/1001-01-01/1/deu/1001-01-01',
        'eli/bund/bgbl-1/1002/1/1002-01-01/1/deu/1002-01-01'
        );
DELETE FROM :NORMS_SCHEMA.norm_expression WHERE
    -- keep our seeds, for now
    eli_norm_expression NOT IN (
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
    FROM :MIGRATION_SCHEMA.ldml_xml ldml_xml
    JOIN :MIGRATION_SCHEMA.ldml_version ldml_version ON ldml_xml.ldml_version_id = ldml_version.id
    WHERE ldml_xml.id IN (
        SELECT ldml_xml.id
        FROM :MIGRATION_SCHEMA.ldml_xml ldml_xml
        LEFT JOIN :MIGRATION_SCHEMA.ldml_error ldml_error ON ldml_xml.id = ldml_error.ldml_xml_id
        WHERE (ldml_error.id IS NULL OR ldml_error.type = 'schematron warning')
        GROUP BY ldml_xml.id
    )
    AND NOT EXISTS (
        SELECT 1
        FROM :MIGRATION_SCHEMA.ldml_xml sub_ldml_xml
        JOIN :MIGRATION_SCHEMA.ldml_error sub_error ON sub_ldml_xml.id = sub_error.ldml_xml_id
        WHERE sub_ldml_xml.ldml_version_id = ldml_version.id
        AND sub_error.type != 'schematron warning'
    )
    ON CONFLICT DO NOTHING -- ensures duplicates are ignored
    RETURNING eli_norm_manifestation
)
-- Create and populate temp table using the CTE from the insert, needed because of two separate statements + subquery in the 2nd one
SELECT eli_norm_manifestation INTO TEMP TABLE inserted_docs FROM inserted_dokumente;

-- Import Binary files
WITH inserted_binary_files AS (
INSERT
INTO :NORMS_SCHEMA.binary_files (content, eli_dokument_manifestation)
SELECT content, (ldml_version.manifestation_eli || '/' || attachment.short_filename)
FROM :MIGRATION_SCHEMA.ldml_version ldml_version
    JOIN :MIGRATION_SCHEMA.ldml_version_norm_xml ldml_version_norm_xml
ON ldml_version.id = ldml_version_norm_xml.ldml_version_id
    JOIN :MIGRATION_SCHEMA.attachment attachment ON ldml_version_norm_xml.norm_xml_id = attachment.norm_xml_id
WHERE ldml_version.manifestation_eli IN (SELECT eli_norm_manifestation FROM inserted_docs)
  AND attachment.short_filename != ''
ON CONFLICT DO NOTHING
    RETURNING 1
);


-- Log the number of migrated dokumente and binary files
INSERT INTO :NORMS_SCHEMA.migration_log (xml_size, binary_size)
SELECT
    (SELECT COUNT(*) FROM inserted_docs),
    (SELECT COUNT(*) FROM inserted_binary_files);

-- Update publish_state in norm_manifestation only for entries coming from the inserted dokumente
UPDATE :NORMS_SCHEMA.norm_manifestation nm
SET publish_state = 'QUEUED_FOR_PUBLISH'
WHERE nm.eli_norm_manifestation IN (SELECT eli_norm_manifestation FROM inserted_docs)
  AND nm.publish_state = 'UNPUBLISHED';

-- Drop the created temporary table (although they are automatically dropped at end of session, it is good practice)
DROP TABLE inserted_docs;

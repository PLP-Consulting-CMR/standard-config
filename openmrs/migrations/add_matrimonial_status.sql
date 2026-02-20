-- ============================================================
-- Migration : Statut matrimonial + Person Attribute Types
-- Date      : 2026-02-19
-- Author    : PlinePay e-health
-- ============================================================

SET NAMES utf8mb4;

UPDATE person_attribute_type
SET description = 'REGISTRATION_LABEL_PHONE_NUMBER_KEY'
WHERE name = 'phoneNumber' AND description != 'REGISTRATION_LABEL_PHONE_NUMBER_KEY';

UPDATE person_attribute_type
SET description = 'REGISTRATION_LABEL_EMPLOYMENT_KEY'
WHERE name = 'Employment' AND description != 'REGISTRATION_LABEL_EMPLOYMENT_KEY';

UPDATE person_attribute_type
SET description = 'REGISTRATION_LABEL_MATRIMONIAL_STATUS_KEY'
WHERE name = 'matrimonialStatus' AND description != 'REGISTRATION_LABEL_MATRIMONIAL_STATUS_KEY';

INSERT INTO concept (uuid, retired, is_set, creator, date_created, datatype_id, class_id)
SELECT
  '53f2016d-fb69-4b39-9451-0e43b175be32',
  0, 1, 1, NOW(),
  (SELECT concept_datatype_id FROM concept_datatype WHERE name = 'Coded'),
  (SELECT concept_class_id FROM concept_class WHERE name = 'Misc')
WHERE NOT EXISTS (
  SELECT 1 FROM concept WHERE uuid = '53f2016d-fb69-4b39-9451-0e43b175be32'
);

SET @matrimonial_id = (SELECT concept_id FROM concept WHERE uuid = '53f2016d-fb69-4b39-9451-0e43b175be32');

INSERT INTO concept_name (concept_id, name, locale, locale_preferred, concept_name_type, creator, date_created, voided, uuid)
SELECT @matrimonial_id, 'Matrimonial status', 'en', 1, 'FULLY_SPECIFIED', 1, NOW(), 0, UUID()
WHERE NOT EXISTS (
  SELECT 1 FROM concept_name
  WHERE concept_id = @matrimonial_id AND locale = 'en' AND voided = 0
);

INSERT INTO concept_name (concept_id, name, locale, locale_preferred, concept_name_type, creator, date_created, voided, uuid)
SELECT @matrimonial_id, 'Statut matrimonial', 'fr', 1, 'FULLY_SPECIFIED', 1, NOW(), 0, UUID()
WHERE NOT EXISTS (
  SELECT 1 FROM concept_name
  WHERE concept_id = @matrimonial_id AND locale = 'fr' AND voided = 0
);

-- ── 4. Answers du concept ──────────────────────────────────────
-- (idempotent : insère uniquement si absent)
INSERT INTO concept_answer (concept_id, answer_concept, sort_weight, creator, date_created, uuid)
SELECT @matrimonial_id, c.concept_id, t.sort_weight, 1, NOW(), UUID()
FROM (
  SELECT '6a13c661-1a44-4d80-99a3-f427018ced70' AS uuid, 1 AS sort_weight UNION ALL
  SELECT '52fea5fc-0aea-49c5-b5ab-d54826b7e164',         2 UNION ALL
  SELECT '395ce16c-c9bf-4f78-a366-c1228a258a30',         3 UNION ALL
  SELECT '6fc43013-bee1-46b1-8e5e-a5d2d3cd266b',         4 UNION ALL
  SELECT 'fcf34be1-20fd-41b0-8562-8e123ed40145',         5 UNION ALL
  SELECT '1067AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',          6
) t
JOIN concept c ON c.uuid = t.uuid
WHERE NOT EXISTS (
  SELECT 1 FROM concept_answer
  WHERE concept_id = @matrimonial_id AND answer_concept = c.concept_id
);

UPDATE person_attribute_type
SET
  format      = 'org.openmrs.Concept',
  foreign_key = @matrimonial_id
WHERE name = 'matrimonialStatus';

SELECT 'Person Attribute Types' AS check_name;
SELECT name, format, foreign_key, description
FROM person_attribute_type
WHERE name IN ('phoneNumber', 'Employment', 'matrimonialStatus', 'education');

SELECT 'Concept Matrimonial Status' AS check_name;
SELECT @matrimonial_id AS concept_id;

SELECT 'Answers' AS check_name;
SELECT ca.sort_weight, cn.name, cn.locale
FROM concept_answer ca
JOIN concept_name cn ON ca.answer_concept = cn.concept_id
WHERE ca.concept_id = @matrimonial_id
AND cn.locale = 'en' AND cn.concept_name_type = 'FULLY_SPECIFIED'
ORDER BY ca.sort_weight;

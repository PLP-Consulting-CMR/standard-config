docker exec -it bahmni-standard_openmrsdb_1 mysql -u openmrs-user -ppassword openmrs


SET @anc_uuid = UUID();

INSERT INTO patient_identifier_type (name, description, check_digit, required, format, uuid, creator, date_created, retired)
VALUES ('ANC Number', 'Identifier for Antenatal Care', 0, 0, NULL, @anc_uuid, 1, NOW(), 0);

-- This query appends the new ANC UUID to the existing list of extra identifiers
UPDATE global_property 
SET property_value = IF(
    property_value IS NULL OR property_value = '', 
    (SELECT uuid FROM patient_identifier_type WHERE name = 'ANC Number'), 
    CONCAT(property_value, ',', (SELECT uuid FROM patient_identifier_type WHERE name = 'ANC Number'))
)
WHERE property = 'bahmni.extraPatientIdentifierTypes';

-- 1. Create the new Identifier Types
INSERT INTO patient_identifier_type (name, description, check_digit, required, uuid, creator, date_created, retired) VALUES 
('NIC number', 'National ID Card Number', 0, 0, UUID(), 1, NOW(), 0),
('Unique identification NIC', 'Unique Identification NIC', 0, 0, UUID(), 1, NOW(), 0),
('TARV number', 'Treatment ARV Number', 0, 0, UUID(), 1, NOW(), 0),
('Passport number', 'Passport identification', 0, 0, UUID(), 1, NOW(), 0),
('Receipt number', 'Financial receipt number', 0, 0, UUID(), 1, NOW(), 0),
('Other number', 'Generic secondary identifier', 0, 0, UUID(), 1, NOW(), 0),
('UHC Unique ID', 'Universal Health Coverage ID', 0, 0, UUID(), 1, NOW(), 0);

-- 2. Update the Bahmni Global Property to include these new IDs
-- This query automatically finds the UUIDs of your new types and appends them to the existing list
SET @new_uuids = (SELECT GROUP_CONCAT(uuid) FROM patient_identifier_type 
                  WHERE name IN ('NIC number', 'Unique identification NIC', 'TARV number', 
                                 'Passport number', 'Receipt number', 'Other number', 'UHC Unique ID'));

UPDATE global_property 
SET property_value = IF(
    property_value IS NULL OR property_value = '', 
    @new_uuids, 
    CONCAT(property_value, ',', @new_uuids)
)
WHERE property = 'bahmni.extraPatientIdentifierTypes';

-- View: view_people_address_contacts_detail.sql
-- Detalha pessoas, endereços e contatos

CREATE OR REPLACE VIEW public.view_people_address_contacts_detail AS
SELECT
    p.id AS person_id,
    p.name AS person_name,
    p.type AS person_type,
    p.document AS person_document,
    p.birth_date,
    p.gender,
    p.status AS person_status,
    p.department_id,
    a.id AS address_id,
    a.street,
    a.number,
    a.complement,
    a.district,
    a.city,
    a.state,
    a.zipcode,
    a.type AS address_type,
    a.reference_point,
    a.is_primary,
    a.created_at AS address_created_at,
    a.updated_at AS address_updated_at,
    c.id AS contact_id,
    c.type AS contact_type,
    c.value AS contact_value,
    c.is_primary AS contact_is_primary,
    c.notes AS contact_notes,
    c.created_at AS contact_created_at,
    c.updated_at AS contact_updated_at
FROM public.core_people p
LEFT JOIN public.core_addresses a ON a.person_id = p.id
LEFT JOIN public.core_contacts c ON c.person_id = p.id;

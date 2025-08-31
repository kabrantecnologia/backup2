-- View: 550_view_core_user_details.sql
-- Combina informações de pessoas, usuários e departamentos


CREATE OR REPLACE VIEW public.view_core_user_details AS
SELECT
    u.id AS user_id,
    u.login,
    u.email,
    u.access_level,
    u.status AS user_status,
    u.last_access,
    u.created_at AS user_created_at,
    u.updated_at AS user_updated_at,
    p.id AS person_id,
    p.name AS person_name,
    p.type AS person_type,
    p.document AS person_document,
    p.birth_date,
    p.gender,
    p.status AS person_status,
    p.department_id,
    d.name AS department_name,
    d.code AS department_code,
    d.manager_id AS department_manager_id,
    d.cost_center,
    d.status AS department_status,
    e.id AS employee_id,
    e.employee_code,
    e.admission_date,
    e.termination_date,
    e.position_id,
    e.manager_id AS employee_manager_id,
    e.contract_type,
    e.salary,
    e.work_hours,
    e.location_id,
    e.notes AS employee_notes,
    e.status AS employee_status
FROM public.core_users u
JOIN public.core_people p ON u.person_id = p.id
LEFT JOIN public.core_departments d ON p.department_id = d.id
LEFT JOIN public.hr_employees e ON e.person_id = p.id;

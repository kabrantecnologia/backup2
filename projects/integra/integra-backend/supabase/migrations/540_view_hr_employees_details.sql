
CREATE OR REPLACE VIEW public.view_hr_employees_details AS
SELECT
    emp_person.name AS employee_name,
    emp.employee_code,
    dept.name AS department_name,
    mgr_person.name AS manager_name,
    emp.id AS employee_id,
    dept.id AS department_id,
    dept.manager_id AS manager_id
FROM
    public.hr_employees emp
JOIN
    public.core_people emp_person ON emp.person_id = emp_person.id
LEFT JOIN
    public.core_departments dept ON emp.department_id = dept.id
LEFT JOIN
    public.core_people mgr_person ON dept.manager_id = mgr_person.id;

COMMENT ON VIEW public.view_hr_employees_details IS 'Provides a detailed view of employees, including their department and manager names.';

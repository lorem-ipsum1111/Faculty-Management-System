
SELECT f.id, f.first_name, f.last_name, d.department_name FROM faculty AS f, department AS d WHERE f.id = d.hod_id;

SELECT DISTINCT f.id, f.first_name, f.last_name, d.department_name, hp.start_date, hp.end_date FROM faculty AS f, department AS d, hod_appointments AS hp WHERE f.id = d.hod_id AND d.hod_id = hp.faculty_id;


SELECT DISTINCT f.id, f.first_name, f.last_name, p.designation, p.start_date, p.end_date FROM faculty AS f, por_appointments AS p WHERE f.id = p.ccfaculty_id;


SELECT f.id, f.first_name, f.last_name, c.designation, c.remaining_leaves FROM faculty AS f, cross_cutting_faculty_details AS c WHERE f.id = c.faculty_id AND c.designation IS NOT NULL;

SELECT id, first_name, last_name, gender, joining_date FROM faculty WHERE leaving_date IS NULL;

SELECT id, first_name, last_name, gender, joining_date,leaving_date FROM faculty;


SELECT l.application_id, l.sender_id, f1.first_name, f1.last_name FROM leave_pending AS l, faculty AS f1 WHERE 	l.sender_id = f1.id  and l.current_holder_id = <INSERT ID HERE>;



SELECT b.budget_type, b.budget_amount, f.first_name, f.last_name FROM budget as b, faculty AS f WHERE f.id = b.budget_head_id AND b.project_id = <INSERT PROJECT ID HERE>;



SELECT request_id, expenditure_type, cost_per_unit, num_of_units FROM expenditure WHERE project_id = <INSERT PROJECT ID HERE>;



SELECT request_id, expenditure_type, cost_per_unit, num_of_units FROM expenditure WHERE project_id = <INSERT PROJECT ID>;

	
SELECT b.budget_type, b.budget_amount, f.first_name, f.last_name FROM budget AS b, faculty AS f WHERE f.id = b.budget_head_id AND b.project_id = <INSERT PROJECT ID>; 

SELECT f. id, f.first_name, f.last_name FROM faculty AS f, normal_pi AS n WHERE n.pi_id = f.id AND n.project_id = <INSERT PROJECT ID>;





----------------APPROVED REQUESTS -----------------------------
SELECT DISTINCT d.request_id,p.project_name, e.expenditure_type, e.cost_per_unit, e.num_of_units FROM decisions_trail as d, expenditure as e WHERE d.request_id = e.request_id AND p.project_id = d.project_id AND d.pi_id = <INSERT PI ID>;


-----------------------REJECTED REQUESTS---------------------
SELECT DISTINCT d.request_id,p.project_name, r.expenditure_type, r.cost_per_unit, r.num_of_units,f.first_name, f.last_name FROM decisions_trail AS d, rejected_requests AS r, faculty AS f WHERE d.request_id = r.request_id AND r.last_holder_id = f.id AND p.project_id = d.project_id AND d.pi_id = <INSERT PI ID>;


--------------------PENDING REQUESTS---------------------------

SELECT DISTINCT d.request_id,p.project_name, c.expenditure_type, c.cost_per_unit, c.num_of_units,f.first_name, f.last_name FROM decisions_trail AS d, current_request AS c, faculty AS f WHERE d.request_id = c.request_id AND c.current_holder_id = f.id AND p.project_id = d.project_id AND d.pi_id = <INSERT PI ID>;


(SELECT DISTINCT p.project_id, p.project_name, p.starting_date, p.ending_date FROM project AS p, normal_pi AS n WHERE n.project_id = p.project_id AND p.ending_date IS NOT NULL AND n.pi_id = <INSERT PI ID HERE> )  UNION (SELECT project_id, project_name, starting_date, ending_date FROM project WHERE ending_date IS NOT NULL AND main_pi_id = <INSERT PI ID HERE>);
	



SELECT p.project_id, p.project_name,p.main_pi_id ,f.first_name, f.last_name,  p.starting_date FROM faculty AS f, project AS p WHERE p.main_pi_id = f.id;


SELECT * FROM decisions_trail;

SELECT b.project_id, p.project_name, b.budget_type, b.budget_amount FROM budget AS b, project AS p WHERE b.project_id = p.project_id;



SELECT e.request_id, e.project_id,p.project_name e.expenditure_type, e.cost_per_unit, e.num_of_units FROM expenditure AS e, project AS p WHERE p.project_id = e.project_id;

SELECT application_ID, action_taker_id, action, comments FROM paper_trail;
	

---------------------------DISPLAY COMPLETED PROJECTS--------------------------------------

(SELECT DISTINCT p.project_id, p.project_name, p.starting_date, p.ending_date FROM project AS p, normal_pi AS n WHERE n.project_id = p.project_id AND p.ending_date IS NOT NULL AND n.pi_id = <INSERT PI ID HERE> )  UNION (SELECT project_id, project_name, starting_date, ending_date FROM project WHERE ending_date IS NOT NULL AND main_pi_id = <INSERT PI ID HERE>);
	

-------------------------------------DISPLAY LIST OF PROJECTS-----------------------------

SELECT p.project_id, p.project_name,p.main_pi_id ,f.first_name, f.last_name,  p.starting_date FROM faculty AS f, project AS p WHERE p.main_pi_id = f.id;



-------------------------------DISPLAY DECISIONS TRAIL-----------------------------
SELECT * FROM decisions_trail;


------------------------------------------DISPLAY LIST OF BUDGETS OF DIFFERENT PROJECTS----------------------

SELECT b.project_id, p.project_name, b.budget_type, b.budget_amount FROM budget AS b, project AS p WHERE b.project_id = p.project_id;

-----------------------------------DISPLAY LIST OF EXPENDITURES ON DIFFERENT PROJECTS---------------------------

SELECT e.request_id, e.project_id,p.project_name e.expenditure_type, e.cost_per_unit, e.num_of_units FROM expenditure AS e, project AS p WHERE p.project_id = e.project_id;

--------------------------------------DISPLAY PAPER TRAIL-----------------------------
SELECT application_ID, action_taker_id, action, comments FROM paper_trail;

-------------------------------DISPLAY FACULTIES BELONGING TO A DEPARTMENT------------------------------
SELECT f.id,f.first_name,f.last_name from faculty as f, normal_faculty_details as n where n.department = '<department_name>';



----------------DISPLAY APPROVED REQUESTS -----------------------------
SELECT DISTINCT d.request_id,p.project_name, e.expenditure_type, e.cost_per_unit, e.num_of_units FROM decisions_trail as d, expenditure as e WHERE d.request_id = e.request_id AND p.project_id = d.project_id AND d.pi_id = <INSERT PI ID>;


-----------------------DISPLAY REJECTED REQUESTS---------------------
SELECT DISTINCT d.request_id,p.project_name, r.expenditure_type, r.cost_per_unit, r.num_of_units,f.first_name, f.last_name FROM decisions_trail AS d, rejected_requests AS r, faculty AS f WHERE d.request_id = r.request_id AND r.last_holder_id = f.id AND p.project_id = d.project_id AND d.pi_id = <INSERT PI ID>;


--------------------DISPLAY PENDING REQUESTS---------------------------

SELECT DISTINCT d.request_id,p.project_name, c.expenditure_type, c.cost_per_unit, c.num_of_units,f.first_name, f.last_name FROM decisions_trail AS d, current_request AS c, faculty AS f WHERE d.request_id = c.request_id AND c.current_holder_id = f.id AND p.project_id = d.project_id AND d.pi_id = <INSERT PI ID>;

-------------------------------DISPLAY EXPENDITURES ON A PARTICULAR PROJECT------------------------------

SELECT request_id, expenditure_type, cost_per_unit, num_of_units FROM expenditure WHERE project_id = <INSERT PROJECT ID>;

----------------------------------DISPLAY BUDGET OF A PARTICULAR PROJECT-----------------------------	
SELECT b.budget_type, b.budget_amount, f.first_name, f.last_name FROM budget AS b, faculty AS f WHERE f.id = b.budget_head_id AND b.project_id = <INSERT PROJECT ID>; 

-------------------------------------DISPLAY LIST OF NORMAL PI OF A PARTICULAR PROJECT--------------------------------

SELECT f. id, f.first_name, f.last_name FROM faculty AS f, normal_pi AS n WHERE n.pi_id = f.id AND n.project_id = <INSERT PROJECT ID>;

----------------------DISPLAY THE PROJECTS OF WHICH YOU WERE THE MAIN PI-----------------------

SELECT project_id, project_name, starting_date FROM project WHERE main_pi_id = <INSERT ID HERE>;


----------------------DISPLAY THE PROJECTS OF WHICH YOU ARE NORMAL PI----------------------------

SELECT p.project_id, p.project_name, p.starting_date FROM project AS p, normal_pi AS n WHERE p.project_id = n.project_id AND n.pi_id = <INSERT ID HERE>;





-----------------------------DISPLAY LIST OF HOD'S------------------------------


SELECT f.id, f.first_name, f.last_name, d.department_name FROM faculty AS f, department AS d WHERE f.id = d.hod_id;


------------------------------------DISPLAY PAST HOD'S----------------------------

SELECT DISTINCT f.id, f.first_name, f.last_name, d.department_name, hp.start_date, hp.end_date FROM faculty AS f, department AS d, hod_appointments AS hp WHERE f.id = d.hod_id AND d.hod_id = hp.faculty_id;




----------------------------DISPLAY PAST POR'S--------------------------------


SELECT DISTINCT f.id, f.first_name, f.last_name, p.designation, p.start_date, p.end_date FROM faculty AS f, por_appointments AS p WHERE f.id = p.ccfaculty_id;


--------------------------------DISPLAY CROSS CUTTING FACULTY DETAILS---------------------------


SELECT f.id, f.first_name, f.last_name, c.designation, c.remaining_leaves FROM faculty AS f, cross_cutting_faculty_details AS c WHERE f.id = c.faculty_id AND c.designation IS NOT NULL;

------------------------------DISPLAY LIST OF PRESENT FACULTIES-------------------------


SELECT id, first_name, last_name, gender, joining_date FROM faculty WHERE leaving_date IS NULL;

--------------------------------------DISPLAY LIST OF ALL FACULTIES----------------------

SELECT id, first_name, last_name, gender, joining_date,leaving_date FROM faculty;


---------------------------------DISPLAY LEAVES PENDING FOR DECISION AT YOUR LEVEL-------------------------------

SELECT l.application_id, l.sender_id, f1.first_name, f1.last_name FROM leave_pending AS l, faculty AS f1 WHERE 	l.sender_id = f1.id  and l.current_holder_id = <INSERT ID HERE>;


---------------------------DISPLAY CROSS CUTTING FACULTY WITH DESIGNATION---------------------------------
SELECT f.id, f.first_name, f.last_name, c.designation FROM faculty AS f, cross_cutting_faculty_details AS c WHERE f.id = c.faculty_id;















CREATE TABLE project(
	project_id SERIAL
	,main_pi_id INT NOT NULL
	,project_name TEXT NOT NULL
	,starting_date DATE NOT NULL
	,ending_date DATE
	,PRIMARY KEY(project_id),FOREIGN KEY (project_id) REFERENCES project(project_id),FOREIGN KEY (main_pi_id) REFERENCES faculty(id)
);



CREATE TABLE normal_pi(
project_id INT NOT NULL
,pi_id INT NOT NULL
,FOREIGN KEY (project_id) REFERENCES project(project_id),FOREIGN KEY (pi_id) REFERENCES faculty(id)

);


CREATE TABLE budget(
	project_id INT NOT NULL
	,budget_type TEXT NOT NULL
	,budget_head_id INT NOT NULL
	,budget_amount INT NOT NULL
	,FOREIGN KEY(project_id) REFERENCES project(project_id), FOREIGN KEY (budget_head_id) REFERENCES faculty(id)
);

CREATE TABLE expenditure(
    request_id INTEGER NOT NULL
    ,project_id INTEGER NOT NULL
    ,expenditure_type TEXT NOT NULL
    ,cost_per_unit INTEGER NOT NULL
    ,num_of_units INTEGER NOT NULL
    ,FOREIGN KEY (project_id) REFERENCES project(project_id)
);

CREATE TABLE decisions_trail(
    request_id INTEGER NOT NULL 
    ,project_id INTEGER NOT NULL
    ,pi_id INTEGER NOT NULL
    ,decision_maker_id INTEGER NOT NULL
    ,date_of_decision DATE 
    ,comments TEXT NOT NULL
    , FOREIGN KEY (pi_id)   REFERENCES  faculty(id)
    , FOREIGN KEY (project_id) REFERENCES project(project_id)
);


CREATE TABLE rejected_requests(
    request_id INTEGER NOT NULL 
    ,expenditure_type TEXT NOT NULL
    ,cost_per_unit INTEGER NOT NULL
    ,num_of_units INTEGER NOT NULL
    ,last_holder_id INTEGER NOT NULL

    ,FOREIGN KEY (last_holder_id) REFERENCES faculty(id)
);

CREATE TABLE request_path(
    designation TEXT
    ,path TEXT[]
);

CREATE TABLE current_request(
    request_id SERIAL NOT NULL
    ,project_id INTEGER NOT NULL
    ,pi_id INTEGER NOT NULL 
    ,pi_designation TEXT NOT NULL
    ,current_holder_id INTEGER NOT NULL 
    ,current_holder_designation TEXT NOT NULL
    ,cost_per_unit INTEGER NOT NULL
    ,num_of_units INTEGER NOT NULL
    ,expenditure_type TEXT NOT NULL
    ,comments TEXT NOT NULL

    ,FOREIGN KEY (project_id) REFERENCES project(project_id)
);





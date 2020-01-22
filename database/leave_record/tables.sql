
CREATE TABLE leave_pending(
application_id SERIAL
,sender_id INT NOT NULL
,sender_designation VARCHAR(20) NOT NULL
,current_holder_id INT NOT NULL
,current_holder_designation VARCHAR(20) NOT NULL
,comments TEXT
, date_of_leave DATE
);




CREATE TABLE paper_trail(
application_id INTEGER
,action_taker_id INT NOT NULL
,action_taker_designation TEXT
,action TEXT
,comments TEXT
,date_of_action DATE 
, date_of_leave DATE
);



CREATE TABLE finalised_leaves(
application_id INTEGER
,original_sender_id INT NOT NULL
,final_holder_id INT NOT NULL
, final_holder_designation TEXT
,final_result TEXT NOT NULL
, date_of_leave DATE
, final_comment TEXT

);


CREATE TABLE path_table(
designation VARCHAR(20)
,path TEXT [] 
);


CREATE TABLE leave_per_year(
	leave INT DEFAULT 40;
);


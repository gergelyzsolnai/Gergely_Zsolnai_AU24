begin;

create database if not exists political_campaign;

commit;

begin;
create table address (
	address_id serial primary key,
	country text not null,
	city text not null,
	zip_code text not null,
	address text not null
	);
commit;

begin;

create table if not exists voter (
	voter_id SERIAL primary KEY,
	address_id INT not NULL,
	first_name VARCHAR(50) not null,
	last_name VARCHAR(50) not null,
	gender CHAR(1) not null, check(gender in ('M', 'F')), --checks if its filled with "M" or "F", otherwise it gets error.
	email VARCHAR(250) unique not null,
	phone VARCHAR(15) unique not null,
	registration_date DATE not null default current_date check (registration_date >= '2000-01-01'),  --checks if the reg.date is higher than 2000.01.01.
	CONSTRAINT address_Fkey FOREIGN KEY (address_id) REFERENCES address (address_id),
	constraint check_email_format check (email like '%@%')  --Checking wether the email is proper email address
	);
commit;

begin;

create table if not exists contributor (
	contributor_id SERIAL primary KEY,
	first_name VARCHAR(50) not null,
	last_name VARCHAR(50) not null,
	email VARCHAR(250) unique not null,
	phone VARCHAR(15) unique not null,
	donation_amount DECIMAL(10,2) NOT NULL CHECK(donation_amount > 0), --checks if the donation amount is higher than 0.
	donation_date DATE not null default current_date check (donation_date >= '2000-01-01'), --checks if the donation date is higher than 2000.01.01.
	constraint check_email_format check (email like '%@%')  --Checking wether the email is proper email address
);
commit;

begin;

create table if not exists campaign (
	campaign_id SERIAL primary KEY,
	name VARCHAR(100) not null,
	start_date DATE not null,
	end_date DATE CHECK (end_date >= start_date), --checks, because end_date must be equal or higher than the start_date is higher than 2000.01.01.
	is_active BOOLEAN default (TRUE) 
);
commit;

begin;

create table if not exists campaign_contribution (
	campaign_contribution_id SERIAL primary KEY,
	campaign_id INT not null,
	contributor_id INT not null,
	contribution_amount DECIMAL(10,2) NOT NULL CHECK(contribution_amount > 0), --checks if the contribution amount is positive mumber
	contribution_date DATE not null default CURRENT_DATE check (contribution_date >= '2000-01-01'), --checks if the contribution date is higher than 2000.01.01.
	CONSTRAINT campaign_Fkey FOREIGN KEY (campaign_id) REFERENCES campaign (campaign_id),
	CONSTRAINT contributor_Fkey FOREIGN KEY (contributor_id) REFERENCES contributor (contributor_id)
);
commit;

begin;

create table if not exists finance (
	finance_id SERIAL primary KEY,
	campaign_id INT not null,
	expense_description text not NULL,
	expense_amount DECIMAL(10,2) not null check (expense_amount > 0), --checks if the contribution amount is positive mumber
	transactional_date TIMESTAMP not null default CURRENT_TIMESTAMP,  --donation_date must be filled, default is the current date and time, when the financial transaction happened
	CONSTRAINT campaign_Fkey FOREIGN KEY (campaign_id) REFERENCES campaign (campaign_id)
);
commit;

begin;

create table if not exists contribution_finance (
	contributor_id INT not null,
	finance_id INT not null,
	CONSTRAINT contributor_Fkey FOREIGN KEY (contributor_id) REFERENCES contributor (contributor_id),
	CONSTRAINT finance_Fkey FOREIGN KEY (finance_id) REFERENCES finance (finance_id),
	CONSTRAINT contribution_finance_Pkey PRIMARY KEY (contributor_id, finance_id)  --The primary key is the congtributor_id and the finance_id together. We don't need a contribution_finance_id to get the primary key.
);
commit;

begin;

CREATE TABLE if not exists event (
	event_id Serial PRIMARY KEY,
	campaign_id INT not null,
	event_type TEXT NOT NULL CHECK (event_type IN ('rally', 'town_hall', 'debate', 'social_media')), --event_type must be one of the listed events, there is no default
	event_date TIMESTAMP not null,
	location VARCHAR(250),
	description text,
	CONSTRAINT campaign_Fkey FOREIGN KEY (campaign_id) REFERENCES campaign (campaign_id)
);
commit;

begin;

create table if not exists volunteer (
	volunteer_id Serial PRIMARY KEY,
	address_id INT not null,
	first_name VARCHAR(50) not null,
	last_name VARCHAR(50) not null,
	gender CHAR(1) not null, check(gender in ('M', 'F')), --checks if its filled with "M" or "F", otherwise it gets error.
	email VARCHAR(250) unique not null,
	phone VARCHAR(15) unique not null,
	availability BOOLEAN not null default true,
	role VARCHAR(50),
	CONSTRAINT address_Fkey FOREIGN KEY (address_id) REFERENCES address (address_id),
	constraint check_email_format check (email like '%@%')  --Checking wether the email is proper email address
);
commit;

begin;

create table if not exists survey (
	survey_id Serial PRIMARY KEY,
	campaign_id INT not null,
	survey_name VARCHAR(150) not null,
	survey_date DATE not null default current_date,
	CONSTRAINT campaign_Fkey FOREIGN KEY (campaign_id) REFERENCES campaign (campaign_id)
);
commit;

begin;

create table if not exists survey_question (
	question_id Serial PRIMARY KEY,
	survey_id INT not null,
	question VARCHAR(250) not null,
	type TEXT NOT NULL CHECK (type IN ('yes_no', 'scale', 'multiple_choice', 'rating', 'text')), --type must be one of the listed questionnaire types, there is not default
	CONSTRAINT survey_Fkey FOREIGN KEY (survey_id) REFERENCES survey (survey_id)
);
commit;

begin;

create table if not exists survey_response (
	response_id serial primary key,
	question_id INT not null,
	voter_id INT not null,
	response VARCHAR(250) not null,
	CONSTRAINT question_Fkey FOREIGN KEY (question_id) REFERENCES survey_question (question_id),
	CONSTRAINT voter_Fkey FOREIGN KEY (voter_id) REFERENCES voter (voter_id)
);
commit;

begin;

create table if not exists measure_event (
	measure_event_id serial primary key,
	event_type TEXT NOT NULL CHECK (event_type IN ('rally', 'town_hall', 'debate', 'survey', 'other')), --event_type must be one of the listed measure events, there is not default
	event_date TIMESTAMP not NULL,
	description TEXT
);
commit;

begin;

create table if not exists opponent_measure (
	measure_id serial primary key,
	measure_event_id INT not null,
	voter_id INT not null,
	opponent_strength INT NOT NULL CHECK (opponent_strength >= 0 AND opponent_strength <= 10), --checking if the number is between 0 and 10.
	public_opinion_score INT not null check(public_opinion_score >= 0 AND public_opinion_score <= 10), --checking if the number is between 0 and 10.
	feedback text,
	CONSTRAINT measure_event_Fkey FOREIGN KEY (measure_event_id) REFERENCES measure_event (measure_event_id),
	CONSTRAINT voter_Fkey FOREIGN KEY (voter_id) REFERENCES voter (voter_id)	
);
commit;

begin;

begin;

create table if not exists event_participant (
	event_participant_id serial primary key,
	event_id INT not null,
	volunteer_id INT not null,
	unique (event_id, volunteer_id), --unique, because the volunteer paricipates on an event and it is unique key combination
	CONSTRAINT volunteer_Fkey FOREIGN KEY (volunteer_id) REFERENCES volunteer (volunteer_id),
	CONSTRAINT event_Fkey FOREIGN KEY (event_id) REFERENCES event (event_id)
);

commit;


alter table address add column record_ts DATE not null default CURRENT_DATE;
alter table voter add column record_ts DATE not null default CURRENT_DATE;
alter table contributor add column record_ts DATE not null default CURRENT_DATE;
alter table campaign add column record_ts DATE not null default CURRENT_DATE;
alter table campaign_contribution add column record_ts DATE not null default CURRENT_DATE;
alter table finance add column record_ts DATE not null default CURRENT_DATE;
alter table contribution_finance add column record_ts DATE not null default CURRENT_DATE;
alter table event add column record_ts DATE not null default CURRENT_DATE;
alter table volunteer add column record_ts DATE not null default CURRENT_DATE;
alter table survey add column record_ts DATE not null default CURRENT_DATE;
alter table survey_question add column record_ts DATE not null default CURRENT_DATE;
alter table survey_response add column record_ts DATE not null default CURRENT_DATE;
alter table measure_event add column record_ts DATE not null default CURRENT_DATE;
alter table opponent_measure add column record_ts DATE not null default CURRENT_DATE;
alter table event_participant add column record_ts DATE not null default CURRENT_DATE;

commit;

begin;

insert into address (country, city, zip_code, address)
	values 
		('Hungary', 'Szeged', '6723', 'Malom street 13/A'),
		('Hungary', 'Budapest', '1173', 'Erzsebet street 42'),
		('Hungary', 'Budapest', '1121', 'Jozsef roundway 12'),
		('Hungary', 'Békéscsaba', '6854', 'Gyula highway 32'),
		('Austria', 'Wien', 'A73_8844', 'Maria-hilfer strasse 77');
	
		
INSERT INTO voter (address_id, first_name, last_name, gender, email, phone)
	SELECT 
    	address_id, 'James', 'Jordan', 'M', 'james.jordan@example.com', '06309875641'
	FROM address 
	WHERE UPPER(country) = 'HUNGARY' 
 	 AND UPPER(city) = 'SZEGED' 
  	AND zip_code = '6723' 
 	 AND UPPER(address) = 'MALOM STREET 13/A'
  	AND NOT EXISTS (SELECT 1 FROM voter WHERE email = 'james.jordan@example.com')
	UNION ALL
	SELECT 
    	address_id, 'Chuck', 'Jones', 'M', 'chuck.jones@example.com', '06201547865'
	FROM address 
	WHERE UPPER(country) = 'HUNGARY' 
  	AND UPPER(city) = 'BUDAPEST' 
  	AND zip_code = '1173' 
  	AND UPPER(address) = 'ERZSEBET STREET 42'
  	AND NOT EXISTS (SELECT 1 FROM voter WHERE email = 'chuck.jones@example.com')
	UNION ALL
	SELECT 
    	address_id, 'Adeliene', 'Francis', 'F', 'adeliene.francis@example.com', '06709951167'
	FROM address 
	WHERE UPPER(country) = 'HUNGARY' 
  	AND UPPER(city) = 'BUDAPEST' 
  	AND zip_code = '1121' 
  	AND UPPER(address) = 'JOZSEF ROUNDWAY 12'
 	 AND NOT EXISTS (SELECT 1 FROM voter WHERE email = 'adeliene.francis@example.com');

insert into contributor (first_name, last_name, email, phone, donation_amount)
	values 
		('Frank', 'Hymenes', 'frank.hymenes@example.com', '36705847335', 500),
		('Tina', 'Smith', 'tina.smith@example.com', '06305125321', 2500),
		('Hhyman', 'Roth', 'hhyman.roth@example.com', '06308547211', 1000);


insert into campaign (name, start_date, end_date, is_active)
	values 
		('Fundraising october', '2024-10-01', '2024-10-31', FALSE),
		('Fundraising november', '2024-11-01', null, TRUE),
		('District-Level', '2024-01-01', null, TRUE);



insert into campaign_contribution (campaign_id, contributor_id, contribution_amount, contribution_date)
	values
		(
			(SELECT campaign_id FROM campaign WHERE name = 'Fundraising october'),
		 	(SELECT contributor_id FROM contributor WHERE upper(first_name) = 'FRANK' AND UPPER(last_name) = 'HYMENES'),
			500, '2024-10-10'
		),
		(
			(SELECT campaign_id FROM campaign WHERE name = 'Fundraising november'),
		 	(SELECT contributor_id FROM contributor WHERE upper(first_name) = 'TINA' AND UPPER(last_name) = 'SMITH'),
			2500, '2024-11-10'
		),
		(
			(SELECT campaign_id FROM campaign WHERE name = 'Fundraising november'),
		 	(SELECT contributor_id FROM contributor WHERE upper(first_name) = 'HHYMAN' AND UPPER(last_name) = 'ROTH'),
			2500, '2024-11-12'
		);


insert into finance (campaign_id, expense_description, expense_amount, transactional_date)
	values
		(
			(SELECT campaign_id from campaign WHERE name = 'Fundraising october'), 'Advertising', 500, '2024-10-01'
		),
		(
			(SELECT campaign_id from campaign WHERE name = 'Fundraising november'), 'Contributors event', 5000, '2024-11-15'
		);



insert into contribution_finance (contributor_id, finance_id)
	values
		( 
			(SELECT contributor_id FROM contributor WHERE upper(first_name) = 'FRANK' AND UPPER(last_name) = 'HYMENES'), 
			(SELECT finance_id FROM finance WHERE expense_description = 'Advertising' and campaign_id = (SELECT campaign_id from campaign WHERE name = 'Fundraising october'))
		),
		( 
			(SELECT contributor_id FROM contributor WHERE upper(first_name) = 'TINA' AND UPPER(last_name) = 'SMITH'), 
			(SELECT finance_id FROM finance WHERE expense_description = 'Contributors event' and campaign_id = (SELECT campaign_id from campaign WHERE name = 'Fundraising november'))
		);



insert into event (campaign_id, event_type, event_date, location, description)
	values
		(
			(SELECT campaign_id from campaign WHERE name = 'Fundraising october'), 'rally', '2024-10-01 10:00:00', 'Budapest', 'Fundraising rally in the Hősök square'
		),
		(
			(SELECT campaign_id from campaign WHERE name = 'Fundraising november'), 'town_hall', '2024-11-20 18:00:00', 'Budapest', 'Fundraising for the contriubutors event'
		);



insert into volunteer (address_id, first_name, last_name, gender, email, phone, availability, role)
	select 
		address_id, 'Michael', 'Jordan', 'M', 'michael.jordan@example.com', '06309875640', true, 'data collector'
	from address 
		WHERE UPPER(country) = 'AUSTRIA' 
 	 	AND UPPER(city) = 'WIEN' 
  		AND zip_code = 'A73_8844' 
 	 	AND UPPER(address) = 'MARIA-HILFER STRASSE 77'
  		AND NOT EXISTS (SELECT 1 FROM volunteer WHERE email = 'michael.jordan@example.com')
	UNION ALL
	select 
		address_id, 'Hugh', 'Coleman', 'M', 'hugh.coleman@example.com', '06208857412', true, 'bar staff'
	from address 
		WHERE UPPER(country) = 'HUNGARY' 
 	 	AND UPPER(city) = 'BÉKÉSCSABA' 
  		AND zip_code = '6854' 
 	 	AND UPPER(address) = 'GYULA HIGHWAY 32'
  		AND NOT EXISTS (SELECT 1 FROM volunteer WHERE email = 'hugh.coleman@example.com');



insert into survey (campaign_id, survey_name, survey_date)
	values
		(
			(select campaign_id from campaign WHERE name = 'Fundraising october'), 'October Campaign Feedback', '2024-11-02'
		),
		(
			(select campaign_id from campaign WHERE name = 'Fundraising november'), 'Contributors Event Feedback', '2024-11-22'
		);


insert into survey_question (survey_id, question, type)
	values
		(
			(SELECT survey_id from survey WHERE survey_name = 'October Campaign Feedback'),
			'do you support our campaign goals?', 'yes_no'
		),
		(
			(SELECT survey_id from survey WHERE survey_name = 'Contributors Event Feedback'),
			'How do you like our candidate', 'rating'
		);


insert into survey_response (question_id, voter_id, response)
	SELECT
		(SELECT question_id FROM survey_question WHERE question = 'do you support our campaign goals?'),
		(SELECT voter_id FROM voter WHERE upper(first_name) = 'JAMES' AND UPPER(last_name) = 'JORDAN' and email = 'james.jordan@example.com'),
		'Yes'
		WHERE NOT EXISTS (
			SELECT 1 FROM survey_response 
				WHERE question_id = (SELECT question_id FROM survey_question WHERE question = 'do you support our campaign goals?') 
				AND voter_id = (SELECT voter_id FROM voter WHERE upper(first_name) = 'JAMES' AND UPPER(last_name) = 'JORDAN' and email = 'james.jordan@example.com') 
		);

insert into survey_response (question_id, voter_id, response)
	SELECT		
		(SELECT question_id FROM survey_question WHERE question = 'do you support our campaign goals?'),
		(SELECT voter_id FROM voter WHERE upper(first_name) = 'CHUCK' AND UPPER(last_name) = 'JONES' and email = 'chuck.jones@example.com'),
		'No'
		WHERE NOT EXISTS (
			SELECT 1 FROM survey_response 
				WHERE question_id = (SELECT question_id FROM survey_question WHERE question = 'do you support our campaign goals?') 
				AND voter_id = (SELECT voter_id FROM voter WHERE upper(first_name) = 'CHUCK' AND UPPER(last_name) = 'JONES' and email = 'chuck.jones@example.com') 
		);






INSERT INTO measure_event (event_type, event_date, description)
	values
		('rally', '2024-10-08 16:00:00', 'Fidesz party rally held next to the Parlaiment'),
		('debate', '2024-11-15 18:00:00', 'Fidesz and Momentum parties debate for city election');



INSERT INTO opponent_measure (measure_event_id, voter_id, opponent_strength, public_opinion_score, feedback)
	values
		(
			(SELECT measure_event_id FROM measure_event WHERE event_type = 'rally' AND event_date = '2024-10-08 16:00:00'),
			(SELECT voter_id FROM voter WHERE upper(first_name) = 'JAMES' AND UPPER(last_name) = 'JORDAN' and email = 'james.jordan@example.com'), 2, 4, 'Very aggressive and hostile.'
		),
		(
			(SELECT measure_event_id FROM measure_event WHERE event_type = 'rally' AND event_date = '2024-10-08 16:00:00'),
			(SELECT voter_id FROM voter WHERE upper(first_name) = 'CHUCK' AND UPPER(last_name) = 'JONES' and email = 'chuck.jones@example.com'), 10, 4, 'I like his aggressiveness.'
		),
		(
			(SELECT measure_event_id FROM measure_event WHERE event_type = 'debate' AND event_date = '2024-11-15 18:00:00'),
			(SELECT voter_id FROM voter WHERE upper(first_name) = 'JAMES' AND UPPER(last_name) = 'JORDAN' and email = 'james.jordan@example.com'), 4, 8, 'It was a fair debate'
		),
		(
			(SELECT measure_event_id FROM measure_event WHERE event_type = 'debate' AND event_date = '2024-11-15 18:00:00'),
			(SELECT voter_id FROM voter WHERE upper(first_name) = 'CHUCK' AND UPPER(last_name) = 'JONES' and email = 'chuck.jones@example.com'), 6, 8, 'Our party did not win the whole debate, but we were better than the other one'
		);



insert into event_participant (event_id, volunteer_id)
	values
		(
			(SELECT event_id FROM event WHERE event_type = 'rally' AND event_date = '2024-10-01 10:00:00'),
			(SELECT volunteer_id FROM volunteer WHERE upper(first_name) = 'MICHAEL' AND UPPER(last_name) = 'JORDAN')
		),
		(
			(SELECT event_id FROM event WHERE event_type = 'town_hall' AND event_date = '2024-11-20 18:00:00'),
			(SELECT volunteer_id FROM volunteer WHERE upper(first_name) = 'HUGH' AND UPPER(last_name) = 'COLEMAN')
		);

commit;
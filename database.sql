-- NUOL Scores database (MySQL / MariaDB, XAMPP)
-- Import with phpMyAdmin (Import tab) or: mysql -u root < database.sql
CREATE DATABASE IF NOT EXISTS nuol_scores CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE nuol_scores;
SET FOREIGN_KEY_CHECKS=0;
DROP TABLE IF EXISTS class_schedule,enrollments,course_offerings,semesters,courses,student_study_type,monthly_credits,user_profiles,users,students,teachers,majors,faculties;
SET FOREIGN_KEY_CHECKS=1;

CREATE TABLE faculties(faculty_id INT AUTO_INCREMENT PRIMARY KEY,name_lao VARCHAR(150) NOT NULL,name_en VARCHAR(150) NOT NULL) ENGINE=InnoDB;
CREATE TABLE majors(major_id INT AUTO_INCREMENT PRIMARY KEY,faculty_id INT NOT NULL,name_lao VARCHAR(150) NOT NULL,name_en VARCHAR(150) NOT NULL,
 FOREIGN KEY(faculty_id) REFERENCES faculties(faculty_id) ON DELETE RESTRICT) ENGINE=InnoDB;
CREATE TABLE teachers(teacher_id INT AUTO_INCREMENT PRIMARY KEY,first_name VARCHAR(80) NOT NULL,last_name VARCHAR(80) NOT NULL DEFAULT '',faculty_id INT NULL,
 FOREIGN KEY(faculty_id) REFERENCES faculties(faculty_id) ON DELETE SET NULL) ENGINE=InnoDB;
CREATE TABLE students(student_id VARCHAR(20) PRIMARY KEY,first_name VARCHAR(80) NOT NULL,last_name VARCHAR(80) NOT NULL DEFAULT '',gender CHAR(1) NOT NULL DEFAULT 'M',
 birth_date DATE NULL,major_id INT NULL,entry_year SMALLINT NULL,phone VARCHAR(20) NOT NULL DEFAULT '',email VARCHAR(150) NOT NULL DEFAULT '',
 FOREIGN KEY(major_id) REFERENCES majors(major_id) ON DELETE SET NULL) ENGINE=InnoDB;
CREATE TABLE users(user_id INT AUTO_INCREMENT PRIMARY KEY,username VARCHAR(50) NOT NULL UNIQUE,password_hash VARCHAR(255) NOT NULL,
 role ENUM('admin','student','teacher') NOT NULL DEFAULT 'student',student_id VARCHAR(20) NULL UNIQUE,teacher_id INT NULL,
 FOREIGN KEY(student_id) REFERENCES students(student_id) ON DELETE CASCADE,
 FOREIGN KEY(teacher_id) REFERENCES teachers(teacher_id) ON DELETE SET NULL) ENGINE=InnoDB;
CREATE TABLE user_profiles(user_id INT PRIMARY KEY,display_name VARCHAR(100) NOT NULL DEFAULT '',email VARCHAR(150) NOT NULL DEFAULT '',phone VARCHAR(20) NOT NULL DEFAULT '',
 FOREIGN KEY(user_id) REFERENCES users(user_id) ON DELETE CASCADE) ENGINE=InnoDB;
CREATE TABLE monthly_credits(student_id VARCHAR(20) NOT NULL,month_no TINYINT NOT NULL,credits TINYINT NOT NULL,PRIMARY KEY(student_id,month_no),
 FOREIGN KEY(student_id) REFERENCES students(student_id) ON DELETE CASCADE) ENGINE=InnoDB;
CREATE TABLE student_study_type(student_id VARCHAR(20) PRIMARY KEY,study_type ENUM('good','normal','lazy','bad') NOT NULL DEFAULT 'normal',
 FOREIGN KEY(student_id) REFERENCES students(student_id) ON DELETE CASCADE) ENGINE=InnoDB;
CREATE TABLE courses(course_id INT AUTO_INCREMENT PRIMARY KEY,course_code VARCHAR(20) NOT NULL UNIQUE,name_lao VARCHAR(150) NOT NULL,name_en VARCHAR(150) NOT NULL,credits TINYINT NOT NULL DEFAULT 3) ENGINE=InnoDB;
CREATE TABLE semesters(semester_id INT AUTO_INCREMENT PRIMARY KEY,academic_year VARCHAR(9) NOT NULL,term TINYINT NOT NULL,is_published TINYINT(1) NOT NULL DEFAULT 0) ENGINE=InnoDB;
CREATE TABLE course_offerings(offering_id INT AUTO_INCREMENT PRIMARY KEY,course_id INT NOT NULL,semester_id INT NOT NULL,teacher_id INT NULL,
 FOREIGN KEY(course_id) REFERENCES courses(course_id) ON DELETE CASCADE,
 FOREIGN KEY(semester_id) REFERENCES semesters(semester_id) ON DELETE CASCADE,
 FOREIGN KEY(teacher_id) REFERENCES teachers(teacher_id) ON DELETE SET NULL) ENGINE=InnoDB;
CREATE TABLE enrollments(enrollment_id INT AUTO_INCREMENT PRIMARY KEY,student_id VARCHAR(20) NOT NULL,offering_id INT NOT NULL,attendance DECIMAL(5,2) NULL,midterm DECIMAL(5,2) NULL,
 assignment DECIMAL(5,2) NULL,final_exam DECIMAL(5,2) NULL,total_score DECIMAL(5,2) NULL,UNIQUE(student_id,offering_id),
 FOREIGN KEY(student_id) REFERENCES students(student_id) ON DELETE CASCADE,
 FOREIGN KEY(offering_id) REFERENCES course_offerings(offering_id) ON DELETE CASCADE) ENGINE=InnoDB;
CREATE TABLE class_schedule(schedule_id INT AUTO_INCREMENT PRIMARY KEY,offering_id INT NOT NULL,day_of_week TINYINT NOT NULL,start_time TIME NOT NULL,end_time TIME NOT NULL,room VARCHAR(30) NOT NULL DEFAULT '',
 FOREIGN KEY(offering_id) REFERENCES course_offerings(offering_id) ON DELETE CASCADE) ENGINE=InnoDB;

-- Demo data
INSERT INTO faculties(faculty_id,name_lao,name_en) VALUES(1,'ຄະນະວິທະຍາສາດທຳມະຊາດ','Faculty of Natural Sciences');
INSERT INTO majors(major_id,faculty_id,name_lao,name_en) VALUES(1,1,'Accounting','Accounting');
INSERT INTO majors(major_id,faculty_id,name_lao,name_en) VALUES(2,1,'Computer Science','Computer Science');
INSERT INTO teachers(teacher_id,first_name,last_name,faculty_id) VALUES(1,'Demo','Teacher',1);
INSERT INTO students(student_id,first_name,last_name,gender,major_id,phone,email) VALUES('2210001234','Somchai','Vongsa','M',2,'','');
INSERT INTO student_study_type VALUES('2210001234','good');
INSERT INTO monthly_credits VALUES('2210001234',1,4),('2210001234',2,3),('2210001234',3,4),('2210001234',4,3),('2210001234',5,4),('2210001234',6,3),('2210001234',7,4),('2210001234',8,3),('2210001234',9,4),('2210001234',10,4);
INSERT INTO students(student_id,first_name,last_name,gender,major_id,phone,email) VALUES('2210001235','Noy','Keomany','F',2,'','');
INSERT INTO student_study_type VALUES('2210001235','normal');
INSERT INTO monthly_credits VALUES('2210001235',2,2),('2210001235',3,2),('2210001235',4,2),('2210001235',5,3),('2210001235',6,2),('2210001235',7,3),('2210001235',8,2),('2210001235',9,2),('2210001235',10,3);
INSERT INTO students(student_id,first_name,last_name,gender,major_id,phone,email) VALUES('2210001301','Manivanh','Vongsa','F',2,'','');
INSERT INTO student_study_type VALUES('2210001301','good');
INSERT INTO monthly_credits VALUES('2210001301',1,3),('2210001301',2,4),('2210001301',3,3),('2210001301',4,4),('2210001301',5,3),('2210001301',6,4),('2210001301',7,4),('2210001301',8,4),('2210001301',9,3),('2210001301',10,4);
INSERT INTO students(student_id,first_name,last_name,gender,major_id,phone,email) VALUES('2210001302','Souksavanh','Phommasone','F',2,'','');
INSERT INTO student_study_type VALUES('2210001302','lazy');
INSERT INTO monthly_credits VALUES('2210001302',1,1),('2210001302',4,0),('2210001302',5,0),('2210001302',7,1),('2210001302',9,2),('2210001302',10,2);
INSERT INTO students(student_id,first_name,last_name,gender,major_id,phone,email) VALUES('2210001303','Khamphet','Xayavong','M',1,'','');
INSERT INTO student_study_type VALUES('2210001303','lazy');
INSERT INTO monthly_credits VALUES('2210001303',2,1),('2210001303',3,2),('2210001303',6,2),('2210001303',7,2),('2210001303',9,1),('2210001303',10,1);
INSERT INTO students(student_id,first_name,last_name,gender,major_id,phone,email) VALUES('2210001304','Sengdao','Chanthavong','F',2,'','');
INSERT INTO student_study_type VALUES('2210001304','good');
INSERT INTO monthly_credits VALUES('2210001304',1,3),('2210001304',2,3),('2210001304',3,4),('2210001304',6,3),('2210001304',7,4),('2210001304',8,3),('2210001304',9,3),('2210001304',10,4);
INSERT INTO students(student_id,first_name,last_name,gender,major_id,phone,email) VALUES('2210001305','Bounmy','Phommasone','M',2,'','');
INSERT INTO student_study_type VALUES('2210001305','bad');
INSERT INTO monthly_credits VALUES('2210001305',1,0),('2210001305',2,0),('2210001305',3,0),('2210001305',4,1),('2210001305',5,0),('2210001305',6,0),('2210001305',7,0),('2210001305',8,0),('2210001305',9,1),('2210001305',10,0);
INSERT INTO students(student_id,first_name,last_name,gender,major_id,phone,email) VALUES('2210001306','Vilayvone','Sayavong','F',1,'','');
INSERT INTO student_study_type VALUES('2210001306','good');
INSERT INTO monthly_credits VALUES('2210001306',1,4),('2210001306',3,3),('2210001306',4,3),('2210001306',5,4),('2210001306',6,3),('2210001306',7,4),('2210001306',8,3),('2210001306',9,3),('2210001306',10,4);
INSERT INTO students(student_id,first_name,last_name,gender,major_id,phone,email) VALUES('2210001307','Phonexay','Chanthavong','M',2,'','');
INSERT INTO student_study_type VALUES('2210001307','good');
INSERT INTO monthly_credits VALUES('2210001307',1,4),('2210001307',2,4),('2210001307',3,3),('2210001307',4,4),('2210001307',5,4),('2210001307',6,4),('2210001307',7,4),('2210001307',8,3),('2210001307',9,4),('2210001307',10,3);
INSERT INTO students(student_id,first_name,last_name,gender,major_id,phone,email) VALUES('2210001308','Khamla','Sisouk','F',2,'','');
INSERT INTO student_study_type VALUES('2210001308','good');
INSERT INTO monthly_credits VALUES('2210001308',2,3),('2210001308',3,4),('2210001308',4,3),('2210001308',5,3),('2210001308',6,4),('2210001308',7,3),('2210001308',8,3),('2210001308',9,3),('2210001308',10,3);
INSERT INTO students(student_id,first_name,last_name,gender,major_id,phone,email) VALUES('2210001309','Sisavath','Sayavong','M',1,'','');
INSERT INTO student_study_type VALUES('2210001309','lazy');
INSERT INTO monthly_credits VALUES('2210001309',3,1),('2210001309',5,2),('2210001309',6,1),('2210001309',8,2),('2210001309',9,1),('2210001309',10,1);
INSERT INTO students(student_id,first_name,last_name,gender,major_id,phone,email) VALUES('2210001310','Bouachanh','Xayavong','F',2,'','');
INSERT INTO student_study_type VALUES('2210001310','normal');
INSERT INTO monthly_credits VALUES('2210001310',1,3),('2210001310',2,2),('2210001310',3,2),('2210001310',4,2),('2210001310',5,3),('2210001310',6,3),('2210001310',7,2),('2210001310',8,3),('2210001310',9,2),('2210001310',10,2);
INSERT INTO students(student_id,first_name,last_name,gender,major_id,phone,email) VALUES('2210001311','Chanthavone','Vongsa','F',2,'','');
INSERT INTO student_study_type VALUES('2210001311','normal');
INSERT INTO monthly_credits VALUES('2210001311',1,3),('2210001311',2,2),('2210001311',3,3),('2210001311',4,3),('2210001311',5,3),('2210001311',6,2),('2210001311',8,2),('2210001311',9,3),('2210001311',10,2);
INSERT INTO students(student_id,first_name,last_name,gender,major_id,phone,email) VALUES('2210001312','Anousith','Inthavong','M',1,'','');
INSERT INTO student_study_type VALUES('2210001312','lazy');
INSERT INTO monthly_credits VALUES('2210001312',2,1),('2210001312',5,1),('2210001312',9,2);
INSERT INTO students(student_id,first_name,last_name,gender,major_id,phone,email) VALUES('2210001313','Nalinthone','Douangdy','F',2,'','');
INSERT INTO student_study_type VALUES('2210001313','good');
INSERT INTO monthly_credits VALUES('2210001313',1,4),('2210001313',2,3),('2210001313',3,4),('2210001313',4,4),('2210001313',5,3),('2210001313',6,4),('2210001313',7,4),('2210001313',8,3),('2210001313',9,3),('2210001313',10,4);
INSERT INTO students(student_id,first_name,last_name,gender,major_id,phone,email) VALUES('2210001314','Vannasone','Vongsa','M',2,'','');
INSERT INTO student_study_type VALUES('2210001314','normal');
INSERT INTO monthly_credits VALUES('2210001314',1,2),('2210001314',2,3),('2210001314',3,2),('2210001314',4,3),('2210001314',5,3),('2210001314',7,3),('2210001314',8,3),('2210001314',9,2),('2210001314',10,3);
INSERT INTO students(student_id,first_name,last_name,gender,major_id,phone,email) VALUES('2210001315','Viengkham','Keomany','F',1,'','');
INSERT INTO student_study_type VALUES('2210001315','lazy');
INSERT INTO monthly_credits VALUES('2210001315',1,0),('2210001315',3,0),('2210001315',4,1),('2210001315',6,0),('2210001315',10,2);
INSERT INTO students(student_id,first_name,last_name,gender,major_id,phone,email) VALUES('2210001316','Thongchanh','Douangdy','M',2,'','');
INSERT INTO student_study_type VALUES('2210001316','bad');
INSERT INTO monthly_credits VALUES('2210001316',2,0),('2210001316',3,0),('2210001316',4,0),('2210001316',6,1),('2210001316',7,2),('2210001316',8,0),('2210001316',9,0),('2210001316',10,2);
INSERT INTO students(student_id,first_name,last_name,gender,major_id,phone,email) VALUES('2210001317','Anousone','Phimmasone','F',2,'','');
INSERT INTO student_study_type VALUES('2210001317','lazy');
INSERT INTO monthly_credits VALUES('2210001317',1,1),('2210001317',3,2),('2210001317',5,0),('2210001317',7,1),('2210001317',8,2);
INSERT INTO students(student_id,first_name,last_name,gender,major_id,phone,email) VALUES('2210001318','Keovilay','Keomany','M',1,'','');
INSERT INTO student_study_type VALUES('2210001318','good');
INSERT INTO monthly_credits VALUES('2210001318',1,3),('2210001318',2,3),('2210001318',3,4),('2210001318',4,3),('2210001318',5,4),('2210001318',7,3),('2210001318',8,3),('2210001318',9,4),('2210001318',10,4);
INSERT INTO students(student_id,first_name,last_name,gender,major_id,phone,email) VALUES('2210001319','Daovone','Inthavong','F',2,'','');
INSERT INTO student_study_type VALUES('2210001319','normal');
INSERT INTO monthly_credits VALUES('2210001319',1,3),('2210001319',2,2),('2210001319',3,3),('2210001319',4,3),('2210001319',5,3),('2210001319',6,3),('2210001319',8,3),('2210001319',9,3),('2210001319',10,3);
INSERT INTO students(student_id,first_name,last_name,gender,major_id,phone,email) VALUES('2210001320','Keomany','Xayavong','F',2,'','');
INSERT INTO student_study_type VALUES('2210001320','good');
INSERT INTO monthly_credits VALUES('2210001320',1,3),('2210001320',2,4),('2210001320',3,4),('2210001320',4,4),('2210001320',5,4),('2210001320',6,4),('2210001320',7,3),('2210001320',8,3),('2210001320',9,4),('2210001320',10,3);
INSERT INTO students(student_id,first_name,last_name,gender,major_id,phone,email) VALUES('2210001321','Souliya','Sisouk','M',1,'','');
INSERT INTO student_study_type VALUES('2210001321','bad');
INSERT INTO monthly_credits VALUES('2210001321',3,1),('2210001321',5,0),('2210001321',6,1),('2210001321',7,1),('2210001321',8,1),('2210001321',9,2),('2210001321',10,1);
INSERT INTO students(student_id,first_name,last_name,gender,major_id,phone,email) VALUES('2210001322','Phetsamone','Phommasone','F',2,'','');
INSERT INTO student_study_type VALUES('2210001322','normal');
INSERT INTO monthly_credits VALUES('2210001322',1,3),('2210001322',3,2),('2210001322',4,2),('2210001322',5,2),('2210001322',6,3),('2210001322',8,3),('2210001322',9,2),('2210001322',10,2);
INSERT INTO students(student_id,first_name,last_name,gender,major_id,phone,email) VALUES('2210001323','Bounthavy','Xayavong','M',2,'','');
INSERT INTO student_study_type VALUES('2210001323','normal');
INSERT INTO monthly_credits VALUES('2210001323',1,2),('2210001323',2,2),('2210001323',3,3),('2210001323',4,3),('2210001323',5,3),('2210001323',6,2),('2210001323',7,3),('2210001323',8,2),('2210001323',9,2),('2210001323',10,3);
INSERT INTO students(student_id,first_name,last_name,gender,major_id,phone,email) VALUES('2210001324','Souphaphone','Chanthavong','F',1,'','');
INSERT INTO student_study_type VALUES('2210001324','lazy');
INSERT INTO monthly_credits VALUES('2210001324',1,1),('2210001324',2,1),('2210001324',7,1),('2210001324',9,1),('2210001324',10,1);
INSERT INTO students(student_id,first_name,last_name,gender,major_id,phone,email) VALUES('2210001325','Chanthaphone','Phommasone','M',2,'','');
INSERT INTO student_study_type VALUES('2210001325','normal');
INSERT INTO monthly_credits VALUES('2210001325',1,2),('2210001325',2,3),('2210001325',3,2),('2210001325',4,3),('2210001325',5,3),('2210001325',6,2),('2210001325',7,3),('2210001325',8,2),('2210001325',10,3);
INSERT INTO students(student_id,first_name,last_name,gender,major_id,phone,email) VALUES('2210001326','Thongsy','Sayavong','F',2,'','');
INSERT INTO student_study_type VALUES('2210001326','bad');
INSERT INTO monthly_credits VALUES('2210001326',1,0),('2210001326',2,2),('2210001326',3,0),('2210001326',4,0),('2210001326',5,2),('2210001326',6,1),('2210001326',7,0),('2210001326',9,0),('2210001326',10,1);
INSERT INTO students(student_id,first_name,last_name,gender,major_id,phone,email) VALUES('2210001327','Sompong','Chanthavong','M',1,'','');
INSERT INTO student_study_type VALUES('2210001327','normal');
INSERT INTO monthly_credits VALUES('2210001327',1,2),('2210001327',2,3),('2210001327',3,3),('2210001327',4,2),('2210001327',5,2),('2210001327',8,2),('2210001327',9,2),('2210001327',10,2);
INSERT INTO students(student_id,first_name,last_name,gender,major_id,phone,email) VALUES('2210001328','Malivan','Sisouk','F',2,'','');
INSERT INTO student_study_type VALUES('2210001328','bad');
INSERT INTO monthly_credits VALUES('2210001328',2,1),('2210001328',3,0),('2210001328',4,1),('2210001328',6,0),('2210001328',7,0),('2210001328',8,0),('2210001328',9,2),('2210001328',10,2);
INSERT INTO students(student_id,first_name,last_name,gender,major_id,phone,email) VALUES('2210001329','Ketsana','Inthavong','F',2,'','');
INSERT INTO student_study_type VALUES('2210001329','lazy');
INSERT INTO monthly_credits VALUES('2210001329',1,1),('2210001329',2,2),('2210001329',3,1),('2210001329',7,2);
INSERT INTO students(student_id,first_name,last_name,gender,major_id,phone,email) VALUES('2210001330','Lattana','Phimmasone','M',1,'','');
INSERT INTO student_study_type VALUES('2210001330','good');
INSERT INTO monthly_credits VALUES('2210001330',1,4),('2210001330',2,4),('2210001330',3,4),('2210001330',4,3),('2210001330',5,4),('2210001330',6,4),('2210001330',7,3),('2210001330',8,3),('2210001330',9,4),('2210001330',10,3);
INSERT INTO students(student_id,first_name,last_name,gender,major_id,phone,email) VALUES('2210001331','Lamphone','Vongsa','F',2,'','');
INSERT INTO student_study_type VALUES('2210001331','bad');
INSERT INTO monthly_credits VALUES('2210001331',1,2),('2210001331',2,0),('2210001331',3,2),('2210001331',5,1),('2210001331',7,2),('2210001331',9,0),('2210001331',10,0);
INSERT INTO students(student_id,first_name,last_name,gender,major_id,phone,email) VALUES('2210001332','Khampheng','Inthavong','M',2,'','');
INSERT INTO student_study_type VALUES('2210001332','normal');
INSERT INTO monthly_credits VALUES('2210001332',1,2),('2210001332',3,3),('2210001332',4,2),('2210001332',5,3),('2210001332',7,3),('2210001332',9,2),('2210001332',10,3);
INSERT INTO students(student_id,first_name,last_name,gender,major_id,phone,email) VALUES('2210001333','Oulayvone','Douangdy','F',1,'','');
INSERT INTO student_study_type VALUES('2210001333','lazy');
INSERT INTO monthly_credits VALUES('2210001333',5,0),('2210001333',6,1),('2210001333',8,1);
INSERT INTO students(student_id,first_name,last_name,gender,major_id,phone,email) VALUES('2210001334','Vilaphone','Vongsa','M',2,'','');
INSERT INTO student_study_type VALUES('2210001334','good');
INSERT INTO monthly_credits VALUES('2210001334',1,4),('2210001334',2,3),('2210001334',4,3),('2210001334',5,3),('2210001334',6,4),('2210001334',7,4),('2210001334',8,3),('2210001334',9,3),('2210001334',10,3);
INSERT INTO students(student_id,first_name,last_name,gender,major_id,phone,email) VALUES('2210001335','Sivilay','Keomany','F',2,'','');
INSERT INTO student_study_type VALUES('2210001335','bad');
INSERT INTO monthly_credits VALUES('2210001335',1,0),('2210001335',2,1),('2210001335',4,2),('2210001335',5,1),('2210001335',6,0),('2210001335',7,1),('2210001335',8,1),('2210001335',10,2);
INSERT INTO students(student_id,first_name,last_name,gender,major_id,phone,email) VALUES('2210001336','Xaysana','Douangdy','M',1,'','');
INSERT INTO student_study_type VALUES('2210001336','lazy');
INSERT INTO monthly_credits VALUES('2210001336',3,0),('2210001336',5,1),('2210001336',6,1),('2210001336',7,1),('2210001336',9,1),('2210001336',10,1);
INSERT INTO students(student_id,first_name,last_name,gender,major_id,phone,email) VALUES('2210001337','Kongkeo','Phimmasone','F',2,'','');
INSERT INTO student_study_type VALUES('2210001337','bad');
INSERT INTO monthly_credits VALUES('2210001337',2,1),('2210001337',3,0),('2210001337',4,0),('2210001337',6,0),('2210001337',7,0),('2210001337',8,0),('2210001337',9,2);
INSERT INTO students(student_id,first_name,last_name,gender,major_id,phone,email) VALUES('2210001338','Phouthone','Keomany','M',2,'','');
INSERT INTO student_study_type VALUES('2210001338','good');
INSERT INTO monthly_credits VALUES('2210001338',1,4),('2210001338',2,3),('2210001338',3,4),('2210001338',4,4),('2210001338',5,4),('2210001338',6,4),('2210001338',7,3),('2210001338',8,3),('2210001338',9,4),('2210001338',10,4);
INSERT INTO users(user_id,username,password_hash,role,student_id) VALUES(1,'admin1234','$2b$10$gLpE3kSnxvUsgsvrU7H2B.WqL0OdK31HfIe6INpFi0y9BrZrgKd8O','admin',NULL);
INSERT INTO users(user_id,username,password_hash,role,student_id) VALUES(2,'2210001234','$2b$10$HfxXbvp5c5GcNlX0n3fLkeTI1cRs88E57IvHzmyFUO8dMeXmSj4lC','student','2210001234');
INSERT INTO user_profiles(user_id,display_name) VALUES(1,'admin1234'),(2,'Somchai Vongsa');
INSERT INTO courses(course_id,course_code,name_lao,name_en,credits) VALUES(1,'CS101','C Programming','C Programming',3),(2,'CS201','Data Structures','Data Structures',3),(3,'ST101','Statistics','Statistics',3);
INSERT INTO semesters(semester_id,academic_year,term,is_published) VALUES(1,'2026-2027',1,1);
INSERT INTO course_offerings(offering_id,course_id,semester_id,teacher_id) VALUES(1,1,1,1),(2,2,1,1),(3,3,1,1);
INSERT INTO class_schedule(offering_id,day_of_week,start_time,end_time,room) VALUES(1,1,'08:00','10:00','A101'),(2,3,'10:00','12:00','A102'),(3,5,'13:00','15:00','B201');

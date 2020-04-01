-

-- Hospital Database
-- Authors: Josh Lovering & Phillip Konyeaso


/* DROP TABLE statements to remove the old tables from the prior upload */
DROP TABLE "EMPLOYEE" CASCADE CONSTRAINTS;
DROP TABLE "EQUIPMENTTYPE" CASCADE CONSTRAINTS;
DROP TABLE "ROOM" CASCADE CONSTRAINTS;
DROP TABLE "EQUIPMENT" CASCADE CONSTRAINTS;
DROP TABLE "ROOMACCESS" CASCADE CONSTRAINTS;
DROP TABLE "ROOMSERVICE" CASCADE CONSTRAINTS;
DROP TABLE "PATIENT" CASCADE CONSTRAINTS;
DROP TABLE "DOCTOR" CASCADE CONSTRAINTS;
DROP TABLE "ADMISSION" CASCADE CONSTRAINTS;
DROP TABLE "EXAMINE" CASCADE CONSTRAINTS;
DROP TABLE "STAYIN" CASCADE CONSTRAINTS;
/* DROP TABLE IF EXISTS dbo.Admission CASCADE CONSTRAINTS; */

/* CREATE TABLE statments */
CREATE TABLE Room
        (num INTEGER Primary Key,
        occupied CHAR(1) Not NULL,
        CONSTRAINT CHK_occupied CHECK (occupied='y' or occupied='n'));

CREATE TABLE Employee
        (ID CHAR(5) Primary Key,
        fName VARCHAR(15) Not NULL,
        lName VARCHAR(15) Not NULL,
        salary REAL,
        jobTitle VARCHAR(20),
        officeNum INTEGER,
        empRank VARCHAR(16) Not Null,
        supervisorID CHAR(5),
        CONSTRAINT CHK_rank CHECK (empRank='Regular Employee' OR empRank='Division Manager' OR empRank='General Manager'),
        CONSTRAINT fk_officeNum Foreign Key (officeNum) References Room(num));

CREATE TABLE EquipmentType
        (ID CHAR(5) Primary Key,
        description VARCHAR(40),
        model VARCHAR(20),
        instructions VARCHAR(40),
        numUnits INTEGER Not Null);

CREATE TABLE Equipment
        (serialID CHAR(7) Primary Key,
        typeID CHAR(5) Not NULL,
        purchaseYear INTEGER Not NULL,
        lastInspection CHAR(10),
        roomNum INTEGER,
        CONSTRAINT fk_typeID Foreign Key (typeID) References EquipmentType(ID),
        CONSTRAINT fk_roomNum Foreign Key(roomNum) References Room(num));

CREATE TABLE RoomService
        (roomNum INTEGER,
        service VARCHAR(20),
        CONSTRAINT fk_roomNumService Foreign Key (roomNum) References Room(num),
        CONSTRAINT pk_id Primary Key(roomNum, service));

CREATE TABLE RoomAccess
        (roomNum INTEGER,
        empID CHAR(5),
        Primary Key (roomNum, empID),
        CONSTRAINT fk_roomNumAccess Foreign Key (roomNum) References Room(num),
        CONSTRAINT fk_empID Foreign Key (empID) References Employee(ID));

CREATE TABLE Patient
        (SSN CHAR(11) Primary Key,
        fName VARCHAR(15),
        lName VARCHAR(15),
        telNum CHAR(11),
        address VARCHAR(20));

CREATE TABLE Doctor
        (ID CHAR(5) Primary Key,
        specialty VARCHAR(30),
        gender VARCHAR(6),
        fName VARCHAR(15) Not Null,
        lName VARCHAR(15) Not Null);

CREATE TABLE Admission
        (num INTEGER Primary Key,
        admissionDate CHAR(16),
        leaveDate CHAR(16),
        futureDate CHAR(16),
        totalPayment REAL,
        insurancePayment REAL,
        patientSSN CHAR(11),
        CONSTRAINT fk_SSNamission Foreign Key (patientSSN) References Patient(SSN));

CREATE TABLE Examine
        (doctorID CHAR(5),
        admissionNum INTEGER,
        note VARCHAR(40),
        Primary Key (doctorID, admissionNum),
        CONSTRAINT fk_didexamine Foreign Key (doctorID) References Doctor(ID),
        CONSTRAINT fk_anumexamine Foreign Key (admissionNum) References Admission(num));

CREATE TABLE StayIn(
        admissionNum INTEGER,
        roomNum INTEGER,
        startDate DATE,
        endDate DATE,
        Primary Key (admissionNum, roomNum, startDate),
        CONSTRAINT fk_anumstayin Foreign Key (admissionNum) References Admission(num),
        CONSTRAINT fk_rnumstayin Foreign Key (roomNum) References Room(num));

--------------
/* TRIGGERS */
--------------

-- if a doctor visits a patient in the ICU, they must leave a comment
CREATE OR REPLACE TRIGGER ICUmustComment
BEFORE INSERT ON Examine
FOR EACH ROW
DECLARE
  aService VARCHAR(20);
BEGIN
  SELECT service
  INTO aService
  FROM RoomService
  WHERE roomNum IN
    (SELECT roomNum
    FROM StayIn
    WHERE admissionNum = :new.admissionNum);
  IF(:new.note is NULL AND aService = 'ICU') THEN
    RAISE_APPLICATION_ERROR(-20004, 'Must leave a comment');
  END IF;
END;
/

-- insurance payment is automatically 65% of the total payment
CREATE OR REPLACE TRIGGER InsurancePayment
BEFORE UPDATE OR INSERT ON Admission
FOR EACH ROW
BEGIN
  IF (:new.insurancePayment != (:new.totalPayment * 0.65)) THEN
  :new.insurancePayment := (:new.totalPayment * 0.65);
  END IF;
END;
/

-- the futureDate for an admission to a 'Emergency' service room must be set two months later
CREATE OR REPLACE TRIGGER emergencyCheckUp
BEFORE INSERT OR UPDATE ON StayIn
FOR EACH ROW
DECLARE
    aService VARCHAR(20);
BEGIN
    SELECT service
    INTO aService
    FROM RoomService
    WHERE roomNum IN
        (SELECT roomNum
        FROM StayIn
        WHERE admissionNum = :new.admissionNum);
  IF(aService = 'Emergency') THEN
    UPDATE Admission A
      SET futureDate = ADD_MONTHS(A.admissionDate,2);
  END IF;
END;
/

-- equipment type 'CT Scanner' and 'Ultrasound' cannot be be null or before 2006
CREATE OR REPLACE TRIGGER ctscannultrasound
BEFORE INSERT OR UPDATE ON Equipment
FOR EACH ROW
DECLARE eqptID CHAR(5);
BEGIN
SELECT typeID INTO eqptID FROM Equipment WHERE typeID = :new.typeID;
  IF ((eqptID = 'Ultrasound' OR eqptID = 'CT Scanner') AND :new.purchaseYear <= 2006) THEN
    RAISE_APPLICATION_ERROR(-20004, 'Purchase year must be after 2006');
  END IF;
END;
/

/* INSERTIONS */

INSERT INTO Room (num, occupied)
VALUES (100, 'y');
INSERT INTO Room (num, occupied)
VALUES (101, 'n');
INSERT INTO Room (num, occupied)
VALUES (102, 'n');
INSERT INTO Room (num, occupied)
VALUES (103, 'n');
INSERT INTO Room (num, occupied)
VALUES (104, 'n');
INSERT INTO Room (num, occupied)
VALUES (105, 'n');
INSERT INTO Room (num, occupied)
VALUES (200, 'y');
INSERT INTO Room (num, occupied)
VALUES (300, 'y');
INSERT INTO Room (num, occupied)
VALUES (400, 'y');
INSERT INTO Room (num, occupied)
VALUES (126, 'n');
INSERT INTO Room (num, occupied)
VALUES (250, 'n');
INSERT INTO Room (num, occupied)
VALUES (251, 'y');

INSERT INTO Employee(ID, fName, lName, salary, jobTitle, officeNum, empRank, supervisorID)
VALUES ('00015', 'Johnny', 'Knox', 2104, 'CEO', 105, 'General Manager', NULL);
INSERT INTO Employee(ID, fName, lName, salary, jobTitle, officeNum, empRank, supervisorID)
VALUES ('00016', 'Thor', 'Warhammer', 2007, 'President', 105, 'General Manager', NULL);
INSERT INTO Employee(ID, fName, lName, salary, jobTitle, officeNum, empRank, supervisorID)
VALUES ('00011', 'Quinn', 'Giller', 2101, 'Trainer', 300, 'Division Manager', '00015');
INSERT INTO Employee(ID, fName, lName, salary, jobTitle, officeNum, empRank, supervisorID)
VALUES ('00012', 'Kong', 'Killer', 2002, 'Chief', 400, 'Division Manager', '00015');
INSERT INTO Employee(ID, fName, lName, salary, jobTitle, officeNum, empRank, supervisorID)
VALUES ('00013', 'Gibly', 'Giller', 2104, 'Vice President', 105, 'Division Manager', '00016');
INSERT INTO Employee(ID, fName, lName, salary, jobTitle, officeNum, empRank, supervisorID)
VALUES ('00014', 'Quincy', 'Killer', 2007, 'Leading Officer', 105, 'Division Manager', '00016');
INSERT INTO Employee(ID, fName, lName, salary, jobTitle, officeNum, empRank, supervisorID)
VALUES ('00001', 'Jim', 'Tiller', 2500, 'Chef', 100, 'Regular Employee', '00012');
INSERT INTO Employee(ID, fName, lName, salary, jobTitle, officeNum, empRank, supervisorID)
VALUES ('00002', 'Tom', 'Miller', 2600, 'Assitant', 101, 'Regular Employee', '00012');
INSERT INTO Employee(ID, fName, lName, salary, jobTitle, officeNum, empRank, supervisorID)
VALUES ('00003', 'Jeff', 'Piller', 2700, 'Secretary', 102, 'Regular Employee', '00013');
INSERT INTO Employee(ID, fName, lName, salary, jobTitle, officeNum, empRank, supervisorID)
VALUES ('00004', 'Jack', 'Niller', 2800, 'Traveler', 103, 'Regular Employee', '00013');
INSERT INTO Employee(ID, fName, lName, salary, jobTitle, officeNum, empRank, supervisorID)
VALUES ('00005', 'Jordan', 'Qiller', 2900, 'Office Worker', 104, 'Regular Employee', '00011');
INSERT INTO Employee(ID, fName, lName, salary, jobTitle, officeNum, empRank, supervisorID)
VALUES ('00006', 'Jimmy', 'Filler', 2200, 'Actor', 105, 'Regular Employee', '00011');
INSERT INTO Employee(ID, fName, lName, salary, jobTitle, officeNum, empRank, supervisorID)
VALUES ('00007', 'JJ', 'Liller', 2400, 'Office Worker', 105, 'Regular Employee', '00014');
INSERT INTO Employee(ID, fName, lName, salary, jobTitle, officeNum, empRank, supervisorID)
VALUES ('00008', 'Jojo', 'Yiller', 2300, 'Office Worker', 105, 'Regular Employee', '00014');
INSERT INTO Employee(ID, fName, lName, salary, jobTitle, officeNum, empRank, supervisorID)
VALUES ('00009', 'Joseph', 'Giller', 2100, 'Foodie', 105, 'Regular Employee', '00013');
INSERT INTO Employee(ID, fName, lName, salary, jobTitle, officeNum, empRank, supervisorID)
VALUES ('00010', 'Jake', 'Killer', 2000, 'Athlete', 200, 'Regular Employee', '00011');

INSERT INTO EquipmentType(ID, description, model, instructions, numUnits)
VALUES ('12345', 'big cutting tool', '2000', 'use carefully', 1);
INSERT INTO EquipmentType(ID, description, model, instructions, numUnits)
VALUES ('0000A', 'Ultrasound', 'Fridge', 'Plug in', 2);
INSERT INTO EquipmentType(ID, description, model, instructions, numUnits)
VALUES ('0000B', 'CT Scanner', 'Table', 'Build', 4);
INSERT INTO EquipmentType(ID, description, model, instructions, numUnits)
VALUES ('0000C', 'Evil', 'Muderer', 'Execute', 9);

INSERT INTO Equipment(serialID, typeID, purchaseYear, lastInspection, roomNum)
VALUES('A01-02X', '12345', 2017, '01/04/2006', 100);
INSERT INTO Equipment(serialID, typeID, purchaseYear, lastInspection, roomNum)
VALUES('000-0A2', '0000A', 2017, '01/04/2006', 200);
INSERT INTO Equipment(serialID, typeID, purchaseYear, lastInspection, roomNum)
VALUES('000-0B1', '0000B', 2007, '20/03/2011', 101);
INSERT INTO Equipment(serialID, typeID, purchaseYear, lastInspection, roomNum)
VALUES('000-0C1', '0000C', 2010, '09/09/1996', 102);
INSERT INTO Equipment(serialID, typeID, purchaseYear, lastInspection, roomNum)
VALUES('000-0C2', '0000C', 2011, '09/09/1996', 102);

INSERT INTO RoomService (roomNum, service)
VALUES(100, 'clean up on isle 3');
INSERT INTO RoomService (roomNum, service)
VALUES(100, 'sink access');
INSERT INTO RoomService (roomNum, service)
VALUES(105, 'pizza dispenser');
INSERT INTO RoomService (roomNum, service)
VALUES(105, 'surgery table');
INSERT INTO RoomService (roomNum, service)
VALUES(200, 'physical therapy');
INSERT INTO RoomService (roomNum, service)
VALUES(200, 'rag steamer');
INSERT INTO RoomService (roomNum, service)
VALUES(300, 'ICU');
INSERT INTO RoomService (roomNum, service)
VALUES(400, 'ICU');
INSERT INTO RoomService (roomNum, service)
VALUES(250, 'Emergency');
INSERT INTO RoomService (roomNum, service)
VALUES(251, 'Emergency');

INSERT INTO RoomAccess (roomNum, empID)
VALUES (103, '00002');
INSERT INTO RoomAccess (roomNum, empID)
VALUES (102, '00002');
INSERT INTO RoomAccess (roomNum, empID)
VALUES (101, '00002');
INSERT INTO RoomAccess (roomNum, empID)
VALUES (100, '00002');
INSERT INTO RoomAccess (roomNum, empID)
VALUES (100, '00001');
INSERT INTO RoomAccess (roomNum, empID)
VALUES (100, '00003');

INSERT INTO Patient (SSN, fName, lName, telNum, address)
VALUES('111-22-3333', 'Alley', 'Cat', '19781112222', '1 dean st');
INSERT INTO Patient(SSN, fName, lName, telNum, address)
VALUES('123-45-6789', 'Alec', 'Nerf', '14012567732', '132 Sunshine Dr.');
INSERT INTO Patient(SSN, fName, lName, telNum, address)
VALUES('123-45-6889', 'Adam', 'Aligo', '14012227732', '12 Sunshine Dr.');
INSERT INTO Patient(SSN, fName, lName, telNum, address)
VALUES('122-45-6789', 'Alice', 'Wonderland', '14014447732', '2 Sunshine Dr.');
INSERT INTO Patient(SSN, fName, lName, telNum, address)
VALUES('123-35-6789', 'Alex', 'Felm', '14012567777', '1 Darkness Dr.');
INSERT INTO Patient(SSN, fName, lName, telNum, address)
VALUES('124-45-6889', 'Alexander', 'Xcom', '14011347732', '3 Hidden Dr.');
INSERT INTO Patient(SSN, fName, lName, telNum, address)
VALUES('122-45-5789', 'Annie', 'Faw', '14014447766', '2 Food Dr.');
INSERT INTO Patient(SSN, fName, lName, telNum, address)
VALUES('123-45-0789', 'Ann', 'Cen', '14012567733', '132 Lost Dr.');
INSERT INTO Patient(SSN, fName, lName, telNum, address)
VALUES('121-45-6889', 'Amber', 'Ven', '14012227722', '12 Music Dr.');
INSERT INTO Patient(SSN, fName, lName, telNum, address)
VALUES('120-45-6789', 'Ather', 'Wall', '14014447711', '2 Party Dr.');

INSERT INTO Doctor (ID, specialty, gender, fName, lName)
VALUES ('12121', 'top chef', 'male', 'Good', 'Dctr');
INSERT INTO Doctor (ID, specialty, gender, fName, lName)
VALUES ('12122', 'head suregon', 'male', 'Doctor', 'Mario');
INSERT INTO Doctor (ID, specialty, gender, fName, lName)
VALUES ('12222', 'airbender', 'male', 'Fox', 'Falco');
INSERT INTO Doctor (ID, specialty, gender, fName, lName)
VALUES ('22222', 'calf specialist', 'n/a', 'Pika', 'Chu');
INSERT INTO Doctor (ID, specialty, gender, fName, lName)
VALUES ('33333', 'neurologist', 'female', 'Ally', 'Straw');
INSERT INTO Doctor (ID, specialty, gender, fName, lName)
VALUES ('22223', 'marine doctor', 'female', 'Betty', 'Boo');
INSERT INTO Doctor (ID, specialty, gender, fName, lName)
VALUES ('22224', 'organ specialist', 'female', 'Shelly', 'Fish');
INSERT INTO Doctor (ID, specialty, gender, fName, lName)
VALUES ('22225', 'reproductive specialist', 'male', 'Bon', 'Bon');
INSERT INTO Doctor (ID, specialty, gender, fName, lName)
VALUES ('22226', 'good guy doctor', 'male', 'Hey', 'Guy');
INSERT INTO Doctor (ID, specialty, gender, fName, lName)
VALUES ('22227', 'fracture specialist', 'male', 'Dr', 'Bones');

INSERT INTO Admission (num, admissionDate, leaveDate, futureDate, totalPayment, insurancePayment, patientSSN)
VALUES (1, '1/9/2018-01:00', '1/9/2018-02:00', '1/10/2018-01:00', 5000, 0, '123-45-6889');
INSERT INTO Admission (num, admissionDate, leaveDate, futureDate, totalPayment, insurancePayment, patientSSN)
VALUES (2, '1/10/2018-01:00', '1/10/2018-14:00', '1/11/2018-08:00', 1200, 300, '123-45-6889');
INSERT INTO Admission (num, admissionDate, leaveDate, futureDate, totalPayment, insurancePayment, patientSSN)
VALUES (3, '2/8/2018-01:00', '2/8/2018-03:00', '3/8/2018-09:00', 2000, 200, '123-45-6789');
INSERT INTO Admission (num, admissionDate, leaveDate, futureDate, totalPayment, insurancePayment, patientSSN)
VALUES (4, '3/8/2018-09:00', '3/8/2018-12:00', '4/8/2018-00:00', 2000, 12, '123-45-6789');
INSERT INTO Admission (num, admissionDate, leaveDate, futureDate, totalPayment, insurancePayment, patientSSN)
VALUES (5, '1/1/2019-07:00', '1/1/2019-07:30', '2/1/2019-14:00', 10, 8, '124-45-6889');
INSERT INTO Admission (num, admissionDate, leaveDate, futureDate, totalPayment, insurancePayment, patientSSN)
VALUES (6, '2/1/2019-14:00', '2/1/2019-21:00', '10/1/2019-07:00', 2000, 1800, '124-45-6889');
INSERT INTO Admission (num, admissionDate, leaveDate, futureDate, totalPayment, insurancePayment, patientSSN)
VALUES (7, '2/8/2019-01:00', '2/8/2019-01:01', '3/8/2019-01:00', 4000, 3000, '123-35-6789');
INSERT INTO Admission (num, admissionDate, leaveDate, futureDate, totalPayment, insurancePayment, patientSSN)
VALUES (8, '3/8/2019-01:00', '3/8/2019-07:00', '4/8/2019-16:00', 10000, 2000, '123-35-6789');
INSERT INTO Admission (num, admissionDate, leaveDate, futureDate, totalPayment, insurancePayment, patientSSN)
VALUES (9, '4/1/2019-01:00', '4/1/2019-07:00', '4/2/2019-16:00', 10000, 2000, '123-45-6789');
INSERT INTO Admission (num, admissionDate, leaveDate, futureDate, totalPayment, insurancePayment, patientSSN)
VALUES (10, '4/2/2019-16:00', '4/2/2019-20:00', '4/3/2019-10:00', 10000, 2000, '123-45-6789');
INSERT INTO Admission (num, admissionDate, leaveDate, futureDate, totalPayment, insurancePayment, patientSSN)
VALUES (11, '4/3/2019-10:00', '4/3/2019-12:00', '4/4/2019-16:00', 10000, 2000, '123-45-6789');
INSERT INTO Admission (num, admissionDate, leaveDate, futureDate, totalPayment, insurancePayment, patientSSN)
VALUES (12, '4/4/2019-16:00', '4/4/2019-20:00', '4/5/2019-10:00', 10000, 2000, '123-45-6789');
INSERT INTO Admission (num, admissionDate, leaveDate, futureDate, totalPayment, insurancePayment, patientSSN)
VALUES (13, '4/5/2019-10:00', '4/5/2019-12:00', '4/6/2019-16:00', 10000, 2000, '123-45-6789');
INSERT INTO Admission (num, admissionDate, leaveDate, futureDate, totalPayment, insurancePayment, patientSSN)
VALUES (14, '4/6/2019-16:00', '4/6/2019-20:00', '4/7/2019-10:00', 10000, 2000, '123-45-6789');
INSERT INTO Admission (num, admissionDate, leaveDate, futureDate, totalPayment, insurancePayment, patientSSN)
VALUES (15, '4/7/2019-10:00', '4/7/2019-12:00', '4/8/2019-16:00', 10000, 2000, '123-45-6889');
INSERT INTO Admission (num, admissionDate, leaveDate, futureDate, totalPayment, insurancePayment, patientSSN)
VALUES (16, '4/8/2019-16:00', '4/8/2019-20:00', '4/9/2019-10:00', 10000, 2000, '123-45-6889');
INSERT INTO Admission (num, admissionDate, leaveDate, futureDate, totalPayment, insurancePayment, patientSSN)
VALUES (17, '4/9/2019-10:00', '4/9/2019-12:00', '4/10/2019-16:00', 10000, 2000, '123-45-6889');
INSERT INTO Admission (num, admissionDate, leaveDate, futureDate, totalPayment, insurancePayment, patientSSN)
VALUES (18, '4/10/2019-16:00', '4/10/2019-20:00', '4/11/2019-10:00', 10000, 2000, '123-45-6889');
INSERT INTO Admission (num, admissionDate, leaveDate, futureDate, totalPayment, insurancePayment, patientSSN)
VALUES (19, '4/11/2019-10:00', '4/11/2019-12:00', '4/12/2019-16:00', 10000, 2000, '123-45-6889');
INSERT INTO Admission (num, admissionDate, leaveDate, futureDate, totalPayment, insurancePayment, patientSSN)
VALUES (20, '4/12/2019-16:00', '4/12/2019-20:00', '4/13/2019-10:00', 10000, 2000, '123-45-6889');
INSERT INTO Admission (num, admissionDate, leaveDate, futureDate, totalPayment, insurancePayment, patientSSN)
VALUES (21, '4/13/2019-10:00', '4/13/2019-12:00', '4/14/2019-16:00', 10000, 2000, '123-45-6889');
INSERT INTO Admission (num, admissionDate, leaveDate, futureDate, totalPayment, insurancePayment, patientSSN)
VALUES (22, '4/14/2019-16:00', '4/14/2019-20:00', '4/15/2019-10:00', 10000, 2000, '123-45-6889');

INSERT INTO StayIn(admissionNum, roomNum, startDate, endDate)
VALUES (1, 100, TO_DATE('01-09-2018 01:00:00', 'DD-MM-YYYY HH24-MI-SS'), TO_DATE('01-09-2018 01:05:00', 'DD-MM-YYYY HH24-MI-SS'));
INSERT INTO StayIn(admissionNum, roomNum, startDate, endDate)
VALUES (3, 300, TO_DATE('02-08-2018 01:00:00', 'DD-MM-YYYY HH24-MI-SS'), TO_DATE('02-08-2018 01:20:00', 'DD-MM-YYYY HH24-MI-SS'));
INSERT INTO StayIn(admissionNum, roomNum, startDate, endDate)
VALUES (3, 400, TO_DATE('02-08-2018 01:30:00', 'DD-MM-YYYY HH24-MI-SS'), TO_DATE('02-08-2018 02:00:00', 'DD-MM-YYYY HH24-MI-SS'));
INSERT INTO StayIn(admissionNum, roomNum, startDate, endDate)
VALUES (17, 300, TO_DATE('04-09-2019 10:00:00', 'DD-MM-YYYY HH24-MI-SS'), TO_DATE('04-09-2019 12:00:00', 'DD-MM-YYYY HH24-MI-SS'));
INSERT INTO StayIn(admissionNum, roomNum, startDate, endDate)
VALUES (18, 300, TO_DATE('04-10-2019 16:00:00', 'DD-MM-YYYY HH24-MI-SS'), TO_DATE('04-10-2019 22:00:00', 'DD-MM-YYYY HH24-MI-SS'));
INSERT INTO StayIn(admissionNum, roomNum, startDate, endDate)
VALUES (18, 400, TO_DATE('04-10-2019 22:00:00', 'DD-MM-YYYY HH24-MI-SS'), TO_DATE('04-11-2019 01:30:00', 'DD-MM-YYYY HH24-MI-SS'));
INSERT INTO StayIn(admissionNum, roomNum, startDate, endDate)
VALUES (19, 300, TO_DATE('04-11-2019 12:00:00', 'DD-MM-YYYY HH24-MI-SS'), TO_DATE('04-11-2019 12:30:00', 'DD-MM-YYYY HH24-MI-SS'));
INSERT INTO StayIn(admissionNum, roomNum, startDate, endDate)
VALUES (19, 400, TO_DATE('04-11-2019 12:31:00', 'DD-MM-YYYY HH24-MI-SS'), TO_DATE('04-11-2019 12:40:00', 'DD-MM-YYYY HH24-MI-SS'));
INSERT INTO StayIn(admissionNum, roomNum, startDate, endDate)
VALUES (22, 250, TO_DATE('14/04/2019 16:30:00', 'DD-MM-YYYY HH24-MI-SS'), TO_DATE('15-04-2019 02:00:00', 'DD-MM-YYYY HH24-MI-SS'));

INSERT INTO Examine(doctorID, admissionNum, note)
VALUES ('12121', 6, 'overweight');
INSERT INTO Examine(doctorID, admissionNum, note)
VALUES ('22222', 7, 'antibiotic prescription');
INSERT INTO Examine(doctorID, admissionNum, note)
VALUES ('22222', 8, 'nice hair');
INSERT INTO Examine(doctorID, admissionNum, note)
VALUES ('22222', 9, 'very nice hair');
INSERT INTO Examine(doctorID, admissionNum, note)
VALUES ('33333', 10, 'overloaddoccomment1');
INSERT INTO Examine(doctorID, admissionNum, note)
VALUES ('33333', 11, 'overloaddoccomment2');
INSERT INTO Examine(doctorID, admissionNum, note)
VALUES ('33333', 12, 'overloaddoccomment3');
INSERT INTO Examine(doctorID, admissionNum, note)
VALUES ('33333', 13, 'overloaddoccomment4');
INSERT INTO Examine(doctorID, admissionNum, note)
VALUES ('33333', 14, 'overloaddoccomment5');
INSERT INTO Examine(doctorID, admissionNum, note)
VALUES ('33333', 15, 'overloaddoccomment6');
INSERT INTO Examine(doctorID, admissionNum, note)
VALUES ('33333', 16, 'overloaddoccomment7');
INSERT INTO Examine(doctorID, admissionNum, note)
VALUES ('33333', 17, 'overloaddoccomment8');
INSERT INTO Examine(doctorID, admissionNum, note)
VALUES ('33333', 18, 'overloaddoccomment9');
INSERT INTO Examine(doctorID, admissionNum, note)
VALUES ('33333', 19, 'overloaddoccomment10');
INSERT INTO Examine(doctorID, admissionNum, note)
VALUES ('12222', 22, 'overloaddoccomment11');

-----------
/* VIEWS */
-----------

CREATE or REPLACE VIEW CriticalCases AS
  (SELECT P.SSN AS Patient_SSN, P.fName AS firstName, P.lName AS lastName, cases.numberOfAdmissionsToICU
  FROM Patient P,
  (SELECT Patient.SSN, COUNT(*) AS numberOfAdmissionsToICU
      FROM StayIn, Patient, Admission
      WHERE StayIn.roomNum IN
        (SELECT roomNum
        FROM RoomService
        WHERE RoomService.service = 'ICU')
      AND Patient.SSN = Admission.PatientSSN
      AND StayIn.admissionNum = Admission.num
      GROUP BY Patient.SSN) cases
  WHERE cases.numberOfAdmissionsToICU >= 2
  AND cases.SSN = P.SSN);


-- need to speiciy unique
-- CREATE or REPLACE VIEW DoctorsLoad AS
--   SELECT E.doctorID, D.gender, count(E.admissionNum) AS load
--   FROM Examine E, Doctor D
--   WHERE D.ID = E.doctorID
--   GROUP BY E.doctorID, D.gender
--   HAVING count(E.admissionNum) > 10;

-- CREATE or REPLACE VIEW DoctorsLoad AS
--   SELECT E.doctorID, D.gender,
--   FROM Examine E, Doctor D
--   WHERE D.ID = E.doctorID
--   GROUP BY E.doctorID, D.gender
--   HAVING count(E.admissionNum) > 10;

-- THEN load := 'Overloaded' ELSE LOAD := 'Underloaded'

-- Report the critical-case patients with num admissions to ICU greater than 4.
  SELECT *
  FROM CriticalCases
  WHERE numberOfAdmissionsToICU > 4;

--Report female overloaded doctors.

--Report comments inserted by underloaded doctors when examining critical-case patients.


--------------
/* TRIGGERS */
--------------

-- regular employees must have their supervisors as division managers. Each regular employee must have a supervisor
-- CREATE OR REPLACE TRIGGER regMustHaveSupervisor
-- BEFORE INSERT OR UPDATE ON EMPLOYEE
-- FOR EACH ROW
-- DECLARE
--   aEmpRank VARCHAR(16);
-- BEGIN
--   SELECT empRank
--   INTO aEmpRank
--   FROM Employee
--   WHERE ID = :new.supervisorID;
--   IF(:new.empRank = 'Regular Employee' AND aEmpRank != 'Division Manager') THEN
--     RAISE_APPLICATION_ERROR(-20004, 'Invalid Supervisor - Must be a Division Manager');
--   END IF;
-- END;
-- /

-- make sure general managers' supervisorid = NULL
-- make sure district managers' supervisorid = a general manager
-- and make sure regular employees' eupervisorid = a district manager
CREATE OR REPLACE TRIGGER empsAndSupervisors
BEFORE INSERT OR UPDATE ON EMPLOYEE
FOR EACH ROW
DECLARE
    supervisorRank VARCHAR2(16);
BEGIN
  IF(:new.empRank = 'General Manager') THEN
  (:new.supervisorID := NULL AND supervisorRank := NULL);
  ELSE
  (SELECT Employee.empRank
  INTO supervisorRank
  FROM Employee
  WHERE Employee.ID = :new.supervisorID)
  END IF;
  IF(:new.empRank = 'Regular Employee' AND supervisorrank != 'District Manager') THEN
    RAISE_APPLICATION_ERROR(-20004, 'Invalid Supervisor - Must be a Division Manager');
  END IF;
END;
/

CREATE OR REPLACE VIEW aLP AS
(SELECT E.note, D.lName
FROM Examine E, Doctor D
WHERE E.doctorID = D.ID);

--printout visit info after admission leave time is set
CREATE OR REPLACE TRIGGER admissionLeavePrintout
BEFORE UPDATE ON Admission
FOR EACH ROW
DECLARE
  fName VARCHAR(15);
  lName VARCHAR(15);
  address VARCHAR(15);
BEGIN
  SELECT fName
  INTO fName
  FROM Patient
  WHERE SSN =
    (SELECT patientSSN
    FROM Admission
    WHERE leaveDate = :old.leaveDate);
  SELECT lName
  INTO lName
  FROM Patient
  WHERE SSN =
    (SELECT patientSSN
    FROM Admission
    WHERE leaveDate = :old.leaveDate);
  SELECT address
  INTO address
  FROM Patient
  WHERE SSN =
    (SELECT patientSSN
    FROM Admission
    WHERE leaveDate = :old.leaveDate);
DBMS_OUTPUT.PUT_LINE(fName, lName, address,
  (SELECT *
  FROM aLP
  WHERE Examine.admissionNum = Admission.Num))
END;
/

/* QUERIES */


/* Q1: Report the hospital rooms (the room number) that are currently occupied.*/
SELECT num
FROM Room
WHERE occupied = 'y';

/* Q2: For a given division manager (say, ID = 10), report all regular employees that are supervised by this manager. Display the employees ID, names, and salary.*/
SELECT ID,  fName, lName, salary
FROM Employee
WHERE supervisorID = '00011'
AND empRank = 'Regular Employee';

/* Q3: For each patient, report the sum of amounts paid by the insurance company for that patient, i.e., report the patients SSN, and the sum of insurance payments over all visits.*/
SELECT patientSSN, sum(insurancePayment) AS sum
FROM Admission
Group By patientSSN;

-- /* Q4: Report the number of visits done for each patient, i.e., for each patient, report the patient SSN, first and last names, and the count of visits done by this patient.*/
-- SELECT A.patientSSN, P.fName, P.lName, count(A.num) as visits
-- FROM Admission A
-- INNER JOIN Patient P ON A.patientSSN = P.SSN
-- Group By A.patientSSN, P.SSN;

/* Q5: Report the room number that has an equipment unit with serial number ‘A01-02X’.*/
SELECT roomNum
FROM Equipment
WHERE serialID = 'A01-02X';

/* Q6: Report the employee who has access to the largest number of rooms. We need the employee ID, and the number of rooms (s)he can access*/
SELECT ra2.empID, count(ra2.roomNum) AS Accessibility
FROM RoomAccess ra2, (SELECT empID, count(roomNum) as CNT
                     FROM RoomAccess
                    Group By empID) ra1
GROUP BY ra1.empID, ra2.empID
Order By Accessibility DESC
OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY;

/* Q7: Report the number of regular employees, division managers, and general managers in the hospital*/
SELECT empRank As Type, count(*) As Count
FROM Employee
Group By empRank;

/* Q8: For patients who have a scheduled future visit (which is part of their most recent visit), report that patient (SSN, and first and last names) and the visit date. Do not report patients who do not have scheduled visit.*/
SELECT A.patientSSN as SSN, A.futureDate, P.fName, P.lName
FROM Patient P
Inner Join Admission A
on P.SSN = A.patientSSN
Group By SSN
Order By SSN DESC;

/* Q9: For each equipment type that has more than 3 units, report the equipment type ID, model, and the number of units this type has.*/
SELECT ID, model, numUnits
FROM EquipmentType
WHERE numUnits > 3;

/* Q10: Report the date of the coming future visit for patient with SSN = 111-22-3333*/
SELECT futureDate
FROM Admission
WHERE patientSSN = '111-22-3333'
Order By admissionDate DESC
FETCH NEXT 1 ROWS ONLY;

/* Q11: For patient with SSN = 111-22-3333, report the doctors (only ID) who have examined this patient more than 2 times*/
SELECT E.doctorID
FROM Examine E, (SELECT num
                 FROM Admission
                 WHERE patientSSN = '111-22-3333') AdNums
WHERE E.admissionNum = AdNums.num
Group By E.doctorID
Having count(E.doctorID) > 2;

-- /* Q12: Report the equipment types (only the ID) for which the hospital has purchased equipments (units) in both 2010 and 2011. Do not report duplication.*/
-- SELECT typeID
-- FROM Equipment
-- WHERE purchaseYear = '2010' AND purchaseYear = '2011';


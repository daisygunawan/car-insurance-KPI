CREATE DATABASE "CarInsurance" /*!40100 DEFAULT CHARACTER SET utf8mb3 COLLATE utf8mb3_bin */ /*!80016 DEFAULT ENCRYPTION='N' */;

use CarInsurance;

CREATE TABLE "Claims" (
  "claimID" int NOT NULL,
  "policyID" int NOT NULL,
  "date_of_incident" date DEFAULT NULL,
  "description" varchar(500) COLLATE utf8mb3_bin DEFAULT NULL,
  "claim_amount" double DEFAULT NULL,
  PRIMARY KEY ("claimID"),
  FOREIGN KEY(policyID) REFERENCES Policy(policyID)
);

CREATE TABLE "Customer" (
  "customerID" int NOT NULL,
  "cu_name" varchar(250) COLLATE utf8mb3_bin DEFAULT NULL,
  "cu_address" varchar(350) COLLATE utf8mb3_bin DEFAULT NULL,
  "cu_contact" varchar(50) COLLATE utf8mb3_bin DEFAULT NULL,
  "vehicle_brand" varchar(100) COLLATE utf8mb3_bin DEFAULT NULL,
  "vehicle_model" varchar(100) COLLATE utf8mb3_bin DEFAULT NULL,
  "vehicle_year" int DEFAULT NULL,
  "assigned_employee" int DEFAULT NULL,
  PRIMARY KEY ("customerID"),
  FOREIGN KEY(assigned_employee) REFERENCES Employees(employeeID)
);

CREATE TABLE "Employees" (
  "employeeID" int NOT NULL,
  "em_name" varchar(250) COLLATE utf8mb3_bin DEFAULT NULL,
  "em_role" varchar(250) COLLATE utf8mb3_bin DEFAULT NULL,
  PRIMARY KEY ("employeeID")
);

CREATE TABLE "Milestones" (
  "milestoneID" int NOT NULL,
  "claimID" int DEFAULT NULL,
  "milestone" varchar(150) COLLATE utf8mb3_bin DEFAULT NULL,
  "milestone_date" date DEFAULT NULL,
  "status" varchar(200) COLLATE utf8mb3_bin DEFAULT NULL,
  "assigned_to" int DEFAULT NULL,
  "estimated_completion_date" date DEFAULT NULL,
  "completion_date" date DEFAULT NULL,
  "notes" varchar(500) COLLATE utf8mb3_bin DEFAULT NULL,
  PRIMARY KEY ("milestoneID"),
  FOREIGN KEY(claimID) REFERENCES Claims(claimID),
  FOREIGN KEY(assigned_to) REFERENCES Employees(employeeID)
);

CREATE TABLE "Policy" (
  "policyID" int NOT NULL,
  "customerID" int DEFAULT NULL,
  "policy_typeID" int DEFAULT NULL,
  "start_date" date DEFAULT NULL,
  "end_date" date DEFAULT NULL,
  "premium_amount" double DEFAULT NULL,
  "coverage_amount" double DEFAULT NULL,
  PRIMARY KEY ("policyID"),
  FOREIGN KEY(customerID) REFERENCES Customer(customerID),
  FOREIGN KEY(policy_typeID) REFERENCES Policy_Types(policy_typeID)
  
);

CREATE TABLE "Policy_Types" (
  "policy_typeID" int NOT NULL,
  "policy_type" varchar(350) COLLATE utf8mb3_bin DEFAULT NULL,
  PRIMARY KEY ("policy_typeID")
);

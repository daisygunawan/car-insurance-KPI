use CarInsurance;
-- TOTAL CLAIMS
CREATE VIEW vw_total_claims AS
SELECT 
    m.status, 
    COUNT(DISTINCT c.claimID) AS total_claims
FROM 
    Milestones m
JOIN 
    Claims c ON m.claimID = c.claimID
GROUP BY 
    m.status;


-- EMPLOYEE PERFORMANCE BASED ON LATE DAYS
CREATE VIEW vw_Employee_Performance AS
SELECT 
    e.em_name AS employee_name,
    m.claimID,
    m.milestone,
    m.milestone_date,
    m.estimated_completion_date,
    m.completion_date,
    DATEDIFF(m.completion_date, m.estimated_completion_date) AS days_late
FROM 
    Milestones m
JOIN 
    Employees e ON m.assigned_to = e.employeeID
WHERE 
    m.completion_date IS NOT NULL
    AND m.estimated_completion_date IS NOT NULL
    AND DATEDIFF(m.completion_date, m.estimated_completion_date) > 0 -- Only include positive days_late
ORDER BY 
    days_late ASC;
    
    
-- EMPLOYEE PERFORMANCE BASED ON LATE DAYS SUMMARY
CREATE VIEW vw_Employee_Late_Days_Summary AS
SELECT 
    e.em_name AS employee_name,
    SUM(
        CASE 
            WHEN m.completion_date IS NOT NULL 
                 AND m.estimated_completion_date IS NOT NULL
                 AND DATEDIFF(m.completion_date, m.estimated_completion_date) > 0 
            THEN DATEDIFF(m.completion_date, m.estimated_completion_date) 
            ELSE 0 
        END
    ) AS total_late_days
FROM 
    Milestones m
JOIN 
    Employees e ON m.assigned_to = e.employeeID
GROUP BY 
    e.em_name
ORDER BY 
    total_late_days DESC;



-- MILESTONE ACHIEVED
CREATE VIEW vw_Milestones_Achieved AS
SELECT 
    m.milestone,
    COUNT(DISTINCT m.claimID) AS total_claims_at_milestone,
    (COUNT(DISTINCT m.claimID) / 
     (SELECT COUNT(*) FROM Claims WHERE Claims.claimID IS NOT NULL)) * 100 AS percentage_achieved
FROM 
    Milestones m
GROUP BY 
    m.milestone
ORDER BY 
    percentage_achieved DESC;
    
    
-- AVERAGE TIME PER MILESTONE
CREATE VIEW vw_Average_Time_Per_Milestone AS
SELECT 
    m.milestone,
    AVG(DATEDIFF(m.milestone_date, 
                 (SELECT MAX(m1.milestone_date) 
                  FROM Milestones m1 
                  WHERE m1.claimID = m.claimID 
                    AND m1.milestone < m.milestone))) AS average_days_to_reach
FROM 
    Milestones m
GROUP BY 
    m.milestone
ORDER BY 
    average_days_to_reach;
    
    
-- CLAIMS STUCK/DELAYED AT MILESTONES
CREATE VIEW vw_Claims_Delayed_at_Milestones AS
SELECT 
    m.claimID,
    m.milestone,
    m.milestone_date,
    m.estimated_completion_date,
    m.completion_date,
    m.status AS milestone_status,
    CASE 
        WHEN m.completion_date IS NULL THEN 'Stuck: No completion date'
        WHEN DATEDIFF(m.completion_date, m.estimated_completion_date) > 0 THEN 'Delayed: Overdue completion'
        ELSE 'On Time'
    END AS delay_reason
FROM 
    Milestones m
WHERE 
    m.estimated_completion_date IS NOT NULL
    AND (m.completion_date IS NULL OR DATEDIFF(m.completion_date, m.estimated_completion_date) > 0)
ORDER BY 
    m.claimID, m.milestone_date;


-- CLAIMS BY EMPLOYEE
CREATE VIEW vw_Claims_by_Employee AS
SELECT 
    e.em_name AS employee_name,
    COUNT(DISTINCT c.claimID) AS total_claims_handled,
    COUNT(m.milestoneID) AS total_milestones_assigned,
    AVG(DATEDIFF(m.completion_date, m.milestone_date)) AS average_days_to_complete_milestone
FROM 
    Employees e
JOIN 
    Milestones m ON m.assigned_to = e.employeeID
JOIN 
    Claims c ON c.claimID = m.claimID
WHERE 
    m.completion_date IS NOT NULL
GROUP BY 
    e.em_name
ORDER BY 
    total_claims_handled DESC;

-- TOTAL CLAIMS BY POLICY TYPE
CREATE VIEW vw_Total_Claims_by_Policy_Type AS
SELECT 
    pt.policy_type AS policy_type,
    COUNT(c.claimID) AS total_claims
FROM 
    Policy p
JOIN 
    Policy_Types pt ON p.policy_typeID = pt.policy_typeID
JOIN 
    Claims c ON c.policyID = p.policyID
GROUP BY 
    pt.policy_type
ORDER BY 
    total_claims DESC;


-- AVERAGE CLAIM VALUE BY POLICY 
CREATE VIEW vw_Avg_Claim_Value_by_Policy AS
SELECT 
    pt.policy_type AS policy_type,
    AVG(c.claim_amount) AS average_claim_value
FROM 
    Policy p
JOIN 
    Policy_Types pt ON p.policy_typeID = pt.policy_typeID
JOIN 
    Claims c ON c.policyID = p.policyID
WHERE 
    c.claim_amount IS NOT NULL
GROUP BY 
    pt.policy_type
ORDER BY 
    average_claim_value DESC;


-- CLAIMS DENIED BY POLICY TYPE
CREATE VIEW vw_Claims_Denied_by_Policy_Type AS
SELECT 
    pt.policy_type AS policy_type,
    COUNT(DISTINCT c.claimID) AS denied_claims
FROM 
    Policy p
JOIN 
    Policy_Types pt ON p.policy_typeID = pt.policy_typeID
JOIN 
    Claims c ON c.policyID = p.policyID
JOIN 
    Milestones m ON m.claimID = c.claimID
WHERE 
    m.status = 'Denied'
GROUP BY 
    pt.policy_type
ORDER BY 
    denied_claims DESC;


-- CLAIMS PROCESSED BY EMPLOYEES
CREATE VIEW vw_Claims_Processed_by_Employee AS
SELECT 
    e.em_name AS employee_name,
    COUNT(DISTINCT c.claimID) AS total_claims_handled,
    COUNT(m.milestoneID) AS total_milestones_assigned,
    SUM(CASE WHEN m.completion_date IS NOT NULL THEN 1 ELSE 0 END) AS completed_claims
FROM 
    Employees e
JOIN 
    Milestones m ON m.assigned_to = e.employeeID
JOIN 
    Claims c ON c.claimID = m.claimID
GROUP BY 
    e.em_name
ORDER BY 
    total_claims_handled DESC;


-- AVERAGE TIME TO PROCESS CLAIMS BY EMPLOYEE
CREATE VIEW vw_Avg_Time_to_Process_Claims_by_Employee AS
SELECT 
    e.em_name AS employee_name,
    AVG(DATEDIFF(m.completion_date, c.date_of_incident)) AS avg_days_to_process
FROM 
    Employees e
JOIN 
    Milestones m ON m.assigned_to = e.employeeID
JOIN 
    Claims c ON c.claimID = m.claimID
WHERE 
    m.completion_date IS NOT NULL
GROUP BY 
    e.em_name
ORDER BY 
    avg_days_to_process ASC;


-- CLAIMS PENDING BY EMPLOYEE
CREATE VIEW vw_Claims_Pending_by_Employee AS
SELECT 
    e.em_name AS employee_name,
    COUNT(DISTINCT c.claimID) AS pending_claims
FROM 
    Employees e
JOIN 
    Milestones m ON m.assigned_to = e.employeeID
JOIN 
    Claims c ON c.claimID = m.claimID
WHERE 
    m.completion_date IS NULL
GROUP BY 
    e.em_name
ORDER BY 
    pending_claims DESC;


-- EMPLOYEE PERFORMANCE METRIC BY TOTAL PREMIUM COLLECTED
CREATE VIEW vw_Top_Performing_Employees AS
SELECT 
    e.em_name AS employee_name,
    SUM(p.premium_amount) AS total_premium_collected
FROM 
    Employees e
JOIN 
    Milestones m ON m.assigned_to = e.employeeID
JOIN 
    Claims c ON c.claimID = m.claimID
JOIN 
    Policy p ON p.policyID = c.policyID
GROUP BY 
    e.em_name
ORDER BY 
    total_premium_collected DESC;


-- TOP 5 CUSTOMER LIFETIME VALUE
CREATE VIEW vw_Customer_Lifetime_Value AS
SELECT 
    c.cu_name AS customer_name,
    SUM(p.premium_amount) AS lifetime_value
FROM 
    Customer c
JOIN 
    Policy p ON p.customerID = c.customerID
GROUP BY 
    c.customerID
ORDER BY 
    lifetime_value DESC
LIMIT 5;


-- BOTTOM 5 CUSTOMER LIFETIME VALUE
CREATE VIEW vw_Bottom_5_Customers_Lifetime_Value AS
SELECT 
    c.cu_name AS customer_name,
    SUM(p.premium_amount) AS lifetime_value
FROM 
    Customer c
JOIN 
    Policy p ON p.customerID = c.customerID
GROUP BY 
    c.customerID
ORDER BY 
    lifetime_value ASC
LIMIT 5;


-- CLAIMS COST VS PREMIUM COLLECTED
CREATE VIEW vw_Claims_Cost_vs_Premium_Collected AS
SELECT 
    pt.policy_type AS policy_type,
    SUM(c.claim_amount) AS total_claim_cost,
    SUM(p.premium_amount) AS total_premium_collected,
    (SUM(c.claim_amount) / SUM(p.premium_amount)) AS claims_to_premium_ratio
FROM 
    Policy p
JOIN 
    Policy_Types pt ON p.policy_typeID = pt.policy_typeID
JOIN 
    Claims c ON c.policyID = p.policyID
GROUP BY 
    pt.policy_type
ORDER BY 
    claims_to_premium_ratio DESC;


-- TOTAL LOSS (CLAIM - PREMIUM)
CREATE VIEW vw_Total_Loss AS
SELECT 
    pt.policy_type AS policy_type,
    SUM(p.premium_amount) AS total_premiums_earned,
    SUM(c.claim_amount) AS total_claims_paid,
    (SUM(p.premium_amount) - SUM(c.claim_amount)) AS total_loss
FROM 
    Policy p
JOIN 
    Policy_Types pt ON p.policy_typeID = pt.policy_typeID
JOIN 
    Claims c ON c.policyID = p.policyID
GROUP BY 
    pt.policy_type
ORDER BY 
    total_loss ASC;
    
    
-- CLAIM PROCESSING BOTTLENECKS (TO SEE IF CERTAIN MILESTONES TAKE LONGER TO DO)
CREATE VIEW vw_Claim_Processing_Bottlenecks AS
SELECT 
    m.milestone AS milestone,
    AVG(DATEDIFF(m.completion_date, m.milestone_date)) AS avg_days_to_complete
FROM 
    Milestones m
WHERE 
    m.completion_date IS NOT NULL
GROUP BY 
    m.milestone
ORDER BY 
    avg_days_to_complete DESC;


-- CLAIMS STATUS RATIO
CREATE VIEW vw_Claims_Status_Ratio AS
SELECT 
    m.status AS status_label,
    (COUNT(m.claimID) / (SELECT COUNT(*) FROM Milestones)) * 100 AS percentage
FROM 
    Milestones m
GROUP BY 
    m.status;
    
    
-- CLAIM COMPLETED VS DENIAL RATE
CREATE VIEW vw_Claim_Completed_Denial_Rate AS
SELECT 
    m.status AS status_label,
    (COUNT(m.claimID) / (SELECT COUNT(*) FROM Milestones)) * 100 AS percentage
FROM 
    Milestones m
WHERE 
    m.status IN ('Completed', 'Denied')
GROUP BY 
    m.status;


-- CLAIM COMPLETION TIMELINESS
CREATE VIEW vw_Claim_Completion_Timeliness AS
SELECT 
    m.claimID,
    DATEDIFF(m.estimated_completion_date, m.milestone_date) AS days_to_estimated_completion,
    DATEDIFF(m.completion_date, m.milestone_date) AS days_to_actual_completion,
    DATEDIFF(m.estimated_completion_date, m.milestone_date) - DATEDIFF(m.completion_date, m.milestone_date) AS days_difference,
    CASE 
        WHEN DATEDIFF(m.completion_date, m.milestone_date) IS NOT NULL AND DATEDIFF(m.estimated_completion_date, m.milestone_date) IS NOT NULL THEN
            CASE 
                WHEN (DATEDIFF(m.estimated_completion_date, m.milestone_date) - DATEDIFF(m.completion_date, m.milestone_date)) > 0 THEN 'Early'
                WHEN (DATEDIFF(m.estimated_completion_date, m.milestone_date) - DATEDIFF(m.completion_date, m.milestone_date)) < 0 THEN 'Late'
                ELSE 'As Estimated'
            END
        ELSE NULL
    END AS completion_status
FROM 
    Milestones m
WHERE 
    m.status IN ('Completed', 'Denied')
    AND m.completion_date IS NOT NULL
    AND m.estimated_completion_date IS NOT NULL;


-- CLAIMS DENIED BY COMPLETION STATUS
CREATE VIEW vw_Claims_Denied_By_Completion_Status AS
SELECT 
    c.completion_status AS completion_status_label,
    COUNT(m.claimID) AS number_of_claims_denied
FROM 
    Milestones m
JOIN 
    vw_Claim_Completion_Timeliness c ON m.claimID = c.claimID
WHERE 
    m.status = 'Denied'
GROUP BY 
    c.completion_status;


-- CLAIMS BY COMPLETION STATUS
CREATE VIEW vw_Claims_By_Completion_Status AS
SELECT 
    completion_status AS completion_status_label,
    COUNT(claimID) AS number_of_claims
FROM 
    vw_Claim_Completion_Timeliness
GROUP BY 
    completion_status;


-- CLAIMS COMPLETED BY COMPLETION STATUS
CREATE VIEW vw_Claims_Completed_By_Completion_Status AS
SELECT 
    c.completion_status AS completion_status_label,
    COUNT(m.claimID) AS number_of_claims_completed
FROM 
    Milestones m
JOIN 
    vw_Claim_Completion_Timeliness c ON m.claimID = c.claimID
WHERE 
    m.status = 'Completed'
GROUP BY 
    c.completion_status;


-- BOTTOM 5 VEHICLE BRANDS
CREATE VIEW "vw_bottom5_popular_vehicle_brands" AS select "c"."vehicle_brand" AS "vehicle_brand",count("p"."policyID") AS "num_of_policies",sum("p"."coverage_amount") AS "total_coverage_amount",avg("p"."premium_amount") AS "average_premium_amount" from ("Policy" "p" join "Customer" "c" on(("p"."customerID" = "c"."customerID"))) group by "c"."vehicle_brand" order by "num_of_policies" limit 5;


-- TOP 5 VEHICLE BRANDS
CREATE VIEW "vw_top5_popular_vehicle_brands" AS select "c"."vehicle_brand" AS "vehicle_brand",count("p"."policyID") AS "num_of_policies",sum("p"."coverage_amount") AS "total_coverage_amount",avg("p"."premium_amount") AS "average_premium_amount" from ("Policy" "p" join "Customer" "c" on(("p"."customerID" = "c"."customerID"))) group by "c"."vehicle_brand" order by "num_of_policies" desc limit 5;


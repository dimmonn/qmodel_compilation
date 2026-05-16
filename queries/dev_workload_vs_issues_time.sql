SELECT
    i.id AS issue_id,
    i.created_at,
    i.closed_at,
    TIMESTAMPDIFF(MINUTE, i.created_at, i.closed_at) AS issue_resolution_time,
    ia.assignees AS assignee,

    (
        SELECT COUNT(*)
        FROM project_issue i2
                 JOIN project_issue_assignees ia2
                      ON i2.id = ia2.project_issue_id
                          AND i2.project_name = ia2.project_issue_project_name
                          AND i2.project_owner = ia2.project_issue_project_owner
        WHERE ia2.assignees = ia.assignees
          AND i2.created_at <= i.created_at
          AND (i2.closed_at > i.created_at OR i2.closed_at IS NULL)
    ) AS open_issues_at_time,

    (
        SELECT COUNT(*)
        FROM project_pull pr
                 JOIN project_pull_assignees pra
                      ON pr.id = pra.project_pull_id
                          AND pr.project_name = pra.project_pull_project_name
                          AND pr.project_owner = pra.project_pull_project_owner
        WHERE pra.assignees = ia.assignees
          AND pr.created_at <= i.created_at
          AND (pr.merged_at > i.created_at OR pr.merged_at IS NULL)
    ) AS open_prs_at_time

FROM project_issue i
         JOIN project_issue_assignees ia
              ON i.id = ia.project_issue_id
                  AND i.project_name = ia.project_issue_project_name
                  AND i.project_owner = ia.project_issue_project_owner
WHERE i.closed_at IS NOT NULL;

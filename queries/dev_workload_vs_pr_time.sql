SELECT pr.id                                                        AS pr_id,
       pr.created_at,
       pr.merged_at,
       TIMESTAMPDIFF(MINUTE, pr.created_at, pr.merged_at)           AS pr_review_time,
       r.reviewers                                                  AS reviewer,

       (SELECT COUNT(*)
        FROM project_issue i
                 JOIN project_issue_assignees a
                      ON i.id = a.project_issue_id
                          AND i.project_name = a.project_issue_project_name
                          AND i.project_owner = a.project_issue_project_owner
        WHERE a.assignees = r.reviewers
          AND i.created_at <= pr.created_at
          AND (i.closed_at > pr.created_at OR i.closed_at IS NULL)) AS open_issues_at_time,

       (SELECT COUNT(*)
        FROM project_pull p
                 JOIN project_pull_assignees a
                      ON p.id = a.project_pull_id
                          AND p.project_name = a.project_pull_project_name
                          AND p.project_owner = a.project_pull_project_owner
        WHERE a.assignees = r.reviewers
          AND p.created_at <= pr.created_at
          AND (p.merged_at > pr.created_at OR p.merged_at IS NULL)) AS open_prs_at_time

FROM project_pull pr
         JOIN project_pull_reviewers r
              ON pr.id = r.project_pull_id
                  AND pr.project_name = r.project_pull_project_name
                  AND pr.project_owner = r.project_pull_project_owner
WHERE pr.merged_at IS NOT NULL;
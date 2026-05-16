SELECT i.id                                                     AS issue_id,
       i.created_at,
       i.closed_at,
       TIMESTAMPDIFF(MINUTE, i.created_at, i.closed_at)         AS issue_resolution_time,
       bic.author                                               AS developer,
       MAX(c.commit_date)                                       AS last_commit_before_issue,
       TIMESTAMPDIFF(MINUTE, MAX(c.commit_date), i.created_at)  AS inactivity_before_issue_minutes,
       TIMESTAMPDIFF(MINUTE, pp.created_at, pp.closed_at)       AS project_pull_review_time,
       TIMESTAMPDIFF(MINUTE, MAX(c.commit_date), pp.created_at) AS inactivity_before_pull_request_minutes

FROM project_issue i
         JOIN
     project_issue_bug_introducing_commits bibc
     ON i.id = bibc.project_issue_id
         AND i.project_name = bibc.project_issue_project_name
         AND i.project_owner = bibc.project_issue_project_owner
         JOIN
     commit bic ON bibc.bug_introducing_commits_sha = bic.sha
         JOIN
     commit c ON c.author = bic.author AND c.commit_date < i.created_at
         JOIN project_pull pp
              on i.fix_pr = pp.id
                  AND i.project_name = pp.project_name
                  AND i.project_owner = pp.project_owner
GROUP BY i.id, i.created_at, i.closed_at, pp.created_at, pp.closed_at, bic.author;

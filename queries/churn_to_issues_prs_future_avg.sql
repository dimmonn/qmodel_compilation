WITH CommitChurnData AS (SELECT DATE(c.commit_date)                  AS time,
                                c.project_name,
                                c.project_owner,
                                COUNT(DISTINCT c.sha)                AS commit_count,

                                COALESCE(SUM(fc.total_changes), 0)   AS total_changes,
                                COALESCE(SUM(fc.total_additions), 0) AS total_additions,
                                COALESCE(SUM(fc.total_deletions), 0) AS total_deletions

                         FROM commit c
                                  LEFT JOIN commit_file_changes cfc ON c.sha = cfc.commit_sha
                                  LEFT JOIN file_change fc ON cfc.file_changes_id = fc.id
                         GROUP BY c.project_owner, c.project_name, DATE(c.commit_date)),
     IssueData AS (SELECT pi.project_name,
                          pi.project_owner,
                          DATE(pi.created_at)   AS issue_date,
                          COUNT(DISTINCT pi.id) AS issues_opened
                   FROM project_issue pi
                   GROUP BY pi.project_name, pi.project_owner, DATE(pi.created_at)),
     PullRequestData AS (SELECT pp.project_name,
                                pp.project_owner,
                                DATE(pp.created_at)   AS pr_date,
                                COUNT(DISTINCT pp.id) AS prs_opened
                         FROM project_pull pp
                         GROUP BY pp.project_name, pp.project_owner, DATE(pp.created_at))
SELECT c.time,
       c.project_owner,
       c.project_name,
       c.commit_count,

       c.total_changes,
       c.total_additions,
       c.total_deletions,

       (SELECT SUM(i.issues_opened)
        FROM IssueData i
        WHERE i.project_name = c.project_name
          AND i.project_owner = c.project_owner
          AND i.issue_date > c.time)  AS num_of_issues_opened_after_commit_date,

       (SELECT SUM(prs.prs_opened)
        FROM PullRequestData prs
        WHERE prs.project_name = c.project_name
          AND prs.project_owner = c.project_owner
          AND prs.pr_date > c.time)   AS num_of_prs_opened_after_commit_date,

       (SELECT AVG(TIMESTAMPDIFF(SECOND, pi.created_at, pi.closed_at)) / 86400
        FROM project_issue pi
        WHERE pi.project_name = c.project_name
          AND pi.project_owner = c.project_owner
          AND pi.closed_at IS NOT NULL
          AND pi.created_at > c.time) AS avg_issue_resolution_time_days,

       (SELECT AVG(TIMESTAMPDIFF(SECOND, pp.created_at, pp.merged_at)) / 86400
        FROM project_pull pp
        WHERE pp.project_name = c.project_name
          AND pp.project_owner = c.project_owner
          AND pp.merged_at IS NOT NULL
          AND pp.created_at > c.time) AS avg_pr_review_time_days

FROM CommitChurnData c
ORDER BY c.time ASC;

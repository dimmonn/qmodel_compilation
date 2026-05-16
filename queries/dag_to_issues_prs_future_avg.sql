WITH CommitData AS (SELECT DATE(c.commit_date)                AS time,
                           COUNT(DISTINCT c.sha)              AS commitCount,
                           c.project_name,
                           c.project_owner,

                           AVG(c.branch_length)               AS avg_branch_length,
                           MAX(c.max_depth_of_commit_history) AS max_commit_depth,
                           MIN(c.min_depth_of_commit_history) AS min_commit_depth,
                           AVG(c.average_degree)              AS avg_degree,
                           MAX(c.max_degree)                  AS max_degree,
                           MAX(c.number_of_branches)          AS max_branches,
                           MAX(c.number_of_edges)             AS max_edges,
                           MAX(c.number_of_vertices)          AS max_vertices,
                           MAX(c.num_of_files_changed)        AS max_files_changed
                    FROM commit c
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
       c.commitCount,
       c.project_owner,
       c.project_name,

       c.avg_branch_length,
       c.max_commit_depth,
       c.min_commit_depth,
       c.avg_degree,
       c.max_degree,
       c.max_branches,
       c.max_edges,
       c.max_vertices,
       c.max_files_changed,

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

FROM CommitData c
ORDER BY c.time ASC;
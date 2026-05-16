SELECT i.id                                                    AS issue_id,
       i.created_at                                            AS issue_created_at,
       i.closed_at                                             AS issue_closed_at,
       TIMESTAMPDIFF(MINUTE, i.created_at, i.closed_at)        AS issue_resolution_time_minutes,

       pp.id                                                   AS pr_id,
       pp.created_at                                           AS pr_created_at,
       pp.closed_at                                            AS pr_closed_at,
       TIMESTAMPDIFF(MINUTE, pp.created_at, pp.closed_at)      AS pull_request_review_time_minutes,

       JSON_UNQUOTE(JSON_EXTRACT(pp.raw_pull, '$.user.login')) AS pr_creator,

       SUM(fc.total_additions)                                 AS total_additions,
       SUM(fc.total_deletions)                                 AS total_deletions,
       SUM(fc.total_changes)                                   AS total_changes,
       COUNT(DISTINCT fc.id)                                   AS files_changed

FROM project_issue i

         JOIN project_pull pp
              ON i.fix_pr = pp.id
                  AND i.project_name = pp.project_name
                  AND i.project_owner = pp.project_owner

         JOIN project_pull_commits prc
              ON prc.project_pull_id = pp.id
                  AND prc.project_pull_project_name = pp.project_name
                  AND prc.project_pull_project_owner = pp.project_owner

         JOIN commit c
              ON prc.commits_sha = c.sha

         JOIN commit_file_changes cfc
              ON c.sha = cfc.commit_sha

         JOIN file_change fc
              ON cfc.file_changes_id = fc.id

GROUP BY i.id, i.created_at, i.closed_at,
         pp.id, pp.created_at, pp.closed_at,
         pr_creator;

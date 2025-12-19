SELECT
    pp.project_owner,
    pp.project_name,
    pp.id                                       AS pr_id,

    -- Same target: PR review time
    TIMESTAMPDIFF(
        HOUR,
        pp.created_at,
        pp.merged_at
    )                                           AS pr_review_hours,

    -- Number of bug-introducing commits in this PR
    COUNT(DISTINCT c.sha)                       AS bic_num_commits,

    -- Graph metrics aggregated over bug-introducing commits
    AVG(c.min_depth_of_commit_history)          AS bic_avg_min_depth,
    AVG(c.max_depth_of_commit_history)          AS bic_avg_max_depth,
    AVG(c.distance_to_branch_start)             AS bic_avg_fp_distance,
    MAX(c.distance_to_branch_start)             AS bic_max_fp_distance,
    AVG(c.upstream_heads_unique_on_segment)     AS bic_avg_upstream_heads,
    MAX(c.upstream_heads_unique_on_segment)     AS bic_max_upstream_heads,
    AVG(c.days_since_last_merge_on_segment)     AS bic_avg_days_since_merge,
    MAX(c.days_since_last_merge_on_segment)     AS bic_max_days_since_merge,
    AVG(c.in_degree)                            AS bic_avg_in_degree,
    AVG(c.out_degree)                           AS bic_avg_out_degree,
    AVG(c.number_of_branches)                   AS bic_avg_branches,
    AVG(c.average_degree)                       AS bic_avg_average_degree,

    -- Churn / file-change metrics aggregated over bug-introducing commits
    SUM(cm.total_additions)                     AS bic_total_additions,
    SUM(cm.total_deletions)                     AS bic_total_deletions,
    SUM(cm.total_changes)                       AS bic_total_changes,
    AVG(cm.avg_changes_per_file)                AS bic_avg_changes_per_file,
    MAX(cm.max_changes_in_file)                 AS bic_max_changes_in_file,
    SUM(cm.num_files_changed)                   AS bic_num_files_changed,
    CASE
        WHEN SUM(cm.num_files_changed) > 0
        THEN SUM(cm.total_changes) / SUM(cm.num_files_changed)
        ELSE NULL
    END                                         AS bic_change_density_per_file

FROM project_pull_commits AS ppc

JOIN project_pull AS pp
  ON  pp.id            = ppc.project_pull_id
  AND pp.project_name  = ppc.project_pull_project_name
  AND pp.project_owner = ppc.project_pull_project_owner

JOIN commit AS c
  ON c.sha = ppc.commits_sha

-- keep only commits that SZZ marks as bug-introducing
JOIN project_issue_bug_introducing_commits AS pibic
  ON pibic.bug_introducing_commits_sha = c.sha

JOIN project_issue AS pi
  ON  pi.id            = pibic.project_issue_id
  AND pi.project_name  = pibic.project_issue_project_name
  AND pi.project_owner = pibic.project_issue_project_owner

LEFT JOIN (
   SELECT
      cfc.commit_sha                       AS commit_sha,
      COUNT(DISTINCT cfc.file_changes_id)  AS num_files_changed,
      SUM(fc.total_additions)             AS total_additions,
      SUM(fc.total_deletions)             AS total_deletions,
      SUM(fc.total_changes)               AS total_changes,
      AVG(fc.total_changes)               AS avg_changes_per_file,
      MAX(fc.total_changes)               AS max_changes_in_file
   FROM commit_file_changes AS cfc
   JOIN file_change AS fc
     ON fc.id = cfc.file_changes_id
   GROUP BY cfc.commit_sha
) AS cm
  ON cm.commit_sha = c.sha

WHERE
      pp.state = 'closed'
  AND pp.created_at IS NOT NULL
  AND pp.merged_at  IS NOT NULL
  AND pi.state = 'closed'
  AND c.max_depth_of_commit_history IS NOT NULL
  AND c.max_depth_of_commit_history > 0
  and c.distance_to_branch_start > 0
  AND pi.project_owner = %(owner)s

GROUP BY
    pp.project_owner,
    pp.project_name,
    pp.id;
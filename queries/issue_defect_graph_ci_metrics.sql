SELECT
    pi.project_owner,
    pi.project_name,
    pi.id AS issue_id,

    TIMESTAMPDIFF(HOUR, pi.created_at, pi.closed_at) AS issue_resolution_hours,

    COUNT(DISTINCT pibic.bug_introducing_commits_sha) AS bic_num_commits,
    AVG(c.max_depth_of_commit_history - c.min_depth_of_commit_history) AS bic_avg_depth_diff,  -- Avg. divergence in commit graph (branch vs root)
    MAX(c.max_depth_of_commit_history - c.min_depth_of_commit_history) AS bic_max_depth_diff,  -- Max divergence (largest integration backlog)
    AVG(c.distance_to_branch_start) AS bic_avg_fp_distance,
    MAX(c.distance_to_branch_start) AS bic_max_fp_distance,
    AVG(c.upstream_heads_unique_on_segment) AS bic_avg_upstream_heads,
    MAX(c.upstream_heads_unique_on_segment) AS bic_max_upstream_heads,
    AVG(c.days_since_last_merge_on_segment) AS bic_avg_days_since_merge,
    MAX(c.days_since_last_merge_on_segment) AS bic_max_days_since_merge,
    AVG(c.in_degree)  AS bic_avg_in_degree,
    AVG(c.out_degree) AS bic_avg_out_degree,
    AVG(c.number_of_branches)    AS bic_avg_branches,
    AVG(c.average_degree)        AS bic_avg_average_degree,

    -- 🔹 **New:** Branch commit rate (commits per day on branch segment)
    AVG(
       CASE
         WHEN c.days_since_last_merge_on_segment > 0
         THEN c.distance_to_branch_start / c.days_since_last_merge_on_segment
       END
    ) AS bic_avg_branch_commit_rate,

    -- 🔹 Churn metrics aggregated over bug-introducing commits
    SUM(cm.total_additions)   AS bic_total_additions,
    SUM(cm.total_deletions)   AS bic_total_deletions,
    SUM(cm.total_changes)     AS bic_total_changes,
    AVG(cm.avg_changes_per_file)  AS bic_avg_changes_per_file,
    MAX(cm.max_changes_in_file)   AS bic_max_changes_in_file,
    AVG(cm.num_files_changed)     AS bic_num_files_changed,
    CASE
       WHEN SUM(cm.num_files_changed) > 0
       THEN SUM(cm.total_changes) / SUM(cm.num_files_changed)
       ELSE NULL
    END AS bic_change_density_per_file

FROM project_issue AS pi
JOIN project_issue_bug_introducing_commits AS pibic
  ON pi.id = pibic.project_issue_id
 AND pi.project_name = pibic.project_issue_project_name
 AND pi.project_owner = pibic.project_issue_project_owner
JOIN commit AS c
  ON c.sha = pibic.bug_introducing_commits_sha
LEFT JOIN (
   SELECT
       cfc.commit_sha AS commit_sha,
       COUNT(DISTINCT cfc.file_changes_id) AS num_files_changed,
       SUM(fc.total_additions)   AS total_additions,
       SUM(fc.total_deletions)   AS total_deletions,
       SUM(fc.total_changes)     AS total_changes,
       AVG(fc.total_changes)     AS avg_changes_per_file,
       MAX(fc.total_changes)     AS max_changes_in_file
   FROM commit_file_changes AS cfc
   JOIN file_change AS fc
     ON fc.id = cfc.file_changes_id
   GROUP BY cfc.commit_sha
) AS cm
  ON cm.commit_sha = c.sha

WHERE
    pi.state = 'closed'
  AND pi.created_at IS NOT NULL
  AND pi.closed_at  IS NOT NULL
  AND c.max_depth_of_commit_history IS NOT NULL
  AND c.distance_to_branch_start > 0          -- consider commits on active branch segments
  AND pi.project_owner = %(owner)s

GROUP BY
    pi.project_owner,
    pi.project_name,
    pi.id;
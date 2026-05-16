SELECT
    pi.project_owner,
    pi.project_name,
    pi.id AS issue_id,
    TIMESTAMPDIFF(HOUR, pi.created_at, pi.closed_at) AS issue_resolution_hours,

    COUNT(DISTINCT pifc.fixing_commits_sha) AS fix_num_commits,
    AVG(c.min_depth_of_commit_history) AS fix_avg_min_depth,
    MAX(c.max_depth_of_commit_history) AS fix_max_max_depth,
    CASE
        WHEN COUNT(DISTINCT pifc.fixing_commits_sha) > 1
        THEN (MAX(c.max_depth_of_commit_history) - MIN(c.min_depth_of_commit_history)) / NULLIF(COUNT(DISTINCT pifc.fixing_commits_sha), 0)
        ELSE NULL
    END AS fix_depth_pace,

    AVG(c.distance_to_branch_start) AS fix_avg_fp_distance,
    AVG(c.upstream_heads_unique_on_segment) AS fix_avg_upstream_heads,
    AVG(c.days_since_last_merge_on_segment) AS fix_avg_days_since_merge,
    AVG(c.in_degree) AS fix_avg_in_degree,
    AVG(c.out_degree) AS fix_avg_out_degree,

    SUM(fc.total_additions) AS fix_total_additions,
    SUM(fc.total_deletions) AS fix_total_deletions,
    SUM(fc.total_changes) AS fix_total_changes,
    AVG(fc.total_changes) AS fix_avg_changes_per_file,
    MAX(fc.total_changes) AS fix_max_changes_in_file,
    COUNT(DISTINCT fc.id) AS fix_num_files_changed,
    CASE
        WHEN COUNT(DISTINCT fc.id) > 0 THEN SUM(fc.total_changes) / COUNT(DISTINCT fc.id)
        ELSE NULL
    END AS fix_change_density_per_file

FROM project_issue pi
JOIN project_issue_fixing_commits pifc
  ON pi.id = pifc.project_issue_id
JOIN commit c
  ON c.sha = pifc.fixing_commits_sha
JOIN commit_file_changes cfc
  ON c.sha = cfc.commit_sha
JOIN file_change fc
  ON fc.id = cfc.file_changes_id

WHERE pi.state = 'closed'
  AND pi.created_at IS NOT NULL AND pi.closed_at IS NOT NULL
and pi.project_owner='facebook'
and c.distance_to_branch_start>0

GROUP BY pi.project_owner, pi.project_name, pi.id;


select count(*) from project_pull_commits;

select count(*) from project_pull
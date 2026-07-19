WITH issue_target AS (
  SELECT
    i.project_owner,
    i.project_name,
    i.id AS issue_id,
    TIMESTAMPDIFF(HOUR, i.created_at, i.closed_at) AS issue_resolution_hours
  FROM qmodel_demo.project_issue i
  WHERE i.closed_at IS NOT NULL
),
fix_commit_features AS (
  SELECT
    fic.project_issue_project_owner AS project_owner,
    fic.project_issue_project_name  AS project_name,
    fic.project_issue_id            AS issue_id,
    COUNT(*)                                     AS n_fix_commits,
    SUM(c.num_of_files_changed)                  AS num_of_files_changed,
    SUM(c.merge_count)                           AS merge_count_near_fix,
    AVG(c.in_degree)                             AS avg_in_degree,
    AVG(c.out_degree)                            AS avg_out_degree,
    AVG(c.max_depth_of_commit_history)           AS avg_max_depth,
    MAX(c.max_depth_of_commit_history)           AS max_max_depth,
    AVG(c.distance_to_branch_start)              AS avg_dist_to_branch_start,
    MAX(c.distance_to_branch_start)              AS max_dist_to_branch_start,
    AVG(c.upstream_heads_unique_on_segment)      AS avg_upstream_heads_unique,
    MAX(c.upstream_heads_unique_on_segment)      AS max_upstream_heads_unique
  FROM qmodel_demo.project_issue_fixing_commits fic
  JOIN qmodel_demo.`commit` c ON c.sha = fic.fixing_commits_sha
  GROUP BY fic.project_issue_project_owner, fic.project_issue_project_name, fic.project_issue_id
)
SELECT f.*, t.issue_resolution_hours
FROM fix_commit_features f
JOIN issue_target t
  ON t.project_owner = f.project_owner
 AND t.project_name  = f.project_name
 AND t.issue_id      = f.issue_id;

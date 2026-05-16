WITH pr_target AS (
  SELECT
    pr.project_owner,
    pr.project_name,
    pr.id AS pr_id,
    TIMESTAMPDIFF(HOUR, pr.created_at, COALESCE(pr.merged_at, pr.closed_at)) AS pr_review_hours
  FROM qmodel_demo.project_pull pr
  WHERE pr.merged_at IS NOT NULL OR pr.closed_at IS NOT NULL
),
pr_commit_features AS (
  SELECT
    pc.project_pull_project_owner AS project_owner,
    pc.project_pull_project_name  AS project_name,
    pc.project_pull_id            AS pr_id,
    COUNT(*)                                      AS commit_count,
    SUM(c.num_of_files_changed)                   AS num_of_files_changed,
    SUM(c.merge_count)                            AS merge_count_in_pr,
    AVG(c.in_degree)                              AS avg_in_degree,
    AVG(c.out_degree)                             AS avg_out_degree,
    AVG(c.max_depth_of_commit_history)            AS avg_max_depth,
    MAX(c.max_depth_of_commit_history)            AS max_max_depth,
    AVG(c.distance_to_branch_start)               AS avg_dist_to_branch_start,
    MAX(c.distance_to_branch_start)               AS max_dist_to_branch_start,
    AVG(c.upstream_heads_unique_on_segment)       AS avg_upstream_heads_unique,
    MAX(c.upstream_heads_unique_on_segment)       AS max_upstream_heads_unique
  FROM qmodel_demo.project_pull_commits pc
  JOIN qmodel_demo.`commit` c ON c.sha = pc.commits_sha
  GROUP BY pc.project_pull_project_owner, pc.project_pull_project_name, pc.project_pull_id
)
SELECT f.*, t.pr_review_hours
FROM pr_commit_features f
JOIN pr_target t
  ON t.project_owner = f.project_owner
 AND t.project_name  = f.project_name
 AND t.pr_id         = f.pr_id;


WITH
    selected_projects AS (
        SELECT project_owner, project_name
        FROM project
        WHERE project_owner IN ('ansible', 'facebook')
    ),

    commit_churn AS (
        SELECT
            c.project_owner,
            c.project_name,
            c.sha,

            COUNT(DISTINCT fc.id) AS files_changed,
            SUM(fc.total_additions) AS total_additions,
            SUM(fc.total_deletions) AS total_deletions,
            SUM(fc.total_changes) AS total_changes,
            AVG(fc.total_changes) AS avg_changes_per_file,
            MAX(fc.total_changes) AS max_changes_in_file
        FROM `commit` c
                 JOIN selected_projects sp
                      ON sp.project_owner = c.project_owner
                          AND sp.project_name  = c.project_name
                 JOIN commit_file_changes cfc
                      ON cfc.commit_sha = c.sha
                 JOIN file_change fc
                      ON fc.id = cfc.file_changes_id
        GROUP BY
            c.project_owner,
            c.project_name,
            c.sha
    ),

    issue_fix_rows AS (
        SELECT
            pi.project_owner,
            pi.project_name,
            pi.id AS analysis_id,

            TIMESTAMPDIFF(HOUR, pi.created_at, pi.closed_at) AS target_hours,

            COUNT(DISTINCT c.sha) AS commits_in_row,

            SUM(CASE
                    WHEN c.in_degree IS NOT NULL
                        AND c.out_degree IS NOT NULL
                        AND c.min_depth_of_commit_history IS NOT NULL
                        AND c.max_depth_of_commit_history IS NOT NULL
                        AND c.distance_to_branch_start IS NOT NULL
                        AND c.upstream_heads_unique_on_segment IS NOT NULL
                        AND c.days_since_last_merge_on_segment IS NOT NULL
                        AND c.number_of_branches IS NOT NULL
                        AND c.average_degree IS NOT NULL
                        THEN 1 ELSE 0
                END) AS graph_ready_commits,

            SUM(CASE
                    WHEN cc.total_changes IS NOT NULL
                        AND cc.files_changed IS NOT NULL
                        AND cc.files_changed > 0
                        THEN 1 ELSE 0
                END) AS churn_ready_commits,

            AVG(c.max_depth_of_commit_history - c.min_depth_of_commit_history) AS avg_depth_range,
            AVG(c.distance_to_branch_start) AS avg_fp_distance,
            AVG(c.upstream_heads_unique_on_segment) AS avg_upstream_heads,
            AVG(c.days_since_last_merge_on_segment) AS avg_days_since_merge,
            SUM(cc.total_changes) AS total_changes
        FROM project_issue pi
                 JOIN selected_projects sp
                      ON sp.project_owner = pi.project_owner
                          AND sp.project_name  = pi.project_name
                 JOIN project_issue_fixing_commits pifc
                      ON pifc.project_issue_id = pi.id
                          AND pifc.project_issue_project_name = pi.project_name
                          AND pifc.project_issue_project_owner = pi.project_owner
                 JOIN `commit` c
                      ON c.sha = pifc.fixing_commits_sha
                 LEFT JOIN commit_churn cc
                           ON cc.sha = c.sha
        WHERE pi.state = 'closed'
          AND pi.created_at IS NOT NULL
          AND pi.closed_at IS NOT NULL
        GROUP BY
            pi.project_owner,
            pi.project_name,
            pi.id,
            pi.created_at,
            pi.closed_at
    ),

    issue_bic_rows AS (
        SELECT
            pi.project_owner,
            pi.project_name,
            pi.id AS analysis_id,

            TIMESTAMPDIFF(HOUR, pi.created_at, pi.closed_at) AS target_hours,

            COUNT(DISTINCT c.sha) AS commits_in_row,

            SUM(CASE
                    WHEN c.in_degree IS NOT NULL
                        AND c.out_degree IS NOT NULL
                        AND c.min_depth_of_commit_history IS NOT NULL
                        AND c.max_depth_of_commit_history IS NOT NULL
                        AND c.distance_to_branch_start IS NOT NULL
                        AND c.upstream_heads_unique_on_segment IS NOT NULL
                        AND c.days_since_last_merge_on_segment IS NOT NULL
                        AND c.number_of_branches IS NOT NULL
                        AND c.average_degree IS NOT NULL
                        THEN 1 ELSE 0
                END) AS graph_ready_commits,

            SUM(CASE
                    WHEN cc.total_changes IS NOT NULL
                        AND cc.files_changed IS NOT NULL
                        AND cc.files_changed > 0
                        THEN 1 ELSE 0
                END) AS churn_ready_commits,

            AVG(c.max_depth_of_commit_history - c.min_depth_of_commit_history) AS avg_depth_range,
            AVG(c.distance_to_branch_start) AS avg_fp_distance,
            AVG(c.upstream_heads_unique_on_segment) AS avg_upstream_heads,
            AVG(c.days_since_last_merge_on_segment) AS avg_days_since_merge,
            SUM(cc.total_changes) AS total_changes
        FROM project_issue pi
                 JOIN selected_projects sp
                      ON sp.project_owner = pi.project_owner
                          AND sp.project_name  = pi.project_name
                 JOIN project_issue_bug_introducing_commits pibic
                      ON pibic.project_issue_id = pi.id
                          AND pibic.project_issue_project_name = pi.project_name
                          AND pibic.project_issue_project_owner = pi.project_owner
                 JOIN `commit` c
                      ON c.sha = pibic.bug_introducing_commits_sha
                 LEFT JOIN commit_churn cc
                           ON cc.sha = c.sha
        WHERE pi.state = 'closed'
          AND pi.created_at IS NOT NULL
          AND pi.closed_at IS NOT NULL
        GROUP BY
            pi.project_owner,
            pi.project_name,
            pi.id,
            pi.created_at,
            pi.closed_at
    ),

    pr_bic_commits AS (
        SELECT DISTINCT
            pp.project_owner,
            pp.project_name,
            pp.id AS pr_id,
            ppc.commits_sha AS sha
        FROM project_pull pp
                 JOIN selected_projects sp
                      ON sp.project_owner = pp.project_owner
                          AND sp.project_name  = pp.project_name
                 JOIN project_pull_commits ppc
                      ON ppc.project_pull_id = pp.id
                          AND ppc.project_pull_project_name = pp.project_name
                          AND ppc.project_pull_project_owner = pp.project_owner
                 JOIN project_issue_bug_introducing_commits pibic
                      ON pibic.bug_introducing_commits_sha = ppc.commits_sha
    ),

    pr_bic_rows AS (
        SELECT
            pp.project_owner,
            pp.project_name,
            pp.id AS analysis_id,

            TIMESTAMPDIFF(HOUR, pp.created_at, pp.merged_at) AS target_hours,

            COUNT(DISTINCT c.sha) AS commits_in_row,

            SUM(CASE
                    WHEN c.in_degree IS NOT NULL
                        AND c.out_degree IS NOT NULL
                        AND c.min_depth_of_commit_history IS NOT NULL
                        AND c.max_depth_of_commit_history IS NOT NULL
                        AND c.distance_to_branch_start IS NOT NULL
                        AND c.upstream_heads_unique_on_segment IS NOT NULL
                        AND c.days_since_last_merge_on_segment IS NOT NULL
                        AND c.number_of_branches IS NOT NULL
                        AND c.average_degree IS NOT NULL
                        THEN 1 ELSE 0
                END) AS graph_ready_commits,

            SUM(CASE
                    WHEN cc.total_changes IS NOT NULL
                        AND cc.files_changed IS NOT NULL
                        AND cc.files_changed > 0
                        THEN 1 ELSE 0
                END) AS churn_ready_commits,

            AVG(c.max_depth_of_commit_history - c.min_depth_of_commit_history) AS avg_depth_range,
            AVG(c.distance_to_branch_start) AS avg_fp_distance,
            AVG(c.upstream_heads_unique_on_segment) AS avg_upstream_heads,
            AVG(c.days_since_last_merge_on_segment) AS avg_days_since_merge,
            SUM(cc.total_changes) AS total_changes
        FROM project_pull pp
                 JOIN pr_bic_commits pbc
                      ON pbc.pr_id = pp.id
                          AND pbc.project_name = pp.project_name
                          AND pbc.project_owner = pp.project_owner
                 JOIN `commit` c
                      ON c.sha = pbc.sha
                 LEFT JOIN commit_churn cc
                           ON cc.sha = c.sha
        WHERE pp.state = 'closed'
          AND pp.created_at IS NOT NULL
          AND pp.merged_at IS NOT NULL
        GROUP BY
            pp.project_owner,
            pp.project_name,
            pp.id,
            pp.created_at,
            pp.merged_at
    ),

    all_rows AS (
        SELECT
            project_owner,
            project_name,
            'Issue-level fixing-commit dataset' AS dataset_name,
            'issue' AS analysis_unit,
            analysis_id,
            target_hours,
            commits_in_row,
            graph_ready_commits,
            churn_ready_commits,
            avg_depth_range,
            avg_fp_distance,
            avg_upstream_heads,
            avg_days_since_merge,
            total_changes
        FROM issue_fix_rows

        UNION ALL

        SELECT
            project_owner,
            project_name,
            'Issue-level candidate-BIC dataset' AS dataset_name,
            'issue' AS analysis_unit,
            analysis_id,
            target_hours,
            commits_in_row,
            graph_ready_commits,
            churn_ready_commits,
            avg_depth_range,
            avg_fp_distance,
            avg_upstream_heads,
            avg_days_since_merge,
            total_changes
        FROM issue_bic_rows

        UNION ALL

        SELECT
            project_owner,
            project_name,
            'PR-level candidate-BIC dataset' AS dataset_name,
            'pull request' AS analysis_unit,
            analysis_id,
            target_hours,
            commits_in_row,
            graph_ready_commits,
            churn_ready_commits,
            avg_depth_range,
            avg_fp_distance,
            avg_upstream_heads,
            avg_days_since_merge,
            total_changes
        FROM pr_bic_rows
    )

SELECT
    project_owner,
    project_name,
    dataset_name,
    analysis_unit,

    COUNT(*) AS analysis_rows,

    SUM(CASE WHEN target_hours IS NOT NULL AND target_hours >= 0 THEN 1 ELSE 0 END)
             AS rows_with_target_duration,

    ROUND(
            100.0 * SUM(CASE WHEN target_hours IS NOT NULL AND target_hours >= 0 THEN 1 ELSE 0 END)
                / NULLIF(COUNT(*), 0),
            2
    ) AS target_duration_computability_percent,

    SUM(CASE WHEN graph_ready_commits > 0 THEN 1 ELSE 0 END)
             AS rows_with_graph_summary,

    ROUND(
            100.0 * SUM(CASE WHEN graph_ready_commits > 0 THEN 1 ELSE 0 END)
                / NULLIF(COUNT(*), 0),
            2
    ) AS graph_summary_computability_percent,

    SUM(CASE WHEN graph_ready_commits = commits_in_row THEN 1 ELSE 0 END)
             AS rows_where_all_commits_have_graph_metrics,

    ROUND(
            100.0 * SUM(CASE WHEN graph_ready_commits = commits_in_row THEN 1 ELSE 0 END)
                / NULLIF(COUNT(*), 0),
            2
    ) AS all_commits_graph_complete_percent,

    SUM(CASE WHEN churn_ready_commits > 0 THEN 1 ELSE 0 END)
             AS rows_with_churn_summary,

    ROUND(
            100.0 * SUM(CASE WHEN churn_ready_commits > 0 THEN 1 ELSE 0 END)
                / NULLIF(COUNT(*), 0),
            2
    ) AS churn_summary_computability_percent,

    SUM(CASE WHEN graph_ready_commits > 0 AND churn_ready_commits > 0 THEN 1 ELSE 0 END)
             AS rows_with_graph_and_churn_summary,

    ROUND(
            100.0 * SUM(CASE WHEN graph_ready_commits > 0 AND churn_ready_commits > 0 THEN 1 ELSE 0 END)
                / NULLIF(COUNT(*), 0),
            2
    ) AS graph_churn_summary_computability_percent,

    ROUND(AVG(commits_in_row), 2) AS avg_commits_per_analysis_row,
    ROUND(AVG(graph_ready_commits), 2) AS avg_graph_ready_commits_per_row,
    ROUND(AVG(churn_ready_commits), 2) AS avg_churn_ready_commits_per_row,

    ROUND(AVG(avg_depth_range), 4) AS avg_depth_range,
    ROUND(AVG(avg_fp_distance), 4) AS avg_fp_distance,
    ROUND(AVG(avg_upstream_heads), 4) AS avg_upstream_heads,
    ROUND(AVG(avg_days_since_merge), 4) AS avg_days_since_merge,
    ROUND(AVG(total_changes), 4) AS avg_total_changes
FROM all_rows
GROUP BY
    project_owner,
    project_name,
    dataset_name,
    analysis_unit
ORDER BY
    project_owner,
    project_name,
    dataset_name;

WITH
    commit_churn AS (
        SELECT
            cfc.commit_sha,
            COUNT(DISTINCT fc.id) AS num_files_changed,
            SUM(COALESCE(fc.total_additions, 0)) AS total_additions,
            SUM(COALESCE(fc.total_deletions, 0)) AS total_deletions,
            SUM(COALESCE(fc.total_changes, 0)) AS total_changes,
            AVG(COALESCE(fc.total_changes, 0)) AS avg_changes_per_file,
            MAX(COALESCE(fc.total_changes, 0)) AS max_changes_in_file
        FROM commit_file_changes cfc
        JOIN file_change fc
          ON fc.id = cfc.file_changes_id
        GROUP BY
            cfc.commit_sha
    ),

    ci_result_rows AS (
        SELECT
            a.commit_sha,
            LOWER(TRIM(a.result)) AS result_norm,
            a.started_at,
            a.completed_at
        FROM action a
        WHERE a.commit_sha IS NOT NULL
          AND a.result IS NOT NULL
          AND TRIM(a.result) <> ''
    ),

    ci_by_commit AS (
        SELECT
            r.commit_sha,

            COUNT(*) AS ci_check_runs,
            COUNT(*) AS ci_total_checks,

            SUM(CASE
                WHEN r.result_norm = 'success'
                THEN 1 ELSE 0
            END) AS ci_passed_checks,

            SUM(CASE
                WHEN r.result_norm IN (
                    'failure',
                    'failed',
                    'timed_out',
                    'startup_failure',
                    'action_required'
                )
                THEN 1 ELSE 0
            END) AS ci_failed_checks,

            SUM(CASE
                WHEN r.result_norm = 'cancelled'
                THEN 1 ELSE 0
            END) AS ci_cancelled_checks,

            SUM(CASE
                WHEN r.result_norm NOT IN (
                    'success',
                    'failure',
                    'failed',
                    'timed_out',
                    'startup_failure',
                    'action_required',
                    'cancelled'
                )
                THEN 1 ELSE 0
            END) AS ci_other_checks,

            ROUND(
                100.0 * SUM(CASE
                    WHEN r.result_norm = 'success'
                    THEN 1 ELSE 0
                END) / NULLIF(COUNT(*), 0),
                2
            ) AS ci_avg_passed_percent,

            ROUND(
                100.0 * SUM(CASE
                    WHEN r.result_norm IN (
                        'failure',
                        'failed',
                        'timed_out',
                        'startup_failure',
                        'action_required'
                    )
                    THEN 1 ELSE 0
                END) / NULLIF(COUNT(*), 0),
                2
            ) AS ci_avg_failed_percent,

            ROUND(
                100.0 * SUM(CASE
                    WHEN r.result_norm = 'cancelled'
                    THEN 1 ELSE 0
                END) / NULLIF(COUNT(*), 0),
                2
            ) AS ci_avg_cancelled_percent,

            ROUND(
                100.0 * SUM(CASE
                    WHEN r.result_norm NOT IN (
                        'success',
                        'failure',
                        'failed',
                        'timed_out',
                        'startup_failure',
                        'action_required',
                        'cancelled'
                    )
                    THEN 1 ELSE 0
                END) / NULLIF(COUNT(*), 0),
                2
            ) AS ci_avg_other_percent,

            AVG(
                CASE
                    WHEN r.started_at IS NOT NULL
                     AND r.completed_at IS NOT NULL
                     AND TIMESTAMPDIFF(SECOND, r.started_at, r.completed_at) >= 0
                    THEN TIMESTAMPDIFF(SECOND, r.started_at, r.completed_at)
                    ELSE NULL
                END
            ) AS ci_avg_duration_seconds

        FROM ci_result_rows r
        GROUP BY
            r.commit_sha
    ),

    bic_by_commit AS (
        SELECT
            pibic.bug_introducing_commits_sha AS commit_sha,
            COUNT(DISTINCT CONCAT(
                pibic.project_issue_project_owner, ':',
                pibic.project_issue_project_name, ':',
                pibic.project_issue_id
            )) AS linked_bic_issues
        FROM project_issue_bug_introducing_commits pibic
        GROUP BY
            pibic.bug_introducing_commits_sha
    ),

    pr_process AS (
        SELECT
            pp.project_owner,
            pp.project_name,
            pp.id AS pr_id,

            COUNT(DISTINCT ppl.labels) AS pr_label_count,
            COUNT(DISTINCT ppa.assignees) AS pr_assignee_count,
            COUNT(DISTINCT ppr.reviewers) AS pr_reviewer_count,
            COUNT(DISTINCT ppt.time_line_id) AS pr_timeline_event_count,
            COALESCE(MAX(r.total_count), 0) AS pr_reaction_count

        FROM project_pull pp

        LEFT JOIN project_pull_labels ppl
          ON ppl.project_pull_id = pp.id
         AND ppl.project_pull_project_name = pp.project_name
         AND ppl.project_pull_project_owner = pp.project_owner

        LEFT JOIN project_pull_assignees ppa
          ON ppa.project_pull_id = pp.id
         AND ppa.project_pull_project_name = pp.project_name
         AND ppa.project_pull_project_owner = pp.project_owner

        LEFT JOIN project_pull_reviewers ppr
          ON ppr.project_pull_id = pp.id
         AND ppr.project_pull_project_name = pp.project_name
         AND ppr.project_pull_project_owner = pp.project_owner

        LEFT JOIN project_pull_time_line ppt
          ON ppt.project_pull_id = pp.id
         AND ppt.project_pull_project_name = pp.project_name
         AND ppt.project_pull_project_owner = pp.project_owner

        LEFT JOIN reaction r
          ON r.id = pp.reaction_id

        WHERE pp.project_owner = %(owner)s

        GROUP BY
            pp.project_owner,
            pp.project_name,
            pp.id
    ),

    pr_commit_rows AS (
        SELECT
            pp.project_owner,
            pp.project_name,
            pp.id AS pr_id,
            pp.created_at AS pr_created_at,
            pp.merged_at AS pr_merged_at,

            TIMESTAMPDIFF(HOUR, pp.created_at, pp.merged_at) AS pr_review_hours,

            c.sha AS commit_sha,

            c.min_depth_of_commit_history,
            c.max_depth_of_commit_history,
            (
                c.max_depth_of_commit_history
                - c.min_depth_of_commit_history
            ) AS depth_diff,

            c.distance_to_branch_start,
            c.upstream_heads_unique_on_segment,
            c.days_since_last_merge_on_segment,
            c.in_degree,
            c.out_degree,
            c.number_of_branches,
            c.average_degree,

            CASE
                WHEN c.days_since_last_merge_on_segment IS NULL THEN NULL
                ELSE
                    1.0 * c.distance_to_branch_start
                    / GREATEST(c.days_since_last_merge_on_segment, 1)
            END AS branch_commit_rate,

            cc.num_files_changed,
            cc.total_additions,
            cc.total_deletions,
            cc.total_changes,
            cc.avg_changes_per_file,
            cc.max_changes_in_file,

            CASE
                WHEN cc.num_files_changed > 0
                    THEN 1.0 * cc.total_changes / cc.num_files_changed
                ELSE NULL
            END AS change_density_per_file,

            ci.ci_check_runs,
            ci.ci_total_checks,
            ci.ci_passed_checks,
            ci.ci_failed_checks,
            ci.ci_cancelled_checks,
            ci.ci_other_checks,
            ci.ci_avg_passed_percent,
            ci.ci_avg_failed_percent,
            ci.ci_avg_cancelled_percent,
            ci.ci_avg_other_percent,
            ci.ci_avg_duration_seconds,

            COALESCE(bic.linked_bic_issues, 0) AS linked_bic_issues,

            CASE
                WHEN c.min_depth_of_commit_history IS NOT NULL
                 AND c.max_depth_of_commit_history IS NOT NULL
                 AND c.distance_to_branch_start IS NOT NULL
                 AND c.upstream_heads_unique_on_segment IS NOT NULL
                 AND c.days_since_last_merge_on_segment IS NOT NULL
                 AND c.in_degree IS NOT NULL
                 AND c.out_degree IS NOT NULL
                 AND c.number_of_branches IS NOT NULL
                 AND c.average_degree IS NOT NULL
                THEN 1 ELSE 0
            END AS graph_ready,

            CASE
                WHEN cc.num_files_changed IS NOT NULL
                 AND cc.num_files_changed > 0
                 AND cc.total_changes IS NOT NULL
                THEN 1 ELSE 0
            END AS churn_ready,

            CASE
                WHEN ci.ci_check_runs IS NOT NULL
                 AND ci.ci_check_runs > 0
                THEN 1 ELSE 0
            END AS ci_ready

        FROM project_pull pp

        JOIN project_pull_commits ppc
          ON ppc.project_pull_id = pp.id
         AND ppc.project_pull_project_name = pp.project_name
         AND ppc.project_pull_project_owner = pp.project_owner

        JOIN `commit` c
          ON c.sha = ppc.commits_sha

        LEFT JOIN commit_churn cc
          ON cc.commit_sha = c.sha

        LEFT JOIN ci_by_commit ci
          ON ci.commit_sha = c.sha

        LEFT JOIN bic_by_commit bic
          ON bic.commit_sha = c.sha

        WHERE pp.project_owner = %(owner)s
          AND pp.created_at IS NOT NULL
          AND pp.merged_at IS NOT NULL
          AND TIMESTAMPDIFF(HOUR, pp.created_at, pp.merged_at) >= 0
    )

SELECT
    pcr.project_owner,
    pcr.project_name,
    pcr.pr_id,
    pcr.pr_created_at,
    pcr.pr_merged_at,

    /* Targets */
    pcr.pr_review_hours,
    LOG(1 + pcr.pr_review_hours) AS log_pr_review_hours,

    CASE
        WHEN MOD(CRC32(CONCAT(pcr.project_owner, ':', pcr.project_name, ':', pcr.pr_id)), 10) < 8
            THEN 'train'
        ELSE 'validation'
    END AS dataset_split,

    /* Process / social features */
    COALESCE(pp.pr_label_count, 0) AS pr_label_count,
    COALESCE(pp.pr_assignee_count, 0) AS pr_assignee_count,
    COALESCE(pp.pr_reviewer_count, 0) AS pr_reviewer_count,
    COALESCE(pp.pr_timeline_event_count, 0) AS pr_timeline_event_count,
    COALESCE(pp.pr_reaction_count, 0) AS pr_reaction_count,

    /* Evidence counts */
    COUNT(DISTINCT pcr.commit_sha) AS pr_num_commits,
    SUM(pcr.graph_ready) AS pr_graph_ready_commits,
    SUM(pcr.churn_ready) AS pr_churn_ready_commits,
    SUM(pcr.ci_ready) AS pr_ci_ready_commits,

    CASE
        WHEN SUM(CASE WHEN pcr.linked_bic_issues > 0 THEN 1 ELSE 0 END) > 0
            THEN 1
        ELSE 0
    END AS pr_contains_candidate_bic,

    SUM(CASE WHEN pcr.linked_bic_issues > 0 THEN 1 ELSE 0 END)
        AS pr_candidate_bic_commits,

    SUM(pcr.linked_bic_issues) AS pr_candidate_bic_issue_links,

    /* Graph-history features */
    COALESCE(AVG(CASE WHEN pcr.graph_ready = 1 THEN pcr.min_depth_of_commit_history END), 0)
        AS pr_avg_min_depth,

    COALESCE(AVG(CASE WHEN pcr.graph_ready = 1 THEN pcr.max_depth_of_commit_history END), 0)
        AS pr_avg_max_depth,

    COALESCE(AVG(CASE WHEN pcr.graph_ready = 1 THEN pcr.depth_diff END), 0)
        AS pr_avg_depth_diff,

    COALESCE(MAX(CASE WHEN pcr.graph_ready = 1 THEN pcr.depth_diff END), 0)
        AS pr_max_depth_diff,

    COALESCE(AVG(CASE WHEN pcr.graph_ready = 1 THEN pcr.branch_commit_rate END), 0)
        AS pr_avg_branch_commit_rate,

    COALESCE(MAX(CASE WHEN pcr.graph_ready = 1 THEN pcr.branch_commit_rate END), 0)
        AS pr_max_branch_commit_rate,

    COALESCE(AVG(CASE WHEN pcr.graph_ready = 1 THEN pcr.distance_to_branch_start END), 0)
        AS pr_avg_fp_distance,

    COALESCE(MAX(CASE WHEN pcr.graph_ready = 1 THEN pcr.distance_to_branch_start END), 0)
        AS pr_max_fp_distance,

    COALESCE(AVG(CASE WHEN pcr.graph_ready = 1 THEN pcr.upstream_heads_unique_on_segment END), 0)
        AS pr_avg_upstream_heads,

    COALESCE(MAX(CASE WHEN pcr.graph_ready = 1 THEN pcr.upstream_heads_unique_on_segment END), 0)
        AS pr_max_upstream_heads,

    COALESCE(AVG(CASE WHEN pcr.graph_ready = 1 THEN pcr.days_since_last_merge_on_segment END), 0)
        AS pr_avg_days_since_merge,

    COALESCE(MAX(CASE WHEN pcr.graph_ready = 1 THEN pcr.days_since_last_merge_on_segment END), 0)
        AS pr_max_days_since_merge,

    COALESCE(AVG(CASE WHEN pcr.graph_ready = 1 THEN pcr.in_degree END), 0)
        AS pr_avg_in_degree,

    COALESCE(AVG(CASE WHEN pcr.graph_ready = 1 THEN pcr.out_degree END), 0)
        AS pr_avg_out_degree,

    COALESCE(AVG(CASE WHEN pcr.graph_ready = 1 THEN pcr.number_of_branches END), 0)
        AS pr_avg_branches,

    COALESCE(AVG(CASE WHEN pcr.graph_ready = 1 THEN pcr.average_degree END), 0)
        AS pr_avg_average_degree,

    /* Churn features */
    COALESCE(SUM(pcr.total_additions), 0) AS pr_total_additions,
    COALESCE(SUM(pcr.total_deletions), 0) AS pr_total_deletions,
    COALESCE(SUM(pcr.total_changes), 0) AS pr_total_changes,

    COALESCE(AVG(CASE WHEN pcr.churn_ready = 1 THEN pcr.avg_changes_per_file END), 0)
        AS pr_avg_changes_per_file,

    COALESCE(MAX(CASE WHEN pcr.churn_ready = 1 THEN pcr.max_changes_in_file END), 0)
        AS pr_max_changes_in_file,

    COALESCE(SUM(pcr.num_files_changed), 0) AS pr_num_files_changed,

    CASE
        WHEN COALESCE(SUM(pcr.num_files_changed), 0) > 0
            THEN 1.0 * COALESCE(SUM(pcr.total_changes), 0)
                 / COALESCE(SUM(pcr.num_files_changed), 0)
        ELSE 0
    END AS pr_change_density_per_file,

    /* Log-scaled count/churn features */
    LOG(1 + COUNT(DISTINCT pcr.commit_sha)) AS log_pr_num_commits,
    LOG(1 + COALESCE(SUM(pcr.total_additions), 0)) AS log_pr_total_additions,
    LOG(1 + COALESCE(SUM(pcr.total_deletions), 0)) AS log_pr_total_deletions,
    LOG(1 + COALESCE(SUM(pcr.total_changes), 0)) AS log_pr_total_changes,
    LOG(1 + COALESCE(SUM(pcr.num_files_changed), 0)) AS log_pr_num_files_changed,

    /* CI features computed from action.result values */
    COALESCE(SUM(pcr.ci_check_runs), 0) AS pr_ci_check_runs,
    COALESCE(SUM(pcr.ci_total_checks), 0) AS pr_ci_total_checks,
    COALESCE(SUM(pcr.ci_passed_checks), 0) AS pr_ci_passed_checks,
    COALESCE(SUM(pcr.ci_failed_checks), 0) AS pr_ci_failed_checks,
    COALESCE(SUM(pcr.ci_cancelled_checks), 0) AS pr_ci_cancelled_checks,
    COALESCE(SUM(pcr.ci_other_checks), 0) AS pr_ci_other_checks,

    CASE
        WHEN COALESCE(SUM(pcr.ci_total_checks), 0) > 0
            THEN ROUND(
                100.0 * COALESCE(SUM(pcr.ci_passed_checks), 0)
                / COALESCE(SUM(pcr.ci_total_checks), 0),
                2
            )
        ELSE 0
    END AS pr_ci_avg_passed_percent,

    CASE
        WHEN COALESCE(SUM(pcr.ci_total_checks), 0) > 0
            THEN ROUND(
                100.0 * COALESCE(SUM(pcr.ci_failed_checks), 0)
                / COALESCE(SUM(pcr.ci_total_checks), 0),
                2
            )
        ELSE 0
    END AS pr_ci_avg_failed_percent,

    CASE
        WHEN COALESCE(SUM(pcr.ci_total_checks), 0) > 0
            THEN ROUND(
                100.0 * COALESCE(SUM(pcr.ci_cancelled_checks), 0)
                / COALESCE(SUM(pcr.ci_total_checks), 0),
                2
            )
        ELSE 0
    END AS pr_ci_avg_cancelled_percent,

    CASE
        WHEN COALESCE(SUM(pcr.ci_total_checks), 0) > 0
            THEN ROUND(
                100.0 * COALESCE(SUM(pcr.ci_other_checks), 0)
                / COALESCE(SUM(pcr.ci_total_checks), 0),
                2
            )
        ELSE 0
    END AS pr_ci_avg_other_percent,

    COALESCE(AVG(pcr.ci_avg_duration_seconds), 0) AS pr_ci_avg_duration_seconds

FROM pr_commit_rows pcr

LEFT JOIN pr_process pp
  ON pp.project_owner = pcr.project_owner
 AND pp.project_name = pcr.project_name
 AND pp.pr_id = pcr.pr_id

GROUP BY
    pcr.project_owner,
    pcr.project_name,
    pcr.pr_id,
    pcr.pr_created_at,
    pcr.pr_merged_at,
    pcr.pr_review_hours,
    pp.pr_label_count,
    pp.pr_assignee_count,
    pp.pr_reviewer_count,
    pp.pr_timeline_event_count,
    pp.pr_reaction_count

HAVING
    COUNT(DISTINCT pcr.commit_sha) > 0

ORDER BY
    pcr.project_owner,
    pcr.project_name,
    pcr.pr_id;
WITH
    project_base AS (
        SELECT
            p.project_owner,
            p.project_name
        FROM project p
    ),

    commit_stats AS (
        SELECT
            c.project_owner,
            c.project_name,
            COUNT(DISTINCT c.sha) AS commits_total,
            COUNT(DISTINCT CASE
                               WHEN c.commit_date IS NOT NULL THEN c.sha
                END) AS commits_with_timestamp,
            COUNT(DISTINCT CASE
                               WHEN a.id IS NOT NULL THEN c.sha
                END) AS commits_with_ci,
            COUNT(DISTINCT a.id) AS ci_runs_total
        FROM commit c
                 LEFT JOIN action a
                           ON a.commit_sha = c.sha
        GROUP BY c.project_owner, c.project_name
    ),

    issue_stats AS (
        SELECT
            pi.project_owner,
            pi.project_name,

            COUNT(DISTINCT pi.id, pi.project_name, pi.project_owner) AS issues_total,

            COUNT(DISTINCT CASE
                               WHEN pi.state = 'closed'
                                   THEN pi.id
                END) AS issues_closed,

            COUNT(DISTINCT CASE
                               WHEN pi.created_at IS NOT NULL
                                   AND (pi.closed_at IS NOT NULL OR pi.state <> 'closed')
                                   THEN pi.id
                END) AS issues_with_usable_timestamps,

            COUNT(DISTINCT CASE
                               WHEN pi.state = 'closed'
                                   AND (
                                        (pi.fix_pr IS NOT NULL AND pi.fix_pr <> 0)
                                            OR (pi.fixpr_id IS NOT NULL AND pi.fixpr_id <> 0)
                                            OR pip.project_pull_id IS NOT NULL
                                            OR ppi.project_pull_id IS NOT NULL
                                            OR ppis.project_pull_id IS NOT NULL
                                        )
                                   THEN pi.id
                END) AS closed_issues_with_pr_link

        FROM project_issue pi
                 LEFT JOIN project_issue_project_pull pip
                           ON  pip.project_issue_id = pi.id
                               AND pip.project_issue_project_name = pi.project_name
                               AND pip.project_issue_project_owner = pi.project_owner

                 LEFT JOIN project_pull_project_issue ppi
                           ON  ppi.project_issue_id = pi.id
                               AND ppi.project_issue_project_name = pi.project_name
                               AND ppi.project_issue_project_owner = pi.project_owner

                 LEFT JOIN project_pull_project_issues ppis
                           ON  ppis.project_issues_id = pi.id
                               AND ppis.project_issues_project_name = pi.project_name
                               AND ppis.project_issues_project_owner = pi.project_owner

        GROUP BY pi.project_owner, pi.project_name
    ),

    pull_stats AS (
        SELECT
            pp.project_owner,
            pp.project_name,
            COUNT(DISTINCT pp.id, pp.project_name, pp.project_owner) AS prs_total,
            COUNT(DISTINCT CASE
                               WHEN pp.state = 'closed'
                                   THEN pp.id
                END) AS prs_closed,
            COUNT(DISTINCT CASE
                               WHEN pp.created_at IS NOT NULL
                                   AND (
                                        pp.merged_at IS NOT NULL
                                            OR pp.closed_at IS NOT NULL
                                            OR pp.state <> 'closed'
                                        )
                                   THEN pp.id
                END) AS prs_with_usable_timestamps,
            COUNT(DISTINCT CASE
                               WHEN ppc.commits_sha IS NOT NULL
                                   THEN pp.id
                END) AS prs_with_commits
        FROM project_pull pp
                 LEFT JOIN project_pull_commits ppc
                           ON  ppc.project_pull_id = pp.id
                               AND ppc.project_pull_project_name = pp.project_name
                               AND ppc.project_pull_project_owner = pp.project_owner
        GROUP BY pp.project_owner, pp.project_name
    ),

    file_change_stats AS (
        SELECT
            c.project_owner,
            c.project_name,
            COUNT(DISTINCT fc.id) AS file_changes_total,
            COUNT(DISTINCT CASE
                               WHEN fc.patch IS NOT NULL AND fc.patch <> ''
                                   THEN fc.id
                END) AS file_changes_with_patch,
            COUNT(DISTINCT fcl.file_change_id) AS file_changes_with_changed_lines
        FROM commit c
                 JOIN commit_file_changes cfc
                      ON cfc.commit_sha = c.sha
                 JOIN file_change fc
                      ON fc.id = cfc.file_changes_id
                 LEFT JOIN file_change_changed_lines fcl
                           ON fcl.file_change_id = fc.id
        GROUP BY c.project_owner, c.project_name
    ),

    timeline_stats AS (
        SELECT
            project_owner,
            project_name,
            COUNT(DISTINCT timeline_id) AS timelines_total,
            COUNT(DISTINCT CASE
                               WHEN created_at IS NOT NULL THEN timeline_id
                END) AS timelines_with_timestamp
        FROM (
                 SELECT
                     pi.project_owner,
                     pi.project_name,
                     t.id AS timeline_id,
                     t.created_at
                 FROM timeline t
                          JOIN project_issue pi
                               ON  pi.id = t.project_issue_id
                                   AND pi.project_name = t.project_issue_project_name
                                   AND pi.project_owner = t.project_issue_project_owner

                 UNION

                 SELECT
                     pp.project_owner,
                     pp.project_name,
                     t.id AS timeline_id,
                     t.created_at
                 FROM timeline t
                          JOIN project_pull pp
                               ON  pp.id = t.project_pull_id
                                   AND pp.project_name = t.project_pull_project_name
                                   AND pp.project_owner = t.project_pull_project_owner
             ) x
        GROUP BY project_owner, project_name
    ),

    reaction_stats AS (
        SELECT
            project_owner,
            project_name,
            COUNT(DISTINCT reaction_id) AS reactions_total
        FROM (
                 SELECT
                     pi.project_owner,
                     pi.project_name,
                     pi.reaction_id
                 FROM project_issue pi
                 WHERE pi.reaction_id IS NOT NULL

                 UNION

                 SELECT
                     pp.project_owner,
                     pp.project_name,
                     pp.reaction_id
                 FROM project_pull pp
                 WHERE pp.reaction_id IS NOT NULL
             ) x
        GROUP BY project_owner, project_name
    ),

    defect_link_stats AS (
        SELECT
            pi.project_owner,
            pi.project_name,

            COUNT(DISTINCT
                  pifc.project_issue_id,
                  pifc.project_issue_project_name,
                  pifc.project_issue_project_owner
            ) AS issues_with_fixing_commits,

            COUNT(DISTINCT pifc.fixing_commits_sha) AS fixing_commits_total,

            COUNT(DISTINCT
                  pibic.project_issue_id,
                  pibic.project_issue_project_name,
                  pibic.project_issue_project_owner
            ) AS issues_with_candidate_bics,

            COUNT(DISTINCT pibic.bug_introducing_commits_sha)
                AS candidate_bic_commits_total,

            COUNT(DISTINCT
                  CONCAT(
                          pibic.project_issue_id, ':',
                          pibic.project_issue_project_name, ':',
                          pibic.project_issue_project_owner, ':',
                          pibic.bug_introducing_commits_sha
                  )
            ) AS issue_candidate_bic_links_total

        FROM project_issue pi
                 LEFT JOIN project_issue_fixing_commits pifc
                           ON  pifc.project_issue_id = pi.id
                               AND pifc.project_issue_project_name = pi.project_name
                               AND pifc.project_issue_project_owner = pi.project_owner

                 LEFT JOIN project_issue_bug_introducing_commits pibic
                           ON  pibic.project_issue_id = pi.id
                               AND pibic.project_issue_project_name = pi.project_name
                               AND pibic.project_issue_project_owner = pi.project_owner

        GROUP BY pi.project_owner, pi.project_name
    )

SELECT
    pb.project_owner,
    pb.project_name,

    /* Artifact counts */
    COALESCE(cs.commits_total, 0) AS commits_total,
    COALESCE(iss.issues_total, 0) AS issues_total,
    COALESCE(ps.prs_total, 0) AS pull_requests_total,
    COALESCE(fcs.file_changes_total, 0) AS file_changes_total,
    COALESCE(ts.timelines_total, 0) AS timelines_total,
    COALESCE(rs.reactions_total, 0) AS reactions_total,
    COALESCE(cs.ci_runs_total, 0) AS ci_check_runs_total,

    /* PR-commit coverage */
    COALESCE(ps.prs_with_commits, 0) AS prs_with_commits,
    ROUND(
            100.0 * COALESCE(ps.prs_with_commits, 0) / NULLIF(ps.prs_total, 0),
            2
    ) AS pr_commit_coverage_percent,

    /* Closed issue-PR link coverage */
    COALESCE(iss.issues_closed, 0) AS closed_issues_total,
    COALESCE(iss.closed_issues_with_pr_link, 0) AS closed_issues_with_pr_link,
    ROUND(
            100.0 * COALESCE(iss.closed_issues_with_pr_link, 0) / NULLIF(iss.issues_closed, 0),
            2
    ) AS closed_issue_pr_link_coverage_percent,

    /* CI coverage */
    COALESCE(cs.commits_with_ci, 0) AS commits_with_ci,
    ROUND(
            100.0 * COALESCE(cs.commits_with_ci, 0) / NULLIF(cs.commits_total, 0),
            2
    ) AS commit_ci_coverage_percent,

    CASE
        WHEN COALESCE(cs.commits_with_ci, 0) > 0
            THEN ROUND(1.0 * COALESCE(cs.ci_runs_total, 0) / cs.commits_with_ci, 2)
        ELSE NULL
        END AS ci_runs_per_ci_covered_commit,

    /* Timestamp completeness */
    COALESCE(cs.commits_with_timestamp, 0) AS commits_with_timestamp,
    ROUND(
            100.0 * COALESCE(cs.commits_with_timestamp, 0) / NULLIF(cs.commits_total, 0),
            2
    ) AS commit_timestamp_completeness_percent,

    COALESCE(iss.issues_with_usable_timestamps, 0) AS issues_with_usable_timestamps,
    ROUND(
            100.0 * COALESCE(iss.issues_with_usable_timestamps, 0) / NULLIF(iss.issues_total, 0),
            2
    ) AS issue_timestamp_completeness_percent,

    COALESCE(ps.prs_with_usable_timestamps, 0) AS prs_with_usable_timestamps,
    ROUND(
            100.0 * COALESCE(ps.prs_with_usable_timestamps, 0) / NULLIF(ps.prs_total, 0),
            2
    ) AS pr_timestamp_completeness_percent,

    COALESCE(ts.timelines_with_timestamp, 0) AS timelines_with_timestamp,
    ROUND(
            100.0 * COALESCE(ts.timelines_with_timestamp, 0) / NULLIF(ts.timelines_total, 0),
            2
    ) AS timeline_timestamp_completeness_percent,

    /* File-change completeness */
    COALESCE(fcs.file_changes_with_patch, 0) AS file_changes_with_patch,
    ROUND(
            100.0 * COALESCE(fcs.file_changes_with_patch, 0) / NULLIF(fcs.file_changes_total, 0),
            2
    ) AS file_change_patch_coverage_percent,

    COALESCE(fcs.file_changes_with_changed_lines, 0) AS file_changes_with_changed_lines,
    ROUND(
            100.0 * COALESCE(fcs.file_changes_with_changed_lines, 0) / NULLIF(fcs.file_changes_total, 0),
            2
    ) AS changed_line_coverage_percent,

    /* Defect-linking statistics */
    COALESCE(dls.issues_with_fixing_commits, 0) AS issues_with_fixing_commits,
    COALESCE(dls.fixing_commits_total, 0) AS fixing_commits_total,
    COALESCE(dls.issues_with_candidate_bics, 0) AS issues_with_candidate_bics,
    COALESCE(dls.candidate_bic_commits_total, 0) AS candidate_bug_introducing_commits_total,
    COALESCE(dls.issue_candidate_bic_links_total, 0) AS issue_candidate_bic_links_total

FROM project_base pb
         LEFT JOIN commit_stats cs
                   ON cs.project_owner = pb.project_owner
                       AND cs.project_name = pb.project_name

         LEFT JOIN issue_stats iss
                   ON iss.project_owner = pb.project_owner
                       AND iss.project_name = pb.project_name

         LEFT JOIN pull_stats ps
                   ON ps.project_owner = pb.project_owner
                       AND ps.project_name = pb.project_name

         LEFT JOIN file_change_stats fcs
                   ON fcs.project_owner = pb.project_owner
                       AND fcs.project_name = pb.project_name

         LEFT JOIN timeline_stats ts
                   ON ts.project_owner = pb.project_owner
                       AND ts.project_name = pb.project_name

         LEFT JOIN reaction_stats rs
                   ON rs.project_owner = pb.project_owner
                       AND rs.project_name = pb.project_name

         LEFT JOIN defect_link_stats dls
                   ON dls.project_owner = pb.project_owner
                       AND dls.project_name = pb.project_name

WHERE
    (pb.project_owner = 'ansible' AND pb.project_name = 'ansible')
   OR (pb.project_owner = 'facebook' AND pb.project_name = 'react')

ORDER BY pb.project_owner, pb.project_name;
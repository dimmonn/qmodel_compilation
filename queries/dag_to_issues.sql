
WITH pr_durations AS (
    SELECT
        c.sha,
        AVG(TIMESTAMPDIFF(
                HOUR,
                p.created_at,
                COALESCE(p.merged_at, p.closed_at, p.updated_at)
            )) AS avg_pr_review_hours,
        COUNT(DISTINCT p.id) AS pr_count
    FROM qmodel_demo.commit c
             JOIN qmodel_demo.project_pull_commits ppc
                  ON ppc.commits_sha = c.sha
             JOIN qmodel_demo.project_pull p
                  ON p.id = ppc.project_pull_id
                      AND p.project_name = ppc.project_pull_project_name
                      AND p.project_owner = ppc.project_pull_project_owner
    GROUP BY c.sha
),

     issue_links AS (
         SELECT
             c.sha,
             pi.id AS issue_id,
             TIMESTAMPDIFF(
                     HOUR,
                     pi.created_at,
                     COALESCE(pi.closed_at, pi.updated_at)
             ) AS issue_resolution_hours
         FROM qmodel_demo.commit c
                  JOIN qmodel_demo.project_issue_fixing_commits pifc
                       ON pifc.fixing_commits_sha = c.sha
                  JOIN qmodel_demo.project_issue pi
                       ON pi.id = pifc.project_issue_id
                           AND pi.project_name = pifc.project_issue_project_name
                           AND pi.project_owner = pifc.project_issue_project_owner

         UNION

         SELECT
             c.sha,
             pi.id AS issue_id,
             TIMESTAMPDIFF(
                     HOUR,
                     pi.created_at,
                     COALESCE(pi.closed_at, pi.updated_at)
             ) AS issue_resolution_hours
         FROM qmodel_demo.commit c
                  JOIN qmodel_demo.project_pull_commits ppc
                       ON ppc.commits_sha = c.sha
                  JOIN qmodel_demo.project_pull_project_issue pppi
                       ON pppi.project_pull_id = ppc.project_pull_id
                           AND pppi.project_pull_project_name = ppc.project_pull_project_name
                           AND pppi.project_pull_project_owner = ppc.project_pull_project_owner
                  JOIN qmodel_demo.project_issue pi
                       ON pi.id = pppi.project_issue_id
                           AND pi.project_name = pppi.project_issue_project_name
                           AND pi.project_owner = pppi.project_issue_project_owner
     ),

     issue_agg AS (
         SELECT
             sha,
             AVG(issue_resolution_hours) AS avg_issue_resolution_hours,
             COUNT(DISTINCT issue_id)    AS issue_count
         FROM issue_links
         GROUP BY sha
     )

SELECT
    c.sha,
    c.project_name,
    c.project_owner,
    c.commit_date,

    c.is_merge,
    c.num_of_files_changed,
    c.average_degree,
    c.in_degree,
    c.out_degree,
    c.number_of_vertices,
    c.number_of_edges,
    c.number_of_branches,
    c.max_depth_of_commit_history,
    c.min_depth_of_commit_history,
    c.days_since_last_merge_on_segment,
    c.distance_to_branch_start,
    c.upstream_heads_unique_on_segment,

    ia.avg_issue_resolution_hours,
    ia.issue_count,
    pd.avg_pr_review_hours,
    pd.pr_count

FROM qmodel_demo.commit c
         LEFT JOIN issue_agg    ia ON ia.sha = c.sha
         LEFT JOIN pr_durations pd ON pd.sha = c.sha

where c.project_owner='ansible'
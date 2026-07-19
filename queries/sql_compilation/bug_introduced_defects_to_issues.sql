SELECT c.sha                                            AS commit_sha,
       c.message                                        AS commit_message,
       c.average_degree,
       c.in_degree,
       c.out_degree,
       c.comment_count,
       c.merge_count,
       c.max_depth_of_commit_history,
       c.min_depth_of_commit_history,
       c.num_of_files_changed,
       c.number_of_branches,
       c.number_of_edges,
       c.number_of_vertices,

       i.id                                             AS issue_id,
       i.title                                          AS issue_title,
       i.state                                          AS issue_state,
       i.created_at                                     AS issue_created_at,
       i.closed_at                                      AS issue_closed_at,
       i.project_name                                   AS issue_project_name,
       i.project_owner                                  AS issue_project_owner,

       TIMESTAMPDIFF(MINUTE, i.created_at, i.closed_at) AS fix_time_minutes
FROM commit c
         JOIN
     project_issue_bug_introducing_commits bibc
     ON c.sha = bibc.bug_introducing_commits_sha
         JOIN
     project_issue i
     ON bibc.project_issue_id = i.id
         AND bibc.project_issue_project_name = i.project_name
         AND bibc.project_issue_project_owner = i.project_owner
ORDER BY fix_time_minutes DESC;

SELECT
    commit.sha AS bug_introducing_commit_sha,
    commit.author AS commit_author,
    commit.commit_date AS commit_date,
    commit.average_degree AS commit_average_degree,
    commit.branch_length AS commit_branch_length,
    commit.max_degree AS commit_max_degree,
    commit.message AS commit_message,
    project_issue.id AS issue_id,
    project_issue.title AS issue_title,
    project_issue.created_at AS issue_created_at,
    project_issue.closed_at AS issue_closed_at,
    TIMESTAMPDIFF(DAY, project_issue.created_at, project_issue.closed_at) AS issue_resolution_time_days,
    project_issue.project_name AS issue_project_name,
    project_issue.project_owner AS issue_project_owner
FROM
    project_issue_bug_introducing_commits AS bug_commits
        JOIN
    commit ON bug_commits.bug_introducing_commits_sha = commit.sha
        JOIN
    project_issue AS project_issue
    ON bug_commits.project_issue_project_name = project_issue.project_name
        AND bug_commits.project_issue_project_owner = project_issue.project_owner
WHERE
    project_issue.closed_at IS NOT NULL;

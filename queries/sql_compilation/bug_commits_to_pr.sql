
SELECT
    commit.sha AS bug_introducing_commit_sha,
    commit.author AS commit_author,
    commit.commit_date AS commit_date,
    commit.average_degree AS commit_average_degree,
    commit.branch_length AS commit_branch_length,
    commit.max_degree AS commit_max_degree,
    commit.message AS commit_message,
    project_pull.id AS pr_id,
    project_pull.title AS pr_title,
    project_pull.created_at AS pr_created_at,
    project_pull.merged_at AS pr_merged_at,
    TIMESTAMPDIFF(DAY, project_pull.created_at, project_pull.merged_at) AS pr_review_time_days,
    project_pull.project_name AS pr_project_name,
    project_pull.project_owner AS pr_project_owner
FROM
    project_issue_bug_introducing_commits AS bug_commits
        JOIN
    commit ON bug_commits.bug_introducing_commits_sha = commit.sha
        JOIN
    project_pull AS project_pull
    ON bug_commits.project_issue_project_name = project_pull.project_name
        AND bug_commits.project_issue_project_owner = project_pull.project_owner
WHERE
    project_pull.merged_at IS NOT NULL;